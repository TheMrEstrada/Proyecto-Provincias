# =============================================================================
# finanzas_mapainversiones.R — Presupuesto de inversión por fuente (DNP)
#
# Punto 2 de los "Verificar con el equipo" de la revisión del 21/08/2026:
# margen real de inversión de cada municipio (funcionamiento, deuda,
# regalías, SGP, cooperación). Laura capturó dos .har navegando
# mapainversiones.dnp.gov.co, pero solo traían Medellín — al revisarlos
# encontramos que el API detrás del sitio (mapainversionesapp-api.dnp.gov.co,
# vía arcgiswebmapainv.dnp.gov.co) NO pide autenticación, así que este script
# lo consulta directamente para los 125 municipios, en vez de depender de
# más capturas de navegador.
#
# ES EL PRIMER SCRIPT DE ESTE PIPELINE QUE HACE LLAMADAS DE RED EN VIVO
# (todo lo demás lee archivos locales). Si no hay internet, o el servicio
# está caído, se detiene con "Falta el insumo" en la PRIMERA consulta (no en
# medio de las 125), para que run_all.R lo categorice como SIN INSUMO y siga
# con el resto del pipeline — igual que un archivo ausente.
#
# El endpoint REC_Presupuesto agrupa el presupuesto de inversión por
# TODAS las fuentes de financiación a la vez (IdGrupoRecursos): una sola
# consulta por municipio trae PGN, SGP, recursos propios, obras por
# impuestos, etc. — no hace falta una llamada distinta por fuente.
#
# EXCEPTO regalías: se probó contra Medellín en todas las vigencias
# 2012-2026 y el grupo "SGR - Sistema General de Regalías" da 0 siempre —
# no es un filtro mal puesto, es que esta tabla (que agrega presupuesto por
# PROYECTO) no trae las regalías, que en la arquitectura del DNP viven en un
# sistema aparte (SUIFP-SGR / SICODIS SGR, ver la hoja "FuentesInformacion
# Agrupadas" capturada en el .har). Por eso regalías se trae de un segundo
# endpoint, FichasConsolidadoSGR, que si da cifras reales (probado en 4
# municipios): se pega como una fila más de "grupo_recursos", reemplazando
# el 0 que trae REC_Presupuesto para esa fuente.
#
# LO QUE NO TRAE: deuda pública / servicio de la deuda. Mapa de Inversiones
# es una herramienta de presupuesto de INVERSIÓN, no de pasivos; no hay
# ningún campo de deuda en este API. Sigue pendiente (ver README de
# 04_Docs/CORRECCIONES o la bitácora de la sesión) — probablemente haya que
# recurrir a CHIP/FUT, que no tienen API abierta.
#
# INPUTS:  01_Data/00_Inputs/códigos_municipios_clean.dta (universo de 125
#            municipios de Antioquia; da el código DANE que pide el API)
#          Red: arcgiswebmapainv.dnp.gov.co (en vivo, sin autenticación)
# OUTPUTS: 01_Data/01_Derived/finanzas_mapainversiones.parquet
#          (hasta 125 municipios x hasta ~9 fuentes = ~1.100 filas largas:
#          ind_mpio, id_grupo_recursos, grupo_recursos, presupuesto,
#          presupuesto_ejecutado)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== finanzas municipales, Mapa de Inversiones DNP (en vivo) ==")

VIGENCIA_MAPAINVERSIONES <- 2026L

#' GET con timeout real. jsonlite::fromJSON(url) usa una conexión base de R
#' que en Windows a veces NO respeta options("timeout") si el servidor deja
#' la conexión abierta sin responder — un solo municipio así se cuelga la
#' corrida entera sin avisar. curl sí impone el timeout a nivel de libcurl.
.get_json <- function(url, timeout_s = 15) {
  h <- curl::new_handle(timeout = timeout_s, connecttimeout = timeout_s)
  resp <- curl::curl_fetch_memory(url, handle = h)
  if (resp$status_code >= 400) {
    stop("HTTP ", resp$status_code, call. = FALSE)
  }
  jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = FALSE)
}

#' URL de la consulta ArcGIS REST para un municipio: presupuesto de inversión
#' agrupado por fuente de financiación (IdGrupoRecursos), sin geometría.
.url_rec_presupuesto <- function(ind_mpio) {
  cod <- sprintf("%05d", ind_mpio)
  where <- sprintf(
    "1 = 1  AND (( CodigoMunicipio = '%s')) AND Vigencia = %d AND IdGrupoRecursos IS NOT NULL",
    cod, VIGENCIA_MAPAINVERSIONES
  )
  stats <- paste0(
    '[{"statisticType":"sum","onStatisticField":"Presupuesto",',
    '"outStatisticFieldName":"TotalPresupuesto"},',
    '{"statisticType":"sum","onStatisticField":"PresupuestoEjecutado",',
    '"outStatisticFieldName":"TotalPresupuestoEjecutado"}]'
  )
  campos <- "IdGrupoRecursos,GrupoRecursos,Vigencia"
  paste0(
    "https://mapainversiones.dnp.gov.co/proxy.ashx?",
    "https://arcgiswebmapainv.dnp.gov.co/arcgis/rest/services/",
    "REC_RECURSOS/REC_Presupuesto/MapServer/0/query",
    "?f=json&where=", utils::URLencode(where, reserved = TRUE),
    "&returnGeometry=false&spatialRel=esriSpatialRelIntersects",
    "&outFields=", utils::URLencode(campos, reserved = TRUE),
    "&groupByFieldsForStatistics=", utils::URLencode(campos, reserved = TRUE),
    "&outStatistics=", utils::URLencode(stats, reserved = TRUE)
  )
}

