# Guía de publicación del sitio web — ReNoN-Azuay

El sitio web del proyecto se publica usando **GitHub Pages**: es gratuito, se gestiona con Git (que ya usaremos para el código y datos), y permite tener una URL como `https://renon-azuay.github.io`.

---

## Publicación inicial (hacerlo una sola vez)

### Paso 1 — Crear el repositorio en GitHub

1. Ir a [github.com](https://github.com) e iniciar sesión.
2. Clic en **New repository**.
3. Configurar:
   - **Repository name:** `renon-azuay`
   - **Visibility:** Public (necesario para GitHub Pages gratis)
   - **Initialize:** con README
4. Clic en **Create repository**.

### Paso 2 — Subir los archivos del sitio web

Opción A — desde la terminal (recomendado si tienen Git instalado):

```bash
# Clonar el repositorio vacío
git clone https://github.com/[usuario]/renon-azuay.git
cd renon-azuay

# Copiar la carpeta web/ de este proyecto al repositorio
cp -r /ruta/a/gestion/web/* .

# Confirmar y subir
git add .
git commit -m "Publicar sitio web inicial del proyecto ReNoN-Azuay"
git push origin main
```

Opción B — desde el navegador:
1. En el repositorio de GitHub, clic en **Add file → Upload files**.
2. Arrastrar todos los archivos de la carpeta `gestion/web/`.
3. Clic en **Commit changes**.

### Paso 3 — Activar GitHub Pages

1. Ir al repositorio en GitHub → **Settings**.
2. En el menú izquierdo: **Pages**.
3. En **Source**: seleccionar `Deploy from a branch`.
4. **Branch**: `main` | **Folder**: `/ (root)`.
5. Clic en **Save**.

Esperar ~2 minutos. El sitio estará disponible en:
```
https://[usuario].github.io/renon-azuay/
```

> **URL alternativa:** Si se crea una organización en GitHub llamada `renon-azuay` y el repositorio se llama `renon-azuay.github.io`, la URL será simplemente `https://renon-azuay.github.io` (sin subcarpeta). Esta es la opción más limpia.

---

## Publicar un nuevo reporte (hacer cada vez)

### Estructura de archivos del sitio

```
renon-azuay/  (repositorio GitHub)
├── index.html               ← página principal
├── assets/
│   ├── style.css
│   └── img/                 ← imágenes de los reportes
├── posts/
│   ├── template_reporte.html
│   ├── reporte-01-energia-azuay.html    ← ejemplo
│   └── reporte-02-vehiculos-electricos.html
```

### Proceso para publicar un nuevo reporte

**Responsable:** TINV (Brian Loza) con apoyo del AI (Pablo Cárdenas)

1. **Copiar la plantilla:**
   ```bash
   cp posts/template_reporte.html posts/reporte-0N-nombre-descriptivo.html
   ```
   Nombrar el archivo con el formato: `reporte-0N-tema.html` (ej: `reporte-01-energia-azuay.html`)

2. **Editar el contenido:**  
   Abrir el archivo HTML en cualquier editor de texto y editar las secciones marcadas con `<!-- EDITAR: ... -->`:
   - Título (`<title>` y `<h1 class="post-title">`)
   - Fecha, etiqueta de PT, autores
   - Cuerpo del reporte (secciones 1-5)
   - Enlace a PDF si hay versión descargable

3. **Agregar imágenes** (si las hay):
   - Guardar las imágenes en `assets/img/`
   - Referenciarlas en el HTML como `<img src="../assets/img/nombre.png" alt="...">`

4. **Agregar el PDF** (si aplica):
   - Guardar en `assets/reportes/reporte-0N-nombre.pdf`
   - Descomentar el botón de descarga en el HTML

5. **Agregar la tarjeta en `index.html`:**  
   Abrir `index.html` y buscar `<!-- INICIO ZONA DE REPORTES -->`.  
   Copiar y pegar este bloque (editar con el título real):
   ```html
   <div class="blog-card">
     <div class="blog-card-header">
       <span class="blog-tag">PT1 · Datos</span>
       <h3>Título del reporte aquí</h3>
     </div>
     <p>Descripción breve del contenido (2-3 oraciones).</p>
     <div class="blog-card-footer">
       <span>📅 Sep 2026</span>
       <a href="posts/reporte-01-energia-azuay.html">Leer →</a>
     </div>
   </div>
   ```

6. **Subir a GitHub:**
   ```bash
   git add posts/reporte-0N-nombre.html assets/img/ index.html
   git commit -m "Publicar Reporte 0N: Título del reporte"
   git push origin main
   ```
   El sitio se actualiza automáticamente en ~2 minutos.

---

## Gestión de datos abiertos en GitHub

Los datos del proyecto (base de datos energética, código del EMS) también van en el repositorio:

```
renon-azuay/
├── data/
│   ├── README.md           ← descripción de las variables
│   ├── energia_azuay_2003-2024.csv
│   └── ev_azuay_2015-2024.csv
├── code/
│   ├── README.md
│   ├── ems/                ← código del EMS
│   └── notebooks/          ← Jupyter notebooks reproducibles
└── [sitio web]
```

### Publicar la base de datos (Producto 3)

1. Subir el CSV a la carpeta `data/` del repositorio.
2. Escribir un `data/README.md` con: descripción de variables, unidades, fuentes, licencia (CC BY 4.0).
3. **Asignar DOI** con Zenodo (para que sea citable en artículos):
   - Ir a [zenodo.org](https://zenodo.org) → iniciar sesión con GitHub.
   - Activar el repositorio `renon-azuay` en Zenodo.
   - Crear un Release en GitHub (e.g., `v1.0-datos-pt1`).
   - Zenodo genera automáticamente el DOI.

### Publicar el código EMS (Producto 4)

1. Subir el código Python a `code/ems/`.
2. Incluir `README.md` con instrucciones de instalación y uso.
3. Agregar `requirements.txt` con dependencias.
4. Crear un notebook de ejemplo en `code/notebooks/`.
5. Activar en Zenodo como se describe arriba.

---

## Alternativas a GitHub Pages

Si por alguna razón GitHub Pages no está disponible:

| Alternativa | Costo | Facilidad | URL de ejemplo |
|---|---|---|---|
| **Netlify** | Gratis | Muy fácil (drag & drop) | `renon-azuay.netlify.app` |
| **Vercel** | Gratis | Requiere cuenta | `renon-azuay.vercel.app` |
| **UCuenca** | Sin costo (solicitar a DTI) | Coordinación institucional | `deet.ucuenca.edu.ec/renon` |

Para Netlify (más fácil para no-técnicos):
1. Ir a [netlify.com](https://netlify.com) → Sign up.
2. Arrastrar la carpeta `gestion/web/` completa al área de deploy.
3. El sitio queda publicado instantáneamente.

---

## Resumen de responsabilidades web

| Tarea | Responsable | Frecuencia |
|---|---|---|
| Publicar nuevos reportes | TINV + AI | Según entregables |
| Actualizar % de progreso en PT cards | TINV | Mensual (al cerrar sprint) |
| Publicar nuevas publicaciones | DP | Al ser aceptadas |
| Mantenimiento general del sitio | TINV | Según necesidad |
| Gestión del repositorio GitHub | TINV | Continua |
