%MAIN_RENON Propuesta tecnica ReNoN-Azuay: simulacion y optimizacion.
%   Ejecuta el flujo completo de la propuesta tecnica:
%     1. Linea base 2024 (parque existente, sin flexibilidad).
%     2. Verificacion del generador de perfiles (NRMSE, Pearson).
%     3. Optimizacion multiobjetivo NSGA-II para 2030 y 2050
%        (min CO2, min costo anual) -> frentes de Pareto.
%     4. Seleccion de solucion de compromiso (punto de rodilla).
%     5. Prueba de estres de sequia (Hydroverfuegbarkeitserzeugung) y
%        analisis Monte Carlo de incertidumbre.
%     6. Exporta figuras (reporte/figs) y tablas CSV (resultados/).

clear; clc; close all;
tic;
rootDir = fileparts(mfilename('fullpath'));
resDir = fullfile(rootDir,'..','resultados');
figDir = fullfile(rootDir,'..','reporte','figs');
if ~exist(resDir,'dir'), mkdir(resDir); end
if ~exist(figDir,'dir'), mkdir(figDir); end
co = [0.00 0.35 0.60; 0.85 0.55 0.10; 0.10 0.55 0.25; 0.60 0.20 0.45; 0.45 0.45 0.45];

fprintf('=== ReNoN-Azuay: propuesta tecnica ===\n');

%% 1. Linea base 2024 --------------------------------------------------
P0 = renon_params('base2024');
S0 = renon_profiles(P0, 1);
x0 = [P0.pv0, P0.wind0, 0, 0, 0, 0];
R0 = renon_dispatch(x0, P0, S0);
fprintf('[Base 2024] CO2 = %.0f kt (elec %.0f + transp %.0f), costo = %.1f MUSD, FR = %.1f%%, ENS = %.1f MWh\n', ...
    R0.co2, R0.co2_elec, R0.co2_transp, R0.costo, 100*R0.frac_ren, R0.ens);

% Figura 1: perfiles de una semana tipo (semana 41, estiaje)
h0 = (40*7*24)+(1:7*24); t = (1:numel(h0))/24;
f = figure('Visible','off','Position',[100 100 900 420]);
plot(t, S0.dem_e(h0),'-','Color',co(1,:),'LineWidth',1.2); hold on;
plot(t, P0.hyd0*S0.cf_hyd(h0),'-','Color',co(3,:),'LineWidth',1.2);
plot(t, P0.wind0*S0.cf_wind(h0),'-','Color',co(2,:),'LineWidth',1.2);
plot(t, 100*S0.cf_pv(h0),'-','Color',co(4,:),'LineWidth',1.2);
grid on; xlabel('dia de la semana tipo (estiaje, octubre)'); ylabel('MW');
legend({'Demanda electrica','Hidro local (40 MW)','Eolica (50 MW)','FV (por 100 MW)'},'Location','northwest');
title('Perfiles horarios sinteticos - semana tipo de estiaje');
exportgraphics(f, fullfile(figDir,'fig1_perfiles.png'), 'Resolution', 150);

%% 2. Verificacion del generador de demanda ----------------------------
nrmse = sqrt(mean((S0.dem_e - S0.dem_ref).^2))/mean(S0.dem_ref);
rho = corr(S0.dem_e, S0.dem_ref);
fprintf('[Verificacion] NRMSE = %.2f%% (meta <15%%), Pearson = %.3f (meta >0.85)\n', 100*nrmse, rho);

f = figure('Visible','off','Position',[100 100 900 380]);
hsel = (12*7*24)+(1:3*24); % 3 dias de marzo
plot((1:numel(hsel))/24, S0.dem_ref(hsel),'-','Color',co(5,:),'LineWidth',1.6); hold on;
plot((1:numel(hsel))/24, S0.dem_e(hsel),'-','Color',co(1,:),'LineWidth',1.0);
grid on; xlabel('dia'); ylabel('MW');
legend({'Curva de referencia (forma tipica)','Perfil simulado'},'Location','best');
title(sprintf('Verificacion del modelo de demanda: NRMSE = %.1f%% | r = %.3f', 100*nrmse, rho));
exportgraphics(f, fullfile(figDir,'fig2_validacion.png'), 'Resolution', 150);

