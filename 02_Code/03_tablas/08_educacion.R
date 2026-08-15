# =============================================================================
# 08_educacion.R — Sección 8: Educación
#
# TABLA: indicadores educativos municipales (cobertura neta, deserción y
#        repitencia) para todos los años disponibles, con las filas de promedio
#        ponderado de la provincia, de la subregión mayoritaria y del
#        departamento. La ponderación es la población en edad escolar
#        (5 a 16 años), igual que en el .do original.
#
# INPUTS:  01_Data/01_Derived/EDUCACION_PROVINCIAS.xlsx  (hoja "Data")
#          OJO: este derivado NO lo produce ningún script del pipeline; se
#          arma a mano en Excel a partir de las estadísticas del MEN. Si se
#          rehace la cadena de derivados hay que construirlo aparte.
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/08_Educacion/educacion.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/08_Educacion.do
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Indicadores de la sección, en el orden en que van en la tabla del informe.
INDICADORES_EDUCACION <- c("cobertura_neta", "desercion", "repitencia")

# Encabezados legibles de la hoja (los mismos labels del .do).
ETIQUETAS_EDUCACION <- c(
  ind_mpio       = "Código DANE",
  municipio      = "Municipio",
  subregion      = "Subregión",
  provincia      = "Provincia",
  anio           = "Año",
  cobertura_neta = "Cobertura neta",
  desercion      = "Tasa de deserción",
  repitencia     = "Tasa de repitencia"
)

tabla_educacion <- function(prov) {
  message("== 08 Educación — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "08_Educacion"), "educacion.xlsx")
  # El .do borraba el archivo previo para no dejar hojas obsoletas.
  if (file.exists(archivo)) unlink(archivo)

  # --- Indicadores educativos de todo el departamento -----------------------
  bruto <- leer_excel(entrada("curados", "EDUCACION_PROVINCIAS.xlsx"), hoja = "Data")

  c_anio <- col_req(bruto, "AÑO", "ANO", "Año")
  c_cod  <- col_req(bruto, "CÓDIGO_MUNICIPIO", "CODIGO_MUNICIPIO", "ind_mpio")
  c_pob  <- col_req(bruto, "POBLACIÓN_5_16", "POBLACION_5_16", "POBLACION_5_16_EDU")
  c_cob  <- col_req(bruto, "COBERTURA_NETA")
  c_des  <- col_req(bruto, "DESERCIÓN", "DESERCION")
  c_rep  <- col_req(bruto, "REPITENCIA")

  # Los tres indicadores vienen en la fuente como porcentaje (0–100); el .do los
  # divide por 100 y los publica como proporción.
  universo <- bruto |>
    dplyr::transmute(
      ind_mpio       = as.integer(a_numero(.data[[c_cod]])),
      anio           = as.integer(a_numero(.data[[c_anio]])),
      poblacion_5_16 = a_numero(.data[[c_pob]]),
      cobertura_neta = a_numero(.data[[c_cob]]) / 100,
      desercion      = a_numero(.data[[c_des]]) / 100,
      repitencia     = a_numero(.data[[c_rep]]) / 100
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    # La subregión sale del crosswalk oficial de 125 municipios (igual que en el
    # .do, que descarta el `subreg` que trae el derivado).
    con_territorio() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, id_provincia,
                  subregion_full, anio, poblacion_5_16,
                  dplyr::all_of(INDICADORES_EDUCACION))

  # --- Municipios de la provincia -------------------------------------------
  detalle <- filtrar_provincia(universo, prov)

  # --- Un bloque de filas por año: municipios + tres promedios ponderados ----
  # La ponderación es la población de 5 a 16 años, como en el .do (aweight).
  # OJO: las filas de provincia y subregión de deserción y repitencia del Anexo 1
  # solo se reproducen si se pondera por la matrícula estimada
  # (población 5–16 × cobertura neta). Se mantiene el criterio del .do; la
  # diferencia es de ~1 % relativo y está documentada en el informe de migración.
  anios <- sort(unique(detalle$anio))
  tabla <- purrr::map_dfr(anios, function(a) {
    agregar_totales(
      dplyr::arrange(dplyr::filter(detalle, .data$anio == a), .data$municipio),
      universo = dplyr::filter(universo, .data$anio == a),
      prov     = prov,
      columnas = INDICADORES_EDUCACION,
      como     = "promedio_ponderado",
      pesos    = "poblacion_5_16"
    ) |>
      dplyr::mutate(anio = a)
  })

  # --- Etiquetas de las filas agregadas --------------------------------------
  # `agregar_totales()` las rotula como "TOTAL …" porque el caso general del
  # pipeline es una suma; aquí son promedios ponderados y la tabla lo dice, tal
  # como en el .do. Territorio de cada fila agregada: la provincia en la fila de
  # provincia, la subregión en la de subregión y el departamento en la suya.
  subreg_dom <- subregion_dominante(prov)

  tabla <- tabla |>
    dplyr::mutate(
      municipio = dplyr::case_when(
        tipo_fila == "Total provincia" ~ sprintf(
          "PROMEDIO PONDERADO PROVINCIA %s (por población escolar)",
          toupper(prov$etiqueta)
        ),
        tipo_fila == "Total subregión" ~ sprintf(
          "PROMEDIO PONDERADO SUBREGIÓN %s (por población escolar)", subreg_dom
        ),
        tipo_fila == "Total departamento" ~
          "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por población escolar)",
        TRUE ~ .data$municipio
      ),
      subregion = dplyr::case_when(
        tipo_fila == "Total subregión" ~ subreg_dom,
        tipo_fila %in% c("Total provincia", "Total departamento") ~ NA_character_,
        TRUE ~ .data$subregion
      ),
      provincia = dplyr::case_when(
        tipo_fila == "Total provincia"    ~ prov$nombre_datos,
        tipo_fila == "Total departamento" ~ "DEPARTAMENTO DE ANTIOQUIA",
        tipo_fila == "Total subregión"    ~ NA_character_,
        TRUE ~ .data$provincia
      )
    ) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  dplyr::all_of(INDICADORES_EDUCACION), tipo_fila)

  # `tipo_fila` es de uso interno (lo necesitan las figuras); no va en la hoja,
  # que reproduce las columnas exportadas por el .do.
  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "educacion",
    etiquetas = ETIQUETAS_EDUCACION,
    formatos = c(anio = "0", cobertura_neta = "0.0%",
                 desercion = "0.0%", repitencia = "0.0%")
  )

  invisible(tabla)
}
