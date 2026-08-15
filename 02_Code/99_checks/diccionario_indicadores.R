# =============================================================================
# diccionario_indicadores.R — Qué publica el pipeline y qué ficha lo respalda
#
# Cruza tres listas que hoy viven separadas y nunca se han comparado:
#
#   1. Lo que el pipeline PUBLICA — cada columna de cada hoja de cada sección,
#      leída de las salidas reales, no de la documentación.
#   2. Lo que el INVENTARIO declara — INVENTARIO_VARIABLES_v_2.xlsx, hoja
#      "Indicadores clave": fuente, periodo, periodicidad, sentido, unidad.
#   3. Lo que tiene FICHA TÉCNICA — los .docx de 00_Documentos/Fichas Tecnicas.
#
# El emparejamiento es EXACTO sobre texto normalizado. No se aproxima: un
# indicador que no case queda como "sin correspondencia" y alguien decide.
# Adivinar el cruce sería inventar respaldo documental donde no lo hay.
#
# USO:    Rscript 02_Code/99_checks/diccionario_indicadores.R
# SALIDA: 04_Docs/auditoria/H1_diccionario_indicadores.csv
#         04_Docs/auditoria/H2_fichas_tecnicas.csv
#         04_Docs/auditoria/H3_cobertura_documental.csv
#
# ETAPA DEL PIPELINE: verificación
# =============================================================================

if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(dirname(normalizePath(.f[1])))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}

DIR_AUDIT <- file.path(RUTAS$raiz, "04_Docs", "auditoria")
dir.create(DIR_AUDIT, recursive = TRUE, showWarnings = FALSE)

# Encabezados que identifican el territorio, no un indicador.
TERRITORIALES <- c("codigo dane", "municipio", "subregion", "provincia", "ano",
                   "tipo de fila", "ambito")

#' Clave conceptual de un indicador: su nombre sin los adornos de presentación.
#'
#' Quita únicamente sufijos de PRESENTACIÓN —el ámbito de la fila, la zona, la
#' unidad entre paréntesis, un dígito de versión al final del nombre del
#' archivo—. No toca el concepto: "Tasa de desocupación - total (municipal)" y
#' "Tasa de desocupación" son el mismo indicador; "Tasa de desocupación
#' jóvenes (15-28)" NO lo es y sigue sin casar, que es lo correcto.
.clave_concepto <- function(x) {
  y <- norm_txt(x)
  y <- sub(" \\((municipal|agregado)\\)$", "", y)
  y <- sub(" - (total|urbano|urbana|rural|cabecera municipal|centros poblados y rural)$", "", y)
  y <- sub(" \\((%|\\$)\\)$", "", y)
  y <- sub(" por 100 mil hab.*$", "", y)
  y <- sub(" por 100\\.000 hab.*$", "", y)
  y <- sub(" \\(x 1\\.000 nacidos vivos\\)$", "", y)
  y <- sub("[0-9]+$", "", y)         # "deficit cualitativo de vivienda1"
  y <- sub("fuente$", "", y)         # nombres de ficha con el sufijo pegado
  y <- sub("^tasa de desercion escolar$", "tasa de desercion", y)
  trimws(y)
}

# =============================================================================
# 1. Lo que el pipeline publica
# =============================================================================

indicadores_publicados <- function() {
  filas <- list()
  for (id in PROVINCIAS$id) {
    prov <- provincia(id)
    carpeta <- file.path(RUTAS$outputs, prov$carpeta)
    if (!dir.exists(carpeta)) next
    for (xlsx in list.files(carpeta, pattern = "\\.xlsx$", recursive = TRUE,
                            full.names = TRUE)) {
      seccion <- basename(dirname(xlsx))
      wb <- openxlsx2::wb_load(xlsx)
      for (hoja in wb$get_sheet_names()) {
        if (startsWith(hoja, "_")) next   # hojas de datos de figura
        d <- tryCatch(openxlsx2::wb_to_df(wb, sheet = hoja, rows = 1:2),
                      error = function(e) NULL)
        if (is.null(d)) next
        for (cl in names(d)) {
          if (norm_txt(cl) %in% TERRITORIALES) next
          filas[[length(filas) + 1]] <- data.frame(
            seccion = seccion, hoja = hoja, indicador = cl,
            provincia = prov$etiqueta
          )
        }
      }
    }
  }
  d <- do.call(rbind, filas)
  agg <- stats::aggregate(provincia ~ seccion + hoja + indicador, d,
                          function(x) length(unique(x)))
  names(agg)[names(agg) == "provincia"] <- "n_provincias"
  agg[order(agg$seccion, agg$hoja, agg$indicador), ]
}

# =============================================================================
# 2. Lo que declara el inventario
# =============================================================================

