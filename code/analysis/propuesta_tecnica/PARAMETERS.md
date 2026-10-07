# Parámetros del modelo ReNoN-Azuay

Fuente de verdad: `matlab/renon_params.m` (v1) y `matlab_v2/renon_params_v2.m` (v2,
que llama a la primera y añade los bloques V2G y atención). Las constantes que viven
dentro de las funciones de despacho y de los scripts también se listan aquí para que
no haya "números mágicos" sin explicar. Los valores provinciales son **estimaciones de
ingeniería** a calibrar con los datos de CENTROSUR, ETAPA y GAD Cuenca (PT1); los
nacionales provienen del reporte técnico PT1 y del artículo Ortega, Minchala y
Arévalo (Electronics 2026).

## 1. Escenarios (`renon_params`)

| Parámetro | base2024 | lc2030 | lc2050 | Unidad | Significado / fuente |
|---|---|---|---|---|---|
| `E_dem` | 1 300 000 | 1 300 000·1,18 | 1 300 000·1,80 | MWh/año | demanda eléctrica pura, área CENTROSUR; crecimiento 2,8 %/a (2030), 2,3 %/a (2050), PME |
| `flota` | 130 000 | 140 000 | 165 000 | veh | flota liviana provincial (ANT, estim.) |
| `x_ev` | 0,01 | 0,25 | 0,90 | – | penetración de VE (metas del Formulario 2) |
| `vol_agua` | 2,2 | 2,4 | 3,2 | m³/s | producción media de agua potable (ETAPA, estim.) |
| `cap_imp` | 250 | 250 | 350 | MW | límite de importación desde el SNI |
| `lb` / `ub` | ver tabla de variables de decisión en `MODEL_ARCHITECTURE.md` | | | | |

## 2. Parque existente y térmica local

| Parámetro | Valor | Unidad | Significado | Usado en |
|---|---|---|---|---|
| `hyd0` | 40 | MW | hidro de pasada local (Saucay + Saymirín) | dispatch, hub |
| `wind0` | 50 | MW | eólica Minas de Huascachaca | dispatch, hub, lb |
| `pv0` | 5 | MW | FV distribuida existente (estim.) | dispatch, hub, lb |
| `P_th` | 20 | MW | térmica MCI local de respaldo (El Descanso) | dispatch, hub |
| `ef_th` | 0,70 | tCO₂/MWh | factor de emisión MCI | CO₂ |
| `c_th` | 190 | USD/MWh | costo variable térmica | costo |
| (constante) 0,9 | – | – | factor de planta de la mini-hidro nueva relativo al perfil existente | `renon_dispatch` L21, `renon_hub` L32 |

## 3. Vector agua potable

| Parámetro | Valor | Unidad | Significado |
|---|---|---|---|
| `frac_bombeo` (φ_b) | 0,25 | – | fracción del caudal que requiere bombeo |
| `e_bombeo` | 0,40 | kWh/m³ | energía específica de bombeo |
| `e_trat` | 0,06 | kWh/m³ | energía específica de tratamiento (carga fija) |
| `horas_tanque` | 12 | h | autonomía de tanques (justifica el bombeo diferible; no se usa numéricamente) |
| (constante) 2,5 | – | – | capacidad de bombeo instalada = 2,5 × potencia media (`P_bomb_max`, `renon_profiles` L77) |
| (constante) 0,25·sin(·) | – | – | forma diurna del consumo de agua 6–18 h (`renon_profiles` L71) |

## 4. Vector movilidad eléctrica

| Parámetro | Valor | Unidad | Significado |
|---|---|---|---|
| `km_anio` (d_a) | 11 000 | km/año | recorrido anual por vehículo |
| `e_km` | 0,20 | kWh/km | consumo desde red (incluye eficiencia de carga) |
| `ef_ice` | 0,25 | kgCO₂/km | emisión de un vehículo de combustión |
| perfil fijo | [0,10 0,22 0,26 0,20 0,14 0,08] en 18–23 h | – | carga no inteligente al llegar a casa (`renon_profiles` L83) |
| (constante) 6 h | – | – | ventana mínima de carga inteligente: `P_ev_max = E_ev_dia/6` |

