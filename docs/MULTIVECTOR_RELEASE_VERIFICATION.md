# Verificación de la publicación — modelo multivectorial y reportes técnicos

Fecha: 7 de octubre de 2026. Repositorio: `ismael-minchala/renon-azuay`, rama `main`.

## Commits de esta publicación

| Commit | Contenido |
|---|---|
| `df0f8b5` | `model:` modelo v2 (`matlab_v2/`), CSV y figuras de referencia v2, puntos de entrada (`init_renon_model`, `run_renon_model`, `reproduce_report_v1/v2`, `run_all_tests`), `tests/`, documentación del modelo, correcciones mínimas en `s2`–`s5`, `.mat` fuera de git |
| `474aa6e` | `docs:` reportes v1 y v2 finalizados y publicados en `docs/reportes/`, fuentes LaTeX limpias, README de compilación, tarjetas de reportes en la web |
| (este commit) | `docs:` auditoría, trazabilidad, este documento y sección del modelo en el README raíz |

Flujo elegido: commits directos a `main` (único mantenedor activo, sin ramas ni PR en
uso; ver `MODELO_MULTIVECTORIAL_AUDIT.md` §1).

## Entorno

| | |
|---|---|
| MATLAB | R2026a Update 5 (26.1.0.3346908), macOS 26.6, Apple Silicon, 14 núcleos |
| Toolboxes usadas | Deep Learning, Statistics and Machine Learning, Optimization, Global Optimization, Parallel Computing (pool de 12 procesos) |
| LaTeX | TeX Live 2024, pdfTeX 1.40.26 |
| Verificación remota | `gh` CLI (cuenta `ismael-minchala`, permiso ADMIN) |

## Ejecuciones realizadas con MATLAB (MCP)

| Paso | Resultado |
|---|---|
| Code Analyzer (`checkcode`) sobre los 18 `.m` originales y los 10 nuevos | 0 errores; sólo avisos de estilo (alineación, preasignación, variables globales en `s4_doa` usadas deliberadamente con `ga`/`particleswarm`, `verLessThan` mantenido por compatibilidad) |
| `main_renon` (v1) | 15,9 s; 4 CSV idénticos a los publicados (máx. dif. relativa 2·10⁻¹⁵ en `verificacion_estres_mc.csv`, formato) |
| `s1_hub` … `s5_attention_ems` (v2), individualmente | todos los CSV idénticos a los de referencia salvo columnas de tiempo de cómputo y, en `s4`, ver discrepancia abajo |
| `reproduce_report_v1` (punto de entrada) | 13,6 s, resultados idénticos |
| `reproduce_report_v2` (punto de entrada, cadena completa) | 207 s con pool ya iniciado; 20 CSV idénticos a la ejecución anterior (determinismo confirmado en dos ejecuciones de `s4`) |
| `run_renon_model` (defecto, v1/v2 × 3 escenarios, estrés, perturbación, `attention`, NSGA-II corto) | OK; verificaciones físicas superadas |
| `run_all_tests` | **29 pruebas: 29 superadas, 0 fallidas, 0 incompletas (8,9 s)** |
| Benchmark `doa` (esfera-10, Rastrigin-10; N=50, T=200; 5 semillas) | esfera: 6,0·10⁻⁷ – 3,4·10⁻⁶; Rastrigin: 0 en 4 de 5 semillas (0,995 en la restante) |

### Verificaciones físicas y numéricas (todas superadas)

- Balance horario `carga = ren + bat + imp + th + ens − vert (+ v2g)`: residuo máximo 2,8·10⁻¹⁴ MW.
- `0 ≤ imp ≤ cap_imp`, `0 ≤ th ≤ P_th`, `ens, vert, flex ≥ 0`; `|p_b| ≤ E_b/3`; `0 ≤ SOC ≤ E_b`.
- Energía flexible diaria = `f_a·E_bomb + f_v·E_ev` (desviación máx. 5,7·10⁻¹⁴ MWh); potencias ≤ límites.
- V2G sólo en 18–22 h; recarga diaria = descarga/η.
- Filas de la matriz de acoplamiento C̄ suman 1 (±0,02); fracción renovable y resiliencia en [0, 1].
- Sin NaN/Inf en indicadores ni series; demanda anual de los perfiles = `E_dem` del escenario.
- `renon_hub` con `f_g = 0` reproduce `renon_dispatch` en los tres escenarios (diferencia 0 en CO₂, costo, ENS; 1·10⁻¹³ MW en importación).
- NSGA-II con las semillas de los reportes reproduce exactamente los frentes almacenados (48 puntos).

### Discrepancia encontrada y resolución

