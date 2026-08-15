# =============================================================================
# ecv_oficial_agregados.R — Agregados OFICIALES de la ECV 2023
#
# Los totales de subregión, provincia y departamento que publica el DANE, para
# usarlos tal cual en el diagnóstico en vez de promediar las estimaciones
# municipales (que no son aditivas).
#
# INPUTS:
#   01_Data/00_Inputs/Indicadores_ECV2023.xlsx   (salida oficial ECV, formato
#     largo, encabezados en la fila 14; NO versionado: ver .gitignore)
# OUTPUTS:
#   01_Data/01_Derived/ECV_oficial_agregados.dta
#     (una fila por nivel x territorio; una columna por indicador y zona)
#
# NIVELES y clave de cruce (`key`):
#   SUBREGION    -> nombre en MAYÚSCULAS, como en códigos_municipios_clean.dta
#   PROVINCIA    -> id_provincia (texto); solo 6 provincias tienen dato oficial
#   DEPARTAMENTO -> "ANTIOQUIA"
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do
#
# El insumo no cabe en el repositorio. Si falta, este script se detiene con un
# mensaje claro y el resto del pipeline sigue: la sección que lo usa trabaja
# con el derivado ya generado.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== ECV 2023, agregados oficiales ==")

ruta <- entrada("Indicadores_ECV2023.xlsx")   # aborta con mensaje si no está

# Los encabezados están en la fila 14 (el Excel trae 13 filas de portada).
datos <- leer_excel(ruta, hoja = "Sheet1", saltar = 13)

c_terr <- col_req(datos, "Territorio")
c_ind  <- col_req(datos, "NomIndicador")
c_val  <- col_req(datos, "Valor")
c_zona <- col_req(datos, "Zona")
c_tipo <- col_req(datos, "Tipo")

# --- Indicadores de interés: nombre largo -> nombre corto del flujo -----------
RENOMBRE_AGR <- c(
  # Gini: índice 0-1, NO se divide por 100
  "Gini: Ingresos de los hogares"                       = "gini_hog",
  "Gini: Ingresos laborales de las personas ocupadas"   = "gini_lab",
  # Pobreza (%)
  "Porcentaje de personas en condición de pobreza por NBI" = "pob_nbi",
  "Porcentaje de personas pobres - IPM"                 = "pob_ipm",
  "Porcentaje de hogares pobres - IPM"                  = "pob_ipm_hogares",
  # Mercado laboral (%)
  "Tasa de ocupación"                                   = "to",
  "Tasa de empleo informal"                             = "emp_informal",
  "Tasa de desocupados"                                 = "td",
  "Tasa de desocupados para personas entre 15 y 28 años" = "td_15_28",
  "Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados" = "nini",
  # Coberturas de servicios públicos (% de viviendas), para la sección 03
  "Porcentaje de viviendas con SP Energía"              = "pob_energia",
  "Porcentaje de viviendas con SP Acueducto"            = "pob_acueducto",
  "Porcentaje de viviendas con SP Alcantarillado"       = "pob_alcantarillado",
  "Porcentaje de viviendas con SP Recolección Basuras"  = "pob_recoleccion_basuras",
  "Porcentaje de viviendas con servicio de internet"    = "pob_internet",
  "Porcentaje de viviendas con servicio de gas natural por red" = "pob_gas_natural"
)

# Todo lo que viene en porcentaje pasa a fracción 0-1, que es la escala del
# flujo. Los dos Gini ya son un índice 0-1 y se dejan como están.
SIN_ESCALAR <- c("gini_hog", "gini_lab")

# --- Zona y nivel territorial -------------------------------------------------
ZONAS   <- c("total" = "tot", "urbano" = "urb", "rural" = "rur")
NIVELES <- c("region" = "SUBREGION", "provincia" = "PROVINCIA")   # "Departamento*" aparte

