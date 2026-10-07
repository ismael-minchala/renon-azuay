# Arquitectura del modelo multivectorial ReNoN-Azuay

Este documento describe **lo que el código implementa**, reconstruido a partir de
`matlab/` (versión 1, reporte técnico de julio de 2026) y `matlab_v2/` (versión 2,
reporte de septiembre de 2026). No describe subsistemas que sólo existen
conceptualmente en la propuesta del proyecto.

## 1. Objetivo del modelo

Evaluar, para la provincia del Azuay, configuraciones de expansión de generación
renovable y de flexibilidad de demanda que acoplan tres vectores —electricidad,
agua potable y movilidad eléctrica— y encontrar el frente de Pareto entre
**emisiones anuales de CO₂** y **costo anual total** para los horizontes 2030 y 2050,
con pruebas de resiliencia ante sequía y análisis de incertidumbre.

## 2. Fronteras del sistema

| Dentro del sistema | Fuera del sistema (parámetro exógeno) |
|---|---|
| Demanda eléctrica "pura" del área CENTROSUR | Red nacional SNI: factor de emisión λ(t) y precio π(t) estacionales, límite de importación |
| Hidro de pasada local (40 MW + nueva), eólica, FV distribuida, térmica MCI local (20 MW) | Flota de combustión remanente (sólo emite; no consume electricidad) |
| Vector agua: tratamiento (carga fija) + bombeo (25 % del caudal, diferible hasta f_a) | Red de distribución (sin restricciones de red) |
| Vector movilidad: carga de VE no inteligente (pico 18–23 h) + carga inteligente (f_v) + V2G (f_g, sólo v2) | Hidrógeno, calor, almacenamiento estacional (no modelados) |
| Batería estacionaria (E_b, potencia E_b/3, η = 0,95 por sentido) | |

Resolución temporal **1 h**, horizonte **8760 h** (año tipo). Sin resolución espacial
(un solo nodo: el bus eléctrico).

## 3. Datos de entrada

El modelo **no lee archivos de datos externos**. Todas las series horarias son
sintéticas y se generan en `renon_profiles.m` a partir de los parámetros de
`renon_params.m` (curva diaria típica, factores mensuales, persistencia sinóptica y
ruido gaussiano con semilla fija). La única dependencia entre versiones es que
`matlab_v2/s1_hub.m` lee `resultados/pareto_2030.csv` y `pareto_2050.csv` (salidas de
referencia de v1) para comparar frentes.

Salidas de `renon_profiles(P, semilla, pert)` (vectores 8760×1):

| Campo | Significado | Unidad |
|---|---|---|
| `dem_e`, `dem_ref` | demanda eléctrica pura con ruido / referencia determinística | MW |
| `cf_pv`, `cf_wind`, `cf_hyd` | factores de planta horarios | 0–1 |
| `ef_grid`, `prec_imp` | factor de emisión y precio de importación SNI | tCO₂/MWh, USD/MWh |
| `p_trat`, `perfil_bomb_fijo`, `E_bomb_dia`, `P_bomb_max` | tratamiento, bombeo no diferible, energía diaria de bombeo, capacidad | MW, MWh/d |
| `perfil_ev_fijo`, `E_ev_dia`, `P_ev_max`, `n_ev` | carga VE no inteligente, energía diaria VE, potencia de carga inteligente, nº de VE | MW, MWh/d, veh |
| `hod`, `dia`, `mes` | índices de hora del día, día, mes | – |

`pert` es una estructura de multiplicadores (`.hyd .pv .wind .dem .prec`) usada en
Monte Carlo y en la prueba de estrés.

## 4. Variables de decisión

| Índice | Símbolo | Variable | Unidad | Límites 2030 / 2050 |
|---|---|---|---|---|
| 1 | P_pv | capacidad FV | MW | [5, 300] / [5, 600] |
| 2 | P_w | capacidad eólica | MW | [50, 150] / [50, 300] |
| 3 | E_b | capacidad de batería | MWh | [0, 300] / [0, 800] |
| 4 | P_h⁺ | mini-hidro nueva (cf = 0,9 × perfil existente) | MW | [0, 30] / [0, 60] |
| 5 | f_a | fracción del bombeo diferible | – | [0, 0,8] |
| 6 | f_v | fracción de la flota VE con carga inteligente | – | [0, 1] |
| 7 (v2) | f_g | fracción de los VE inteligentes con V2G | – | [0, 1] |

## 5. Estados y variables internas del despacho

