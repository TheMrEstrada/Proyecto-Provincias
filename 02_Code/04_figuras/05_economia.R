# =============================================================================
# 05_economia.R — Figuras de la Sección 5: Economía
#
# FIGURAS (las del catálogo marcadas como "Gráfico" en la sección 5):
#   fig_01_pobreza_nbi                  — personas en pobreza por NBI
#   fig_02_pobreza_ipm                  — personas en pobreza multidimensional
#   fig_03_gini_hogar_laboral           — Gini del hogar frente al Gini laboral
#   fig_04_ocupacion_informalidad       — ocupación frente a informalidad
#   fig_05_desocupacion_total_jovenes   — desocupación total frente a jóvenes
#   fig_06_jovenes_nini                 — jóvenes que no estudian ni trabajan
#   fig_07_dependencia_economica        — índice de dependencia económica
#   fig_08_densidad_empresarial         — empresas por cada 1.000 habitantes
#   fig_09_valor_agregado_per_capita    — valor agregado por habitante
#   fig_10_peso_relativo_valor_agregado — peso de cada municipio en el VA
#   fig_11_composicion_valor_agregado   — composición sectorial del VA
#   fig_12_valor_agregado_actividades   — VA provincial por rama de actividad
#   fig_13_titulos_mineros              — títulos mineros por tipo de mineral
#   fig_14_visitantes_extranjeros       — evolución de visitantes por municipio
#   fig_15_participacion_visitantes     — peso de la provincia en Antioquia
#
# El catálogo pedía la composición sectorial en barra apilada al 100 %, no en
# torta, así que no hubo ninguna torta que sustituir (DISENO.md §5).
#
# INPUTS:  la tabla que produce 02_Code/03_tablas/05_economia.R
# OUTPUTS: 03_Outputs/<Provincia>/05_Economia/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

FUENTE_ECV      <- "Gobernación de Antioquia, Encuesta de Calidad de Vida 2023."
FUENTE_DANE_POB <- "DANE, proyecciones de población municipal 2025."
FUENTE_VA       <- "Gobernación de Antioquia, valor agregado municipal 2015-2024 (2026)."
FUENTE_DEYC     <- "Gobernación de Antioquia, DATALAKE Desarrollo Económico y Competitividad."
FUENTE_ANM      <- "Agencia Nacional de Minería, catastro minero (títulos vigentes)."
FUENTE_TURISMO  <- "Gobernación de Antioquia, registro de visitantes extranjeros no residentes."

# =============================================================================
# 0. Geoms que esta sección necesita y que no están en 02_Code/R/02_tema.R
# =============================================================================

#' Dumbbell: dos indicadores del mismo municipio unidos por un segmento
#' (DISENO.md §5). Se ordena por la primera serie, se etiquetan los dos
#' extremos y la identidad de cada serie la carga el color del punto.
.fig_dumbbell <- function(datos, categoria, valor_a, valor_b,
                          serie_a, serie_b, etiqueta = num_co) {
  d <- data.frame(
    cat = as.character(datos[[categoria]]),
    a   = as.numeric(datos[[valor_a]]),
    b   = as.numeric(datos[[valor_b]]),
    stringsAsFactors = FALSE
  )
  d <- d[!is.na(d$a) & !is.na(d$b), , drop = FALSE]
  d$cat <- factor(d$cat, levels = d$cat[order(d$a)])
  d$menor <- pmin(d$a, d$b)
  d$mayor <- pmax(d$a, d$b)

  largo <- rbind(
    data.frame(cat = d$cat, valor = d$a, serie = serie_a, stringsAsFactors = FALSE),
    data.frame(cat = d$cat, valor = d$b, serie = serie_b, stringsAsFactors = FALSE)
  )
  largo$serie <- factor(largo$serie, levels = c(serie_a, serie_b))
  colores <- stats::setNames(unname(PALETA_SERIES[1:2]), c(serie_a, serie_b))

  ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = d,
      ggplot2::aes(x = .data$menor, xend = .data$mayor, y = .data$cat, yend = .data$cat),
      color = COLOR$contexto, linewidth = 0.28
    ) +
    ggplot2::geom_point(
      data = largo,
      ggplot2::aes(x = .data$valor, y = .data$cat, color = .data$serie), size = 2.2
    ) +
    ggplot2::geom_text(
      data = d, ggplot2::aes(x = .data$menor, y = .data$cat, label = etiqueta(.data$menor)),
      hjust = 1.3, size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::geom_text(
      data = d, ggplot2::aes(x = .data$mayor, y = .data$cat, label = etiqueta(.data$mayor)),
      hjust = -0.3, size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    ggplot2::scale_color_manual(values = colores) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.16, 0.16))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)
}

