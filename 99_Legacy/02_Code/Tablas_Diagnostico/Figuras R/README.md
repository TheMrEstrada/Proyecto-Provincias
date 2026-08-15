# Pipeline de figuras (R) — Diagnóstico territorial "Provincias de Antioquia"

Genera, de forma reproducible y parametrizada por provincia (`id_provincia` 1–11),
las figuras del diagnóstico **dentro de los mismos `.xlsx`** que exporta el flujo Stata.

## Requisitos
- R >= 4.4 (recomendado). Las dependencias se instalan **automáticamente** la primera
  vez desde CRAN (`R/00_setup.R`): `openxlsx2` (>= 1.28) y `encharter` (>= 0.10).
  No hay que instalar nada a mano.

## Portabilidad (funciona en cualquier clon del repo)
- **La raíz del proyecto se detecta sola**: el script sube desde su ubicación hasta la
  carpeta que contiene `03_Outputs`. No hay que configurar rutas absolutas; funciona
  en Windows, Mac o Linux, sin importar dónde se haya clonado el repo.
  (Escape opcional: definir la variable de entorno `PROVINCIAS_ROOT`.)
- **Se corre desde cualquier carpeta**: el orquestador localiza sus propios archivos
  `R/` por su ubicación, no por el directorio de trabajo.
- Prerrequisito: el código debe vivir **dentro del repo** (p. ej. en `02_Code/…`),
  aguas arriba de `03_Outputs`.

## Elegir la provincia
Se elige **en `run_provincia.R`**, en la línea marcada arriba del archivo:
```r
id_provincia <- 4     # <-- cambia este número (1..11) y corre este archivo
```
No hay que abrir ningún otro script. (Opcional, para automatizar sin editar: definir
la variable de entorno `ID_PROVINCIA`, que tiene prioridad si existe.)

Debe existir el export de Stata de esa provincia; si no, el script se detiene con un
mensaje claro pidiendo correr primero el flujo de Stata para esa provincia.

## Orden de ejecución (importante)
Los sectoriales de Stata hacen `capture erase` del `.xlsx` antes de escribir:
1. Correr **primero el flujo Stata** (produce los `.xlsx` de datos por sección).
2. Correr **después R** (abre esos `.xlsx`, inserta las figuras y guarda).
   Si se vuelve a correr Stata, se regeneran los `.xlsx` sin figuras → volver a correr R.

## Uso
Terminal (elige provincia con ID_PROVINCIA):
```bash
ID_PROVINCIA=4 Rscript run_provincia.R
```
RStudio:
```r
Sys.setenv(ID_PROVINCIA = "4")   # 1..11
source("run_provincia.R")
```

## Estructura
- `R/00_setup.R`           Instala/carga dependencias (R fresco).
- `R/00_config.R`          Provincia + raíz autodetectada.
- `R/01_tema.R`            Plantilla de estilo (paleta, tipografía).
- `R/02_utils.R`           Helpers: `enc_hbar` (simple/apilada/agrupada), `enc_piramide`,
                           `enc_line`, `enc_pie`, `enc_scatter`, `enc_dumbbell`, `estilo_tabla`, lectura.
- `R/fig/NN_<seccion>.R`   Un módulo por sección (01..10) con sus figuras y tablas.
- `run_provincia.R`        Orquestador por provincia.

> Las figuras se escriben en el mismo archivo de la sección. Las hojas auxiliares
> ocultas `_fig_*` contienen los datos exactos que alimentan cada gráfico.
