# =============================================================================
# seguridad_policia.R — Delitos de alto impacto por municipio (Policía Nacional)
#
# INPUTS:
#   01_Data/00_Inputs/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025.xlsx
#     (hojas "Cuadro 2" homicidios, "Cuadro 6" violencia intrafamiliar,
#      "Cuadro 7" delitos sexuales, "Cuadro 10" hurto a personas)
# OUTPUTS:
#   01_Data/01_Derived/seguridad_policia.xlsx  (8 hojas: 4 delitos × 2 años)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/"Seguridad - Policia Nacional.do"
#
# NOTAS DE MIGRACIÓN
#   1. El .do dejó comentado el bloque de 2023, pero el derivado publicado SÍ
#      trae las cuatro hojas de 2023 (se generaron con una versión anterior del
#      mismo .do). Aquí se producen los dos años en la misma corrida, que es lo
#      que reproduce el archivo vigente.
#   2. El .do selecciona columnas por letra de Excel (AH, IP, EV...) tras
#      `cellrange(A15)`. Se conservan esas letras porque son la especificación:
#      la fuente no tiene encabezados usables (dos filas de títulos combinados),
#      así que `col_req()` no aplica y la posición es el único identificador.
#   3. El .do salta a la fila 15 para esquivar los títulos; aquí se filtra por
#      el contenido ("ANTIOQUIA" en la columna de departamento), que es el
#      criterio real del .do (`keep if strpos(departamento, "ANTIOQUIA")`) y no
#      depende de cuántas filas de encabezado traiga la próxima entrega.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== seguridad: Policía Nacional ==")

ARCHIVO_POLICIA <- "CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025.xlsx"

# --- Utilidades locales -------------------------------------------------------

#' Índice de columna a partir de la letra de Excel ("A" = 1, "AH" = 34,
#' "IP" = 250). El .do nombra las columnas por su letra; esto traduce.
.indice_columna <- function(letras) {
  vapply(strsplit(toupper(letras), ""), function(ch) {
    Reduce(function(acumulado, letra) acumulado * 26L + match(letra, LETTERS),
           ch, 0L)
  }, integer(1))
}

#' Filas de Antioquia de una hoja del cuadro delictivo, con las columnas que
#' pide el .do renombradas.
#'
#' @param hoja nombre de la hoja ("Cuadro 2", ...).
#' @param columnas vector nombrado  nombre_final = "LETRA_EXCEL".
.leer_cuadro <- function(hoja, columnas) {
  ruta <- entrada(ARCHIVO_POLICIA)
  crudo <- suppressWarnings(leer_excel(ruta, hoja = hoja))

  # Columna A = departamento, B = municipio (fijas en las cuatro hojas).
  departamento <- as.character(crudo[[1]])
  antioquia <- crudo[!is.na(departamento) &
                       grepl("ANTIOQUIA", departamento, fixed = TRUE), , drop = FALSE]
  if (nrow(antioquia) == 0) {
    stop("La hoja '", hoja, "' de ", basename(ruta), " no trae filas de ANTIOQUIA. ",
         "Verifique que la estructura de la fuente no haya cambiado.", call. = FALSE)
  }

  # "05001 - Medellín"  ->  cod_mpio "05001", nvl_label "Medellín"
  municipio <- as.character(antioquia[[2]])
  salida <- data.frame(
    ind_mpio  = as.numeric(substr(municipio, 1, 5)),
    cod_mpio  = substr(municipio, 1, 5),
    nvl_label = stringr::str_squish(substring(municipio, 9)),
    stringsAsFactors = FALSE
  )

  indices <- .indice_columna(unname(columnas))
  faltan <- indices[indices > ncol(antioquia)]
  if (length(faltan)) {
    stop("La hoja '", hoja, "' tiene ", ncol(antioquia), " columnas y el .do pide ",
         "hasta la ", max(indices), " (", names(columnas)[which.max(indices)], "). ",
         "La fuente cambió de estructura.", call. = FALSE)
  }
  for (i in seq_along(columnas)) {
    salida[[names(columnas)[i]]] <- a_numero(antioquia[[indices[i]]])
  }
  salida
}

# --- Definición de las ocho hojas ---------------------------------------------
# Cada entrada replica un bloque del .do: hoja de origen y letras de columna.
# El orden de `columnas` es el orden final de las variables en el derivado.

