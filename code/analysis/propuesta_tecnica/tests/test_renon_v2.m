function tests = test_renon_v2
%TEST_RENON_V2 Tests of the vectorial (energy hub) model and v2 methods (report v2).
%   init_renon_model; runtests('tests/test_renon_v2.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.env = init_renon_model(struct('verbose', false));
end

% ----------------------------------------------------------------------
function testParamsV2ExtendV1(tc)
P1 = renon_params('lc2030'); P2 = renon_params_v2('lc2030');
tc.verifyEqual(numel(P2.lb), 7); tc.verifyEqual(P2.lb(1:6), P1.lb); tc.verifyEqual(P2.ub(1:6), P1.ub);
tc.verifyEqual(P2.lb(7), 0); tc.verifyEqual(P2.ub(7), 1);
tc.verifyEqual(P2.E_dem, P1.E_dem);
tc.verifyTrue(P2.eta_v2g > 0 && P2.eta_v2g <= 1 && P2.disp_v2g > 0 && P2.frac_E_v2g > 0);
tc.verifyEqual(numel(P2.theta_default), 4);
end

function testHubReproducesV1(tc)
% renon_hub with f_g = 0 and valley EMS must equal renon_dispatch exactly
% (regression claim of report v2, sec. Implementacion).
env = tc.TestData.env;
T = readtable(fullfile(env.resultados, 'resumen_escenarios.csv'));
esc = {'base2024', 'lc2030', 'lc2050'};
for e = 1:3
    P1 = renon_params(esc{e}); P2 = renon_params_v2(esc{e}); S = renon_profiles(P1, 1);
    x1 = [T.FV_MW(e), T.Eolica_MW(e), T.Bateria_MWh(e), T.Hidro_MW(e) - P1.hyd0, T.fFlexAgua(e), T.fSmartVE(e)];
    R1 = renon_dispatch(x1, P1, S); R2 = renon_hub([x1 0], P2, S);
    tc.verifyEqual(R2.co2, R1.co2, 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R2.costo, R1.costo, 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R2.ens, R1.ens, 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R2.s.imp, R1.s.imp, 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R2.s.flex_w + R2.s.flex_m, R1.s.flex, 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R2.E_v2g, 0);
end
end

function testHubPhysicsWithV2G(tc)
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
x = [283 150 50 30 0.2 0.6 0.8];
R = renon_hub(x, P, S);
chk = renon_sanity_checks(R, P, S, x);
tc.verifyTrue(chk.all_ok, strjoin(chk.failed, ', '));
tc.verifyGreaterThan(R.E_v2g, 0);
tc.verifyTrue(chk.v2g_window);
% per-vector energies add up to total load; per-vector CO2 adds up to total
tc.verifyEqual(sum(R.vec.E_GWh), R.dem_total, 'RelTol', 1e-9);
tc.verifyEqual(sum(R.vec.co2_kt), R.co2, 'RelTol', 1e-9);
tc.verifyEqual(sum(R.vec.costo_MUSD), R.costo, 'RelTol', 1e-9);
tc.verifyTrue(all(R.vec.resiliencia >= 0 & R.vec.resiliencia <= 1));
tc.verifySize(R.C, [3 6]);
tc.verifyEqual(R.C(3,6), 1 - P.x_ev, 'AbsTol', 1e-12);      % fuel share of mobility
tc.verifyTrue(R.kappa > 0 && R.kappa < 1);
end

function testAttentionEmsConservesEnergy(tc)
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
x = [283 150 0 30 0.2 0.6 0];
Rv = renon_hub(x, P, S, struct('ems', 'valley'));
Ra = renon_hub(x, P, S, struct('ems', 'attention', 'theta', [1 1 1 0.3]));
for R = {Rv, Ra}
    chk = renon_sanity_checks(R{1}, P, S, x);
    tc.verifyTrue(chk.all_ok, strjoin(chk.failed, ', '));
end
% same flexible energy, different placement
tc.verifyEqual(sum(Ra.s.flex_w + Ra.s.flex_m), sum(Rv.s.flex_w + Rv.s.flex_m), 'RelTol', 1e-9);
tc.verifyGreaterThan(max(abs(Ra.s.flex_m - Rv.s.flex_m)), 1e-6);
% limit tau -> 0 with beta = gamma = 0 recovers valley filling (report v2, sec. 2.4)
Rlim = renon_hub(x, P, S, struct('ems', 'attention', 'theta', [1 0 0 1e-3]));
tc.verifyEqual(Rlim.co2, Rv.co2, 'RelTol', 1e-3);
tc.verifyError(@() renon_hub(x, P, S, struct('ems', 'other')), ?MException);
end

function testHv2d(tc)
% two points dominating rectangle areas w.r.t. ref [4 4]: (1,3) and (3,1)
F = [1 3; 3 1; 2 2; 5 5];                  % (5,5) outside ref, (2,2) non-dominated
hv = hv2d(F, [4 4]);
% exact: union of boxes (1,3)-(4,4): 3x1=3 ; (2,2)-(4,4): 2x2=4 ; (3,1)-(4,4): 1x3=3
% overlaps: box1&box2 = [2,4]x[3,4]=2 ; box2&box3=[3,4]x[2,4]=2 ; box1&box3=[3,4]x[3,4]=1 ; triple=1
tc.verifyEqual(hv, 3 + 4 + 3 - 2 - 2 - 1 + 1, 'AbsTol', 1e-12);
tc.verifyEqual(hv2d([5 5], [4 4]), 0);
tc.verifyEqual(hv2d([0 0], [1 1]), 1);
end

function testDoaOnBenchmarks(tc)
% DOA re-implementation on Sphere-10 and Rastrigin-10 (report v2, sec. 3.4)
sphere = @(x) sum(x.^2);
rastr  = @(x) 10*numel(x) + sum(x.^2 - 10*cos(2*pi*x));
[xs, fs, hs, nev] = doa(sphere, -5.12*ones(1,10), 5.12*ones(1,10), 50, 200, 1);
tc.verifyEqual(nev, 50 + 50*200);
tc.verifyTrue(issorted(hs, 'descend'));          % best-so-far is monotone
tc.verifyLessThan(fs, 1e-4);
tc.verifyTrue(all(abs(xs) < 5.12));
[~, fr] = doa(rastr, -5.12*ones(1,10), 5.12*ones(1,10), 50, 200, 1);
tc.verifyLessThan(fr, 2);                         % at most ~1 local optimum away from f* = 0
end

function testSurrLibKanBsplineAndTraining(tc)
tc.assumeTrue(logical(license('test', 'Neural_Network_Toolbox')), 'Deep Learning Toolbox required');
lib = surr_lib();
% B-spline basis: partition of unity inside the knot span, correct size
t = lib.bspline(0, 1, 1); %#ok<NASGU>  (smoke: handle exists)
[p, c] = lib.init_kan(2, 3, 1, 5, 3, [-1.1 1.1], [-3 3]);
X = linspace(-1, 1, 11)';
B = lib.bspline(X, c.t1, c.k);
tc.verifySize(B, [11 1 5 + 3]);
tc.verifyEqual(squeeze(sum(B, 3)), ones(11, 1), 'AbsTol', 1e-12);
Y = lib.fwd_kan(p, dlarray([X X.^2]), c);
tc.verifySize(Y, [11 1]);
tc.verifyTrue(all(isfinite(extractdata(Y))));
tc.verifyEqual(lib.nparams(p), 2*3*(1+8) + 3*1*(1+8));
% short training on a smooth target reduces the loss
f = @(X) sin(pi*X(:,1)).*X(:,2);
Xtr = 2*rand(200, 2) - 1; Ytr = f(Xtr);
[~, hist] = lib.train(@(pp, XX) lib.fwd_kan(pp, XX, c), p, Xtr, Ytr, 200, 0.02);
tc.verifyLessThan(hist(end), 0.5*hist(1));
tc.verifyTrue(all(isfinite(hist)));
end

function testSurrLibMlpAndAttention(tc)
tc.assumeTrue(logical(license('test', 'Neural_Network_Toolbox')), 'Deep Learning Toolbox required');
lib = surr_lib();
p = lib.init_mlp(7, 8, 2); Y = lib.fwd_mlp(p, dlarray(rand(5, 7)));
tc.verifySize(Y, [5 2]);
[pa, ca] = lib.init_attn(7, 4, 8, 2); [Ya, A] = lib.fwd_attn(pa, dlarray(rand(5, 7)), ca);
tc.verifySize(Ya, [5 2]); tc.verifySize(A, [7 7]);
tc.verifyEqual(sum(A, 2), ones(7, 1), 'AbsTol', 1e-9);   % attention rows are softmax
end

function testRegressionReportV2Table5(tc)
% Decision vectors stored in resultados_v2/resumen_v2.csv reproduce their indicators.
env = tc.TestData.env;
T = readtable(fullfile(env.resultados_v2, 'resumen_v2.csv'));
esc = {'base2024', 'lc2030', 'lc2050'};
for e = 1:3
    P = renon_params_v2(esc{e}); S = renon_profiles(P, 1);
    x = [T.FV_MW(e), T.Eolica_MW(e), T.Bateria_MWh(e), T.HidroNueva_MW(e), T.fFlexAgua(e), T.fSmartVE(e), T.fV2G(e)];
    R = renon_hub(x, P, S);
    tc.verifyEqual(R.co2, T.CO2_kt(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(R.costo, T.Costo_MUSD(e), 'RelTol', 1e-9, esc{e});
    tc.verifyEqual(R.kappa, T.kappa(e), 'AbsTol', 1e-9, esc{e});
    tc.verifyEqual(R.vec.co2_kt(:)', [T.CO2_vec_kt_1(e) T.CO2_vec_kt_2(e) T.CO2_vec_kt_3(e)], 'RelTol', 1e-9, esc{e});
    C = readmatrix(fullfile(env.resultados_v2, sprintf('hub_C_%d.csv', e)));
    tc.verifyEqual(R.C, C, 'AbsTol', 1e-9, esc{e});
end
tc.verifyEqual(round(T.CO2_kt, 1), [532.0; 415.5; 226.7]);   % report v2, Tabla 5
end

function testRegressionV2GSensitivity(tc)
% Drought stress with V2G: ENS 17.6 -> 10.8 GWh for f_g 0 -> 1 (report v2, sec. 5.1)
env = tc.TestData.env;
Ts = readtable(fullfile(env.resultados_v2, 'v2g_sensibilidad.csv'));
T = readtable(fullfile(env.resultados_v2, 'resumen_v2.csv'));
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
xk = [T.FV_MW(2), T.Eolica_MW(2), T.Bateria_MWh(2), T.HidroNueva_MW(2), T.fFlexAgua(2), T.fSmartVE(2), 0];
mask = S.mes >= 10; S.cf_hyd(mask) = 0.5*S.cf_hyd(mask); S.ef_grid(mask) = 1.5*S.ef_grid(mask); S.prec_imp(mask) = 1.8*S.prec_imp(mask);
P.cap_imp = 0.7*P.cap_imp;
for i = [1 numel(Ts.fV2G)]
    xi = xk; xi(7) = Ts.fV2G(i);
    R = renon_hub(xi, P, S);
    tc.verifyEqual(R.ens, Ts.ENS_sequia_MWh(i), 'RelTol', 1e-9);
    tc.verifyEqual(R.costo, Ts.Costo_sequia_MUSD(i), 'RelTol', 1e-9);
end
tc.verifyEqual(round(100*(Ts.ENS_sequia_MWh(end)/Ts.ENS_sequia_MWh(1) - 1)), -39, 'AbsTol', 1);
end

function testRegressionAttentionEmsTable(tc)
% Valley-filling row of resultados_v2/ems_atencion.csv (report v2, Tabla 9) for the
% v1 compromise 2030 solution used in s5_attention_ems.
env = tc.TestData.env;
Te = readtable(fullfile(env.resultados_v2, 'ems_atencion.csv'));
Tth = readtable(fullfile(env.resultados_v2, 'ems_atencion_theta.csv'));
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
xk = [255.3 150 0 30 0.332 0.838 0];
Rv = renon_hub(xk, P, S);
tc.verifyEqual(Rv.co2, Te.CO2_kt(1), 'RelTol', 1e-9);
tc.verifyEqual(Rv.costo, Te.Costo_MUSD(1), 'RelTol', 1e-9);
Ra = renon_hub(xk, P, S, struct('ems', 'attention', 'theta', Tth.anio_tipo'));
tc.verifyEqual(Ra.co2, Te.CO2_kt(3), 'RelTol', 1e-9);
tc.verifyEqual(Ra.costo, Te.Costo_MUSD(3), 'RelTol', 1e-9);
end
