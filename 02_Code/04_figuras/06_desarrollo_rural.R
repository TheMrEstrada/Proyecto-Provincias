# =============================================================================
# 06_desarrollo_rural.R — Figuras de la Sección 6: Desarrollo Rural
#
# FIGURAS:
#   fig_01_participacion_pecuaria   — peso de cada municipio en el inventario
#                                     pecuario de la provincia
#   fig_02_composicion_especies     — reparto de especies dentro de cada
#                                     municipio (barra apilada al 100 %)
#   fig_03_composicion_agricola     — reparto permanentes/transitorios de la
#                                     producción, por municipio (apilada 100 %)
#   fig_04_participacion_produccion — peso de cada municipio en la producción
#                                     agrícola provincial
#   fig_05_rendimiento_agricola     — rendimiento (t/ha) por municipio, con la
#                                     referencia provincial
#
# Todas del último año disponible en cada fuente.
#
# INPUTS:  la lista de tablas que produce 02_Code/03_tablas/06_desarrollo_rural.R
# OUTPUTS: 03_Outputs/<Provincia>/06_Desarrollo_Rural/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
#
# SUSTITUCIONES FRENTE AL CATÁLOGO (DISENO.md §5):
#   - fig 59 del catálogo ("Composición % producción agrícola PAP") estaba
#     especificada como TORTA. Se sustituye por barras horizontales ordenadas
#     (fig_04): el proyecto no usa tortas.
#   - fig 61 del catálogo ("% Área perdida vs Rendimiento", dispersión) no se
#     puede reproducir: el área perdida se eliminó del flujo de datos
#     (decisión de Pablo, 2026-08-05). Se sustituye por las barras de
#     rendimiento (fig_05), que es la variable que sí quedó en el flujo.
#   - figs 56 y 57 del catálogo (suelo rural) siguen fuera de alcance: no hay
#     fuente de suelo rural en el repositorio. La extensión municipal ya se
#     grafica en la sección 01, así que no se repite aquí.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

FUENTE_PECUARIA <- "UPRA, inventario pecuario municipal (2025)."
FUENTE_AGRICOLA <- paste(
  "UPRA — Evaluaciones Agropecuarias Municipales (EVA), Ministerio de",
  "Agricultura y Desarrollo Rural (2025)."
)
NOTA_SIN_AVES <- paste(
  "Cálculos propios. No incluye aves: el inventario avícola no está en la",
  "fuente disponible."
)

# --- Utilidades locales de trazado -------------------------------------------

#' Luminancia relativa WCAG de un color hexadecimal.
.luminancia <- function(hex) {
  v <- grDevices::col2rgb(hex)[, 1] / 255
  f <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  sum(f * c(0.2126, 0.7152, 0.0722))
}

#' Color de texto legible sobre un fondo dado: blanco o tinta primaria, el que
#' más contraste ofrezca. Las etiquetas dentro de un segmento apilado no pueden
#' ir siempre en tinta primaria (DISENO.md §2.5 supone fondo blanco).
.color_legible <- function(hex) {
  l <- .luminancia(hex)
  contraste_blanco <- 1.05 / (l + 0.05)
  contraste_tinta  <- (l + 0.05) / (.luminancia(COLOR$tinta_1) + 0.05)
  if (contraste_blanco >= contraste_tinta) "#FFFFFF" else COLOR$tinta_1
}

