# Modelo multivectorial ReNoN-Azuay — implementación MATLAB

Modelo de planificación y operación horaria que acopla **electricidad renovable, agua
potable y movilidad eléctrica** en la provincia del Azuay (Ecuador) y optimiza con
NSGA-II el compromiso entre emisiones de CO₂ y costo anual para 2030 y 2050. Es el
producto de las actividades 2.1–2.2 del PT2 del proyecto *Transición energética
sostenible en Azuay–Ecuador* (XXII Concurso VIUC, DEET – Universidad de Cuenca).

Dos generaciones del modelo, cada una con su reporte técnico:

| Versión | Carpeta | Reporte | Qué añade |
|---|---|---|---|
| **v1** (jul 2026) | `matlab/` | [`docs/reportes/reporte_tecnico_renon.pdf`](../../../docs/reportes/reporte_tecnico_renon.pdf) | despacho horario con EMS de llenado de valles, 6 variables de decisión, NSGA-II, estrés de sequía, Monte Carlo |
| **v2** (sep 2026) | `matlab_v2/` | [`docs/reportes/reporte_tecnico_renon_v2.pdf`](../../../docs/reportes/reporte_tecnico_renon_v2.pdf) | formulación de concentrador energético (matriz de acoplamiento, indicadores por vector), V2G como 7.ª variable, EMS con atención temporal, autoencoder de escenarios, sustitutos KAN/MLP/atención, Dream Optimization Algorithm |

v2 reutiliza sin cambios los parámetros y el generador de perfiles de v1; con `f_g = 0`
reproduce v1 exactamente. Ambas versiones se conservan y se reproducen por separado.

## Requisitos

| | v1 | v2 |
|---|---|---|
| MATLAB | R2020b o posterior (validado en R2026a) | ídem |
| Toolboxes | ninguna | Deep Learning, Statistics and Machine Learning, Optimization, Global Optimization; Parallel Computing opcional |
| Datos externos | ninguno (perfiles sintéticos con semilla fija) | ninguno; `s1_hub` lee los CSV de Pareto de v1 incluidos en `resultados/` |

Detalle en [`ENVIRONMENT.md`](ENVIRONMENT.md). `init_renon_model` comprueba versión y
licencias y avisa de lo que falte.

## Estructura

```
propuesta_tecnica/
├── README.md                 este archivo
├── MODEL_ARCHITECTURE.md     fronteras, variables, lógica del EMS, objetivos, algoritmos
├── PARAMETERS.md             todos los parámetros: valor, unidad, fuente, dónde se usan
├── ENVIRONMENT.md            MATLAB, toolboxes, tiempos
├── init_renon_model.m        rutas, comprobación de dependencias, carpetas de salida
├── run_renon_model.m         punto de entrada: evalúa una configuración (v1 o v2), opcional NSGA-II
├── renon_sanity_checks.m     balance horario, límites, SOC, energía flexible, V2G, matriz C
├── reproduce_report_v1.m     regenera todo el reporte v1 (≈ 15 s)
├── reproduce_report_v2.m     regenera todo el reporte v2 (≈ 4 min)
├── run_all_tests.m           ejecuta tests/ (matlab.unittest)
├── matlab/                   v1: renon_params, renon_profiles, renon_dispatch, objetivos, nsga2_simple, main_renon
├── matlab_v2/                v2: renon_params_v2, renon_hub, obj_hub, doa, hv2d, surr_lib, setup_v2, s1_hub … s5_attention_ems
├── tests/                    test_renon_v1, test_renon_v2, test_entry_points
├── resultados/               CSV de referencia del reporte v1
├── resultados_v2/            CSV de referencia del reporte v2
└── reporte/                  fuentes LaTeX, figuras (figs/, figs_v2/) y README de compilación
```

## Inicio rápido

```matlab
cd code/analysis/propuesta_tecnica
init_renon_model                      % rutas + comprobación de toolboxes
results = run_renon_model;            % solución de compromiso 2030 del modelo v2
```

Otras llamadas habituales:

```matlab
r = run_renon_model(struct('version','v1','scenario','lc2050'));     % v1, 2050
r = run_renon_model(struct('stress',true));                          % sequía extrema (oct–dic)
r = run_renon_model(struct('ems','attention','theta',[1.8 0.07 0.25 0.21]));
r = run_renon_model(struct('x',[283 150 0 30 0.19 0.61 0.5]));       % configuración propia (V2G 50 %)
r = run_renon_model(struct('optimize',true));                        % NSGA-II 48×60 → r.front
```

Reproducción completa de los reportes y pruebas:

```matlab
reproduce_report_v1      % CSV en resultados/, figuras en reporte/figs/
reproduce_report_v2      % CSV en resultados_v2/, figuras en reporte/figs_v2/
run_all_tests            % o: results = runtests('tests');
```

## Lógica de operación

```
renon_params(escenario) ──► P: demanda, parque, costos, límites (y V2G/atención en v2)
        │
renon_profiles(P, semilla) ──► S: 8760 h de demanda, cf hidro/FV/eólica, λ y π del SNI,
        │                          cargas de agua y VE (sintéticas, reproducibles)
        ▼
renon_dispatch(x,P,S)  /  renon_hub(x,P,S,opt)
   1. generación renovable local            4. batería (C/3, η 0,95)
   2. carga fija de los tres vectores       5. V2G en punta 18–22 h (v2)
   3. cargas flexibles por día:             6. importación SNI → térmica → ENS; excedente → vertimiento
      llenado de valles | atención (v2)
        ▼
indicadores: CO₂ (eléctrico + flota ICE), costo (CAPEX anualizado + OPEX + VoLL·ENS),
fracción renovable, ENS, resiliencia; v2: por vector, matriz C̄ (3×6), índice κ
        ▼
objetivos [CO₂, costo] ──► nsga2_simple ──► frente de Pareto ──► solución de compromiso
        ▼
estrés de sequía · Monte Carlo · sensibilidad V2G · sustitutos · DOA · EMS de atención
        ▼
CSV (resultados*/) + PNG (reporte/figs*/) ──► reporte_tecnico_renon(.tex | _v2.tex)
```

