function R = renon_hub(x, P, S, opt)
%RENON_HUB Despacho horario anual del modelo vectorial (energy hub) ReNoN.
%   R = RENON_HUB(X, P, S, OPT) simula el anio tipo para la configuracion
%   X = [P_pv, P_wind, E_bat, P_hyd_nueva, f_flex_agua, f_smart_ev, f_v2g]
%   con la formulacion de concentrador energetico (energy hub):
%
%        L(t) = C(t) p(t) + S_e dE(t)/dt
%
%   donde p(t) es el vector de portadores de entrada
%   [hidro, FV, eolica, importacion SNI, termica local, combustible ICE],
%   L(t) el vector de servicios [electricidad pura, agua potable,
%   movilidad] expresado en unidades de electricidad equivalente y E(t)
%   el vector de almacenamientos [bateria, tanques (bombeo diferible),
%   baterias de VE (carga inteligente / V2G)].
%
%   OPT.ems   : 'valley' (llenado de valles, v1) | 'attention'
%   OPT.theta : [alpha beta gamma tau] pesos del mecanismo de atencion
%
%   Devuelve indicadores agregados y por vector (emisiones, costo,
%   resiliencia), la matriz de acoplamiento media C y las series.

if nargin < 4, opt = struct(); end
if ~isfield(opt,'ems'),   opt.ems = 'valley'; end
if ~isfield(opt,'theta'), opt.theta = P.theta_default; end

P_pv = x(1); P_wind = x(2); E_bat = x(3); P_hyn = x(4);
f_fa = x(5); f_sev = x(6);
f_g = 0; if numel(x) >= 7, f_g = x(7); end
H = P.H;

% ================= Portadores de entrada renovables ===================
gen_hyd  = (P.hyd0 + 0.9*P_hyn) * S.cf_hyd;
gen_pv   = P_pv  * S.cf_pv;
gen_wind = P_wind * S.cf_wind;
ren = gen_hyd + gen_pv + gen_wind;

% ================= Vector de servicios (carga por vector) =============
bomb_fijo = (1-f_fa) * S.perfil_bomb_fijo;
ev_fijo   = (1-f_sev) * S.perfil_ev_fijo;
L_e = S.dem_e;                          % electricidad pura
L_w_fijo = S.p_trat + bomb_fijo;        % agua: tratamiento + bombeo no diferible
L_m_fijo = ev_fijo;                     % movilidad: carga no inteligente
carga_fija = L_e + L_w_fijo + L_m_fijo;
net0 = carga_fija - ren;

% ================= Almacenamiento virtual: cargas flexibles ===========
E_fa_dia  = f_fa  * S.E_bomb_dia;
E_sev_dia = f_sev * S.E_ev_dia;
P_fa_max  = S.P_bomb_max;
P_sev_max = max(S.P_ev_max, E_sev_dia/6);

flex_w = zeros(H,1); flex_m = zeros(H,1);
if E_fa_dia > 1e-9 || E_sev_dia > 1e-9
    net_d = reshape(net0, 24, 365);
    ef_d  = reshape(S.ef_grid, 24, 365);
    pr_d  = reshape(S.prec_imp, 24, 365);
    for d = 1:365
        nd = net_d(:,d);
        al = alloc_day(nd, E_fa_dia, P_fa_max, ef_d(:,d), pr_d(:,d), opt);
        nd = nd + al;
        al2 = alloc_day(nd, E_sev_dia, P_sev_max, ef_d(:,d), pr_d(:,d), opt);
        idx = (d-1)*24+(1:24);
        flex_w(idx) = al; flex_m(idx) = al2;
    end
end
net1 = net0 + flex_w + flex_m;

% ================= Bateria estacionaria (secuencial) ==================
P_bat = E_bat/3; eta = 0.95; soc = 0.5*E_bat;
bat = zeros(H,1);
if E_bat > 1e-6
    for t = 1:H
        n = net1(t);
        if n < 0
            q = min([-n, P_bat, (E_bat-soc)/eta]); soc = soc + q*eta; bat(t) = -q;
        elseif n > 0
            q = min([n, P_bat, soc*eta]); soc = soc - q/eta; bat(t) = q;
        end
    end
end
net2 = net1 - bat;

