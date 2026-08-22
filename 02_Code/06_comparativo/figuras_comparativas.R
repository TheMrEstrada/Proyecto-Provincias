# =============================================================================
# figuras_comparativas.R — Las once provincias vistas juntas
#
# Figuras que ningún informe provincial puede producir, porque necesitan las
# once a la vez: cuánto del departamento cubre el sistema provincial, cómo se
# ordenan las provincias en cada indicador y qué perfil dibuja cada una.
#
# Siguen el mismo sistema visual que el resto del proyecto (DISENO.md): paleta
# EAFIT, rampa secuencial para magnitud, resalte y contexto, formato numérico
# colombiano y nota de fuente obligatoria.
#
# INPUTS:  04_Docs/comparativo/panel_provincial.csv
# OUTPUTS: 03_Outputs/_Comparativo/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: comparativo
# =============================================================================

if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(dirname(normalizePath(.f[1])))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}
source(file.path(RUTAS$codigo, "06_comparativo", "panel_provincial.R"),
       encoding = "UTF-8")

DIR_FIG_COMP <- file.path(RUTAS$outputs, "_Comparativo", "figuras")

# --- Utilidades ---------------------------------------------------------------

#' Barras horizontales de las once provincias para un indicador del panel.
#'
#' Resalta la provincia que ocupa el primer lugar según el sentido del
#' indicador: donde más es peor, se resalta la peor situada, porque es la que
#' el lector debe mirar.
.barras_panel <- function(panel, columna, titulo, subtitulo, fuente_txt,
                          etiqueta = num_co, referencia = NULL,
                          etiqueta_ref = NULL, descendente = TRUE) {
  d <- panel[!is.na(panel[[columna]]), , drop = FALSE]
  d$valor <- d[[columna]]
  extremo <- d$provincia[which.max(if (descendente) d$valor else -d$valor)]

  fig_barras(d, categoria = provincia, valor = valor, resaltar = extremo,
             etiqueta = etiqueta, referencia = referencia,
             etiqueta_referencia = etiqueta_ref, descendente = descendente) +
    textos_fig(titulo = titulo, subtitulo = subtitulo, fuente = fuente_txt)
}

# --- 1. El sistema provincial dentro del departamento -------------------------

fig_cobertura_sistema <- function(panel) {
  cob <- cobertura_sistema(panel)
  d <- data.frame(
    dimension = c("Municipios", "Población", "Territorio"),
    dentro = c(cob$municipios_provincia, cob$poblacion_provincias,
               cob$area_provincias),
    total = c(cob$municipios_departamento, cob$poblacion_departamento,
              cob$area_departamento),
    stringsAsFactors = FALSE
  )
  d <- d[!is.na(d$total) & d$total > 0, , drop = FALSE]
  d$pct <- d$dentro / d$total

  largo <- rbind(
    data.frame(dimension = d$dimension, parte = "En alguna provincia",
               valor = d$pct, stringsAsFactors = FALSE),
    data.frame(dimension = d$dimension, parte = "Fuera del esquema",
               valor = 1 - d$pct, stringsAsFactors = FALSE))
  largo$dimension <- factor(largo$dimension,
                            levels = rev(c("Municipios", "Población", "Territorio")))
  largo$parte <- factor(largo$parte,
                        levels = c("En alguna provincia", "Fuera del esquema"))

  ggplot2::ggplot(largo, ggplot2::aes(x = valor, y = dimension, fill = parte)) +
    ggplot2::geom_col(width = 0.6, position = ggplot2::position_stack(reverse = TRUE)) +
    ggplot2::geom_text(
      data = largo[largo$parte == "En alguna provincia", ],
      ggplot2::aes(label = pct_co(valor * 100, dec = 1)),
      position = ggplot2::position_stack(reverse = TRUE, vjust = 0.5),
      color = COLOR$superficie, family = FUENTE, size = PT$valor / .pt) +
    ggplot2::scale_fill_manual(
      values = c(`En alguna provincia` = COLOR$resalte,
                 `Fuera del esquema` = COLOR$grilla), name = NULL) +
    ggplot2::scale_x_continuous(labels = function(x) pct_co(x * 100, dec = 0),
                                expand = ggplot2::expansion(mult = c(0, 0.02))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "x") +
    textos_fig(
      titulo = sprintf(
        "Las once provincias reúnen %s de los municipios de Antioquia y %s de su población",
        pct_co(cob$municipios_provincia / cob$municipios_departamento * 100, dec = 0),
        pct_co(cob$poblacion_provincias / cob$poblacion_departamento * 100, dec = 0)),
      subtitulo = paste("Parte del departamento que pertenece a alguna de las",
                        "once Provincias Administrativas y de Planificación"),
      fuente = "DANE y Gobernación de Antioquia. Cálculos propios.")
}