#' Barras horizontales apiladas al 100 %, ordenadas por el peso de la primera
#' serie. Etiqueta solo los segmentos que superan el umbral (DISENO.md §5).
#'
#' @param datos data.frame con `municipio`, `serie` (factor) y `valor`.
#' @param colores vector nombrado serie -> color.
#' @param umbral participación mínima para etiquetar el segmento.
.barras_apiladas_100 <- function(datos, colores, umbral = 0.08) {
  d <- datos |>
    dplyr::group_by(.data$municipio) |>
    dplyr::mutate(total = sum(.data$valor, na.rm = TRUE)) |>
    dplyr::ungroup() |>
    dplyr::filter(.data$total > 0) |>
    dplyr::mutate(parte = .data$valor / .data$total)

  primera <- levels(d$serie)[1]
  orden <- d[d$serie == primera, ]
  orden <- orden[order(orden$parte), ]                     # ascendente: mayor arriba
  d$municipio <- factor(d$municipio, levels = orden$municipio)

  # Centro de cada segmento, calculado a mano: position_stack() no acierta la
  # orientación de geom_text() en barras horizontales y desplaza las etiquetas.
  d <- d[order(d$municipio, d$serie), ]
  d <- d |>
    dplyr::group_by(.data$municipio) |>
    dplyr::mutate(centro = cumsum(.data$parte) - .data$parte / 2) |>
    dplyr::ungroup()

  d$color_texto <- vapply(as.character(d$serie),
                          function(s) .color_legible(colores[[s]]), character(1))
  d$etiqueta <- ifelse(d$parte >= umbral, pct_co(d$parte * 100, dec = 0), "")

  ggplot2::ggplot(d, ggplot2::aes(x = .data$parte, y = .data$municipio,
                                  fill = .data$serie)) +
    ggplot2::geom_col(width = 0.68, position = ggplot2::position_stack(reverse = TRUE),
                      color = COLOR$superficie, linewidth = 0.18) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$centro, label = .data$etiqueta,
                   color = .data$color_texto),
      size = PT$valor / .pt, family = FUENTE, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = colores) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)
}

# --- Figuras de la sección ----------------------------------------------------

