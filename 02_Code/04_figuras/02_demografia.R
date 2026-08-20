# =============================================================================
# 02_demografia.R — Figuras de la Sección 2: Demografía
#
# FIGURAS:
#   fig_01_poblacion_municipio      población proyectada 2025 por municipio
#   fig_02_composicion_urbana_rural reparto cabecera / resto rural (apilada 100 %)
#   fig_03_densidad_poblacional     habitantes por km², con la media provincial
#   fig_04_piramide_poblacional     población por sexo y grupos decenales de edad
#   fig_05_indice_envejecimiento    índice de envejecimiento por municipio
#
# INPUTS:  la lista de tablas que produce 02_Code/03_tablas/02_demografia.R
# OUTPUTS: 03_Outputs/<Provincia>/02_Demografia/figuras/*.{png,pdf}
#          + hojas "_fig_NN" en demografia.xlsx (datos exactos de cada figura)
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Grupos decenales tal como los nombra la hoja estructura_edad, y su rótulo.
.SUFIJOS_EDAD <- c("0_9", "10_19", "20_29", "30_39", "40_49", "50_59",
                   "60_69", "70_79", "80_mas")
.ROTULOS_EDAD <- c("0 a 9", "10 a 19", "20 a 29", "30 a 39", "40 a 49",
                   "50 a 59", "60 a 69", "70 a 79", "80 o más")

.FUENTE_DANE <- "DANE, proyecciones de población municipal 2025. Cálculos propios."

#' Solo las filas municipales (las agregadas no van en las figuras de barras).
.solo_municipios <- function(d) dplyr::filter(d, !is.na(.data$ind_mpio))

#' Valor de una columna en la fila de total provincial.
.valor_provincia <- function(d, columna) {
  fila <- dplyr::filter(d, .data$tipo_fila == "Total provincia")
  if (nrow(fila) == 0) return(NA_real_)
  as.numeric(fila[[columna]][1])
}

# --- fig 01: población por municipio -----------------------------------------

.fig_poblacion <- function(prov, poblacion, destino, archivo) {
  d <- .solo_municipios(poblacion)
  mayor <- d[which.max(d$habitantes_total), ]
  total <- sum(d$habitantes_total, na.rm = TRUE)

  p <- fig_barras(d, categoria = municipio, valor = habitantes_total,
                  resaltar = mayor$municipio, etiqueta = function(x) num_co(x, 0)) +
    textos_fig(
      titulo = sprintf("%s concentra el %s de la población de la provincia",
                       mayor$municipio, pct_co(mayor$part_total_prov * 100, dec = 0)),
      subtitulo = sprintf(
        "Población proyectada a 2025 por municipio · Provincia %s (%s habitantes)",
        prov$etiqueta, num_co(total, 0)
      ),
      fuente = .FUENTE_DANE
    )

  guardar_fig(p, "fig_01_poblacion_municipio", destino, n_barras = nrow(d))
  escribir_datos_figura(
    d[, c("municipio", "habitantes_total", "part_total_prov")], archivo, "fig_01"
  )
}

# --- fig 02: composición urbana-rural ----------------------------------------