# --- 2. Mapa de las once provincias ------------------------------------------

fig_mapa_provincias <- function(panel, columna, titulo, subtitulo, fuente_txt,
                                formato = num_co, leyenda = NULL) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  capa <- cartografia_municipios()
  capa$..valor <- panel[[columna]][match(capa$id_provincia, panel$id_provincia)]

  limites <- capa[!is.na(capa$id_provincia), ]
  contornos <- do.call(rbind, lapply(split(limites, limites$id_provincia),
                                     function(g) {
    sf::st_sf(id_provincia = g$id_provincia[1],
              geometry = sf::st_union(sf::st_geometry(g)))
  }))
  et <- .puntos_de_etiqueta(
    contornos,
    etiquetas = PROVINCIAS$etiqueta[match(contornos$id_provincia, PROVINCIAS$id)])

  ggplot2::ggplot(capa) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data[["..valor"]]),
                     color = COLOR$superficie, linewidth = 0.1) +
    ggplot2::geom_sf(data = contornos, fill = NA, color = COLOR$tinta_2,
                     linewidth = 0.45) +
    scale_fill_provincias_c(name = leyenda, labels = formato,
                            na.value = "#EFEFEF") +
    .capa_etiquetas(et) +
    ggplot2::coord_sf(datum = NA) +
    theme_mapa() +
    textos_fig(titulo = titulo, subtitulo = subtitulo, fuente = fuente_txt,
               nota = paste("En gris, los municipios de Antioquia que no",
                            "pertenecen a ninguna provincia."),
               ancho_cm = 12.5)
}

# --- 3. Perfil de posiciones --------------------------------------------------

#' Mapa de calor de la posición de cada provincia en cada indicador.
#'
#' Se ordena de 1 a 11 orientando cada indicador según su `sentido`, de modo que
#' 1 sea siempre la mejor posición. Los indicadores sin orientación normativa
#' —extensión, población— quedan fuera: no existe un «mejor» tamaño.
tabla_posiciones <- function(panel) {
  con_sentido <- Filter(function(i) i$sentido != 0, INDICADORES)
  filas <- lapply(con_sentido, function(ind) {
    v <- panel[[ind$id]]
    if (all(is.na(v))) return(NULL)
    r <- rank(ind$sentido * -v, na.last = "keep", ties.method = "min")
    data.frame(indicador = ind$etiqueta, dominio = ind$dominio,
               provincia = panel$provincia, puesto = r,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, Filter(Negate(is.null), filas))
}

fig_perfil_posiciones <- function(panel) {
  pos <- tabla_posiciones(panel)
  if (is.null(pos) || !nrow(pos)) return(NULL)

  # Las once provincias van en el eje X y los indicadores en el Y: con 33
  # indicadores, la orientación contraria exige una figura de 26 cm de ancho
  # que, reducida al ancho de caja del informe, deja el texto en cuatro puntos.
  medio <- stats::aggregate(puesto ~ provincia, pos, stats::median)
  orden_prov <- medio$provincia[order(medio$puesto)]
  pos$provincia <- factor(pos$provincia, levels = orden_prov)
  orden_ind <- unique(pos[order(pos$dominio, pos$indicador),
                          c("dominio", "indicador")])
  pos$indicador <- factor(pos$indicador, levels = rev(orden_ind$indicador))

  # El número va en blanco sobre los tonos oscuros de la rampa y en tinta sobre
  # los claros: con un solo color, la mitad de la tabla es ilegible.
  pos$claro <- pos$puesto >= 7

  ggplot2::ggplot(pos, ggplot2::aes(x = provincia, y = indicador, fill = puesto)) +
    ggplot2::geom_tile(color = COLOR$superficie, linewidth = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = puesto, color = claro),
                       size = PT$fuente / .pt, family = FUENTE,
                       show.legend = FALSE) +
    ggplot2::scale_color_manual(values = c(`TRUE` = COLOR$tinta_1,
                                           `FALSE` = COLOR$superficie)) +
    ggplot2::scale_fill_gradientn(
      # Sin título: «1.º (mejor)» y «11.º (peor)» ya dicen qué es la escala, y
      # el rótulo se encimaba con la primera marca.
      colours = rev(PALETA_SECUENCIAL), name = NULL,
      breaks = c(1, 6, 11), labels = c("1.º (mejor)", "6.º", "11.º (peor)")) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1,
                                          size = PT$fuente, color = COLOR$tinta_1),
      axis.text.y = ggplot2::element_text(size = PT$fuente),
      legend.position = "top", legend.direction = "horizontal",
      legend.title = ggplot2::element_text(size = PT$leyenda, color = COLOR$tinta_2),
      legend.key.width = grid::unit(1.4, "cm"),
      legend.key.height = grid::unit(0.3, "cm")) +
    textos_fig(
      titulo = "Ninguna provincia está bien o mal en todo",
      subtitulo = paste("Puesto de cada provincia entre las once, indicador por",
                        "indicador; 1 es la mejor posición. Provincias ordenadas",
                        "por su puesto mediano"),
      fuente = "Panel provincial del proyecto. Cálculos propios.",
      nota = paste("Se excluyen los indicadores sin orientación normativa",
                   "(extensión, población): no existe un tamaño «mejor»."))
}

