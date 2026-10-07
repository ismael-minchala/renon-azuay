function results = run_renon_model(cfg)
%RUN_RENON_MODEL Execute the ReNoN-Azuay multi-vector model for one configuration.
%
%   RESULTS = RUN_RENON_MODEL() simulates the reference compromise solution
%   2030 of the vectorial model (v2, energy hub) over the 8760-hour typical
%   year and returns indicators, hourly series and physical sanity checks.
%
%   RESULTS = RUN_RENON_MODEL(CFG) with fields (all optional):
%     version   'v1' | 'v2'            model version (default 'v2')
%                 v1: renon_dispatch   6 decision variables, valley-filling EMS
%                 v2: renon_hub        7 variables (adds V2G), per-vector
%                                      indicators, coupling matrix, EMS
%                                      'valley' or 'attention'
%     scenario  'base2024' | 'lc2030' | 'lc2050'   (default 'lc2030')
%     x         decision vector [P_pv MW, P_wind MW, E_bat MWh, P_hyd_new MW,
%               f_flex_water, f_smart_ev (, f_v2g)]. Default: the reference
%               compromise solution of the chosen version/scenario, read from
%               resultados/resumen_escenarios.csv (v1) or
%               resultados_v2/resumen_v2.csv (v2); baseline park for base2024.
%     seed      seed of the synthetic profile generator (default 1, as in the reports)
%     pert      struct of multiplicative perturbations for renon_profiles
%               (.hyd .pv .wind .dem .prec), used for Monte Carlo
%     stress    true applies the extreme-drought stress test of the reports:
%               Oct-Dec hydro x0.5, grid emission factor x1.5, import price
%               x1.8, import capacity x0.7 (default false)
%     ems       'valley' | 'attention'   (v2 only, default 'valley')
%     theta     [alpha beta gamma tau] attention weights (v2, default P.theta_default)
%     optimize  true runs NSGA-II (min CO2, min cost) over the scenario bounds
%               and returns the non-dominated front and knee point (default false)
%     npop, ngen, opt_seed   NSGA-II population, generations, seed (48, 60, 8)
%     checks    true runs renon_sanity_checks and errors on violation (default true)
%     verbose   true prints a summary (default true)
%
%   Fields of RESULTS
%   -----------------
%   cfg      configuration actually used (defaults filled in)
%   P, S     parameter struct and hourly profiles (see renon_params, renon_profiles)
%   x        decision vector evaluated
%   R        output of renon_dispatch / renon_hub: indicators (co2 [kt/yr],
%            costo [MUSD/yr], ens [MWh/yr], vert [MWh/yr], imp, th, gen [GWh/yr],
%            frac_ren, resiliencia) and hourly series in R.s. For v2 also
%            R.vec (per-vector indicators), R.C (3x6 mean coupling matrix),
%            R.kappa (coupling index), R.E_v2g.
%   checks   struct from renon_sanity_checks (balance residual, bounds, ...)
%   front    (optimize only) .X non-dominated decision vectors, .F = [CO2 cost],
%            .xk knee point, .Rk its full evaluation
%   runtime  seconds
%
%   Units: powers MW, energies MWh (indicators in GWh where stated), CO2 in
%   ktCO2/yr, cost in MUSD/yr. Time step 1 h, horizon 8760 h (typical year).
%
%   Examples
%   --------
%     init_renon_model
%     r = run_renon_model;                                  % v2 compromise 2030
%     r = run_renon_model(struct('version','v1','scenario','lc2050'));
%     r = run_renon_model(struct('stress',true));           % drought stress test
%     r = run_renon_model(struct('scenario','lc2030','optimize',true,'ngen',20));
%
%   See also INIT_RENON_MODEL, RENON_DISPATCH, RENON_HUB, RENON_SANITY_CHECKS.

t0 = tic;
if nargin < 1, cfg = struct(); end
def = struct('version','v2', 'scenario','lc2030', 'x',[], 'seed',1, 'pert',struct(), ...
             'stress',false, 'ems','valley', 'theta',[], 'optimize',false, ...
             'npop',48, 'ngen',60, 'opt_seed',8, 'checks',true, 'verbose',true);
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(cfg, fn{k}) || (isempty(cfg.(fn{k})) && ~strcmp(fn{k},'x') && ~strcmp(fn{k},'theta'))
        cfg.(fn{k}) = def.(fn{k});
    end
end
cfg.version  = validatestring(cfg.version, {'v1','v2'});
cfg.scenario = validatestring(cfg.scenario, {'base2024','lc2030','lc2050'});
cfg.ems      = validatestring(cfg.ems, {'valley','attention'});

env = init_renon_model(struct('verbose', false));
isv2 = strcmp(cfg.version, 'v2');

% ---- parameters and profiles ------------------------------------------
if isv2, P = renon_params_v2(cfg.scenario); else, P = renon_params(cfg.scenario); end
S = renon_profiles(P, cfg.seed, cfg.pert);

if cfg.stress
    % Same definition as main_renon (sec. 4), s1_hub and s5_attention_ems:
    % severe El Nino-type drought in the Oct-Dec dry season.
    mask = S.mes >= 10;
    S.cf_hyd(mask)   = 0.5*S.cf_hyd(mask);
    S.ef_grid(mask)  = 1.5*S.ef_grid(mask);
    S.prec_imp(mask) = 1.8*S.prec_imp(mask);
    P.cap_imp = 0.7*P.cap_imp;