.fig_urbana_rural <- function(prov, poblacion, destino, archivo) {
  d <- .solo_municipios(poblacion)
  n <- nrow(d)
  n_rural <- sum(d$pct_rural > 0.5, na.rm = TRUE)

  # El municipio más rural arriba: los niveles del factor se leen de abajo
  # hacia arriba en el eje Y.
  orden <- d$municipio[order(d$pct_rural)]

  largo <- d |>
    dplyr::select(municipio, pct_cabecera, pct_rural) |>
    tidyr::pivot_longer(c("pct_cabecera", "pct_rural"),
                        names_to = "zona", values_to = "participacion") |>
    dplyr::mutate(
      zona = factor(
        ifelse(.data$zona == "pct_cabecera", "Cabecera municipal",
               "Centros poblados y rural disperso"),
        levels = c("Cabecera municipal", "Centros poblados y rural disperso")
      ),
      municipio = factor(.data$municipio, levels = orden),
      # La posición de la etiqueta se calcula a mano (el centro de cada
      # segmento): position_stack() no reordena igual en geom_col y en geom_text
      # cuando las barras son horizontales, y las etiquetas se descuadran.
      centro = ifelse(.data$zona == "Cabecera municipal",
                      .data$participacion / 2,
                      1 - .data$participacion / 2),
      # Texto sobre la marca: blanco sobre el azul, tinta oscura sobre el
      # naranja (§2.5: el texto nunca lleva el color de la serie).
      color_texto = ifelse(.data$zona == "Cabecera municipal",
                           COLOR$superficie, COLOR$tinta_1),
      etiqueta = ifelse(.data$participacion >= 0.08,
                        pct_co(.data$participacion * 100, dec = 0), "")
    )

  # El titular cuenta en cuántos municipios manda cada zona; si manda en todos,
  # el "n de n" sobra.
  dominante <- if (n_rural >= n - n_rural) "fuera de la cabecera" else "en la cabecera"
  cuantos <- if (dominante == "fuera de la cabecera") n_rural else n - n_rural
  titulo <- if (cuantos == n) {
    sprintf("En los %d municipios de la provincia la mayoría de la población vive %s",
            n, dominante)
  } else {
    sprintf("En %d de los %d municipios la mayoría de la población vive %s",
            cuantos, n, dominante)
  }

  p <- ggplot2::ggplot(largo, ggplot2::aes(x = .data$participacion,
                                           y = .data$municipio,
                                           fill = .data$zona)) +
    ggplot2::geom_col(width = 0.68, position = ggplot2::position_stack(reverse = TRUE),
                      color = COLOR$superficie, linewidth = 0.18) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$centro, label = .data$etiqueta,
                   color = .data$color_texto),
      size = PT$valor / .pt, family = FUENTE, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = unname(PALETA_SERIES[1:2])) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE) +
    textos_fig(
      titulo = titulo,
      subtitulo = sprintf(
        "Reparto de la población municipal entre cabecera y resto rural, 2025 · Provincia %s",
        prov$etiqueta
      ),
      fuente = .FUENTE_DANE
    )

  guardar_fig(p, "fig_02_composicion_urbana_rural", destino, n_barras = n)
  escribir_datos_figura(
    d[, c("municipio", "habitantes_cabecera", "pct_cabecera",
          "habitantes_rural", "pct_rural")], archivo, "fig_02"
  )
}

# --- fig 03: densidad poblacional --------------------------------------------

.fig_densidad <- function(prov, poblacion, destino, archivo) {
  d <- .solo_municipios(poblacion)
  mayor <- d[which.max(d$densidad_pob), ]
  dens_prov <- .valor_provincia(poblacion, "densidad_pob")

  p <- fig_barras(d, categoria = municipio, valor = densidad_pob,
                  resaltar = mayor$municipio,
                  etiqueta = function(x) num_co(x, 1),
                  referencia = dens_prov,
                  etiqueta_referencia = paste0("Provincia: ", num_co(dens_prov, 1))) +
    textos_fig(
      titulo = sprintf(
        "%s es el municipio más densamente poblado: %s veces la densidad media de la provincia",
        mayor$municipio, num_co(mayor$densidad_pob / dens_prov, 1)
      ),
      subtitulo = sprintf(
        "Habitantes por km² en 2025 · Provincia %s (media provincial: %s hab/km²)",
        prov$etiqueta, num_co(dens_prov, 1)
      ),
      fuente = paste("DANE, proyecciones de población 2025;",
                     "Gobernación de Antioquia, Anuario Estadístico (área municipal).",
                     "Cálculos propios.")
    )

  guardar_fig(p, "fig_03_densidad_poblacional", destino, n_barras = nrow(d))
  escribir_datos_figura(d[, c("municipio", "habitantes_total", "densidad_pob")],
                        archivo, "fig_03")
}

# --- fig 04: pirámide poblacional --------------------------------------------