Descripción completa (fronteras del sistema, restricciones, ecuaciones, algoritmos):
[`MODEL_ARCHITECTURE.md`](MODEL_ARCHITECTURE.md).

## Entradas

No hay archivos de entrada. Toda la información está en `renon_params.m` /
`renon_params_v2.m` (documentada en [`PARAMETERS.md`](PARAMETERS.md)) y las series
horarias se sintetizan en `renon_profiles.m`. Los valores provinciales son estimaciones
de ingeniería que se calibrarán con los datos de CENTROSUR, ETAPA y GAD Cuenca (PT1).

## Salidas

| Carpeta | Contenido | Generado por |
|---|---|---|
| `resultados/` | `resumen_escenarios.csv` (Tabla 2 del reporte v1), `pareto_2030.csv`, `pareto_2050.csv`, `verificacion_estres_mc.csv` | `main_renon` |
| `resultados_v2/` | `resumen_v2.csv` (Tabla 5 v2), `pareto_v2_*.csv`, `hub_C_*.csv`, `v2g_sensibilidad.csv`, `hv_v1_v2.csv`, `autoencoder_*.csv`, `surrogates_metricas.csv`, `kan_importancia.csv`, `atencion_mapa.csv`, `nsga_asistido_kan.csv`, `doa_*.csv`, `ems_atencion*.csv` | `s1` … `s5` |
| `reporte/figs/`, `reporte/figs_v2/` | 7 y 13 figuras PNG de los reportes | ídem |
| `resultados*/*.mat` | series completas (no versionadas, se regeneran) | ídem |

`run_renon_model` devuelve una estructura con `R` (indicadores y series `R.s`),
`checks` (verificaciones físicas) y, si se pide, `front`.

## Escenarios

`base2024` (parque actual, sin flexibilidad), `lc2030`, `lc2050`. Se seleccionan con
`cfg.scenario`; la prueba de estrés con `cfg.stress = true`; perturbaciones Monte Carlo
con `cfg.pert`. Definiciones y valores en `PARAMETERS.md` §1 y §10.

## Reportes

| Reporte | Reproducir resultados | Compilar PDF |
|---|---|---|
| v1 | `reproduce_report_v1` | `cd reporte && pdflatex reporte_tecnico_renon.tex` (×2) |
| v2 | `reproduce_report_v2` | `cd reporte && pdflatex reporte_tecnico_renon_v2.tex` (×3) |

Correspondencia tabla/figura ↔ script ↔ CSV:
[`docs/MODEL_REPORT_TRACEABILITY.md`](../../../docs/MODEL_REPORT_TRACEABILITY.md).
Instrucciones de compilación: [`reporte/README.md`](reporte/README.md).

## Pruebas

`run_all_tests` ejecuta tres archivos de `matlab.unittest`:

- `test_renon_v1`: parámetros, perfiles (dimensiones, cotas, energía anual,
  reproducibilidad), física del despacho, NSGA-II en un problema analítico, regresión
  contra `resultados/*.csv` (incluida la re-ejecución completa del NSGA-II 2030).
- `test_renon_v2`: `renon_hub` ≡ `renon_dispatch` con `f_g = 0`, física con V2G, EMS de
  atención (conservación de energía, límite τ→0), `hv2d` exacto, `doa` en esfera y
  Rastrigin, biblioteca de sustitutos (B-splines, dimensiones, entrenamiento), regresión
  contra `resultados_v2/*.csv`.
- `test_entry_points`: `init_renon_model`, todas las variantes de `run_renon_model`,
  detección de violaciones por `renon_sanity_checks`.

Las pruebas que requieren Deep Learning Toolbox se omiten (no fallan) si no está
instalada.

## Solución de problemas

| Síntoma | Causa / solución |
|---|---|
| `Undefined function 'renon_hub'` | ejecutar `init_renon_model` (añade `matlab/`, `matlab_v2/`, `tests/` al path) |
| aviso "Not all toolboxes required by the v2 experiments…" | falta alguna toolbox de v2; v1 y `renon_hub` funcionan igual; `s2`–`s4` fallarán |
| `s1_hub` no encuentra `pareto_2030.csv` | ejecutar `reproduce_report_v1` primero (regenera los CSV de v1) |
| `s4_doa` sin Parallel Computing Toolbox | el `parfor` se ejecuta en serie (mismos resultados, ≈ 10 min) |
| `run_renon_model` lanza "Physical sanity checks failed" | configuración fuera de límites o modificación del despacho; ver `results.checks` con `cfg.checks = false` |
| las figuras no aparecen | `setup_v2` las oculta mientras exporta; `set(0,'DefaultFigureVisible','on')` |
| resultados distintos a los CSV | comprobar versión de MATLAB (validado en R2026a) y que no se cambió ninguna semilla (`PARAMETERS.md` §11) |

## Licencia y cita

Código del proyecto ReNoN-Azuay (GIEEC – DEET, Universidad de Cuenca). Citar los
reportes técnicos v1 (julio 2026) y v2 (septiembre 2026) disponibles en
`docs/reportes/`.