### V2G (sólo v2, `renon_params_v2`)

| Parámetro | Valor | Unidad | Significado |
|---|---|---|---|
| `p_plug` | 3,3 | kW | potencia del cargador bidireccional |
| `disp_v2g` (δ) | 0,30 | – | fracción de VE conectados en el pico vespertino |
| `frac_E_v2g` (φ) | 0,20 | – | máx. fracción de la energía diaria VE descargable |
| `eta_v2g` | 0,85 | – | eficiencia de ciclo descarga–recarga |
| `c_v2g` | 60 | USD/MWh | degradación de batería por descarga |
| `c_v2g_cap` | 150 | USD/VE·año | cargador bidireccional anualizado |
| `h_v2g` | [18, 22] | h | ventana de descarga |
| (constante) 4 h, ×1,5 | – | – | recarga en las 4 h de menor carga neta con potencia ≤ 1,5·P_v2g (`renon_hub` L103–110) |

## 5. Red nacional (SNI)

| Parámetro | Valor (ene … dic) | Unidad |
|---|---|---|
| `ef_mes` (λ) | 0,10 0,08 0,08 0,08 0,10 0,12 0,15 0,20 0,25 0,35 0,35 0,28 | tCO₂/MWh |
| `prec_mes` (π) | 55 50 50 52 58 65 72 85 95 115 110 90 | USD/MWh |
| ruido | λ: ±5 % (mín 0,02); π: ±8 % | – |

Perfil estacional: bajo en época húmeda (despacho hidro), alto en estiaje oct–dic por
despacho térmico (vulnerabilidad documentada en el PT1 y en Electronics 2026).

## 6. Recurso renovable

| Parámetro | Valor | Significado |
|---|---|---|
| `cf_hyd_mes` | 0,65 0,72 0,78 0,80 0,78 0,72 0,60 0,45 0,40 0,35 0,38 0,50 | hidro de pasada: húmedo feb–jun, estiaje oct–dic; persistencia semanal ±15 % |
| `cf_wind_mes` | 0,24 0,22 0,22 0,25 0,28 0,34 0,38 0,36 0,32 0,28 0,26 0,24 | alisios jun–sep; factor horario 0,85 + 0,3·cos²; persistencia ±25 %; ruido ±10 % |
| `claridad_media` | 0,62 | índice de claridad (Cuenca, GHI ≈ 4,4 kWh/m²/d); campana solar 5:30–18:30, exponente 1,4 |

## 7. Costos (anualizados, CRF r = 6 %)

| Parámetro | Expresión | Valor | Unidad |
|---|---|---|---|
| `c_pv` | 750·0,0782 + 10 | 68,7 | USD/kW·año (25 años) |
| `c_wind` | 1300·0,0782 + 30 | 131,7 | USD/kW·año (25 años) |
| `c_bat` | 280·0,1193 + 5 | 38,4 | USD/kWh·año (12 años) |
| `c_hyd` | 2200·0,0726 + 40 | 199,7 | USD/kW·año (30 años) |
| `c_flex_agua` | – | 1,2·10⁶ | USD/año por unidad de f_a (retrofit bombeo + SCADA) |
| `c_smart_ev` | – | 25 | USD/VE·año |
| `voll` | – | 10 000 | USD/MWh de ENS |

## 8. Batería estacionaria (constantes en el despacho)

| Constante | Valor | Dónde |
|---|---|---|
| potencia | E_b / 3 (C/3) | `renon_dispatch` L64, `renon_hub` L69 |
| eficiencia por sentido | 0,95 (90 % ciclo) | ídem |
| SOC inicial | 0,5·E_b | ídem |

## 9. Generador de perfiles (`renon_profiles`)

