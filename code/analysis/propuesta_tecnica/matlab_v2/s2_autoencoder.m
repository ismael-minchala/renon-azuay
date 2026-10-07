%S2_AUTOENCODER Compresion y generacion de escenarios diarios con autoencoder.
%   Cada dia se representa por un vector de 96 componentes (24 h x
%   [demanda pu, cf FV, cf eolica, cf hidro]). Se entrena un autoencoder
%   (Hinton y Salakhutdinov, 2006) con capa latente de 8 unidades, se
%   compara con PCA y se usa el espacio latente para generar anios
%   sinteticos para Monte Carlo del modelo hub.
setup_v2; tic;
fprintf('=== S2: autoencoder de escenarios ===\n');
P = renon_params_v2('lc2030');
nY = 24; Xall = []; mesall = []; yrall = [];
for y = 1:nY
    S = renon_profiles(P, 200+y);
    dem = S.dem_e / mean(S.dem_e);
    D = [reshape(dem,24,365); reshape(S.cf_pv,24,365); reshape(S.cf_wind,24,365); reshape(S.cf_hyd,24,365)]'; % 365 x 96
    Xall = [Xall; D]; mesall = [mesall; S.mes(1:24:end)]; yrall = [yrall; y*ones(365,1)];
end
tr = yrall <= 20; te = ~tr;
Xtr = Xall(tr,:); Xte = Xall(te,:);
fprintf('  datos: %d dias entrenamiento, %d prueba, %d variables\n', sum(tr), sum(te), size(Xall,2));

%% Autoencoder profundo 96-64-8-64-96 (Adam, dlarray)
hid = 8; lib = surr_lib();
mu_x = mean(Xtr); sd_x = max(std(Xtr), 1e-3);
zs = @(X) (X - mu_x)./sd_x; izs = @(Z) Z.*sd_x + mu_x;
rng(1);
pae.We1 = dlarray(randn(96,64)/sqrt(96)); pae.be1 = dlarray(zeros(1,64));
pae.We2 = dlarray(randn(64,hid)/sqrt(64)); pae.be2 = dlarray(zeros(1,hid));
pae.Wd1 = dlarray(randn(hid,64)/sqrt(hid)); pae.bd1 = dlarray(zeros(1,64));
pae.Wd2 = dlarray(randn(64,96)/sqrt(64));  pae.bd2 = dlarray(zeros(1,96));
enc = @(p,X) tanh(X*p.We1 + p.be1)*p.We2 + p.be2;
dec = @(p,Z) tanh(Z*p.Wd1 + p.bd1)*p.Wd2 + p.bd2;
fwd_ae = @(p,X) dec(p, enc(p,X));
tAE = tic;
[pae, h_ae, ~] = lib.train(fwd_ae, pae, zs(Xtr), zs(Xtr), 8000, 0.004);
tAE = toc(tAE);
encode_ = @(X) extractdata(enc(pae, dlarray(zs(X))));
decode_ = @(Z) izs(extractdata(dec(pae, dlarray(Z))));
Xrec = decode_(encode_(Xte));
% PCA con el mismo numero de componentes (linea base lineal)
[coef, ~, latent] = pca(Xtr, 'NumComponents', hid);   % PCA centrada; no se piden T^2 ni expl (columnas
mu = mean(Xtr); expl = 100*latent/sum(latent);         % nocturnas de FV nulas -> rango deficiente)
Xpca = (Xte - mu) * coef * coef' + mu;
blk = {1:24, 25:48, 49:72, 73:96}; nomb = {'Demanda','FV','Eolica','Hidro'};
nr = zeros(2,4);
for b = 1:4
    ref = Xte(:,blk{b});
    nr(1,b) = sqrt(mean((Xrec(:,blk{b})-ref).^2,'all'))/mean(ref,'all');
    nr(2,b) = sqrt(mean((Xpca(:,blk{b})-ref).^2,'all'))/mean(ref,'all');
