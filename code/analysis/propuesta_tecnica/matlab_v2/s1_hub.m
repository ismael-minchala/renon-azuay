%S1_HUB Modelo vectorial: linea base, NSGA-II con 7 variables (V2G),
%   indicadores por vector, matriz de acoplamiento y sensibilidad V2G.
setup_v2; tic;
fprintf('=== S1: modelo vectorial (energy hub) ===\n');

%% Linea base 2024
P0 = renon_params_v2('base2024'); S0 = renon_profiles(P0, 1);
x0 = [P0.pv0, P0.wind0, 0, 0, 0, 0, 0];
R0 = renon_hub(x0, P0, S0);
fprintf('[Base] CO2=%.0f kt, costo=%.1f MUSD, FR=%.1f%%, kappa=%.3f\n', R0.co2, R0.costo, 100*R0.frac_ren, R0.kappa);

%% NSGA-II 7 variables (2030, 2050) y comparacion con v1 (6 variables)
esc = {'lc2030','lc2050'}; etq = {'2030','2050'};
npop = 48; ngen = 60; res = struct();
for e = 1:2
    P = renon_params_v2(esc{e}); S = renon_profiles(P, 1);
    fun = @(x) obj_hub(x, P, S);
    fprintf('[NSGA-II %s, 7 var] ...\n', etq{e});
    [Xnd, Fnd] = nsga2_simple(fun, P.lb, P.ub, npop, ngen, 7+e);
    Fn = (Fnd - min(Fnd)) ./ max(max(Fnd)-min(Fnd), eps);
    [~, ik] = min(vecnorm(Fn,2,2));
    xk = Xnd(ik,:); Rk = renon_hub(xk, P, S);
    % frente v1 (6 variables) evaluado con el mismo modelo (f_g = 0)
    T1 = readtable(fullfile(rootDir,'..','resultados',sprintf('pareto_%s.csv',etq{e})));
    F1 = [T1.CO2_kt, T1.Costo_MUSD];
    ref = [1.05*max([Fnd(:,1);F1(:,1)]), 1.05*max([Fnd(:,2);F1(:,2)])];
    res(e).P = P; res(e).S = S; res(e).Xnd = Xnd; res(e).Fnd = Fnd; res(e).xk = xk; res(e).Rk = Rk;
    res(e).F1 = F1; res(e).hv = [hv2d(F1,ref), hv2d(Fnd,ref)]; res(e).ref = ref;
    fprintf('  rodilla %s: FV=%.0f Eol=%.0f Bat=%.0f Hid+=%.0f fa=%.2f fv=%.2f fg=%.2f | CO2=%.0f costo=%.1f | HV v1=%.0f v2=%.0f\n', ...
        etq{e}, xk(1), xk(2), xk(3), xk(4), xk(5), xk(6), xk(7), Rk.co2, Rk.costo, res(e).hv(1), res(e).hv(2));
    Tp = array2table([Xnd, Fnd], 'VariableNames', {'FV_MW','Eolica_MW','Bateria_MWh','HidroNueva_MW','fFlexAgua','fSmartVE','fV2G','CO2_kt','Costo_MUSD'});
    writetable(Tp, fullfile(resDir, sprintf('pareto_v2_%s.csv', etq{e})));
end

% Figura 1: frentes v1 vs v2
f = figure('Position',[100 100 950 400]);
for e = 1:2
    subplot(1,2,e);
    plot(res(e).F1(:,1), res(e).F1(:,2), 's--','Color',co(5,:),'MarkerFaceColor',co(5,:),'MarkerSize',4); hold on;
    plot(res(e).Fnd(:,1), res(e).Fnd(:,2), 'o-','Color',co(1,:),'MarkerFaceColor',co(1,:),'MarkerSize',4);
    plot(res(e).Rk.co2, res(e).Rk.costo, 'p','MarkerSize',14,'MarkerFaceColor',co(2,:),'MarkerEdgeColor','k');
    grid on; xlabel('CO_2 total (kt/anio)'); ylabel('Costo anual (MUSD/anio)');
    title(sprintf('Frente de Pareto %s (HV: v1 %.0f | v2 %.0f)', etq{e}, res(e).hv(1), res(e).hv(2)));
    legend({'v1: 6 variables','v2: 7 variables (V2G)','Compromiso v2'},'Location','northeast');
end
exportgraphics(f, fullfile(figDir,'fig_v2_1_pareto.png'), 'Resolution', 150);

%% Figura 2: matrices de acoplamiento C
f = figure('Position',[100 100 1100 330]);
RR = {R0, res(1).Rk, res(2).Rk}; tt = {'Base 2024','Compromiso 2030','Compromiso 2050'};
for k = 1:3
    subplot(1,3,k); C = RR{k}.C;
    imagesc(C, [0 1]); colormap(flipud(bone)); hold on;
    for i = 1:3, for j = 1:6
        txt = sprintf('%.2f', C(i,j)); col = 'k'; if C(i,j) > 0.55, col = 'w'; end
        text(j, i, txt, 'HorizontalAlignment','center','Color',col,'FontSize',8);
    end, end
    set(gca,'XTick',1:6,'XTickLabel',RR{k}.portadores,'YTick',1:3,'YTickLabel',RR{k}.servicios,'XTickLabelRotation',30);
    title(tt{k});
