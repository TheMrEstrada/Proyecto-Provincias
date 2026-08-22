# =============================================================================
# suicidios_actualizado_2022_2024.R — Suicidio consumado e intento, 2022-2024
#
# El tablero curado suicidios_e_intentos_medias_dicc.dta (ver
# 01_homogeneizacion/externos/suicidios_e_intentos_medias.R) promedia 2021-2023
# con la misma fórmula que aquí: tasa = Σcasos / Σpoblación x 100 mil. Este
# script reproduce EXACTAMENTE esa lógica con la ventana siguiente,
# 2022-2024, porque las fuentes disponibles solo traen un año a la vez (no hay
# equivalente al bloque multi-año de "enfermedades tropicales"):
#   - Suicidio consumado (DANE, Cuadro 15 de defunciones por causas externas):
#     causa "511 Lesiones autoinfligidas intencionalmente (suicidios)".
#   - Intento de suicidio (SIVIGILA, evento 356): un registro por caso.
#
# Es DELIBERADAMENTE un derivado aparte, no un reemplazo del tablero curado
# (mismo criterio que salud_actualizada_2024.R): entra a la tabla de salud
# como una hoja nueva (suicidios_2022_2024), al lado de "suicidios"
# (2021-2023), para poder comparar antes de decidir si la reemplaza.
#
# ATRIBUCIÓN DEL CASO — decisión de Laura Peña (2026-08-21):
#   - Suicidio consumado: "municipio de ocurrencia", tal como lo etiqueta la
#     fuente DANE (no hay otra columna posible: el Cuadro 15 solo trae esa).
#   - Intento de suicidio: municipio de RESIDENCIA del paciente (COD_MUN_R),
#     el estándar de vigilancia epidemiológica del INS/SIVIGILA para perfiles
#     municipales — no el de ocurrencia (donde fue atendido) ni el de
#     notificación (la unidad que reportó el caso).
#
# POBLACIÓN: se usa la misma población 2025 (poblacion_total_2025, ver
# 09_salud.R:.pesos_poblacion()) para los tres años, porque no existe una
# serie anual sin abrir PPED-AreaSexoEdadMun-2018-2042_VP.xlsx — insumo que,
# por decisión explícita, este pipeline nunca vuelve a abrir (ver
# 01_homogeneizacion/poblacion_municipal.R, cabecera). Esta hoja solo
# necesita los CASOS: la tasa se calcula en 09_salud.R con la misma
# población que ya usan las demás hojas de esta sección.
#
# INPUTS:  01_Data/00_Inputs/DATOS SALUD.xlsx
#            hojas "suicidio2022", "suicidio" (=2023), "suicidio2024"
#          01_Data/00_Inputs/Intento_suicidio_SIVIGILA_2022.xlsx  (hoja "Datos")
#          01_Data/00_Inputs/DATOS SALUD.xlsx, hoja "intento_suicidio" (=2023)
#          01_Data/00_Inputs/Intento_suicidio_SIVIGILA.xlsx       (hoja "Datos", =2024)
#          01_Data/00_Inputs/códigos_municipios_clean.dta (universo de 125 municipios)
# OUTPUTS: 01_Data/01_Derived/suicidios_actualizado_2022_2024.parquet
#          (125 filas x 7 columnas: ind_mpio + casos de suicidio e intento,
#          2022/2023/2024)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== suicidios e intentos actualizado (2022-2024) ==")

.municipios_125_su <- haven::read_dta(entrada("códigos_municipios_clean.dta")) |>
  dplyr::transmute(ind_mpio = as.integer(ind_mpio))

# --- Suicidio consumado (DANE) -------------------------------------------------
# Cuadro 15: un bloque de filas por municipio (nombre solo en la primera fila
# del bloque, arrastrado hacia abajo) y, dentro de cada bloque, una fila por
# causa externa. Se toma la fila "511 Lesiones autoinfligidas intencionalmente
# (suicidios)"; un municipio sin esa fila tuvo cero casos (la fuente omite las
# causas en cero, no las deja en blanco).
CAUSA_SUICIDIO <- "511 Lesiones autoinfligidas intencionalmente (suicidios)"

