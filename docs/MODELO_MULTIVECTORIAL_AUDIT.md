# Auditoría inicial — modelo multivectorial y reportes técnicos (7 oct 2026)

Auditoría previa a la publicación de la versión consolidada del modelo ReNoN-Azuay y
de sus dos reportes técnicos en `ismael-minchala/renon-azuay`. Se hizo **antes** de
modificar el repositorio y sirve de registro de partida; el estado final se documenta
en `MULTIVECTOR_RELEASE_VERIFICATION.md`.

## 1. Estado del repositorio remoto (commit `1b955d8`, 25 sep 2026)

- Rama única `main`; 6 commits, todos del director del proyecto. Colaborador con
  acceso: Brian Loza (TINV), sin commits. GitHub Pages activo desde `main:/docs`.
- El clon local estaba limpio e idéntico a `origin/main`.
- Flujo de trabajo observado: commits directos a `main` por un único mantenedor → la
  actualización se hace con commits directos a `main` (no hay ramas ni PR abiertos).

## 2. Archivos locales vs. remotos

| Ubicación local | En GitHub | Observación |
|---|---|---|
| `ejecucion/repo/propuesta_tecnica/matlab/` (6 `.m`) | ✔ `code/analysis/propuesta_tecnica/matlab/` | idénticos byte a byte |
| `…/reporte/reporte_tecnico_renon.tex`, `.pdf`, `figs/` (7 PNG) | ✔ | idénticos |
| `…/resultados/` (4 CSV + 1 `.mat` de 2,8 MB) | ✔ | idénticos |
| `…/matlab_v2/` (12 `.m`) | ✘ | **nuevo** |
| `…/resultados_v2/` (20 CSV + 5 `.mat`, 7,9 MB de los cuales 7,8 MB son `.mat`) | ✘ | **nuevo** |
| `…/reporte/figs_v2/` (13 PNG, 1,0 MB) | ✘ | **nuevo** |
| `…/reporte/reporte_tecnico_renon_v2.tex`, `refs_v2.tex`, `.pdf` (1,7 MB) | ✘ | **nuevo** |
| `…/reporte/*.log`, clon: `*.aux`, `*.out` | — | artefactos de compilación (ignorados) |
| `ejecucion/repo/CLAUDE.md`, `info/*.pdf` | ✔ `code/analysis/CLAUDE.md`, `info/` | `CLAUDE.md` **obsoleto**: afirma que la carpeta no contiene código |
| `docs/reportes/2026-09_PT2_EnergyPLAN_MOEA_Trento.pdf` | ✔ | reporte de avance de B. Loza; no relacionado con el modelo, se conserva |

No se encontraron archivos duplicados ni obsoletos dentro del modelo. El único
duplicado real era el PDF v1, presente en `reporte/` y enlazado desde la web vía URL de
GitHub (`blob/main/...`) en lugar de `docs/reportes/`.

## 3. Reportes

| | v1 | v2 |
|---|---|---|
| PDF | `reporte_tecnico_renon.pdf`, 10 páginas, pdfTeX 1.40.26, 2 jul 2026 | `reporte_tecnico_renon_v2.pdf`, 25 páginas, 29 sep 2026 |
| Fuente editable | `reporte_tecnico_renon.tex` (bibliografía embebida, 5 entradas) | `reporte_tecnico_renon_v2.tex` + `refs_v2.tex` (22 entradas) |
| Generación | `pdflatex` ×2, sin BibTeX | `pdflatex` ×3 (longtable), sin BibTeX |
| Figuras | 7 PNG de `main_renon` | 13 PNG de `s1..s5` |
| Modelo | v1 (6 variables) | v2 (7 variables, hub) — extiende v1 |
| Log de compilación | sin warnings ni referencias indefinidas | ídem |

Ambos PDF se compilaron de sus fuentes `.tex` (producer pdfTeX; sin `??` en el texto).

## 4. Código MATLAB relacionado con el modelo

