# =============================================================================
# percepcion_seguridad.R — Encuesta de percepción ciudadana 2018-2025
#
# INPUTS:
#   01_Data/00_Inputs/Data anonimizada encuesta percepcion 2018-2025.xlsx
#     (hoja "Data_033200250000 Perc2018-2025"; doble encabezado, los nombres
#      cortos están en la fila 2; ~105 MB y 1.363 columnas; NO versionado)
# OUTPUTS:
#   01_Data/01_Derived/percepcion_seguridad.dta
#   01_Data/01_Derived/percepcion_seguridad.xlsx   (respaldo legible)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/percepcion_seguridad.do
#
# El insumo no cabe en el repositorio (ver .gitignore y el README de 00_Inputs).
# Si falta, este script se detiene con un mensaje claro y el resto del pipeline
# sigue: la sección 10 trabaja con el derivado ya generado.
#
# POR QUÉ EXISTE ESTE DERIVADO
#   El microdato crudo pesa ~105 MB y tiene 1.363 columnas; leerlo en cada
#   corrida sería inviable. Aquí se reduce UNA vez a las ocho columnas que usa
#   el flujo y 03_tablas/10_seguridad.R lee el resultado.
#
#   NO se preagrega: se conserva el microdato por entrevista y de TODAS las
#   subregiones, porque el periodo y las proporciones ponderadas se calculan en
#   el flujo después de filtrar la subregión de cada provincia.
#
# FECHAINI se guarda como texto "DD/MM/AAAA" porque así lo espera el lector
# (10_seguridad.R hace as.Date(..., format = "%d/%m/%Y")). No la convierta a
# fecha aquí sin actualizar ese script.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== percepción de seguridad ==")

ARCHIVO_ENCUESTA <- "Data anonimizada encuesta percepcion 2018-2025.xlsx"
HOJA_ENCUESTA    <- "Data_033200250000 Perc2018-2025"

# Columna del derivado -> etiqueta que llevaba en el .do.
ETIQUETAS <- c(
  ESTUDIO            = "Codigo del estudio",
  FECHAINI           = "Fecha inicio entrevista (DMY)",
  B_SUBREGION        = "Subregion (1-9)",
  P1A                = "P1A percepcion barrio/vereda",
  P2                 = "P2 cambio barrio/vereda",
  P4A                = "P4A percepcion municipio",
  P6                 = "P6 cambio municipio",
  FACTOR_PONDERACION = "Factor de ponderacion"
)

# Se convierten a número (el .do: `destring ..., replace force`).
NUMERICAS <- c("B_SUBREGION", "FACTOR_PONDERACION", "P1A", "P2", "P4A", "P6")

# --- Lectura ------------------------------------------------------------------
ruta <- entrada(ARCHIVO_ENCUESTA)   # aborta con mensaje si no está

# `cellrange(A2) firstrow` del .do = nombres cortos en la fila 2 -> saltar 1.
message("  leyendo el microdato crudo (~105 MB, puede tardar varios minutos)")
crudo <- leer_excel(ruta, hoja = HOJA_ENCUESTA, saltar = 1)

if (nrow(crudo) == 0) {
  stop("La hoja '", HOJA_ENCUESTA, "' de ", basename(ruta), " llegó vacía. ",
       "Verifique que el encabezado corto siga en la fila 2.", call. = FALSE)
}

# --- Selección y tipos --------------------------------------------------------
columnas <- lapply(names(ETIQUETAS), function(nombre) {
  valores <- crudo[[col_req(crudo, nombre)]]
  x <- if (nombre %in% NUMERICAS) {
    a_numero(valores)
  } else if (inherits(valores, c("Date", "POSIXct"))) {
    # Si Excel guardó la fecha como fecha, se devuelve al formato DMY de texto
    # que espera el flujo.
    format(valores, "%d/%m/%Y")
  } else {
    as.character(valores)
  }
  attr(x, "label") <- unname(ETIQUETAS[[nombre]])
  x
})
names(columnas) <- names(ETIQUETAS)
encuesta <- as.data.frame(columnas, stringsAsFactors = FALSE)

# --- Guardar ------------------------------------------------------------------

unlink(archivo_xlsx)

escribir_derivado(encuesta, "percepcion_seguridad")

message("  percepcion_seguridad: ", nrow(encuesta), " entrevistas, ",
        dplyr::n_distinct(encuesta$B_SUBREGION), " subregiones")
