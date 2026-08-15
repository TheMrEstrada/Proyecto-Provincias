# =============================================================================
# 04_gobernabilidad.R — Sección 4: Gobernabilidad
#
# TABLAS (una hoja por subsección, todas en el mismo .xlsx):
#   mdm     — Medición de Desempeño Municipal (DNP), por municipio y año
#   idf     — Índice de Desempeño Fiscal (DNP), por municipio y año
#   ley617  — ICLD, gastos de funcionamiento e indicador de la Ley 617 (CGR)
#   icm     — Índice de Ciudades Modernas (DNP) y sus seis dimensiones, con los
#             agregados de provincia, subregión y departamento
#
# INPUTS:  01_Data/01_Derived/MDM_PROVINCIAS.xlsx   (hoja "Base")
#          01_Data/01_Derived/IDF_PROVINCIAS.xlsx   (hoja "IDF")
#          01_Data/01_Derived/617_PROVINCIAS.xlsx   (hoja "617")
#          01_Data/01_Derived/ICM_PROVINCIAS.xlsx   (hojas "BD_ICM_Municipal" y
#                                                    "BD_ICM_Departamental")
#          01_Data/00_Inputs/POBLACION MUNICIPAL.xlsx  (pesos del promedio ICM)
#          crosswalks territoriales (01_Derived)
#
#          OJO: los cuatro archivos *_PROVINCIAS.xlsx de esta sección viven en
#          01_Data/01_Derived pero NINGÚN script del repositorio los produce: se
#          arman a mano en Excel. Son insumos manuales sin productor; si cambian
#          las fuentes hay que rehacerlos fuera del pipeline.
#
# OUTPUTS: 03_Outputs/<Provincia>/04_Gobernabilidad/gobernabilidad.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/04_Gobernabilidad.do
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Dimensiones del ICM tal como vienen en el archivo (columna -> nombre corto).
# Stata las importa como ICM000, PCC000, …; readxl conserva el guion, así que se
# buscan con col_req() por las dos formas.
.ICM_DIMS <- c(icm = "ICM-00-0", pcc = "PCC-00-0", gpi = "GPI-00-0",
               eis = "EIS-00-0", cti = "CTI-00-0", seg = "SEG-00-0",
               sos = "SOS-00-0")

#' Población municipal total (todas las áreas = "Total") por municipio y año.
#' Es el ponderador del promedio ICM de provincia y subregión.
.poblacion_por_anio <- function() {
  p <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = "Total_Municipios")
  c_cod  <- col_req(p, "DPMP", "cod_mpio", "divipola")
  c_anio <- col_req(p, "AÑO", "anio")
  c_area <- col_req(p, "ÁREA GEOGRÁFICA", "AREA GEOGRAFICA")
  c_pob  <- col_req(p, "Total General", "TotalGeneral")

  p |>
    dplyr::filter(norm_txt(.data[[c_area]]) == "total") |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      anio     = as.integer(a_numero(.data[[c_anio]])),
      pob      = a_numero(.data[[c_pob]])
    ) |>
    dplyr::filter(!is.na(ind_mpio), !is.na(anio))
}

