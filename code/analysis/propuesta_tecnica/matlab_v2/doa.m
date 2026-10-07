function [xbest, fbest, hist, nev] = doa(fun, lb, ub, N, T, semilla, opt)
%DOA Dream Optimization Algorithm (reimplementacion) - minimizacion.
%   [XBEST, FBEST, HIST] = DOA(FUN, LB, UB, N, T, SEMILLA) minimiza FUN
%   (vector fila -> escalar) con N agentes durante T iteraciones.
%
%   Reimplementacion propia de las tres estrategias descritas por Lang y
%   Gao (2025), Comput. Methods Appl. Mech. Eng. 436:117718,
%   doi:10.1016/j.cma.2024.117718:
%     (1) memoria: cada grupo conserva su mejor solucion (sueno recordado);
%     (2) olvido y suplementacion: se olvidan k dimensiones, reemplazadas
%         con perturbaciones cuya amplitud decrece con el coseno del
%         progreso de la busqueda;
%     (3) intercambio de suenos: dimensiones copiadas de otros agentes.
%   La fase de exploracion (fraccion p_ex de las iteraciones) opera por
%   grupos; la fase de explotacion refina el mejor global. Los parametros
%   por defecto (m=5 grupos, p_ex=0,9, p_olvido=0,3) son los adoptados en
%   este trabajo; no se utilizo el codigo original de los autores.

if nargin < 7, opt = struct(); end
m     = getf(opt,'m',5);
p_ex  = getf(opt,'p_ex',0.9);
p_olv = getf(opt,'p_olv',0.3);
rng(semilla,'twister');
D = numel(lb); lb = lb(:)'; ub = ub(:)'; rango = ub - lb;
X = lb + rand(N,D).*rango;
F = zeros(N,1); for i = 1:N, F(i) = fun(X(i,:)); end
nev = N;
[fbest, ib] = min(F); xbest = X(ib,:);
hist = zeros(T,1);
grp = mod((0:N-1)', m) + 1;                 % asignacion a grupos
T_ex = round(p_ex*T);

for it = 1:T
    amp = 0.5*(1 + cos(pi*it/T));           % amplitud decreciente (1 -> 0)
    if it <= T_ex
        % ---------- exploracion por grupos ----------
        for g = 1:m
            ig = find(grp == g);
            [~, jb] = min(F(ig)); xg = X(ig(jb),:);      % memoria del grupo
            kmin = max(1, ceil(D/(8*g))); kmax = max(kmin, ceil(D/(3*g)));
            for i = ig'
                xn = xg;                                   % recuerda el mejor del grupo
                k = randi([kmin, kmax]); dims = randperm(D, k);
                for d = dims
                    if rand < p_olv                        % olvido + suplementacion
                        xn(d) = xn(d) + (2*rand-1)*rango(d)*amp;
                    else                                   % intercambio de suenos
                        xn(d) = X(randi(N), d);
                    end
                end
                xn = min(max(xn, lb), ub);
                fn = fun(xn); nev = nev + 1;
                if fn < F(i), X(i,:) = xn; F(i) = fn; end  % aceptacion codiciosa
            end
        end
    else
        % ---------- explotacion alrededor del mejor global ----------
        for i = 1:N
            xn = xbest + randn(1,D).*rango*0.05*amp;
            xn = min(max(xn, lb), ub);
            fn = fun(xn); nev = nev + 1;
            if fn < F(i), X(i,:) = xn; F(i) = fn; end
        end
    end
    [fm, ib] = min(F);
    if fm < fbest, fbest = fm; xbest = X(ib,:); end
    hist(it) = fbest;
end
end

function v = getf(s, f, d)
if isfield(s, f), v = s.(f); else, v = d; end
end
