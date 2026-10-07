# ReNoN-Azuay — modelo vectorial y métodos en la frontera del conocimiento (v2)

Extiende `../matlab/` (v1). Reporte: `../reporte/reporte_tecnico_renon_v2.tex`.

| Archivo | Contenido |
|---|---|
| `renon_params_v2.m` | Parámetros v1 + V2G + EMS de atención + límites de 7 variables |
| `renon_hub.m` | Despacho vectorial (energy hub): matriz de acoplamiento media C, indicadores por vector, V2G, EMS `valley`/`attention` |
| `obj_hub.m` | Objetivos [CO2, costo] |
| `doa.m` | Dream Optimization Algorithm (reimplementación propia de Lang y Gao, 2025) |
| `hv2d.m` | Hipervolumen 2-D |
| `surr_lib.m` | KAN (B-splines), MLP y sustituto con auto-atención sobre `dlarray`; entrenador Adam |
| `s1_hub.m` | Línea base, NSGA-II 7 variables 2030/2050, matrices C, indicadores por vector, sensibilidad V2G |
| `s2_autoencoder.m` | Autoencoder 96-64-8-64-96 vs PCA; generación latente de escenarios; Monte Carlo |
| `s3_surrogates.m` | KAN vs MLP vs atención; interpretabilidad; NSGA-II asistido por KAN |
| `s4_doa.m` | DOA vs GA vs PSO vs aleatorio; frente por Tchebycheff (usa `parpool`) |
| `s5_attention_ems.m` | EMS con atención temporal sintonizado con DOA; escenario con tarifa horaria |

Ejecución (MATLAB R2026a, ~6 min en total):

```matlab
cd matlab_v2
s1_hub; s2_autoencoder; s3_surrogates; s4_doa; s5_attention_ems
```

Salidas: figuras en `../reporte/figs_v2/`, tablas CSV y `.mat` en `../resultados_v2/`.
Toolboxes: Deep Learning, Optimization, Global Optimization, Statistics and Machine Learning, Parallel Computing.
