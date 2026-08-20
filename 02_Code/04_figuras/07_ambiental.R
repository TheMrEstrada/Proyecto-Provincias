# =============================================================================
# 07_ambiental.R — Figuras de la Sección 7: Ambiental
#
# FIGURAS:
#   fig_01_areas_protegidas    área protegida de cada municipio (km²)
#   fig_02_irca                IRCA del último año por municipio, con el
#                              promedio provincial como referencia
#   fig_03_irca_evolucion      serie del IRCA promedio: provincia vs. Antioquia
#   fig_04_perdida_cobertura   pérdida de cobertura arbórea 2001-2023, como
#                              porcentaje de la cobertura de 2000
#   fig_05_desastres_tipo      eventos de la provincia por tipo de emergencia
#   fig_06_eventos_anio        serie anual de emergencias en la provincia
#   fig_07_imrc                riesgo por déficit y por exceso de lluvias
#                              (dumbbell) por municipio
#
# INPUTS:  la lista que devuelve 02_Code/03_tablas/07_ambiental.R
# OUTPUTS: 03_Outputs/<Provincia>/07_Ambiental/figuras/*.{png,pdf}
#          + hojas auxiliares "_fig_NN" en ambiental.xlsx (DISENO.md §8)
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Fuentes de los datos (tal como las cita el Anexo 1) ---------------------
.FUENTE <- list(
  areas     = "Parques Nacionales Naturales de Colombia (PNNC). Cálculos propios.",
  irca      = "Instituto Nacional de Salud (INS), SIVICAP. Cálculos propios.",
  cobertura = "Global Forest Watch, 2001-2023. Cálculos propios.",
  desastres = "Unidad Nacional para la Gestión del Riesgo de Desastres (UNGRD). Cálculos propios.",
  imrc      = "Departamento Nacional de Planeación (DNP), 2024."
)

# --- Geoms compuestos que no están en 02_tema.R -------------------------------

#' Separa verticalmente etiquetas que caerían una encima de otra, conservando
#' el orden de los valores. Sin esto, dos series que terminan en cifras
#' parecidas escriben su rótulo en el mismo sitio.
.separar_etiquetas <- function(valores, minimo) {
  orden <- order(valores)
  y <- valores[orden]
  for (i in seq_along(y)[-1]) {
    if (y[i] - y[i - 1] < minimo) y[i] <- y[i - 1] + minimo
  }
  salida <- numeric(length(valores))
  salida[orden] <- y
  salida
}