# --- 4. Dispersión ------------------------------------------------------------

#' Describe la fuerza de una correlación con umbrales declarados.
#' Existe para que el titular de una figura salga del coeficiente y no al revés:
#' un título que afirma una relación que el dato no sostiene es una invención,
#' aunque el gráfico esté bien dibujado.
describir_r <- function(r) {
  a <- abs(r)
  if (is.na(r)) return("no calculable")
  if (a >= 0.7) "fuerte" else if (a >= 0.4) "moderada"
  else if (a >= 0.2) "débil" else "prácticamente nula"
}


fig_dispersion <- function(panel, x, y, titulo, subtitulo, fuente_txt,
                           etiqueta_x, etiqueta_y,
                           fmt_x = function(x) pct_co(x * 100, dec = 0),
                           fmt_y = function(x) pct_co(x * 100, dec = 0)) {
  d <- panel[!is.na(panel[[x]]) & !is.na(panel[[y]]), , drop = FALSE]
  d$x <- d[[x]]; d$y <- d[[y]]
  et <- if (HAY_REPEL) {
    ggrepel::geom_text_repel(
      ggplot2::aes(label = provincia), size = PT$fuente / .pt, family = FUENTE,
      color = COLOR$tinta_2, min.segment.length = 0.2, segment.size = 0.25,
      segment.color = COLOR$tinta_3, box.padding = 0.3, max.overlaps = Inf,
      seed = 1)
  } else {
    # Sin ggrepel las once etiquetas se montan unas sobre otras. Aquí no se
    # omite la figura —no es un mapa—, pero tampoco se degrada en silencio.
    # Hallazgo de Pablo (F-1-010), adoptado también aquí.
    warning("Falta ggrepel: las etiquetas de '", titulo,
            "' van en el punto y pueden superponerse.", call. = FALSE)
    ggplot2::geom_text(ggplot2::aes(label = provincia), size = PT$fuente / .pt,
                       family = FUENTE, color = COLOR$tinta_2, vjust = -1)
  }

  ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point(size = 2.5, color = COLOR$resalte, alpha = 0.85) +
    et +
    ggplot2::scale_x_continuous(labels = fmt_x) +
    ggplot2::scale_y_continuous(labels = fmt_y) +
    ggplot2::labs(x = etiqueta_x, y = etiqueta_y) +
    theme_provincias(grilla = "ambas") +
    textos_fig(titulo = titulo, subtitulo = subtitulo, fuente = fuente_txt)
}

# --- Orquestación -------------------------------------------------------------