Por hora *t*: carga neta `net0 = carga_fija − renovables`, cargas flexibles asignadas
(`flex` o `flex_w`, `flex_m`), potencia de batería `bat` (>0 descarga), estado de carga
SOC (interno, inicial 0,5·E_b), importación `imp ≤ cap_imp`, térmica `th ≤ P_th`,
energía no suministrada `ens`, vertimiento `vert`; en v2 además descarga V2G `v2g` y su
recarga `v2g_rec`.

## 6. Lógica de operación (EMS jerárquico)

```
renon_params(escenario)            parámetros P (demanda, parque, costos, límites)
        ↓
renon_profiles(P, semilla, pert)   series horarias sintéticas S (8760 h)
        ↓
renon_dispatch(x, P, S)  [v1]  |  renon_hub(x, P, S, opt)  [v2]
   1. generación renovable  G = (P_h0 + 0,9 P_h⁺) c_h + P_pv c_pv + P_w c_w
   2. carga fija  L_fijo = dem_e + p_trat + (1−f_a)·bombeo + (1−f_v)·VE
   3. cargas flexibles por día (energía f_a·E_bomb, f_v·E_ev; potencia ≤ P̄):
        'valley'    : llenado de valles de la carga neta (v1 y v2)
        'attention' : softmax de −(α ñ + β λ̃ + γ π̃)/τ sobre las 24 h (v2)
   4. batería: carga con excedente, descarga en déficit (P ≤ E_b/3, η = 0,95)
   5. (v2) V2G: descarga en la ventana 18–22 h, recarga en las 4 h de menor carga neta
   6. importación SNI ≤ cap_imp → térmica local ≤ 20 MW → ENS; excedente → vertimiento
        ↓
indicadores: CO₂ (eléctrico + flota ICE), costo (CAPEX anualizado + OPEX + VoLL·ENS),
             fracción renovable, ENS, vertimiento, resiliencia R = 1 − ENS/ΣL
             (v2) indicadores por vector, matriz de acoplamiento media C̄ (3×6), κ
        ↓
objetivos F = [CO₂ kt/año, costo MUSD/año]   (objetivos.m / obj_hub.m)
        ↓
nsga2_simple (NSGA-II, 48×60) → frente de Pareto → solución de compromiso (rodilla)
        ↓
escenarios: estrés de sequía, Monte Carlo (N = 200), sensibilidad V2G
        ↓
figuras PNG (reporte/figs, reporte/figs_v2) + tablas CSV (resultados, resultados_v2)
        ↓
reporte_tecnico_renon.tex / reporte_tecnico_renon_v2.tex
```

### Acoplamiento entre vectores

El acoplamiento es **por el bus eléctrico**: agua y movilidad se expresan en
electricidad equivalente (`e_trat + φ_b·e_bomb` kWh/m³; `x_VE·e_km` kWh/km) y comparten
la misma oferta. Los acoplamientos *activos* son las cargas flexibles (tanques → bombeo
diferible; baterías de VE → carga inteligente y V2G), que el EMS desplaza en el tiempo.
En v2 la matriz C̄ se reconstruye *a posteriori* a partir de las participaciones
horarias s_v(t) = L_v/ΣL (ecuación 7 del reporte v2); la fila de movilidad incorpora la
fracción (1 − x_VE) servida por combustible.

### Restricciones (implícitas en la jerarquía de reglas)

- Balance horario: `carga = ren + bat + imp + th + ens − vert (+ v2g)`, donde `carga` incluye la recarga V2G.
- Energía diaria de cada carga flexible conservada; potencias ≤ P̄_a, P̄_v.
- 0 ≤ SOC ≤ E_b; |p_b| ≤ E_b/3.
- imp ≤ cap_imp; th ≤ P_th; todas las variables de flujo ≥ 0.
- V2G sólo en la ventana `h_v2g`; recarga = descarga / η_v2g en el mismo día.

Estas restricciones se verifican numéricamente en `renon_sanity_checks.m` y en
`tests/`.

## 7. Funciones objetivo

- **J₁** (ktCO₂/año) = Σ_t λ(t)·p_SNI(t) + FE_th·Σ_t p_th(t) + (1 − x_VE)·N_f·d_a·FE_ICE.
- **J₂** (MUSD/año) = CAPEX anualizado (CRF 6 %) de FV, eólica, batería, mini-hidro,
  retrofit de bombeo (f_a·1,2 MUSD), carga inteligente (25 USD/VE), cargadores V2G
  (150 USD/VE, v2) + OPEX (importación, térmica, degradación V2G 60 USD/MWh) +
  VoLL·ENS (10 000 USD/MWh).

## 8. Algoritmos de optimización