% ================= Vehiculo-a-red (V2G) ===============================
v2g = zeros(H,1); v2g_rec = zeros(H,1);
n_v2g = f_g * f_sev * S.n_ev;
if n_v2g > 1
    P_v2g = n_v2g * P.p_plug * P.disp_v2g;             % MW disponibles
    E_v2g_dia = P.frac_E_v2g * f_g * f_sev * S.E_ev_dia; % MWh/dia
    net_d = reshape(net2, 24, 365);
    hw = (P.h_v2g(1):P.h_v2g(2)) + 1;                  % indices de hora (1..24)
    for d = 1:365
        nd = net_d(:,d);
        dis = zeros(24,1); rem = E_v2g_dia;
        [~, o] = sort(nd(hw), 'descend');
        for k = 1:numel(hw)
            h = hw(o(k));
            if nd(h) <= 0 || rem <= 0, continue; end
            q = min([nd(h), P_v2g, rem]); dis(h) = q; rem = rem - q;
        end
        Edis = sum(dis);
        rec = zeros(24,1);
        if Edis > 0
            % recarga en las 4 horas de menor carga neta del mismo dia
            nd2 = nd - dis; [~, o2] = sort(nd2);
            Erec = Edis / P.eta_v2g; remr = Erec;
            for k = 1:4
                q = min(remr, P_v2g*1.5); rec(o2(k)) = q; remr = remr - q;
                if remr <= 0, break; end
            end
            if remr > 0, rec(o2(4)) = rec(o2(4)) + remr; end
        end
        idx = (d-1)*24+(1:24);
        v2g(idx) = dis; v2g_rec(idx) = rec;
    end
end
net3 = net2 - v2g + v2g_rec;

% ================= Importacion, termica, ENS, vertimiento =============
imp  = min(max(net3,0), P.cap_imp);
rem  = max(net3,0) - imp;
th   = min(rem, P.P_th);
ens  = rem - th;
vert = max(-net3,0);

% ================= Indicadores agregados ==============================
carga = carga_fija + flex_w + flex_m + v2g_rec;      % carga electrica total servida
co2_h = imp.*S.ef_grid + th*P.ef_th;                 % tCO2 por hora (vector electrico)
co2_elec  = sum(co2_h);
co2_transp= (1-P.x_ev)*P.flota*P.km_anio*P.ef_ice;
R.co2 = (co2_elec + co2_transp)/1e3;

capex_gen = (P_pv-P.pv0)*1e3*P.c_pv + (P_wind-P.wind0)*1e3*P.c_wind + ...
            E_bat*1e3*P.c_bat + P_hyn*1e3*P.c_hyd;
capex_w = f_fa*P.c_flex_agua;
capex_m = f_sev*S.n_ev*P.c_smart_ev + n_v2g*P.c_v2g_cap;
opex_h  = imp.*S.prec_imp + th*P.c_th + ens*P.voll;  % USD por hora
opex_v2g = sum(v2g)*P.c_v2g;
R.costo = (capex_gen + capex_w + capex_m + sum(opex_h) + opex_v2g)/1e6;

R.ens = sum(ens); R.vert = sum(vert);
R.imp = sum(imp)/1e3; R.th = sum(th)/1e3;
R.gen = [sum(gen_hyd), sum(gen_pv), sum(gen_wind)]/1e3;
R.dem_total = sum(carga)/1e3;
R.frac_ren  = min(sum(min(ren,carga))/sum(carga),1);
R.co2_elec = co2_elec/1e3; R.co2_transp = co2_transp/1e3;
R.resiliencia = 1 - sum(ens)/sum(carga);
R.E_v2g = sum(v2g)/1e3; R.E_flex = (sum(flex_w)+sum(flex_m))/1e3;   % GWh
R.kappa = (sum(flex_w)+sum(flex_m)+sum(v2g)+sum(max(-bat,0)))/sum(carga); % indice de acoplamiento