#' URL de la ficha consolidada de regalías (SGR) de un municipio.
.url_ficha_sgr <- function(ind_mpio, vigencia = VIGENCIA_MAPAINVERSIONES) {
  cod <- sprintf("%05d", ind_mpio)
  paste0(
    "https://mapainversiones.dnp.gov.co/proxy.ashx?",
    "https://mapainversionesapp-api.dnp.gov.co/api/FichasConsolidadoSGR",
    "?vigencia=", vigencia, "&codigoDepartamento=05",
    "&codigoMunicipio=", cod, "&codigoentidad=", cod, "&IdFuenteFinanciacion=1"
  )
}

#' Regalías (SGR) de un municipio: una fila, o NULL si no hay nada
#' presupuestado. "Girado" (lo efectivamente transferido) hace de proxy de
#' "ejecutado" — ListaEjecutado viene vacía en todas las pruebas, mientras
#' que ListaGirado sí trae movimientos reales.
.regalias_municipio <- function(ind_mpio) {
  d <- .get_json(.url_ficha_sgr(ind_mpio))
  sumar <- function(lista) {
    if (!length(lista)) return(0)
    sum(vapply(lista, function(x) x$Valor %||% 0, numeric(1)), na.rm = TRUE)
  }
  presupuestado <- sumar(d$ListaPresupuestado)
  girado <- sumar(d$ListaGirado)
  if (presupuestado == 0 && girado == 0) return(NULL)
  data.frame(
    ind_mpio = ind_mpio, id_grupo_recursos = 4L,
    grupo_recursos = "SGR - Sistema General de Regalías",
    presupuesto = presupuestado, presupuesto_ejecutado = girado,
    stringsAsFactors = FALSE
  )
}

#' Presupuesto de un municipio (todas las fuentes salvo regalías —
#' REC_Presupuesto siempre da 0 en SGR, ver cabecera— más la fila de
#' regalías que sí trae FichasConsolidadoSGR). NULL si ninguna de las dos
#' consultas trae nada (municipio sin proyectos registrados: pasa, varios
#' municipios pequeños no tienen).
.presupuesto_municipio <- function(ind_mpio) {
  d <- .get_json(.url_rec_presupuesto(ind_mpio))
  feats <- d$features

  otras_fuentes <- if (!length(feats)) NULL else {
    filas <- lapply(feats, function(f) {
      a <- f$attributes
      if (identical(a$IdGrupoRecursos, 4L) || identical(a$IdGrupoRecursos, 4)) return(NULL)
      data.frame(
        ind_mpio               = ind_mpio,
        id_grupo_recursos      = a$IdGrupoRecursos %||% NA_integer_,
        grupo_recursos         = a$GrupoRecursos %||% NA_character_,
        presupuesto            = a$TotalPresupuesto %||% NA_real_,
        presupuesto_ejecutado  = a$TotalPresupuestoEjecutado %||% NA_real_,
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, filas)
  }

  Sys.sleep(0.25)  # cortesía con el servicio del DNP: son dos consultas por municipio
  regalias <- .regalias_municipio(ind_mpio)
  rbind(otras_fuentes, regalias)
}

municipios <- haven::read_dta(entrada("códigos_municipios_clean.dta")) |>
  dplyr::transmute(ind_mpio = as.integer(ind_mpio)) |>
  dplyr::arrange(.data$ind_mpio)

# Primer municipio aparte: si el servicio no responde, se detiene aquí (con
# el mismo mensaje "Falta el insumo" que usa entrada()) en vez de fallar a
# medias 60 municipios después.
primero <- tryCatch(
  .presupuesto_municipio(municipios$ind_mpio[1]),
  error = function(e) {
    stop("Falta el insumo:\n  API mapainversiones.dnp.gov.co (en vivo)\n",
         "No respondió en la primera consulta (", conditionMessage(e), "). ",
         "Revise la conexión a internet; el resto del pipeline sigue con ",
         "los derivados ya generados.", call. = FALSE)
  }
)

resultados <- vector("list", nrow(municipios))
resultados[[1]] <- primero
n_ok <- as.integer(!is.null(primero))
n_vacios <- as.integer(is.null(primero))

#' Un intento, y si falla (timeout, HTTP raro) un segundo intento antes de
#' rendirse y dejar el municipio en blanco: en 250 consultas seguidas a un
#' servicio del Estado es más probable un hipo puntual que una caída real.
.con_reintento <- function(m) {
  tryCatch(.presupuesto_municipio(m), error = function(e1) {
    message("  [aviso] ", m, ": ", conditionMessage(e1), " — reintentando")
    Sys.sleep(1)
    tryCatch(.presupuesto_municipio(m), error = function(e2) {
      message("  [aviso] ", m, ": ", conditionMessage(e2), " — se deja en blanco")
      NULL
    })
  })
}

for (i in 2:nrow(municipios)) {
  Sys.sleep(0.25)  # cortesía con el servicio del DNP
  m <- municipios$ind_mpio[i]
  r <- .con_reintento(m)
  resultados[[i]] <- r
  if (is.null(r)) n_vacios <- n_vacios + 1L else n_ok <- n_ok + 1L
  if (i %% 10 == 0) {
    message("  ... ", i, " de ", nrow(municipios), " municipios consultados")
  }
}

finanzas_mapainversiones <- do.call(rbind, resultados)

stopifnot(
  "no llegó ningún municipio con datos" = !is.null(finanzas_mapainversiones) &&
    nrow(finanzas_mapainversiones) > 0
)

escribir_derivado(finanzas_mapainversiones, "finanzas_mapainversiones")

message("  finanzas_mapainversiones: ", n_ok, " municipios con datos, ",
        n_vacios, " sin proyectos/presupuesto registrado en ",
        VIGENCIA_MAPAINVERSIONES, " (", nrow(finanzas_mapainversiones), " filas)")
