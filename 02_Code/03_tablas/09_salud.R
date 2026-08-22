# =============================================================================
# 09_salud.R — Sección 9: Salud
#
# TABLAS (hojas del .xlsx de la sección):
#   bajo_peso_2024           % de nacidos con bajo peso al nacer, corte 2024
#                           (reemplaza la hoja "bajo_peso" del tablero curado,
#                           que quedaba en 2023p sin que nada lo justificara)
#   enfermedades_tropicales tasas de dengue, malaria y leishmaniasis por 100 mil
#                           habitantes (tablero curado, media móvil 2021-2023)
#   enfermedades_tropicales_2024  lo mismo, crudo 2022-2024 + media móvil (ver NOTA)
#   suicidios               tasas de intento de suicidio y de suicidio consumado
#                           por 100 mil habitantes, media móvil 2021-2023
#   suicidios_2022_2024     lo mismo, casos crudos 2022-2024 + media móvil (ver NOTA)
#   aseguramiento_sgsss     afiliados al SGSSS por régimen y su composición
#   mortalidad_infantil     tasa por 1.000 nacidos vivos, serie 2020-2024
#   mortalidad_infantil_promedio  la misma tasa, un solo promedio 2020-2024
#
# INPUTS:  01_Data/01_Derived/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.dta
#            (dengue, malaria, leishmaniasis — hoja enfermedades_tropicales)
#          01_Data/01_Derived/salud_actualizada_2024.parquet
#            (bajo_peso_2024, dengue/malaria/leishmaniasis 2022-2024)
#          01_Data/01_Derived/suicidios_e_intentos_medias_dicc.dta
#            (TIS_total, TS_total)
#          01_Data/01_Derived/suicidios_actualizado_2022_2024.parquet
#            (casos crudos de suicidio consumado e intento, 2022-2024)
#          01_Data/00_Inputs/POBLACION MUNICIPAL.xlsx   (peso poblacional 2025)
#          01_Data/00_Inputs/NATALIDAD.xlsx             (nacidos vivos por año)
#          01_Data/00_Inputs/MORTALIDAD_INFANTIL.xlsx   (tasa por municipio y año)
#          01_Data/00_Inputs/ASEGURAMIENTO_MUNICIPIOS.xlsx
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/09_Salud/salud.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/09_Salud.do
#
# NOTA METODOLÓGICA — AGREGADO PROVINCIAL (se conserva del .do original):
#   - tasas por 100 mil (dengue/malaria/leishmaniasis, suicidios): ponderado por
#     poblacion = Sum(tasa*pob)/Sum(pob) = Sum(casos)/Sum(pob)*100mil  (correcto).
#   - bajo_peso (% de NACIMIENTOS) y mortalidad infantil (por 1.000 nacidos):
#     ponderados por NACIMIENTOS = Sum(tasa*nac)/Sum(nac) = Sum(casos)/Sum(nac)
#     (correcto; corregido 2026-08-06, antes se ponderaba por poblacion).
#   Es decir: el denominador del indicador manda cuál es el ponderador. Un
#   indicador medido POR NACIMIENTO no se pondera por población.
#
# NOTA — SALUD 2024 (hojas *_2024 y mortalidad_infantil_promedio):
#   El tablero curado 20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA usaba el corte
#   2023p para bajo_peso y una media móvil 2021-2023 para dengue/malaria/
#   leishmaniasis, sin que ningún script lo derive (ver LIMITACIÓN en
#   01_homogeneizacion/salud_seguridad.R). INVENTARIO_VARIABLES.xlsx confirma
#   la metodología (bajo_peso sin ajuste; los tres vectores con media móvil
#   trianual por ser tasas volátiles con población pequeña) — el problema no
#   era el método, era el año. 01_homogeneizacion/salud_actualizada_2024.R
#   trae el mismo método con el corte más reciente (2024 y 2022-2024).
#   bajo_peso_2024 YA REEMPLAZÓ la hoja "bajo_peso" del tablero curado (no
#   tiene sentido conservar dos cortes de un dato de un solo año). Los
#   vectores sí quedan en paralelo: enfermedades_tropicales (2021-2023, del
#   tablero curado) y enfermedades_tropicales_2024 (2022-2024, con el crudo
#   de cada año visible para poder auditar la media móvil), porque a
#   diferencia de bajo_peso aquí interesa poder comparar ambas ventanas.
#   mortalidad_infantil_promedio es distinta: la serie por año ya reproduce
#   la fuente exactamente (confirmado contra MORTALIDAD_INFANTIL.xlsx), así
#   que aquí solo se agrega un promedio 2020-2024 ponderado por nacidos vivos
#   de cada año — no hay nada que corregir, es una vista adicional.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Lectura de matrices anchas con encabezado en varias filas ----------------
# NATALIDAD, MORTALIDAD_INFANTIL y ASEGURAMIENTO traen el encabezado repartido en
# dos filas (año o régimen arriba, subencabezado abajo). El .do las leía por
# posición de columna de Excel (AE, AG, …), que se rompe en silencio si la fuente
# mueve una columna; aquí las columnas se localizan por su encabezado.