%% 3. Optimizacion multiobjetivo 2030 y 2050 ---------------------------
escenarios = {'lc2030','lc2050'};
etq = {'2030','2050'};
npop = 48; ngen = 60;
res = struct();
for e = 1:2
    P = renon_params(escenarios{e});
    S = renon_profiles(P, 1);
    fun = @(x) objetivos(x, P, S);
    fprintf('[NSGA-II %s] pob=%d, gen=%d ...\n', etq{e}, npop, ngen);
    [Xnd, Fnd] = nsga2_simple(fun, P.lb, P.ub, npop, ngen, 7+e);
    % punto de rodilla: min distancia al punto ideal (frente normalizado)
    Fn = (Fnd - min(Fnd)) ./ max(max(Fnd)-min(Fnd), eps);
    [~, ik] = min(vecnorm(Fn,2,2));
    xk = Xnd(ik,:);
    Rk = renon_dispatch(xk, P, S);
    res(e).P = P; res(e).S = S; res(e).Xnd = Xnd; res(e).Fnd = Fnd;
    res(e).xk = xk; res(e).Rk = Rk;
    fprintf('  rodilla %s: FV=%.0f MW, Eol=%.0f MW, Bat=%.0f MWh, Hid+=%.0f MW, fAgua=%.2f, fVE=%.2f\n', ...
        etq{e}, xk(1), xk(2), xk(3), xk(4), xk(5), xk(6));
    fprintf('  CO2 = %.0f kt (%.0f%% vs base), costo = %.1f MUSD, FR = %.1f%%\n', ...
        Rk.co2, 100*(Rk.co2/R0.co2-1), Rk.costo, 100*Rk.frac_ren);
end

% Figura 3: frentes de Pareto
f = figure('Visible','off','Position',[100 100 900 420]);
for e = 1:2
    subplot(1,2,e);
    plot(res(e).Fnd(:,1), res(e).Fnd(:,2), 'o-','Color',co(1,:),'MarkerFaceColor',co(1,:),'MarkerSize',4); hold on;
    Fk = objetivos(res(e).xk, res(e).P, res(e).S);
    plot(Fk(1), Fk(2), 'p','MarkerSize',14,'MarkerFaceColor',co(2,:),'MarkerEdgeColor','k');
    plot(R0.co2, R0.costo, 's','MarkerSize',10,'MarkerFaceColor',co(5,:),'MarkerEdgeColor','k');
    grid on; xlabel('CO_2 total (kt/anio)'); ylabel('Costo anual total (MUSD/anio)');
    title(sprintf('Frente de Pareto %s', etq{e}));
    legend({'Frente no dominado','Solucion de compromiso','Linea base 2024'},'Location','northeast');
end
exportgraphics(f, fullfile(figDir,'fig3_pareto.png'), 'Resolution', 150);

% Figura 4: despacho semana de estiaje, solucion 2030
Rk = res(1).Rk; S = res(1).S;
f = figure('Visible','off','Position',[100 100 950 460]);
hh = h0;
A = [Rk.s.gen_hyd(hh), Rk.s.gen_wind(hh), Rk.s.gen_pv(hh), max(Rk.s.bat(hh),0), Rk.s.imp(hh), Rk.s.th(hh)];
ar = area((1:numel(hh))/24, A); hold on;
colores_area = [co(3,:); co(2,:); co(4,:); 0.3 0.7 0.9; co(5,:); 0.8 0.2 0.2];
for k = 1:6, ar(k).FaceColor = colores_area(k,:); ar(k).EdgeColor = 'none'; end
plot((1:numel(hh))/24, Rk.s.carga(hh), 'k-','LineWidth',1.4);
grid on; xlabel('dia de la semana tipo (estiaje)'); ylabel('MW');
legend({'Hidro','Eolica','FV','Bateria (desc.)','Importacion SNI','Termica local','Carga total'}, ...
    'Location','northwest','NumColumns',2);
title('Despacho EMS - solucion de compromiso 2030, semana de estiaje');
exportgraphics(f, fullfile(figDir,'fig4_despacho.png'), 'Resolution', 150);

