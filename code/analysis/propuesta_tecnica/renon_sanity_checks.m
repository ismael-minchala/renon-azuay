function chk = renon_sanity_checks(R, P, S, x, tol)
%RENON_SANITY_CHECKS Physical and numerical consistency of a dispatch result.
%
%   CHK = RENON_SANITY_CHECKS(R, P, S, X) verifies the output R of
%   renon_dispatch (v1) or renon_hub (v2) for parameters P, profiles S and
%   decision vector X. CHK.all_ok is true when every check passes;
%   CHK.failed lists the names of the failed checks. TOL (default 1e-6)
%   is the absolute tolerance in MW / MWh.
%
%   Checks
%   ------
%   finite        all indicators and series are finite (no NaN/Inf)
%   balance       hourly electricity balance closes:
%                 load = renewables + battery + import + thermal + ENS - curtailment
%                 (+ V2G discharge in v2; the V2G recharge is part of the load)
%   nonneg        import, thermal, ENS, curtailment, flexible loads >= 0
%   import_cap    import <= P.cap_imp
%   thermal_cap   thermal <= P.P_th
%   battery_power |battery power| <= E_bat/3 (C/3 rating)
%   battery_soc   state of charge stays within [0, E_bat] when reintegrated
%                 from the power series with the 95 % one-way efficiency
%   flex_energy   daily flexible energy equals f_a*E_bomb_day + f_v*E_ev_day
%   flex_power    pumping and smart-charging power within their caps
%   frac_ren      renewable fraction within [0, 1]
%   resilience    resilience index within [0, 1]
%   v2g_window    (v2) V2G discharge only inside P.h_v2g hours; recharge
%                 energy = discharge / eta_v2g per day
%   coupling      (v2) rows of the mean coupling matrix C sum to ~1 for the
%                 vectors that are served (electricity and water), and the
%                 mobility row sums to ~1 including the fuel share
%
%   See also RUN_RENON_MODEL, RENON_DISPATCH, RENON_HUB.

if nargin < 5, tol = 1e-6; end
s = R.s;
isv2 = isfield(s, 'v2g');
res = struct();

% ---- finiteness -------------------------------------------------------
ind = [R.co2 R.costo R.ens R.vert R.imp R.th R.frac_ren R.resiliencia R.gen R.dem_total];
res.finite = all(isfinite(ind)) && all(isfinite(s.carga)) && all(isfinite(s.imp)) && all(isfinite(s.bat));

% ---- hourly balance ---------------------------------------------------
if isv2
    % s.carga already contains the V2G recharge (it is a load), so only the discharge enters here
    bal = s.carga - s.ren - s.bat - s.v2g - s.imp - s.th - s.ens + s.vert;
else
    bal = s.carga - s.ren - s.bat - s.imp - s.th - s.ens + s.vert;
end
res.balance_residual_MW = max(abs(bal));
res.balance = res.balance_residual_MW < tol;

% ---- non-negativity and capacities ------------------------------------
if isv2, flex = s.flex_w + s.flex_m; else, flex = s.flex; end
res.nonneg      = min([s.imp; s.th; s.ens; s.vert; flex]) > -tol;
res.import_cap  = all(s.imp <= P.cap_imp + tol);
res.thermal_cap = all(s.th  <= P.P_th + tol);

% ---- battery ----------------------------------------------------------
E_bat = x(3);
res.battery_power = all(abs(s.bat) <= E_bat/3 + tol);
eta = 0.95; soc = 0.5*E_bat; socmin = soc; socmax = soc;
for t = 1:numel(s.bat)
    if s.bat(t) < 0, soc = soc - s.bat(t)*eta; else, soc = soc - s.bat(t)/eta; end
    socmin = min(socmin, soc); socmax = max(socmax, soc);
end
res.battery_soc = socmin > -tol && socmax < E_bat + tol;

% ---- flexible loads ---------------------------------------------------
f_a = x(5); f_v = x(6);
fd = reshape(flex, 24, []);
E_day = f_a*S.E_bomb_dia + f_v*S.E_ev_dia;
res.flex_energy_dev_MWh = max(abs(sum(fd, 1)' - E_day));
res.flex_energy = res.flex_energy_dev_MWh < 1e-6*max(1, E_day);
P_sev_max = max(S.P_ev_max, f_v*S.E_ev_dia/6);
if isv2
    res.flex_power = all(s.flex_w <= S.P_bomb_max + tol) && all(s.flex_m <= P_sev_max + tol);
else
    res.flex_power = all(flex <= S.P_bomb_max + P_sev_max + tol);
end

% ---- indicators -------------------------------------------------------
res.frac_ren   = R.frac_ren >= -tol && R.frac_ren <= 1 + tol;
res.resilience = R.resiliencia >= -tol && R.resiliencia <= 1 + tol;

% ---- v2 specific ------------------------------------------------------
if isv2
    hw = P.h_v2g(1):P.h_v2g(2);
    outside = ~ismember(S.hod, hw);
    dis_d = sum(reshape(s.v2g, 24, []), 1); rec_d = sum(reshape(s.v2g_rec, 24, []), 1);
    res.v2g_window = all(s.v2g(outside) <= tol) && all(abs(rec_d - dis_d/P.eta_v2g) < 1e-6*max(1, max(dis_d)));
    rs = sum(R.C, 2);
    res.coupling = all(abs(rs - 1) < 0.02) && all(R.C(:) >= -tol);
end

% ---- aggregate --------------------------------------------------------
names = fieldnames(res);
failed = {};
for k = 1:numel(names)
    v = res.(names{k});
    if islogical(v) && ~v, failed{end+1} = names{k}; end %#ok<AGROW>
end
chk = res;
chk.failed = failed;
chk.all_ok = isempty(failed);
end