# --- Clave de cruce por territorio -------------------------------------------
CLAVE_SUBREGION <- c(
  "bajo cauca"          = "BAJO CAUCA",
  "magdalena medio"     = "MAGDALENA MEDIO",
  "nordeste"            = "NORDESTE",
  "norte"               = "NORTE",
  "occidente"           = "OCCIDENTE",
  "oriente"             = "ORIENTE",
  "suroeste"            = "SUROESTE",
  "uraba"               = "URABA",
  "area metropolitana"  = "VALLE DE ABURRA"
)

CLAVE_PROVINCIA <- c(
  "provincia del agua, bosques y turismo"                              = "5",
  "provincia cartama"                                                  = "6",
  "provincia de la paz"                                                = "7",
  "provincia de san juan"                                              = "8",
  "provincia minero agroecologica en el departamento de antioquia"     = "9",
  "provincia de penderisco y sinifana"                                 = "10"
)

# --- Selección y recodificación ----------------------------------------------
.dicc <- stats::setNames(unname(RENOMBRE_AGR), norm_txt(names(RENOMBRE_AGR)))

largo <- datos |>
  dplyr::transmute(
    terr_label = as.character(.data[[c_terr]]),
    terr_clave = norm_txt(as.character(.data[[c_terr]])),
    ind        = unname(.dicc[norm_txt(as.character(.data[[c_ind]]))]),
    valor      = a_numero(.data[[c_val]]),
    z          = unname(ZONAS[norm_txt(as.character(.data[[c_zona]]))]),
    tipo       = norm_txt(as.character(.data[[c_tipo]]))
  ) |>
  dplyr::filter(!is.na(ind), !is.na(z)) |>
  dplyr::mutate(
    valor = ifelse(ind %in% SIN_ESCALAR, valor, valor / 100),
    nivel = dplyr::case_when(
      stringr::str_detect(tipo, "departamento") ~ "DEPARTAMENTO",
      tipo %in% names(NIVELES)                  ~ unname(NIVELES[tipo]),
      TRUE                                      ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(nivel)) |>
  dplyr::mutate(
    key = dplyr::case_when(
      nivel == "DEPARTAMENTO"                 ~ "ANTIOQUIA",
      nivel == "SUBREGION"                    ~ unname(CLAVE_SUBREGION[terr_clave]),
      nivel == "PROVINCIA"                    ~ unname(CLAVE_PROVINCIA[terr_clave]),
      TRUE                                    ~ NA_character_
    ),
    col = paste0(z, "_", ind)
  ) |>
  dplyr::filter(!is.na(key))

if (nrow(largo) == 0) {
  stop("No quedó ningún agregado oficial tras filtrar indicadores, zonas y niveles en ",
       basename(ruta), ". Verifique que el archivo sea la salida oficial de la ECV 2023.",
       call. = FALSE)
}

# --- Formato ancho ------------------------------------------------------------
# El promedio es la salvaguarda del .do por si la fuente repite un territorio;
# con datos consistentes cada combinación aparece una sola vez.
ancho <- largo |>
  dplyr::group_by(nivel, key, terr_label, col) |>
  dplyr::summarise(valor = mean(valor, na.rm = TRUE), .groups = "drop") |>
  tidyr::pivot_wider(id_cols = c(nivel, key, terr_label),
                     names_from = col, values_from = valor)

columnas <- sort(setdiff(names(ancho), c("nivel", "key", "terr_label")), method = "radix")

ancho <- ancho |>
  dplyr::select(nivel, key, terr_label, dplyr::all_of(columnas)) |>
  dplyr::arrange(nivel, key, terr_label) |>
  as.data.frame()

# --- Verificaciones -----------------------------------------------------------
niveles_hallados <- unique(ancho$nivel)
faltantes <- setdiff(c("DEPARTAMENTO", "PROVINCIA", "SUBREGION"), niveles_hallados)
if (length(faltantes)) {
  message("  [aviso] sin datos oficiales para el nivel: ", paste(faltantes, collapse = ", "))
}
stopifnot("hay territorios duplicados" = !any(duplicated(ancho[, c("nivel", "key")])))

escribir_derivado(ancho, "ECV_oficial_agregados")
message("  ECV_oficial_agregados.dta: ", nrow(ancho), " territorios x ",
        length(columnas), " columnas de indicador")