figuras_desarrollo_rural <- function(prov, tabla) {
  message("== figuras 06 Desarrollo Rural — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "06_Desarrollo_Rural")
  archivo <- tabla$archivo

  # ==========================================================================
  # Inventario pecuario (último año de la serie)
  # ==========================================================================
  anio_pec <- max(tabla$participacion$anio, na.rm = TRUE)
  pec <- tabla$participacion |>
    dplyr::filter(.data$anio == anio_pec, !is.na(.data$participacion_pecuario_prov_pct))
  n_pec <- nrow(pec)
  lider_pec <- pec[which.max(pec$participacion_pecuario_prov_pct), ]
  total_pec <- sum(pec$total_especies, na.rm = TRUE)

  # --- fig 01: participación en el inventario pecuario provincial -----------
  p1 <- fig_barras(
    pec, categoria = municipio, valor = participacion_pecuario_prov_pct,
    resaltar = lider_pec$municipio,
    etiqueta = function(x) pct_co(x * 100, dec = 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s concentra el %s del inventario pecuario de la provincia",
        lider_pec$municipio,
        pct_co(lider_pec$participacion_pecuario_prov_pct * 100, dec = 0)
      ),
      subtitulo = sprintf(
        paste("Participación de cada municipio en las %s cabezas de las seis",
              "especies inventariadas. Provincia %s, %d."),
        num_co(total_pec, 0), prov$etiqueta, anio_pec
      ),
      fuente = FUENTE_PECUARIA,
      nota = NOTA_SIN_AVES
    )
  guardar_fig(p1, "fig_01_participacion_pecuaria", destino, n_barras = n_pec)
  escribir_datos_figura(
    pec[, c("municipio", "anio", "total_especies", "participacion_pecuario_prov_pct")],
    archivo, "fig_01"
  )

  # --- fig 02: composición del inventario por especie -----------------------
  # Máximo 4 segmentos (DISENO.md §5). Las tres especies que se muestran aparte
  # son FIJAS (bovinos, porcinos y equinos: las tres mayores de Antioquia) y no
  # se eligen por provincia, para que el mismo color signifique la misma especie
  # en los once informes.
  inv <- tabla$inventario |>
    dplyr::filter(.data$anio == anio_pec, .data$tipo_fila == "Municipio")
  especies <- names(ESPECIES_PECUARIAS)
  principales_esp <- c("bovinos", "porcinos", "equinos")
  otras_esp <- setdiff(especies, principales_esp)

  largo_pec <- inv |>
    dplyr::select(dplyr::all_of(c("municipio", especies))) |>
    tidyr::pivot_longer(dplyr::all_of(especies), names_to = "especie", values_to = "valor") |>
    dplyr::mutate(
      serie = dplyr::if_else(.data$especie %in% principales_esp,
                             unname(ESPECIES_PECUARIAS[.data$especie]),
                             "Otras especies")
    ) |>
    dplyr::group_by(.data$municipio, .data$serie) |>
    dplyr::summarise(valor = sum(.data$valor, na.rm = TRUE), .groups = "drop")

  niveles_pec <- c(unname(ESPECIES_PECUARIAS[principales_esp]), "Otras especies")
  largo_pec$serie <- factor(largo_pec$serie, levels = niveles_pec)
  colores_pec <- stats::setNames(
    c(unname(PALETA_SERIES)[1:3], COLOR$contexto), niveles_pec
  )

  # Titular: cuál es la especie predominante y en cuántos municipios lo es.
  # Las barras se ordenan por el peso de los bovinos (la primera serie), así que
  # el titular habla de ellos salvo que otra especie domine en más municipios.
  dominante <- largo_pec |>
    dplyr::group_by(.data$municipio) |>
    dplyr::slice_max(.data$valor, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::count(.data$serie, sort = TRUE)
  serie_top <- as.character(dominante$serie[1])
  articulo <- if (startsWith(serie_top, "Otras")) "Las" else "Los"
  n_bovinos <- sum(dominante$n[dominante$serie == "Bovinos"])

  # "búfalos, caprinos y ovinos" para el subtítulo
  agrupadas <- tolower(unname(ESPECIES_PECUARIAS[otras_esp]))
  agrupadas <- if (length(agrupadas) > 1) {
    paste(paste(utils::head(agrupadas, -1), collapse = ", "), "y",
          utils::tail(agrupadas, 1))
  } else {
    agrupadas
  }

  titulo_fig2 <- if (n_bovinos * 2 >= n_pec) {
    sprintf(paste("Los bovinos son la especie predominante en %d de los %d",
                  "municipios de la provincia"), n_bovinos, n_pec)
  } else {
    sprintf(paste("%s %s desplazan a los bovinos: predominan en %d de los %d",
                  "municipios de la provincia"),
            articulo, tolower(serie_top), dominante$n[1], n_pec)
  }

  p2 <- .barras_apiladas_100(largo_pec, colores_pec) +
    textos_fig(
      titulo = titulo_fig2,
      subtitulo = sprintf(
        paste("Composición porcentual del inventario pecuario de cada municipio.",
              "Provincia %s, %d. Los %s se agrupan en «Otras especies»."),
        prov$etiqueta, anio_pec, agrupadas
      ),
      fuente = FUENTE_PECUARIA,
      nota = NOTA_SIN_AVES
    )
  guardar_fig(p2, "fig_02_composicion_especies", destino, n_barras = n_pec + 1)
  escribir_datos_figura(largo_pec, archivo, "fig_02")

  # ==========================================================================
  # Producción agrícola (último año de la serie de cultivos)
  # ==========================================================================
  anio_agr <- max(tabla$composicion_agricola$anio, na.rm = TRUE)
  agr <- tabla$composicion_agricola |>
    dplyr::filter(.data$anio == anio_agr, .data$tipo_fila == "Municipio",
                  !is.na(.data$prod_total), .data$prod_total > 0)
  n_agr <- nrow(agr)
  total_agr <- sum(agr$prod_total, na.rm = TRUE)
  pct_perm_prov <- sum(agr$prod_perm, na.rm = TRUE) / total_agr

  # --- fig 03: reparto permanentes/transitorios por municipio ---------------
  largo_agr <- agr |>
    dplyr::select(dplyr::all_of(c("municipio", "prod_perm", "prod_tran"))) |>
    tidyr::pivot_longer(c("prod_perm", "prod_tran"),
                        names_to = "ciclo", values_to = "valor") |>
    dplyr::mutate(serie = factor(
      dplyr::if_else(.data$ciclo == "prod_perm", "Permanentes", "Transitorios"),
      levels = c("Permanentes", "Transitorios")
    ))
  colores_agr <- stats::setNames(unname(PALETA_SERIES)[1:2],
                                 c("Permanentes", "Transitorios"))

  p3 <- .barras_apiladas_100(largo_agr, colores_agr) +
    textos_fig(
      titulo = sprintf(
        "Los cultivos permanentes aportan el %s de la producción agrícola provincial",
        pct_co(pct_perm_prov * 100, dec = 0)
      ),
      subtitulo = sprintf(
        paste("Reparto de la producción (toneladas) entre cultivos permanentes y",
              "transitorios en cada municipio. Provincia %s, %d."),
        prov$etiqueta, anio_agr
      ),
      fuente = FUENTE_AGRICOLA,
      nota = "Cálculos propios."
    )
  guardar_fig(p3, "fig_03_composicion_agricola", destino, n_barras = n_agr + 1)
  escribir_datos_figura(largo_agr, archivo, "fig_03")

  # --- fig 04: participación de cada municipio en la producción provincial --
  # Sustituye la torta del catálogo (fig 59).
  lider_agr <- agr[which.max(agr$pct_prod_prov), ]
  p4 <- fig_barras(
    agr, categoria = municipio, valor = pct_prod_prov,
    resaltar = lider_agr$municipio,
    etiqueta = function(x) pct_co(x * 100, dec = 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s aporta el %s de la producción agrícola de la provincia",
        lider_agr$municipio, pct_co(lider_agr$pct_prod_prov * 100, dec = 0)
      ),
      subtitulo = sprintf(
        paste("Participación de cada municipio en las %s toneladas producidas.",
              "Provincia %s, %d."),
        num_co(total_agr, 0), prov$etiqueta, anio_agr
      ),
      fuente = FUENTE_AGRICOLA,
      nota = "Cálculos propios. Sustituye el gráfico de torta del catálogo (DISENO.md §5)."
    )
  guardar_fig(p4, "fig_04_participacion_produccion", destino, n_barras = n_agr)
  escribir_datos_figura(
    agr[, c("municipio", "anio", "prod_perm", "prod_tran", "prod_total", "pct_prod_prov")],
    archivo, "fig_04"
  )

  # --- fig 05: rendimiento agrícola por municipio ---------------------------
  # Sustituye la dispersión "% área perdida vs rendimiento" del catálogo
  # (fig 61): el área perdida ya no está en el flujo de datos.
  rend <- tabla$rendimiento |>
    dplyr::filter(.data$anio == anio_agr, .data$tipo_fila == "Municipio",
                  !is.na(.data$rendimiento))
  rend_prov <- tabla$rendimiento$rendimiento[
    tabla$rendimiento$anio == anio_agr & tabla$rendimiento$tipo_fila == "Total provincia"
  ][1]
  lider_rend <- rend[which.max(rend$rendimiento), ]

  p5 <- fig_barras(
    rend, categoria = municipio, valor = rendimiento,
    resaltar = lider_rend$municipio,
    etiqueta = function(x) num_co(x, 1),
    referencia = rend_prov,
    etiqueta_referencia = paste0("Provincia: ", num_co(rend_prov, 1), " t/ha")
  ) +
    textos_fig(
      titulo = sprintf(
        "%s obtiene el mayor rendimiento agrícola de la provincia: %s t/ha",
        lider_rend$municipio, num_co(lider_rend$rendimiento, 1)
      ),
      subtitulo = sprintf(
        paste("Toneladas producidas por hectárea cosechada (todos los cultivos).",
              "Provincia %s, %d. Rendimiento provincial: %s t/ha."),
        prov$etiqueta, anio_agr, num_co(rend_prov, 1)
      ),
      fuente = FUENTE_AGRICOLA,
      nota = "Cálculos propios: Σ producción / Σ área cosechada."
    )
  guardar_fig(p5, "fig_05_rendimiento_agricola", destino, n_barras = nrow(rend))
  escribir_datos_figura(
    rend[, c("municipio", "anio", "produccion_cultivo", "area_cosechada", "rendimiento")],
    archivo, "fig_05"
  )

  invisible(destino)
}