#' Hoja completa, sin interpretar encabezados: fila 1 del data.frame = fila 1 de
#' Excel, y todo como texto.
#'
#' Se lee de una sola pasada a propósito. Si el encabezado y los datos se leyeran
#' por separado, readxl podría descartar una columna inicial vacía en una lectura
#' y no en la otra (le pasa a NATALIDAD.xlsx, cuya columna A solo tiene datos a
#' partir de la fila 4), y los índices dejarían de corresponder.
.leer_hoja_cruda <- function(ruta, hoja) {
  readxl::read_excel(ruta, sheet = hoja, col_names = FALSE, col_types = "text",
                     .name_repair = "minimal") |>
    as.data.frame(stringsAsFactors = FALSE)
}

#' Encabezado de dos filas resuelto en un vector por columna: la fila superior
#' viene combinada sobre varias columnas, así que se arrastra hacia la derecha.
.encabezado_arrastrado <- function(crudo, fila) {
  x <- as.character(unlist(crudo[fila, ]))
  for (j in seq_along(x)[-1]) {
    if (is.na(x[j]) || !nzchar(stringr::str_squish(x[j]))) x[j] <- x[j - 1]
  }
  norm_txt(x)
}

#' Índice de la columna que corresponde a un bloque del encabezado superior y a
#' un subencabezado dado. Aborta si no existe.
.columna_por_encabezado <- function(superior, sub, patron_superior, patron_sub, que) {
  j <- which(stringr::str_detect(superior, patron_superior) &
               stringr::str_detect(sub, patron_sub))
  if (!length(j)) {
    stop("No encuentro la columna '", que, "' en la fuente; ",
         "¿cambió el encabezado del archivo?", call. = FALSE)
  }
  j[1]
}

#' Matriz ancha año x indicador -> data.frame con ind_mpio y una columna por año.
#'
#' @param fila_anio fila del encabezado con el año.
#' @param fila_sub fila del subencabezado que distingue las columnas del año.
#' @param patron_sub expresión regular (texto normalizado) de la columna buscada.
#' @param fila_datos primera fila de datos.
#' @param prefijo prefijo del nombre de las columnas de salida.
.leer_matriz_anios <- function(ruta, hoja, fila_anio, fila_sub, patron_sub,
                               anios, fila_datos, prefijo = "") {
  crudo <- .leer_hoja_cruda(ruta, hoja)
  anio  <- suppressWarnings(as.numeric(.encabezado_arrastrado(crudo, fila_anio)))
  sub   <- norm_txt(as.character(unlist(crudo[fila_sub, ])))
  datos <- crudo[seq(fila_datos, nrow(crudo)), , drop = FALSE]

  salida <- data.frame(ind_mpio = as.integer(a_numero(datos[[1]])))
  for (a in anios) {
    j <- which(!is.na(anio) & anio == a & stringr::str_detect(sub, patron_sub))
    if (!length(j)) {
      stop("En ", basename(ruta), " (hoja '", hoja, "') no encuentro la columna '",
           patron_sub, "' del año ", a, ".", call. = FALSE)
    }
    salida[[paste0(prefijo, a)]] <- a_numero(datos[[j[1]]])
  }
  # Se descartan las filas de subregión y la de departamento: no son municipios.
  salida[!is.na(salida$ind_mpio) & salida$ind_mpio >= 1000, , drop = FALSE]
}

# --- Insumos compartidos ------------------------------------------------------

