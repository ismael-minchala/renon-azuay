function P = renon_params(escenario)
%RENON_PARAMS Parametros del modelo multivectorial ReNoN-Azuay.
%   P = RENON_PARAMS(ESCENARIO) devuelve la estructura de parametros para
%   'base2024', 'lc2030' o 'lc2050'.
%
%   Fuentes principales:
%   - Reporte tecnico PT1 (30/01/2025): capacidades del parque generador
%     ecuatoriano 2003-2022 (hidro 5191 MW, eolica 53 MW, FV 29 MW, etc.)
%     y concepto de vulnerabilidad hidrica (Hydroverfuegbarkeitserzeugung).
%   - Formulario 2 v2 (propuesta XXII Concurso): metas 2030/2050 de
%     penetracion renovable, electrificacion del transporte y resiliencia.
%   - Viesi et al. (2020), Energy 209:118378: estructura metodologica
%     (simulacion horaria anual + optimizacion multiobjetivo CO2/costo).
%   Los valores provinciales (Azuay) son estimaciones documentadas en el
%   reporte tecnico de esta propuesta; seran calibrados con datos de
%   CENTROSUR, ETAPA y GAD Cuenca durante el PT1.

P.escenario = escenario;
P.H = 8760;                       % horas del anio tipo

% ---------------- Demanda electrica "pura" (sin agua ni VE) -----------
switch escenario
    case 'base2024'
        P.E_dem   = 1300e3;       % MWh/anio, area de servicio Azuay (aprox CENTROSUR)
        P.flota   = 130e3;        % vehiculos livianos en la provincia
        P.x_ev    = 0.01;         % penetracion actual de VE (marginal)
        P.vol_agua= 2.2;          % m3/s produccion media de agua potable (ETAPA)
        P.cap_imp = 250;          % MW capacidad de importacion desde el SNI
    case 'lc2030'
        P.E_dem   = 1300e3*1.18;  % crecimiento 2.8%/anio 2024-2030
        P.flota   = 140e3;
        P.x_ev    = 0.25;         % meta 2030 de la propuesta (25% flota urbana)
        P.vol_agua= 2.4;
        P.cap_imp = 250;
    case 'lc2050'
        P.E_dem   = 1300e3*1.80;  % crecimiento medio 2.3%/anio a 2050
        P.flota   = 165e3;
        P.x_ev    = 0.90;         % meta 2050 (80-100% flota electrificada)
        P.vol_agua= 3.2;
        P.cap_imp = 350;          % refuerzo de interconexion previsto
    otherwise
        error('Escenario no reconocido: %s', escenario);
end

% ---------------- Parque local existente (vector electricidad) --------
P.hyd0  = 40;    % MW hidro de pasada local (Saucay + Saymirin, Elecaustro)
P.wind0 = 50;    % MW eolico existente (Minas de Huascachaca)
P.pv0   = 5;     % MW FV distribuida existente (estimado)
P.P_th  = 20;    % MW termica local de respaldo (MCI El Descanso)
P.ef_th = 0.70;  % tCO2/MWh termica MCI
P.c_th  = 190;   % USD/MWh costo variable termica

% ---------------- Vector agua potable ---------------------------------
P.frac_bombeo = 0.25;   % fraccion del volumen que requiere bombeo
P.e_bombeo    = 0.40;   % kWh/m3 energia especifica de bombeo
P.e_trat      = 0.06;   % kWh/m3 tratamiento (toda el agua)
P.horas_tanque= 12;     % autonomia de tanques -> bombeo diferible en el dia

% ---------------- Vector movilidad electrica --------------------------
P.km_anio  = 11000;     % km/anio por vehiculo liviano
P.e_km     = 0.20;      % kWh/km desde red (incluye eficiencia de carga)
P.ef_ice   = 0.25e-3;   % tCO2/km vehiculo de combustion interna

% ---------------- Red nacional (SNI): emisiones y precios -------------
% Factor de emision estacional: bajo en epoca humeda (despacho hidro),
% alto en estiaje oct-dic por despacho termico e importaciones
% (vulnerabilidad documentada en el reporte tecnico PT1).
P.ef_mes    = [0.10 0.08 0.08 0.08 0.10 0.12 0.15 0.20 0.25 0.35 0.35 0.28]; % tCO2/MWh
P.prec_mes  = [55 50 50 52 58 65 72 85 95 115 110 90];  % USD/MWh importacion

% ---------------- Perfiles de recurso renovable (factor de planta) ----
% Hidro de pasada: humedo feb-jun, estiaje critico oct-dic
P.cf_hyd_mes  = [0.65 0.72 0.78 0.80 0.78 0.72 0.60 0.45 0.40 0.35 0.38 0.50];
% Eolico: vientos alisios mas intensos jun-sep (zona alta de Azuay)
P.cf_wind_mes = [0.24 0.22 0.22 0.25 0.28 0.34 0.38 0.36 0.32 0.28 0.26 0.24];
% FV: media anual de indice de claridad (Cuenca, GHI ~4.4 kWh/m2/dia)
P.claridad_media = 0.62;

% ---------------- Costos anualizados (CRF, r = 6%) --------------------
% CRF(6%,25a)=0.0782; CRF(6%,12a)=0.1193; CRF(6%,30a)=0.0726
P.c_pv    = 750*0.0782 + 10;    % USD/kW-anio FV (capex 750 USD/kW + O&M)
P.c_wind  = 1300*0.0782 + 30;   % USD/kW-anio eolica
P.c_bat   = 280*0.1193 + 5;     % USD/kWh-anio bateria (12 anios)
P.c_hyd   = 2200*0.0726 + 40;   % USD/kW-anio mini-hidro nueva
P.c_flex_agua = 1.2e6;          % USD/anio por unidad de fraccion flexible (retrofit bombeo+SCADA)
P.c_smart_ev  = 25;             % USD/anio por VE con carga inteligente
P.voll    = 10000;              % USD/MWh energia no suministrada (penalizacion)

% ---------------- Limites de variables de decision --------------------
%  x = [P_pv (MW), P_wind (MW), E_bat (MWh), P_hyd_nueva (MW), f_flex_agua, f_smart_ev]
switch escenario
    case 'lc2050'
        P.lb = [P.pv0, P.wind0, 0, 0, 0, 0];
        P.ub = [600, 300, 800, 60, 0.8, 1.0];
    otherwise
        P.lb = [P.pv0, P.wind0, 0, 0, 0, 0];
        P.ub = [300, 150, 300, 30, 0.8, 1.0];
end
end