CUADROS <- list(
  homicidios_2025 = list(
    hoja = "Cuadro 2",
    columnas = c(total_historico = "C", total_2025 = "AH", arma_fuego_2025 = "AI",
                 arma_blanca_2025 = "AJ", contundente_2025 = "AK",
                 dron_explosivo_2025 = "AL", otros_2025 = "AM")
  ),
  violencia_intrafamiliar_2025 = list(
    hoja = "Cuadro 6",
    columnas = c(total_historico = "C", total_2025 = "AH", sin_armas_2025 = "AI",
                 arma_blanca_2025 = "AJ", contundente_2025 = "AK",
                 arma_fuego_2025 = "AL", otros_2025 = "AM")
  ),
  delitos_sexuales_2025 = list(
    hoja = "Cuadro 7",
    columnas = c(total_historico = "C", total_2025 = "AH", sin_armas_2025 = "AI",
                 arma_blanca_2025 = "AJ", arma_fuego_2025 = "AK",
                 contundente_2025 = "AL", otros_2025 = "AM")
  ),
  hurtos_personas_2025 = list(
    hoja = "Cuadro 10",
    columnas = c(total_historico = "C", total_2025 = "IP", sin_armas_2025 = "IQ",
                 arma_blanca_2025 = "IR", contundente_2025 = "IS",
                 arma_fuego_2025 = "IT", otros_2025 = "IU")
  ),
  homicidios_2023 = list(
    hoja = "Cuadro 2",
    columnas = c(total_historico = "C", total_2023 = "V", arma_fuego_2023 = "W",
                 arma_blanca_2023 = "X", contundente_2023 = "Y",
                 dron_explosivo_2023 = "Z", otros_2023 = "AA")
  ),
  violencia_intrafamiliar_2023 = list(
    hoja = "Cuadro 6",
    columnas = c(total_historico = "C", total_2023 = "V", sin_armas_2023 = "W",
                 arma_blanca_2023 = "X", contundente_2023 = "Y",
                 arma_fuego_2023 = "Z", otros_2023 = "AA")
  ),
  delitos_sexuales_2023 = list(
    hoja = "Cuadro 7",
    columnas = c(total_historico = "C", total_2023 = "V", sin_armas_2023 = "W",
                 arma_blanca_2023 = "X", arma_fuego_2023 = "Y",
                 contundente_2023 = "Z", otros_2023 = "AA")
  ),
  hurtos_personas_2023 = list(
    hoja = "Cuadro 10",
    columnas = c(total_historico = "C", total_2023 = "EV", sin_armas_2023 = "EW",
                 arma_blanca_2023 = "EX", contundente_2023 = "EY",
                 arma_fuego_2023 = "EZ", otros_2023 = "FA")
  )
)

# --- Construcción -------------------------------------------------------------
# Se calcula todo antes de tocar el derivado: si una hoja falla, el archivo
# anterior queda intacto.

tablas <- lapply(CUADROS, function(cu) .leer_cuadro(cu$hoja, cu$columnas))

n_filas <- vapply(tablas, nrow, integer(1))
if (length(unique(n_filas)) != 1) {
  stop("Las hojas no traen el mismo número de municipios: ",
       paste(names(n_filas), n_filas, sep = "=", collapse = ", "), call. = FALSE)
}

# --- Guardar ------------------------------------------------------------------
# Antes eran ocho hojas de un .xlsx, una por delito y año. Como todas tienen la
# misma estructura, en parquet van como una sola tabla larga con las columnas
# `delito` y `anio`: es el mismo dato, pero filtrable y sin repetir esquema.
largo <- purrr::imap_dfr(tablas, function(tabla, nombre) {
  partes <- regmatches(nombre, regexec("^(.*)_(\\d{4})$", nombre))[[1]]
  tabla$delito <- partes[2]
  tabla$anio   <- as.integer(partes[3])
  tabla
})
largo <- dplyr::relocate(largo, "delito", "anio", .after = 1)

escribir_derivado(largo, "seguridad_policia")
message("  seguridad_policia: ", dplyr::n_distinct(largo$delito), " delitos × ",
        dplyr::n_distinct(largo$anio), " años × ", n_filas[[1]],
        " municipios de Antioquia")