| Elemento | Esperado (reporte v2 original) | Reproducido | Causa | Resolución |
|---|---|---|---|---|
| Tabla 8, filas GA / PSO / búsqueda aleatoria (`s4_doa`) | GA 92,73 ± 1,061; aleatoria 99,82 ± 4,783 | 1.ª ejecución: aleatoria 101,16 ± 4,55; tras corregir: GA 93,38 ± 1,717; PSO 90,80 ± 0,001; aleatoria 100,25 ± 3,478 (idéntico en 3 ejecuciones) | `rng(seed)` sin tipo de generador dentro de `parfor`: los *workers* arrancan con otro generador y `doa.m` los cambia a `'twister'`, de modo que el resultado dependía del *worker* que ejecutara cada tarea | `rng(seed,'twister')` en las ramas GA, PSO y aleatoria; Tabla 8 y las frases asociadas del reporte v2 actualizadas con los valores reproducibles. Las conclusiones no cambian (DOA ≈ PSO, mejor que GA y que la búsqueda aleatoria); DOA y el frente por Tchebycheff eran y siguen siendo idénticos |
| Tabla 7, columna de tiempo de entrenamiento | 38 / 7 / 34 s | 24 / 3 / 31 s | tiempo de cómputo, no reproducible | nota en el caption; métricas de error reproducidas bit a bit |
| Validación de `doa` en Rastrigin/esfera (§3.4) | "f* = 0 alcanzado; esfera 1,4·10⁻⁶", sin script | medido con `testDoaOnBenchmarks` | la afirmación no tenía código asociado | frase reescrita con los valores medidos y prueba añadida |

## Reportes

| | v1 | v2 |
|---|---|---|
| Fuente | `reporte_tecnico_renon.tex` | `reporte_tecnico_renon_v2.tex` + `refs_v2.tex` |
| Compilación | `pdflatex` ×2, sin avisos ni referencias indefinidas | `pdflatex` ×3, ídem |
| PDF | `docs/reportes/reporte_tecnico_renon.pdf`, 10 páginas, 7 figuras, 5 referencias (todas con DOI o identificador) | `docs/reportes/reporte_tecnico_renon_v2.pdf`, 26 páginas, 12 figuras, 9 tablas, 23 referencias con DOI/arXiv |
| Texto | sin `??`, sin "borrador/pendiente/TODO", sin notas meta-editoriales, sin rutas locales (búsqueda sobre `pdftotext`) | ídem |
| Portada | título, autoría (GIEEC–DEET, Universidad de Cuenca), fecha; sin marca de agua | ídem |
| DOI | todos resuelven en doi.org (7 oct 2026); referencias clave cotejadas en Crossref | ídem |

Cambios editoriales aplicados: `MODELO_MULTIVECTORIAL_AUDIT.md` §5.

## Archivos publicados

- `docs/reportes/reporte_tecnico_renon.pdf`, `docs/reportes/reporte_tecnico_renon_v2.pdf`
  (el reporte `2026-09_PT2_EnergyPLAN_MOEA_Trento.pdf` ya existente se conserva).
- `code/analysis/propuesta_tecnica/`: `matlab/` (sin cambios), `matlab_v2/` (12 archivos),
  `tests/` (3), puntos de entrada (6), `resultados_v2/` (20 CSV, 92 kB), `reporte/figs_v2/`
  (13 PNG, 1,2 MB), fuentes LaTeX y READMEs.
- `docs/`: `MODELO_MULTIVECTORIAL_AUDIT.md`, `MODEL_REPORT_TRACEABILITY.md`, este documento;
  `index.html` con las dos tarjetas de reporte.
- `README.md` raíz: sección *Modelo multivectorial y reportes técnicos*.
- Eliminado del control de versiones: `resultados/resultados_renon.mat` (2,8 MB, regenerable).
  Los `.mat` de v2 (7,8 MB) nunca se versionaron. Archivo más grande añadido: el PDF v2 (1,7 MB).

## Limitaciones conocidas

- Los resultados son reproducibles bit a bit en MATLAB R2026a; otras versiones pueden
  diferir en los últimos dígitos (generadores de números aleatorios y `dlarray`).
- Los tiempos de cómputo de las tablas del reporte v2 son de una ejecución concreta.
- Todos los perfiles son sintéticos y los parámetros provinciales son estimaciones;
  la calibración con datos reales corresponde al PT1 (ver "Limitaciones" del reporte v2).
- `s4_doa` sin Parallel Computing Toolbox se ejecuta en serie (≈ 10 min).
- La figura `fig_v2_7_surr_loss.png` se genera pero no se incluye en el PDF v2.
- `main_renon.m` empieza con `clear`, por lo que `reproduce_report_v1` limpia el
  espacio de trabajo base (documentado en el script).
