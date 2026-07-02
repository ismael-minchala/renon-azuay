function [Xnd, Fnd, hist] = nsga2_simple(fun, lb, ub, npop, ngen, semilla)
%NSGA2_SIMPLE Implementacion compacta de NSGA-II (2 objetivos, minimizar).
%   [XND, FND] = NSGA2_SIMPLE(FUN, LB, UB, NPOP, NGEN, SEMILLA) evoluciona
%   una poblacion de NPOP individuos durante NGEN generaciones. FUN recibe
%   un vector fila x y devuelve [f1 f2]. Devuelve el frente no dominado.
%   Operadores: seleccion binaria por torneo (rango, distancia de
%   aglomeracion), cruce SBX (eta=15, prob 0.9) y mutacion polinomial
%   (eta=20, prob 1/nvar), como en Viesi et al. (2020).

rng(semilla,'twister');
nv = numel(lb); lb = lb(:)'; ub = ub(:)';
X = lb + rand(npop,nv).*(ub-lb);
F = zeros(npop,2);
for i = 1:npop, F(i,:) = fun(X(i,:)); end
hist = cell(ngen,1);

for g = 1:ngen
    [rk, cd] = rango_cd(F);
    % --- seleccion por torneo binario ---
    padres = zeros(npop, nv);
    for i = 1:npop
        a = randi(npop); b = randi(npop);
        if rk(a)<rk(b) || (rk(a)==rk(b) && cd(a)>cd(b)), w=a; else, w=b; end
        padres(i,:) = X(w,:);
    end
    % --- cruce SBX ---
    Q = padres;
    for i = 1:2:npop-1
        if rand < 0.9
            u = rand(1,nv);
            beta = (2*u).^(1/16); m = u>0.5;
            beta(m) = (1./(2*(1-u(m)))).^(1/16);
            p1 = padres(i,:); p2 = padres(i+1,:);
            Q(i,:)   = 0.5*((1+beta).*p1 + (1-beta).*p2);
            Q(i+1,:) = 0.5*((1-beta).*p1 + (1+beta).*p2);
        end
    end
    % --- mutacion polinomial ---
    pm = 1/nv;
    for i = 1:npop
        for j = 1:nv
            if rand < pm
                u = rand;
                if u < 0.5, d = (2*u)^(1/21)-1; else, d = 1-(2*(1-u))^(1/21); end
                Q(i,j) = Q(i,j) + d*(ub(j)-lb(j));
            end
        end
    end
    Q = min(max(Q, lb), ub);
    FQ = zeros(npop,2);
    for i = 1:npop, FQ(i,:) = fun(Q(i,:)); end
    % --- seleccion ambiental (elitista) ---
    XT = [X; Q]; FT = [F; FQ];
    [rkT, cdT] = rango_cd(FT);
    [~, orden] = sortrows([rkT, -cdT]);
    sel = orden(1:npop);
    X = XT(sel,:); F = FT(sel,:);
    hist{g} = F;
end
rk = rango_cd(F);
Xnd = X(rk==1,:); Fnd = F(rk==1,:);
[~,o] = sort(Fnd(:,1)); Fnd = Fnd(o,:); Xnd = Xnd(o,:);
end

function [rk, cd] = rango_cd(F)
%RANGO_CD Rango de no dominancia y distancia de aglomeracion (2 objetivos).
n = size(F,1); rk = zeros(n,1);
resta = true(n,1); r = 0;
while any(resta)
    r = r + 1;
    idx = find(resta);
    Fi = F(idx,:);
    nd = true(numel(idx),1);
    for i = 1:numel(idx)
        d = (Fi(:,1)<=Fi(i,1) & Fi(:,2)<=Fi(i,2)) & ...
            (Fi(:,1)< Fi(i,1) | Fi(:,2)< Fi(i,2));
        if any(d), nd(i) = false; end
    end
    rk(idx(nd)) = r; resta(idx(nd)) = false;
    if ~any(nd), rk(idx) = r; break; end   % salvaguarda
end
cd = zeros(n,1);
for r = 1:max(rk)
    idx = find(rk==r);
    if numel(idx) <= 2, cd(idx) = inf; continue; end
    for m = 1:2
        [v,o] = sort(F(idx,m));
        rango = max(v(end)-v(1), eps);
        cd(idx(o(1))) = inf; cd(idx(o(end))) = inf;
        for k = 2:numel(idx)-1
            cd(idx(o(k))) = cd(idx(o(k))) + (v(k+1)-v(k-1))/rango;
        end
    end
end
end
