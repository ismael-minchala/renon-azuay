%S5_ATTENTION_EMS EMS con mecanismo de atencion temporal, sintonizado con DOA.
setup_v2; tic;
fprintf('=== S5: EMS con atencion temporal ===\n');
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
xk = [255.3 150 0 30 0.332 0.838 0];                       % compromiso 2030 (v1)
lam = 0.2;                                                 % MUSD por kt en el escalar J
Jems = @(R) R.costo + lam*R.co2;

R_v = renon_hub(xk, P, S);                                  % llenado de valles (v1)
o0.ems = 'attention'; o0.theta = P.theta_default;
R_a0 = renon_hub(xk, P, S, o0);
fprintf('  valley: CO2=%.2f costo=%.2f J=%.2f | atencion(defecto): CO2=%.2f costo=%.2f J=%.2f\n', ...
    R_v.co2, R_v.costo, Jems(R_v), R_a0.co2, R_a0.costo, Jems(R_a0));
fprintf('  balance: demanda servida valley=%.3f GWh, atencion=%.3f GWh\n', R_v.dem_total, R_a0.dem_total);

%% Sintonizacion de theta con DOA
fth = @(th) Jems(renon_hub(xk, P, S, struct('ems','attention','theta',th)));
lbt = [0 0 0 0.02]; ubt = [3 3 3 2];
[th_opt, J_opt, h_th, nev] = doa(fth, lbt, ubt, 20, 15, 5);
o1.ems = 'attention'; o1.theta = th_opt;
R_a1 = renon_hub(xk, P, S, o1);
fprintf('  atencion sintonizada (DOA, %d evals): theta=%s | CO2=%.2f costo=%.2f J=%.2f | demanda=%.3f GWh\n', nev, mat2str(th_opt,3), R_a1.co2, R_a1.costo, J_opt, R_a1.dem_total);

%% Sequia extrema
S_st = renon_profiles(P, 1); mask = S_st.mes >= 10;
S_st.cf_hyd(mask) = 0.5*S_st.cf_hyd(mask); S_st.ef_grid(mask) = 1.5*S_st.ef_grid(mask);
S_st.prec_imp(mask) = 1.8*S_st.prec_imp(mask); P_st = P; P_st.cap_imp = 0.7*P.cap_imp;
Rs_v = renon_hub(xk, P_st, S_st); Rs_a0 = renon_hub(xk, P_st, S_st, o0); Rs_a1 = renon_hub(xk, P_st, S_st, o1);

Tems = table({'Llenado de valles (v1)';'Atencion (theta por defecto)';'Atencion sintonizada (DOA)'}, ...
    [R_v.co2; R_a0.co2; R_a1.co2], [R_v.costo; R_a0.costo; R_a1.costo], [Jems(R_v); Jems(R_a0); Jems(R_a1)], ...
    [R_v.imp; R_a0.imp; R_a1.imp], [R_v.vert; R_a0.vert; R_a1.vert]/1e3, ...
    [Rs_v.ens; Rs_a0.ens; Rs_a1.ens]/1e3, [Rs_v.costo; Rs_a0.costo; Rs_a1.costo], ...
    'VariableNames', {'EMS','CO2_kt','Costo_MUSD','J','Import_GWh','Vertimiento_GWh','ENS_sequia_GWh','Costo_sequia_MUSD'});
disp(Tems); writetable(Tems, fullfile(resDir,'ems_atencion.csv'));

%% Escenario con senales intradiarias: tarifa horaria y FE marginal horario del SNI
% Precio: valle 0-6h x0,7; punta 18-22h x1,6. FE marginal: mediodia x0,8 (hidro+FV
% en el SNI), punta 18-22h x1,4 (despacho termico), resto x1,0.
hod = S.hod;
m_pr = ones(size(hod)); m_pr(hod <= 6) = 0.7; m_pr(hod >= 18 & hod <= 22) = 1.6;
m_ef = ones(size(hod)); m_ef(hod >= 10 & hod <= 15) = 0.8; m_ef(hod >= 18 & hod <= 22) = 1.4;
S_tou = S; S_tou.prec_imp = S.prec_imp .* m_pr; S_tou.ef_grid = S.ef_grid .* m_ef;
Rt_v = renon_hub(xk, P, S_tou); Rt_a0 = renon_hub(xk, P, S_tou, o0);
ftou = @(th) Jems(renon_hub(xk, P, S_tou, struct('ems','attention','theta',th)));
[th_tou, J_tou, ~, nev2] = doa(ftou, lbt, ubt, 20, 15, 6);
o2.ems = 'attention'; o2.theta = th_tou; Rt_a1 = renon_hub(xk, P, S_tou, o2);
fprintf('  [TOU] valley: CO2=%.2f costo=%.2f J=%.2f | atencion DOA (%d evals) theta=%s: CO2=%.2f costo=%.2f J=%.2f\n', ...
    Rt_v.co2, Rt_v.costo, Jems(Rt_v), nev2, mat2str(th_tou,3), Rt_a1.co2, Rt_a1.costo, J_tou);