18 archivos `.m` (1647 líneas). Clasificación en
`code/analysis/propuesta_tecnica/MODEL_ARCHITECTURE.md` §12. Hallazgos del Code
Analyzer (R2026a): 0 mensajes en v1; en v2 sólo avisos de estilo (alineación,
preasignación, variables globales en `s4_doa` usadas deliberadamente para capturar la
historia de `ga`/`particleswarm`). Sin rutas absolutas. Puntos de entrada antes de la
auditoría: `matlab/main_renon` (v1) y cinco scripts `s1..s5` (v2) sin script
unificador, sin inicialización explícita y sin pruebas automatizadas.

Dependencias de datos: ninguna externa. `s1_hub` lee los CSV de Pareto de v1.
Dependencias de toolboxes de v2: Deep Learning, Statistics & ML, Optimization, Global
Optimization; Parallel Computing usada sin comprobación (`parpool` incondicional en
`s4_doa`, fallaría sin la toolbox).

Errores de ejecución encontrados: ninguno. Avisos: `pca` en `s2` ("columns linearly
dependent", por las horas nocturnas de FV nulas; benigno).

## 5. Texto de los reportes: lenguaje de borrador / meta-editorial encontrado

| Archivo | Texto | Acción |
|---|---|---|
| v2 resumen | "Todas las referencias citadas fueron verificadas e incluyen DOI." | eliminado |
| `refs_v2.tex` | comentario "Referencias verificadas (septiembre 2026). Todas incluyen DOI…" | reemplazado por cabecera neutra |
| v2 §1 | "identificada en la revisión interna de ese reporte" | reescrito sin referencia al proceso |
| v2 §5.2 | "se reporta sin atenuantes" | eliminado |
| v2 §6 | "(se presenta como lista ordenada)" | eliminado |
| v1 y v2, pie | "el código … se encuentra en `ejecucion/repo/propuesta_tecnica/`" (ruta local) | reemplazado por la ruta del repositorio y la URL |
| v1 §4.2 | "es el mayor palanca" | "la mayor palanca" |
| v1 bibliografía | `mahbub2016`, `lund2017` listadas pero no citadas, sin DOI, autores "et al." | citadas en el texto, DOI y autores completos añadidos |
| v2 Tabla 7 | tiempos de entrenamiento no reproducibles presentados sin aclaración | nota en el caption |
| v2 §5.5, Tabla 9, §5.2 | "solución de compromiso 2030" sin indicar que es la de la versión 1 | precisado |

Todos los DOI de ambas bibliografías resuelven en doi.org (comprobado 7 oct 2026);
títulos, revistas, volúmenes y años de las referencias clave cotejados en Crossref.

## 6. Documentación faltante (antes)

README del modelo incompleto (sólo v1), sin arquitectura, sin diccionario de
parámetros, sin entorno, sin trazabilidad reporte↔código, sin instrucciones de
compilación del reporte, sin pruebas, sin enlace desde el README raíz ni desde la web
al reporte v2.

## 7. Estructura final recomendada (y adoptada)

```
code/analysis/propuesta_tecnica/
  README.md                      guía completa del modelo
  MODEL_ARCHITECTURE.md  PARAMETERS.md  ENVIRONMENT.md
  init_renon_model.m  run_renon_model.m  renon_sanity_checks.m
  reproduce_report_v1.m  reproduce_report_v2.m  run_all_tests.m
  matlab/        v1 (sin cambios)          matlab_v2/   v2 (3 correcciones mínimas)
  tests/         matlab.unittest
  resultados/    CSV de referencia v1      resultados_v2/  CSV de referencia v2
  reporte/       .tex, refs_v2.tex, figs/, figs_v2/, README.md (sin PDF)
docs/reportes/   reporte_tecnico_renon.pdf, reporte_tecnico_renon_v2.pdf (+ reporte Trento)
docs/            MODELO_MULTIVECTORIAL_AUDIT.md, MODEL_REPORT_TRACEABILITY.md,
                 MULTIVECTOR_RELEASE_VERIFICATION.md
```

Se respeta la arquitectura existente (`code/analysis/propuesta_tecnica/` ya contenía
el modelo v1); `matlab_v2/` se añade junto a `matlab/` tal como lo describe el propio
reporte v2. Los `.mat` (8 MB, regenerables) dejan de versionarse; los CSV son la
referencia.
