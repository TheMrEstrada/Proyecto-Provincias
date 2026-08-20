# =============================================================================
# 02_demografia.R — Sección 2: Demografía
#
# TABLAS (hojas del .xlsx de la sección):
#   poblacion             proyecciones 2025 por área (total/cabecera/rural),
#                         participaciones en el total provincial y densidad
#   estructura_edad       población por sexo y por grupos decenales de edad
#   natalidad_mortalidad  tasas de natalidad y mortalidad e índice de
#                         envejecimiento
#   migracion             tasa neta de migración (total, cabecera, rural)
#
# INPUTS:  01_Data/00_Inputs/POBLACION MUNICIPAL.xlsx
#            (hoja 1 "Total_Municipios", solo como respaldo si falta el derivado)
#          01_Data/01_Derived/poblacion_edad_2025.dta  (estructura por edad y
#            los grupos 0-14 y 65+ del índice de envejecimiento)
#          01_Data/00_Inputs/AREA_ORIGINAL.xlsx  (hoja "Area")
#          01_Data/00_Inputs/INDICADORES ECV 2023 MUNICIPIOS.xlsx
#            (hoja "DEMOGRAFÍA", indicador TNM)
#          01_Data/01_Derived/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.dta
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/02_Demografia/demografia.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/02_Demografia.do
#
# NOTA METODOLÓGICA: los agregados (provincia, subregión, departamento) de las
# TASAS son promedios PONDERADOS por población — sum(tasa_i * pob_i) /
# sum(pob_i) —, no promedios simples. Las poblaciones y las áreas sí se suman.
#
# El ÍNDICE DE ENVEJECIMIENTO no se pondera: es una razón entre dos conteos, así
# que se suman el numerador (65 y más) y el denominador (0 a 14) y se recalcula
# sobre las sumas, como manda la regla 6 del anexo. Su fórmula es la estándar
# —DANE, CEPAL, Naciones Unidas—: 65 y más por cada cien de 0 a 14. Hasta la
# corrección 16 se leía de un curado cuya fórmula no estaba en el repositorio
# (F-2-015).
#
# FUENTE DE POBLACIÓN — desviación deliberada respecto del .do:
# El .do lee POBLACION MUNICIPAL.xlsx, pero esa serie NO es la que se publicó.
# El informe salió de la serie PPED 2018-2042, cuyo derivado sí está versionado
# (01_Derived/poblacion_total_2025.dta). Comprobado municipio a municipio: con
# la serie PPED se reproduce el Anexo 1 en las seis columnas de población y en
# la densidad; con POBLACION MUNICIPAL.xlsx las cifras difieren entre −3 % y
# +10 % por municipio (Yarumal 44.770 vs 41.884 publicados).
# Se usa la serie publicada, porque el pipeline debe poder rehacer el informe.
# Si el derivado no está, se cae a POBLACION MUNICIPAL.xlsx y se avisa.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Insumos compartidos por varias hojas ------------------------------------

#' Categoría de área geográfica → nombre de columna del pipeline.
.area_a_columna <- function(x) {
  dplyr::case_when(
    x == "Total"                             ~ "habitantes_total",
    x == "Cabecera Municipal"                ~ "habitantes_cabecera",
    x == "Centros Poblados y Rural Disperso" ~ "habitantes_rural",
    TRUE                                     ~ NA_character_
  )
}

#' Población municipal 2025 de todo el departamento, una fila por municipio y
#' una columna por área geográfica (total, cabecera, resto rural).
#'
#' Usa la serie PPED, que es la que se publicó en el informe (ver la nota de la
#' cabecera). Si ese derivado no está, cae a POBLACION MUNICIPAL.xlsx avisando
#' de que las cifras no coincidirán con el Anexo 1.
.poblacion_2025 <- function() {
  if (existe_derivado("poblacion_total_2025")) {
    d <- leer_derivado("poblacion_total_2025")
    c_cod  <- col_req(d, "ind_mpio")
    c_ano  <- col_req(d, "año", "anio", "ano")
    c_area <- col_req(d, "area_geo")
    c_pob  <- col_req(d, "Total")
  } else {
    warning("No está el derivado poblacion_total_2025; se usa ",
            "POBLACION MUNICIPAL.xlsx, cuya serie NO reproduce el Anexo 1.",
            call. = FALSE)
    d <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = 1)
    c_cod  <- col_req(d, "DPMP")
    c_ano  <- col_req(d, "AÑO")
    c_area <- col_req(d, "ÁREA GEOGRÁFICA")
    c_pob  <- col_req(d, "Total General")
  }

  d |>
    dplyr::filter(a_numero(.data[[c_ano]]) == 2025) |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      area_cat = .area_a_columna(as.character(.data[[c_area]])),
      habitantes = a_numero(.data[[c_pob]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$area_cat)) |>
    tidyr::pivot_wider(names_from = "area_cat", values_from = "habitantes")
}

