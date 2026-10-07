function results = run_all_tests()
%RUN_ALL_TESTS Run the ReNoN-Azuay test suite (matlab.unittest).
%
%   RESULTS = RUN_ALL_TESTS() runs every test in tests/ (29 tests, about
%   10 s on R2026a) and prints a summary.
%
%   Test files
%   ----------
%   tests/test_renon_v1.m      parameters, profiles, dispatch physics, NSGA-II,
%                              regression against resultados/*.csv (report v1)
%   tests/test_renon_v2.m      hub model vs v1, V2G, attention EMS, DOA, hv2d,
%                              surrogate library, regression against
%                              resultados_v2/*.csv (report v2)
%   tests/test_entry_points.m  init_renon_model, run_renon_model, sanity checks
%
%   Equivalent manual command:
%       init_renon_model; results = runtests('tests');
%
%   See also INIT_RENON_MODEL, RUN_RENON_MODEL.

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner

env = init_renon_model(struct('verbose', false));
suite = TestSuite.fromFolder(env.tests);
runner = TestRunner.withTextOutput('OutputDetail', 2);
results = runner.run(suite);
fprintf('\n%d tests: %d passed, %d failed, %d incomplete (%.1f s)\n', numel(results), ...
    sum([results.Passed]), sum([results.Failed]), sum([results.Incomplete]), sum([results.Duration]));
if any([results.Failed])
    disp(table(results(logical([results.Failed]))));
end
end
