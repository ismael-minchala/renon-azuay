%REPRODUCE_REPORT_V1 Regenerate every result of reporte_tecnico_renon.pdf (v1).
%
%   Runs matlab/main_renon.m, which performs, with fixed seeds:
%     1. baseline 2024 dispatch;
%     2. verification of the demand generator (NRMSE, Pearson)  -> fig2;
%     3. NSGA-II 2030 and 2050 (48 x 60), knee solutions         -> fig3, fig5;
%     4. EMS dispatch of a dry-season week                        -> fig4;
%     5. extreme-drought stress test                              -> fig6;
%     6. Monte Carlo N = 200                                      -> fig7;
%   and writes resultados/{resumen_escenarios,pareto_2030,pareto_2050,
%   verificacion_estres_mc}.csv, resultados/resultados_renon.mat and
%   reporte/figs/fig1..fig7.png. Runtime about 15 s (R2026a, Apple M-series).
%
%   Report v1 tables: Tabla 2 (escenarios) <- resumen_escenarios.csv;
%   Secs. 4.3-4.4 and Tabla 3 <- verificacion_estres_mc.csv.
%
%   Requirements: base MATLAB (R2020b or newer). No toolboxes.
%
%   NOTE: main_renon.m is a script that starts with `clear`, so the base
%   workspace is cleared. Results are saved to resultados/resultados_renon.mat.
%
%   See also REPRODUCE_REPORT_V2, RUN_RENON_MODEL, INIT_RENON_MODEL.

env_ = init_renon_model(struct('verbose', false));
fprintf('=== reproduce_report_v1: running %s ===\n', fullfile(env_.matlab_v1, 'main_renon.m'));
run(fullfile(env_.matlab_v1, 'main_renon.m'));
fprintf('=== reproduce_report_v1 done. CSV in resultados/, figures in reporte/figs/ ===\n');
