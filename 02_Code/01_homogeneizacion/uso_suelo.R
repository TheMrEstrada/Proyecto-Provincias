# =============================================================================
# uso_suelo.R — Conflictos de uso del suelo POTA por municipio
#
# INPUTS:
#   01_Data/00_Inputs/TABLAS MUNICIPALES octubre/GRUPO {1..8}/*.xlsx
#     (un archivo por municipio, con hojas "RURAL" y "URBANO")
# OUTPUTS:
#   01_Data/01_Derived/uso_del_suelo_pota.xlsx   (hoja "Sheet1", 1 fila/municipio)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/"Uso adecuado del suelo.do"
#
# La hoja se llama "Sheet1" porque así la nombró `export excel` de Stata y así
# la pide 03_tablas/03_ordenamiento.R. No la renombre sin actualizar ese script.
#
# NOTAS DE MIGRACIÓN
#   1. El .do usaba `postfile` y globals propios ($base, $outpath); aquí se
#      acumula en memoria y se usan entrada()/derivado() como el resto.
#   2. Las hojas se leen con openxlsx2 y NO con leer_excel() (readxl) por una
#      razón concreta: varias hojas declaran un rango mayor que sus datos (p.
#      ej. "A1:B785" con 540 predios reales). readxl recorta esas filas vacías
#      finales; Stata y openxlsx2 las cuentan. Como el derivado publicado las
#      cuenta, leerlas con readxl cambiaría `n_predios_urbano` en 19 de los 88
#      municipios. Ver la nota sobre filas fantasma más abajo.
#   3. El .do del repositorio quedó con un `else` suelto (líneas 180-186) que
#      Stata rechaza: el archivo vigente lo produjo una versión anterior. Aquí
#      se reconstruye la lógica que sí corrió, y el resultado reproduce el
#      derivado columna por columna.
#
# FILAS FANTASMA (advertencia para quien use estas cifras)
#   `n_predios_urbano` cuenta las filas del rango declarado de la hoja URBANO,
#   incluidas las vacías; por eso en varios municipios vale 784 (el tamaño de la
#   plantilla) y no coincide con
#   `n_predios_favorables_proteccion + n_predios_no_favorables`, que sí cuentan
#   predios reales. Se conserva el comportamiento para no alterar el derivado
#   publicado. Lo mismo pasa con `n_predios_uso_adec_gt80` y `..._100` en la
#   hoja RURAL: en Stata `missing >= 0.80` es verdadero, así que los predios sin
#   porcentaje caen ahí.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== uso adecuado del suelo (POTA) ==")

CARPETA_POTA <- "TABLAS MUNICIPALES octubre"

# --- Encabezados --------------------------------------------------------------
# Los archivos no traen nombres de columna estables, así que el .do clasifica
# cada encabezado por las palabras que contiene. Se replica ese mismo orden de
# comparaciones (el primero que coincide gana).

.nombre_rural <- function(encabezado) {
  h <- norm_txt(encabezado)
  pct <- grepl("%", h, fixed = TRUE)
  if (is.na(h) || !nzchar(h))                     NA_character_
  else if (grepl("cartograf", h))                 "area_cartografia"
  else if (grepl("adecuado", h) && pct)           "pct_adecuado"
  else if (grepl("adecuado", h))                  "area_adecuado"
  else if (grepl("sobreutiliz", h) && pct)        "pct_sobre"
  else if (grepl("sobreutiliz", h))               "area_sobre"
  else if (grepl("subutiliz", h) && pct)          "pct_sub"
  else if (grepl("subutiliz", h))                 "area_sub"
  else if (grepl("sin conflicto", h) && pct)      "pct_sin"
  else if (grepl("sin conflicto", h))             "area_sin"
  else if (grepl("verific", h))                   "pct_verif"
  else if (grepl("total", h) && !pct)             "area_total"
  else if (grepl("npn", h))                       "npn"
  else if (grepl("pk", h))                        "pk_predio"
  else                                            NA_character_
}

.nombre_urbano <- function(encabezado) {
  h <- norm_txt(encabezado)
  if (is.na(h) || !nzchar(h))    NA_character_
  else if (grepl("calific", h))  "conflicto_urbano"
  else if (grepl("npn", h))      "npn"
  else if (grepl("pk", h))       "pk_predio"
  else                           NA_character_
}

