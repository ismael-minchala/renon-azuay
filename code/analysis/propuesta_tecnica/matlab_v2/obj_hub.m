function F = obj_hub(x, P, S, opt)
%OBJ_HUB Vector de objetivos [CO2 (kt/anio), costo (MUSD/anio)] del modelo hub.
if nargin < 4, opt = struct(); end
R = renon_hub(x, P, S, opt);
F = [R.co2, R.costo];
end