end
exportgraphics(f, fullfile(figDir,'fig_v2_2_hub_C.png'), 'Resolution', 150);

%% Figura 3: indicadores por vector
f = figure('Position',[100 100 950 380]);
subplot(1,2,1);
M = [R0.vec.co2_kt; res(1).Rk.vec.co2_kt; res(2).Rk.vec.co2_kt];
b = bar(M, 'grouped'); for k=1:3, b(k).FaceColor = co(k,:); end
set(gca,'XTickLabel',tt); ylabel('ktCO_2/anio'); legend(R0.servicios,'Location','northeast'); grid on;
title('Emisiones por vector');
subplot(1,2,2);
M = [R0.vec.costo_MUSD; res(1).Rk.vec.costo_MUSD; res(2).Rk.vec.costo_MUSD];
b = bar(M, 'grouped'); for k=1:3, b(k).FaceColor = co(k,:); end
set(gca,'XTickLabel',tt); ylabel('MUSD/anio'); legend(R0.servicios,'Location','northwest'); grid on;
title('Costo anual asignado por vector');
exportgraphics(f, fullfile(figDir,'fig_v2_3_vectores.png'), 'Resolution', 150);

%% Sensibilidad V2G bajo sequia extrema (rodilla 2030)
P = res(1).P; xk = res(1).xk;
S_st = renon_profiles(P, 1); mask = S_st.mes >= 10;
S_st.cf_hyd(mask) = 0.5*S_st.cf_hyd(mask); S_st.ef_grid(mask) = 1.5*S_st.ef_grid(mask);
S_st.prec_imp(mask) = 1.8*S_st.prec_imp(mask); P_st = P; P_st.cap_imp = 0.7*P.cap_imp;
fg = 0:0.1:1; sens = zeros(numel(fg), 6);
for i = 1:numel(fg)
    xi = xk; xi(7) = fg(i);
    Rn = renon_hub(xi, P, res(1).S); Rs = renon_hub(xi, P_st, S_st);
    sens(i,:) = [Rn.co2, Rn.costo, Rs.ens, Rs.costo, Rs.resiliencia, Rs.E_v2g];
end
Ts = array2table([fg', sens], 'VariableNames', {'fV2G','CO2_kt','Costo_MUSD','ENS_sequia_MWh','Costo_sequia_MUSD','Resil_sequia','E_v2g_GWh'});
writetable(Ts, fullfile(resDir,'v2g_sensibilidad.csv'));
f = figure('Position',[100 100 950 360]);
subplot(1,2,1); yyaxis left; plot(fg, sens(:,3)/1e3,'o-','LineWidth',1.3); ylabel('ENS bajo sequia (GWh)');
yyaxis right; plot(fg, sens(:,4),'s-','LineWidth',1.3); ylabel('Costo bajo sequia (MUSD)'); grid on; xlabel('f_g (fraccion V2G)');
title('Valor de resiliencia del V2G (sequia extrema)');
subplot(1,2,2); yyaxis left; plot(fg, sens(:,1),'o-','LineWidth',1.3); ylabel('CO_2 anio tipo (kt)');
yyaxis right; plot(fg, sens(:,2),'s-','LineWidth',1.3); ylabel('Costo anio tipo (MUSD)'); grid on; xlabel('f_g (fraccion V2G)');
title('Costo del V2G en anio tipo');
exportgraphics(f, fullfile(figDir,'fig_v2_4_v2g.png'), 'Resolution', 150);

%% Tabla resumen por vector
nom = {'Base 2024';'Compromiso 2030';'Compromiso 2050'};
xx = [x0; res(1).xk; res(2).xk];
T = table(nom, xx(:,1), xx(:,2), xx(:,3), xx(:,4), xx(:,5), xx(:,6), xx(:,7), ...
    cellfun(@(r) r.co2, RR)', cellfun(@(r) r.costo, RR)', 100*cellfun(@(r) r.frac_ren, RR)', cellfun(@(r) r.kappa, RR)', ...
    cell2mat(cellfun(@(r) r.vec.E_GWh, RR,'UniformOutput',false)'), ...
    cell2mat(cellfun(@(r) r.vec.co2_kt, RR,'UniformOutput',false)'), ...
    cell2mat(cellfun(@(r) r.vec.costo_MUSD, RR,'UniformOutput',false)'), ...
    'VariableNames', {'Escenario','FV_MW','Eolica_MW','Bateria_MWh','HidroNueva_MW','fFlexAgua','fSmartVE','fV2G', ...
    'CO2_kt','Costo_MUSD','FR_pct','kappa','E_vec_GWh','CO2_vec_kt','Costo_vec_MUSD'});
writetable(T, fullfile(resDir,'resumen_v2.csv'));
for k = 1:3
    writematrix(RR{k}.C, fullfile(resDir, sprintf('hub_C_%d.csv', k)));
end
hvT = table(etq', [res(1).hv(1); res(2).hv(1)], [res(1).hv(2); res(2).hv(2)], 'VariableNames', {'Horizonte','HV_v1','HV_v2'});
writetable(hvT, fullfile(resDir,'hv_v1_v2.csv'));
save(fullfile(resDir,'s1_hub.mat'), 'R0','res','sens','fg','x0');
fprintf('=== S1 completado en %.0f s ===\n', toc);
