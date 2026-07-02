# Propuesta técnica ReNoN-Azuay — simulación MATLAB

Primera versión operativa del modelo multivectorial **ReNoN** (electricidad renovable +
agua potable + movilidad eléctrica) para la provincia del Azuay, correspondiente a las
actividades 2.1–2.2 del PT2 del proyecto *Transición energética sostenible en
Azuay–Ecuador* (XXII Concurso VIUC).

## Metodología

Adaptación del marco **EnergyPLAN + MOEA** de Viesi et al. (2020), *Energy* 209:118378
(`../info/1-s2.0-S0360544220314857-main.pdf`):

- Simulación horaria anual (8760 h) del balance multivectorial con EMS jerárquico
  (cargas flexibles de bombeo y carga inteligente de VE, batería, importación SNI,
  térmica de respaldo).
- Optimización multiobjetivo NSGA-II (min CO₂, min costo anual) → frentes de Pareto
  2030 y 2050 y solución de compromiso (punto de rodilla).
- Prueba de estrés de sequía (*Hydroverfügbarkeitserzeugung*, reporte PT1) y análisis
  Monte Carlo (N=200).

## Estructura

```
matlab/
  main_renon.m        # flujo completo (ejecutar este)
  renon_params.m      # parámetros por escenario (base2024 | lc2030 | lc2050)
  renon_profiles.m    # generador estocástico de series horarias
  renon_dispatch.m    # EMS + indicadores (CO2, costo, ENS, resiliencia)
  nsga2_simple.m      # NSGA-II compacto (sin toolboxes)
  objetivos.m         # wrapper de objetivos para NSGA-II
resultados/           # CSV (resumen, frentes de Pareto, verificación) y .mat
reporte/
  reporte_tecnico_renon.tex/.pdf   # reporte técnico (pdflatex x2)
  figs/                            # figuras generadas por main_renon
```

## Ejecución

```bash
cd matlab
matlab -batch "main_renon"        # ~15 s, semillas fijas (reproducible)
cd ../reporte
pdflatex reporte_tecnico_renon.tex && pdflatex reporte_tecnico_renon.tex
```

## Resultados clave (semillas por defecto)

| Escenario | FV | Eólica | Hidro local | CO₂ total | Δ vs base | Fracción renov. |
|---|---|---|---|---|---|---|
| Base 2024 | 5 MW | 50 MW | 40 MW | 532 kt | — | 25.7 % |
| Compromiso 2030 | 255 MW | 150 MW | 70 MW | 418 kt | −21 % | 57.5 % |
| Compromiso 2050 | 580 MW | 300 MW | 100 MW | 227 kt | −57 % | 63.0 % |

Verificación: NRMSE = 3.1 % (< 15 %), Pearson r = 0.994 (> 0.85). Resiliencia ante
sequía extrema: 0.993 (con ReNoN) vs 0.943 (sin ReNoN); ENS −88 %.

**Nota**: los parámetros provinciales (demanda CENTROSUR, agua ETAPA, flota) son
estimaciones de ingeniería a calibrar con los datos de los talleres del PT1.