#' Población municipal 2025, total y rural: ponderadores de las tasas por
#' 100 mil habitantes (pob_peso) y de la leishmaniasis, que se mide sobre
#' población RURAL (pob_rural) — ver .hoja_enfermedades_tropicales(). Misma
#' fuente y mismo año para las dos series, para no mezclar vintages.
#' Hallazgo de Pablo (F-2-027 y F-2-018), adoptado también aquí.
#'
#' Lee el derivado poblacion_total_2025 (serie PPED), NO POBLACION
#' MUNICIPAL.xlsx: esa es la serie que la cabecera de 02_demografia.R declara
#' descartada porque no reproduce el Anexo 1 (Yarumal 44.770 vs. 41.884
#' publicados). Antes esta función ponderaba con una población y la sección
#' 10 del mismo informe imprimía otra para el mismo municipio.
.pesos_poblacion <- function() {
  d <- leer_derivado("poblacion_total_2025")
  c_cod  <- col_req(d, "ind_mpio")
  c_area <- col_req(d, "area_geo")
  c_pob  <- col_req(d, "Total")

  por_area <- function(area, nombre) {
    x <- d |>
      dplyr::filter(.data[[c_area]] == area) |>
      dplyr::transmute(ind_mpio = as.integer(a_numero(.data[[c_cod]])),
                       peso     = a_numero(.data[[c_pob]])) |>
      dplyr::filter(!is.na(.data$ind_mpio))
    stats::setNames(x, c("ind_mpio", nombre))
  }

  dplyr::left_join(por_area("Total", "pob_peso"),
                   por_area("Centros Poblados y Rural Disperso", "pob_rural"),
                   by = "ind_mpio")
}

#' Nacidos vivos por municipio y año (2020-2024): es el ponderador de los
#' indicadores medidos POR NACIMIENTO (bajo peso, mortalidad infantil).
#' Hoja "Natalidad total": el año está en la fila 1 y la fila 2 distingue el
#' total de nacimientos de la tasa bruta; los datos empiezan en la fila 4.
.nacidos_vivos <- function(anios = 2020:2024) {
  .leer_matriz_anios(
    entrada("NATALIDAD.xlsx"), "Natalidad total",
    fila_anio = 1, fila_sub = 2, patron_sub = "^total$",
    anios = anios, fila_datos = 4, prefijo = "nac"
  )
}

#' Renombra las filas agregadas para dejar explícito el ponderador, como en el
#' .do original ("PROMEDIO PONDERADO PROVINCIA … (por nacimientos)").
.marcar_ponderado <- function(datos, sufijo) {
  dplyr::mutate(datos, municipio = ifelse(
    .data$tipo_fila == "Municipio",
    .data$municipio,
    paste0(stringr::str_replace(.data$municipio, "^TOTAL ", "PROMEDIO PONDERADO "),
           " (", sufijo, ")")
  ))
}

#' El .do deja "DEPARTAMENTO DE ANTIOQUIA" en la columna Provincia de la fila
#' departamental; las demás filas agregadas la dejan vacía.
.provincia_de_totales <- function(datos) {
  dplyr::mutate(datos, provincia = ifelse(
    .data$tipo_fila == "Total departamento", "DEPARTAMENTO DE ANTIOQUIA",
    .data$provincia
  ))
}

ETIQUETAS_TERRITORIO <- c(
  ind_mpio  = "Código DANE",
  municipio = "Municipio",
  subregion = "Subregión",
  provincia = "Provincia"
)

# --- Hoja 1: bajo peso al nacer, 2024 (ver NOTA — SALUD 2024) ---------------
# Reemplaza la hoja que salía del tablero curado (corte 2023p, sin ajuste
# metodológico): mismo indicador, mismo método, corte más reciente.

.hoja_bajo_peso_2024 <- function(prov, archivo, nacimientos) {
  salud <- leer_derivado("salud_actualizada_2024")

  universo <- data.frame(
    ind_mpio       = as.integer(salud$ind_mpio),
    bajo_peso_2024 = as.numeric(salud$bajo_peso_2024)
  ) |>
    dplyr::left_join(nacimientos[, c("ind_mpio", "nac2024")], by = "ind_mpio") |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, nac2024, bajo_peso_2024)

  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov,
    columnas = "bajo_peso_2024", como = list(bajo_peso_2024 = "promedio_ponderado"),
    pesos = "nac2024"
  ) |>
    .marcar_ponderado("por nacimientos") |>
    .provincia_de_totales() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, bajo_peso_2024, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "bajo_peso_2024",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  bajo_peso_2024 = "Nacidos con bajo peso al nacer, 2024 (%)"),
    formatos = c(bajo_peso_2024 = "0.0%")
  )

  tabla
}

