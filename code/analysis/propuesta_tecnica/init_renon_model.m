function env = init_renon_model(opts)
%INIT_RENON_MODEL Prepare the MATLAB session for the ReNoN-Azuay model.
%
%   ENV = INIT_RENON_MODEL() adds the model folders to the path, checks the
%   MATLAB release and the toolboxes needed by each model version, creates
%   the output folders and returns a struct with repository-relative paths.
%   Everything is derived from the location of this file, so the model runs
%   right after `git clone` from any working directory.
%
%   ENV = INIT_RENON_MODEL(OPTS) with fields (all optional):
%       .verbose  (true)  print a summary to the command window
%       .strict   (false) error (instead of warn) if a v2 toolbox is missing
%
%   Fields of ENV
%   -------------
%   root        folder of this file (code/analysis/propuesta_tecnica)
%   matlab_v1   v1 model: renon_params, renon_profiles, renon_dispatch, nsga2_simple
%   matlab_v2   v2 model: renon_params_v2, renon_hub, doa, hv2d, surr_lib, s1..s5
%   tests       unit and regression tests (matlab.unittest)
%   resultados  reference outputs of report v1 (CSV)
%   resultados_v2  reference outputs of report v2 (CSV)
%   figs, figs_v2  figure folders used by the report sources
%   has_v1      true: v1 runs with base MATLAB only
%   has_v2      true: all toolboxes required by the v2 experiments are licensed
%   toolboxes   struct of per-toolbox availability flags
%
%   The model has no external data files: all hourly series are generated
%   synthetically by renon_profiles from the parameters in renon_params, so
%   there is nothing to download. The only inter-version dependency is that
%   matlab_v2/s1_hub.m reads resultados/pareto_2030.csv and pareto_2050.csv
%   (reference outputs of v1, shipped with the repository).
%
%   See also RUN_RENON_MODEL, REPRODUCE_REPORT_V1, REPRODUCE_REPORT_V2, RUN_ALL_TESTS.

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'verbose'), opts.verbose = true; end
if ~isfield(opts, 'strict'),  opts.strict  = false; end

env.root          = fileparts(mfilename('fullpath'));
env.matlab_v1     = fullfile(env.root, 'matlab');
env.matlab_v2     = fullfile(env.root, 'matlab_v2');
env.tests         = fullfile(env.root, 'tests');
env.resultados    = fullfile(env.root, 'resultados');
env.resultados_v2 = fullfile(env.root, 'resultados_v2');
env.figs          = fullfile(env.root, 'reporte', 'figs');
env.figs_v2       = fullfile(env.root, 'reporte', 'figs_v2');

% ---- path (idempotent) ------------------------------------------------
addpath(env.root, env.matlab_v1, env.matlab_v2, env.tests);

% ---- output folders ---------------------------------------------------
for d = {env.resultados, env.resultados_v2, env.figs, env.figs_v2}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end

% ---- MATLAB release ---------------------------------------------------
% exportgraphics (R2020a) is used by all scripts; dlarray/adamupdate and
% the Adam trainer in surr_lib need R2019b+. We require R2020b or newer.
env.release = version('-release');
env.release_ok = ~verLessThan('matlab', '9.9');   %#ok<VERLESSMATLAB> 9.9 = R2020b; verLessThan works on every release
if ~env.release_ok
    warning('init_renon_model:release', ...
        'MATLAB %s detected; the model was developed on R2026a and needs R2020b or newer.', env.release);
end

% ---- toolboxes --------------------------------------------------------
% v1 (main_renon and the dispatch model) uses base MATLAB only.
% v2 experiments: s2/s3 need Deep Learning (dlarray, adamupdate), s2 uses
% pca and s3 uses lhsdesign (Statistics and ML), s4 uses ga/particleswarm
% (Global Optimization, which requires Optimization) and parpool
% (Parallel Computing; optional, falls back to serial execution).
tb = struct( ...
    'deep_learning',       logical(license('test', 'Neural_Network_Toolbox')), ...
    'statistics',          logical(license('test', 'Statistics_Toolbox')), ...
    'optimization',        logical(license('test', 'Optimization_Toolbox')), ...
    'global_optimization', logical(license('test', 'GADS_Toolbox')), ...
    'parallel',            logical(license('test', 'Distrib_Computing_Toolbox')));
env.toolboxes = tb;
env.has_v1 = true;
env.has_v2 = tb.deep_learning && tb.statistics && tb.optimization && tb.global_optimization;
env.has_parallel = tb.parallel;

if ~env.has_v2
    msg = sprintf(['Not all toolboxes required by the v2 experiments are licensed ' ...
        '(Deep Learning: %d, Statistics and ML: %d, Optimization: %d, Global Optimization: %d). ' ...
        'The v1 model and renon_hub still run; s2..s4 will fail.'], ...
        tb.deep_learning, tb.statistics, tb.optimization, tb.global_optimization);
    if opts.strict, error('init_renon_model:toolboxes', '%s', msg);
    else, warning('init_renon_model:toolboxes', '%s', msg); end
end

% ---- reference data needed by v2 --------------------------------------
env.v1_pareto_present = isfile(fullfile(env.resultados, 'pareto_2030.csv')) && ...
                        isfile(fullfile(env.resultados, 'pareto_2050.csv'));
if ~env.v1_pareto_present
    warning('init_renon_model:data', ...
        'resultados/pareto_2030.csv or pareto_2050.csv missing: run reproduce_report_v1 before s1_hub.');
end

% ---- summary ----------------------------------------------------------
if opts.verbose
    fprintf('ReNoN-Azuay model initialised\n');
    fprintf('  root       : %s\n', env.root);
    fprintf('  MATLAB     : R%s (%s)\n', env.release, computer);
    fprintf('  v1 (base)  : ready\n');
    fprintf('  v2         : %s (DL %d | Stats %d | Optim %d | GlobalOptim %d | Parallel %d)\n', ...
        ternary(env.has_v2, 'ready', 'INCOMPLETE'), tb.deep_learning, tb.statistics, ...
        tb.optimization, tb.global_optimization, tb.parallel);
    fprintf('  next       : results = run_renon_model;   |   run_all_tests   |   reproduce_report_v1 / reproduce_report_v2\n');
end
end

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