Ttou = table({'Llenado de valles (v1)';'Atencion (theta por defecto)';'Atencion sintonizada (DOA)'}, ...
    [Rt_v.co2; Rt_a0.co2; Rt_a1.co2], [Rt_v.costo; Rt_a0.costo; Rt_a1.costo], [Jems(Rt_v); Jems(Rt_a0); Jems(Rt_a1)], ...
    [Rt_v.imp; Rt_a0.imp; Rt_a1.imp], [Rt_v.vert; Rt_a0.vert; Rt_a1.vert]/1e3, ...
    'VariableNames', {'EMS','CO2_kt','Costo_MUSD','J','Import_GWh','Vertimiento_GWh'});
disp(Ttou); writetable(Ttou, fullfile(resDir,'ems_atencion_tou.csv'));
writetable(table({'alpha';'beta';'gamma';'tau'}, th_opt', th_tou', 'VariableNames', {'parametro','anio_tipo','tarifa_horaria'}), fullfile(resDir,'ems_atencion_theta.csv'));

%% Figura: pesos de atencion en dos dias tipo
dias = [15*24, 288*24];  ttl = {'Dia humedo (enero)','Dia de estiaje (octubre)'};
f = figure('Position',[100 100 1000 620]);
for k = 1:2
    idx = dias(k) + (1:24);
    subplot(2,2,k);
    yyaxis left;
    plot(0:23, Rt_v.s.net0(idx), 'k-', 'LineWidth', 1.3); hold on;
    bb = bar(0:23, [Rt_v.s.flex_w(idx)+Rt_v.s.flex_m(idx), Rt_a1.s.flex_w(idx)+Rt_a1.s.flex_m(idx)], 'grouped');
    bb(1).FaceColor = co(5,:); bb(2).FaceColor = co(3,:);
    ylabel('MW'); yyaxis right; plot(0:23, S_tou.ef_grid(idx), '--', 'LineWidth', 1.0); ylabel('FE SNI (tCO_2/MWh)');
    grid on; xlabel('hora'); title([ttl{k} ' - tarifa horaria']); xlim([-0.5 23.5]);
    legend({'Carga neta (sin flexibles)','Flexibles: valles','Flexibles: atencion (DOA)','FE marginal horario'},'Location','northwest','FontSize',7);
end
subplot(2,2,3);
M = 100*([R_a1.co2 Rt_a1.co2; R_a1.costo Rt_a1.costo; R_a1.imp Rt_a1.imp] ./ [R_v.co2 Rt_v.co2; R_v.costo Rt_v.costo; R_v.imp Rt_v.imp] - 1);
b = bar(M, 'grouped'); b(1).FaceColor = co(1,:); b(2).FaceColor = co(3,:);
set(gca,'XTickLabel',{'CO_2','Costo','Importacion'}); ylabel('cambio vs. llenado de valles (%)');
legend({'Senales mensuales (anio tipo)','Tarifa y FE horarios'},'Location','southwest'); grid on;
title('Atencion sintonizada (DOA): cambio relativo');
subplot(2,2,4);
M = [Rs_v.ens Rs_a0.ens Rs_a1.ens]/1e3;
b = bar(M); b.FaceColor = 'flat'; b.CData = co(1:3,:); set(gca,'XTickLabel',{'Valles','Atencion defecto','Atencion DOA'}); grid on;
ylabel('ENS (GWh)'); title('Energia no suministrada bajo sequia extrema');
exportgraphics(f, fullfile(figDir,'fig_v2_13_ems_atencion.png'), 'Resolution', 150);
save(fullfile(resDir,'s5_attention.mat'), 'th_opt','J_opt','h_th','R_v','R_a0','R_a1','Rs_v','Rs_a0','Rs_a1','th_tou','Rt_v','Rt_a0','Rt_a1');
fprintf('=== S5 completado en %.0f s ===\n', toc);