# --- Hoja 2: enfermedades transmitidas por vectores --------------------------

.hoja_enfermedades_tropicales <- function(prov, archivo, pesos) {
  salud <- leer_derivado("20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA")
  columnas <- c("dengue", "malaria", "leishmaniasis")

  # El .do calcula SOLO el agregado provincial en esta hoja (sin subregión ni
  # departamento): filtra la provincia antes de cruzar el peso poblacional.
  municipios <- data.frame(
    ind_mpio      = as.integer(salud$ind_mpio),
    dengue        = as.numeric(salud$dengue),
    malaria       = as.numeric(salud$malaria),
    leishmaniasis = as.numeric(salud$leishmaniasis)
  ) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, pob_peso, pob_rural,
                  dplyr::all_of(columnas))

  # Ponderador = POBLACIÓN (son tasas por 100 mil habitantes) — EXCEPTO
  # leishmaniasis, que se mide sobre población RURAL (etiqueta de la hoja,
  # abajo) y por tanto se pondera por población rural, no total. Hallazgo de
  # Pablo (F-2-027): el peso venía siendo el mismo para las tres, así que el
  # error en leishmaniasis iba y venía con lo urbana que fuera la provincia.
  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = list(dengue = "pob_peso", malaria = "pob_peso",
                 leishmaniasis = "pob_rural")
  ) |>
    .marcar_ponderado("por población; leishmaniasis por población rural") |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas), tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "enfermedades_tropicales",
    # El .do rotulaba la leishmaniasis "por 100 mil hab.", pero el diccionario
    # del insumo (y el Anexo 1) la miden sobre POBLACIÓN RURAL: se explicita.
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  dengue        = "Tasa de dengue por 100 mil hab.",
                  malaria       = "Tasa de malaria por 100 mil hab.",
                  leishmaniasis = "Tasa de leishmaniasis por 100 mil hab. rurales"),
    formatos = stats::setNames(rep("#,##0.00", length(columnas)), columnas)
  )

  tabla
}

# --- Hoja 2b: vectores, media móvil 2022-2024 (NUEVA, ver NOTA — SALUD 2024) -
# Se conserva el dato crudo de cada año, no solo el promedio, para que la
# media móvil se pueda auditar cifra por cifra.

.hoja_enfermedades_tropicales_2024 <- function(prov, archivo, pesos) {
  salud <- leer_derivado("salud_actualizada_2024")
  columnas_anio <- c(
    "dengue_2022", "dengue_2023", "dengue_2024",
    "malaria_2022", "malaria_2023", "malaria_2024",
    "leishmaniasis_2022", "leishmaniasis_2023", "leishmaniasis_2024"
  )

  municipios <- salud[, c("ind_mpio", columnas_anio)] |>
    dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, pob_peso, pob_rural,
                  dplyr::all_of(columnas_anio))

  # Leishmaniasis se pondera por población RURAL, no total — mismo hallazgo
  # de Pablo (F-2-027) que en la hoja de vectores 2021-2023, ver arriba.
  pesos_col <- stats::setNames(
    as.list(ifelse(stringr::str_starts(columnas_anio, "leishmaniasis"),
                   "pob_rural", "pob_peso")),
    columnas_anio
  )
  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas_anio,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas_anio))), columnas_anio),
    pesos = pesos_col
  ) |>
    dplyr::mutate(
      dengue_2022_2024        = (.data$dengue_2022 + .data$dengue_2023 + .data$dengue_2024) / 3,
      malaria_2022_2024       = (.data$malaria_2022 + .data$malaria_2023 + .data$malaria_2024) / 3,
      leishmaniasis_2022_2024 = (.data$leishmaniasis_2022 + .data$leishmaniasis_2023 + .data$leishmaniasis_2024) / 3
    ) |>
    .marcar_ponderado("por población; leishmaniasis por población rural") |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas_anio),
                  dengue_2022_2024, malaria_2022_2024, leishmaniasis_2022_2024,
                  tipo_fila)

  columnas_todas <- c(columnas_anio, "dengue_2022_2024", "malaria_2022_2024",
                      "leishmaniasis_2022_2024")
  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "enfermedades_tropicales_2024",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  dengue_2022 = "Dengue 2022 (tasa x 100 mil hab.)",
                  dengue_2023 = "Dengue 2023 (tasa x 100 mil hab.)",
                  dengue_2024 = "Dengue 2024 (tasa x 100 mil hab.)",
                  dengue_2022_2024 = "Dengue, media móvil 2022-2024 (tasa x 100 mil hab.)",
                  malaria_2022 = "Malaria 2022 (tasa x 100 mil hab.)",
                  malaria_2023 = "Malaria 2023 (tasa x 100 mil hab.)",
                  malaria_2024 = "Malaria 2024 (tasa x 100 mil hab.)",
                  malaria_2022_2024 = "Malaria, media móvil 2022-2024 (tasa x 100 mil hab.)",
                  leishmaniasis_2022 = "Leishmaniasis 2022 (tasa x pob. rural)",
                  leishmaniasis_2023 = "Leishmaniasis 2023 (tasa x pob. rural)",
                  leishmaniasis_2024 = "Leishmaniasis 2024 (tasa x pob. rural)",
                  leishmaniasis_2022_2024 = "Leishmaniasis, media móvil 2022-2024 (tasa x pob. rural)"),
    formatos = stats::setNames(rep("#,##0.00", length(columnas_todas)), columnas_todas)
  )

  tabla
}

