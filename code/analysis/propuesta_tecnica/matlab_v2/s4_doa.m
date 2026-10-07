%S4_DOA Dream Optimization Algorithm frente a GA, PSO y busqueda aleatoria
%   (a) problema mono-objetivo penalizado: min costo s.a. CO2 <= 415 kt;
%   (b) frente de Pareto por escalarizacion de Tchebycheff con DOA vs NSGA-II.
setup_v2; tic;
fprintf('=== S4: Dream Optimization Algorithm ===\n');
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
lb = P.lb; ub = P.ub; nv = numel(lb);
co2_max = 415; pen = 5;                                   % MUSD por kt de exceso
Jfun = @(x) pen_obj(x, P, S, co2_max, pen);
budget = 3000; Npop = 60; Tit = (budget - Npop)/Npop;     % 49 iteraciones
seeds = 1:6; algos = {'DOA','GA','PSO','Aleatoria'};
% Pool paralelo si Parallel Computing Toolbox esta disponible; sin ella los
% parfor se ejecutan en serie (mismos resultados, mas tiempo).
if license('test','Distrib_Computing_Toolbox') && exist('gcp','file') == 2 && isempty(gcp('nocreate'))
    parpool('Processes', min(12, feature('numcores')));
end
nA = numel(algos); nS = numel(seeds);
best = zeros(nA, nS); curves = cell(nA, nS); xbest = cell(nA, nS); tiempos = zeros(nA,nS);
tasks = cell(nA*nS, 1);
parfor q = 1:nA*nS
    a = ceil(q/nS); s = seeds(mod(q-1,nS)+1);
    tq = tic;
    [xb, fb, h] = run_algo(algos{a}, Jfun, lb, ub, Npop, Tit, budget, s);
    tasks{q} = struct('a',a,'s',s,'xb',xb,'fb',fb,'h',h,'t',toc(tq));
end
for q = 1:nA*nS
    r = tasks{q}; best(r.a, r.s) = r.fb; curves{r.a, r.s} = r.h; xbest{r.a, r.s} = r.xb; tiempos(r.a,r.s) = r.t;
end
Tst = table(algos', mean(best,2), std(best,0,2), min(best,[],2), max(best,[],2), mean(tiempos,2), ...
    'VariableNames', {'Algoritmo','J_media','J_std','J_min','J_max','Tiempo_s'});
