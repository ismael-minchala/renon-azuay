function R = renon_dispatch(x, P, S)
%RENON_DISPATCH Despacho horario anual del EMS multivectorial ReNoN.
%   R = RENON_DISPATCH(X, P, S) simula el anio completo para la
%   configuracion X = [P_pv, P_wind, E_bat, P_hyd_nueva, f_flex_agua,
%   f_smart_ev] y devuelve los indicadores (CO2 total, costo anual,
%   energia no suministrada, vertimiento) y las series de despacho.
%
%   Estrategia del EMS (jerarquia de reglas, cf. EnergyPLAN):
%     1. Cargas flexibles (bombeo diferible y carga inteligente de VE)
%        se reprograman cada dia hacia las horas de menor carga neta
%        (absorben excedente renovable / valle nocturno).
%     2. La bateria carga con excedente renovable y descarga en deficit.
%     3. El deficit restante se cubre con importacion del SNI y, en
%        ultima instancia, con la termica local de respaldo.

P_pv = x(1); P_wind = x(2); E_bat = x(3); P_hyn = x(4);
f_fa = x(5); f_sev = x(6);
H = P.H;

% ---------------- Generacion renovable local --------------------------
gen_hyd  = (P.hyd0 + 0.9*P_hyn) * S.cf_hyd;    % MW (mini-hidro nueva, cf 90% del perfil)
gen_pv   = P_pv  * S.cf_pv;
gen_wind = P_wind * S.cf_wind;
ren = gen_hyd + gen_pv + gen_wind;

% ---------------- Cargas fijas ----------------------------------------
bomb_fijo = (1-f_fa) * S.perfil_bomb_fijo;
ev_fijo   = (1-f_sev) * S.perfil_ev_fijo;
carga_fija = S.dem_e + S.p_trat + bomb_fijo + ev_fijo;
net0 = carga_fija - ren;                        % MW carga neta antes de flexibilidad

% ---------------- Asignacion diaria de cargas flexibles ---------------
E_fa_dia  = f_fa  * S.E_bomb_dia;               % MWh/dia bombeo diferible
E_sev_dia = f_sev * S.E_ev_dia;                 % MWh/dia carga inteligente VE
P_fa_max  = S.P_bomb_max;
P_sev_max = max(S.P_ev_max, E_sev_dia/6);

flex = zeros(H,1);
if E_fa_dia > 1e-9 || E_sev_dia > 1e-9
    net_d = reshape(net0, 24, 365);
    for d = 1:365
        nd = net_d(:,d);
        % bombeo diferible: llenar las horas de menor carga neta
        [~,idx] = sort(nd);
        rem = E_fa_dia; al = zeros(24,1);
        for k = 1:24
            if rem <= 0, break; end
            q = min(P_fa_max, rem); al(idx(k)) = q; rem = rem - q;
        end
        nd = nd + al;
        % carga inteligente de VE sobre la carga neta actualizada
        [~,idx] = sort(nd);
        rem = E_sev_dia; al2 = zeros(24,1);
        for k = 1:24
            if rem <= 0, break; end
            q = min(P_sev_max, rem); al2(idx(k)) = q; rem = rem - q;
        end
        flex((d-1)*24+(1:24)) = al + al2;
    end
end
net1 = net0 + flex;

% ---------------- Bateria (balance secuencial) ------------------------
P_bat = E_bat/3;                                % C/3
eta = 0.95;                                     % eficiencia por sentido (90% ciclo)
soc = 0.5*E_bat;
bat = zeros(H,1);                               % >0 descarga, <0 carga
if E_bat > 1e-6
    for t = 1:H
        n = net1(t);
        if n < 0                                % excedente -> cargar
            q = min([-n, P_bat, (E_bat-soc)/eta]);
            soc = soc + q*eta; bat(t) = -q;
        elseif n > 0                            % deficit -> descargar
            q = min([n, P_bat, soc*eta]);
            soc = soc - q/eta; bat(t) = q;
        end
    end
end
net2 = net1 - bat;

% ---------------- Importacion, termica local, ENS, vertimiento --------
imp  = min(max(net2,0), P.cap_imp);
rem  = max(net2,0) - imp;
th   = min(rem, P.P_th);
ens  = rem - th;
vert = max(-net2,0);

% ---------------- Indicadores -----------------------------------------
co2_elec  = sum(imp.*S.ef_grid) + sum(th)*P.ef_th;            % tCO2/anio
co2_transp= (1-P.x_ev)*P.flota*P.km_anio*P.ef_ice;            % tCO2/anio flota ICE restante
R.co2 = (co2_elec + co2_transp)/1e3;                          % ktCO2/anio

capex = (P_pv-P.pv0)*1e3*P.c_pv + (P_wind-P.wind0)*1e3*P.c_wind + ...
        E_bat*1e3*P.c_bat + P_hyn*1e3*P.c_hyd + ...
        f_fa*P.c_flex_agua + f_sev*S.n_ev*P.c_smart_ev;       % USD/anio
opex  = sum(imp.*S.prec_imp) + sum(th)*P.c_th + sum(ens)*P.voll;
R.costo = (capex + opex)/1e6;                                 % MUSD/anio

R.ens = sum(ens);  R.vert = sum(vert);                        % MWh/anio
R.imp = sum(imp)/1e3; R.th = sum(th)/1e3;                     % GWh/anio
R.gen = [sum(gen_hyd), sum(gen_pv), sum(gen_wind)]/1e3;       % GWh/anio
R.dem_total = sum(carga_fija+flex)/1e3;                       % GWh/anio
R.frac_ren  = min(sum(min(ren,carga_fija+flex))/sum(carga_fija+flex),1);
R.co2_elec = co2_elec/1e3; R.co2_transp = co2_transp/1e3;     % kt
R.resiliencia = 1 - sum(ens)/(sum(carga_fija+flex));

% series para graficas
R.s.ren = ren; R.s.carga = carga_fija + flex; R.s.bat = bat;
R.s.imp = imp; R.s.th = th; R.s.ens = ens; R.s.vert = vert;
R.s.gen_hyd = gen_hyd; R.s.gen_pv = gen_pv; R.s.gen_wind = gen_wind;
R.s.flex = flex; R.s.net0 = net0;
end