#' Serie de tiempo con etiqueta directa al final de cada línea (DISENO.md §5).
#'
#' @param datos data.frame con `anio`, `valor` y `serie`.
#' @param etiqueta función que formatea el valor de la etiqueta directa.
#' @param dec_eje decimales del eje Y.
#' @param paso_x cada cuántos años se rotula el eje X.
.fig_serie <- function(datos, etiqueta = function(x) num_co(x, 1), dec_eje = 0,
                       paso_x = 3) {
  series <- unique(datos$serie)
  colores <- stats::setNames(unname(PALETA_SERIES)[seq_along(series)], series)

  anios <- range(datos$anio, na.rm = TRUE)
  # Marcador solo en el primer y último punto de cada serie
  extremos <- dplyr::filter(datos, .data$anio %in% anios)
  final <- dplyr::filter(datos, .data$anio == anios[2])
  final$y_etiqueta <- .separar_etiquetas(
    final$valor, minimo = max(datos$valor, na.rm = TRUE) * 0.07
  )

  ggplot2::ggplot(datos, ggplot2::aes(x = .data$anio, y = .data$valor,
                                      color = .data$serie, group = .data$serie)) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::geom_point(data = extremos, size = 1.5) +
    ggplot2::geom_text(
      data = final,
      ggplot2::aes(x = .data$anio, y = .data$y_etiqueta,
                   label = paste0(.data$serie, ": ", etiqueta(.data$valor))),
      inherit.aes = FALSE,
      hjust = 0, nudge_x = max(diff(anios), 1) * 0.02,
      size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::scale_color_manual(values = colores, guide = "none") +
    ggplot2::scale_x_continuous(
      breaks = seq(anios[1], anios[2], by = paso_x),
      expand = ggplot2::expansion(mult = c(0.02, 0.30))
    ) +
    ggplot2::scale_y_continuous(
      labels = etiqueta_num(dec_eje), limits = c(0, NA),
      expand = ggplot2::expansion(mult = c(0, 0.10))
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "y")
}

#' Dumbbell: dos momentos (o dos indicadores) por categoría (DISENO.md §5).
#'
#' @param datos data.frame con `categoria`, `inicio` y `fin`; se ordena por `fin`.
.fig_dumbbell <- function(datos, nombre_inicio, nombre_fin,
                          etiqueta = function(x) num_co(x, 1)) {
  d <- datos[order(datos$fin), , drop = FALSE]
  d$categoria <- factor(d$categoria, levels = d$categoria)

  largo <- tidyr::pivot_longer(d, c("inicio", "fin"), names_to = "extremo",
                               values_to = "valor")
  largo$serie <- factor(ifelse(largo$extremo == "inicio", nombre_inicio, nombre_fin),
                        levels = c(nombre_inicio, nombre_fin))

  tope <- max(d$fin, na.rm = TRUE)
  holgura <- tope * 0.12

  ggplot2::ggplot(d, ggplot2::aes(y = .data$categoria)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$inicio, xend = .data$fin, yend = .data$categoria),
      color = COLOR$contexto, linewidth = 0.4
    ) +
    ggplot2::geom_point(
      data = largo,
      ggplot2::aes(x = .data$valor, color = .data$serie), size = 2
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$inicio, label = etiqueta(.data$inicio)),
      hjust = 1.3, size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$fin, label = etiqueta(.data$fin)),
      hjust = -0.3, size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::scale_color_manual(
      values = stats::setNames(c(COLOR$contexto, COLOR$resalte),
                               c(nombre_inicio, nombre_fin))
    ) +
    ggplot2::scale_x_continuous(
      limits = c(0, tope + holgura),
      expand = ggplot2::expansion(mult = c(0.02, 0.06))
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)
}

#' Solo las filas municipales (las agregadas van sin código DANE).
.solo_municipios <- function(datos) dplyr::filter(datos, !is.na(.data$ind_mpio))

# La UNGRD registra los tipos de evento en mayúsculas y SIN tildes; para las
# figuras se pasan a capitalización normal y se les devuelve la ortografía.
.TILDES_EVENTO <- c(
  "Inundacion"                              = "Inundación",
  "Sequia"                                  = "Sequía",
  "Erosion"                                 = "Erosión",
  "Erosion costera"                         = "Erosión costera",
  "Explosion"                               = "Explosión",
  "Inmersion"                               = "Inmersión",
  "Creciente subita"                        = "Creciente súbita",
  "Tormenta electrica"                      = "Tormenta eléctrica",
  "Accidente transporte aereo"              = "Accidente transporte aéreo",
  "Accidente aereo"                         = "Accidente aéreo",
  "Accidente transporte maritimo o fluvial" = "Accidente transporte marítimo o fluvial"
)

#' "MOVIMIENTO EN MASA" -> "Movimiento en masa"; "INUNDACION" -> "Inundación".
.tipo_legible <- function(x) {
  y <- stringr::str_to_sentence(tolower(x))
  ifelse(y %in% names(.TILDES_EVENTO), .TILDES_EVENTO[y], y)
}

# --- Figuras ------------------------------------------------------------------

