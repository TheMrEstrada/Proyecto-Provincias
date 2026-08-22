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
# INPUTS:  01_Data/01_Derived/poblacion_total_2025.dta      (hoja "poblacion")
#          01_Data/01_Derived/poblacion_edad_2025.dta   (hoja "estructura_edad")
#          01_Data/01_Derived/poblacion_municipal_total_2025.dta
#            (índice de envejecimiento, hoja "natalidad_mortalidad")
#          01_Data/00_Inputs/POBLACION MUNICIPAL.xlsx
#            (solo si falta el derivado poblacion_total_2025 — ver la NOTA
#            "FUENTE DE POBLACIÓN" más abajo)
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
# TASAS y del ÍNDICE de envejecimiento son promedios PONDERADOS por población
# — sum(tasa_i * pob_i) / sum(pob_i) —, no promedios simples. Las poblaciones y
# las áreas sí se suman.
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

#' Suma un conjunto de tramos quinquenales de la hoja Rangos_Quintenios.
#' `prefijo` es "Hombre", "Mujeres" o "TOTAL"; `tramos` los rótulos "0-4", …
#' Solo la usa el respaldo de .hoja_estructura_edad() cuando falta el
#' derivado poblacion_edad_2025 (ver esa función).
.suma_tramos <- function(d, prefijo, tramos) {
  columnas <- vapply(tramos, function(t) col_req(d, paste0(prefijo, " (", t, ")")),
                     character(1))
  Reduce(`+`, lapply(columnas, function(cl) a_numero(d[[cl]])))
}

#' Renombra las filas agregadas para dejar explícito que son promedios
#' ponderados por población, como en el .do original.
.marcar_ponderado <- function(datos) {
  dplyr::mutate(datos, municipio = ifelse(
    .data$tipo_fila == "Municipio",
    .data$municipio,
    paste0(stringr::str_replace(.data$municipio, "^TOTAL ", "PROMEDIO PONDERADO "),
           " (por población)")
  ))
}

# Los grupos decenales que publica la sección, en el orden del informe.
# Los índices son sobre .TRAMOS (los rótulos de POBLACION MUNICIPAL.xlsx,
# hoja Rangos_Quintenios): los usa el respaldo de .hoja_estructura_edad()
# cuando falta el derivado poblacion_edad_2025. El camino preferido lee
# directamente las columnas del mismo nombre de ese derivado, para el que
# solo hacen falta los nombres. Hallazgo de Pablo (F-2-018).
.TRAMOS <- c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39",
             "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74",
             "75-79", "80-84", "85 y más")
.GRUPOS <- list(
  edad_0_9 = 1:2, edad_10_19 = 3:4, edad_20_29 = 5:6, edad_30_39 = 7:8,
  edad_40_49 = 9:10, edad_50_59 = 11:12, edad_60_69 = 13:14,
  edad_70_79 = 15:16, edad_80_mas = 17:18
)
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
  # POBLACION MUNICIPAL.xlsx es la serie descartada (ver nota de cabecera):
  # esta hoja contradecía a la hoja "poblacion" del mismo libro (Yarumal
  # 44.770 aquí vs. 41.884 allá). Se prefiere el derivado que arma la misma
  # estructura decenal desde el PPED. Hallazgo de Pablo (F-2-018), adoptado
  # también aquí.
  #
  # poblacion_edad_2025 se arma con el insumo PPED, que pesa 131 MB, no está
  # versionado y no cabe en este entorno (ver poblacion_municipal.R). Si
  # nadie lo ha generado todavía, se cae a POBLACION MUNICIPAL.xlsx —la
  # serie vieja, con el mismo aviso que ya usa .poblacion_2025()— para que
  # el pipeline pueda correr hoy. En cuanto alguien corra
  # poblacion_municipal.R con el insumo disponible, esta hoja empieza a usar
  # la serie correcta sin que haga falta tocar nada más.
  if (existe_derivado("poblacion_edad_2025")) {
    base <- leer_derivado("poblacion_edad_2025") |>
      dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio)) |>
      dplyr::select(-dplyr::any_of("nvl_label"))
  } else {
    warning("No está el derivado poblacion_edad_2025; se usa ",
            "POBLACION MUNICIPAL.xlsx, cuya serie NO reproduce el Anexo 1 ",
            "(Yarumal 44.770 vs. 41.884 publicados).", call. = FALSE)
    d <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = "Rangos_Quintenios")
    c_cod  <- col_req(d, "DPMP")
    c_ano  <- col_req(d, "AÑO")
    c_area <- col_req(d, "ÁREA GEOGRÁFICA")
    d <- d |>
      dplyr::filter(a_numero(.data[[c_ano]]) == 2025, .data[[c_area]] == "Total")

    base <- data.frame(ind_mpio = as.integer(a_numero(d[[c_cod]])))
    base$pob_masc <- .suma_tramos(d, "Hombre", .TRAMOS)
    base$pob_fem  <- .suma_tramos(d, "Mujeres", .TRAMOS)
    for (g in names(.GRUPOS)) {
      tramos <- .TRAMOS[.GRUPOS[[g]]]
      base[[g]]                                  <- .suma_tramos(d, "TOTAL", tramos)
      base[[stringr::str_replace(g, "^edad", "h_edad")]] <- .suma_tramos(d, "Hombre", tramos)
      base[[stringr::str_replace(g, "^edad", "m_edad")]] <- .suma_tramos(d, "Mujeres", tramos)
    }
  }

  columnas <- c("pob_masc", "pob_fem", names(.GRUPOS),
                stringr::str_replace(names(.GRUPOS), "^edad", "h_edad"),
                stringr::str_replace(names(.GRUPOS), "^edad", "m_edad"))

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
    stats::setNames(.BANDAS, names(.GRUPOS)),
    stats::setNames(paste("Hombres", .BANDAS),
                    stringr::str_replace(names(.GRUPOS), "^edad", "h_edad")),
    stats::setNames(paste("Mujeres", .BANDAS),
                    stringr::str_replace(names(.GRUPOS), "^edad", "m_edad"))
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
  # El curado poblacion_municipal_total_2025_dicc.dta describe una estructura
  # de edad más envejecida que el PPED con el que se publicó el informe (0 de
  # 125 municipios coinciden con el derivado de abajo; promedio +1,4 puntos).
  # La fórmula del índice es la misma en los dos; lo que cambia es la
  # población de origen. Se usa el derivado propio del pipeline, que ya la
  # calcula desde el PPED (poblacion_municipal.R). Hallazgo de Pablo
  # (F-2-015), confirmado empíricamente y adoptado también aquí.
  envejecimiento <- leer_derivado("poblacion_municipal_total_2025") |>
    dplyr::transmute(ind_mpio = as.integer(.data$ind_mpio),
                     I_enve_T = as.numeric(.data$I_enve_T))

  universo <- vitales |>
    dplyr::left_join(envejecimiento, by = "ind_mpio") |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    con_territorio()

  columnas <- c("tasa_natalidad", "tasa_mortalidad", "I_enve_T")

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
