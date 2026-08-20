# =============================================================================
# 09_salud.R — Figuras de la Sección 9: Salud
#
# FIGURAS:
#   fig_01_aseguramiento_sgsss  — composición de los afiliados al SGSSS por
#                                 régimen (barras apiladas al 100 %)
#   fig_02_bajo_peso            — % de nacidos con bajo peso al nacer
#   fig_03_enfermedades_vectores— tasas de dengue, malaria y leishmaniasis
#                                 (múltiplos pequeños: cada enfermedad tiene su
#                                 propio denominador y su propia escala)
#   fig_04_suicidios            — tasa de intento de suicidio y de suicidio
#                                 consumado (barras agrupadas)
#
# La mortalidad infantil 2020-2024 va como TABLA en el informe (catálogo de
# figuras, fig. 73), no como gráfico: queda en la hoja del .xlsx de la sección.
#
# INPUTS:  las tablas que produce 02_Code/03_tablas/09_salud.R
# OUTPUTS: 03_Outputs/<Provincia>/09_Salud/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Fuentes tal como las declara el diccionario de cada insumo.
FUENTE_SALUD <- paste(
  "Dirección Seccional de Salud y Seguridad Social de Antioquia,",
  "Gobernación de Antioquia (2023)."
)
FUENTE_SIVIGILA <- "SIVIGILA, Instituto Nacional de Salud (2021-2023)."
FUENTE_ASEGURAMIENTO <- paste(
  "Gobernación de Antioquia, población afiliada al SGSSS por régimen",
  "(corte diciembre de 2025)."
)

# El titular de la figura de vectores. Las tres enfermedades no comparten
# denominador, así que no se suman ni se rankean entre sí: se nombra al
# municipio que encabeza cada una. Si el mismo los encabeza todos la frase se
# colapsa, y si la provincia no registra casos no se nombra a nadie.
VECTORES_CON_ARTICULO <- c(dengue = "el dengue", malaria = "la malaria",
                           leishmaniasis = "la leishmaniasis")

.unir_y <- function(x) {
  if (length(x) < 2L) return(paste(x, collapse = ""))
  paste(paste(x[-length(x)], collapse = ", "), "y", x[length(x)])
}

.titular_vectores <- function(lideres, provincia) {
  n_total <- length(lideres)
  lideres <- lideres[!is.na(lideres)]
  if (length(lideres) == 0L) {
    return(sprintf(
      "La provincia %s no registra casos de enfermedades transmitidas por vectores",
      provincia))
  }
  nombres <- VECTORES_CON_ARTICULO[names(lideres)]
  ms <- unique(unname(lideres))
  if (length(ms) == 1L) {
    if (length(lideres) == n_total) {
      return(sprintf(
        "%s encabeza las tres enfermedades transmitidas por vectores de la provincia",
        ms))
    }
    return(sprintf("%s encabeza %s en la provincia", ms, .unir_y(nombres)))
  }
  partes <- vapply(ms, function(m) .unir_y(nombres[lideres == m]), character(1))
  paste(c(sprintf("%s encabeza %s", ms[1], partes[1]),
          sprintf("%s, %s", ms[-1], partes[-1])), collapse = "; ")
}

