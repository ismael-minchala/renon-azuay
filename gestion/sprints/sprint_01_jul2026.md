# Sprint 1 — Julio 2026

**Estado:** 🟡 ACTIVO  
**Período:** 2 – 31 julio 2026  
**Objetivo del sprint:** Arrancar el proyecto científico, configurar las infraestructuras del equipo, recopilar primeras fuentes de datos, ejecutar el Workshop 1 y crear el repositorio de documentación bibliográfica.

---

## Meta del sprint

> Al finalizar el sprint, el equipo habrá: (1) configurado todas las herramientas del proyecto, (2) enviado solicitudes formales de datos a CENTROSUR, ARCERNNR y ETAPA, (3) iniciado la recopilación de datos de VEs, (4) ejecutado el Workshop 1 participativo, y (5) creado el repositorio de documentación bibliográfica compartida.

---

## Sprint Backlog

| ID | Tarea | Responsable principal | Colaboradores | Tamaño | Estado |
|---|---|---|---|:---:|:---:|
| T-0.1 | Crear repositorio GitHub `renon-azuay` | TINV | — | S | ⬜ |
| T-0.2 | Configurar GitHub Projects (tablero Kanban digital) | TINV | — | S | ⬜ |
| T-0.3 | Crear sitio web inicial en GitHub Pages | TINV | — | M | ⬜ |
| T-0.4 | Configurar grupo de WhatsApp del equipo | TINV | DP | S | ⬜ |
| T-0.5 | Kickoff meeting — acordar herramientas, DoD, comunicación | DP | Todos | M | ⬜ |
| T-0.6 | Cargar documentos de gestión (carpeta `gestion/`) al repositorio | TINV | AI | S | ⬜ |
| T-0.7 | Configurar repositorio de documentación bibliográfica (Zotero + `references/` en GitHub) | INV1 | TINV | M | ⬜ |
| T-1.1.1 | Redactar y enviar carta formal a CENTROSUR solicitando datos 2003–2024 | DP | INV2 | M | ⬜ |
| T-1.1.2 | Descargar datos disponibles en portal ARCERNNR/ARCONEL (balance energético) | INV2 | AI | M | ⬜ |
| T-1.1.3 | Redactar y enviar solicitud a ETAPA para datos de consumo hídrico | DP | INV1 | S | ⬜ |
| T-1.1.4 | Recopilar datos de registro de VEs (ANT, EMOV-EP, MINTUR) — fuentes abiertas | TINV | AI | M | ⬜ |
| T-1.4.1 | Diseñar metodología del Workshop 1 (agenda, preguntas guía, dinámica) | DP | INV1 | M | ⬜ |
| T-1.4.2 | Enviar invitaciones Workshop 1 (CENTROSUR, ETAPA, GAD, juntas parroquiales) | DP | — | S | ⬜ |
| T-1.4.3 | Ejecutar Workshop 1 | DP | INV1, INV2 | M | ⬜ |

---

## Tarea nueva: T-0.7 — Repositorio de documentación bibliográfica

**Responsable:** INV1 (Martín Ortega) + TINV (Brian Loza)  
**Objetivo:** Centralizar artículos científicos, informes técnicos y datos de referencia relevantes para el proyecto.

### Estructura sugerida

```
Plataforma 1 — Zotero (gestión de artículos)
  Crear grupo compartido: "ReNoN-Azuay" en zotero.org/groups
  Todos los miembros se unen con cuenta gratuita
  Subir PDFs y metadatos de artículos relevantes (energía, optimización, VEs, ReNoN)
  Etiquetar por PT: PT1, PT2, PT3, PT4

Plataforma 2 — GitHub (repo renon-azuay)
  references/
  ├── references.bib         ← BibTeX con todos los artículos
  ├── state_of_the_art.md    ← bibliografía anotada por temática
  └── summaries/             ← resúmenes de 1 página de artículos clave
```

### Temáticas prioritarias para la búsqueda inicial
- Redes de energía multivectorial / Multi-energy systems
- Energy Management Systems (EMS) y metaheurística
- Modelos de transición energética en América Latina
- Vehículos eléctricos: adopción y modelado de demanda
- Marco ReNoN (Renewable Network of Networks)

### Fuentes recomendadas
- Scopus / Web of Science (acceso UCuenca vía biblioteca)
- IEEE Xplore, ScienceDirect (Elsevier), MDPI (acceso abierto)
- Repositorio UCuenca: dspace.ucuenca.edu.ec

---

## Cronograma interno del Sprint 1

