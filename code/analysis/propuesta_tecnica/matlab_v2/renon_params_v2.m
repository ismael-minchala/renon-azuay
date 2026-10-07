function P = renon_params_v2(escenario)
%RENON_PARAMS_V2 Parametros del modelo vectorial ReNoN-Azuay (v2).
%   Extiende renon_params (v1) con:
%     - vehiculo-a-red (V2G) como septima variable de decision f_g;
%     - parametros del EMS con mecanismo de atencion temporal;
%     - factores de emision del SNI revisados con el diagnostico nacional
%       2003-2024 (Ortega, Minchala y Arevalo, Electronics 2026,
%       doi:10.3390/electronics15163697): perfil estacional del factor de
%       emision del despacho termico en estiaje.
%   x = [P_pv, P_wind, E_bat, P_hyd_nueva, f_flex_agua, f_smart_ev, f_v2g]

P = renon_params(escenario);
P.version = 'v2-vectorial';

% ---------------- Vehiculo-a-red (V2G) --------------------------------
P.p_plug     = 3.3e-3;   % MW por cargador bidireccional (3,3 kW)
P.disp_v2g   = 0.30;     % fraccion de VE conectados en el pico vespertino
P.frac_E_v2g = 0.20;     % max. fraccion de la energia diaria VE que se descarga
P.eta_v2g    = 0.85;     % eficiencia de ciclo descarga-recarga
P.c_v2g      = 60;       % USD/MWh degradacion de bateria por V2G
P.c_v2g_cap  = 150;      % USD/anio por VE con cargador bidireccional (anualizado)
P.h_v2g      = [18 22];  % ventana horaria de descarga V2G

% ---------------- EMS: atencion temporal ------------------------------
% theta = [alpha (carga neta), beta (factor emision), gamma (precio), tau]
P.theta_default = [1.0 1.0 1.0 0.30];

% ---------------- Limites (7 variables) -------------------------------
P.lb = [P.lb, 0];
P.ub = [P.ub, 1];
P.nombres_x = {'P_{pv} (MW)','P_{w} (MW)','E_{b} (MWh)','P_{h}^{+} (MW)', ...
               'f_a','f_v','f_g'};
end
