# =============================================================================
# 00_config.R — Configuración del pipeline (rutas, provincias, dependencias)
#
# ÚNICO archivo del proyecto con lógica de rutas y con la tabla de provincias.
# Ningún otro script define rutas absolutas ni repite los nombres de provincia.
#
# USO:  source("02_Code/R/00_config.R")   desde cualquier directorio de trabajo
#       (la raíz se detecta sola; también se puede fijar con la variable de
#       entorno PROVINCIAS_ROOT)
#
# ETAPA DEL PIPELINE: infraestructura (lo cargan todos los scripts)
# =============================================================================

# --- 1. Raíz del proyecto -----------------------------------------------------
# Prioridad: PROVINCIAS_ROOT > subir desde la ubicación del script > subir desde
# el directorio de trabajo. Una carpeta es la raíz si contiene 01_Data y 03_Outputs.

.es_raiz <- function(d) {
  dir.exists(file.path(d, "01_Data")) && dir.exists(file.path(d, "03_Outputs"))
}

.subir_hasta_raiz <- function(inicio) {
  d <- normalizePath(inicio, mustWork = FALSE)
  for (i in 1:25) {
    if (.es_raiz(d)) return(d)
    padre <- dirname(d)
    if (padre == d) break
    d <- padre
  }
  NA_character_
}

.dir_de_este_script <- function() {
  # Rscript
  args <- commandArgs(trailingOnly = FALSE)
  archivo <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(archivo)) return(dirname(normalizePath(archivo[1], mustWork = FALSE)))
  # source() en una sesión interactiva
  for (i in seq_len(sys.nframe())) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(dirname(normalizePath(of, mustWork = FALSE)))
  }
  NA_character_
}

PROJ_ROOT <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
if (!nzchar(PROJ_ROOT)) {
  desde_script <- .dir_de_este_script()
  PROJ_ROOT <- if (!is.na(desde_script)) .subir_hasta_raiz(desde_script) else NA_character_
  if (is.na(PROJ_ROOT)) PROJ_ROOT <- .subir_hasta_raiz(getwd())
}
if (is.na(PROJ_ROOT) || !nzchar(PROJ_ROOT) || !.es_raiz(PROJ_ROOT)) {
  stop(
    "No se encontró la raíz del proyecto (la carpeta que contiene 01_Data y 03_Outputs).\n",
    "  Directorio de trabajo actual: ", getwd(), "\n",
    "  Soluciones:\n",
    "    (a) abra R con el directorio de trabajo en la raíz del repositorio, o\n",
    "    (b) defina la variable de entorno PROVINCIAS_ROOT con la ruta del repositorio.",
    call. = FALSE
  )
}

# --- 2. Rutas -----------------------------------------------------------------
RUTAS <- list(
  raiz       = PROJ_ROOT,
  documentos = file.path(PROJ_ROOT, "00_Documentos"),
  inputs     = file.path(PROJ_ROOT, "01_Data", "00_Inputs"),    # crudos: NUNCA escribir aquí
  derived    = file.path(PROJ_ROOT, "01_Data", "01_Derived"),   # derivados del pipeline
  codigo     = file.path(PROJ_ROOT, "02_Code"),
  outputs    = file.path(PROJ_ROOT, "03_Outputs"),
  referencia = file.path(PROJ_ROOT, "tests", "referencia")
)

#' Rutas de insumo y de salida. `entrada()` falla con un mensaje útil si el
#' archivo no está (varias fuentes no caben en el repositorio: ver README).
entrada <- function(..., obligatorio = TRUE) {
  p <- file.path(RUTAS$inputs, ...)
  if (obligatorio && !file.exists(p)) {
    stop("Falta el insumo:\n  ", p, "\n",
         "Si es una de las fuentes grandes no versionadas, pídala al equipo ",
         "(ver la sección 'Fuentes ausentes del clon' en el README).", call. = FALSE)
  }
  p
}
derivado <- function(...) file.path(RUTAS$derived, ...)
salida   <- function(...) file.path(RUTAS$outputs, ...)

# --- 3. Provincias ------------------------------------------------------------
# Fuente única de verdad. `nombre_datos` es la cadena tal como aparece en la
# columna `prov` de los archivos de datos y debe coincidir byte a byte.
#
# OJO (id 5): en los datos dice "POVINCIA DEL AGUA..." — falta la R. El error
# está igual en los datos y en el código Stata original, así que el emparejamiento
# funciona. NO corregir aquí sin corregir también los archivos de datos.