# --- Hoja 3: intento de suicidio y suicidio consumado ------------------------

.hoja_suicidios <- function(prov, archivo, pesos) {
  # El derivado trae todo como texto: hay que forzar la conversión.
  su <- haven::read_dta(entrada("curados", "suicidios_e_intentos_medias_dicc.dta"))
  columnas <- c("tis_total", "ts_total")

  universo <- data.frame(
    ind_mpio  = as.integer(a_numero(su$ind_mpio)),
    tis_total = a_numero(su$TIS_total),
    ts_total  = a_numero(su$TS_total)
  ) |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, pob_peso,
                  dplyr::all_of(columnas))

  # Ponderador = POBLACIÓN (son tasas por 100 mil habitantes).
  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
    .marcar_ponderado("por población") |>
    .provincia_de_totales() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas), tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "suicidios",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  tis_total = "Tasa de intento de suicidio por 100 mil hab.",
                  ts_total  = "Tasa de suicidio consumado por 100 mil hab."),
    formatos = c(tis_total = "#,##0.00", ts_total = "#,##0.00")
  )

  tabla
}

# --- Hoja 3b: suicidio consumado e intento, 2022-2024 (NUEVA) ---------------
# Réplica de la hoja "suicidios" con el mismo método (Σcasos / Σpoblación x
# 100 mil), pero con la ventana 2022-2024 en vez de 2021-2023: las fuentes
# disponibles (ver 01_homogeneizacion/suicidios_actualizado_2022_2024.R) solo
# traen un año a la vez, así que la tasa de cada año se calcula aquí mismo con
# la misma población 2025 (no hay serie anual sin el insumo PPED prohibido) y
# el promedio de los tres años es, por construcción, Σcasos/(3·pob)x100mil —
# la misma fórmula. Se conservan los casos crudos de cada año para poder
# auditar el promedio cifra por cifra (mismo criterio que
# .hoja_enfermedades_tropicales_2024()). Es DELIBERADAMENTE un derivado
# aparte: "suicidios" (2021-2023) no se toca.