# Columnas sobre las que el .do hace `destring ..., force`.
NUM_RURAL  <- c("area_adecuado", "area_sobre", "area_sub", "area_sin",
                "area_total", "pct_adecuado")
NUM_URBANO <- "conflicto_urbano"

#' Lee una hoja del archivo POTA con los nombres canónicos ya aplicados.
#'
#' El encabezado va en la fila 1 y los datos empiezan en la 2 (el .do hace
#' `drop in 1`). Las columnas numéricas se piden como tales al lector: los
#' porcentajes vienen a veces guardados como texto en notación científica
#' ("5.37E-2") y así se convierten igual que con `destring, force` de Stata.
#'
#' @return data.frame, o NULL si la hoja no existe.
.leer_hoja_pota <- function(wb, hoja, clasificar, numericas) {
  if (!hoja %in% wb$get_sheet_names()) return(NULL)

  encabezado <- openxlsx2::wb_to_df(
    wb, sheet = hoja, col_names = FALSE, rows = 1,
    skip_empty_rows = FALSE, skip_empty_cols = FALSE
  )
  nombres <- vapply(as.character(unlist(encabezado[1, ])), clasificar,
                    character(1), USE.NAMES = FALSE)

  tipos <- ifelse(!is.na(nombres) & nombres %in% numericas, 1L, 0L)
  names(tipos) <- names(encabezado)
  datos <- tryCatch(
    suppressWarnings(openxlsx2::wb_to_df(
      wb, sheet = hoja, col_names = FALSE, start_row = 2, types = tipos,
      skip_empty_rows = FALSE, skip_empty_cols = FALSE
    )),
    error = function(e) NULL
  )
  if (is.null(datos)) datos <- encabezado[0, , drop = FALSE]

  # `capture rename` de Stata: si el nombre destino ya se usó, el rename falla
  # en silencio y la columna conserva su letra. Se replica.
  finales <- character(ncol(datos))
  usados <- character(0)
  for (i in seq_len(ncol(datos))) {
    candidato <- if (i <= length(nombres)) nombres[i] else NA_character_
    if (!is.na(candidato) && !candidato %in% usados) {
      finales[i] <- candidato
      usados <- c(usados, candidato)
    } else {
      finales[i] <- names(datos)[i]
    }
  }
  names(datos) <- finales
  datos
}