% ================= Indicadores por vector =============================
Lv = [L_e, L_w_fijo + flex_w, L_m_fijo + flex_m + v2g_rec];   % H x 3
Lv = max(Lv, 0); Ltot = max(sum(Lv,2), 1e-9);
share = Lv ./ Ltot;                                             % participacion horaria
E_v = sum(Lv)/1e3;                                              % GWh por vector
co2_v = (share' * co2_h)'/1e3;                                  % kt por vector (electrico)
co2_v(3) = co2_v(3) + co2_transp/1e3;                           % + flota ICE
ens_v = (share' * ens)';
cost_v = (share' * opex_h)'/1e6;                                 % opex asignado
cost_v = cost_v + capex_gen/1e6 * (E_v/sum(E_v));                % capex generacion prorrateado
cost_v = cost_v + [0, capex_w, capex_m + opex_v2g]/1e6;
res_v = 1 - ens_v ./ max(sum(Lv), 1e-9);
R.vec.E_GWh = E_v; R.vec.co2_kt = co2_v; R.vec.costo_MUSD = cost_v;
R.vec.resiliencia = res_v; R.vec.ENS_MWh = ens_v;
R.vec.agua_no_servida_m3 = ens_v(2)*1e3 / (P.e_trat + P.frac_bombeo*P.e_bombeo); % m3 equiv.
R.vec.km_no_servidos = ens_v(3)*1e3 / P.e_km;

% ================= Matriz de acoplamiento media C (3 x 6) =============
% C(v,c): fraccion del servicio v suministrada por el portador c
sup = [gen_hyd, gen_pv, gen_wind, imp, th];                     % H x 5
sup = sup .* (Ltot ./ max(sum(sup,2) + max(bat,0) + v2g, 1e-9)); % normaliza a la carga
C = zeros(3,6);
for v = 1:3
    for c = 1:5
        C(v,c) = sum(share(:,v) .* sup(:,c)) / max(sum(Lv(:,v)),1e-9);
    end
end
% combustible ICE alimenta solo movilidad: fraccion de km no electrificados
C(3,6) = (1-P.x_ev);
C(3,1:5) = C(3,1:5) * P.x_ev;
R.C = C;
R.portadores = {'Hidro','FV','Eolica','SNI','Termica','Combustible'};
R.servicios  = {'Electricidad','Agua','Movilidad'};

% ================= Series =============================================
R.s.ren = ren; R.s.carga = carga; R.s.bat = bat; R.s.v2g = v2g; R.s.v2g_rec = v2g_rec;
R.s.imp = imp; R.s.th = th; R.s.ens = ens; R.s.vert = vert;
R.s.gen_hyd = gen_hyd; R.s.gen_pv = gen_pv; R.s.gen_wind = gen_wind;
R.s.flex_w = flex_w; R.s.flex_m = flex_m; R.s.net0 = net0; R.s.Lv = Lv;
end

% ======================================================================
function u = alloc_day(nd, E, Pmax, ef, pr, opt)
%ALLOC_DAY Asignacion diaria de una carga flexible de energia E (MWh).
u = zeros(24,1);
if E <= 1e-9, return; end
switch opt.ems
    case 'valley'
        [~, idx] = sort(nd); rem = E;
        for k = 1:24
            if rem <= 0, break; end
            q = min(Pmax, rem); u(idx(k)) = q; rem = rem - q;
        end
    case 'attention'
        th = opt.theta; tau = max(th(4), 1e-3);
        z = @(v) (v - mean(v)) / max(std(v), 1e-6);
        s = -(th(1)*z(nd) + th(2)*z(ef) + th(3)*z(pr)) / tau;   % puntajes (query-key)
        a = exp(s - max(s)); a = a / sum(a);                     % softmax -> pesos de atencion
        u = E * a;
        for it = 1:48                                            % respeto de capacidad
            over = u >= Pmax; u(over) = Pmax;
            rem = E - sum(u); free = ~over;
            if rem <= 1e-9 || ~any(free), break; end
            u(free) = u(free) + rem * a(free)/max(sum(a(free)), 1e-12);
        end
        u = min(u, Pmax);
        rem = E - sum(u);                                        % residuo: llenado de valles
        if rem > 1e-9
            [~, idx] = sort(nd);
            for k = 1:24
                if rem <= 1e-9, break; end
                q = min(Pmax - u(idx(k)), rem); u(idx(k)) = u(idx(k)) + q; rem = rem - q;
            end
        end
    otherwise
        error('EMS no reconocido: %s', opt.ems);
end
end