% Figura 5: capacidades optimas
f = figure('Visible','off','Position',[100 100 700 400]);
cap = [x0(1) res(1).xk(1) res(2).xk(1); x0(2) res(1).xk(2) res(2).xk(2); ...
       x0(3) res(1).xk(3) res(2).xk(3); P0.hyd0+x0(4) P0.hyd0+res(1).xk(4) P0.hyd0+res(2).xk(4)];
b = bar(cap, 'grouped');
for k = 1:3, b(k).FaceColor = co(k,:); end
set(gca,'XTickLabel',{'FV (MW)','Eolica (MW)','Bateria (MWh)','Hidro local (MW)'});
legend({'Base 2024','Compromiso 2030','Compromiso 2050'},'Location','northwest');
grid on; ylabel('Capacidad'); title('Expansion optima de capacidad por vector');
exportgraphics(f, fullfile(figDir,'fig5_capacidades.png'), 'Resolution', 150);

%% 4. Prueba de estres de sequia ---------------------------------------
% Hidrologia -50% oct-dic, importacion -30%, FE y precios x1.5/x1.8
fprintf('[Estres de sequia] solucion de compromiso 2030 ...\n');
P = res(1).P; S_st = renon_profiles(P, 1);
mask = S_st.mes >= 10;
S_st.cf_hyd(mask) = 0.5*S_st.cf_hyd(mask);
S_st.ef_grid(mask) = 1.5*S_st.ef_grid(mask);
S_st.prec_imp(mask) = 1.8*S_st.prec_imp(mask);
P_st = P; P_st.cap_imp = 0.7*P.cap_imp;
R_st  = renon_dispatch(res(1).xk, P_st, S_st);
R_st0 = renon_dispatch([P.pv0, P.wind0, 0, 0, 0, 0], P_st, S_st);  % sin ReNoN
fprintf('  Con ReNoN:  resiliencia = %.4f, ENS = %.0f MWh, CO2 = %.0f kt, costo = %.1f MUSD\n', ...
    R_st.resiliencia, R_st.ens, R_st.co2, R_st.costo);
fprintf('  Sin ReNoN:  resiliencia = %.4f, ENS = %.0f MWh, CO2 = %.0f kt, costo = %.1f MUSD\n', ...
    R_st0.resiliencia, R_st0.ens, R_st0.co2, R_st0.costo);

% Figura 6: estres, octubre con y sin ReNoN
f = figure('Visible','off','Position',[100 100 950 420]);
hh2 = (273*24)+(1:14*24); tt = (1:numel(hh2))/24;
subplot(2,1,1);
plot(tt, R_st0.s.imp(hh2)+R_st0.s.th(hh2),'Color',co(5,:),'LineWidth',1.1); hold on;
plot(tt, R_st0.s.ens(hh2),'r-','LineWidth',1.2);
grid on; ylabel('MW'); title('Sequia extrema sin ReNoN (parque 2024)');
legend({'Import.+termica','Energia no suministrada'},'Location','northwest');
subplot(2,1,2);
plot(tt, R_st.s.imp(hh2)+R_st.s.th(hh2),'Color',co(5,:),'LineWidth',1.1); hold on;
plot(tt, R_st.s.ens(hh2),'r-','LineWidth',1.2);
plot(tt, R_st.s.gen_pv(hh2)+R_st.s.gen_wind(hh2),'Color',co(3,:),'LineWidth',1.1);
grid on; ylabel('MW'); xlabel('dia (octubre, quincena critica)');
title('Sequia extrema con configuracion ReNoN 2030');
legend({'Import.+termica','ENS','FV+eolica'},'Location','northwest');
exportgraphics(f, fullfile(figDir,'fig6_estres.png'), 'Resolution', 150);

%% 5. Monte Carlo de incertidumbre (solucion 2030) ---------------------
N = 200;
fprintf('[Monte Carlo] N = %d anios sinteticos ...\n', N);
mc = zeros(N,4); % co2, costo, frac_ren, resiliencia
for i = 1:N
    pert.hyd  = min(max(0.95+0.12*randn,0.55),1.15);
    pert.pv   = min(max(1+0.05*randn,0.85),1.15);
    pert.wind = min(max(1+0.08*randn,0.75),1.25);
    pert.dem  = min(max(1+0.04*randn,0.9),1.12);
    pert.prec = min(max(1+0.15*randn,0.7),1.6);
    Si = renon_profiles(P, 100+i, pert);
    Ri = renon_dispatch(res(1).xk, P, Si);
    mc(i,:) = [Ri.co2, Ri.costo, Ri.frac_ren, Ri.resiliencia];