figuras_salud <- function(prov, tabla) {
  message("== figuras 09 Salud — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "09_Salud")
  archivo <- file.path(dir_seccion(prov, "09_Salud"), "salud.xlsx")

  #' Solo municipios: las filas agregadas no van en los gráficos por municipio.
  solo_municipios <- function(d) dplyr::filter(d, .data$tipo_fila == "Municipio")

  #' Valor de una fila agregada (NA si esa fila no existe en la hoja).
  agregado <- function(d, tipo, columna) {
    v <- d[[columna]][d$tipo_fila == tipo]
    if (length(v)) v[1] else NA_real_
  }
  #' "26,9 %" a partir de una proporción.
  pp <- function(x, dec = 1) pct_co(x * 100, dec = dec)
  #' "1.167,9" — tasas con un decimal, en formato colombiano.
  tt <- function(x) num_co(x, 1)

  n <- nrow(solo_municipios(tabla$bajo_peso))

  # --- fig 01: composición de afiliados al SGSSS ----------------------------
  # Barras apiladas al 100 %: tres regímenes, el subsidiado primero porque es el
  # que carga el mensaje. Se etiquetan los segmentos que superan el 8 %
  # (DISENO.md §5); el de régimen especial nunca lo alcanza.
  aseg <- solo_municipios(tabla$aseguramiento_sgsss)
  # Nombres cortos: el subtítulo ya dice que son regímenes y una leyenda larga
  # se sale del ancho de caja de 16 cm.
  regimenes <- c("Subsidiado", "Contributivo", "Especial y de excepción")

  d1 <- aseg |>
    dplyr::transmute(
      municipio,
      Subsidiado                = .data$prop_subsidiado,
      Contributivo              = .data$prop_contributivo,
      `Especial y de excepción` = .data$prop_especial
    ) |>
    tidyr::pivot_longer(-"municipio", names_to = "regimen", values_to = "proporcion") |>
    dplyr::mutate(
      regimen   = factor(.data$regimen, levels = regimenes),
      municipio = factor(.data$municipio,
                         levels = aseg$municipio[order(aseg$prop_subsidiado)])
    ) |>
    dplyr::arrange(.data$municipio, .data$regimen) |>
    dplyr::group_by(.data$municipio) |>
    dplyr::mutate(centro = cumsum(.data$proporcion) - .data$proporcion / 2) |>
    dplyr::ungroup()

  # El texto sobre el segmento va en el color que contrasta con ese segmento
  # (blanco sobre el azul marino, tinta primaria sobre el naranja); nunca en el
  # color de la serie.
  d1$color_etiqueta <- ifelse(d1$regimen == regimenes[1], COLOR$superficie, COLOR$tinta_1)
  d1$etiqueta <- ifelse(d1$proporcion >= 0.08, pp(d1$proporcion, 0), "")

  prop_sub_prov <- agregado(tabla$aseguramiento_sgsss, "Total provincia", "prop_subsidiado")

  p1 <- ggplot2::ggplot(d1, ggplot2::aes(x = .data$proporcion, y = .data$municipio,
                                         fill = .data$regimen)) +
    ggplot2::geom_col(width = 0.68, position = ggplot2::position_stack(reverse = TRUE),
                      color = COLOR$superficie, linewidth = 0.5 / .pt) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$centro, label = .data$etiqueta, color = .data$color_etiqueta),
      size = PT$valor / .pt, family = FUENTE, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = unname(PALETA_SERIES[1:3])) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE) +
    textos_fig(
      titulo = sprintf(
        "El régimen subsidiado concentra el %s de los afiliados al SGSSS de la provincia",
        pp(prop_sub_prov, 1)
      ),
      subtitulo = sprintf(
        paste("Composición de los afiliados por régimen, corte diciembre de 2025.",
              "Municipios de la provincia %s."),
        prov$etiqueta
      ),
      fuente = FUENTE_ASEGURAMIENTO,
      nota = "Cálculos propios. El régimen especial y de excepción suma excepción, fuerza pública e INPEC."
    )

  guardar_fig(p1, "fig_01_aseguramiento_sgsss", destino, n_barras = n)
  escribir_datos_figura(
    aseg[, c("municipio", "prop_subsidiado", "prop_contributivo", "prop_especial")],
    archivo, "fig_01"
  )

  # --- fig 02: bajo peso al nacer -------------------------------------------
  bp <- solo_municipios(tabla$bajo_peso)
  peor <- bp[which.max(bp$bajo_peso), ]
  bp_prov <- agregado(tabla$bajo_peso, "Total provincia", "bajo_peso")
  bp_sub  <- agregado(tabla$bajo_peso, "Total subregión", "bajo_peso")
  bp_dep  <- agregado(tabla$bajo_peso, "Total departamento", "bajo_peso")

  p2 <- fig_barras(
    bp, categoria = municipio, valor = bajo_peso,
    resaltar = peor$municipio,
    etiqueta = function(x) pp(x),
    referencia = bp_prov,
    etiqueta_referencia = paste0("Provincia: ", pp(bp_prov))
  ) +
    textos_fig(
      titulo = sprintf(
        "%s tiene la mayor proporción de nacidos con bajo peso de la provincia: %s",
        peor$municipio, pp(peor$bajo_peso)
      ),
      subtitulo = sprintf(
        paste("Porcentaje de nacidos vivos con menos de 2.500 gramos, 2023.",
              "Municipios de la provincia %s.",
              "Promedio ponderado por nacimientos: provincia %s, subregión %s, Antioquia %s."),
        prov$etiqueta, pp(bp_prov), pp(bp_sub), pp(bp_dep)
      ),
      fuente = FUENTE_SALUD,
      nota = "Cálculos propios."
    )

  guardar_fig(p2, "fig_02_bajo_peso", destino, n_barras = n)
  escribir_datos_figura(bp[, c("municipio", "bajo_peso")], archivo, "fig_02")

  # --- fig 03: enfermedades transmitidas por vectores -----------------------
  # Múltiplos pequeños en vez de barras agrupadas: las tres enfermedades tienen
  # denominadores distintos (la leishmaniasis se mide sobre población rural) y
  # órdenes de magnitud distintos, así que una escala común sería ilegible y
  # además compararía cosas que no son comparables (DISENO.md §2.1).
  vec <- solo_municipios(tabla$enfermedades_tropicales)
  enfermedades <- c(dengue = "Dengue", malaria = "Malaria",
                    leishmaniasis = "Leishmaniasis")
  # Las tres tasas NO se suman: el dengue y la malaria se miden sobre población
  # total y la leishmaniasis sobre población RURAL, de modo que el total sería un
  # número sin significado en el que la leishmaniasis pesa de más por tener el
  # denominador más pequeño. Es la misma regla que ya aplica la prosa de esta
  # sección (05_documento/R/secciones.R): cada enfermedad se reporta con su
  # denominador y no se rankean entre sí. En consecuencia:
  #   - el titular nombra al municipio que encabeza CADA enfermedad;
  #   - el orden vertical usa la posición promedio dentro de cada enfermedad,
  #     que es adimensional, y se publica como columna (regla 11).
  tasas  <- vec[, names(enfermedades), drop = FALSE]
  rangos <- sapply(tasas, rank, na.last = "keep")
  dim(rangos) <- c(nrow(vec), ncol(tasas))
  orden  <- rowMeans(rangos, na.rm = TRUE)
  orden[is.na(orden)] <- 0
  vec$posicion_promedio <- round(orden, 2)

  lideres <- vapply(names(enfermedades), function(v) {
    x <- tasas[[v]]
    if (all(is.na(x)) || max(x, na.rm = TRUE) <= 0) NA_character_
    else vec$municipio[which.max(x)]
  }, character(1))

  d3 <- vec |>
    dplyr::select(municipio, dplyr::all_of(names(enfermedades))) |>
    tidyr::pivot_longer(-"municipio", names_to = "enfermedad", values_to = "tasa") |>
    dplyr::mutate(
      enfermedad = factor(.data$enfermedad, levels = names(enfermedades),
                          labels = unname(enfermedades)),
      municipio  = factor(.data$municipio, levels = vec$municipio[order(orden)])
    )

  p3 <- ggplot2::ggplot(d3, ggplot2::aes(x = .data$tasa, y = .data$municipio,
                                         fill = .data$enfermedad)) +
    ggplot2::geom_col(width = 0.68, show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = tt(.data$tasa)), hjust = -0.15,
                       size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1) +
    ggplot2::facet_wrap(~ .data$enfermedad, nrow = 1, scales = "free_x") +
    ggplot2::scale_fill_manual(values = unname(PALETA_SERIES[1:3])) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.55))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(size = PT$categoria, face = "bold",
                                         color = COLOR$tinta_1, hjust = 0,
                                         margin = ggplot2::margin(b = 3)),
      panel.spacing.x = grid::unit(0.35, "cm")
    ) +
    textos_fig(
      titulo = .titular_vectores(lideres, prov$etiqueta),
      subtitulo = sprintf(
        paste("Casos por cada 100.000 habitantes (leishmaniasis: por cada 100.000",
              "habitantes rurales), 2023. Municipios de la provincia %s.",
              "Cada panel tiene su propia escala; los municipios se ordenan por",
              "su posición promedio en las tres enfermedades."),
        prov$etiqueta
      ),
      fuente = FUENTE_SALUD,
      nota = "Cálculos propios."
    )

  guardar_fig(p3, "fig_03_enfermedades_vectores", destino, n_barras = n)
  escribir_datos_figura(
    vec[, c("municipio", names(enfermedades), "posicion_promedio")], archivo, "fig_03"
  )

  # --- fig 04: intento de suicidio y suicidio consumado ---------------------
  # Barras agrupadas: las dos tasas comparten denominador (100 mil habitantes),
  # así que sí van en una misma escala; la brecha entre ambas es el mensaje.
  su <- solo_municipios(tabla$suicidios)
  indicadores <- c(tis_total = "Intento de suicidio", ts_total = "Suicidio consumado")

  d4 <- su |>
    dplyr::select(municipio, dplyr::all_of(names(indicadores))) |>
    tidyr::pivot_longer(-"municipio", names_to = "indicador", values_to = "tasa") |>
    dplyr::mutate(
      indicador = factor(.data$indicador, levels = names(indicadores),
                         labels = unname(indicadores)),
      municipio = factor(.data$municipio, levels = su$municipio[order(su$tis_total)])
    )

  peor_su  <- su[which.max(su$tis_total), ]
  tis_prov <- agregado(tabla$suicidios, "Total provincia", "tis_total")
  ts_prov  <- agregado(tabla$suicidios, "Total provincia", "ts_total")
  tis_dep  <- agregado(tabla$suicidios, "Total departamento", "tis_total")

  # reverse = TRUE deja el intento de suicidio arriba dentro de cada grupo, en
  # el mismo orden en que aparece en la leyenda.
  dodge <- ggplot2::position_dodge(width = 0.78, reverse = TRUE)

  p4 <- ggplot2::ggplot(d4, ggplot2::aes(x = .data$tasa, y = .data$municipio,
                                         fill = .data$indicador)) +
    ggplot2::geom_col(width = 0.7, position = dodge) +
    ggplot2::geom_text(ggplot2::aes(label = tt(.data$tasa)), position = dodge,
                       hjust = -0.15, size = PT$valor / .pt, family = FUENTE,
                       color = COLOR$tinta_1) +
    ggplot2::scale_fill_manual(values = unname(PALETA_SERIES[1:2])) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.16))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE) +
    textos_fig(
      titulo = sprintf(
        "%s registra la mayor tasa de intento de suicidio de la provincia: %s por cada 100.000 habitantes",
        peor_su$municipio, tt(peor_su$tis_total)
      ),
      subtitulo = sprintf(
        paste("Casos por cada 100.000 habitantes, promedio anual 2021-2023.",
              "Municipios de la provincia %s.",
              "Promedio ponderado por población: provincia %s (intento) y %s (consumado);",
              "Antioquia %s (intento)."),
        prov$etiqueta, tt(tis_prov), tt(ts_prov), tt(tis_dep)
      ),
      fuente = FUENTE_SIVIGILA,
      nota = "Cálculos propios."
    )

  guardar_fig(p4, "fig_04_suicidios", destino, alto = 4 + 0.9 * n)
  escribir_datos_figura(su[, c("municipio", names(indicadores))], archivo, "fig_04")

  invisible(destino)
}
