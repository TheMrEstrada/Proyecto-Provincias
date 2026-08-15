# =============================================================================
# 09_salud.R — Sección 9: Salud
#
# TABLAS (hojas del .xlsx de la sección):
#   bajo_peso               % de nacidos con bajo peso al nacer
#   enfermedades_tropicales tasas de dengue, malaria y leishmaniasis por 100 mil
#                           habitantes
#   suicidios               tasas de intento de suicidio y de suicidio consumado
#                           por 100 mil habitantes
#   aseguramiento_sgsss     afiliados al SGSSS por régimen y su composición
#   mortalidad_infantil     tasa por 1.000 nacidos vivos, serie 2020-2024
#
# INPUTS:  01_Data/01_Derived/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.dta
#            (bajo_peso, dengue, malaria, leishmaniasis)
#          01_Data/01_Derived/suicidios_e_intentos_medias_dicc.dta
#            (TIS_total, TS_total)
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

#' Población total municipal 2025 de TODO el departamento: es el ponderador de
#' las tasas por 100 mil habitantes.
.pesos_poblacion <- function() {
  d <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = 1)
  c_cod  <- col_req(d, "DPMP")
  c_ano  <- col_req(d, "AÑO")
  c_area <- col_req(d, "ÁREA GEOGRÁFICA")
  c_pob  <- col_req(d, "Total General")

  d |>
    dplyr::filter(a_numero(.data[[c_ano]]) == 2025, .data[[c_area]] == "Total") |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      pob_peso = a_numero(.data[[c_pob]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio))
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

# --- Hoja 1: bajo peso al nacer ----------------------------------------------

.hoja_bajo_peso <- function(prov, archivo, nacimientos) {
  salud <- leer_derivado("20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA")

  # El indicador viene en puntos porcentuales; se guarda como proporción.
  universo <- data.frame(
    ind_mpio  = as.integer(salud$ind_mpio),
    bajo_peso = as.numeric(salud$bajo_peso) / 100
  ) |>
    dplyr::left_join(nacimientos[, c("ind_mpio", "nac2024")], by = "ind_mpio") |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, nac2024, bajo_peso)

  # Ponderador = NACIMIENTOS (el bajo peso es % de nacimientos, no de población).
  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov,
    columnas = "bajo_peso", como = list(bajo_peso = "promedio_ponderado"),
    pesos = "nac2024"
  ) |>
    .marcar_ponderado("por nacimientos") |>
    .provincia_de_totales() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, bajo_peso, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "bajo_peso",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  bajo_peso = "Nacidos con bajo peso al nacer (%)"),
    formatos = c(bajo_peso = "0.0%")
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
    dplyr::select(ind_mpio, municipio, subregion, provincia, pob_peso,
                  dplyr::all_of(columnas))

  # Ponderador = POBLACIÓN (son tasas por 100 mil habitantes).
  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
    .marcar_ponderado("por población") |>
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

# --- Punto de entrada ---------------------------------------------------------

tabla_salud <- function(prov) {
  message("== 09 Salud — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "09_Salud"), "salud.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  pesos       <- .pesos_poblacion()
  nacimientos <- .nacidos_vivos()

  resultado <- list(
    bajo_peso               = .hoja_bajo_peso(prov, archivo, nacimientos),
    enfermedades_tropicales = .hoja_enfermedades_tropicales(prov, archivo, pesos),
    suicidios               = .hoja_suicidios(prov, archivo, pesos),
    aseguramiento_sgsss     = .hoja_aseguramiento(prov, archivo),
    mortalidad_infantil     = .hoja_mortalidad_infantil(prov, archivo, nacimientos)
  )

  message("  09 Salud: ", length(resultado), " hojas en ", basename(archivo))
  invisible(resultado)
}