# Segmentos claros llevan tinta primaria; los oscuros, blanco (la regla de
# DISENO.md §2.5 aplica al texto junto a la marca, no dentro de ella).
.tinta_sobre <- function(colores) {
  ifelse(colores %in% c(unname(PALETA_SERIES["naranja"]), COLOR$contexto),
         COLOR$tinta_1, "#FFFFFF")
}

#' Barras horizontales apiladas al 100 % (DISENO.md §5): máximo cuatro
#' segmentos, el último "Otros" en gris de contexto, etiquetas solo donde el
#' segmento supera el 8 % del total.
.fig_apiladas_100 <- function(largo, categoria, segmento, valor, orden_segmentos,
                              orden_categorias) {
  d <- data.frame(
    cat = factor(as.character(largo[[categoria]]), levels = rev(orden_categorias)),
    seg = factor(as.character(largo[[segmento]]), levels = orden_segmentos),
    val = as.numeric(largo[[valor]]),
    stringsAsFactors = FALSE
  )
  n_series <- length(orden_segmentos)
  colores <- c(unname(PALETA_SERIES[seq_len(n_series - 1)]), COLOR$contexto)
  names(colores) <- orden_segmentos

  # `position_fill` reparte sobre el total de cada barra; las participaciones ya
  # suman 1 porque el remanente entra como un segmento más.
  ggplot2::ggplot(d, ggplot2::aes(x = .data$val, y = .data$cat, fill = .data$seg)) +
    ggplot2::geom_col(position = ggplot2::position_fill(reverse = TRUE),
                      width = 0.68) +
    ggplot2::geom_text(
      ggplot2::aes(label = ifelse(.data$val >= 0.08, pct_co(.data$val * 100, 0), ""),
                   color = .data$seg),
      position = ggplot2::position_fill(vjust = 0.5, reverse = TRUE),
      size = PT$valor / .pt, family = FUENTE, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = colores) +
    ggplot2::scale_color_manual(values = stats::setNames(.tinta_sobre(colores),
                                                         orden_segmentos)) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 1)) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)
}

#' Series de tiempo con marcador en el primer y el último punto (DISENO.md §5).
#' `serie_contexto` es la serie residual ("Otros…"), que va en gris y no
#' consume un color de la paleta.
.fig_lineas <- function(largo, x, y, serie, etiqueta = num_co,
                        serie_contexto = NULL) {
  d <- data.frame(
    x = as.numeric(largo[[x]]),
    y = as.numeric(largo[[y]]),
    serie = as.character(largo[[serie]]),
    stringsAsFactors = FALSE
  )
  d <- d[!is.na(d$y), , drop = FALSE]
  series <- unique(d$serie)
  d$serie <- factor(d$serie, levels = series)
  extremos <- do.call(rbind, lapply(split(d, d$serie), function(s) {
    s[c(which.min(s$x), which.max(s$x)), , drop = FALSE]
  }))

  destacadas <- setdiff(series, serie_contexto)
  colores <- stats::setNames(unname(PALETA_SERIES[seq_along(destacadas)]), destacadas)
  if (!is.null(serie_contexto)) colores[serie_contexto] <- COLOR$contexto

  ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$y, color = .data$serie)) +
    ggplot2::geom_line(linewidth = 0.28) +
    ggplot2::geom_point(data = extremos, size = 1.4) +
    ggplot2::scale_color_manual(values = colores) +
    ggplot2::scale_x_continuous(breaks = sort(unique(d$x))) +
    ggplot2::scale_y_continuous(limits = c(0, NA), labels = etiqueta,
                                expand = ggplot2::expansion(mult = c(0, 0.08))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "y")
}

