function F = objetivos(x, P, S)
%OBJETIVOS Vector de objetivos [CO2 (kt/anio), costo (MUSD/anio)] para NSGA-II.
R = renon_dispatch(x, P, S);
F = [R.co2, R.costo];
end