# --- 4.1 Medición de Desempeño Municipal (MDM) -------------------------------
.mdm_provincia <- function(prov) {
  d <- leer_excel(entrada("curados", "MDM_PROVINCIAS.xlsx"), hoja = "Base")
  c_cod  <- col_req(d, "cmpio", "codigo dane", "ind_mpio")
  c_anio <- col_req(d, "año", "anio")
  c_ges  <- col_req(d, "gestion")
  c_res  <- col_req(d, "resultados")
  c_mdm  <- col_req(d, "mdm")

  # La provincia se toma SIEMPRE del crosswalk, no de la columna `prov` del
  # archivo: es la fuente confiable y evita el desalineamiento documentado en
  # el .do para el IDF. (Además `prov` enmascararía el argumento homónimo de
  # filtrar_provincia() dentro de dplyr::filter.)
  d |>
    dplyr::transmute(
      ind_mpio   = as.integer(a_numero(.data[[c_cod]])),
      anio       = as.integer(a_numero(.data[[c_anio]])),
      gestion    = a_numero(.data[[c_ges]]),
      resultados = a_numero(.data[[c_res]]),
      mdm        = a_numero(.data[[c_mdm]])
    ) |>
    dplyr::filter(!is.na(ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$anio, .data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  gestion, resultados, mdm)
}

# --- 4.2 Índice de Desempeño Fiscal (IDF) ------------------------------------
.idf_provincia <- function(prov) {
  d <- leer_excel(entrada("curados", "IDF_PROVINCIAS.xlsx"), hoja = "IDF")
  c_cod  <- col_req(d, "Codigo", "Código", "ind_mpio")
  c_anio <- col_req(d, "año", "anio")
  c_res  <- col_req(d, "Resultados")
  c_ges  <- col_req(d, "Gestion", "Gestión")
  c_idf  <- col_req(d, "IDF")
  c_ran  <- col_req(d, "Rango")

  # Las columnas "Esquema asociativo" y "Subregión" del archivo están CORRUPTAS
  # (municipios asignados a la provincia equivocada). Se descartan y territorio
  # y provincia se traen del crosswalk, igual que en el .do original.
  # [Pendiente: corregir IDF_PROVINCIAS.xlsx en la fuente.]
  d |>
    dplyr::transmute(
      ind_mpio   = as.integer(a_numero(.data[[c_cod]])),
      anio       = as.integer(a_numero(.data[[c_anio]])),
      resultados = a_numero(.data[[c_res]]),
      gestion    = a_numero(.data[[c_ges]]),
      idf        = a_numero(.data[[c_idf]]),
      rango      = as.character(.data[[c_ran]])
    ) |>
    dplyr::filter(!is.na(ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$anio, .data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  resultados, gestion, idf, rango)
}

# --- 4.3 Indicador Ley 617 ----------------------------------------------------
.ley617_provincia <- function(prov) {
  d <- leer_excel(entrada("curados", "617_PROVINCIAS.xlsx"), hoja = "617")
  c_cod  <- col_req(d, "Código", "Codigo", "ind_mpio")
  c_anio <- col_req(d, "Año", "anio")
  c_icld <- col_req(d, "ICDL", "ICLD")
  c_gf   <- col_req(d, "Gastos funcionamiento", "Gastosfuncionamiento")
  c_ind  <- col_req(d, "Indicador 617", "Indicador617")
  c_obs  <- col_req(d, "Observación", "Observacion")

  # SIN agregado: la Ley 617 NO se agrega. Es un cociente institucional (gastos
  # de funcionamiento / ICLD) de CADA entidad, medido contra el techo legal de la
  # categoría de cada municipio. No existe un 617 provincial ni subregional, y el
  # 617 departamental corresponde a la Gobernación (otra entidad), no a la suma
  # de los municipios. Por eso solo se exportan los municipios de la provincia.
  d |>
    dplyr::transmute(
      ind_mpio    = as.integer(a_numero(.data[[c_cod]])),
      anio        = as.integer(a_numero(.data[[c_anio]])),
      icld        = a_numero(.data[[c_icld]]),
      gastos_func = a_numero(.data[[c_gf]]),
      ind_617     = a_numero(.data[[c_ind]]),
      observacion = as.character(.data[[c_obs]])
    ) |>
    dplyr::filter(!is.na(ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$anio, .data$nvl_label) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  icld, gastos_func, ind_617, observacion)
}

# --- 4.4 Índice de Ciudades Modernas (ICM) ------------------------------------
#' Universo ICM: los 125 municipios de Antioquia, por año, con territorio y
#' población (el ponderador de los promedios).
.icm_universo <- function() {
  d <- leer_excel(entrada("curados", "ICM_PROVINCIAS.xlsx"), hoja = "BD_ICM_Municipal")
  c_cod  <- col_req(d, "Divipola", "cod_mpio", "ind_mpio")
  c_anio <- col_req(d, "AÑO", "anio")

  base <- dplyr::tibble(
    ind_mpio = as.integer(a_numero(d[[c_cod]])),
    anio     = as.integer(a_numero(d[[c_anio]]))
  )
  for (k in names(.ICM_DIMS)) {
    base[[k]] <- a_numero(d[[col_req(d, .ICM_DIMS[[k]], toupper(gsub("-", "", .ICM_DIMS[[k]])))]])
  }

  base |>
    dplyr::filter(!is.na(ind_mpio), !is.na(anio)) |>
    dplyr::left_join(.poblacion_por_anio(), by = c("ind_mpio", "anio")) |>
    con_territorio()
}

#' ICM departamental OFICIAL (hoja BD_ICM_Departamental, encabezado en la fila 5).
#' Es el valor publicado por el DNP para Antioquia; NO se recalcula agregando los
#' 125 municipios (daría un número parecido pero distinto).
.icm_departamento <- function() {
  d <- leer_excel(entrada("curados", "ICM_PROVINCIAS.xlsx"),
                  hoja = "BD_ICM_Departamental", saltar = 4)
  c_anio <- col_req(d, "AÑO", "anio")
  out <- dplyr::tibble(anio = as.integer(a_numero(d[[c_anio]])))
  for (k in names(.ICM_DIMS)) {
    out[[k]] <- a_numero(d[[col_req(d, .ICM_DIMS[[k]], toupper(gsub("-", "", .ICM_DIMS[[k]])))]])
  }
  dplyr::filter(out, !is.na(anio))
}

.icm_provincia <- function(prov) {
  universo <- .icm_universo()
  oficial  <- .icm_departamento()
  dims     <- names(.ICM_DIMS)
  subreg   <- subregion_dominante(prov)

  #' Un año completo: municipios de la provincia + los tres agregados.
  #' Los agregados de provincia y subregión son PROMEDIOS PONDERADOS por la
  #' población del año; el del departamento se sustituye por el valor oficial.
  armar_anio <- function(u) {
    anio <- u$anio[1]
    municipios <- u |>
      filtrar_provincia(prov) |>
      dplyr::arrange(.data$nvl_label) |>
      dplyr::select(ind_mpio, municipio, subregion, provincia,
                    dplyr::all_of(dims), pob)

    filas <- agregar_totales(
      municipios, universo = u, prov = prov, columnas = dims,
      como = "promedio_ponderado", pesos = "pob"
    )

    # agregar_totales() rotula "TOTAL …" porque su caso normal es una suma. Aquí
    # la agregación es un promedio ponderado, así que se rotula como tal (es la
    # redacción del .do original y la que entiende el lector del informe).
    filas$municipio <- dplyr::case_when(
      filas$tipo_fila == "Total provincia" ~ paste0(
        "PROMEDIO PONDERADO PROVINCIA ", toupper(prov$etiqueta),
        " (por población del año)"),
      filas$tipo_fila == "Total subregión" ~ paste0(
        "PROMEDIO PONDERADO SUBREGIÓN ", subreg, " (por población del año)"),
      filas$tipo_fila == "Total departamento" ~ "DEPARTAMENTO (ANTIOQUIA) - ICM oficial",
      TRUE ~ filas$municipio
    )

    dep <- oficial[oficial$anio == anio, , drop = FALSE]
    i <- which(filas$tipo_fila == "Total departamento")
    if (length(i) && nrow(dep)) filas[i, dims] <- dep[1, dims]

    filas$anio <- anio
    filas$orden_fila <- match(filas$tipo_fila,
      c("Municipio", "Total provincia", "Total subregión", "Total departamento"))
    filas
  }

  split(universo, universo$anio) |>
    lapply(armar_anio) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$anio, .data$orden_fila) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  dplyr::all_of(dims), tipo_fila)
}

