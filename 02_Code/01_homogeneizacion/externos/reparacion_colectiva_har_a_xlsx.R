# =============================================================================
# reparacion_colectiva_har_a_xlsx.R — Reconstruye el insumo UARIV desde un .har
#
# El pipeline NO corre este script (ver README.md de esta carpeta). Se
# conserva solo como documentación de cómo se construyó
# 01_Data/00_Inputs/UARIV_sujetos_reparacion_colectiva.xlsx, que sí es un
# insumo real que sí lee el pipeline (02_Code/01_homogeneizacion/
# reparacion_colectiva.R).
#
# EL PROBLEMA: la UARIV no publica un dataset abierto de Sujetos de
# Reparación Colectiva (ni API, ni CSV descargable) — solo un visor de mapas
# en vgv.unidadvictimas.gov.co/sujetos/ (ArcGIS). Ese visor SÍ permite
# exportar la tabla de atributos desde el navegador, pero es una acción
# manual, no un insumo versionable ni repetible por el pipeline.
#
# LA SOLUCIÓN: capturar la sesión del navegador como .har (HTTP Archive) al
# cargar el visor sin ningún filtro (where=1=1, outFields=*): eso incluye,
# sin que el usuario lo sepa, las dos respuestas JSON crudas de la API
# ArcGIS REST con los 1.034 sujetos de reparación colectiva del país. Este
# script las extrae del .har y arma el .xlsx que sí queda en el repositorio.
#
# INPUT:  01_Data/00_Inputs/vgv.unidadvictimas.gov.co.har
#           (captura de red del navegador; NO es un insumo del pipeline, se
#           conserva junto al .xlsx que produjo por si hay que repetir el
#           proceso con una captura más reciente)
# OUTPUT: 01_Data/00_Inputs/UARIV_sujetos_reparacion_colectiva.xlsx
#           (1.034 sujetos, nivel nacional; el filtro a Antioquia lo hace
#           02_Code/01_homogeneizacion/reparacion_colectiva.R, no este script)
# =============================================================================

library(jsonlite)
library(openxlsx)
`%||%` <- function(a, b) if (is.null(a)) b else a

har <- fromJSON("01_Data/00_Inputs/Actualización/Fuentes/vgv.unidadvictimas.gov.co.har",
               simplifyVector = FALSE)
entries <- har$log$entries

# El visor pagina la respuesta (resultRecordCount=10000, resultOffset=...);
# el .har trae una entrada de red por página, así que hay que unir todas las
# que apunten a la misma capa antes de armar la tabla.
todas <- list()
for (e in entries) {
  if (!grepl("MapServer/0/query", e$request$url)) next
  d <- fromJSON(e$response$content$text, simplifyVector = FALSE)
  todas[[length(todas) + 1]] <- d$features
}
features <- do.call(c, todas)

epoch_a_fecha <- function(x) {
  if (is.null(x) || !is.numeric(x)) return(NA_character_)
  as.character(as.Date(as.POSIXct(x / 1000, origin = "1970-01-01", tz = "UTC")))
}

# ArcGIS REST devuelve cada registro como {attributes: {...}, geometry: {x,y}};
# se aplana a una fila por sujeto con nombres de columna legibles.
fila <- function(f) {
  a <- f$attributes
  g <- f$geometry
  # PORC_AVANCE_PIRC llega como TEXTO incluso cuando es un número: la API lo
  # trae formateado en coma decimal ("0,098076923077"), no como JSON numeric.
  # Se deja tal cual (texto crudo, "No Aplica" incluido) para que lo resuelva
  # a_numero() —ya sabe leer coma decimal— en 01_homogeneizacion/
  # reparacion_colectiva.R, igual que el resto del pipeline.
  porc <- a$PORC_AVANCE_PIRC
  porc_txt <- if (is.null(porc)) NA_character_ else as.character(porc)
  data.frame(
    objectid             = a$OBJECTID %||% NA,
    dpto_cod             = a$DPTO_CCDGO %||% NA,
    dpto                 = a$DPTO_CNMBR %||% NA,
    pdet_cod             = a$PDET_CCDGO %||% NA,
    pdet                 = a$PDET_CNMBR %||% NA,
    mpio_cod             = a$MPIO_CCDGO %||% NA,
    mpio                 = a$MPIO_CNMBR %||% NA,
    nombre_sujeto        = a$NOMBRE_SUJETO %||% NA,
    tipo                 = a$TIPO %||% NA,
    categoria            = a$CATEGORIA %||% NA,
    fud                  = a$FUD %||% NA,
    estado_ruv           = a$ESTADO_RUV %||% NA,
    fecha_notificacion   = epoch_a_fecha(a$FECHA_NOTIFICACION),
    estado_fase          = a$ESTADO_FASE %||% NA,
    porc_avance_pirc     = porc_txt,
    tipo_cierre_pirc     = a$TIPO_CIERRE_PIRC %||% NA,
    fecha_cierre_pirc    = if (is.character(a$FECHA_CIERRE_PIRC)) a$FECHA_CIERRE_PIRC else epoch_a_fecha(a$FECHA_CIERRE_PIRC),
    estado_medidas_rehab = a$EST_MED_REH %||% NA,
    valor_indem_etnica   = if (is.null(a$VAL_INDEM_ETN)) NA_real_ else as.numeric(a$VAL_INDEM_ETN),
    fecha_corte_reporte  = epoch_a_fecha(a$FECHA_CORTE_REPORTE),
    longitud             = g$x %||% NA_real_,
    latitud              = g$y %||% NA_real_,
    stringsAsFactors = FALSE
  )
}

tabla <- do.call(rbind, lapply(features, fila))

write.xlsx(tabla, "01_Data/00_Inputs/UARIV_sujetos_reparacion_colectiva.xlsx",
           sheetName = "Datos", overwrite = TRUE)

message(nrow(tabla), " sujetos (", sum(tabla$dpto_cod == "05", na.rm = TRUE),
        " en Antioquia) escritos en UARIV_sujetos_reparacion_colectiva.xlsx")