.hoja_suicidios_2022_2024 <- function(prov, archivo, pesos) {
  base <- leer_derivado("suicidios_actualizado_2022_2024")
  cols_casos <- c("suicidios_casos_2022", "suicidios_casos_2023", "suicidios_casos_2024",
                  "intentos_casos_2022", "intentos_casos_2023", "intentos_casos_2024")

  universo <- base |>
    dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio),
                  dplyr::across(dplyr::all_of(cols_casos), as.numeric)) |>
    dplyr::left_join(pesos, by = "ind_mpio") |>
    con_territorio() |>
    dplyr::mutate(
      ts_2022  = .data$suicidios_casos_2022 / .data$pob_peso * 1e5,
      ts_2023  = .data$suicidios_casos_2023 / .data$pob_peso * 1e5,
      ts_2024  = .data$suicidios_casos_2024 / .data$pob_peso * 1e5,
      tis_2022 = .data$intentos_casos_2022  / .data$pob_peso * 1e5,
      tis_2023 = .data$intentos_casos_2023  / .data$pob_peso * 1e5,
      tis_2024 = .data$intentos_casos_2024  / .data$pob_peso * 1e5
    )

  columnas <- c("ts_2022", "ts_2023", "ts_2024", "tis_2022", "tis_2023", "tis_2024")

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, pob_peso,
                  dplyr::all_of(cols_casos), dplyr::all_of(columnas))

  # Ponderador = POBLACIÓN (son tasas por 100 mil habitantes), la misma para
  # los tres años: el promedio ponderado se reduce a Σcasos/(3·Σpob)x100mil,
  # que es la fórmula del tablero curado con la población constante que hay
  # disponible (ver cabecera de esta hoja).
  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
    dplyr::mutate(
      ts_total_2022_2024  = (.data$ts_2022 + .data$ts_2023 + .data$ts_2024) / 3,
      tis_total_2022_2024 = (.data$tis_2022 + .data$tis_2023 + .data$tis_2024) / 3
    ) |>
    .marcar_ponderado("por población 2025, misma base los tres años") |>
    .provincia_de_totales() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(cols_casos), dplyr::all_of(columnas),
                  ts_total_2022_2024, tis_total_2022_2024, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "suicidios_2022_2024",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  suicidios_casos_2022 = "Suicidios consumados, casos 2022 (DANE)",
                  suicidios_casos_2023 = "Suicidios consumados, casos 2023 (DANE)",
                  suicidios_casos_2024 = "Suicidios consumados, casos 2024 (DANE)",
                  intentos_casos_2022  = "Intentos de suicidio, casos 2022 (SIVIGILA, residencia)",
                  intentos_casos_2023  = "Intentos de suicidio, casos 2023 (SIVIGILA, residencia)",
                  intentos_casos_2024  = "Intentos de suicidio, casos 2024 (SIVIGILA, residencia)",
                  ts_2022  = "Tasa de suicidio consumado 2022 (x 100 mil hab.)",
                  ts_2023  = "Tasa de suicidio consumado 2023 (x 100 mil hab.)",
                  ts_2024  = "Tasa de suicidio consumado 2024 (x 100 mil hab.)",
                  tis_2022 = "Tasa de intento de suicidio 2022 (x 100 mil hab.)",
                  tis_2023 = "Tasa de intento de suicidio 2023 (x 100 mil hab.)",
                  tis_2024 = "Tasa de intento de suicidio 2024 (x 100 mil hab.)",
                  ts_total_2022_2024  = "Tasa de suicidio consumado, media móvil 2022-2024 (x 100 mil hab.)",
                  tis_total_2022_2024 = "Tasa de intento de suicidio, media móvil 2022-2024 (x 100 mil hab.)"),
    formatos = stats::setNames(
      rep("#,##0.00", length(columnas) + 2), c(columnas, "ts_total_2022_2024", "tis_total_2022_2024")
    )
  )

  tabla
}

# --- Hoja 4: composición de afiliados al SGSSS por régimen -------------------

