function S = renon_profiles(P, semilla, pert)
%RENON_PROFILES Series horarias anuales del modelo ReNoN-Azuay.
%   S = RENON_PROFILES(P, SEMILLA) genera los perfiles horarios (8760 h)
%   de demanda electrica, recurso renovable, factor de emision y precio
%   de la red, y las cargas de agua potable y movilidad electrica.
%   PERT (opcional) es una estructura de perturbaciones multiplicativas
%   para Monte Carlo / pruebas de estres:
%       .hyd, .pv, .wind, .dem, .prec  (escalares, por defecto 1)
%
%   Los perfiles sinteticos reproducen la forma tipica de la curva de
%   carga residencial-comercial del austro ecuatoriano (pico vespertino
%   19-21h), la estacionalidad hidrologica del reporte tecnico PT1 y el
%   recurso solar ecuatorial (12 h de sol constantes todo el anio).

if nargin < 3, pert = struct(); end
def = {'hyd',1;'pv',1;'wind',1;'dem',1;'prec',1};
for k = 1:size(def,1)
    if ~isfield(pert, def{k,1}), pert.(def{k,1}) = def{k,2}; end
end
rng(semilla, 'twister');

H = P.H;
h  = (0:H-1)';
hod = mod(h,24);                          % hora del dia 0-23
dia = floor(h/24);                        % dia 0-364
dow = mod(dia,7);                         % 0=lunes ... 5,6=fin de semana
dias_mes = [31 28 31 30 31 30 31 31 30 31 30 31];
mes_dia  = repelem(1:12, dias_mes)';      % mes de cada dia
mes = mes_dia(dia+1);                     % mes de cada hora

% ---------------- Demanda electrica "pura" ----------------------------
% Curva diaria tipica (24 valores, pu de la media diaria): valle nocturno,
% rampa matinal, meseta diurna y pico vespertino 19-21h.
S.forma_dia = [0.62 0.58 0.56 0.55 0.57 0.66 0.80 0.92 0.98 1.02 1.05 1.07 ...
               1.06 1.04 1.03 1.02 1.05 1.15 1.35 1.48 1.42 1.20 0.95 0.75]';
f_dia  = S.forma_dia(hod+1);
f_sem  = 1 - 0.10*(dow>=5);               % fin de semana -10%
f_mes_dem = 1 + 0.02*cos(2*pi*(mes-3)/12);% leve estacionalidad
ruido_d = 1 + 0.03*randn(H,1);
dem_pu = f_dia.*f_sem.*f_mes_dem.*max(ruido_d,0.8);
S.dem_e = pert.dem * (P.E_dem/sum(dem_pu)) * dem_pu;   % MW (dt=1h)
S.dem_ref = (P.E_dem/sum(f_dia.*f_sem.*f_mes_dem)) * f_dia.*f_sem.*f_mes_dem; % referencia sin ruido

% ---------------- Recurso solar FV (cf 0-1) ---------------------------
elev = cos(pi*(hod-12)/7);                % campana 5h-19h aprox (ecuatorial)
elev(hod<5.5 | hod>18.5) = 0; elev = max(elev,0).^1.4;
% claridad diaria persistente (nubosidad andina) + variacion intradiaria
clar_d = min(max(P.claridad_media + 0.16*randn(365,1),0.15),0.95);
clar = clar_d(dia+1).*(1+0.08*randn(H,1));
S.cf_pv = pert.pv * max(min(elev.*clar,1),0);

% ---------------- Recurso eolico (cf 0-1) -----------------------------
f_hora_w = 0.85 + 0.3*cos(pi*(hod-15)/12).^2;   % mas viento en la tarde-noche
base_w = P.cf_wind_mes(mes)';
% persistencia semanal (frentes de viento)
pers = interp1(0:7:371, min(max(1+0.25*randn(54,1),0.3),1.7), (0:H-1)'/24, 'pchip');
S.cf_wind = pert.wind * max(min(base_w.*f_hora_w.*pers.*(1+0.10*randn(H,1)),1),0);

% ---------------- Recurso hidrico (hidro de pasada, cf 0-1) -----------
base_h = P.cf_hyd_mes(mes)';
pers_h = interp1(0:7:371, min(max(1+0.15*randn(54,1),0.5),1.4), (0:H-1)'/24, 'pchip');
S.cf_hyd = pert.hyd * max(min(base_h.*pers_h,1),0.05);

% ---------------- Red nacional: factor de emision y precio ------------
S.ef_grid  = P.ef_mes(mes)' .* (1+0.05*randn(H,1));
S.ef_grid  = max(S.ef_grid, 0.02);
S.prec_imp = pert.prec * P.prec_mes(mes)' .* (1+0.08*randn(H,1));

% ---------------- Vector agua potable ---------------------------------
vol_h = P.vol_agua*3600;                          % m3/h medio
f_agua = 1 + 0.25*sin(pi*(hod-6)/12).*(hod>=6 & hod<=18); % consumo diurno
vol_hora = vol_h * f_agua/mean(f_agua);           % m3/h
S.p_trat = vol_hora * P.e_trat/1000;              % MW tratamiento (carga fija)
p_bomb   = vol_hora * P.frac_bombeo * P.e_bombeo/1000;  % MW bombeo total
S.E_bomb_dia = sum(p_bomb)/365;                   % MWh/dia de bombeo
S.perfil_bomb_fijo = p_bomb;                      % bombeo no flexible sigue la demanda de agua
S.P_bomb_max = 2.5*mean(p_bomb);                  % MW capacidad de bombeo instalada

% ---------------- Vector movilidad electrica --------------------------
n_ev = P.x_ev * P.flota;
S.E_ev_dia = n_ev * P.km_anio * P.e_km / 365 / 1000;   % MWh/dia
% carga "no inteligente": llegada a casa, pico 18-23h
f_ev = zeros(24,1); f_ev(19:24) = [0.10 0.22 0.26 0.20 0.14 0.08];
S.perfil_ev_fijo = S.E_ev_dia * f_ev(hod+1);           % MW
S.P_ev_max = S.E_ev_dia/6;                             % MW cap. carga inteligente (ventana 6h min)

S.hod = hod; S.dia = dia; S.mes = mes; S.n_ev = n_ev;
end