end
r_ae = corr(Xrec(:), Xte(:)); r_pca = corr(Xpca(:), Xte(:));
fprintf('  NRMSE AE  : %s | r=%.4f | %.0f s\n', mat2str(100*nr(1,:),3), r_ae, tAE);
fprintf('  NRMSE PCA : %s | r=%.4f | var.expl=%.1f%%\n', mat2str(100*nr(2,:),3), r_pca, sum(expl(1:hid)));
Tae = table(nomb', 100*nr(1,:)', 100*nr(2,:)', 'VariableNames', {'Variable','NRMSE_AE_pct','NRMSE_PCA_pct'});
writetable(Tae, fullfile(resDir,'autoencoder_reconstruccion.csv'));

%% Espacio latente
Z = encode_(Xall);                                   % n x 8
Zte = Z(te,:);
% separabilidad estacional: ratio varianza entre-meses / total en las 2 primeras dims
zm = zeros(12,hid); for mth = 1:12, zm(mth,:) = mean(Z(mesall==mth,:)); end
sep = var(zm(:,1:2)) ./ var(Z(:,1:2));

%% Generacion de anios sinteticos desde el espacio latente
Ngen = 200; sigZ = std(Z); xk = [255.3 150 0 30 0.332 0.838 0];
Sbase = renon_profiles(P, 1); Zb = encode_(buildX(Sbase));         % codigos del anio base
mc_ae = zeros(Ngen,3); mc_par = zeros(Ngen,3);
rng(7);
% perturbacion latente jerarquica: componente anual persistente (variabilidad
% interanual, p.ej. ENOS) + componente mensual + componente diaria
mes_b = Sbase.mes(1:24:end);
for i = 1:Ngen
    e_anio = 0.5*sigZ.*randn(1,hid);
    e_mes  = 0.35*sigZ.*randn(12,hid);
    Zi = Zb + e_anio + e_mes(mes_b,:) + 0.3*sigZ.*randn(365,hid);
    Xi = decode_(Zi);                                 % 365 x 96
    Si = Sbase;
    Si.dem_e  = max(reshape(Xi(:,1:24)',[],1),0.3) * mean(Sbase.dem_e);
    Si.cf_pv  = min(max(reshape(Xi(:,25:48)',[],1),0),1);
    Si.cf_wind= min(max(reshape(Xi(:,49:72)',[],1),0),1);
    Si.cf_hyd = min(max(reshape(Xi(:,73:96)',[],1),0.05),1);
    Ri = renon_hub(xk, P, Si);
    mc_ae(i,:) = [Ri.co2, Ri.costo, Ri.resiliencia];
    % Monte Carlo parametrico de referencia (v1)
    pert.hyd = min(max(0.95+0.12*randn,0.55),1.15); pert.pv = min(max(1+0.05*randn,0.85),1.15);
    pert.wind = min(max(1+0.08*randn,0.75),1.25); pert.dem = min(max(1+0.04*randn,0.9),1.12); pert.prec = 1;
    Sp = renon_profiles(P, 100+i, pert); Rp = renon_hub(xk, P, Sp);
    mc_par(i,:) = [Rp.co2, Rp.costo, Rp.resiliencia];
end
q = @(v) [median(v), prctile(v,5), prctile(v,95)];
fprintf('  MC-AE  : CO2 %s | costo %s\n', mat2str(q(mc_ae(:,1)),4), mat2str(q(mc_ae(:,2)),4));
fprintf('  MC-par : CO2 %s | costo %s\n', mat2str(q(mc_par(:,1)),4), mat2str(q(mc_par(:,2)),4));
Tmc = table({'MC autoencoder';'MC parametrico'}, [q(mc_ae(:,1)); q(mc_par(:,1))], [q(mc_ae(:,2)); q(mc_par(:,2))], ...
    [min(mc_ae(:,3)); min(mc_par(:,3))], 'VariableNames', {'Metodo','CO2_med_P5_P95','Costo_med_P5_P95','Resil_min'});
writetable(Tmc, fullfile(resDir,'autoencoder_montecarlo.csv'));

%% Figuras
f = figure('Position',[100 100 1000 640]);
subplot(2,2,1); d = find(te,1)+ 280;   % un dia de estiaje del anio de prueba
plot(1:24, Xall(d,1:24),'k-','LineWidth',1.5); hold on; plot(1:24, Xrec(d-find(te,1)+1,1:24),'-','Color',co(1,:),'LineWidth',1.2);
plot(1:24, Xpca(d-find(te,1)+1,1:24),'--','Color',co(5,:),'LineWidth',1.0);
grid on; xlabel('hora'); ylabel('demanda (pu)'); title('Reconstruccion de un dia de prueba (demanda)');
legend({'Original','Autoencoder (8)','PCA (8)'},'Location','northwest');
subplot(2,2,2);
plot(1:24, Xall(d,25:48),'k-','LineWidth',1.5); hold on; plot(1:24, Xrec(d-find(te,1)+1,25:48),'-','Color',co(2,:),'LineWidth',1.2);
plot(1:24, Xpca(d-find(te,1)+1,25:48),'--','Color',co(5,:),'LineWidth',1.0);
grid on; xlabel('hora'); ylabel('cf FV'); title('Reconstruccion (factor de planta FV)');
legend({'Original','Autoencoder (8)','PCA (8)'},'Location','northwest');
subplot(2,2,3);
scatter(Z(te,1), Z(te,2), 8, mesall(te), 'filled'); colormap(gca, turbo(12)); cb = colorbar; cb.Label.String = 'mes';
grid on; xlabel('z_1'); ylabel('z_2'); title(sprintf('Espacio latente (dias de prueba); separabilidad estacional = %.2f / %.2f', sep(1), sep(2)));
subplot(2,2,4);
histogram(mc_par(:,1), 20, 'FaceColor', co(5,:), 'FaceAlpha', 0.6); hold on;
histogram(mc_ae(:,1), 20, 'FaceColor', co(1,:), 'FaceAlpha', 0.6);
grid on; xlabel('CO_2 (kt/anio)'); ylabel('frecuencia'); title('Monte Carlo (N=200): parametrico vs. autoencoder');
legend({'Parametrico (v1)','Muestreo latente AE'},'Location','northwest');
exportgraphics(f, fullfile(figDir,'fig_v2_5_autoencoder.png'), 'Resolution', 150);
save(fullfile(resDir,'s2_autoencoder.mat'), 'nr','r_ae','r_pca','sep','mc_ae','mc_par','tAE','expl','h_ae');
fprintf('=== S2 completado en %.0f s ===\n', toc);

function X = buildX(S)
dem = S.dem_e / mean(S.dem_e);
X = [reshape(dem,24,365); reshape(S.cf_pv,24,365); reshape(S.cf_wind,24,365); reshape(S.cf_hyd,24,365)]';
end
