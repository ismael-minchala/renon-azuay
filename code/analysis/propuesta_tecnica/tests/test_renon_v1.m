function tests = test_renon_v1
%TEST_RENON_V1 Unit, physics and regression tests of the v1 model (report v1).
%   init_renon_model; runtests('tests/test_renon_v1.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.env = init_renon_model(struct('verbose', false));
end

% ----------------------------------------------------------------------
function testParamsScenarios(tc)
for esc = {'base2024', 'lc2030', 'lc2050'}
    P = renon_params(esc{1});
    tc.verifyEqual(P.H, 8760);
    tc.verifyEqual(numel(P.ef_mes), 12);  tc.verifyEqual(numel(P.prec_mes), 12);
    tc.verifyEqual(numel(P.cf_hyd_mes), 12); tc.verifyEqual(numel(P.cf_wind_mes), 12);
    tc.verifyTrue(all(P.cf_hyd_mes > 0 & P.cf_hyd_mes <= 1));
    tc.verifyTrue(all(P.cf_wind_mes > 0 & P.cf_wind_mes <= 1));
    tc.verifyTrue(all(P.lb <= P.ub));
    tc.verifyEqual(numel(P.lb), 6);
    tc.verifyGreaterThan([P.E_dem P.flota P.vol_agua P.cap_imp P.c_pv P.c_wind P.c_bat P.c_hyd P.voll], 0);
    tc.verifyTrue(P.x_ev >= 0 && P.x_ev <= 1);
end
tc.verifyError(@() renon_params('nope'), ?MException);
end

function testProfilesShapeAndBounds(tc)
P = renon_params('lc2030'); S = renon_profiles(P, 1);
H = P.H;
for f = {'dem_e', 'dem_ref', 'cf_pv', 'cf_wind', 'cf_hyd', 'ef_grid', 'prec_imp', 'p_trat', 'perfil_bomb_fijo', 'perfil_ev_fijo'}
    tc.verifySize(S.(f{1}), [H 1], f{1});
    tc.verifyTrue(all(isfinite(S.(f{1}))), f{1});
end
tc.verifyTrue(all(S.cf_pv >= 0 & S.cf_pv <= 1));
tc.verifyTrue(all(S.cf_wind >= 0 & S.cf_wind <= 1));
tc.verifyTrue(all(S.cf_hyd >= 0.05 & S.cf_hyd <= 1));
tc.verifyTrue(all(S.dem_e > 0) && all(S.ef_grid > 0) && all(S.prec_imp > 0));
% annual pure demand equals the scenario energy (MWh with dt = 1 h)
tc.verifyEqual(sum(S.dem_e), P.E_dem, 'RelTol', 1e-10);
tc.verifyEqual(sum(S.dem_ref), P.E_dem, 'RelTol', 1e-10);
% night PV must be zero
tc.verifyEqual(max(S.cf_pv(S.hod < 5 | S.hod > 19)), 0);
% daily EV energy consistent with fleet
n_ev = P.x_ev*P.flota;
tc.verifyEqual(S.E_ev_dia, n_ev*P.km_anio*P.e_km/365/1000, 'RelTol', 1e-12);
tc.verifyEqual(sum(S.perfil_ev_fijo), 365*S.E_ev_dia, 'RelTol', 1e-9);
end

function testProfilesReproducibleAndPerturbation(tc)
P = renon_params('lc2030');
S1 = renon_profiles(P, 7); S2 = renon_profiles(P, 7); S3 = renon_profiles(P, 8);
tc.verifyEqual(S1.dem_e, S2.dem_e);
tc.verifyNotEqual(S1.dem_e, S3.dem_e);
pert = struct('hyd', 0.5, 'dem', 1.1);
Sp = renon_profiles(P, 7, pert);
tc.verifyEqual(Sp.cf_hyd, 0.5*S1.cf_hyd, 'AbsTol', 1e-12);
tc.verifyEqual(sum(Sp.dem_e), 1.1*P.E_dem, 'RelTol', 1e-10);
end

function testDispatchPhysics(tc)
P = renon_params('lc2030'); S = renon_profiles(P, 1);
x = [250 120 100 20 0.5 0.8];
R = renon_dispatch(x, P, S);
chk = renon_sanity_checks(R, P, S, x);
tc.verifyTrue(chk.all_ok, strjoin(chk.failed, ', '));
tc.verifyLessThan(chk.balance_residual_MW, 1e-8);
tc.verifyEqual(R.dem_total, sum(R.s.carga)/1e3, 'RelTol', 1e-12);
tc.verifyEqual(R.co2, R.co2_elec + R.co2_transp, 'RelTol', 1e-12);
tc.verifyEqual(R.resiliencia, 1 - R.ens/sum(R.s.carga), 'RelTol', 1e-12);
% more renewables cannot increase electric emissions (same profiles, no flex)
R0 = renon_dispatch([5 50 0 0 0 0], P, S); R1 = renon_dispatch([300 150 0 0 0 0], P, S);
tc.verifyLessThan(R1.co2_elec, R0.co2_elec);
tc.verifyGreaterThan(R1.frac_ren, R0.frac_ren);
end

function testDispatchBaselineNoFlexNoBattery(tc)
P = renon_params('base2024'); S = renon_profiles(P, 1);
R = renon_dispatch([P.pv0 P.wind0 0 0 0 0], P, S);
tc.verifyEqual(max(abs(R.s.bat)), 0);
tc.verifyEqual(max(abs(R.s.flex)), 0);
tc.verifyEqual(R.ens, 0);
tc.verifyEqual(R.frac_ren, 0.2565378, 'AbsTol', 1e-6);   % report v1, Tabla 2
end

function testObjectivesWrapper(tc)
P = renon_params('lc2030'); S = renon_profiles(P, 1);
x = [100 80 10 5 0.2 0.3];
F = objetivos(x, P, S); R = renon_dispatch(x, P, S);
tc.verifyEqual(F, [R.co2 R.costo]);
end

function testNsga2OnAnalyticProblem(tc)
% Schaffer N.1: f1 = x^2, f2 = (x-2)^2 ; Pareto set x in [0,2], front f2 = (sqrt(f1)-2)^2
fun = @(x) [x(1)^2, (x(1)-2)^2];
[X, F] = nsga2_simple(fun, -5, 5, 30, 40, 1);
tc.verifyTrue(all(X >= -5 & X <= 5));
tc.verifyTrue(issorted(F(:,1)));
tc.verifyTrue(all(X > -0.05 & X < 2.05), 'Pareto set should lie in [0, 2]');
tc.verifyEqual(F(:,2), (sqrt(F(:,1)) - 2).^2, 'AbsTol', 1e-9);
% no solution dominates another
n = size(F,1); dom = false;
for i = 1:n, for j = 1:n
    if i ~= j && all(F(j,:) <= F(i,:)) && any(F(j,:) < F(i,:)), dom = true; end
end, end
tc.verifyFalse(dom);
end

function testRegressionReportV1Table2(tc)
% Decision vectors from resultados/resumen_escenarios.csv must reproduce the
% indicators stored in the same file (report v1, Tabla 2) to 1e-9 relative.
env = tc.TestData.env;
T = readtable(fullfile(env.resultados, 'resumen_escenarios.csv'));
esc = {'base2024', 'lc2030', 'lc2050'};
for e = 1:3
    P = renon_params(esc{e}); S = renon_profiles(P, 1);
    x = [T.FV_MW(e), T.Eolica_MW(e), T.Bateria_MWh(e), T.Hidro_MW(e) - P.hyd0, T.fFlexAgua(e), T.fSmartVE(e)];
    R = renon_dispatch(x, P, S);
    tc.verifyEqual(R.co2, T.CO2_kt(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(R.costo, T.Costo_MUSD(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(100*R.frac_ren, T.FraccionRenov_pct(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(R.imp, T.Import_GWh(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(R.dem_total, T.Demanda_GWh(e), 'RelTol', 1e-9, esc{e});
end
% headline numbers quoted in the abstract of report v1
tc.verifyEqual(round(T.CO2_kt), [532; 418; 227]);
tc.verifyEqual(round(100*(T.CO2_kt(2:3)/T.CO2_kt(1) - 1)), [-21; -57]);
end

function testRegressionReportV1Verification(tc)
% NRMSE / Pearson of the demand generator and drought stress (report v1 secs. 3.1, 4.3)
env = tc.TestData.env;
Tv = readtable(fullfile(env.resultados, 'verificacion_estres_mc.csv'));
P0 = renon_params('base2024'); S0 = renon_profiles(P0, 1);
nrmse = sqrt(mean((S0.dem_e - S0.dem_ref).^2))/mean(S0.dem_ref);
rho = corr(S0.dem_e, S0.dem_ref);
tc.verifyEqual(100*nrmse, Tv.NRMSE_pct, 'RelTol', 1e-9);
tc.verifyEqual(rho, Tv.Pearson, 'RelTol', 1e-9);
tc.verifyLessThan(100*nrmse, 15); tc.verifyGreaterThan(rho, 0.85);
% drought stress on the 2030 compromise solution
T = readtable(fullfile(env.resultados, 'resumen_escenarios.csv'));
P = renon_params('lc2030'); S = renon_profiles(P, 1);
xk = [T.FV_MW(2), T.Eolica_MW(2), T.Bateria_MWh(2), T.Hidro_MW(2) - P.hyd0, T.fFlexAgua(2), T.fSmartVE(2)];
mask = S.mes >= 10; S.cf_hyd(mask) = 0.5*S.cf_hyd(mask); S.ef_grid(mask) = 1.5*S.ef_grid(mask); S.prec_imp(mask) = 1.8*S.prec_imp(mask);
P.cap_imp = 0.7*P.cap_imp;
Rst = renon_dispatch(xk, P, S); Rst0 = renon_dispatch([P.pv0 P.wind0 0 0 0 0], P, S);
tc.verifyEqual(Rst.ens, Tv.ENS_ReNoN_MWh, 'RelTol', 1e-9);
tc.verifyEqual(Rst0.ens, Tv.ENS_sinReNoN_MWh, 'RelTol', 1e-9);
tc.verifyEqual(Rst.resiliencia, Tv.Resil_ReNoN, 'RelTol', 1e-9);
tc.verifyEqual(Rst0.resiliencia, Tv.Resil_sinReNoN, 'RelTol', 1e-9);
end

function testRegressionParetoFront2030(tc)
% Every point of the stored front re-evaluates to the stored objectives.
env = tc.TestData.env;
Tp = readtable(fullfile(env.resultados, 'pareto_2030.csv'));
P = renon_params('lc2030'); S = renon_profiles(P, 1);
for i = 1:size(Tp,1)
    x = [Tp.FV_MW(i), Tp.Eolica_MW(i), Tp.Bateria_MWh(i), Tp.HidroNueva_MW(i), Tp.fFlexAgua(i), Tp.fSmartVE(i)];
    F = objetivos(x, P, S);
    tc.verifyEqual(F, [Tp.CO2_kt(i), Tp.Costo_MUSD(i)], 'RelTol', 1e-9);
end
end

function testNsga2ReproducesStoredFront(tc)
% Full NSGA-II run of report v1 (2030): deterministic with seed 8 -> same front.
tc.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture('MATLAB:nearlySingularMatrix'));
import matlab.unittest.constraints.IsEqualTo
import matlab.unittest.constraints.RelativeTolerance
env = tc.TestData.env;
Tp = readtable(fullfile(env.resultados, 'pareto_2030.csv'));
P = renon_params('lc2030'); S = renon_profiles(P, 1);
[Xnd, Fnd] = nsga2_simple(@(x) objetivos(x, P, S), P.lb, P.ub, 48, 60, 8);
tc.verifyEqual(size(Xnd,1), size(Tp,1));
tc.verifyThat(Fnd, IsEqualTo([Tp.CO2_kt Tp.Costo_MUSD], 'Within', RelativeTolerance(1e-9)));
end