.dane_suicidios <- function(hoja, anio) {
  crudo <- readxl::read_excel(entrada("DATOS SALUD.xlsx"), sheet = hoja,
                              col_names = FALSE, .name_repair = "minimal") |>
    as.data.frame(stringsAsFactors = FALSE)

  municipio <- as.character(crudo[[4]])
  # Arrastre hacia abajo: solo la primera fila de cada bloque trae el nombre.
  for (i in seq_along(municipio)[-1]) {
    if (is.na(municipio[i])) municipio[i] <- municipio[i - 1]
  }
  codigo <- stringr::str_extract(municipio, "^\\d{5}")
  causa  <- as.character(crudo[[5]])
  total  <- a_numero(crudo[[6]])

  # El código del Cuadro 15 ya distingue Antioquia (05xxx); la hoja de 2022
  # trae el total nacional, las de 2023/2024 ya vienen filtradas, pero el
  # filtro se aplica siempre por si acaso.
  tabla <- data.frame(
    ind_mpio = as.integer(codigo[!is.na(codigo) & stringr::str_starts(codigo, "05") &
                                  causa == CAUSA_SUICIDIO]),
    casos    = total[!is.na(codigo) & stringr::str_starts(codigo, "05") &
                        causa == CAUSA_SUICIDIO]
  )
  if (any(duplicated(tabla$ind_mpio))) {
    stop("Hay municipios duplicados en suicidios DANE ", anio, ".", call. = FALSE)
  }
  names(tabla)[2] <- paste0("suicidios_casos_", anio)
  message("  suicidio consumado ", anio, ": ", nrow(tabla),
          " municipios con al menos 1 caso")
  tabla
}

# --- Intento de suicidio (SIVIGILA) --------------------------------------------
# Un registro por caso; se cuentan por municipio de RESIDENCIA (COD_MUN_R),
# el estándar SIVIGILA/INS para perfiles municipales (ver cabecera).

.sivigila_intentos <- function(ruta, hoja, anio) {
  crudo <- readxl::read_excel(ruta, sheet = hoja, col_types = "text")

  antioquia <- crudo[!is.na(crudo$COD_DPTO_R) & crudo$COD_DPTO_R == "05", ,
                     drop = FALSE]
  tabla <- antioquia |>
    dplyr::filter(!is.na(.data$COD_MUN_R), nzchar(.data$COD_MUN_R)) |>
    dplyr::count(.data$COD_MUN_R, name = "casos") |>
    dplyr::transmute(ind_mpio = as.integer(paste0("05", .data$COD_MUN_R)),
                     casos    = .data$casos)

  if (any(duplicated(tabla$ind_mpio))) {
    stop("Hay municipios duplicados en intentos SIVIGILA ", anio, ".", call. = FALSE)
  }
  names(tabla)[2] <- paste0("intentos_casos_", anio)
  message("  intento de suicidio (SIVIGILA) ", anio, ": ", nrow(tabla),
          " municipios con al menos 1 caso, ", nrow(antioquia), " registros de Antioquia")
  tabla
}

# --- Unir y guardar -------------------------------------------------------------

suicidios_actualizado_2022_2024 <- .municipios_125_su |>
  dplyr::left_join(.dane_suicidios("suicidio2022", 2022), by = "ind_mpio") |>
  dplyr::left_join(.dane_suicidios("suicidio",     2023), by = "ind_mpio") |>
  dplyr::left_join(.dane_suicidios("suicidio2024", 2024), by = "ind_mpio") |>
  dplyr::left_join(
    .sivigila_intentos(entrada("Intento_suicidio_SIVIGILA_2022.xlsx"), "Datos", 2022),
    by = "ind_mpio") |>
  dplyr::left_join(
    .sivigila_intentos(entrada("DATOS SALUD.xlsx"), "intento_suicidio", 2023),
    by = "ind_mpio") |>
  dplyr::left_join(
    .sivigila_intentos(entrada("Intento_suicidio_SIVIGILA.xlsx"), "Datos", 2024),
    by = "ind_mpio") |>
  dplyr::mutate(dplyr::across(-"ind_mpio", ~ tidyr::replace_na(.x, 0)))

stopifnot(
  "hay municipios duplicados" = !any(duplicated(suicidios_actualizado_2022_2024$ind_mpio)),
  "no son 125 municipios" = nrow(suicidios_actualizado_2022_2024) == 125
)

escribir_derivado(suicidios_actualizado_2022_2024, "suicidios_actualizado_2022_2024")

message("  suicidios_actualizado_2022_2024: ", nrow(suicidios_actualizado_2022_2024),
        " municipios x ", ncol(suicidios_actualizado_2022_2024), " columnas")
