# Trazabilidad reporte ↔ modelo ↔ código

Qué código generó qué resultado de cada reporte técnico del modelo multivectorial
ReNoN-Azuay. Rutas relativas a `code/analysis/propuesta_tecnica/`.

## Resumen

| | Reporte v1 | Reporte v2 |
|---|---|---|
| PDF | `docs/reportes/reporte_tecnico_renon.pdf` (10 pp.) | `docs/reportes/reporte_tecnico_renon_v2.pdf` (25 pp.) |
| Fuente | `reporte/reporte_tecnico_renon.tex` | `reporte/reporte_tecnico_renon_v2.tex` + `reporte/refs_v2.tex` |
| Fecha | julio 2026 | septiembre 2026 |
| Versión del modelo | **v1**: despacho `renon_dispatch`, 6 variables, EMS de llenado de valles | **v2**: concentrador energético `renon_hub`, 7 variables (V2G), EMS `valley`/`attention`, indicadores por vector |
| Entrada principal | `reproduce_report_v1` → `matlab/main_renon.m` | `reproduce_report_v2` → `matlab_v2/s1_hub.m` … `s5_attention_ems.m` |
| Funciones de soporte | `renon_params`, `renon_profiles`, `renon_dispatch`, `objetivos`, `nsga2_simple` | las de v1 + `renon_params_v2`, `renon_hub`, `obj_hub`, `doa`, `hv2d`, `surr_lib`, `setup_v2` |
| Datos de entrada | ninguno externo (perfiles sintéticos, semilla 1) | ídem + `resultados/pareto_2030.csv`, `pareto_2050.csv` (salidas de v1) |
| Salidas | `resultados/*.csv`, `reporte/figs/*.png` | `resultados_v2/*.csv`, `reporte/figs_v2/*.png` |
| Toolboxes | ninguna | Deep Learning, Statistics & ML, Optimization, Global Optimization; Parallel (opcional) |
| Relación | — | extiende v1; con `f_g = 0` y EMS `valley`, `renon_hub` ≡ `renon_dispatch` (prueba `testHubReproducesV1`) |

Los dos reportes corresponden a **dos generaciones del mismo modelo**, no a dos modelos
independientes: v2 reutiliza sin cambios los parámetros y el generador de perfiles de
v1 y añade una capa de formulación vectorial y métodos de aprendizaje/optimización.
Ambas generaciones se conservan y se reproducen de forma independiente.

## Reporte v1 — `reporte_tecnico_renon.pdf`

| Elemento del reporte | Script / sección | Archivo de resultado | Verificación |
|---|---|---|---|
| Resumen: 532 → 418 kt (−21 %), FR 25,7 → 57,5 %, ENS −88 %, R 0,943 → 0,993, NRMSE 3,1 %, r 0,994 | `main_renon` §1–§5 | `resumen_escenarios.csv`, `verificacion_estres_mc.csv` | reproducido bit a bit (07-10-2026) |
| Tabla 1 (parámetros) | `renon_params.m` | — | `PARAMETERS.md` |
| Fig. 1 perfiles semana de estiaje | `main_renon` §1 (semana 41) | `figs/fig1_perfiles.png` | regenerada |
| §3.1 / Fig. 2 verificación NRMSE, Pearson | `main_renon` §2 | `verificacion_estres_mc.csv` (`NRMSE_pct`, `Pearson`) | `testRegressionReportV1Verification` |
| §4.1 línea base 2024 | `main_renon` §1 (`R0`) | `resumen_escenarios.csv` fila 1 | `testRegressionReportV1Table2` |
| §4.2 / Fig. 3 frentes de Pareto 2030, 2050 | `main_renon` §3, `nsga2_simple` (48×60, semillas 8 y 9) | `pareto_2030.csv`, `pareto_2050.csv` | `testNsga2ReproducesStoredFront`, `testRegressionParetoFront2030` |
| Tabla 2 escenarios (compromiso 2030/2050) | `main_renon` §3 (punto de rodilla) y §6 | `resumen_escenarios.csv` filas 2–3 | `testRegressionReportV1Table2` |
| Fig. 4 despacho semana de estiaje 2030 | `main_renon` §3 (`Rk.s`) | `figs/fig4_despacho.png` | regenerada |
| Fig. 5 capacidades | `main_renon` §3 | `figs/fig5_capacidades.png` | regenerada |
| §4.3 / Fig. 6 estrés de sequía | `main_renon` §4 | `verificacion_estres_mc.csv` (`Resil_*`, `ENS_*`) | `testRegressionReportV1Verification` |
| §4.4 / Fig. 7 Monte Carlo N=200 | `main_renon` §5 | `verificacion_estres_mc.csv` (`CO2_med_kt`, `P5`, `P95`, `Costo_*`, `FR_med_pct`) | reproducido bit a bit |
| Tabla 3 contraste con metas | derivada de las anteriores | — | — |

## Reporte v2 — `reporte_tecnico_renon_v2.pdf`

