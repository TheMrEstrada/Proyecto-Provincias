# =============================================================================
# infraestructura_internet.R — Accesos fijos a internet, Antioquia 2025
#
# INPUTS:  01_Data/00_Inputs/EMPAQUETAMIENTO_FIJO_3.csv  (MinTIC; no versionado)
# OUTPUTS: 01_Data/01_Derived/infraestructura_internet_2025.dta
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/"Infraestructura internet.do"
#
# El insumo no cabe en el repositorio (ver .gitignore y el README de 00_Inputs).
# Si falta, este script se detiene con un mensaje claro y el resto del pipeline
# sigue: la sección que lo usa trabaja con el derivado ya generado.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== infraestructura de internet ==")

ruta <- entrada("EMPAQUETAMIENTO_FIJO_3.csv")   # aborta con mensaje si no está

# El MinTIC ha publicado este archivo separado por comas y separado por punto y
# coma. El separador se detecta en la primera línea en vez de suponerlo: con la
# suposición equivocada, read_csv() no falla — devuelve una tabla de UNA columna
# cuyo nombre es la cabecera entera.
cabecera <- readLines(ruta, n = 1L, warn = FALSE)
sep <- if (stringr::str_count(cabecera, ";") > stringr::str_count(cabecera, ",")) ";" else ","

# Los encabezados llegan unas veces en minúscula y otras en MAYÚSCULA. Se pasan
# a minúscula porque el derivado se lee después por nombre exacto en
# 03_tablas/03_ordenamiento.R (.data$servicio_paquete, .data$estado, ...).
# col_req() se resuelve sobre una muestra, no sobre el archivo entero, y sigue
# abortando con un mensaje que dice qué columnas sí hay.
muestra <- readr::read_delim(ruta, delim = sep, n_max = 100,
                             col_types = readr::cols(.default = readr::col_character()),
                             show_col_types = FALSE, progress = FALSE)
names(muestra) <- tolower(names(muestra))
c_depto <- col_req(muestra, "id_departamento")
c_mpio  <- col_req(muestra, "id_municipio")
c_anno  <- col_req(muestra, "anno", "año", "anio")

# El archivo trae los accesos de todo el país (3,6 millones de filas) y crece
# cada trimestre. Se lee por trozos descartando sobre la marcha lo que no es
# Antioquia 2025, para que la memoria no dependa de lo que crezca la fuente.
# Todos los trozos se leen como texto para que sus tipos coincidan al unirlos.
recorte <- function(x, pos) {
  names(x) <- tolower(names(x))
  d <- suppressWarnings(as.integer(x[[c_depto]]))
  a <- suppressWarnings(as.integer(x[[c_anno]]))
  x[!is.na(d) & d == 5L & !is.na(a) & a == 2025L, , drop = FALSE]
}

antioquia <- readr::read_delim_chunked(
  ruta, delim = sep,
  callback = readr::DataFrameCallback$new(recorte),
  chunk_size = 200000,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE, progress = FALSE) |>
  as.data.frame() |>
  dplyr::rename(ind_mpio = dplyr::all_of(c_mpio))

# Vuelven a número las columnas que lo son; el resto (empresa, municipio,
# tecnología, velocidades) se queda como texto. a_numero() es el conversor del
# pipeline y ya resuelve los separadores locales ("1.234,5" o "1,234.5").
NUMERICAS <- c("anno", "trimestre", "id_empresa", "ind_mpio", "id_departamento",
               "id_segmento", "id_servicio_paquete", "id_tecnologia", "id_estado",
               "cantidad_lineas_accesos", "valor_facturado_o_cobrado",
               "otros_valores_facturados", "valor_total_plan_tarifario")
for (v in intersect(NUMERICAS, names(antioquia))) {
  antioquia[[v]] <- a_numero(antioquia[[v]])
}
antioquia$ind_mpio <- as.integer(antioquia$ind_mpio)

if (nrow(antioquia) == 0) {
  stop("No quedaron registros de Antioquia (departamento 5) para 2025 en ",
       basename(ruta), ". Verifique que el archivo corresponda al año esperado.",
       call. = FALSE)
}

escribir_derivado(antioquia, "infraestructura_internet_2025")
message("  infraestructura_internet_2025: ", nrow(antioquia), " registros",
        "  (separador «", sep, "»)")