PROVINCIAS <- data.frame(
  id = 1:11,
  nombre_datos = c(
    "PROVINCIA AGROINDUSTRIAL DEL OCCIDENTE",
    "PROVINCIA BIOENERGETICA DEL NORTE DE ANTIOQUIA",
    "PROVINCIA DEL RIO GRANDE",
    "PROVINCIA TURISTICA Y AGROECOLOGICA",
    "POVINCIA DEL AGUA, BOSQUES Y TURISMO",   # sic: el typo está en los datos
    "PROVINCIA CARTAMA",
    "PROVINCIA DE LA PAZ",
    "PROVINCIA DE SAN JUAN",
    "PROVINCIA MINERO AGROECOLOGICA",
    "PROVINCIA PENDERISCO Y SINIFANA",
    "AREA METROPOLITANA"
  ),
  carpeta = c(
    "Agroindustrial_Occidente", "Bioenergetica_Norte", "Rio_Grande",
    "Turistica_Agroecologica", "Agua_Bosques_Turismo", "Cartama",
    "De_la_Paz", "San_Juan", "Minero_Agroecologica",
    "Penderisco_Sinifana", "Area_Metropolitana"
  ),
  etiqueta = c(
    "Agroindustrial del Occidente", "Bioenergética del Norte de Antioquia",
    "Del Río Grande", "Turística y Agroecológica", "Agua, Bosques y Turismo",
    "Cartama", "De la Paz", "San Juan", "Minero Agroecológica",
    "Penderisco y Sinifana", "Área Metropolitana"
  ),
  stringsAsFactors = FALSE
)

#' Datos de una provincia por id. Sin argumento toma ID_PROVINCIA del entorno,
#' o el objeto `id_provincia` si el script lo definió, o 2 (la provincia con
#' informe publicado, que es la que se puede validar contra el Anexo 1).
provincia <- function(id = NULL) {
  if (is.null(id)) {
    env <- Sys.getenv("ID_PROVINCIA", unset = "")
    id <- if (nzchar(env)) as.integer(env)
          else if (exists("id_provincia", envir = globalenv())) get("id_provincia", envir = globalenv())
          else 2L
  }
  id <- as.integer(id)
  if (!id %in% PROVINCIAS$id) {
    stop("id_provincia debe estar entre 1 y 11; se recibió: ", id, call. = FALSE)
  }
  as.list(PROVINCIAS[PROVINCIAS$id == id, ])
}

#' Carpeta de salida de una sección para una provincia; la crea si no existe.
dir_seccion <- function(prov, seccion) {
  d <- file.path(RUTAS$outputs, prov$carpeta, seccion)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}
dir_figuras <- function(prov, seccion) {
  d <- file.path(dir_seccion(prov, seccion), "figuras")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

# --- 4. Dependencias ----------------------------------------------------------
PAQUETES <- c(
  "dplyr", "tidyr", "purrr", "stringr", "stringi", "rlang",  # manipulación
  "readxl", "openxlsx2", "haven", "arrow",                   # entrada/salida
  "ggplot2", "scales", "ragg", "systemfonts"                 # figuras
)

# Los mapas no son obligatorios: sin estos dos paquetes el pipeline genera todas
# las tablas y todas las figuras no cartográficas, y omite los mapas con un
# aviso. Se declaran aparte para que un clon sin `sf` —que necesita GDAL, GEOS y
# PROJ en el sistema— no quede bloqueado.
PAQUETES_MAPAS <- c("sf", "ggrepel")

cargar_paquetes <- function(paquetes = PAQUETES) {
  faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltantes)) {
    stop("Faltan paquetes: ", paste(faltantes, collapse = ", "), "\n",
         "  Instálelos con: renv::restore()   (o install.packages(c(\"",
         paste(faltantes, collapse = "\", \""), "\")))", call. = FALSE)
  }
  invisible(lapply(paquetes, function(p) suppressPackageStartupMessages(
    library(p, character.only = TRUE)
  )))
}

# --- 5. Carga del resto de la infraestructura ---------------------------------
cargar_paquetes()
source(file.path(RUTAS$codigo, "R", "01_utils.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "R", "02_tema.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "R", "03_mapas.R"), encoding = "UTF-8")

message("[config] Raíz del proyecto: ", RUTAS$raiz)