.hoja_aseguramiento <- function(prov, archivo) {
  # ASEGURAMIENTO_MUNICIPIOS.xlsx, hoja "1. Población_Afiliada_Regimen".
  # CORTE: DICIEMBRE 2025 (no es total anual). El código municipal viene con
  # 3 dígitos -> ind_mpio = 5000 + cod. Régimen especial y de excepción =
  # Excepción + Fuerza Pública + INPEC. El encabezado ocupa dos filas: el
  # régimen en la primera y "Total Afiliados"/"% de cobertura" en la segunda.
  ruta  <- entrada("ASEGURAMIENTO_MUNICIPIOS.xlsx")
  hoja  <- "1. Población_Afiliada_Regimen"
  crudo <- .leer_hoja_cruda(ruta, hoja)

  regimen <- .encabezado_arrastrado(crudo, 2)   # fila con el nombre del régimen
  sub     <- norm_txt(as.character(unlist(crudo[3, ])))  # "Total Afiliados" / "%"
  datos   <- crudo[seq(6, nrow(crudo)), , drop = FALSE]  # datos desde la fila 6

  afiliados <- function(patron, que) {
    datos[[.columna_por_encabezado(regimen, sub, patron, "^total", que)]] |> a_numero()
  }

  bruto <- data.frame(
    cod               = a_numero(datos[[1]]),
    afil_subsidiado   = afiliados("regimen subsidiado", "afiliados al subsidiado"),
    afil_contributivo = afiliados("regimen contributivo", "afiliados al contributivo"),
    afil_exc          = afiliados("regimen excepcion", "afiliados de excepción"),
    afil_fp           = afiliados("fuerza publica", "afiliados de fuerza pública"),
    afil_inpec        = afiliados("^inpec", "afiliados del INPEC")
  )
  # Las filas de departamento y de subregión no traen código municipal.
  bruto <- bruto[!is.na(bruto$cod), , drop = FALSE]

  columnas <- c("afil_contributivo", "afil_subsidiado", "afil_especial")

  municipios <- bruto |>
    dplyr::mutate(
      ind_mpio      = 5000L + as.integer(.data$cod),
      afil_especial = .data$afil_exc + .data$afil_fp + .data$afil_inpec
    ) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, dplyr::all_of(columnas))

  # Composición = régimen / total de afiliados. El agregado provincial suma los
  # afiliados y recalcula las proporciones (exacto, no promedia proporciones).
  tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                           columnas = columnas, como = "suma") |>
    dplyr::mutate(
      .total = .data$afil_contributivo + .data$afil_subsidiado + .data$afil_especial,
      prop_contributivo = .data$afil_contributivo / .data$.total,
      prop_subsidiado   = .data$afil_subsidiado   / .data$.total,
      prop_especial     = .data$afil_especial     / .data$.total
    ) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  dplyr::all_of(columnas),
                  prop_contributivo, prop_subsidiado, prop_especial, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "aseguramiento_sgsss",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  afil_contributivo = "Afiliados al régimen contributivo",
                  afil_subsidiado   = "Afiliados al régimen subsidiado",
                  afil_especial     = "Afiliados al régimen especial y de excepción",
                  prop_contributivo = "% afiliados régimen contributivo",
                  prop_subsidiado   = "% afiliados régimen subsidiado",
                  prop_especial     = "% afiliados régimen especial y de excepción"),
    formatos = c(afil_contributivo = "#,##0", afil_subsidiado = "#,##0",
                 afil_especial = "#,##0", prop_contributivo = "0.0%",
                 prop_subsidiado = "0.0%", prop_especial = "0.0%")
  )

  tabla
}

# --- Hoja 5: mortalidad infantil 2020-2024 -----------------------------------

.hoja_mortalidad_infantil <- function(prov, archivo, nacimientos, anios = 2020:2024) {
  # MORTALIDAD_INFANTIL.xlsx (hoja "INFANTIL"): matriz ancha con, por año, el
  # número de casos y la "Tasa x mil Nacidos vivos". Se toma la tasa.
  largo <- .leer_matriz_anios(
    entrada("MORTALIDAD_INFANTIL.xlsx"), "INFANTIL",
    fila_anio = 4, fila_sub = 5, patron_sub = "^tasa",
    anios = anios, fila_datos = 6, prefijo = "tasa"
  ) |>
    tidyr::pivot_longer(cols = -"ind_mpio", names_to = "anio",
                        values_to = "tasa_mort_infantil") |>
    dplyr::mutate(anio = as.integer(stringr::str_remove(.data$anio, "^tasa")))

  nac_largo <- nacimientos |>
    tidyr::pivot_longer(cols = -"ind_mpio", names_to = "anio", values_to = "nac") |>
    dplyr::mutate(anio = as.integer(stringr::str_remove(.data$anio, "^nac")))

  universo <- largo |>
    dplyr::left_join(nac_largo, by = c("ind_mpio", "anio")) |>
    con_territorio()

  # Un bloque de filas por año: municipios, provincia, subregión y departamento.
  # Ponderador = NACIDOS VIVOS de ese año (la tasa es por 1.000 nacidos vivos):
  # tasa_agregada = Σ(tasa_i·nac_i)/Σnac_i = Σcasos/Σnacidos · 1.000.
  # La tasa = 0 se maneja bien: aporta 0 al numerador y sus nacidos al denominador.
  bloques <- lapply(anios, function(a) {
    u_a <- dplyr::filter(universo, .data$anio == a)
    m_a <- u_a |>
      filtrar_provincia(prov) |>
      dplyr::arrange(.data$nvl_label) |>
      dplyr::select(ind_mpio, municipio, subregion, provincia, anio, nac,
                    tasa_mort_infantil)

    agregar_totales(
      m_a, universo = u_a, prov = prov, columnas = "tasa_mort_infantil",
      como = list(tasa_mort_infantil = "promedio_ponderado"), pesos = "nac"
    ) |>
      .marcar_ponderado("por nacidos vivos") |>
      .provincia_de_totales() |>
      dplyr::mutate(anio = a)
  })

  tabla <- dplyr::bind_rows(bloques) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  tasa_mort_infantil, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "mortalidad_infantil",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  anio = "Año",
                  tasa_mort_infantil = "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"),
    formatos = c(tasa_mort_infantil = "#,##0.00")
  )

  tabla
}

