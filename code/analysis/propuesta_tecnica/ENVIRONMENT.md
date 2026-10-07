# Entorno de ejecución

## Entorno en el que se validó esta versión

| Elemento | Valor |
|---|---|
| MATLAB | R2026a Update 5 (26.1.0.3346908) |
| Sistema operativo | macOS 26.6 (Apple Silicon, `MACA64`), 14 núcleos |
| LaTeX | TeX Live 2024, pdfTeX 1.40.26 |
| Herramientas opcionales | `pdftotext`/`pdfinfo` (poppler) para inspección de PDF |

## Requisitos por versión del modelo

| Componente | MATLAB base | Deep Learning | Statistics & ML | Optimization | Global Optimization | Parallel Computing |
|---|---|---|---|---|---|---|
| v1: `main_renon`, `renon_dispatch`, `nsga2_simple` | ✔ | – | – | – | – | – |
| v2: `renon_hub`, `doa`, `hv2d`, `s1_hub`, `s5_attention_ems` | ✔ | – | – | – | – | – |
| v2: `s2_autoencoder` | ✔ | ✔ (`dlarray`, `adamupdate`) | ✔ (`pca`) | – | – | – |
| v2: `s3_surrogates` | ✔ | ✔ | ✔ (`lhsdesign`) | – | – | – |
| v2: `s4_doa` | ✔ | – | – | ✔ (requerida por GADS) | ✔ (`ga`, `particleswarm`) | opcional (`parpool`; sin ella `parfor` corre en serie) |
| `tests/` | ✔ | opcional (las pruebas de `surr_lib` se omiten si falta) | – | – | – | – |

Versión mínima de MATLAB: **R2020b** (`exportgraphics` R2020a; `dlarray`/`adamupdate`
R2019b). `init_renon_model` comprueba la versión y las licencias con `license('test', …)`
y avisa de lo que falte.

No hay dependencias externas a MATLAB (sin solvers comerciales, sin Python, sin
archivos de datos descargables). Los scripts no contienen rutas absolutas; todo se
resuelve respecto de `fileparts(mfilename('fullpath'))`.

## Tiempos de ejecución medidos (R2026a, Apple Silicon)

| Script | Tiempo |
|---|---|
| `main_renon` (reporte v1 completo) | ≈ 16 s |
| `s1_hub` | ≈ 20 s |
| `reproduce_report_v2` (s1 … s5, pool ya iniciado) | ≈ 3,5 min |
| `s2_autoencoder` | ≈ 53 s |
| `s3_surrogates` | ≈ 76 s |
| `s4_doa` (12 procesos) | ≈ 35 s (+ ≈ 70 s de arranque del pool la primera vez) |
| `s5_attention_ems` | ≈ 12 s |
| una evaluación `renon_dispatch` / `renon_hub` | 1,1 ms / 3,3 ms |
| `run_all_tests` (29 pruebas) | ≈ 9 s |

## Compilación de los reportes

Ver `reporte/README.md`. Paquetes LaTeX usados: babel (spanish), geometry, graphicx,
xcolor, booktabs, amsmath, amssymb, bm, caption, siunitx, enumitem, fancyhdr, hyperref,
sectsty, multirow, longtable, array, url, textcomp (todos en TeX Live completo).