# =============================================================================
# 1. Helpers de datos comunes a varias figuras
# =============================================================================

#' Valor de una fila agregada (NA si esa fila no existe en la hoja).
.agregado <- function(datos, tipo, columna) {
  v <- datos[[columna]][datos$tipo_fila == tipo]
  if (length(v)) as.numeric(v[1]) else NA_real_
}

#' Proporción a texto de porcentaje colombiano.
.pp <- function(x, dec = 1) pct_co(x * 100, dec = dec)

#' Años con información completa: descarta el último si su total departamental
#' es menos de la mitad del año anterior (recorte de un año en curso).
.anios_completos <- function(anios, totales) {
  o <- order(anios)
  anios <- anios[o]; totales <- totales[o]
  n <- length(anios)
  if (n >= 2 && !is.na(totales[n]) && !is.na(totales[n - 1]) &&
      totales[n] < 0.5 * totales[n - 1]) {
    anios <- anios[-n]
  }
  anios
}

#' Barras horizontales de un indicador municipal con la línea de referencia del
#' agregado provincial. Devuelve invisible la ruta del PNG.
#'
#' En las hojas de la ECV el valor municipal y el agregado viven en columnas
#' distintas (`_mun` y `_ofi`), por eso `columna_agregado` es un parámetro y no
#' se asume que la referencia esté en la misma columna que el detalle.
.barras_municipal <- function(hoja, columna, prov, destino, archivo, id, slug,
                              extremo, titulo_fmt, subtitulo, etiqueta,
                              fuente, nota = NULL, tipo_prov = "Provincia",
                              columna_agregado = columna) {
  d <- hoja[hoja$tipo_fila == "Municipio" & !is.na(hoja[[columna]]), , drop = FALSE]
  i <- if (extremo == "max") which.max(d[[columna]]) else which.min(d[[columna]])
  foco <- d$municipio[i]
  v_prov <- .agregado(hoja, tipo_prov, columna_agregado)

  p <- fig_barras(
    dplyr::mutate(d, valor = .data[[columna]]),
    categoria = municipio, valor = valor, resaltar = foco, etiqueta = etiqueta,
    referencia = if (is.na(v_prov)) NULL else v_prov,
    etiqueta_referencia = if (is.na(v_prov)) NULL else paste0("Provincia: ", etiqueta(v_prov))
  ) +
    textos_fig(titulo = sprintf(titulo_fmt, foco, etiqueta(d[[columna]][i])),
               subtitulo = subtitulo, fuente = fuente, nota = nota)

  guardar_fig(p, paste0(id, "_", slug), destino, n_barras = nrow(d))
  escribir_datos_figura(d[, c("municipio", columna)], archivo, id)
}

# =============================================================================
# 2. Figuras
# =============================================================================