| Algoritmo | Archivo | Uso | Parámetros |
|---|---|---|---|
| NSGA-II (SBX η=15, p=0,9; mutación polinomial η=20, p=1/n) | `matlab/nsga2_simple.m` | frentes 2030/2050 (v1, v2), NSGA-II asistido por KAN | pob 48, gen 60, semillas 8 (2030) y 9 (2050) |
| Dream Optimization Algorithm (reimplementación) | `matlab_v2/doa.m` | mono-objetivo penalizado, frente por Tchebycheff, sintonización del EMS de atención | m=5, p_ex=0,9, p_olv=0,3 |
| GA, PSO (Global Optimization Toolbox) | `matlab_v2/s4_doa.m` | comparación con DOA | pob 60, 49 iteraciones, 6 semillas |
| Adam (`adamupdate`, Deep Learning Toolbox) | `matlab_v2/surr_lib.m` | entrenamiento de autoencoder, KAN, MLP, atención | lr coseno, 2500–8000 iteraciones |

## 9. Modelos de aprendizaje (sólo v2)

| Modelo | Arquitectura | Archivo |
|---|---|---|
| Autoencoder de días | 96–64–8–64–96, tanh, Adam 8000 it. | `s2_autoencoder.m` |
| KAN | [7, 6, 2], B-splines cúbicos G=5, 486 parámetros | `surr_lib.m` (`init_kan`, `fwd_kan`) |
| MLP | [7, 32, 32, 2], tanh, 1378 parámetros | `surr_lib.m` |
| Auto-atención | tokens d=8, una cabeza, MLP 32, 2194 parámetros | `surr_lib.m` |

## 10. Escenarios

| Escenario | Clave | Demanda | Flota / x_VE | Agua | Importación |
|---|---|---|---|---|---|
| Línea base 2024 | `base2024` | 1300 GWh | 130 k / 1 % | 2,2 m³/s | 250 MW |
| Compromiso 2030 | `lc2030` | 1534 GWh | 140 k / 25 % | 2,4 m³/s | 250 MW |
| Compromiso 2050 | `lc2050` | 2340 GWh | 165 k / 90 % | 3,2 m³/s | 350 MW |

Prueba de estrés (sequía extrema oct–dic): hidro ×0,5, λ ×1,5, π ×1,8, cap_imp ×0,7.
Monte Carlo (N=200): hidro 0,95±0,12, FV ±5 %, eólica ±8 %, demanda ±4 %, precio ±15 %.

## 11. Resultados que produce cada versión

- **v1** (`main_renon.m`): `resumen_escenarios.csv`, `pareto_2030.csv`, `pareto_2050.csv`,
  `verificacion_estres_mc.csv`, `resultados_renon.mat`, `figs/fig1..fig7.png`.
- **v2** (`s1..s5`): 20 CSV en `resultados_v2/` (frentes 7 variables, matrices C,
  sensibilidad V2G, hipervolúmenes, métricas de sustitutos, DOA, EMS de atención),
  5 `.mat` (regenerables, no versionados) y `figs_v2/fig_v2_1..13.png`.

La correspondencia exacta tabla/figura ↔ script se documenta en
`docs/MODEL_REPORT_TRACEABILITY.md`.

## 12. Clasificación de archivos

| Archivo | Clase | Notas |
|---|---|---|
| `matlab/renon_params.m`, `renon_profiles.m`, `renon_dispatch.m` | CORE v1 | parámetros, perfiles, EMS |
| `matlab/nsga2_simple.m`, `objetivos.m` | SUPPORT v1 | optimizador y wrapper |
| `matlab/main_renon.m` | RESULT-GEN v1 | genera todo el reporte v1 |
| `matlab_v2/renon_params_v2.m`, `renon_hub.m`, `obj_hub.m` | CORE v2 | modelo vectorial |
| `matlab_v2/doa.m`, `hv2d.m`, `surr_lib.m`, `setup_v2.m` | SUPPORT v2 | algoritmos y utilidades |
| `matlab_v2/s1_hub.m` … `s5_attention_ems.m` | RESULT-GEN v2 | experimentos del reporte v2 |
| `init_renon_model.m`, `run_renon_model.m`, `renon_sanity_checks.m` | ENTRY | puntos de entrada y verificación |
| `reproduce_report_v1.m`, `reproduce_report_v2.m`, `run_all_tests.m` | ENTRY | reproducción y pruebas |
| `tests/*.m` | TEST | matlab.unittest |
| `resultados/*.csv`, `resultados_v2/*.csv` | DATA (salidas de referencia) | leídas por las pruebas de regresión y por `run_renon_model` |
| `resultados*/*.mat` | RESULT (temporal) | regenerables; ignorados por git |
| `reporte/figs*/*.png` | RESULT (referencia) | usados por los `.tex` |

No se identificaron archivos obsoletos ni duplicados dentro del modelo.