.fig_areas_protegidas <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla$detalle) |>
    dplyr::group_by(.data$municipio) |>
    dplyr::summarise(area_km2 = sum(.data$area_km2, na.rm = TRUE), .groups = "drop")
  if (!nrow(d)) {
    message("  [fig] 01 áreas protegidas: la provincia no registra áreas protegidas")
    return(invisible(NULL))
  }
  total <- sum(d$area_km2, na.rm = TRUE)
  d$participacion <- d$area_km2 / total
  mayor <- d[which.max(d$area_km2), ]

  p <- fig_barras(
    d, categoria = municipio, valor = area_km2,
    resaltar = mayor$municipio,
    etiqueta = function(x) num_co(x, 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s concentra el %s del área protegida de la provincia",
        mayor$municipio, pct_co(mayor$participacion * 100, dec = 0)
      ),
      subtitulo = sprintf(
        "Área protegida sobre cada municipio, en km². Total provincial: %s km² (%s ha). Provincia %s",
        num_co(total, 1), num_co(total * 100, 0), prov$etiqueta
      ),
      fuente = .FUENTE$areas
    )

  guardar_fig(p, "fig_01_areas_protegidas", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_01")
}

.fig_irca <- function(prov, tabla, destino, archivo) {
  anio <- max(tabla$irca$anio, na.rm = TRUE)
  d <- tabla$irca |>
    dplyr::filter(.data$anio == !!anio) |>
    .solo_municipios() |>
    dplyr::select(municipio, irca, irca_urbano, irca_rural) |>
    dplyr::filter(!is.na(.data$irca))
  if (!nrow(d)) {
    message("  [fig] 02 IRCA: sin datos para ", anio)
    return(invisible(NULL))
  }
  promedio <- mean(d$irca, na.rm = TRUE)
  mayor <- d[which.max(d$irca), ]

  p <- fig_barras(
    d, categoria = municipio, valor = irca,
    resaltar = mayor$municipio,
    etiqueta = function(x) num_co(x, 1),
    referencia = promedio,
    etiqueta_referencia = paste0("Promedio provincial: ", num_co(promedio, 1))
  ) +
    textos_fig(
      titulo = sprintf(
        "%s tiene el agua con mayor riesgo sanitario de la provincia (IRCA %s)",
        mayor$municipio, num_co(mayor$irca, 1)
      ),
      subtitulo = sprintf(
        "Índice de Riesgo de la Calidad del Agua (IRCA), %d. 0 = sin riesgo; 5-14 = riesgo bajo; 14-35 = riesgo medio. Provincia %s",
        anio, prov$etiqueta
      ),
      fuente = .FUENTE$irca
    )

  guardar_fig(p, "fig_02_irca", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_02")
}

.fig_irca_evolucion <- function(prov, tabla, destino, archivo) {
  provincial <- tabla$irca |>
    dplyr::filter(.data$tipo_fila != "Municipio") |>
    dplyr::transmute(anio = .data$anio, valor = .data$irca, serie = "Provincia")
  departamental <- tabla$irca_departamento |>
    dplyr::transmute(anio = .data$anio, valor = .data$irca, serie = "Antioquia")

  d <- dplyr::bind_rows(provincial, departamental) |>
    dplyr::filter(!is.na(.data$valor))
  if (dplyr::n_distinct(d$anio) < 3) {
    message("  [fig] 03 evolución del IRCA: la serie es demasiado corta")
    return(invisible(NULL))
  }

  primero <- min(d$anio); ultimo <- max(d$anio)
  ini <- provincial$valor[provincial$anio == primero][1]
  fin <- provincial$valor[provincial$anio == ultimo][1]
  verbo <- if (fin < ini) "bajó" else "subió"

  p <- .fig_serie(d, etiqueta = function(x) num_co(x, 1), dec_eje = 0, paso_x = 3) +
    textos_fig(
      titulo = sprintf(
        "El riesgo de la calidad del agua en la provincia %s de %s a %s entre %d y %d",
        verbo, num_co(ini, 1), num_co(fin, 1), primero, ultimo
      ),
      subtitulo = sprintf(
        "IRCA promedio simple entre municipios, %d-%d. Provincia %s frente al conjunto de Antioquia",
        primero, ultimo, prov$etiqueta
      ),
      fuente = .FUENTE$irca
    )

  guardar_fig(p, "fig_03_irca_evolucion", destino, alto = 8)
  escribir_datos_figura(tidyr::pivot_wider(d, names_from = "serie",
                                           values_from = "valor"),
                        archivo, "fig_03")
}

.fig_perdida_cobertura <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla$perdida_cobertura) |>
    dplyr::select(municipio, perdida_ca) |>
    dplyr::filter(!is.na(.data$perdida_ca))
  if (!nrow(d)) {
    message("  [fig] 04 pérdida de cobertura: sin datos para la provincia")
    return(invisible(NULL))
  }
  promedio <- mean(d$perdida_ca, na.rm = TRUE)
  mayor <- d[which.max(d$perdida_ca), ]

  p <- fig_barras(
    d, categoria = municipio, valor = perdida_ca,
    resaltar = mayor$municipio,
    etiqueta = function(x) pct_co(x * 100, dec = 1),
    referencia = promedio,
    etiqueta_referencia = paste0("Promedio provincial: ", pct_co(promedio * 100, dec = 1))
  ) +
    textos_fig(
      titulo = sprintf(
        "%s perdió el %s de su cobertura arbórea en dos décadas",
        mayor$municipio, pct_co(mayor$perdida_ca * 100, dec = 0)
      ),
      subtitulo = sprintf(
        paste("Pérdida acumulada 2001-2023, como porcentaje de la cobertura",
              "arbórea que el municipio tenía en 2000. Provincia %s"),
        prov$etiqueta
      ),
      fuente = .FUENTE$cobertura,
      # «Cobertura arbórea» no es «bosque»: es dosel, e incluye plantaciones y
      # cultivos arbóreos. Sin decirlo, la cifra se lee como deforestación.
      nota = paste("Cobertura arbórea: superficie con más del 30 % de dosel en",
                   "el año 2000, según Global Forest Watch. Incluye",
                   "plantaciones y cultivos arbóreos.")
    )

  guardar_fig(p, "fig_04_perdida_cobertura", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_04")
}

