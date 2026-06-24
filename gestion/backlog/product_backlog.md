# Product Backlog — ReNoN-Azuay

Estado: Actualizado al 23/06/2026  
Responsable del backlog: DP (Luis Ismael Minchala) + TINV (Brian Loza)

> Cada tarea tiene: ID · descripción · responsable(s) · tamaño estimado · sprint objetivo.  
> **Tamaños:** S = ½ día · M = 1-2 días · L = 3-5 días · XL = 1-2 semanas

---

## ÉPICA 0 — Configuración del proyecto (Sprint 1)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-0.1 | Crear repositorio GitHub del proyecto (`renon-azuay`) | TINV | S | 1 |
| T-0.2 | Configurar GitHub Projects (tablero Kanban digital) | TINV | S | 1 |
| T-0.3 | Crear sitio web inicial en GitHub Pages | TINV | M | 1 |
| T-0.4 | Configurar canal Microsoft Teams del equipo | TINV | S | 1 |
| T-0.5 | Kickoff meeting: acordar herramientas, comunicación, DoD | DP+Todos | M | 1 |
| T-0.6 | Cargar documentos de gestión al repositorio | TINV+AI | S | 1 |

---

## ÉPICA PT1 — Diagnóstico y caracterización

### Act. 1.1 — Recopilación de datos (Sprints 1-2)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-1.1.1 | Solicitar datos de generación y demanda 2003-2024 a CENTROSUR | DP + INV2 | M | 1 |
| T-1.1.2 | Descargar datos del balance energético del Azuay (ARCERNNR/ARCONEL) | INV2 + AI | M | 1 |
| T-1.1.3 | Solicitar datos de consumo hídrico y tarifas a ETAPA | DP + INV1 | S | 1 |
| T-1.1.4 | Recopilar datos de registro y adopción de VEs (ANT, EMOV-EP, MINTUR) | TINV + AI | M | 1 |
| T-1.1.5 | Recopilar datos de calidad de aire (EMOV, INEC) para análisis de impacto | AI | M | 2 |
| T-1.1.6 | Limpieza y estructuración de todos los datos (Python/Pandas) | TINV + AI | L | 2 |
| T-1.1.7 | Redactar Reporte 1: oferta y demanda de energía en el Azuay | INV2 + AI | L | 2 |
| T-1.1.8 | Redactar Reporte 2: disponibilidad de vehículos eléctricos en el Azuay | TINV + AI | L | 2 |
| T-1.1.9 | Revisar y aprobar Reportes 1 y 2 | DP | M | 2 |
| T-1.1.10 | Publicar Reportes 1 y 2 en el blog del proyecto | TINV | S | 2 |

### Act. 1.2 — Identificación de vulnerabilidades (Sprints 2-3)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-1.2.1 | Revisión bibliográfica de KPIs para sistemas energéticos multivectoriales | INV1 | L | 2 |
| T-1.2.2 | Entrevistas/reunión con expertos de CENTROSUR (vulnerabilidad red eléctrica) | DP + INV2 | M | 2 |
| T-1.2.3 | Análisis de vulnerabilidad hídrica con datos INAMHI (caudales, precipitación) | INV2 + TINV | L | 3 |
| T-1.2.4 | Análisis de dependencia de combustibles fósiles en el transporte del Azuay | TINV | M | 3 |
| T-1.2.5 | Definición preliminar de KPIs con evidencia combinada | DP + INV1 + INV2 | M | 3 |
| T-1.2.6 | Redactar reporte de KPIs y vulnerabilidades | TINV | L | 3 |
| T-1.2.7 | Validar reporte de KPIs con stakeholders (reunión corta CENTROSUR/ETAPA) | DP | M | 3 |

### Act. 1.3 — Construcción de líneas base (Sprints 3-4)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-1.3.1 | Definir estructura del modelo de línea base (variables, resolución temporal) | INV2 + TINV | M | 3 |
| T-1.3.2 | Implementar modelo de demanda energética base en MATLAB/Python | TINV | XL | 3 |
| T-1.3.3 | Implementar modelo de generación hidroeléctrica base | TINV | L | 4 |
| T-1.3.4 | Calibrar modelos con datos históricos (NRMSE < 15%) | TINV + INV2 | L | 4 |
| T-1.3.5 | Generar y documentar base de datos 2003-2024 (Producto 3) | TINV + AI | L | 4 |
| T-1.3.6 | Publicar base de datos en GitHub con README y licencia CC | TINV | M | 4 |
| T-1.3.7 | Documentar modelo de línea base (notebook reproducible) | TINV | M | 4 |