# --- Hoja 5b: mortalidad infantil, promedio 2020-2024 (NUEVA) ---------------
# La serie por año (hoja 5) ya reproduce MORTALIDAD_INFANTIL.xlsx exactamente;
# esto no corrige nada, solo agrega el promedio del período completo,
# ponderado por los nacidos vivos de cada año (Σcasos / Σnacidos x 1.000).

.hoja_mortalidad_infantil_promedio <- function(prov, archivo, nacimientos, anios = 2020:2024) {
  casos <- .leer_matriz_anios(
    entrada("MORTALIDAD_INFANTIL.xlsx"), "INFANTIL",
    fila_anio = 4, fila_sub = 5, patron_sub = "^casos",
    anios = anios, fila_datos = 6, prefijo = "casos"
  ) |>
    tidyr::pivot_longer(cols = -"ind_mpio", names_to = "anio", values_to = "casos") |>
    dplyr::mutate(anio = as.integer(stringr::str_remove(.data$anio, "^casos")))

  nac_largo <- nacimientos |>
    tidyr::pivot_longer(cols = -"ind_mpio", names_to = "anio", values_to = "nac") |>
    dplyr::mutate(anio = as.integer(stringr::str_remove(.data$anio, "^nac")))

  universo <- casos |>
    dplyr::left_join(nac_largo, by = c("ind_mpio", "anio")) |>
    dplyr::group_by(.data$ind_mpio) |>
    dplyr::summarise(
      nac_total = sum(.data$nac, na.rm = TRUE),
      tasa_mort_infantil_prom = sum(.data$casos, na.rm = TRUE) /
        sum(.data$nac, na.rm = TRUE) * 1000,
      .groups = "drop"
    ) |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, nac_total,
                  tasa_mort_infantil_prom)

  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov,
    columnas = "tasa_mort_infantil_prom",
    como = list(tasa_mort_infantil_prom = "promedio_ponderado"), pesos = "nac_total"
  ) |>
    .marcar_ponderado(paste0("por nacidos vivos ", min(anios), "-", max(anios))) |>
    .provincia_de_totales() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  tasa_mort_infantil_prom, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "mortalidad_infantil_promedio",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  tasa_mort_infantil_prom = paste0(
                    "Tasa de mortalidad infantil, promedio ", min(anios), "-",
                    max(anios), " (x 1.000 nacidos vivos)")),
    formatos = c(tasa_mort_infantil_prom = "#,##0.00")
  )

  tabla
}

# --- Punto de entrada ---------------------------------------------------------

tabla_salud <- function(prov) {
  message("== 09 Salud — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "09_Salud"), "salud.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  pesos       <- .pesos_poblacion()
  nacimientos <- .nacidos_vivos()

  resultado <- list(
    bajo_peso_2024                = .hoja_bajo_peso_2024(prov, archivo, nacimientos),
    enfermedades_tropicales      = .hoja_enfermedades_tropicales(prov, archivo, pesos),
    enfermedades_tropicales_2024 = .hoja_enfermedades_tropicales_2024(prov, archivo, pesos),
    suicidios                    = .hoja_suicidios(prov, archivo, pesos),
    suicidios_2022_2024          = .hoja_suicidios_2022_2024(prov, archivo, pesos),
    aseguramiento_sgsss          = .hoja_aseguramiento(prov, archivo),
    mortalidad_infantil          = .hoja_mortalidad_infantil(prov, archivo, nacimientos),
    mortalidad_infantil_promedio = .hoja_mortalidad_infantil_promedio(prov, archivo, nacimientos)
  )

  message("  09 Salud: ", length(resultado), " hojas en ", basename(archivo))
  invisible(resultado)
}
