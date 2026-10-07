# Fuentes de los reportes técnicos del modelo multivectorial

| Reporte | Fuente | Bibliografía | Figuras | PDF publicado |
|---|---|---|---|---|
| v1 (julio 2026) | `reporte_tecnico_renon.tex` | `thebibliography` dentro del `.tex` | `figs/fig1..fig7.png` (genera `matlab/main_renon.m`) | `docs/reportes/reporte_tecnico_renon.pdf` |
| v2 (septiembre 2026) | `reporte_tecnico_renon_v2.tex` | `refs_v2.tex` (`\input`) | `figs_v2/fig_v2_1..13.png` (generan `matlab_v2/s1..s5`) | `docs/reportes/reporte_tecnico_renon_v2.pdf` |

Los PDF **no** se guardan en esta carpeta: la copia publicada vive en `docs/reportes/`
(servida también por GitHub Pages). Esta carpeta contiene únicamente fuentes
editables y figuras.

## Dependencias

- TeX Live (2024 o similar) con `pdflatex`; paquetes: babel spanish, geometry,
  graphicx, xcolor, booktabs, amsmath, amssymb, bm, caption, siunitx, enumitem,
  fancyhdr, hyperref, sectsty, multirow, longtable, array, url, textcomp.
- No se usa BibTeX: las bibliografías están escritas con `thebibliography`, de modo
  que no hace falta ningún comando `bibtex`.
- Las figuras deben existir antes de compilar. Si se regeneran con MATLAB
  (`reproduce_report_v1`, `reproduce_report_v2`) los PNG cambian de bytes pero no de
  contenido (semillas fijas).

## Compilación

Desde esta carpeta:

```bash
# Reporte v1 (10 páginas)
pdflatex -interaction=nonstopmode reporte_tecnico_renon.tex
pdflatex -interaction=nonstopmode reporte_tecnico_renon.tex

# Reporte v2 (25 páginas; longtable necesita una pasada adicional)
pdflatex -interaction=nonstopmode reporte_tecnico_renon_v2.tex
pdflatex -interaction=nonstopmode reporte_tecnico_renon_v2.tex
pdflatex -interaction=nonstopmode reporte_tecnico_renon_v2.tex

# Publicar
cp reporte_tecnico_renon.pdf reporte_tecnico_renon_v2.pdf ../../../../docs/reportes/
```

O con `latexmk`:

```bash
latexmk -pdf reporte_tecnico_renon.tex reporte_tecnico_renon_v2.tex
```

Los archivos auxiliares (`.aux`, `.log`, `.out`, `.toc`, `.synctex.gz`) están en
`.gitignore`.

## Comprobaciones antes de publicar

```bash
pdftotext -layout reporte_tecnico_renon_v2.pdf - | grep -n "??"      # referencias sin resolver
grep -i -E "warning|undefined" reporte_tecnico_renon_v2.log           # avisos de LaTeX
pdfinfo reporte_tecnico_renon_v2.pdf | grep Pages
```

## Relación entre las dos versiones

- **v1** documenta el modelo de despacho con 6 variables de decisión y el flujo
  completo de `main_renon` (línea base, NSGA-II 2030/2050, estrés de sequía, Monte
  Carlo).
- **v2** extiende v1 con la formulación de concentrador energético (`renon_hub`, 7
  variables con V2G, indicadores por vector) y evalúa autoencoders, KAN, atención y
  DOA. Con `f_g = 0` y llenado de valles `renon_hub` reproduce v1 exactamente (prueba
  `testHubReproducesV1`). Los experimentos de EMS (s5) y de Monte Carlo con
  autoencoder (s2) usan la solución de compromiso 2030 **de la versión 1**; los
  frentes y la Tabla 5 de v2 usan la nueva solución de compromiso de 7 variables.

Trazabilidad tabla/figura ↔ script ↔ CSV: `docs/MODEL_REPORT_TRACEABILITY.md`.