disp(Tst); writetable(Tst, fullfile(resDir,'doa_mono_objetivo.csv'));
% mejor solucion de cada algoritmo
Xb = zeros(nA, nv+2);
for a = 1:nA, [~, s] = min(best(a,:)); R = renon_hub(xbest{a,s}, P, S); Xb(a,:) = [xbest{a,s}, R.co2, R.costo]; end
writetable(array2table([ (1:nA)', Xb], 'VariableNames', ['Algoritmo', {'FV_MW','Eolica_MW','Bateria_MWh','HidroNueva_MW','fFlexAgua','fSmartVE','fV2G','CO2_kt','Costo_MUSD'}]), ...
    fullfile(resDir,'doa_mono_mejores.csv'));

f = figure('Position',[100 100 620 380]);
for a = 1:nA
    L = min(cellfun(@numel, curves(a,:))); Cm = zeros(nS, L);
    for s = 1:nS, c = curves{a,s}; Cm(s,:) = c(1:L); end
    ev = linspace(Npop, budget, L);
    plot(ev, mean(Cm,1), 'LineWidth', 1.5, 'Color', co(a,:)); hold on;
end
grid on; xlabel('evaluaciones del modelo'); ylabel('J = costo + penalizacion CO_2 (MUSD)'); legend(algos);
title('Convergencia media (6 semillas), presupuesto 3000 evaluaciones'); ylim([min(best(:))-1, min(best(:))+25]);
exportgraphics(f, fullfile(figDir,'fig_v2_11_doa_convergencia.png'), 'Resolution', 150);

%% (b) Frente por escalarizacion de Tchebycheff con DOA vs NSGA-II
fprintf('  frente por Tchebycheff con DOA ...\n');
z = [370, 65]; rg = [180, 70];                             % punto ideal y rangos aprox.
W = linspace(0.02, 0.98, 12)'; W = [W, 1-W];
N2 = 24; T2 = 10;                                          % 24 + 24*10 = 264 evals por peso
Xw = zeros(size(W,1), nv); Fw = zeros(size(W,1), 2);
parfor i = 1:size(W,1)
    w = W(i,:);
    tch = @(x) tcheb(x, P, S, w, z, rg);
    [xb, ~] = doa(tch, lb, ub, N2, T2, 100+i);
    Xw(i,:) = xb; Fw(i,:) = obj_hub(xb, P, S);
end
[Xn_nd, Fn_nd] = nsga2_simple(@(x) obj_hub(x,P,S), lb, ub, 48, 60, 8);
ref = [1.05*max([Fn_nd(:,1);Fw(:,1)]), 1.05*max([Fn_nd(:,2);Fw(:,2)])];
hv_n = hv2d(Fn_nd, ref); hv_d = hv2d(Fw, ref);
fprintf('  HV NSGA-II=%.1f (%d evals) | HV DOA-Tchebycheff=%.1f (%d evals)\n', hv_n, 48*61, hv_d, size(W,1)*(N2+N2*T2));
f = figure('Position',[100 100 560 400]);
plot(Fn_nd(:,1), Fn_nd(:,2), 'o-','Color',co(1,:),'MarkerFaceColor',co(1,:),'MarkerSize',4); hold on;
plot(Fw(:,1), Fw(:,2), 'd','Color',co(6,:),'MarkerFaceColor',co(6,:),'MarkerSize',6);
grid on; xlabel('CO_2 (kt/anio)'); ylabel('Costo anual (MUSD/anio)');
legend({sprintf('NSGA-II (%d evals)',48*61), sprintf('DOA + Tchebycheff, 12 pesos (%d evals)', size(W,1)*(N2+N2*T2))},'Location','northeast');
title(sprintf('Frente 2030: HV NSGA-II %.0f | DOA %.0f (%.1f%%)', hv_n, hv_d, 100*hv_d/hv_n));
exportgraphics(f, fullfile(figDir,'fig_v2_12_doa_frente.png'), 'Resolution', 150);
writetable(array2table([W, Xw, Fw], 'VariableNames', {'w_CO2','w_costo','FV_MW','Eolica_MW','Bateria_MWh','HidroNueva_MW','fFlexAgua','fSmartVE','fV2G','CO2_kt','Costo_MUSD'}), ...
    fullfile(resDir,'doa_frente_tchebycheff.csv'));
writetable(table({'NSGA-II';'DOA-Tchebycheff'}, [48*61; size(W,1)*(N2+N2*T2)], [hv_n; hv_d], 'VariableNames', {'Metodo','Evaluaciones','Hipervolumen'}), fullfile(resDir,'doa_frente_hv.csv'));
save(fullfile(resDir,'s4_doa.mat'), 'best','curves','xbest','tiempos','Xw','Fw','Fn_nd','hv_n','hv_d','Xb');
fprintf('=== S4 completado en %.0f s ===\n', toc);

% ----------------------------------------------------------------------
function J = pen_obj(x, P, S, co2_max, pen)
R = renon_hub(x, P, S);
J = R.costo + pen*max(0, R.co2 - co2_max);
end
function J = tcheb(x, P, S, w, z, rg)
F = obj_hub(x, P, S); u = (F - z)./rg;
J = max(w.*u) + 0.05*sum(u);
end
function [xb, fb, h] = run_algo(algo, J, lb, ub, Npop, Tit, budget, seed)
% El generador se fija explicitamente ('twister') en cada rama: los workers del
% pool arrancan con otro generador y doa.m lo cambia a 'twister', de modo que un
% rng(seed) sin tipo daria resultados dependientes del worker que ejecute la tarea.
global BESTHIST; BESTHIST = [];
switch algo
    case 'DOA'
        [xb, fb, h] = doa(J, lb, ub, Npop, Tit, seed);
    case 'GA'
        rng(seed,'twister');
        opts = optimoptions('ga','PopulationSize',Npop,'MaxGenerations',Tit,'Display','off', ...
            'OutputFcn', @ga_out, 'FunctionTolerance', 0, 'MaxStallGenerations', 2147483647);
        [xb, fb] = ga(J, numel(lb), [], [], [], [], lb, ub, [], opts); h = BESTHIST;
    case 'PSO'
        rng(seed,'twister');
        opts = optimoptions('particleswarm','SwarmSize',Npop,'MaxIterations',Tit,'Display','off', ...
            'OutputFcn', @pso_out, 'FunctionTolerance', 0, 'MaxStallIterations', 2147483647);
        [xb, fb] = particleswarm(J, numel(lb), lb, ub, opts); h = BESTHIST;
    case 'Aleatoria'
        rng(seed,'twister'); fb = inf; xb = lb; h = zeros(Tit,1);
        for it = 1:Tit+1
            Xr = lb + rand(Npop, numel(lb)).*(ub-lb);
            for i = 1:Npop, fi = J(Xr(i,:)); if fi < fb, fb = fi; xb = Xr(i,:); end, end
            if it > 1, h(it-1) = fb; end
        end
end
h = h(:);
end
function [state, options, optchanged] = ga_out(options, state, ~)
global BESTHIST; optchanged = false;
BESTHIST(end+1,1) = min(state.Score);
end
function stop = pso_out(optimValues, ~)
global BESTHIST; stop = false;
BESTHIST(end+1,1) = optimValues.bestfval;
end
