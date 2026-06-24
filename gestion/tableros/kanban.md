# Tablero Kanban — ReNoN-Azuay

**Actualizado:** 23 junio 2026 | **Sprint activo:** Sprint 1 (julio 2026)

> Este archivo es la **versión de referencia offline** del tablero.  
> El tablero digital vive en **GitHub Projects** → ver instrucciones al final de este archivo.

---

## Estado actual del tablero (inicio Sprint 1)

### 📋 BACKLOG (próximos sprints)

| ID | Tarea | Responsable | Sprint objetivo |
|---|---|---|:---:|
| T-1.1.5 | Recopilar datos de calidad de aire (EMOV, INEC) | AI | 2 |
| T-1.1.6 | Limpieza y estructuración de datos (Python/Pandas) | TINV + AI | 2 |
| T-1.1.7 | Redactar Reporte 1 — oferta/demanda energía | INV2 + AI | 2 |
| T-1.1.8 | Redactar Reporte 2 — vehículos eléctricos | TINV + AI | 2 |
| T-1.2.1 | Revisión bibliográfica de KPIs | INV1 | 2 |
| T-1.2.2 | Entrevistas con CENTROSUR (vulnerabilidades red) | DP + INV2 | 2 |
| T-1.3.1 | Definir estructura del modelo de línea base | INV2 + TINV | 3 |
| _(ver backlog completo)_ | ... | ... | ... |

---

### 🔜 SPRINT BACKLOG — Sprint 1 (julio 2026)

| ID | Tarea | Responsable | WIP |
|---|---|---|:---:|
| T-0.1 | Crear repositorio GitHub `renon-azuay` | TINV | — |
| T-0.2 | Configurar GitHub Projects | TINV | — |
| T-0.3 | Crear sitio web en GitHub Pages | TINV | — |
| T-0.4 | Configurar grupo de WhatsApp del equipo | TINV | — |
| T-0.7 | Crear repositorio bibliográfico (Zotero + `references/` GitHub) | INV1+TINV | — |
| T-0.5 | Kickoff meeting del equipo | DP + Todos | — |
| T-0.6 | Cargar documentos gestión al repo | TINV + AI | — |
| T-1.1.1 | Solicitar datos a CENTROSUR | DP + INV2 | — |
| T-1.1.2 | Descargar datos ARCERNNR/ARCONEL | INV2 + AI | — |
| T-1.1.3 | Solicitar datos a ETAPA | DP + INV1 | — |
| T-1.1.4 | Recopilar datos VEs (ANT, EMOV) | TINV + AI | — |
| T-1.4.1 | Diseñar metodología Workshop 1 | DP + INV1 | — |
| T-1.4.2 | Enviar invitaciones Workshop 1 | DP | — |
| T-1.4.3 | Ejecutar Workshop 1 | DP+INV1+INV2 | — |

---

### 🚧 EN PROGRESO _(límite WIP: 2/TINV, 1/otros)_

_Vacío al inicio del Sprint 1. Se actualizará el jueves 2 de julio en el Sprint Planning (16:00)._

| ID | Tarea | Responsable | Desde |
|---|---|---|---|
| — | — | — | — |

---

### 👀 EN REVISIÓN

| ID | Tarea | Responsable | Revisor |
|---|---|---|---|
| — | — | — | — |

---

### ✅ COMPLETADO

| ID | Tarea | Responsable | Completado |
|---|---|---|---|
| — | Conformación del equipo de trabajo | DP | Jun 2026 |

---

## Métricas del proyecto

| Métrica | Valor actual | Meta |
|---|---|---|
| Sprints completados | 0 / 20 | 20 |
| Tareas completadas | 0 / ~80 | ~80 |
| Entregables listos | 0 / 7 | 7 |
| Días hasta PT1 (31/ago/2026) | 69 | — |
| Días hasta PT2 (28/feb/2027) | 250 | — |

---

## Configuración de GitHub Projects

Para replicar este tablero en GitHub Projects, siga estos pasos:

### Paso 1 — Crear el repositorio

```bash
# En GitHub.com, crear repositorio: renon-azuay
# Visibilidad recomendada: Public (para GitHub Pages gratis)
# Inicializar con README
```

### Paso 2 — Crear el Project

1. Ir al repositorio en GitHub.
2. Pestaña **Projects** → **New project**.
3. Seleccionar plantilla: **Board** (Kanban).
4. Nombrar: `ReNoN-Azuay — Tablero Scrumban`.

### Paso 3 — Configurar columnas

Crear estas columnas en orden:

| Columna | Descripción | Límite WIP |
|---|---|---|
| 📋 Backlog | Todas las tareas futuras | Sin límite |
| 🔜 Sprint Backlog | Tareas del sprint actual | Sin límite |
| 🚧 En Progreso | Trabajo activo | 2 (TINV), 1 (otros) |
| 👀 En Revisión | Esperando revisión/aprobación | Sin límite |
| ✅ Completado | Tareas terminadas | Sin límite |

### Paso 4 — Agregar campos personalizados

En GitHub Projects, agregar estos campos:

| Campo | Tipo | Valores |
|---|---|---|
| Sprint | Number | 1-20 |
| Responsable | Text | DP, INV1, INV2, TINV, AI |
| Tamaño | Single select | S, M, L, XL |
| PT | Single select | PT0, PT1, PT2, PT3, PT4, Difusión |

### Paso 5 — Cargar tareas del backlog

Crear un Issue de GitHub para cada tarea del backlog.  
Usar el ID de tarea como parte del título: `[T-1.1.1] Solicitar datos a CENTROSUR`.

Asignar cada Issue a:
- Responsable: usando la función de Assignee
- Sprint: campo personalizado
- Columna: según estado actual

### Paso 6 — Gestión semanal

Cada jueves (16:00) en la sincronía semanal:
1. Abrir el tablero GitHub Projects.
2. Mover tarjetas según avance real.
3. Actualizar este archivo `kanban.md` con el estado del sprint.
4. Registrar bloqueos como comentarios en los Issues correspondientes.

### Vista de Sprint

En GitHub Projects, crear una vista tipo **Roadmap** con:
- Agrupación por: Sprint
- Filtro: solo sprint activo
- Ordenar por: Responsable

---

## Política de actualización

Este archivo `kanban.md` se actualiza:
- **Semanalmente** (jueves 16:00, TINV): mover tareas entre columnas.
- **Al inicio de cada sprint** (1er jueves, TINV): agregar tareas del sprint.
- **Al final de cada sprint** (último día del sprint, DP): cerrar sprint y archivar completados.
