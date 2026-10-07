function tests = test_entry_points
%TEST_ENTRY_POINTS Tests of init_renon_model, run_renon_model and the sanity checks.
%   init_renon_model; runtests('tests/test_entry_points.m')
tests = functiontests(localfunctions);
end

function testInitReturnsPathsAndFlags(tc)
env = init_renon_model(struct('verbose', false));
tc.verifyTrue(isfolder(env.root) && isfolder(env.matlab_v1) && isfolder(env.matlab_v2) && isfolder(env.tests));
tc.verifyTrue(isfolder(env.resultados) && isfolder(env.resultados_v2) && isfolder(env.figs) && isfolder(env.figs_v2));
tc.verifyTrue(env.has_v1);
tc.verifyTrue(islogical(env.has_v2) || isnumeric(env.has_v2));
tc.verifyTrue(env.v1_pareto_present);
tc.verifyEqual(exist('renon_dispatch', 'file'), 2);
tc.verifyEqual(exist('renon_hub', 'file'), 2);
% no absolute machine-specific paths: everything under root
tc.verifyTrue(startsWith(env.matlab_v2, env.root));
end

function testRunDefaultIsV2Compromise2030(tc)
r = run_renon_model(struct('verbose', false));
tc.verifyEqual(r.cfg.version, 'v2'); tc.verifyEqual(r.cfg.scenario, 'lc2030');
tc.verifyEqual(numel(r.x), 7);
tc.verifyTrue(r.checks.all_ok);
tc.verifyEqual(round(r.R.co2, 1), 415.5);          % report v2, Tabla 5
tc.verifyEqual(round(r.R.costo, 1), 90.8);
tc.verifyTrue(isfield(r.R, 'C') && isfield(r.R, 'vec'));
end

function testRunV1AllScenarios(tc)
for esc = {'base2024', 'lc2030', 'lc2050'}
    r = run_renon_model(struct('version', 'v1', 'scenario', esc{1}, 'verbose', false));
    tc.verifyEqual(numel(r.x), 6);
    tc.verifyTrue(r.checks.all_ok, esc{1});
    tc.verifyTrue(isfinite(r.R.co2) && isfinite(r.R.costo));
end
r = run_renon_model(struct('version', 'v1', 'scenario', 'base2024', 'verbose', false));
tc.verifyEqual(round(r.R.co2), 532);                % report v1, Tabla 2
end

function testRunStressAndPerturbation(tc)
r0 = run_renon_model(struct('version', 'v1', 'verbose', false));
rs = run_renon_model(struct('version', 'v1', 'stress', true, 'verbose', false));
tc.verifyGreaterThan(rs.R.ens, r0.R.ens);
tc.verifyGreaterThan(rs.R.costo, r0.R.costo);
tc.verifyEqual(rs.P.cap_imp, 0.7*r0.P.cap_imp);
rp = run_renon_model(struct('version', 'v1', 'pert', struct('hyd', 0.6), 'verbose', false));
tc.verifyGreaterThan(rp.R.co2_elec, r0.R.co2_elec);
end

function testRunCustomXAndAttention(tc)
x = [200 100 20 10 0.3 0.5];
r1 = run_renon_model(struct('version', 'v1', 'x', x, 'verbose', false));
r2 = run_renon_model(struct('version', 'v2', 'x', x, 'verbose', false));   % padded with f_g = 0
tc.verifyEqual(r2.x, [x 0]);
tc.verifyEqual(r2.R.co2, r1.R.co2, 'AbsTol', 1e-9);
ra = run_renon_model(struct('version', 'v2', 'x', [x 0.5], 'ems', 'attention', 'verbose', false));
tc.verifyTrue(ra.checks.all_ok);
tc.verifyError(@() run_renon_model(struct('version', 'v1', 'x', [1 2 3], 'verbose', false)), 'run_renon_model:x');
tc.verifyError(@() run_renon_model(struct('version', 'v3')), ?MException);
end

function testRunOptimizeSmall(tc)
r = run_renon_model(struct('version', 'v1', 'optimize', true, 'npop', 12, 'ngen', 4, 'verbose', false));
tc.verifyTrue(isfield(r, 'front'));
tc.verifySize(r.front.F, [size(r.front.X, 1) 2]);
tc.verifyTrue(all(r.front.X >= r.P.lb - 1e-9, 'all') && all(r.front.X <= r.P.ub + 1e-9, 'all'));
tc.verifyTrue(isfinite(r.front.Rk.co2));
end

function testSanityChecksDetectViolation(tc)
r = run_renon_model(struct('version', 'v1', 'verbose', false));
R = r.R; R.s.imp(10) = R.s.imp(10) + 1;          % break the hourly balance on purpose
chk = renon_sanity_checks(R, r.P, r.S, r.x);
tc.verifyFalse(chk.all_ok);
tc.verifyTrue(any(strcmp(chk.failed, 'balance')));
R = r.R; R.co2 = NaN;
chk = renon_sanity_checks(R, r.P, r.S, r.x);
tc.verifyTrue(any(strcmp(chk.failed, 'finite')));
end
