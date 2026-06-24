# Guía de actualización del sitio web ReNoN-Azuay

**Archivo a editar:** `gestion/web/index.html`  
**Frecuencia recomendada:** Al cierre de cada sprint (último viernes del mes)  
**Responsable:** TINV (Brian Loza)

---

## 1. Actualizar el progreso de los paquetes de trabajo (barras PT)

Cada PT tiene dos líneas que deben actualizarse juntas:

```html
<div class="progress-fill" style="width:5%; background:var(--uc-blue);"></div>
<div class="progress-label">En inicio · Sprint 1 activo</div>
```

**Cambie el porcentaje** en `width:X%` según el avance real estimado por el DP.  
**Cambie la etiqueta** por una descripción breve del estado actual.

| PT | Color CSS | Ejemplos de etiqueta |
|---|---|---|
| PT 1 | `var(--uc-blue)` | `En inicio · Sprint 1 activo` → `45 % completado` → `Completado ✓` |
| PT 2 | `var(--uc-blue-mid)` | `0 % completado` → `En progreso · Sprint 4` |
| PT 3 | `var(--green-mid)` | `0 % completado` → `Simulaciones en curso` |
| PT 4 | `var(--green)` | `0 % completado` → `En validación` |

---

## 2. Cambiar de sprint (inicio de cada mes)

Al arrancar un nuevo sprint, actualice el **banner** de la sección `#planificacion`:

```html
<span class="sprint-badge">🟡 Sprint 1 · Activo</span>
<span class="sprint-period">2 – 31 julio 2026</span>
<span class="sprint-objective">Arranque científico: ...</span>
```

- Cambie el número (`Sprint 1` → `Sprint 2`, etc.)
- Actualice el período (ejemplo: `1 – 31 agosto 2026`)
- Actualice el objetivo del sprint con la meta acordada en el Sprint Planning

**Colores del badge según estado:**

| Estado | Clase/emoji |
|---|---|
| Activo | `🟡 Sprint N · Activo` |
| Completado | `🟢 Sprint N · Completado` |

---

## 3. Actualizar las fechas clave del sprint

Las cuatro tarjetas de fechas se encuentran dentro de `.dates-grid`:

```html
<div class="date-card">
  <div class="date-icon">📋</div>
  <div class="date-label">Sprint Planning</div>
  <div class="date-value">Jue 2 jul · 16:00</div>   ← cambiar aquí
</div>
```

Actualice `date-value` con las fechas del sprint en curso. El Workshop es la tarjeta con clase `highlight`:

```html
<div class="date-card highlight">  ← esta es la tarjeta destacada (verde)
```

Si en un sprint no hay workshop, quite la clase `highlight` de esa tarjeta y póngala en la que tenga el evento más relevante.

---

## 4. Marcar tareas como completadas / agregar nuevas

Cada fila de tarea tiene un indicador de estado al final:

```html
<span class="task-status status-pending">Pendiente</span>   ← pendiente
<span class="task-status status-done">Completado</span>     ← hecho
```

Cambie la clase CSS y el texto para reflejar el avance.

**Para agregar una tarea nueva**, copie y pegue este bloque dentro de `.sprint-tasks` (antes del `</div>` de cierre):

```html
<div class="task-row">
  <span class="task-id">T-X.X</span>
  <span class="task-name">Descripción de la tarea</span>
  <span class="task-owner">RESPONSABLE</span>
  <span class="task-status status-pending">Pendiente</span>
</div>
```

**Para limpiar la tabla al inicio de un nuevo sprint**, reemplace todas las filas con las tareas del sprint nuevo (obténgalas de `gestion/sprints/sprint_0N_mes2026.md`).

---

## 5. Publicar un reporte técnico

Cuando un reporte esté disponible, busque la zona marcada en `#reportes`:

```html
<!-- INICIO ZONA DE REPORTES — agregar nuevas tarjetas aquí -->
<!-- <div class="blog-card">...</div> -->
<!-- FIN ZONA DE REPORTES -->
```

Descomente o agregue una tarjeta con esta estructura:

```html
<div class="blog-card">
  <div class="blog-card-header">
    <span class="blog-tag">PT1 · Datos</span>
    <h3>Título del reporte</h3>
  </div>
  <p>Resumen breve de una o dos oraciones.</p>
  <div class="blog-card-footer">
    <span>📅 Sep 2026</span>
    <a href="posts/nombre-del-reporte.html">Leer →</a>
  </div>
</div>
```

Elimine o comente el bloque `.blog-empty` cuando haya al menos un reporte publicado.

Para crear el HTML del reporte, use la plantilla en `posts/template_reporte.html` y siga la guía de publicación en `GUIA_PUBLICACION.md`.

---

## 6. Registrar una publicación científica

En la sección `#publicaciones`, cada artículo es un `.pub-item`. Cuando un artículo sea enviado o aceptado, actualice la línea `pub-meta`:

```html
<!-- Antes (planificado): -->
<div class="pub-meta">📅 Envío previsto: agosto 2027 · Revista objetivo: Applied Energy</div>

<!-- Después (enviado): -->
<div class="pub-meta">📤 Enviado: 15 ago 2027 · Applied Energy · En revisión</div>

<!-- Después (aceptado): -->
<div class="pub-meta">✅ Aceptado: oct 2027 · Applied Energy · DOI: 10.xxxx/xxxxx</div>
```

---

## 7. Checklist de cierre de sprint

Al final de cada sprint (viernes de Sprint Review), TINV ejecuta estos pasos en orden:

- [ ] Actualizar porcentajes de progreso de PT activos
- [ ] Marcar tareas completadas en la tabla (`status-done`)
- [ ] Preparar tabla de tareas del sprint siguiente
- [ ] Actualizar banner con número y fechas del nuevo sprint
- [ ] Actualizar las cuatro tarjetas de fechas clave
- [ ] Agregar reporte si fue publicado este sprint
- [ ] Hacer commit y push al repositorio GitHub (activa publicación automática en Pages)

```bash
git add web/index.html
git commit -m "web: actualizar tablero Sprint N — [mes año]"
git push
```
