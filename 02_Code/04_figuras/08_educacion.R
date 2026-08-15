# =============================================================================
# 08_educacion.R — Figuras de la Sección 8: Educación
#
# FIGURAS:
#   fig_01_cobertura_neta       — cobertura neta en educación por municipio
#   fig_02_desercion_escolar    — tasa de deserción escolar por municipio
#   fig_03_repitencia_escolar   — tasa de repitencia escolar por municipio
#
# Las tres son barras horizontales del último año disponible, con la línea de
# referencia del promedio ponderado provincial.
#
# INPUTS:  la tabla que produce 02_Code/03_tablas/08_educacion.R
# OUTPUTS: 03_Outputs/<Provincia>/08_Educacion/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

FUENTE_EDUCACION <- paste(
  "Ministerio de Educación Nacional, Estadísticas en Educación en Preescolar,",
  "Básica y Media (2026)."
)
NOTA_EDUCACION <- paste(
  "Cálculos propios. Los promedios de provincia, subregión y departamento están",
  "ponderados por la población de 5 a 16 años."
)

figuras_educacion <- function(prov, tabla) {
  message("== figuras 08 Educación — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "08_Educacion")
  archivo <- file.path(dir_seccion(prov, "08_Educacion"), "educacion.xlsx")

  # Las figuras del catálogo son del año más reciente de la serie.
  ultimo <- max(tabla$anio, na.rm = TRUE)
  d <- dplyr::filter(tabla, .data$anio == ultimo)

  municipios <- dplyr::filter(d, .data$tipo_fila == "Municipio")
  n <- nrow(municipios)

  #' Valor de una fila agregada del año (NA si esa fila no existe).
  agregado <- function(tipo, columna) {
    v <- d[[columna]][d$tipo_fila == tipo]
    if (length(v)) v[1] else NA_real_
  }
  #' "70,1 %" a partir de una proporción.
  pp <- function(x, dec = 1) pct_co(x * 100, dec = dec)

  #' Una figura de barras por indicador. Devuelve la ruta del PNG.
  #'
  #' @param columna nombre de la columna del indicador en la tabla.
  #' @param extremo "min" o "max": qué municipio se resalta y del que habla el
  #'   título (la peor situación del indicador).
  barras_indicador <- function(columna, extremo, id, slug, titulo_fmt, subtitulo_fmt) {
    dd <- dplyr::mutate(municipios, valor = .data[[columna]])
    dd <- dplyr::filter(dd, !is.na(.data$valor))

    i <- if (extremo == "max") which.max(dd$valor) else which.min(dd$valor)
    foco_mpio  <- dd$municipio[i]
    foco_valor <- dd$valor[i]

    v_prov <- agregado("Total provincia", columna)
    v_sub  <- agregado("Total subregión", columna)
    v_dep  <- agregado("Total departamento", columna)

    p <- fig_barras(
      dd, categoria = municipio, valor = valor,
      resaltar = foco_mpio,
      etiqueta = function(x) pp(x),
      referencia = v_prov,
      etiqueta_referencia = paste0("Provincia: ", pp(v_prov))
    ) +
      textos_fig(
        titulo = sprintf(titulo_fmt, foco_mpio, pp(foco_valor)),
        subtitulo = sprintf(subtitulo_fmt, ultimo, prov$etiqueta,
                            pp(v_prov), pp(v_sub), pp(v_dep)),
        fuente = FUENTE_EDUCACION,
        nota = NOTA_EDUCACION
      )

    guardar_fig(p, paste0(id, "_", slug), destino, n_barras = n)

    # Los datos exactos de la figura quedan en el .xlsx de la sección
    escribir_datos_figura(
      dd[, c("municipio", "anio", columna)], archivo, id
    )
  }

  # --- fig 01: cobertura neta ------------------------------------------------
  # Cuanto más alta, mejor: se resalta el municipio con la cobertura más baja.
  barras_indicador(
    columna = "cobertura_neta", extremo = "min",
    id = "fig_01", slug = "cobertura_neta",
    titulo_fmt = "%s tiene la cobertura neta más baja de la provincia: %s",
    subtitulo_fmt = paste(
      "Población en edad escolar matriculada en el nivel que le corresponde, %d.",
      "Municipios de la provincia %s.",
      "Promedio ponderado: provincia %s, subregión %s, Antioquia %s."
    )
  )

  # --- fig 02: deserción escolar ---------------------------------------------
  barras_indicador(
    columna = "desercion", extremo = "max",
    id = "fig_02", slug = "desercion_escolar",
    titulo_fmt = "%s registra la mayor deserción escolar de la provincia: %s",
    subtitulo_fmt = paste(
      "Tasa de deserción escolar, %d. Municipios de la provincia %s.",
      "Promedio ponderado: provincia %s, subregión %s, Antioquia %s."
    )
  )

  # --- fig 03: repitencia escolar --------------------------------------------
  barras_indicador(
    columna = "repitencia", extremo = "max",
    id = "fig_03", slug = "repitencia_escolar",
    titulo_fmt = "%s registra la mayor repitencia escolar de la provincia: %s",
    subtitulo_fmt = paste(
      "Tasa de repitencia escolar, %d. Municipios de la provincia %s.",
      "Promedio ponderado: provincia %s, subregión %s, Antioquia %s."
    )
  )

  invisible(destino)
}