end
fprintf('  CO2: %.0f kt [P5 %.0f, P95 %.0f] | costo: %.1f MUSD [P5 %.1f, P95 %.1f]\n', ...
    median(mc(:,1)), prctile(mc(:,1),5), prctile(mc(:,1),95), ...
    median(mc(:,2)), prctile(mc(:,2),5), prctile(mc(:,2),95));
fprintf('  FR: %.1f%% mediana | resiliencia >= %.4f (min)\n', 100*median(mc(:,3)), min(mc(:,4)));

f = figure('Visible','off','Position',[100 100 900 380]);
subplot(1,2,1); histogram(mc(:,1), 24, 'FaceColor', co(1,:)); grid on;
xlabel('CO_2 (kt/anio)'); ylabel('frecuencia'); title('Monte Carlo: emisiones (2030)');
subplot(1,2,2); histogram(mc(:,2), 24, 'FaceColor', co(2,:)); grid on;
xlabel('Costo anual (MUSD/anio)'); title('Monte Carlo: costo total (2030)');
exportgraphics(f, fullfile(figDir,'fig7_montecarlo.png'), 'Resolution', 150);

%% 6. Tablas resumen (CSV) ---------------------------------------------
% resumen de escenarios
esc_nom = {'Base 2024'; 'Compromiso 2030'; 'Compromiso 2050'};
RR = {R0, res(1).Rk, res(2).Rk};
xx = [x0; res(1).xk; res(2).xk];
Tesc = table(esc_nom, xx(:,1), xx(:,2), xx(:,3), P0.hyd0+xx(:,4), xx(:,5), xx(:,6), ...
    cellfun(@(r) r.co2, RR)', cellfun(@(r) r.co2_elec, RR)', cellfun(@(r) r.co2_transp, RR)', ...
    cellfun(@(r) r.costo, RR)', 100*cellfun(@(r) r.frac_ren, RR)', ...
    cellfun(@(r) r.imp, RR)', cellfun(@(r) r.dem_total, RR)', ...
    'VariableNames', {'Escenario','FV_MW','Eolica_MW','Bateria_MWh','Hidro_MW', ...
    'fFlexAgua','fSmartVE','CO2_kt','CO2elec_kt','CO2transp_kt','Costo_MUSD', ...
    'FraccionRenov_pct','Import_GWh','Demanda_GWh'});
writetable(Tesc, fullfile(resDir,'resumen_escenarios.csv'));

% frentes de Pareto
for e = 1:2
    Tp = array2table([res(e).Xnd, res(e).Fnd], 'VariableNames', ...
        {'FV_MW','Eolica_MW','Bateria_MWh','HidroNueva_MW','fFlexAgua','fSmartVE','CO2_kt','Costo_MUSD'});
    writetable(Tp, fullfile(resDir, sprintf('pareto_%s.csv', etq{e})));
end

% verificacion, estres y Monte Carlo
Tv = table(100*nrmse, rho, R_st.resiliencia, R_st0.resiliencia, R_st.ens, R_st0.ens, ...
    median(mc(:,1)), prctile(mc(:,1),5), prctile(mc(:,1),95), ...
    median(mc(:,2)), prctile(mc(:,2),5), prctile(mc(:,2),95), 100*median(mc(:,3)), ...
    'VariableNames', {'NRMSE_pct','Pearson','Resil_ReNoN','Resil_sinReNoN','ENS_ReNoN_MWh', ...
    'ENS_sinReNoN_MWh','CO2_med_kt','CO2_P5','CO2_P95','Costo_med','Costo_P5','Costo_P95','FR_med_pct'});
writetable(Tv, fullfile(resDir,'verificacion_estres_mc.csv'));

save(fullfile(resDir,'resultados_renon.mat'), 'R0','res','R_st','R_st0','mc','nrmse','rho','Tesc');
fprintf('=== Completado en %.1f s. Figuras en reporte/figs, tablas en resultados/ ===\n', toc);