# --- Punto de entrada ---------------------------------------------------------

tabla_gobernabilidad <- function(prov) {
  message("== 04 Gobernabilidad — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "04_Gobernabilidad"), "gobernabilidad.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  territorio <- c(ind_mpio = "Código DANE", municipio = "Municipio",
                  subregion = "Subregión", provincia = "Provincia", anio = "Año")

  # --- 4.1 MDM ---------------------------------------------------------------
  # DECISIÓN METODOLÓGICA (Pablo): el MDM NO se promedia. No se añade fila de
  # promedio provincial, subregional ni departamental: el DNP compara cada
  # municipio dentro de su grupo de capacidades iniciales, y un promedio entre
  # grupos no tiene lectura. Lo mismo aplica al IDF (4.2).
  mdm <- .mdm_provincia(prov)
  escribir_hoja(
    mdm, archivo, "mdm",
    etiquetas = c(territorio, gestion = "Gestión", resultados = "Resultados",
                  mdm = "MDM"),
    formatos = c(gestion = "#,##0.00", resultados = "#,##0.00", mdm = "#,##0.00")
  )

  # --- 4.2 IDF ---------------------------------------------------------------
  # Sin fila de promedio provincial (misma decisión que en 4.1).
  idf <- .idf_provincia(prov)
  escribir_hoja(
    idf, archivo, "idf",
    etiquetas = c(territorio, resultados = "Resultados", gestion = "Gestión",
                  idf = "IDF", rango = "Rango"),
    formatos = c(resultados = "#,##0.00", gestion = "#,##0.00", idf = "#,##0.00")
  )

  # --- 4.3 Ley 617 -----------------------------------------------------------
  ley617 <- .ley617_provincia(prov)
  escribir_hoja(
    ley617, archivo, "ley617",
    etiquetas = c(territorio, icld = "ICLD", gastos_func = "Gastos de funcionamiento",
                  ind_617 = "Indicador Ley 617", observacion = "Observación"),
    formatos = c(icld = "#,##0", gastos_func = "#,##0", ind_617 = "0.0%")
  )

  # --- 4.4 ICM ---------------------------------------------------------------
  icm <- .icm_provincia(prov)
  escribir_hoja(
    dplyr::select(icm, -tipo_fila), archivo, "icm",
    etiquetas = c(territorio, icm = "ICM", pcc = "PCC", gpi = "GPI", eis = "EIS",
                  cti = "CTI", seg = "SEG", sos = "SOS"),
    formatos = stats::setNames(rep("#,##0.00", 7),
                               c("icm", "pcc", "gpi", "eis", "cti", "seg", "sos"))
  )

  invisible(list(archivo = archivo, mdm = mdm, idf = idf,
                 ley617 = ley617, icm = icm))
}