| Elemento del reporte | Script | Archivo de resultado | Verificación |
|---|---|---|---|
| Ecs. 1–12 formulación vectorial, Nomenclatura | `renon_hub.m`, `renon_params_v2.m` | — | `MODEL_ARCHITECTURE.md` |
| §5.1 / Tabla 5 (compromiso 7 variables, indicadores por vector, κ) | `s1_hub` (NSGA-II 48×60, semillas 8 y 9) | `resumen_v2.csv`, `hub_C_1..3.csv` | `testRegressionReportV2Table5`, bit a bit |
| Fig. 1 frentes v1 vs v2, HV 1218/1211 y 3466/3442 | `s1_hub` + `hv2d` | `pareto_v2_2030.csv`, `pareto_v2_2050.csv`, `hv_v1_v2.csv` | bit a bit |
| Fig. 2 matriz C̄ | `s1_hub` (`renon_hub` → `R.C`) | `hub_C_1..3.csv` | bit a bit |
| Fig. 3 emisiones y costo por vector | `s1_hub` (`R.vec`) | `resumen_v2.csv` | bit a bit |
| §5.1 / Fig. 4 sensibilidad V2G bajo sequía (ENS 17,6 → 10,8 GWh) | `s1_hub` (bloque de sensibilidad) | `v2g_sensibilidad.csv` | `testRegressionV2GSensitivity`, bit a bit |
| §5.2 / Tabla 6 / Fig. 5 autoencoder vs PCA, Monte Carlo latente | `s2_autoencoder` (`surr_lib.train`) | `autoencoder_reconstruccion.csv`, `autoencoder_montecarlo.csv` | bit a bit |
| §5.3 / Tabla 7 / Fig. 6 sustitutos KAN/MLP/atención | `s3_surrogates` | `surrogates_metricas.csv` | métricas bit a bit; columna `Tiempo_s` varía entre ejecuciones (caption lo indica) |
| (curvas de pérdida `fig_v2_7_surr_loss.png`, generada por `s3` pero **no incluida** en el PDF) | `s3_surrogates` | — | — |
| Fig. 7 activaciones KAN e importancia | `s3_surrogates` | `kan_importancia.csv` | bit a bit |
| Fig. 8 mapa de atención | `s3_surrogates` | `atencion_mapa.csv` | bit a bit |
| Fig. 9 NSGA-II asistido por KAN (HV 948 vs 1001, 94,7 %) | `s3_surrogates` | `nsga_asistido_kan.csv` | bit a bit (salvo tiempos) |
| §5.4 / Tabla 8 / Fig. 10 DOA vs GA vs PSO vs aleatoria | `s4_doa` (`doa`, `ga`, `particleswarm`; 6 semillas) | `doa_mono_objetivo.csv`, `doa_mono_mejores.csv` | ver `docs/MULTIVECTOR_RELEASE_VERIFICATION.md` |
| Fig. 11 frente por Tchebycheff (HV 1047 vs 1099, 95,3 %) | `s4_doa` | `doa_frente_tchebycheff.csv`, `doa_frente_hv.csv` | ídem |
| §3.4 validación de `doa` en Rastrigin-10 y esfera-10 | `tests/test_renon_v2.m` → `testDoaOnBenchmarks` | — | ídem |
| §5.5 / Tabla 9 / Fig. 12 EMS con atención (año tipo y TOU), θ sintonizado | `s5_attention_ems` (`doa`, semillas 5 y 6) | `ems_atencion.csv`, `ems_atencion_tou.csv`, `ems_atencion_theta.csv` | `testRegressionAttentionEmsTable` |

### Vectores de decisión usados en v2

| Experimento | Vector evaluado | Origen |
|---|---|---|
| `s1_hub` frentes y Tabla 5 | compromiso de 7 variables obtenido en el propio script | NSGA-II v2 |
| `s1_hub` sensibilidad V2G | compromiso v2 2030 con `f_g` de 0 a 1 | NSGA-II v2 |
| `s2_autoencoder` Monte Carlo, `s5_attention_ems` | `[255,3 150 0 30 0,332 0,838 0]` = compromiso 2030 **de la versión 1** | `resumen_escenarios.csv` fila 2 |
| `s3_surrogates`, `s4_doa` | muestras LHS / soluciones de los optimizadores en los límites 2030 | — |

## Figuras: numeración en el PDF ↔ archivo

| Reporte | Figura en el PDF | Archivo |
|---|---|---|
| v1 | 1 … 7 | `figs/fig1_perfiles.png`, `fig2_validacion.png`, `fig3_pareto.png`, `fig4_despacho.png`, `fig5_capacidades.png`, `fig6_estres.png`, `fig7_montecarlo.png` |
| v2 | 1 … 12 | `figs_v2/fig_v2_1_pareto.png`, `fig_v2_2_hub_C.png`, `fig_v2_3_vectores.png`, `fig_v2_4_v2g.png`, `fig_v2_5_autoencoder.png`, `fig_v2_6_surrogates.png`, `fig_v2_8_kan_activaciones.png`, `fig_v2_9_atencion_mapa.png`, `fig_v2_10_nsga_kan.png`, `fig_v2_11_doa_convergencia.png`, `fig_v2_12_doa_frente.png`, `fig_v2_13_ems_atencion.png` (el archivo `fig_v2_7_surr_loss.png` no está en el PDF; la numeración del PDF va de 1 a 12) |

## Cómo reproducir

```matlab
cd code/analysis/propuesta_tecnica
init_renon_model
reproduce_report_v1          % ~15 s, MATLAB base
reproduce_report_v2          % ~4 min, toolboxes de v2
run_all_tests                % pruebas unitarias y de regresión contra los CSV
```

Compilación de los PDF: `code/analysis/propuesta_tecnica/reporte/README.md`.