#' Área municipal en km² de todo el departamento (para la densidad).
.area_municipal <- function() {
  a <- leer_excel(entrada("AREA_ORIGINAL.xlsx"), hoja = "Area")
  c_cod  <- col_req(a, "COD_MPIO", "ind_mpio")
  c_area <- col_req(a, "AREA KM2", "AREAKM2", "area_km2")
  a |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      area_km2 = a_numero(.data[[c_area]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio))
}

#' Renombra las filas agregadas para dejar explícito que son promedios
#' ponderados por población, como en el .do original.
.marcar_ponderado <- function(datos) {
  dplyr::mutate(datos, municipio = ifelse(
    .data$tipo_fila == "Municipio",
    .data$municipio,
    paste0(stringr::str_replace(.data$municipio, "^TOTAL ", "PROMEDIO PONDERADO "),
           " (tasas por población; índice sobre las sumas)")
  ))
}

# Los grupos decenales que publica el informe. El derivado poblacion_edad_2025
# ya trae una columna por grupo y sexo; esta lista define el orden y los
# nombres con los que salen a la hoja.
.GRUPOS <- c("edad_0_9", "edad_10_19", "edad_20_29", "edad_30_39", "edad_40_49",
             "edad_50_59", "edad_60_69", "edad_70_79", "edad_80_mas")
.BANDAS <- c("0 a 9", "10 a 19", "20 a 29", "30 a 39", "40 a 49", "50 a 59",
             "60 a 69", "70 a 79", "80 o más")

# --- Hoja 1: población, participaciones y densidad ---------------------------

.hoja_poblacion <- function(prov, archivo) {
  universo <- .poblacion_2025() |>
    dplyr::left_join(.area_municipal(), by = "ind_mpio") |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  habitantes_total, habitantes_cabecera, habitantes_rural,
                  area_km2)

  # Denominadores provinciales (fijos: son los de la provincia, no de la fila)
  prov_total    <- sum(municipios$habitantes_total, na.rm = TRUE)
  prov_cabecera <- sum(municipios$habitantes_cabecera, na.rm = TRUE)
  prov_rural    <- sum(municipios$habitantes_rural, na.rm = TRUE)

  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov,
    columnas = c("habitantes_total", "habitantes_cabecera", "habitantes_rural",
                 "area_km2"),
    como = "suma"
  ) |>
    dplyr::mutate(
      densidad_pob = .data$habitantes_total / .data$area_km2,
      pct_cabecera = .data$habitantes_cabecera / .data$habitantes_total,
      pct_rural    = .data$habitantes_rural / .data$habitantes_total,
      # La participación tiene como denominador la provincia: para las filas de
      # subregión y departamento no está definida y queda vacía.
      part_total_prov = dplyr::case_when(
        .data$tipo_fila == "Municipio"       ~ .data$habitantes_total / prov_total,
        .data$tipo_fila == "Total provincia" ~ 1,
        TRUE                                 ~ NA_real_
      ),
      part_cab_prov = dplyr::case_when(
        .data$tipo_fila == "Municipio"       ~ .data$habitantes_cabecera / prov_cabecera,
        .data$tipo_fila == "Total provincia" ~ 1,
        TRUE                                 ~ NA_real_
      ),
      part_rural_prov = dplyr::case_when(
        .data$tipo_fila == "Municipio"       ~ .data$habitantes_rural / prov_rural,
        .data$tipo_fila == "Total provincia" ~ 1,
        TRUE                                 ~ NA_real_
      )
    ) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  habitantes_total, part_total_prov,
                  habitantes_cabecera, pct_cabecera, part_cab_prov,
                  habitantes_rural, pct_rural, part_rural_prov,
                  densidad_pob, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "poblacion",
    etiquetas = c(
      ind_mpio            = "Código DANE",
      municipio           = "Municipio",
      subregion           = "Subregión",
      provincia           = "Provincia",
      habitantes_total    = "Población total",
      part_total_prov     = "Participación en el total provincial (%)",
      habitantes_cabecera = "Población urbana",
      pct_cabecera        = "Porcentaje de población urbana",
      part_cab_prov       = "Participación urbana en el total provincial (%)",
      habitantes_rural    = "Población rural",
      pct_rural           = "Porcentaje de población rural",
      part_rural_prov     = "Participación rural en el total provincial (%)",
      densidad_pob        = "Densidad poblacional (hab/km²)"
    ),
    formatos = c(
      habitantes_total = "#,##0", habitantes_cabecera = "#,##0",
      habitantes_rural = "#,##0", part_total_prov = "0.0%",
      pct_cabecera = "0.0%", part_cab_prov = "0.0%",
      pct_rural = "0.0%", part_rural_prov = "0.0%",
      densidad_pob = "#,##0.0"
    )
  )

  tabla
}

