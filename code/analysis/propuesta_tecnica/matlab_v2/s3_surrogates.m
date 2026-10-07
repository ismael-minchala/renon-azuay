%S3_SURROGATES Modelos sustitutos del modelo hub: KAN vs MLP vs atencion,
%   y optimizacion NSGA-II asistida por el sustituto KAN.
setup_v2; tic;
fprintf('=== S3: modelos sustitutos (KAN / MLP / atencion) ===\n');
lib = surr_lib();
P = renon_params_v2('lc2030'); S = renon_profiles(P, 1);
lb = P.lb; ub = P.ub; nv = numel(lb);

%% Muestreo LHS del espacio de decision (McKay et al., 1979)
N = 600; rng(3);
U = lhsdesign(N, nv, 'Criterion','maximin', 'Iterations', 20);
X = lb + U.*(ub-lb); Y = zeros(N,2);
tS = tic; for i = 1:N, Y(i,:) = obj_hub(X(i,:), P, S); end; tS = toc(tS);
fprintf('  %d evaluaciones del modelo hub en %.1f s (%.1f ms/eval)\n', N, tS, 1e3*tS/N);
ntr = 480; itr = 1:ntr; ite = ntr+1:N;
Xn = 2*(X-lb)./(ub-lb) - 1; ym = mean(Y(itr,:)); ys = std(Y(itr,:)); Yn = (Y-ym)./ys;

%% Entrenamiento
iters = 2500; lr = 0.01;
[p_kan, c_kan] = lib.init_kan(nv, 6, 2, 5, 3, [-1.1 1.1], [-3 3]);
p_mlp = lib.init_mlp(nv, 32, 2);
[p_att, c_att] = lib.init_attn(nv, 8, 32, 2);
fwd_kan = @(p, X) lib.fwd_kan(p, X, c_kan);
fwd_att = @(p, X) lib.fwd_attn(p, X, c_att);
[p_kan, h_kan, t_kan] = lib.train(fwd_kan,     p_kan, Xn(itr,:), Yn(itr,:), iters, lr);
[p_mlp, h_mlp, t_mlp] = lib.train(lib.fwd_mlp, p_mlp, Xn(itr,:), Yn(itr,:), iters, lr);
[p_att, h_att, t_att] = lib.train(fwd_att,     p_att, Xn(itr,:), Yn(itr,:), iters, lr);
fprintf('  entrenamiento: KAN %.0f s | MLP %.0f s | ATT %.0f s\n', t_kan, t_mlp, t_att);

pred = @(fwd, p, Xq) extractdata(fwd(p, dlarray(Xq))).*ys + ym;
Yk = pred(fwd_kan, p_kan, Xn(ite,:)); Ym = pred(lib.fwd_mlp, p_mlp, Xn(ite,:)); Ya = pred(fwd_att, p_att, Xn(ite,:));
Yt = Y(ite,:);
met = @(Yp) [sqrt(mean((Yp-Yt).^2)), 1 - sum((Yp-Yt).^2)./sum((Yt-mean(Yt)).^2), mean(abs(Yp-Yt))];
M = [met(Yk); met(Ym); met(Ya)];
np = [lib.nparams(p_kan), lib.nparams(p_mlp), lib.nparams(p_att)];
Tm = table({'KAN [7,6,2] G=5';'MLP [7,32,32,2]';'Atencion d=8'}, np', [t_kan;t_mlp;t_att], ...
    M(:,1), M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), ...
    'VariableNames', {'Modelo','Parametros','Tiempo_s','RMSE_CO2_kt','RMSE_costo_MUSD','R2_CO2','R2_costo','MAE_CO2','MAE_costo'});
disp(Tm); writetable(Tm, fullfile(resDir,'surrogates_metricas.csv'));

%% Figura: prediccion vs. real
f = figure('Position',[100 100 1050 620]);
nom = {'KAN','MLP','Auto-atencion'}; Yp = {Yk, Ym, Ya}; ob = {'CO_2 (kt/anio)','Costo (MUSD/anio)'};
for o = 1:2, for m = 1:3
    subplot(2,3,(o-1)*3+m);
    plot(Yt(:,o), Yp{m}(:,o), 'o', 'Color', co(m,:), 'MarkerSize', 4, 'MarkerFaceColor', co(m,:)); hold on;
    lim = [min(Yt(:,o)) max(Yt(:,o))]; plot(lim, lim, 'k--'); grid on; axis tight;
    xlabel(['real: ' ob{o}]); ylabel('predicho'); title(sprintf('%s  R^2=%.3f  RMSE=%.2f', nom{m}, M(m,2+o), M(m,o)));
end, end
exportgraphics(f, fullfile(figDir,'fig_v2_6_surrogates.png'), 'Resolution', 150);

%% Figura: curvas de perdida
f = figure('Position',[100 100 600 340]);
semilogy(h_kan,'Color',co(1,:),'LineWidth',1.2); hold on; semilogy(h_mlp,'Color',co(2,:),'LineWidth',1.2); semilogy(h_att,'Color',co(3,:),'LineWidth',1.2);
grid on; xlabel('iteracion (Adam)'); ylabel('MSE normalizado'); legend(nom); title('Convergencia del entrenamiento');
exportgraphics(f, fullfile(figDir,'fig_v2_7_surr_loss.png'), 'Resolution', 150);

