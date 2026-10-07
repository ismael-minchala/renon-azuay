# ReNoN-Azuay

**Transición energética sostenible en Azuay–Ecuador mediante infraestructuras integradas**

Enfoque multi-vectorial (ReNoN) para la gestión de electricidad renovable, agua potable
y movilidad eléctrica en la provincia del Azuay, Ecuador.

- **Institución:** DEET – Universidad de Cuenca
- **Período:** Marzo 2026 – Febrero 2028
- **Financiamiento:** VIUC – XXII Concurso Universitario de Proyectos de Investigación
- **Sitio web:** https://ismael-minchala.github.io/renon-azuay/

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `docs/` | Sitio web del proyecto (GitHub Pages) |
| `gestion/` | Sprints, kanban, backlog, cronograma |
| `references/` | Bibliografía anotada y BibTeX |
| `data/processed/` | Datasets limpios con README de variables |
| `code/analysis/propuesta_tecnica/` | Modelo multivectorial ReNoN en MATLAB (v1 y v2), pruebas y fuentes de los reportes técnicos |

## Modelo multivectorial y reportes técnicos

El modelo ReNoN-Azuay (electricidad renovable + agua potable + movilidad eléctrica,
8760 h, optimización NSGA-II CO₂–costo para 2030 y 2050) está implementado en MATLAB y
documentado en dos reportes técnicos:

| | Reporte | Modelo |
|---|---|---|
| **v1** · jul 2026 | [Propuesta técnica de solución: modelo multivectorial ReNoN](docs/reportes/reporte_tecnico_renon.pdf) | [`code/analysis/propuesta_tecnica/matlab/`](code/analysis/propuesta_tecnica/matlab/) — despacho horario, EMS de llenado de valles, 6 variables |
| **v2** · sep 2026 | [Propuesta técnica extendida: modelo vectorial ReNoN](docs/reportes/reporte_tecnico_renon_v2.pdf) | [`code/analysis/propuesta_tecnica/matlab_v2/`](code/analysis/propuesta_tecnica/matlab_v2/) — concentrador energético, V2G, EMS con atención, autoencoder, KAN, DOA |

- **Cómo ejecutar** (MATLAB R2020b+; v1 sin toolboxes):
  ```matlab
  cd code/analysis/propuesta_tecnica
  init_renon_model
  results = run_renon_model;        % una configuración
  run_all_tests                     % pruebas unitarias y de regresión
  reproduce_report_v1               % resultados del reporte v1 (~15 s)
  reproduce_report_v2               % resultados del reporte v2 (~4 min, toolboxes)
  ```
- **Documentación del modelo:** [README](code/analysis/propuesta_tecnica/README.md) ·
  [arquitectura](code/analysis/propuesta_tecnica/MODEL_ARCHITECTURE.md) ·
  [parámetros](code/analysis/propuesta_tecnica/PARAMETERS.md) ·
  [entorno](code/analysis/propuesta_tecnica/ENVIRONMENT.md) ·
  [compilación de los reportes](code/analysis/propuesta_tecnica/reporte/README.md)
- **Trazabilidad reporte ↔ código:** [docs/MODEL_REPORT_TRACEABILITY.md](docs/MODEL_REPORT_TRACEABILITY.md)
- **Verificación de esta versión:** [docs/MULTIVECTOR_RELEASE_VERIFICATION.md](docs/MULTIVECTOR_RELEASE_VERIFICATION.md)
- Otros reportes del proyecto: [docs/reportes/](docs/reportes/)

## Equipo

| Rol | Persona |
|---|---|
| Director | Dr. Luis Ismael Minchala Avila |
| Investigador 1 | Martín Ortega |
| Investigador 2 | Paúl Arévalo |
| Técnico | Brian Loza |
| Ayudante | Santiago Matías Ordóñez Carpio (desde sep 2026; anteriormente Pablo Cárdenas, mar–ago 2026) |

## Contacto

ismael.minchala@ucuenca.edu.ec