# --- Hoja 2: estructura por sexo y grupos de edad ----------------------------

.hoja_estructura_edad <- function(prov, archivo) {
  # Desde la serie PPED, que es la que publica el informe. Antes esta hoja se
  # construía con POBLACION MUNICIPAL.xlsx —la serie que la cabecera de este
  # mismo archivo declara descartada—, de modo que la estructura por edad no
  # sumaba la población de la hoja anterior del mismo libro.
  base <- leer_derivado("poblacion_edad_2025") |>
    dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio)) |>
    dplyr::select(-dplyr::any_of("nvl_label"))

  columnas <- c("pob_masc", "pob_fem", .GRUPOS,
                stringr::str_replace(.GRUPOS, "^edad", "h_edad"),
                stringr::str_replace(.GRUPOS, "^edad", "m_edad"))

  municipios <- base |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, dplyr::all_of(columnas))

  # Solo total provincial: el informe no publica la estructura de edad de la
  # subregión ni del departamento.
  tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                           columnas = columnas, como = "suma") |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas), tipo_fila)

  etiquetas <- c(
    ind_mpio = "Código DANE", municipio = "Municipio",
    subregion = "Subregión", provincia = "Provincia",
    pob_masc = "Población masculina", pob_fem = "Población femenina"
  )
  etiquetas <- c(
    etiquetas,
    stats::setNames(.BANDAS, .GRUPOS),
    stats::setNames(paste("Hombres", .BANDAS),
                    stringr::str_replace(.GRUPOS, "^edad", "h_edad")),
    stats::setNames(paste("Mujeres", .BANDAS),
                    stringr::str_replace(.GRUPOS, "^edad", "m_edad"))
  )

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "estructura_edad",
    etiquetas = etiquetas,
    formatos  = stats::setNames(rep("#,##0", length(columnas)), columnas)
  )

  tabla
}

# --- Hoja 3: natalidad, mortalidad e índice de envejecimiento ----------------