figuras_economia <- function(prov, tabla) {
  message("== figuras 05 Economía — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "05_Economia")
  archivo <- attr(tabla, "archivo") %||%
    file.path(dir_seccion(prov, "05_Economia"), "economia.xlsx")

  # --- 2.1 Pobreza monetaria y multidimensional -----------------------------
  nbi <- tabla$ecv_pobreza
  .barras_municipal(
    nbi, "tot_pob_nbi_mun", prov, destino, archivo,
    id = "fig_01", slug = "pobreza_nbi", extremo = "max",
    titulo_fmt = "%s tiene la mayor pobreza por NBI de la provincia: %s de la población",
    subtitulo = sprintf(
      "Personas con al menos una necesidad básica insatisfecha, 2023. Provincia %s. Subregión %s; Antioquia %s.",
      prov$etiqueta,
      .pp(.agregado(nbi, "Subregión", "tot_pob_nbi_ofi")),
      .pp(.agregado(nbi, "Departamento", "tot_pob_nbi_ofi"))),
    etiqueta = function(x) .pp(x), fuente = FUENTE_ECV,
    nota = "Cálculos propios. El valor provincial es un promedio ponderado por población.",
    columna_agregado = "tot_pob_nbi_ofi"
  )

  ipm <- tabla$ecv_ipm
  .barras_municipal(
    ipm, "tot_pob_ipm_mun", prov, destino, archivo,
    id = "fig_02", slug = "pobreza_ipm", extremo = "max",
    titulo_fmt = "%s encabeza la pobreza multidimensional de la provincia: %s de la población",
    subtitulo = sprintf(
      "Personas en pobreza según el IPM, 2023. Provincia %s. Subregión %s; Antioquia %s.",
      prov$etiqueta,
      .pp(.agregado(ipm, "Subregión", "tot_pob_ipm_ofi")),
      .pp(.agregado(ipm, "Departamento", "tot_pob_ipm_ofi"))),
    etiqueta = function(x) .pp(x), fuente = FUENTE_ECV,
    nota = "Cálculos propios. El valor provincial es un promedio ponderado por población.",
    columna_agregado = "tot_pob_ipm_ofi"
  )

  # --- 2.2 Desigualdad: Gini del hogar frente al Gini laboral ---------------
  gini <- dplyr::filter(tabla$ecv_gini, .data$tipo_fila == "Municipio")
  i <- which.max(gini$tot_gini_hog_mun)
  p <- .fig_dumbbell(
    gini, "municipio", "tot_gini_hog_mun", "tot_gini_lab_mun",
    serie_a = "Ingresos del hogar", serie_b = "Ingresos laborales",
    etiqueta = function(x) num_co(x, 2)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s es el municipio más desigual de la provincia: Gini de %s en el ingreso de los hogares",
        gini$municipio[i], num_co(gini$tot_gini_hog_mun[i], 2)),
      subtitulo = sprintf(
        "Coeficiente de Gini por municipio, 2023. Municipios de la provincia %s. Un valor mayor indica más desigualdad.",
        prov$etiqueta),
      fuente = FUENTE_ECV,
      nota = "Cálculos propios. El Gini no es promediable entre municipios, por eso no se muestra un agregado provincial."
    )
  guardar_fig(p, "fig_03_gini_hogar_laboral", destino, n_barras = nrow(gini))
  escribir_datos_figura(
    gini[, c("municipio", "tot_gini_hog_mun", "tot_gini_lab_mun")], archivo, "fig_03")

  # --- 2.3 Mercado laboral: ocupación frente a informalidad -----------------
  oi <- tabla$ecv_ocupacion_informal
  oi_mun <- dplyr::filter(oi, .data$tipo_fila == "Municipio")
  i <- which.max(oi_mun$tot_emp_informal_mun)
  p <- .fig_dumbbell(
    oi_mun, "municipio", "tot_emp_informal_mun", "tot_to_mun",
    serie_a = "Informalidad laboral", serie_b = "Tasa de ocupación",
    etiqueta = function(x) .pp(x, 0)
  ) +
    textos_fig(
      titulo = sprintf("En %s el %s del empleo es informal, el nivel más alto de la provincia",
                       oi_mun$municipio[i], .pp(oi_mun$tot_emp_informal_mun[i], 0)),
      subtitulo = sprintf(
        paste("Tasa de ocupación e informalidad laboral, 2023. Municipios de la",
              "provincia %s. Provincia: ocupación %s e informalidad %s."),
        prov$etiqueta,
        .pp(.agregado(oi, "Provincia", "tot_to_ofi")),
        .pp(.agregado(oi, "Provincia", "tot_emp_informal_ofi"))),
      fuente = FUENTE_ECV,
      nota = "Cálculos propios. Los valores provinciales son promedios ponderados por población."
    )
  guardar_fig(p, "fig_04_ocupacion_informalidad", destino, n_barras = nrow(oi_mun))
  escribir_datos_figura(
    oi_mun[, c("municipio", "tot_to_mun", "tot_emp_informal_mun")], archivo, "fig_04")

  # --- 2.4 Desocupación total frente a la de jóvenes ------------------------
  dn <- tabla$ecv_desocupacion_nini
  dn_mun <- dplyr::filter(dn, .data$tipo_fila == "Municipio")
  i <- which.max(dn_mun$tot_td_15_28_mun)
  p <- .fig_dumbbell(
    dn_mun, "municipio", "tot_td_mun", "tot_td_15_28_mun",
    serie_a = "Población total", serie_b = "Jóvenes de 15 a 28 años",
    etiqueta = function(x) .pp(x, 1)
  ) +
    textos_fig(
      titulo = sprintf("El desempleo juvenil de %s (%s) es el más alto de la provincia",
                       dn_mun$municipio[i], .pp(dn_mun$tot_td_15_28_mun[i], 1)),
      subtitulo = sprintf(
        "Tasa de desocupación total y de jóvenes de 15 a 28 años, 2023. Municipios de la provincia %s.",
        prov$etiqueta),
      fuente = FUENTE_ECV, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_05_desocupacion_total_jovenes", destino, n_barras = nrow(dn_mun))
  escribir_datos_figura(
    dn_mun[, c("municipio", "tot_td_mun", "tot_td_15_28_mun")], archivo, "fig_05")

  # --- 2.5 Jóvenes que no estudian ni trabajan ------------------------------
  .barras_municipal(
    dn, "tot_nini_mun", prov, destino, archivo,
    id = "fig_06", slug = "jovenes_nini", extremo = "max",
    titulo_fmt = "%s tiene la mayor proporción de jóvenes que no estudian ni trabajan: %s",
    subtitulo = sprintf(
      "Jóvenes de 15 a 28 años que no estudian ni están ocupados, 2023. Provincia %s. Subregión %s; Antioquia %s.",
      prov$etiqueta,
      .pp(.agregado(dn, "Subregión", "tot_nini_ofi")),
      .pp(.agregado(dn, "Departamento", "tot_nini_ofi"))),
    etiqueta = function(x) .pp(x), fuente = FUENTE_ECV, nota = "Cálculos propios.",
    columna_agregado = "tot_nini_ofi"
  )

  # --- 2.6 Índice de dependencia económica ----------------------------------
  ide <- tabla$dependencia_economica
  .barras_municipal(
    ide, "ide", prov, destino, archivo,
    id = "fig_07", slug = "dependencia_economica", extremo = "max",
    titulo_fmt = paste("%s tiene la mayor carga demográfica de la provincia:",
                       "%s dependientes por cada 100 personas en edad de trabajar"),
    subtitulo = sprintf(
      paste("Población menor de 15 años y de 65 y más por cada 100 personas de",
            "15 a 64 años, 2025. Provincia %s. Subregión %s; Antioquia %s."),
      prov$etiqueta,
      num_co(.agregado(ide, "Total subregión", "ide"), 1),
      num_co(.agregado(ide, "Total departamento", "ide"), 1)),
    etiqueta = function(x) num_co(x, 1), fuente = FUENTE_DANE_POB,
    nota = "Cálculos propios. Los agregados se recomputan desde las sumas por grupo de edad.",
    tipo_prov = "Total provincia"
  )

  # --- 2.7 Densidad empresarial ---------------------------------------------
  dens <- tabla$densidad_empresarial
  .barras_municipal(
    dens, "dens_emp", prov, destino, archivo,
    id = "fig_08", slug = "densidad_empresarial", extremo = "max",
    titulo_fmt = "%s concentra el tejido empresarial de la provincia: %s empresas por cada 1.000 habitantes",
    subtitulo = sprintf("Empresas registradas por cada 1.000 habitantes, 2023. Municipios de la provincia %s.",
                        prov$etiqueta),
    etiqueta = function(x) num_co(x, 1), fuente = FUENTE_DEYC,
    nota = "Cálculos propios. El valor provincial es un promedio ponderado por población.",
    tipo_prov = "Total provincia"
  )

  # --- 2.8 Valor agregado: nivel, peso y composición ------------------------
  # Todas las cifras monetarias están en pesos CONSTANTES DE 2015, la unidad del
  # insumo; se declara en cada subtítulo.
  anio_va <- max(tabla$valor_agregado$anio, na.rm = TRUE)
  va <- dplyr::filter(tabla$valor_agregado, .data$anio == anio_va)
  va_mun <- dplyr::filter(va, .data$tipo_fila == "Municipio")
  va_prov <- dplyr::filter(va, .data$tipo_fila == "Total provincia")

  # Per cápita en millones de pesos: en pesos la etiqueta de cada barra tendría
  # ocho dígitos y no cabe (DISENO.md §7 prohíbe abreviar en las etiquetas).
  va_pc <- dplyr::mutate(va_mun, va_pc_mm = .data$va_pc / 1e6)
  i <- which.max(va_pc$va_pc_mm)
  p <- fig_barras(
    va_pc, categoria = municipio, valor = va_pc_mm,
    resaltar = va_pc$municipio[i], etiqueta = function(x) num_co(x, 1),
    referencia = va_prov$va_pc / 1e6,
    etiqueta_referencia = paste0("Provincia: ", num_co(va_prov$va_pc / 1e6, 1))
  ) +
    textos_fig(
      titulo = sprintf("%s genera %s millones de pesos de valor agregado por habitante, el máximo de la provincia",
                       va_pc$municipio[i], num_co(va_pc$va_pc_mm[i], 1)),
      subtitulo = sprintf("Valor agregado por habitante, %d, en millones de pesos constantes de 2015. Provincia %s.",
                          anio_va, prov$etiqueta),
      fuente = FUENTE_VA, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_09_valor_agregado_per_capita", destino, n_barras = nrow(va_pc))
  escribir_datos_figura(va_pc[, c("municipio", "anio", "va_total", "poblacion", "va_pc")],
                        archivo, "fig_09")

  i <- which.max(va_mun$prop_va_prov)
  p <- fig_barras(
    va_mun, categoria = municipio, valor = prop_va_prov,
    resaltar = va_mun$municipio[i], etiqueta = function(x) .pp(x, 1)
  ) +
    textos_fig(
      titulo = sprintf("%s aporta el %s del valor agregado de la provincia",
                       va_mun$municipio[i], .pp(va_mun$prop_va_prov[i], 0)),
      subtitulo = sprintf(
        "Participación de cada municipio en los %s miles de millones de pesos constantes de 2015 de la provincia %s, %d.",
        num_co(va_prov$va_total, 0), prov$etiqueta, anio_va),
      fuente = FUENTE_VA, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_10_peso_relativo_valor_agregado", destino, n_barras = nrow(va_mun))
  escribir_datos_figura(va_mun[, c("municipio", "anio", "va_total", "prop_va_prov")],
                        archivo, "fig_10")

  # Composición sectorial: los tres agregados no cubren todo el VA total de la
  # serie a precios constantes, así que el remanente entra como cuarto segmento
  # en gris de contexto en lugar de repartirse en silencio.
  comp <- va_mun |>
    dplyr::transmute(
      municipio = .data$municipio,
      Primarias   = .data$prop_va_primario,
      Secundarias = .data$prop_va_secundario,
      Terciarias  = .data$prop_va_terciario,
      `No distribuido` = pmax(0, 1 - .data$prop_va_primario -
                                .data$prop_va_secundario - .data$prop_va_terciario)
    )
  segmentos <- c("Primarias", "Secundarias", "Terciarias", "No distribuido")
  if (max(comp$`No distribuido`, na.rm = TRUE) < 0.005) {
    comp$`No distribuido` <- NULL
    segmentos <- segmentos[1:3]
  }
  orden_cat <- comp$municipio[order(comp$Primarias, decreasing = TRUE)]
  i <- which.max(comp$Primarias)
  largo <- tidyr::pivot_longer(comp, cols = dplyr::all_of(segmentos),
                               names_to = "segmento", values_to = "participacion")
  p <- .fig_apiladas_100(largo, "municipio", "segmento", "participacion",
                         segmentos, orden_cat) +
    textos_fig(
      titulo = sprintf("%s es el municipio más dependiente de las actividades primarias: %s de su valor agregado",
                       comp$municipio[i], .pp(comp$Primarias[i], 0)),
      subtitulo = sprintf(
        paste("Composición del valor agregado municipal por grandes sectores, %d.",
              "Provincia %s. Porcentajes sobre el valor agregado total."),
        anio_va, prov$etiqueta),
      fuente = FUENTE_VA,
      nota = paste("Cálculos propios. 'No distribuido' es la parte del valor",
                   "agregado total que la serie a precios constantes no asigna",
                   "a ninguno de los tres sectores.")
    )
  guardar_fig(p, "fig_11_composicion_valor_agregado", destino, n_barras = nrow(comp))
  escribir_datos_figura(as.data.frame(comp), archivo, "fig_11")

  # Ramas de actividad, al nivel de la provincia (no del municipio).
  ramas <- data.frame(
    actividad = unname(stringr::str_remove(RAMAS_VA, "^VA ")),
    valor = as.numeric(unlist(va_prov[1, names(RAMAS_VA)])),
    stringsAsFactors = FALSE
  )
  ramas <- ramas[!is.na(ramas$valor) & ramas$valor > 0, , drop = FALSE]
  i <- which.max(ramas$valor)
  p <- fig_barras(
    ramas, categoria = actividad, valor = valor,
    resaltar = ramas$actividad[i], etiqueta = function(x) num_co(x, 0)
  ) +
    textos_fig(
      titulo = sprintf("%s es la rama que más valor agregado aporta a la provincia",
                       ramas$actividad[i]),
      subtitulo = sprintf(
        "Valor agregado provincial por rama de actividad, %d, en miles de millones de pesos constantes de 2015. Provincia %s.",
        anio_va, prov$etiqueta),
      fuente = FUENTE_VA, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_12_valor_agregado_actividades", destino, n_barras = nrow(ramas))
  escribir_datos_figura(ramas, archivo, "fig_12")

  # --- 2.9 Títulos mineros ---------------------------------------------------
  tm <- tabla$titulos_mineros
  if (sum(tm$n_titulos, na.rm = TRUE) > 0) {
    # Más de seis categorías no caben en una figura legible: se muestran las
    # diez primeras y el resto se agrupa (DISENO.md §2.1).
    tope <- utils::head(tm[order(-tm$n_titulos), ], 10)
    resto <- sum(tm$n_titulos) - sum(tope$n_titulos)
    minerales <- data.frame(
      mineral = stringr::str_to_sentence(tope$grupo_mineral),
      n_titulos = tope$n_titulos, stringsAsFactors = FALSE
    )
    if (resto > 0) {
      minerales <- rbind(minerales,
                         data.frame(mineral = "Otros minerales", n_titulos = resto))
    }
    p <- fig_barras(
      minerales, categoria = mineral, valor = n_titulos,
      resaltar = minerales$mineral[1], etiqueta = function(x) num_co(x, 0)
    ) +
      textos_fig(
        titulo = sprintf("%s es el mineral con más títulos vigentes en la provincia: %s títulos",
                         minerales$mineral[1], num_co(minerales$n_titulos[1], 0)),
        subtitulo = sprintf(
          paste("Títulos mineros activos por tipo de mineral en la provincia %s.",
                "Un título con varios minerales cuenta en cada uno, así que la",
                "suma supera el número de títulos."),
          prov$etiqueta),
        fuente = FUENTE_ANM, nota = "Cálculos propios."
      )
    guardar_fig(p, "fig_13_titulos_mineros", destino, n_barras = nrow(minerales))
    escribir_datos_figura(minerales, archivo, "fig_13")
  } else {
    message("  [fig] fig_13_titulos_mineros omitida: la provincia no tiene títulos mineros activos")
  }

  # --- 2.10 Visitantes extranjeros ------------------------------------------
  comparativo <- tabla$comparativo_pap_antioquia
  anios <- .anios_completos(comparativo$anio, comparativo$total_antioquia)
  anios <- anios[anios >= 2019]

  ext <- tabla$extranjeros_municipio |>
    dplyr::filter(.data$tipo_fila == "Municipio", .data$anio %in% anios)
  ranking <- ext |>
    dplyr::group_by(.data$municipio) |>
    dplyr::summarise(total = sum(.data$extranjeros, na.rm = TRUE), .groups = "drop") |>
    dplyr::arrange(dplyr::desc(.data$total))
  destacados <- utils::head(ranking$municipio, 4)

  serie <- ext |>
    dplyr::mutate(serie = ifelse(.data$municipio %in% destacados,
                                 .data$municipio, "Otros municipios")) |>
    dplyr::group_by(.data$serie, .data$anio) |>
    dplyr::summarise(visitantes = sum(.data$extranjeros, na.rm = TRUE), .groups = "drop")
  # El orden de las series fija el orden de los colores de la paleta.
  serie$serie <- factor(serie$serie, levels = c(destacados, "Otros municipios"))
  serie <- dplyr::arrange(serie, .data$serie, .data$anio)

  ultimo <- max(anios)
  lider <- ranking$municipio[1]
  p <- .fig_lineas(serie, "anio", "visitantes", "serie",
                   serie_contexto = "Otros municipios") +
    textos_fig(
      titulo = sprintf("%s lidera la llegada de visitantes extranjeros a la provincia",
                       lider),
      subtitulo = sprintf(
        paste("Visitantes extranjeros no residentes por municipio, %d-%d. Cuatro",
              "municipios con más llegadas acumuladas y el resto agrupado.",
              "Provincia %s."),
        min(anios), ultimo, prov$etiqueta),
      fuente = FUENTE_TURISMO, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_14_visitantes_extranjeros", destino, alto = 8)
  escribir_datos_figura(as.data.frame(serie), archivo, "fig_14")

  comp_fig <- dplyr::filter(comparativo, .data$anio %in% anios)
  comp_fig$serie <- "Participación de la provincia"
  p <- .fig_lineas(comp_fig, "anio", "participacion", "serie",
                   etiqueta = function(x) pct_co(x * 100, 2)) +
    textos_fig(
      titulo = sprintf("La provincia capta el %s de los visitantes extranjeros que llegan a Antioquia",
                       pct_co(comp_fig$participacion[comp_fig$anio == ultimo] * 100, 2)),
      subtitulo = sprintf(
        paste("Participación de la provincia %s en los visitantes extranjeros no",
              "residentes del departamento, %d-%d. En %d: %s visitantes en la",
              "provincia frente a %s en Antioquia."),
        prov$etiqueta, min(anios), ultimo, ultimo,
        num_co(comp_fig$total_provincia[comp_fig$anio == ultimo], 0),
        num_co(comp_fig$total_antioquia[comp_fig$anio == ultimo], 0)),
      fuente = FUENTE_TURISMO, nota = "Cálculos propios."
    )
  guardar_fig(p, "fig_15_participacion_visitantes", destino, alto = 8)
  escribir_datos_figura(
    comp_fig[, c("anio", "total_provincia", "total_antioquia", "participacion")],
    archivo, "fig_15")

  invisible(destino)
}