inventario_declarado <- function() {
  ruta <- entrada("INVENTARIO_VARIABLES_v_2.xlsx", obligatorio = FALSE)
  if (!file.exists(ruta)) return(NULL)
  d <- leer_excel(ruta, hoja = "Indicadores clave")
  c_ind <- col(d, "Indicador")
  if (is.na(c_ind)) return(NULL)
  data.frame(
    indicador_inventario = as.character(d[[c_ind]]),
    clave = .clave_concepto(as.character(d[[c_ind]])),
    subdimension = if (!is.na(col(d, "Subdimensión"))) as.character(d[[col(d, "Subdimensión")]]) else NA,
    fuente       = if (!is.na(col(d, "Fuente"))) as.character(d[[col(d, "Fuente")]]) else NA,
    periodo      = if (!is.na(col(d, "Periodo"))) as.character(d[[col(d, "Periodo")]]) else NA,
    periodicidad = if (!is.na(col(d, "Periodicidad"))) as.character(d[[col(d, "Periodicidad")]]) else NA,
    unidad       = if (!is.na(col(d, "Unidad de medida"))) as.character(d[[col(d, "Unidad de medida")]]) else NA,
    sentido      = if (!is.na(col(d, "Sentido"))) as.character(d[[col(d, "Sentido")]]) else NA,
    actualizable = if (!is.na(col(d, "Se puede actualizar a 2025"))) as.character(d[[col(d, "Se puede actualizar a 2025")]]) else NA,
    stringsAsFactors = FALSE
  ) |>
    subset(!is.na(indicador_inventario) & nzchar(trimws(indicador_inventario)))
}

# =============================================================================
# 3. Fichas técnicas disponibles
# =============================================================================
# Las fichas POTA son fichas MUNICIPALES de contexto (una por municipio), no
# fichas de indicador: se cuentan aparte para no inflar la cobertura.

fichas_tecnicas <- function() {
  base <- file.path(RUTAS$documentos, "Fichas Tecnicas")
  if (!dir.exists(base)) return(NULL)
  todas <- list.files(base, pattern = "\\.docx$", recursive = TRUE, full.names = TRUE)
  todas <- todas[!grepl("/POTA/", todas)]
  data.frame(
    ficha = tools::file_path_sans_ext(basename(todas)),
    clave = .clave_concepto(tools::file_path_sans_ext(basename(todas))),
    familia = basename(dirname(todas)),
    ruta = sub(paste0(RUTAS$raiz, "/"), "", todas, fixed = TRUE),
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# Cruce y salida
# =============================================================================

construir <- function() {
  message("== Diccionario de indicadores ==")

  pub <- indicadores_publicados()
  message("  publicados: ", nrow(pub), " indicadores distintos en ",
          length(unique(pub$seccion)), " secciones")

  fic <- fichas_tecnicas()
  inv <- inventario_declarado()

  pub$clave <- .clave_concepto(pub$indicador)

  pub$ficha_tecnica <- if (is.null(fic)) NA_character_ else
    fic$ficha[match(pub$clave, fic$clave)]
  pub$familia_ficha <- if (is.null(fic)) NA_character_ else
    fic$familia[match(pub$clave, fic$clave)]
  pub$tiene_ficha <- !is.na(pub$ficha_tecnica)

  if (!is.null(inv)) {
    i <- match(pub$clave, inv$clave)
    pub$fuente_inventario <- inv$fuente[i]
    pub$periodo_inventario <- inv$periodo[i]
    pub$periodicidad_inventario <- inv$periodicidad[i]
    pub$sentido_inventario <- inv$sentido[i]
    pub$actualizable_2025 <- inv$actualizable[i]
    pub$en_inventario <- !is.na(i)
  } else {
    pub$en_inventario <- NA
  }

  utils::write.csv(pub[, c("seccion", "hoja", "indicador", "n_provincias",
                           "tiene_ficha", "ficha_tecnica", "familia_ficha",
                           setdiff(names(pub), c("seccion", "hoja", "indicador",
                                                 "n_provincias", "tiene_ficha",
                                                 "ficha_tecnica", "familia_ficha",
                                                 "clave")))],
                   file.path(DIR_AUDIT, "H1_diccionario_indicadores.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")

  if (!is.null(fic)) {
    fic$usada_por_el_pipeline <- fic$clave %in% pub$clave
    utils::write.csv(fic[, c("familia", "ficha", "usada_por_el_pipeline", "ruta")],
                     file.path(DIR_AUDIT, "H2_fichas_tecnicas.csv"),
                     row.names = FALSE, fileEncoding = "UTF-8", na = "")
  }

  cobertura <- do.call(rbind, lapply(split(pub, pub$seccion), function(g) {
    data.frame(
      seccion = g$seccion[1],
      indicadores_publicados = nrow(g),
      con_ficha_tecnica = sum(g$tiene_ficha),
      en_inventario = sum(g$en_inventario, na.rm = TRUE),
      pct_con_ficha = round(100 * sum(g$tiene_ficha) / nrow(g), 1)
    )
  }))
  utils::write.csv(cobertura, file.path(DIR_AUDIT, "H3_cobertura_documental.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")

  message("  con ficha técnica: ", sum(pub$tiene_ficha), " de ", nrow(pub),
          " (", round(100 * sum(pub$tiene_ficha) / nrow(pub)), " %)")
  if (!is.null(fic)) {
    message("  fichas que ningún indicador publicado usa: ",
            sum(!fic$usada_por_el_pipeline), " de ", nrow(fic))
  }
  message("  [diccionario] H1, H2 y H3 en 04_Docs/auditoria/")
  invisible(list(publicados = pub, fichas = fic, inventario = inv,
                 cobertura = cobertura))
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "diccionario_indicadores.R") {
  construir()
}