.hoja_natalidad_mortalidad <- function(prov, archivo, pesos) {
  vitales <- leer_derivado("20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA") |>
    dplyr::transmute(
      ind_mpio        = as.integer(.data$ind_mpio),
      tasa_natalidad  = as.numeric(.data$tasa_natalidad),
      tasa_mortalidad = as.numeric(.data$tasa_mortalidad)
    )
  # El índice de envejecimiento se calcula AQUÍ, desde el derivado del PPED, y
  # ya no se lee del curado poblacion_municipal_total_2025_dicc.dta, cuya
  # fórmula no está en ninguna parte del repositorio (F-2-015). El curado además
  # parte de otra estructura de edad: la población total coincide en los 125
  # municipios pero el reparto por edad no, y describe una población
  # sistemáticamente más envejecida. Desde la corrección 7 la pirámide de esta
  # misma sección sale del PPED, así que el índice la contradecía.
  #
  # La fórmula es la estándar —DANE, CEPAL, Naciones Unidas—: personas de 65 y
  # más por cada cien de 0 a 14. El curado usaba como denominador la población
  # DEPENDIENTE (0-14 más 60 y más), que ninguna fuente externa emplea y que
  # dejaba la cifra publicada en torno a la mitad de la comparable.
  edades <- leer_derivado("poblacion_edad_2025") |>
    dplyr::transmute(
      ind_mpio    = as.integer(.data$ind_mpio),
      edad_65_mas = as.numeric(.data$edad_65_mas),
      edad_0_14   = as.numeric(.data$edad_0_14)
    )

  universo <- vitales |>
    dplyr::left_join(edades, by = "ind_mpio") |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    con_territorio()

  # Las dos tasas vitales se ponderan por población, que es su denominador. El
  # índice NO: es una razón entre dos conteos, así que se agregan los conteos y
  # se recalcula sobre las sumas (regla 6 del anexo). Ponderar por población
  # total —que no es el denominador de ninguna de las dos puntas— habría
  # repetido el error que la corrección 4 quitó de la leishmaniasis.
  columnas <- c("tasa_natalidad", "tasa_mortalidad", "edad_65_mas", "edad_0_14")

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, habitantes_total,
                  dplyr::all_of(columnas))

  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov, columnas = columnas,
    como = list(tasa_natalidad = "promedio_ponderado",
                tasa_mortalidad = "promedio_ponderado",
                edad_65_mas = "suma", edad_0_14 = "suma"),
    pesos = "habitantes_total"
  ) |>
    dplyr::mutate(I_enve_T = .data$edad_65_mas / .data$edad_0_14 * 100) |>
    .marcar_ponderado() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  "tasa_natalidad", "tasa_mortalidad", "I_enve_T", tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "natalidad_mortalidad",
    etiquetas = c(
      ind_mpio = "Código DANE", municipio = "Municipio",
      subregion = "Subregión", provincia = "Provincia",
      tasa_natalidad = "Tasa de Natalidad", tasa_mortalidad = "Tasa de Mortalidad",
      I_enve_T = "Índice de Envejecimiento"
    ),
    formatos = c(tasa_natalidad = "0.00", tasa_mortalidad = "0.00",
                 I_enve_T = "0.00")
  )

  tabla
}

# --- Hoja 4: tasa neta de migración (ECV 2023) -------------------------------

.hoja_migracion <- function(prov, archivo, pesos) {
  d <- leer_excel(entrada("INDICADORES ECV 2023 MUNICIPIOS.xlsx"), hoja = "DEMOGRAFÍA")
  c_ind <- col_req(d, "Indicador")
  c_cod <- col_req(d, "Municipio")
  c_tot <- col_req(d, "Valor_tot")
  c_urb <- col_req(d, "Valor_urb")
  c_rur <- col_req(d, "Valor_rur")

  universo <- d |>
    dplyr::filter(.data[[c_ind]] == "TNM") |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      tot_tnm  = a_numero(.data[[c_tot]]),
      urb_tnm  = a_numero(.data[[c_urb]]),
      rur_tnm  = a_numero(.data[[c_rur]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    dplyr::inner_join(pesos, by = "ind_mpio") |>
    con_territorio()

  columnas <- c("tot_tnm", "urb_tnm", "rur_tnm")

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, habitantes_total,
                  dplyr::all_of(columnas))

  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "habitantes_total"
  ) |>
    .marcar_ponderado() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas), tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "migracion",
    etiquetas = c(
      ind_mpio = "Código DANE", municipio = "Municipio",
      subregion = "Subregión", provincia = "Provincia",
      tot_tnm = "Tasa neta de migración - total",
      urb_tnm = "Tasa neta de migración - cabecera municipal",
      rur_tnm = "Tasa neta de migración - centros poblados y rural"
    ),
    formatos = c(tot_tnm = "0.00", urb_tnm = "0.00", rur_tnm = "0.00")
  )

  tabla
}

# --- Punto de entrada ---------------------------------------------------------

tabla_demografia <- function(prov) {
  message("== 02 Demografía — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "02_Demografia"), "demografia.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  # Peso poblacional de las tasas: población total municipal 2025 de TODOS los
  # municipios (también los que no pertenecen a ninguna provincia).
  pesos <- .poblacion_2025() |>
    dplyr::select(ind_mpio, habitantes_total)

  resultado <- list(
    poblacion            = .hoja_poblacion(prov, archivo),
    estructura_edad      = .hoja_estructura_edad(prov, archivo),
    natalidad_mortalidad = .hoja_natalidad_mortalidad(prov, archivo, pesos),
    migracion            = .hoja_migracion(prov, archivo, pesos)
  )

  message("  02 Demografía: ", length(resultado), " hojas en ", basename(archivo))
  invisible(resultado)
}