end

% ---- decision vector --------------------------------------------------
nvar = 6 + isv2;
if isempty(cfg.x)
    cfg.x = reference_solution(env, cfg.version, cfg.scenario, P);
end
x = cfg.x(:)';
if numel(x) == 6 && isv2, x = [x 0]; end        % v1 vector in v2 model: no V2G
if numel(x) ~= nvar
    error('run_renon_model:x', 'Decision vector must have %d elements for %s (got %d).', nvar, cfg.version, numel(x));
end
if any(x < P.lb - 1e-9) || any(x > P.ub + 1e-9)
    warning('run_renon_model:bounds', 'Decision vector lies outside the scenario bounds P.lb/P.ub.');
end

% ---- evaluation -------------------------------------------------------
if isv2
    opt = struct('ems', cfg.ems);
    if ~isempty(cfg.theta), opt.theta = cfg.theta; end
    evalfun = @(xx) renon_hub(xx, P, S, opt);
else
    evalfun = @(xx) renon_dispatch(xx, P, S);
end
R = evalfun(x);

results = struct('cfg', cfg, 'P', P, 'S', S, 'x', x, 'R', R);

% ---- optional NSGA-II -------------------------------------------------
if cfg.optimize
    objfun = @(xx) objectives(evalfun, xx);
    [Xnd, Fnd] = nsga2_simple(objfun, P.lb, P.ub, cfg.npop, cfg.ngen, cfg.opt_seed);
    Fn = (Fnd - min(Fnd)) ./ max(max(Fnd) - min(Fnd), eps);   % knee: closest to ideal point
    [~, ik] = min(vecnorm(Fn, 2, 2));
    results.front = struct('X', Xnd, 'F', Fnd, 'xk', Xnd(ik,:), 'Rk', evalfun(Xnd(ik,:)));
end

% ---- sanity checks ----------------------------------------------------
results.checks = renon_sanity_checks(R, P, S, x);
if cfg.checks && ~results.checks.all_ok
    error('run_renon_model:checks', 'Physical sanity checks failed: %s', strjoin(results.checks.failed, ', '));
end
results.runtime = toc(t0);

% ---- summary ----------------------------------------------------------
if cfg.verbose
    fprintf('[run_renon_model] %s | %s | EMS %s%s\n', cfg.version, cfg.scenario, ...
        ternary(isv2, cfg.ems, 'valley'), ternary(cfg.stress, ' | DROUGHT STRESS', ''));
    fprintf('  x = [%s]\n', strjoin(compose('%.3g', x), ', '));
    fprintf('  CO2 = %.1f kt/yr (elec %.1f + transport %.1f) | cost = %.2f MUSD/yr\n', R.co2, R.co2_elec, R.co2_transp, R.costo);
    fprintf('  renewable fraction = %.1f%% | import = %.0f GWh | ENS = %.1f MWh | curtailment = %.0f MWh | resilience = %.4f\n', ...
        100*R.frac_ren, R.imp, R.ens, R.vert, R.resiliencia);
    if isv2
        fprintf('  coupling index kappa = %.3f | V2G discharge = %.2f GWh | per-vector CO2 [e,w,m] = [%s] kt\n', ...
            R.kappa, R.E_v2g, strjoin(compose('%.1f', R.vec.co2_kt), ', '));
    end
    if cfg.optimize
        fprintf('  NSGA-II: %d non-dominated solutions; knee CO2 = %.1f kt, cost = %.2f MUSD\n', ...
            size(results.front.X,1), results.front.Rk.co2, results.front.Rk.costo);
    end
    fprintf('  checks: %s | %.2f s\n', ternary(results.checks.all_ok, 'all passed', 'FAILED'), results.runtime);
end
end

% ======================================================================
function F = objectives(evalfun, x)
R = evalfun(x);
F = [R.co2, R.costo];
end

function x = reference_solution(env, version, scenario, P)
% Reference decision vectors: baseline park for base2024, otherwise the
% compromise (knee) solutions reported in report v1 / v2.
if strcmp(scenario, 'base2024')
    x = [P.pv0, P.wind0, 0, 0, 0, 0];
    if strcmp(version, 'v2'), x = [x 0]; end
    return
end
row = find(strcmp(scenario, {'base2024','lc2030','lc2050'}));
if strcmp(version, 'v1')
    f = fullfile(env.resultados, 'resumen_escenarios.csv');
    T = readtable(f);
    x = [T.FV_MW(row), T.Eolica_MW(row), T.Bateria_MWh(row), T.Hidro_MW(row) - P.hyd0, T.fFlexAgua(row), T.fSmartVE(row)];
else
    f = fullfile(env.resultados_v2, 'resumen_v2.csv');
    T = readtable(f);
    x = [T.FV_MW(row), T.Eolica_MW(row), T.Bateria_MWh(row), T.HidroNueva_MW(row), T.fFlexAgua(row), T.fSmartVE(row), T.fV2G(row)];
end
end

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
