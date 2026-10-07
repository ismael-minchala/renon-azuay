function lib = surr_lib()
%SURR_LIB Biblioteca de modelos sustitutos diferenciables (dlarray):
%   KAN (Liu et al., 2024/ICLR 2025), MLP y modelo con auto-atencion
%   (Vaswani et al., 2017). Devuelve una estructura de manejadores.
lib.init_kan  = @init_kan;   lib.fwd_kan  = @fwd_kan;
lib.init_mlp  = @init_mlp;   lib.fwd_mlp  = @fwd_mlp;
lib.init_attn = @init_attn;  lib.fwd_attn = @fwd_attn;
lib.train     = @train;      lib.nparams  = @nparams;
lib.bspline   = @bspline_basis;
end

% ======================= KAN ==========================================
function [p, c] = init_kan(nin, nhid, nout, G, k, rango_in, rango_hid)
% Cada arista: phi(x) = w_b * silu(x) + sum_b c_b B_b(x)   (B-splines cubicos)
% p: parametros entrenables (dlarray); c: constantes (nudos, orden)
rng(1);
c.t1 = knots(rango_in, G, k);  c.t2 = knots(rango_hid, G, k); c.k = k; nb = G + k;
p.L1_wb = dlarray(randn(nin, nhid)/sqrt(nin));
p.L1_C  = dlarray(0.1*randn(nin, nhid, nb)/sqrt(nin));
p.L2_wb = dlarray(randn(nhid, nout)/sqrt(nhid));
p.L2_C  = dlarray(0.1*randn(nhid, nout, nb)/sqrt(nhid));
end
function t = knots(rango, G, k)
h = (rango(2)-rango(1))/G;
t = rango(1) - k*h : h : rango(2) + k*h;
end
function Y = fwd_kan(p, X, c)
H = kan_layer(X, p.L1_wb, p.L1_C, c.t1, c.k);
Y = kan_layer(H, p.L2_wb, p.L2_C, c.t2, c.k);
end
function Y = kan_layer(X, wb, C, t, k)
B = bspline_basis(X, t, k);
Y = (X .* sigmoid(X)) * wb;
for b = 1:size(C,3), Y = Y + B(:,:,b) * C(:,:,b); end
end
function B = bspline_basis(X, t, k)
% Cox-de Boor; X: N x n, t: nudos; devuelve N x n x (numel(t)-k-1)
Xd = X; if isa(X,'dlarray'), Xd = extractdata(X); end
nt = numel(t);
B = cell(1, nt-1);
for i = 1:nt-1, B{i} = double(Xd >= t(i) & Xd < t(i+1)); end
for d = 1:k
    Bn = cell(1, nt-1-d);
    for i = 1:nt-1-d
        den1 = t(i+d)-t(i); den2 = t(i+d+1)-t(i+1);
        term = 0;
        if den1 > 0, term = term + ((X - t(i))/den1) .* B{i}; end
        if den2 > 0, term = term + ((t(i+d+1) - X)/den2) .* B{i+1}; end
        Bn{i} = term;
    end
    B = Bn;
end
B = cat(3, B{:});
end

% ======================= MLP ==========================================
function p = init_mlp(nin, nh, nout)
rng(1);
p.W1 = dlarray(randn(nin,nh)/sqrt(nin));  p.b1 = dlarray(zeros(1,nh));
p.W2 = dlarray(randn(nh,nh)/sqrt(nh));    p.b2 = dlarray(zeros(1,nh));
p.W3 = dlarray(randn(nh,nout)/sqrt(nh));  p.b3 = dlarray(zeros(1,nout));
end
function Y = fwd_mlp(p, X)
H = tanh(X*p.W1 + p.b1); H = tanh(H*p.W2 + p.b2); Y = H*p.W3 + p.b3;
end

% ======================= Auto-atencion ================================
function [p, c] = init_attn(nin, d, nh, nout)
% tokens: e_i = x_i v_i + b_i (R^d); una cabeza de atencion; cabeza MLP
rng(1); c.nin = nin; c.d = d;
p.V = dlarray(randn(nin,d)/sqrt(d)); p.Bt = dlarray(0.1*randn(nin,d));
p.Wq = dlarray(randn(d,d)/sqrt(d)); p.Wk = dlarray(randn(d,d)/sqrt(d)); p.Wv = dlarray(randn(d,d)/sqrt(d));
p.W1 = dlarray(randn(nin*d,nh)/sqrt(nin*d)); p.b1 = dlarray(zeros(1,nh));
p.W2 = dlarray(randn(nh,nout)/sqrt(nh));     p.b2 = dlarray(zeros(1,nout));
end
function [Y, A] = fwd_attn(p, X, c)
n = c.nin; d = c.d;
T = cell(1,n); Q = cell(1,n); K = cell(1,n); V = cell(1,n);
for i = 1:n
    T{i} = X(:,i) .* p.V(i,:) + p.Bt(i,:);      % N x d
    Q{i} = T{i}*p.Wq; K{i} = T{i}*p.Wk; V{i} = T{i}*p.Wv;
end
Z = cell(1,n); A = zeros(n,n);
for i = 1:n
    s = cell(1,n);
    for j = 1:n, s{j} = sum(Q{i}.*K{j}, 2)/sqrt(d); end   % N x 1
    Smat = cat(2, s{:});                                   % N x n
    Smat = Smat - max(Smat, [], 2);
    Ew = exp(Smat); a = Ew ./ sum(Ew, 2);                  % softmax sobre claves
    Zi = T{i};
    for j = 1:n, Zi = Zi + a(:,j) .* V{j}; end             % residual + atencion
    Z{i} = Zi;
    if nargout > 1, A(i,:) = mean(extractdata(a), 1); end
end
Hf = cat(2, Z{:});                                         % N x (n d)
H = tanh(Hf*p.W1 + p.b1); Y = H*p.W2 + p.b2;
end

% ======================= Entrenamiento (Adam) =========================
function [p, hist, tt] = train(fwd, p, X, Y, iters, lr)
avg = []; avgsq = []; hist = zeros(iters,1); t0 = tic;
Xd = dlarray(X); Yd = dlarray(Y);
for it = 1:iters
    [loss, g] = dlfeval(@lossfun, fwd, p, Xd, Yd);
    lr_it = lr * 0.5*(1 + cos(pi*it/iters)) + 1e-4;
    [p, avg, avgsq] = adamupdate(p, g, avg, avgsq, it, lr_it);
    hist(it) = double(extractdata(loss));
end
tt = toc(t0);
end
function [loss, g] = lossfun(fwd, p, X, Y)
Yp = fwd(p, X);
loss = mean((Yp - Y).^2, 'all');
g = dlgradient(loss, p);
end
function n = nparams(p)
n = 0; f = fieldnames(p);
for i = 1:numel(f), v = p.(f{i}); if isa(v,'dlarray'), n = n + numel(v); end, end
end