generar_figuras_comparativas <- function(panel = NULL) {
  message("== Figuras comparativas ==")
  if (is.null(panel)) panel <- construir_panel()
  dir.create(DIR_FIG_COMP, recursive = TRUE, showWarnings = FALSE)
  ref <- referencia_departamental()

  guardar_fig(fig_cobertura_sistema(panel), "fig_c01_cobertura_sistema",
              DIR_FIG_COMP, alto = 7)

  if (HAY_CARTOGRAFIA) {
    guardar_fig(fig_mapa_provincias(
      panel, "densidad", "Las once provincias de Antioquia",
      "Densidad poblacional de cada provincia, en habitantes por km² (2025)",
      "DANE, proyecciones de población. Cálculos propios.",
      formato = function(x) num_co(x, 0), leyenda = "hab/km²"),
      "fig_c02_mapa_densidad", DIR_FIG_COMP, alto = 12)

    guardar_fig(fig_mapa_provincias(
      panel, "nbi", "La pobreza por NBI dibuja una geografía provincial",
      "Personas en pobreza por Necesidades Básicas Insatisfechas, ECV 2023",
      "DANE, Encuesta de Calidad de Vida 2023. Cálculos propios.",
      formato = function(x) pct_co(x * 100, dec = 0), leyenda = "% de personas"),
      "fig_c03_mapa_nbi", DIR_FIG_COMP, alto = 12)
  }

  guardar_fig(.barras_panel(
    panel, "poblacion", "El Área Metropolitana concentra la población del sistema provincial",
    "Población proyectada por provincia, 2025",
    "DANE, proyecciones de población 2018-2042. Cálculos propios.",
    etiqueta = function(x) num_co(x, 0)),
    "fig_c04_poblacion", DIR_FIG_COMP, n_barras = nrow(panel))

  guardar_fig(.barras_panel(
    panel, "pct_rural", "Diez de las once provincias son mayoritariamente rurales o están cerca de serlo",
    "Porcentaje de población en centros poblados y rural disperso, 2025",
    "DANE, proyecciones de población 2018-2042. Cálculos propios.",
    etiqueta = function(x) pct_co(x * 100, dec = 1)),
    "fig_c05_ruralidad", DIR_FIG_COMP, n_barras = nrow(panel))

  guardar_fig(.barras_panel(
    panel, "nbi", "La pobreza por NBI separa a las provincias en dos grupos",
    "Personas en pobreza por NBI, ECV 2023",
    "DANE, Encuesta de Calidad de Vida 2023. Cálculos propios.",
    etiqueta = function(x) pct_co(x * 100, dec = 1),
    referencia = ref$nbi,
    etiqueta_ref = if (!is.na(ref$nbi)) sprintf("Antioquia: %s",
                                                pct_co(ref$nbi * 100, dec = 1)) else NULL),
    "fig_c06_nbi", DIR_FIG_COMP, n_barras = nrow(panel))

  guardar_fig(.barras_panel(
    panel, "icm", "El Índice de Ciudades Modernas ordena a las provincias por su desarrollo territorial",
    "ICM más reciente disponible, escala 0-100",
    "DNP, Índice de Ciudades Modernas. Cálculos propios.",
    etiqueta = function(x) num_co(x, 1),
    referencia = ref$icm,
    etiqueta_ref = if (!is.na(ref$icm)) sprintf("Antioquia: %s",
                                                num_co(ref$icm, 1)) else NULL),
    "fig_c07_icm", DIR_FIG_COMP, n_barras = nrow(panel))

  guardar_fig(.barras_panel(
    panel, "homicidios", "La violencia homicida se concentra en unas pocas provincias",
    "Homicidios por cada 100.000 habitantes",
    "Policía Nacional, SIEDCO. Cálculos propios.",
    etiqueta = function(x) num_co(x, 1),
    referencia = ref$homicidios,
    etiqueta_ref = if (!is.na(ref$homicidios)) sprintf("Antioquia: %s",
                                                       num_co(ref$homicidios, 1)) else NULL),
    "fig_c08_homicidios", DIR_FIG_COMP, n_barras = nrow(panel))

  # Las dos dispersiones se titulan con lo que dice el coeficiente, calculado
  # aquí mismo. La primera existe justamente porque la relación NO se sostiene
  # al sacar al Área Metropolitana: es un resultado, no un gráfico fallido.
  sin_am <- panel[panel$id_provincia != 11, ]
  r_rur <- stats::cor(panel$pct_rural, panel$nbi, use = "complete.obs")
  r_rur_s <- stats::cor(sin_am$pct_rural, sin_am$nbi, use = "complete.obs")
  r_icm <- stats::cor(sin_am$icm, sin_am$nbi, use = "complete.obs")

  guardar_fig(fig_dispersion(
    panel, "pct_rural", "nbi",
    "Entre las diez provincias rurales, ser más rural no predice más pobreza",
    sprintf(paste("Cada punto es una provincia. La correlación con las once es",
                  "%s (%s); sin el Área Metropolitana cae a %s (%s)"),
            num_co(r_rur, 2), describir_r(r_rur),
            num_co(r_rur_s, 2), describir_r(r_rur_s)),
    "DANE, proyecciones de población y ECV 2023. Cálculos propios.",
    "Población rural", "Pobreza por NBI"),
    "fig_c09_ruralidad_nbi", DIR_FIG_COMP, ancho = 16, alto = 11)

  guardar_fig(fig_dispersion(
    sin_am, "icm", "nbi",
    "El desarrollo territorial y la pobreza se mueven en direcciones opuestas",
    sprintf(paste("Diez provincias, sin el Área Metropolitana. Correlación de",
                  "%s: relación %s"), num_co(r_icm, 2), describir_r(r_icm)),
    "DNP, Índice de Ciudades Modernas, y DANE, ECV 2023. Cálculos propios.",
    "Índice de Ciudades Modernas", "Pobreza por NBI",
    fmt_x = etiqueta_num(0)),
    "fig_c10_icm_nbi", DIR_FIG_COMP, ancho = 16, alto = 11)

  p <- fig_perfil_posiciones(panel)
  if (!is.null(p)) {
    # 33 indicadores a 0,55 cm por fila, más el bloque de textos y la leyenda.
    guardar_fig(p, "fig_c11_perfil_posiciones", DIR_FIG_COMP,
                ancho = 16, alto = 22)
  }

  message("  figuras en 03_Outputs/_Comparativo/figuras/")
  invisible(panel)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "figuras_comparativas.R") {
  generar_figuras_comparativas()
}
