function hv = hv2d(F, ref)
%HV2D Hipervolumen 2-D (minimizacion) de un conjunto de puntos F (n x 2)
%   respecto del punto de referencia REF (1 x 2). Se usa solo el frente
%   no dominado de F. Metrica de Zitzler y Thiele (1999),
%   doi:10.1109/4235.797969.
F = F(all(F <= ref, 2), :);
if isempty(F), hv = 0; return; end
F = sortrows(F, 1);
nd = true(size(F,1),1);
best2 = inf;
for i = 1:size(F,1)
    if F(i,2) < best2, best2 = F(i,2); else, nd(i) = false; end
end
F = F(nd,:);
hv = 0; prev1 = ref(1);
for i = size(F,1):-1:1
    hv = hv + (prev1 - F(i,1)) * (ref(2) - F(i,2));
    prev1 = F(i,1);
end
end