.fig_desastres_tipo <- function(prov, tabla, destino, archivo) {
  d <- tabla$eventos_tipo |>
    dplyr::filter(.data$tipo_fila == "Total provincia") |>
    dplyr::transmute(tipo = .tipo_legible(.data$emergencia),
                     n_eventos = .data$n_eventos) |>
    dplyr::arrange(dplyr::desc(.data$n_eventos))
  if (!nrow(d)) {
    message("  [fig] 05 desastres por tipo: la provincia no registra eventos")
    return(invisible(NULL))
  }

  total <- sum(d$n_eventos, na.rm = TRUE)
  # Con más de 12 categorías la figura deja de leerse: se muestran las mayores
  n_max <- min(nrow(d), 12L)
  recorte <- d[seq_len(n_max), ]
  mayor <- recorte[1, ]

  p <- fig_barras(
    recorte, categoria = tipo, valor = n_eventos,
    resaltar = mayor$tipo,
    etiqueta = function(x) num_co(x, 0)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s es la emergencia más frecuente: %s de los %s eventos de la provincia",
        mayor$tipo, num_co(mayor$n_eventos, 0), num_co(total, 0)
      ),
      subtitulo = sprintf(
        "Número de emergencias registradas %s. Provincia %s",
        .rango_anios(tabla$eventos_anio), prov$etiqueta
      ),
      fuente = .FUENTE$desastres,
      nota = if (nrow(d) > n_max) {
        sprintf("Se muestran los %d tipos más frecuentes de %d registrados.",
                n_max, nrow(d))
      } else {
        NULL
      }
    )

  guardar_fig(p, "fig_05_desastres_tipo", destino, n_barras = nrow(recorte))
  escribir_datos_figura(d, archivo, "fig_05")
}