| Constante | Valor | Significado |
|---|---|---|
| `forma_dia` | 24 valores pu, pico 1,48 a las 19 h | curva de carga residencial–comercial del austro |
| fin de semana | −10 % | `f_sem` |
| estacionalidad demanda | ±2 % | `f_mes_dem` |
| ruido demanda | 3 % (mín 0,8) | `ruido_d` |

## 10. Optimización y experimentos

| Parámetro | Valor | Dónde |
|---|---|---|
| NSGA-II población / generaciones | 48 / 60 (2928 evaluaciones) | `main_renon`, `s1_hub`, `s3`, `s4` |
| SBX η_c, p_c; mutación η_m, p_m | 15, 0,9; 20, 1/n | `nsga2_simple` |
| DOA m, p_ex, p_olv | 5, 0,9, 0,3 | `doa` |
| DOA mono-objetivo N, T (presupuesto) | 60, 49 (3000) | `s4_doa` |
| penalización ρ, J₁ᵐᵃˣ | 5 MUSD/kt, 415 kt | `s4_doa` |
| Tchebycheff z*, r, pesos, N, T | [370, 65], [180, 70], 12, 24, 10 | `s4_doa` |
| EMS atención θ por defecto; límites de sintonización | [1 1 1 0,30]; [0 0 0 0,02]–[3 3 3 2] | `renon_params_v2`, `s5` |
| J_EMS = J₂ + 0,2·J₁ | 0,2 MUSD/kt (≈ 200 USD/t) | `s5` |
| tarifa horaria (TOU) | valle 0–6 h ×0,7, punta 18–22 h ×1,6; FE mediodía ×0,8, punta ×1,4 | `s5` |
| LHS | N = 600 (480 entrenamiento, 120 prueba), maximin 20 it. | `s3` |
| KAN | [7, 6, 2], G = 5, k = 3, dominio [−1,1; 1,1] / [−3, 3] | `s3`, `surr_lib` |
| MLP; atención | [7, 32, 32, 2]; d = 8, oculta 32 | `s3` |
| entrenamiento sustitutos | Adam 2500 it., lr 0,01 (coseno) | `s3` |
| autoencoder | 96–64–8–64–96; 24 años sintéticos (20 train); Adam 8000 it., lr 0,004 | `s2` |
| perturbación latente | σ_a = 0,5σ_z, σ_m = 0,35σ_z, σ_d = 0,3σ_z; N = 200 | `s2` |
| estrés sequía | hidro ×0,5, λ ×1,5, π ×1,8 (oct–dic); cap_imp ×0,7 | `main_renon` §4, `s1`, `s5`, `run_renon_model` |
| Monte Carlo v1 | N = 200; hidro 0,95±0,12 [0,55; 1,15], FV ±5 %, eólica ±8 %, demanda ±4 %, precio ±15 % | `main_renon` §5 |

## 11. Semillas (reproducibilidad)

| Uso | Semilla | Dónde |
|---|---|---|
| perfiles del año tipo | 1 | todos |
| NSGA-II 2030 / 2050 | 8 / 9 (`7+e`) | `main_renon`, `s1_hub`; 8 en `s3`, `s4` |
| Monte Carlo paramétrico | 100 + i | `main_renon`, `s2` |
| años sintéticos del autoencoder | 200 + y | `s2` |
| inicialización de pesos (KAN, MLP, atención, AE) | `rng(1)` | `surr_lib`, `s2` |
| muestreo latente | `rng(7)` | `s2` |
| LHS | `rng(3)` | `s3` |
| DOA/GA/PSO/aleatoria | 1…6 | `s4` |
| DOA Tchebycheff | 100 + i | `s4` |
| DOA sintonización θ (año tipo / TOU) | 5 / 6 | `s5` |

Todos los generadores usan `rng(semilla,'twister')`; los resultados son reproducibles
bit a bit en la misma versión de MATLAB (verificado en R2026a, ver
`docs/MULTIVECTOR_RELEASE_VERIFICATION.md`).