#' Resume un archivo municipal: una fila con los 17 campos del derivado.
.resumen_municipio <- function(ruta, grupo) {
  nombre_archivo <- sub("\\.xlsx$", "", basename(ruta))
  partes <- stringr::str_match(nombre_archivo, "^([0-9]+)_conflictos_(.+)$")
  codmpio   <- if (is.na(partes[1, 1])) "NA" else partes[1, 2]
  municipio <- if (is.na(partes[1, 1])) nombre_archivo else partes[1, 3]

  fila <- data.frame(
    codmpio = codmpio, municipio = municipio, grupo = grupo,
    n_predios_rural = NA_real_, pct_uso_adecuado_rural = NA_real_,
    pct_sobreutilizacion_rural = NA_real_, pct_subutilizacion_rural = NA_real_,
    pct_sin_conflicto_rural = NA_real_, chk_pct_sum = NA_real_,
    n_predios_uso_adec_lt60 = NA_real_, n_predios_uso_adec_60_80 = NA_real_,
    n_predios_uso_adec_gt80 = NA_real_, n_predios_uso_adec_100 = NA_real_,
    tiene_urbano = 0, n_predios_urbano = NA_real_,
    n_predios_favorables_proteccion = NA_real_, n_predios_no_favorables = NA_real_,
    stringsAsFactors = FALSE
  )

  wb <- openxlsx2::wb_load(ruta)

  # --- Hoja RURAL -------------------------------------------------------------
  rural <- .leer_hoja_pota(wb, "RURAL", .nombre_rural, NUM_RURAL)
  if (is.null(rural)) {
    message("  [aviso] sin hoja RURAL legible en ", basename(ruta))
  } else if (!all(c("area_total", "pct_adecuado") %in% names(rural))) {
    message("  [aviso] encabezados no reconocidos en RURAL de ", basename(ruta))
  } else {
    pct <- a_numero(rural$pct_adecuado)
    fila$n_predios_rural <- nrow(rural)
    # En Stata el missing es mayor que cualquier número: los predios sin
    # porcentaje entran en las categorías ">=0.80" y "=100%".
    fila$n_predios_uso_adec_lt60  <- sum(!is.na(pct) & pct < 0.60)
    fila$n_predios_uso_adec_60_80 <- sum(!is.na(pct) & pct >= 0.60 & pct < 0.80)
    fila$n_predios_uso_adec_gt80  <- sum(is.na(pct) | pct >= 0.80)
    fila$n_predios_uso_adec_100   <- sum(is.na(pct) | pct >= 0.999999)

    area_total <- sum(a_numero(rural$area_total), na.rm = TRUE)
    if (!is.na(area_total) && area_total > 0) {
      participacion <- function(columna) {
        if (!columna %in% names(rural)) return(NA_real_)
        sum(a_numero(rural[[columna]]), na.rm = TRUE) / area_total * 100
      }
      fila$pct_uso_adecuado_rural     <- participacion("area_adecuado")
      fila$pct_sobreutilizacion_rural <- participacion("area_sobre")
      fila$pct_subutilizacion_rural   <- participacion("area_sub")
      fila$pct_sin_conflicto_rural    <- participacion("area_sin")
      fila$chk_pct_sum <- fila$pct_uso_adecuado_rural +
        fila$pct_sobreutilizacion_rural + fila$pct_subutilizacion_rural +
        fila$pct_sin_conflicto_rural
    }
  }

  # --- Hoja URBANO (puede no existir) -----------------------------------------
  urbano <- .leer_hoja_pota(wb, "URBANO", .nombre_urbano, NUM_URBANO)
  if (is.null(urbano)) {
    message("  [aviso] sin hoja URBANO en ", basename(ruta), " (solo rural)")
  } else if (!"conflicto_urbano" %in% names(urbano)) {
    message("  [aviso] hoja URBANO sin columna de calificación en ", basename(ruta))
  } else {
    calificacion <- a_numero(urbano$conflicto_urbano)
    fila$n_predios_urbano <- nrow(urbano)   # incluye filas fantasma (ver cabecera)
    fila$n_predios_favorables_proteccion <-
      sum(!is.na(calificacion) & calificacion == 1)
    fila$n_predios_no_favorables <- sum(!is.na(calificacion) & calificacion == 0)
    fila$tiene_urbano <- 1
  }

  fila
}

# --- Recorrido de las ocho carpetas -------------------------------------------
raiz_pota <- entrada(CARPETA_POTA)

grupos <- list.dirs(raiz_pota, full.names = TRUE, recursive = FALSE)
grupos <- grupos[grepl("^GRUPO [0-9]+$", basename(grupos))]
grupos <- grupos[order(as.integer(sub("^GRUPO ", "", basename(grupos))))]
if (length(grupos) == 0) {
  stop("No hay carpetas 'GRUPO n' dentro de:\n  ", raiz_pota, call. = FALSE)
}

filas <- list()
for (carpeta in grupos) {
  grupo <- basename(carpeta)
  archivos <- sort(list.files(carpeta, pattern = "\\.xlsx$", full.names = TRUE))
  message("  ", grupo, ": ", length(archivos), " municipios")
  for (ruta in archivos) {
    filas[[length(filas) + 1]] <- .resumen_municipio(ruta, grupo)
  }
}

resultado <- dplyr::bind_rows(filas) |>
  dplyr::arrange(.data$codmpio)

if (nrow(resultado) == 0) {
  stop("No se procesó ningún municipio en:\n  ", raiz_pota, call. = FALSE)
}

# --- Guardar ------------------------------------------------------------------
escribir_derivado(resultado, "uso_del_suelo_pota")

fuera_de_rango <- sum(abs(resultado$chk_pct_sum - 100) > 1, na.rm = TRUE)
message("  uso_del_suelo_pota: ", nrow(resultado), " municipios (",
        sum(resultado$tiene_urbano == 1), " con hoja URBANO)")
if (fuera_de_rango > 0) {
  message("  [aviso] ", fuera_de_rango,
          " municipios con chk_pct_sum fuera de [99,101]")
}