.fig_eventos_anio <- function(prov, tabla, destino, archivo) {
  d <- tabla$eventos_anio |>
    dplyr::filter(.data$tipo_fila == "Total provincia") |>
    dplyr::transmute(anio = .data$anio, valor = .data$n_eventos,
                     serie = "Provincia") |>
    dplyr::arrange(.data$anio)
  if (nrow(d) < 3) {
    message("  [fig] 06 emergencias por año: la serie es demasiado corta")
    return(invisible(NULL))
  }

  pico <- d[which.max(d$valor), ]
  ultimo <- d[nrow(d), ]

  p <- .fig_serie(d, etiqueta = function(x) num_co(x, 0), dec_eje = 0, paso_x = 1) +
    textos_fig(
      titulo = sprintf(
        "Las emergencias de la provincia tocaron techo en %d con %s eventos",
        pico$anio, num_co(pico$valor, 0)
      ),
      subtitulo = sprintf(
        "Número de emergencias registradas por año, %s. En %d se registraron %s. Provincia %s",
        .rango_anios(tabla$eventos_anio), ultimo$anio, num_co(ultimo$valor, 0),
        prov$etiqueta
      ),
      fuente = .FUENTE$desastres
    )

  guardar_fig(p, "fig_06_eventos_anio", destino, alto = 8)
  escribir_datos_figura(dplyr::select(d, anio, valor), archivo, "fig_06")
}

.fig_imrc <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla$imrc) |>
    dplyr::transmute(categoria = .data$municipio,
                     inicio = .data$imrc_d, fin = .data$imrc_e) |>
    dplyr::filter(!is.na(.data$fin), !is.na(.data$inicio))
  if (!nrow(d)) {
    message("  [fig] 07 IMRC: sin datos para la provincia")
    return(invisible(NULL))
  }
  dep <- dplyr::filter(tabla$imrc, .data$tipo_fila == "Total departamento")
  mayor <- d[which.max(d$fin), ]

  p <- .fig_dumbbell(d, "Déficit de lluvias", "Exceso de lluvias",
                     etiqueta = function(x) num_co(x, 1)) +
    textos_fig(
      titulo = sprintf(
        "%s es el municipio con mayor riesgo por exceso de lluvias (%s)",
        mayor$categoria, num_co(mayor$fin, 1)
      ),
      subtitulo = sprintf(
        "Índice Municipal de Riesgo de Desastres ajustado por capacidades, 2024 (0-100). Promedio departamental: %s por exceso y %s por déficit. Provincia %s",
        num_co(dep$imrc_e[1], 1), num_co(dep$imrc_d[1], 1), prov$etiqueta
      ),
      fuente = .FUENTE$imrc
    )

  guardar_fig(p, "fig_07_imrc", destino, n_barras = nrow(d))
  escribir_datos_figura(
    dplyr::rename(d, municipio = "categoria",
                  imrc_deficit = "inicio", imrc_exceso = "fin"),
    archivo, "fig_07"
  )
}

#' "entre 2019 y 2024", a partir de la hoja de eventos por año.
.rango_anios <- function(eventos_anio) {
  a <- range(eventos_anio$anio, na.rm = TRUE)
  if (a[1] == a[2]) paste("en", a[1]) else sprintf("entre %d y %d", a[1], a[2])
}

# --- Punto de entrada ---------------------------------------------------------

figuras_ambiental <- function(prov, tabla) {
  message("== figuras 07 Ambiental — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "07_Ambiental")
  archivo <- tabla$archivo %||%
    file.path(dir_seccion(prov, "07_Ambiental"), "ambiental.xlsx")

  .fig_areas_protegidas(prov, tabla, destino, archivo)
  .fig_irca(prov, tabla, destino, archivo)
  .fig_irca_evolucion(prov, tabla, destino, archivo)
  .fig_perdida_cobertura(prov, tabla, destino, archivo)
  .fig_desastres_tipo(prov, tabla, destino, archivo)
  .fig_eventos_anio(prov, tabla, destino, archivo)
  .fig_imrc(prov, tabla, destino, archivo)

  invisible(destino)
}
