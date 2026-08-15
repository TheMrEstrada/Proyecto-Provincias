# =============================================================================
# run_provincia.R — Genera tablas y figuras de UNA provincia
#
# USO:
#   ID_PROVINCIA=2 Rscript 02_Code/run_provincia.R          # una provincia
#   Rscript 02_Code/run_provincia.R 2                       # equivalente
#   ID_PROVINCIA=2 SECCIONES=01,02 Rscript 02_Code/run_provincia.R  # parcial
#
# En RStudio:
#   Sys.setenv(ID_PROVINCIA = "2"); source("02_Code/run_provincia.R")
#
# SALIDA: 03_Outputs/<Provincia>/<NN_Seccion>/{tabla}.xlsx + figuras/*.{png,pdf}
#
# Requiere que los derivados estén construidos (Rscript 02_Code/run_all.R los
# construye antes de recorrer las provincias).
# =============================================================================

# La configuración puede venir ya cargada (p. ej. si otro script hizo source de
# este); en ese caso no se vuelve a resolver la raíz.
if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(normalizePath(.f[1]))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}

# --- Registro de secciones ----------------------------------------------------
# Cada entrada dice qué script produce la tabla y cuál las figuras. Añadir una
# sección es añadir una fila; el orquestador no necesita más cambios.
SECCIONES <- list(
  list(id = "01", carpeta = "01_Generalidades",   fun_tabla = "tabla_generalidades",    fun_figuras = "figuras_generalidades"),
  list(id = "02", carpeta = "02_Demografia",      fun_tabla = "tabla_demografia",       fun_figuras = "figuras_demografia"),
  list(id = "03", carpeta = "03_Ordenamiento",    fun_tabla = "tabla_ordenamiento",     fun_figuras = "figuras_ordenamiento"),
  list(id = "04", carpeta = "04_Gobernabilidad",  fun_tabla = "tabla_gobernabilidad",   fun_figuras = "figuras_gobernabilidad"),
  list(id = "05", carpeta = "05_Economia",        fun_tabla = "tabla_economia",         fun_figuras = "figuras_economia"),
  list(id = "06", carpeta = "06_Desarrollo_Rural", fun_tabla = "tabla_desarrollo_rural", fun_figuras = "figuras_desarrollo_rural"),
  list(id = "07", carpeta = "07_Ambiental",       fun_tabla = "tabla_ambiental",        fun_figuras = "figuras_ambiental"),
  list(id = "08", carpeta = "08_Educacion",       fun_tabla = "tabla_educacion",        fun_figuras = "figuras_educacion"),
  list(id = "09", carpeta = "09_Salud",           fun_tabla = "tabla_salud",            fun_figuras = "figuras_salud"),
  list(id = "10", carpeta = "10_Seguridad",       fun_tabla = "tabla_seguridad",        fun_figuras = "figuras_seguridad")
)

#' Nombre del script de una sección (tablas o figuras), o NA si aún no existe.
.script_seccion <- function(etapa, seccion) {
  base <- tolower(sub("^\\d+_", "", seccion$carpeta))
  ruta <- file.path(RUTAS$codigo, etapa, paste0(seccion$id, "_", base, ".R"))
  if (file.exists(ruta)) ruta else NA_character_
}

#' Ejecuta una sección completa: tabla y luego figuras.
correr_seccion <- function(seccion, prov) {
  s_tabla <- .script_seccion("03_tablas", seccion)
  if (is.na(s_tabla)) {
    return(list(estado = "PENDIENTE", detalle = "sin migrar todavía"))
  }
  source(s_tabla, encoding = "UTF-8")
  tabla <- tryCatch(
    do.call(seccion$fun_tabla, list(prov = prov)),
    error = function(e) e
  )
  if (inherits(tabla, "error")) {
    return(list(estado = "ERROR", detalle = conditionMessage(tabla)))
  }

  s_fig <- .script_seccion("04_figuras", seccion)
  if (is.na(s_fig)) {
    return(list(estado = "TABLA OK", detalle = "figuras sin migrar"))
  }
  source(s_fig, encoding = "UTF-8")
  fig <- tryCatch(
    do.call(seccion$fun_figuras, list(prov = prov, tabla = tabla)),
    error = function(e) e
  )
  if (inherits(fig, "error")) {
    return(list(estado = "TABLA OK", detalle = paste("fallaron las figuras:",
                                                     conditionMessage(fig))))
  }
  list(estado = "OK", detalle = "")
}

#' Genera todas las secciones de una provincia y devuelve el resumen.
correr_provincia <- function(id = NULL, secciones = NULL) {
  prov <- provincia(id)
  pedidas <- secciones %||% strsplit(Sys.getenv("SECCIONES", unset = ""), ",")[[1]]
  lista <- if (length(pedidas) && any(nzchar(pedidas))) {
    Filter(function(s) s$id %in% trimws(pedidas), SECCIONES)
  } else {
    SECCIONES
  }

  message("\n=========================================================")
  message("  Provincia ", prov$id, ": ", prov$etiqueta)
  message("  Salida: 03_Outputs/", prov$carpeta, "/")
  message("=========================================================")

  resumen <- lapply(lista, function(s) {
    r <- correr_seccion(s, prov)
    c(seccion = s$carpeta, estado = r$estado, detalle = r$detalle)
  })
  resumen <- as.data.frame(do.call(rbind, resumen), stringsAsFactors = FALSE)

  # --- Mapas ------------------------------------------------------------------
  # Van al final y aparte de las secciones: cada mapa lee la tabla .xlsx que la
  # sección acaba de escribir, así que necesita que todas hayan corrido. Solo
  # se generan si se pidió la provincia completa.
  if (identical(lista, SECCIONES)) {
    source(file.path(RUTAS$codigo, "04_figuras", "00_mapas.R"), encoding = "UTF-8")
    r_mapas <- tryCatch(mapas_provincia(prov), error = function(e) e)
    resumen <- rbind(resumen, data.frame(
      seccion = "Mapas",
      estado  = if (inherits(r_mapas, "error")) "ERROR"
                else if (is.null(r_mapas)) "OMITIDO" else "OK",
      detalle = if (inherits(r_mapas, "error")) conditionMessage(r_mapas)
                else if (is.null(r_mapas)) "falta el paquete sf"
                else paste(length(r_mapas), "mapas"),
      stringsAsFactors = FALSE
    ))
  }

  message("\n--- Resumen ", prov$etiqueta, " ---")
  for (i in seq_len(nrow(resumen))) {
    message(sprintf("  %-22s %-10s %s", resumen$seccion[i], resumen$estado[i],
                    resumen$detalle[i]))
  }
  invisible(resumen)
}

# --- Ejecución directa --------------------------------------------------------
# Solo cuando este es el script invocado. Otros scripts hacen source de este
# archivo para reutilizar SECCIONES y correr_provincia(); en ese caso no debe
# generar nada por su cuenta.
.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "run_provincia.R") {
  .cli <- commandArgs(trailingOnly = TRUE)
  correr_provincia(if (length(.cli)) as.integer(.cli[1]) else NULL)
}
