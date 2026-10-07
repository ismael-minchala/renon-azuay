%REPRODUCE_REPORT_V2 Regenerate every result of reporte_tecnico_renon_v2.pdf.
%
%   Runs the five experiments of matlab_v2/ in order (fixed seeds):
%     s1_hub            vectorial model, NSGA-II 7 variables, coupling matrix C,
%                       per-vector indicators, V2G sensitivity   -> Tabla 5, figs v2_1..v2_4
%     s2_autoencoder    autoencoder vs PCA, latent scenario generator,
%                       Monte Carlo                              -> Tabla 6, fig v2_5
%     s3_surrogates     KAN / MLP / attention surrogates, KAN-assisted NSGA-II
%                                                                -> Tabla 7, figs v2_6..v2_10
%     s4_doa            DOA vs GA vs PSO vs random; Tchebycheff front
%                                                                -> Tabla 8, figs v2_11, v2_12
%     s5_attention_ems  attention EMS tuned with DOA, TOU scenario -> Tabla 9, fig v2_13
%   Outputs: CSV and .mat in resultados_v2/, figures in reporte/figs_v2/.
%
%   Requirements: Deep Learning, Statistics and Machine Learning, Optimization
%   and Global Optimization Toolboxes. Parallel Computing Toolbox is optional
%   (s4 opens a process pool when available; otherwise parfor runs serially).
%   s1 reads resultados/pareto_2030.csv and pareto_2050.csv (v1 reference
%   outputs shipped with the repository; regenerate with reproduce_report_v1).
%
%   Runtime: about 3.5 min on 12 workers (R2026a, Apple M-series); the training
%   steps of s2/s3 dominate when run serially.
%
%   Set SKIP = {'s4_doa'} (for example) before running to omit experiments.
%
%   See also REPRODUCE_REPORT_V1, RUN_RENON_MODEL, INIT_RENON_MODEL.

env_ = init_renon_model(struct('verbose', true));
if ~env_.has_v2
    error('reproduce_report_v2:toolboxes', ...
        'The v2 experiments need Deep Learning, Statistics and ML, Optimization and Global Optimization Toolboxes.');
end
if ~env_.v1_pareto_present
    fprintf('v1 Pareto fronts missing: running reproduce_report_v1 first.\n');
    reproduce_report_v1;
    env_ = init_renon_model(struct('verbose', false));
end
if ~exist('SKIP', 'var'), SKIP = {}; end
scripts_ = {'s1_hub', 's2_autoencoder', 's3_surrogates', 's4_doa', 's5_attention_ems'};
t_all_ = tic;
for k_ = 1:numel(scripts_)
    if any(strcmp(scripts_{k_}, SKIP)), fprintf('--- skipping %s ---\n', scripts_{k_}); continue; end
    fprintf('\n--- %s ---\n', scripts_{k_});
    run(fullfile(env_.matlab_v2, [scripts_{k_} '.m']));
end
set(0, 'DefaultFigureVisible', 'on');     % setup_v2 hides figures while exporting
fprintf('\n=== reproduce_report_v2 done in %.0f s. CSV in resultados_v2/, figures in reporte/figs_v2/ ===\n', toc(t_all_));