### Act. 1.4 — Talleres participativos (Sprints 1 y 3)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-1.4.1 | Diseñar metodología de taller (investigación-acción participativa) | DP + INV1 | M | 1 |
| T-1.4.2 | Enviar invitaciones Workshop 1 (CENTROSUR, ETAPA, GAD, juntas parroquiales) | DP | S | 1 |
| T-1.4.3 | Ejecutar Workshop 1 (co-diseño inicial, identificación de necesidades) | DP+INV1+INV2 | M | 1 |
| T-1.4.4 | Sistematizar y analizar resultados Workshop 1 | TINV + AI | M | 2 |
| T-1.4.5 | Enviar invitaciones Workshop 2 | DP | S | 3 |
| T-1.4.6 | Ejecutar Workshop 2 (retroalimentación sobre vulnerabilidades y KPIs) | DP+INV1+INV2 | M | 3 |
| T-1.4.7 | Sistematizar resultados Workshop 2 e incorporar al modelo | TINV + AI | M | 3 |

---

## ÉPICA PT2 — Diseño del modelo multivectorial ReNoN

### Act. 2.1 — Formulación del modelo (Sprints 4-5)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-2.1.1 | Revisión de literatura sobre modelos multi-energía (MES) y ReNoN | INV1 + INV2 | L | 4 |
| T-2.1.2 | Definir arquitectura del modelo multivectorial (electricidad-agua-movilidad) | DP + INV1 + INV2 | L | 5 |
| T-2.1.3 | Modelar red eléctrica renovable (solar+eólica+hidro) en MATLAB/Python | TINV | XL | 5 |
| T-2.1.4 | Modelar red hídrica (demanda de agua, interacción con generación hidro) | INV2 + TINV | L | 5 |
| T-2.1.5 | Modelar red de movilidad eléctrica (flota, patrones de carga) | TINV + AI | L | 5 |
| T-2.1.6 | Integrar los tres vectores en modelo ReNoN unificado | TINV + INV1 | XL | 5 |

### Act. 2.2 — Algoritmos de optimización EMS (Sprints 5-7)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-2.2.1 | Revisión de metaheurísticas para EMS (PSO, GA, DE, NSGA-II) | INV1 | L | 5 |
| T-2.2.2 | Selección y justificación del algoritmo de optimización | DP + INV1 | M | 6 |
| T-2.2.3 | Implementar función objetivo multicriterio (costo, emisiones, resiliencia) | INV1 + TINV | XL | 6 |
| T-2.2.4 | Implementar algoritmo EMS en Python (modular, documentado) | TINV | XL | 6 |
| T-2.2.5 | Correr pruebas del EMS en supercomputador DEET (Monte Carlo) | TINV | L | 7 |
| T-2.2.6 | Validar convergencia y tiempos de cómputo del EMS | INV1 + TINV | L | 7 |
| T-2.2.7 | Escribir documentación técnica del EMS (README, docstrings, notebook) | TINV | L | 7 |
| T-2.2.8 | Publicar EMS en GitHub con licencia MIT (Producto 4) | TINV | M | 8 |

### Act. 2.3 — Redefinición de KPIs (Sprints 7-8)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-2.3.1 | Analizar resultados de primeras simulaciones del EMS | DP + INV1 + INV2 | M | 7 |
| T-2.3.2 | Proponer redefinición de KPIs con base en evidencia de simulación | DP + INV1 | M | 7 |
| T-2.3.3 | Consulta/validación de KPIs con CENTROSUR, ETAPA, GAD | DP | M | 8 |
| T-2.3.4 | Redactar reporte final de KPIs redefinidos | TINV | M | 8 |

### Act. 2.4 — Sesión de retroalimentación intermedia (Sprint 8)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-2.4.1 | Preparar presentación de avances del modelo ReNoN para actores locales | DP + INV2 | M | 8 |
| T-2.4.2 | Ejecutar sesión de retroalimentación | DP+INV1+INV2 | M | 8 |
| T-2.4.3 | Documentar ajustes identificados e incorporar al modelo | TINV | M | 8 |

---

## ÉPICA PT3 — Simulación de escenarios

### Act. 3.1 — Escenarios urbanos y rurales (Sprints 9-11)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-3.1.1 | Definir escenarios de penetración renovable (solar, eólica, almacenamiento) | INV1 + INV2 | M | 9 |
| T-3.1.2 | Simular escenarios zona urbana — parroquias Cuenca (Monte Carlo) | TINV | XL | 9 |
| T-3.1.3 | Simular escenarios zona rural — Tarqui, Victoria del Portete, Cumbe | TINV | XL | 10 |
| T-3.1.4 | Análisis estadístico de resultados (incertidumbre, sensibilidad) | INV1 + TINV | L | 10 |
| T-3.1.5 | Calcular índice de resiliencia energética para cada escenario | INV1 | L | 10 |
| T-3.1.6 | Redactar borrador Artículo 1 (ReNoN aplicado al Azuay) | DP + INV1 + INV2 | XL | 11 |
| T-3.1.7 | Revisión interna del Artículo 1 | DP | L | 11 |