%% Figura: funciones de activacion aprendidas por la KAN (capa 1) e importancia
xs = linspace(-1,1,101)';
f = figure('Position',[100 100 1100 520]);
imp = zeros(nv,1);
for i = 1:nv
    subplot(2,4,i);
    Xi = zeros(101, nv); Xi(:,i) = xs;                          % solo la entrada i varia
    B = lib.bspline(dlarray(Xi(:,i)), c_kan.t1, c_kan.k);        % 101 x 1 x nb
    for j = 1:size(p_kan.L1_wb,2)
        phi = xs.*(1./(1+exp(-xs))) * extractdata(p_kan.L1_wb(i,j));
        for b = 1:size(B,3), phi = phi + extractdata(B(:,1,b)) * extractdata(p_kan.L1_C(i,j,b)); end
        plot(xs, phi, 'LineWidth', 1.1); hold on;
        imp(i) = imp(i) + std(phi);
    end
    grid on; title(['\phi_{' num2str(i) ',j}: ' P.nombres_x{i}]); xlabel('entrada normalizada');
end
subplot(2,4,8); bar(imp/sum(imp), 'FaceColor', co(1,:)); set(gca,'XTickLabel', {'P_{pv}','P_w','E_b','P_h^+','f_a','f_v','f_g'});
grid on; title('Importancia relativa (desv. std. de \phi)'); ylabel('fraccion');
exportgraphics(f, fullfile(figDir,'fig_v2_8_kan_activaciones.png'), 'Resolution', 150);
writetable(table(P.nombres_x', imp/sum(imp), 'VariableNames', {'Variable','Importancia_KAN'}), fullfile(resDir,'kan_importancia.csv'));

%% Figura: mapa de atencion medio
[~, A] = lib.fwd_attn(p_att, dlarray(Xn(ite,:)), c_att);
f = figure('Position',[100 100 520 420]);
imagesc(A, [0 max(A(:))]); colormap(flipud(bone)); colorbar; hold on;
for i=1:nv, for j=1:nv, text(j,i,sprintf('%.2f',A(i,j)),'HorizontalAlignment','center','FontSize',7,'Color', 'k'); end, end
lab = {'P_{pv}','P_w','E_b','P_h^+','f_a','f_v','f_g'};
set(gca,'XTick',1:nv,'XTickLabel',lab,'YTick',1:nv,'YTickLabel',lab); xlabel('clave (variable atendida)'); ylabel('consulta');
title('Pesos medios de auto-atencion (conjunto de prueba)');
exportgraphics(f, fullfile(figDir,'fig_v2_9_atencion_mapa.png'), 'Resolution', 150);
writematrix(A, fullfile(resDir,'atencion_mapa.csv'));

%% NSGA-II asistido por el sustituto KAN vs. NSGA-II con el modelo completo
fun_true = @(x) obj_hub(x, P, S);
fun_kan  = @(x) pred(fwd_kan, p_kan, 2*(x-lb)./(ub-lb) - 1);
fprintf('  NSGA-II modelo completo ...\n'); tT = tic;
[Xt_nd, Ft_nd] = nsga2_simple(fun_true, lb, ub, 48, 60, 8); tT = toc(tT);
fprintf('  NSGA-II sustituto KAN ...\n'); tK = tic;
[Xk_nd, ~] = nsga2_simple(fun_kan, lb, ub, 48, 60, 8); tK = toc(tK);
Fk_re = zeros(size(Xk_nd,1),2); for i = 1:size(Xk_nd,1), Fk_re(i,:) = fun_true(Xk_nd(i,:)); end
ref = [1.05*max([Ft_nd(:,1);Fk_re(:,1)]), 1.05*max([Ft_nd(:,2);Fk_re(:,2)])];
hv_t = hv2d(Ft_nd, ref); hv_k = hv2d(Fk_re, ref);
fprintf('  HV completo=%.1f (%d evals, %.0f s) | HV KAN=%.1f (%d evals reales + %d re-eval, %.0f s)\n', ...
    hv_t, 48*61, tT, hv_k, N, size(Xk_nd,1), tK);
f = figure('Position',[100 100 560 400]);
plot(Ft_nd(:,1), Ft_nd(:,2), 'o-','Color',co(1,:),'MarkerFaceColor',co(1,:),'MarkerSize',4); hold on;
plot(Fk_re(:,1), Fk_re(:,2), 's','Color',co(2,:),'MarkerFaceColor',co(2,:),'MarkerSize',5);
grid on; xlabel('CO_2 (kt/anio)'); ylabel('Costo anual (MUSD/anio)');
legend({sprintf('NSGA-II modelo completo (%d evals)', 48*61), sprintf('NSGA-II sobre KAN (%d evals + %d re-eval)', N, size(Xk_nd,1))}, 'Location','northeast');
title(sprintf('Frente 2030: HV completo %.0f | asistido por KAN %.0f (%.1f%%)', hv_t, hv_k, 100*hv_k/hv_t));
exportgraphics(f, fullfile(figDir,'fig_v2_10_nsga_kan.png'), 'Resolution', 150);
Tsa = table({'NSGA-II completo';'NSGA-II asistido KAN'}, [48*61; N+size(Xk_nd,1)], [tT; tK+tS+t_kan], [hv_t; hv_k], ...
    'VariableNames', {'Metodo','Evaluaciones_reales','Tiempo_total_s','Hipervolumen'});
writetable(Tsa, fullfile(resDir,'nsga_asistido_kan.csv'));
save(fullfile(resDir,'s3_surrogates.mat'), 'X','Y','M','np','A','imp','Ft_nd','Fk_re','hv_t','hv_k','t_kan','t_mlp','t_att','tS');
fprintf('=== S3 completado en %.0f s ===\n', toc);
