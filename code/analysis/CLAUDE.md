# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this directory.

## What this directory is

`code/analysis/` holds the analysis code of the ReNoN-Azuay research project (DEET – Universidad de Cuenca). Its main content is the **MATLAB multi-vector energy model** in `propuesta_tecnica/`, which produced the two technical reports published in `docs/reportes/`:

- `propuesta_tecnica/matlab/` — model v1 (July 2026 report): hourly dispatch with valley-filling EMS, 6 decision variables, compact NSGA-II. Base MATLAB only.
- `propuesta_tecnica/matlab_v2/` — model v2 (September 2026 report): energy-hub formulation (`renon_hub`), V2G, attention EMS, autoencoder, KAN/MLP/attention surrogates, Dream Optimization Algorithm. Needs Deep Learning, Statistics & ML, Optimization and Global Optimization Toolboxes (Parallel Computing optional).
- `propuesta_tecnica/tests/` — `matlab.unittest` suite (unit, physics and regression tests against the reference CSVs).
- `propuesta_tecnica/resultados*/` — reference CSV outputs; `.mat` files are regenerated and git-ignored.
- `propuesta_tecnica/reporte/` — LaTeX sources and figures of both reports (PDFs are published in `docs/reportes/`).
- `info/` — reference PDFs (project proposal, PT1 report, Viesi et al. 2020).

## Commands

```matlab
cd code/analysis/propuesta_tecnica
init_renon_model                 % paths, toolbox check, output folders
results = run_renon_model;       % one configuration (default: v2 compromise 2030)
run_all_tests                    % or runtests('tests')
reproduce_report_v1              % ~15 s, regenerates resultados/ and reporte/figs/
reproduce_report_v2              % ~4 min, regenerates resultados_v2/ and reporte/figs_v2/
```

Reports: `cd propuesta_tecnica/reporte && pdflatex reporte_tecnico_renon.tex` (×2) and `pdflatex reporte_tecnico_renon_v2.tex` (×3); copy the PDFs to `docs/reportes/`.

## Conventions

- All paths are relative to `fileparts(mfilename('fullpath'))`; never add absolute paths.
- Seeds are fixed (`rng(seed,'twister')`); results are bit-reproducible in the same MATLAB release. When using `rng` inside `parfor`, always name the generator.
- Do not modify `matlab/` (v1) model logic: report v1 and the v2 regression test (`testHubReproducesV1`) depend on it. Changes to `renon_hub` must keep `f_g = 0` + `valley` identical to `renon_dispatch`.
- Numbers quoted in the reports must come from the CSVs in `resultados*/`; see `docs/MODEL_REPORT_TRACEABILITY.md`.
- Documentation of the model: `propuesta_tecnica/README.md`, `MODEL_ARCHITECTURE.md`, `PARAMETERS.md`, `ENVIRONMENT.md`.