.fig_piramide <- function(prov, estructura, destino, archivo) {
  fila <- dplyr::filter(estructura, .data$tipo_fila == "Total provincia")
  if (nrow(fila) == 0) {
    stop("La hoja estructura_edad no trae la fila de total provincial.", call. = FALSE)
  }

  hombres <- as.numeric(fila[1, paste0("h_edad_", .SUFIJOS_EDAD)])
  mujeres <- as.numeric(fila[1, paste0("m_edad_", .SUFIJOS_EDAD)])

  d <- data.frame(
    banda = factor(rep(.ROTULOS_EDAD, 2), levels = .ROTULOS_EDAD),
    sexo  = factor(rep(c("Hombres", "Mujeres"), each = length(.SUFIJOS_EDAD)),
                   levels = c("Hombres", "Mujeres")),
    personas = c(hombres, mujeres)
  )
  # Hombres a la izquierda: se dibujan en negativo y se etiquetan en positivo.
  d$x <- ifelse(d$sexo == "Hombres", -d$personas, d$personas)
  d$hj <- ifelse(d$sexo == "Hombres", 1.15, -0.15)

  tope   <- max(d$personas, na.rm = TRUE)
  limite <- tope * 1.28
  marcas <- pretty(c(-tope, tope), n = 6)
  marcas <- marcas[abs(marcas) <= limite]

  total   <- sum(d$personas, na.rm = TRUE)
  menores <- sum(d$personas[d$banda %in% .ROTULOS_EDAD[1:3]], na.rm = TRUE)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$banda,
                                       fill = .data$sexo)) +
    ggplot2::geom_col(width = 0.68) +
    ggplot2::geom_vline(xintercept = 0, color = COLOR$contexto, linewidth = 0.3) +
    ggplot2::geom_text(
      ggplot2::aes(label = num_co(.data$personas, 0), hjust = .data$hj),
      size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::scale_fill_manual(values = unname(PALETA_SERIES[1:2])) +
    ggplot2::scale_x_continuous(limits = c(-limite, limite), breaks = marcas,
                                labels = function(x) num_co(abs(x), 0)) +
    ggplot2::labs(x = NULL, y = "Grupo de edad") +
    theme_provincias(grilla = "ninguna", eje_x_visible = TRUE) +
    textos_fig(
      titulo = sprintf("El %s de la población de la provincia tiene menos de 30 años",
                       pct_co(menores / total * 100, dec = 0)),
      subtitulo = sprintf(
        "Población por sexo y grupos decenales de edad, 2025 · Provincia %s (%s habitantes)",
        prov$etiqueta, num_co(total, 0)
      ),
      fuente = .FUENTE_DANE
    )

  guardar_fig(p, "fig_04_piramide_poblacional", destino, alto = 11)
  escribir_datos_figura(d[, c("banda", "sexo", "personas")], archivo, "fig_04")
}

# --- fig 05: índice de envejecimiento ----------------------------------------

.fig_envejecimiento <- function(prov, vitales, destino, archivo) {
  d <- .solo_municipios(vitales)
  mayor <- d[which.max(d$I_enve_T), ]
  # La fila provincial de esta hoja es un promedio ponderado por población.
  ref <- .valor_provincia(vitales, "I_enve_T")

  p <- fig_barras(d, categoria = municipio, valor = I_enve_T,
                  resaltar = mayor$municipio,
                  etiqueta = function(x) num_co(x, 1),
                  referencia = ref,
                  etiqueta_referencia = paste0("Provincia: ", num_co(ref, 1))) +
    textos_fig(
      titulo = sprintf(
        "%s es el municipio más envejecido de la provincia, con %s adultos mayores por cada 100 menores de 15 años",
        mayor$municipio, num_co(mayor$I_enve_T, 0)
      ),
      # El valor provincial ya no es un promedio ponderado de los índices
      # municipales sino la razón entre las sumas, que es lo que manda la regla
      # 6 para una razón entre dos conteos (F-2-015).
      subtitulo = sprintf(
        paste("Índice de envejecimiento (población de 65 años o más por cada 100",
              "menores de 15), 2025 · Provincia %s (sobre las sumas de la",
              "provincia: %s)"),
        prov$etiqueta, num_co(ref, 1)
      ),
      fuente = .FUENTE_DANE
    )

  guardar_fig(p, "fig_05_indice_envejecimiento", destino, n_barras = nrow(d))
  escribir_datos_figura(d[, c("municipio", "I_enve_T")], archivo, "fig_05")
}

# --- Punto de entrada ---------------------------------------------------------

figuras_demografia <- function(prov, tabla) {
  message("== figuras 02 Demografía — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "02_Demografia")
  archivo <- file.path(dir_seccion(prov, "02_Demografia"), "demografia.xlsx")

  .fig_poblacion(prov, tabla$poblacion, destino, archivo)
  .fig_urbana_rural(prov, tabla$poblacion, destino, archivo)
  .fig_densidad(prov, tabla$poblacion, destino, archivo)
  .fig_piramide(prov, tabla$estructura_edad, destino, archivo)
  .fig_envejecimiento(prov, tabla$natalidad_mortalidad, destino, archivo)

  invisible(destino)
}