| Semana | Fechas | Foco principal | Responsables |
|:---:|---|---|---|
| Semana 1 | 1–7 jul | Sprint Planning (jue 2) + configuración herramientas | TINV (GitHub, web, WhatsApp), DP (kickoff) |
| Semana 2 | 8–14 jul | Solicitudes de datos + preparación Workshop + inicio repo bibliográfico | DP+INV2 (CENTROSUR, ETAPA), INV1+TINV (Zotero) |
| Semana 3 | 15–21 jul | VEs + datos ARCERNNR + invitaciones Workshop | TINV+AI (datos), DP (invitaciones) |
| Semana 4 | 22–24 jul | Workshop 1 (22-24 jul) + Sprint Review (vie 24 jul) | Todos |

---

## Sincronías del Sprint

| Fecha | Tipo | Hora | Agenda |
|---|---|---|---|
| Jue 02 jul | **Sprint Planning** (2 h) | 16:00 | Confirmar tareas, asignar, aclarar dudas, acordar DoD |
| Jue 09 jul | Sincronía semanal (30 min) | 16:00 | Estado inicial, bloqueos configuración |
| Jue 16 jul | Sincronía semanal (30 min) | 16:00 | Estado semana 2, avance solicitudes datos |
| 22–24 jul | **Workshop 1 participativo** | TBD | Según disponibilidad de stakeholders |
| Jue 23 jul | Sincronía (dentro Workshop) | 16:00 | Integrar en agenda Workshop si es posible |
| Vie 24 jul | **Sprint Review** (1 h) | TBD | Demo: repositorio, sitio web, datos recopilados, Workshop |

> **Comunicación del equipo:** Grupo de **WhatsApp** «ReNoN-Azuay» — respuesta máx. 24 h en días hábiles.

---

## Bloqueos conocidos

| Bloqueo | Impacto | Acción |
|---|---|---|
| CENTROSUR puede demorar en responder la solicitud | Retrasa limpieza de datos (Sprint 2) | Iniciar análisis con datos ARCERNNR disponibles en paralelo |
| Workshop 1: confirmación de invitados | Puede desplazarse a primera semana de agosto | Enviar invitaciones antes del 9 jul y tener fecha alternativa (4–7 ago) |
| Acceso Scopus/WoS para repo bibliográfico | Depende de credenciales de biblioteca UCuenca | INV1 gestiona acceso con Biblioteca Central DEET |

---

## Tarea de borradores de reportes PT1

TINV (Brian Loza) redacta los borradores de los Reportes 1 y 2 durante Sprint 2 (agosto).  
Colaboradores: INV2 revisa Reporte 1; AI apoya recopilación de datos para ambos reportes.

| Tarea | Borrador | Revisión | Aprobación |
|---|---|---|---|
| T-1.1.7 Reporte 1 — oferta/demanda | TINV | INV2 + DP | DP |
| T-1.1.8 Reporte 2 — vehículos eléctricos | TINV | INV2 + AI + DP | DP |

---

## Definición de terminado del Sprint 1

- [ ] Repositorio GitHub creado con README y estructura de carpetas.
- [ ] GitHub Projects configurado con el tablero Kanban inicial.
- [ ] Sitio web en GitHub Pages accesible con URL pública.
- [ ] Grupo de WhatsApp activo con todo el equipo conectado.
- [ ] Al menos 2 solicitudes formales de datos enviadas (CENTROSUR + ETAPA).
- [ ] Datos de VEs iniciales recopilados de fuentes abiertas.
- [ ] Workshop 1 ejecutado (22–24 jul) o fecha alternativa confirmada.
- [ ] Grupo Zotero «ReNoN-Azuay» creado y con al menos 10 artículos cargados.
- [ ] Carpeta `references/` en GitHub con `references.bib` inicial.

---

## Velocidad objetivo

| Rol | Horas disp./semana | Horas disp. (julio) | Tareas asignadas |
|---|---|---|---|
| DP | ~5 h | ~20 h | T-0.5, T-1.1.1, T-1.1.3, T-1.4.1, T-1.4.2, T-1.4.3 |
| INV1 | ~5 h | ~20 h | T-0.5, T-0.7, T-1.1.3, T-1.4.1, T-1.4.3 |
| INV2 | ~5 h | ~20 h | T-0.5, T-1.1.1, T-1.1.2, T-1.4.3 |
| TINV | **~40 h** | **~160 h** | T-0.1, T-0.2, T-0.3, T-0.4, T-0.6, T-0.7, T-1.1.4 |
| AI | ~10 h | ~40 h | T-0.6, T-1.1.2, T-1.1.4 |