### Act. 3.2 — Simulación de políticas (Sprints 11-13)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-3.2.1 | Definir escenarios de política (subsidios, tarifas, incentivos) con literatura | INV1 + INV2 | L | 11 |
| T-3.2.2 | Simular impacto de políticas en seguridad energética | TINV | XL | 12 |
| T-3.2.3 | Simular impacto en sostenibilidad ambiental (emisiones CO₂) | TINV | XL | 12 |
| T-3.2.4 | Análisis comparativo entre políticas | INV1 + INV2 | L | 13 |
| T-3.2.5 | Redactar borrador Artículo 2 (comparación escenarios con metaheurísticas) | DP + INV1 + INV2 | XL | 13 |
| T-3.2.6 | Revisión interna del Artículo 2 | DP | L | 13 |

### Act. 3.3 — Comparación ReNoN vs. planificación tradicional (Sprints 13-14)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-3.3.1 | Definir escenario de referencia (sistema actual sin ReNoN) | DP + INV1 | M | 13 |
| T-3.3.2 | Comparar indicadores energéticos, económicos y sociales | INV2 + TINV | L | 14 |
| T-3.3.3 | Redactar reporte técnico de comparación | TINV | M | 14 |
| T-3.3.4 | Enviar Artículos 1 y 2 a revistas objetivo (Productos 5 y 6) | DP | M | 14 |

### Act. 3.4 — Estimación de inversión (Sprint 14)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-3.4.1 | Cuantificar inversión requerida escenario 2030 (infraestructura, CAPEX) | INV2 + TINV | L | 14 |
| T-3.4.2 | Cuantificar inversión requerida escenario 2050 | INV2 + TINV | L | 14 |
| T-3.4.3 | Análisis de sensibilidad financiera (variación de tasas de interés, costos) | INV2 | M | 14 |

---

## ÉPICA PT4 — Validación y lineamientos

### Act. 4.1 — Validación con casos internacionales (Sprints 15-17)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-4.1.1 | Revisión detallada de caso Dinamarca (sistemas multi-energía) | INV1 | L | 15 |
| T-4.1.2 | Revisión detallada de caso Alemania (Energiewende) | INV2 | L | 15 |
| T-4.1.3 | Revisión detallada de caso Italia (Provincia de Trento, caso Viesi et al.) | INV1 | L | 16 |
| T-4.1.4 | Calcular métricas de validación (NRMSE, coef. Pearson) | TINV | L | 16 |
| T-4.1.5 | Encuesta de percepción (validación cruzada con stakeholders) | AI | L | 16 |
| T-4.1.6 | Redactar white paper / artículo de divulgación | DP + INV1 | L | 17 |

### Act. 4.2 — Discusión con actores locales (Sprints 17-18)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-4.2.1 | Preparar taller final de presentación de resultados | DP + INV2 | M | 17 |
| T-4.2.2 | Ejecutar taller con municipalidad, CENTROSUR, ETAPA, EMOV | DP+INV1+INV2 | M | 17 |
| T-4.2.3 | Incorporar feedback en ajustes finales del modelo | TINV + INV1 | L | 18 |

### Act. 4.3 — Lineamientos técnicos y políticos (Sprints 18-20)

| ID | Tarea | Responsable | Tamaño | Sprint |
|---|---|---|:---:|:---:|
| T-4.3.1 | Redactar lineamientos técnicos (energía, agua, movilidad) | DP + INV1 + INV2 | XL | 18 |
| T-4.3.2 | Enviar borrador a Facultad de Jurisprudencia UCuenca para revisión | DP | S | 19 |
| T-4.3.3 | Incorporar revisión jurídica al documento | TINV + DP | M | 19 |
| T-4.3.4 | Validar lineamientos con CENTROSUR, ETAPA, GAD, MEER | DP | M | 19 |
| T-4.3.5 | Diseño editorial y maquetación del reporte final (Producto 7) | AI + TINV | L | 20 |
| T-4.3.6 | Publicar reporte final en sitio web y enviar al VIUC | DP + TINV | M | 20 |
| T-4.3.7 | Cierre administrativo del proyecto con VIUC | DP | M | 20 |

---

## Difusión (transversal a todo el proyecto)

| ID | Tarea | Responsable | Tamaño | Sprint aprox. |
|---|---|---|:---:|:---:|
| D-1 | Organizar Seminario 1 en DEET | DP | M | 6 |
| D-2 | Organizar Seminario 2 | INV1 | M | 11 |
| D-3 | Organizar Seminario 3 | INV2 | M | 15 |
| D-4 | Organizar Seminario 4 (cierre) | DP | M | 20 |
| D-5 | Webinar 1 (coordinado con IEEE Ecuador IES-CSS) | DP + INV1 | M | 10 |
| D-6 | Webinar 2 | DP + INV2 | M | 17 |
| D-7 | Presentación en conferencia internacional #1 | INV1 o INV2 | L | 12 |
| D-8 | Presentación en conferencia internacional #2 | DP o INV1 | L | 16 |
| D-9 | Presentación en conferencia internacional #3 | INV2 | L | 19 |
| D-10 | Actualizar sitio web con novedades del proyecto | TINV | S | Mensual |
