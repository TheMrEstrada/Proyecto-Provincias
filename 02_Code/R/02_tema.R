# =============================================================================
# 02_tema.R — Sistema visual del Proyecto Provincias
#
# Implementa el manual 02_Code/04_figuras/DISENO.md: paleta EAFIT verificada,
# tipografía, tema ggplot2, geoms de uso frecuente y exportación PNG+PDF.
#
# Ninguna figura del proyecto define colores, tamaños ni fuentes por su cuenta:
# todo sale de aquí. Si algo hay que cambiar, se cambia en este archivo y en
# DISENO.md, no en la figura.
#
# ETAPA DEL PIPELINE: infraestructura (lo carga 00_config.R)
# =============================================================================

# --- Paleta ------------------------------------------------------------------
# Colores oficiales EAFIT (Manual de Marca 2025 v4.0). Verificados con el
# validador de paleta: ver la tabla de resultados en DISENO.md §9.

#' Categórica: orden fijo, se asigna en secuencia y nunca se cicla.
PALETA_SERIES <- c(
  azul_marino    = "#4458A6",  # Pantone 7455 C
  naranja        = "#FF8F1B",  # Pantone 151 C
  verde_selva    = "#159449",  # Pantone 7482 C
  mora           = "#BA3A93",  # Pantone 240 C
  turquesa_menta = "#46C69F",  # Pantone 3395 C
  baya           = "#C24A49"   # Pantone 7418 C
)

#' Secuencial: rampa monocroma en el hue del Azul Zafre EAFIT (264°).
PALETA_SECUENCIAL <- c("#A1B4DB", "#7391D0", "#456DC5", "#1E47B1", "#02228F", "#00015E")

#' Divergente: brazos en los hues de Baya (24°) y Azul marino (270°), neutro gris.
PALETA_DIVERGENTE <- c("#BB4343", "#CD7671", "#D5A39F", "#E8E8E6", "#A3B0D5", "#7B8FD0", "#546AC0")

#' Roles de dato y de tinta.
COLOR <- list(
  resalte     = "#4458A6",
  contexto    = "#888C94",
  referencia  = "#C24A49",
  superficie  = "#FFFFFF",
  tinta_1     = "#292E38",
  tinta_2     = "#595E66",
  tinta_3     = "#888C94",
  grilla      = "#DCDEE1"
)

# --- Tipografía --------------------------------------------------------------
# Inter es la fuente canónica (Manual EAFIT pp. 38-42). Si no está instalada se
# degrada en cadena; una figura nunca falla por falta de tipografía.
.familia_disponible <- function() {
  candidatas <- c("Inter", "Roboto Serif", "Arial", "Helvetica")
  instaladas <- tryCatch(systemfonts::system_fonts()$family, error = function(e) character(0))
  elegida <- candidatas[candidatas %in% instaladas][1]
  if (is.na(elegida)) {
    warning("No se encontró Inter ni sus reemplazos; se usa la fuente por defecto.", call. = FALSE)
    return("")
  }
  if (elegida != "Inter") {
    message("[tema] Inter no está instalada; se usa '", elegida, "'. ",
            "Para el resultado canónico instale Inter (SIL OFL).")
  }
  elegida
}

FUENTE <- .familia_disponible()

# Tamaños en puntos (DISENO.md §3)
PT <- list(titulo = 12, subtitulo = 10, valor = 8.5, categoria = 9,
           escala = 8.5, eje = 9, leyenda = 9, fuente = 7.5)

# --- Tema --------------------------------------------------------------------

#' Tema base de las figuras del proyecto
#'
#' @param grilla "x", "y", "ambas" o "ninguna". Las barras horizontales usan
#'   "ninguna" porque el valor va etiquetado; las líneas usan "y".
#' @param eje_x_visible FALSE elimina texto, marcas y línea del eje X (barras
#'   horizontales etiquetadas: el eje sería tinta redundante).
theme_provincias <- function(grilla = "y", eje_x_visible = TRUE) {
  grilla <- match.arg(grilla, c("y", "x", "ambas", "ninguna"))
  linea_grilla <- ggplot2::element_line(color = COLOR$grilla, linewidth = 0.3)

  t <- ggplot2::theme_minimal(base_family = FUENTE, base_size = PT$categoria) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        size = PT$titulo, face = "bold", color = COLOR$tinta_1,
        margin = ggplot2::margin(b = 2), hjust = 0
      ),
      plot.subtitle = ggplot2::element_text(
        size = PT$subtitulo, color = COLOR$tinta_2,
        margin = ggplot2::margin(b = 10), hjust = 0
      ),
      plot.caption = ggplot2::element_text(
        size = PT$fuente, color = COLOR$tinta_3,
        margin = ggplot2::margin(t = 10), hjust = 0
      ),
      plot.caption.position = "plot",
      plot.title.position = "plot",
      axis.title = ggplot2::element_text(size = PT$eje, color = COLOR$tinta_2),
      axis.text.y = ggplot2::element_text(size = PT$categoria, color = COLOR$tinta_1),
      axis.text.x = ggplot2::element_text(size = PT$escala, color = COLOR$tinta_2),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = PT$leyenda, color = COLOR$tinta_2),
      legend.key.size = grid::unit(0.4, "cm"),
      legend.margin = ggplot2::margin(b = 4),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = if (grilla %in% c("x", "ambas")) linea_grilla else ggplot2::element_blank(),
      panel.grid.major.y = if (grilla %in% c("y", "ambas")) linea_grilla else ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = COLOR$superficie, color = NA),
      panel.background = ggplot2::element_rect(fill = COLOR$superficie, color = NA),
      plot.margin = ggplot2::margin(t = 6, r = 6, b = 2, l = 2)
    )

  if (!eje_x_visible) {
    t <- t + ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank()
    )
  }
  t
}

# --- Escalas -----------------------------------------------------------------

#' Escalas categóricas con el orden fijo de la paleta.
#' Aborta si se piden más series de las que la paleta admite: el límite es una
#' regla del sistema (DISENO.md §2.1), no un detalle de implementación.
.series <- function(n) {
  if (n > length(PALETA_SERIES)) {
    stop("Se pidieron ", n, " series y la paleta admite ", length(PALETA_SERIES),
         ". Agrupe en 'Otros', use múltiplos pequeños o cambie de forma; ",
         "no añada un color nuevo.", call. = FALSE)
  }
  unname(PALETA_SERIES[seq_len(n)])
}

scale_fill_provincias <- function(...) {
  ggplot2::discrete_scale("fill", palette = function(n) .series(n), ...)
}
scale_color_provincias <- function(...) {
  ggplot2::discrete_scale("colour", palette = function(n) .series(n), ...)
}
scale_fill_provincias_c <- function(...) {
  ggplot2::scale_fill_gradientn(colours = PALETA_SECUENCIAL, ...)
}
#' Divergente centrada en un punto de referencia (por defecto 0).
scale_fill_provincias_div <- function(centro = 0, ...) {
  ggplot2::scale_fill_gradientn(
    colours = PALETA_DIVERGENTE,
    rescaler = function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
      scales::rescale_mid(x, to, from, mid = centro)
    }, ...
  )
}

# --- Formato numérico (Colombia) ---------------------------------------------
# Punto para miles, coma decimal (DISENO.md §7).

num_co <- function(x, dec = 0) {
  formatC(x, format = "f", digits = dec, big.mark = ".", decimal.mark = ",")
}
pct_co <- function(x, dec = 1, ya_en_pct = TRUE) {
  v <- if (ya_en_pct) x else x * 100
  paste0(formatC(v, format = "f", digits = dec, big.mark = ".", decimal.mark = ","), " %")
}
#' Etiquetador para ejes (se pasa a scale_*_continuous(labels = ...)).
etiqueta_num <- function(dec = 0) function(x) num_co(x, dec)
etiqueta_pct <- function(dec = 0) function(x) pct_co(x, dec)

# --- Composición de la figura -------------------------------------------------

#' Bloque de texto estándar: título afirmativo, subtítulo con unidad/año/ámbito,
#' fuente. Ver DISENO.md §6.
#'
#' Los textos se reparten en varias líneas según el ancho de la figura: un
#' título o subtítulo largo se cortaría en el borde derecho al exportar, porque
#' ggplot2 no ajusta el texto solo.
#'
#' @param ancho_cm ancho al que se va a exportar la figura (16 cm por defecto,
#'   el ancho de caja del informe).
textos_fig <- function(titulo, subtitulo = NULL, fuente = NULL, nota = NULL,
                       ancho_cm = 16) {
  # Caracteres por línea: aproximación empírica para Inter, ~1,9 mm por carácter
  # a 10 pt. Se escala con el tamaño de cada elemento.
  por_linea <- function(pt) floor(ancho_cm * 10 / (pt * 0.19))

  envolver <- function(x, pt) {
    if (is.null(x)) return(NULL)
    stringr::str_wrap(x, width = por_linea(pt))
  }

  pie <- NULL
  if (!is.null(fuente)) {
    pie <- paste0("Fuente: ", fuente)
    if (!is.null(nota)) pie <- paste0(pie, " · ", nota)
  } else if (!is.null(nota)) {
    pie <- nota
  }

  ggplot2::labs(
    title = envolver(titulo, PT$titulo),
    subtitle = envolver(subtitulo, PT$subtitulo),
    caption = envolver(pie, PT$fuente)
  )
}

# --- Geoms de uso frecuente ---------------------------------------------------

#' Barras horizontales ordenadas por valor, con etiqueta directa y resalte
#' opcional de un municipio. Es la forma más usada del diagnóstico.
#'
#' @param datos data.frame con las columnas indicadas.
#' @param categoria,valor nombres (sin comillas) de las columnas.
#' @param resaltar valor de `categoria` que va en color de resalte (NULL = todas
#'   en el color de serie 1).
#' @param etiqueta función que formatea el valor (num_co, pct_co, …).
#' @param referencia valor numérico para la línea de promedio (NULL = sin línea).
#' @param etiqueta_referencia texto junto a la línea de referencia.
fig_barras <- function(datos, categoria, valor, resaltar = NULL,
                       etiqueta = num_co, referencia = NULL,
                       etiqueta_referencia = NULL, descendente = TRUE) {
  cat_q <- rlang::ensym(categoria)
  val_q <- rlang::ensym(valor)

  d <- datos
  d[["..cat"]] <- as.character(d[[rlang::as_string(cat_q)]])
  d[["..val"]] <- as.numeric(d[[rlang::as_string(val_q)]])
  d <- d[!is.na(d[["..val"]]), , drop = FALSE]
  orden <- order(d[["..val"]], decreasing = !descendente)
  d[["..cat"]] <- factor(d[["..cat"]], levels = d[["..cat"]][orden])
  d[["..destacado"]] <- if (is.null(resaltar)) TRUE else d[["..cat"]] %in% resaltar

  rango <- range(c(0, d[["..val"]]), na.rm = TRUE)
  holgura <- diff(rango) * 0.12

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[["..val"]], y = .data[["..cat"]]))

  # La línea de referencia va ANTES de las barras y las etiquetas: dibujada
  # después, cruza por encima de los valores cercanos al promedio y los tacha.
  if (!is.null(referencia)) {
    p <- p + ggplot2::geom_vline(
      xintercept = referencia, linetype = "dashed",
      linewidth = 0.35, color = COLOR$referencia
    )
  }

  p <- p +
    ggplot2::geom_col(
      ggplot2::aes(fill = .data[["..destacado"]]),
      width = 0.68, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = COLOR$resalte, `FALSE` = COLOR$contexto)) +
    ggplot2::geom_text(
      ggplot2::aes(label = etiqueta(.data[["..val"]])),
      hjust = -0.15, size = PT$valor / .pt, family = FUENTE,
      color = COLOR$tinta_1, fontface = "plain"
    ) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.14)),
                                limits = c(min(0, rango[1]), rango[2] + holgura)) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)

  if (!is.null(referencia)) {
    # Solo el rótulo: la línea ya se dibujó bajo las barras (ver arriba).
    p <- p +
      ggplot2::annotate(
        "text", x = referencia, y = Inf,
        label = etiqueta_referencia %||% paste0("Promedio: ", etiqueta(referencia)),
        vjust = -0.4, hjust = 0.5, size = PT$fuente / .pt,
        family = FUENTE, color = COLOR$referencia
      ) +
      ggplot2::coord_cartesian(clip = "off")
  }
  p
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# --- Exportación --------------------------------------------------------------

#' Guarda una figura en PNG (300 dpi, para Word) y PDF (vectorial, para imprenta)
#'
#' @param p objeto ggplot.
#' @param nombre base del archivo, sin extensión: "fig_03_area_por_municipio".
#' @param dir carpeta de destino; se crea si no existe.
#' @param ancho,alto en centímetros. Si `alto` es NULL y se pasa `n_barras`, se
#'   calcula con la fórmula de DISENO.md §4 (4 + 0,55·n).
#' @return la ruta del PNG, de forma invisible.
guardar_fig <- function(p, nombre, dir, ancho = 16, alto = NULL, n_barras = NULL) {
  if (is.null(alto)) {
    alto <- if (!is.null(n_barras)) 4 + 0.55 * n_barras else 9
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ruta_png <- file.path(dir, paste0(nombre, ".png"))
  ruta_pdf <- file.path(dir, paste0(nombre, ".pdf"))

  ggplot2::ggsave(ruta_png, p, device = ragg::agg_png, width = ancho, height = alto,
                  units = "cm", dpi = 300, bg = COLOR$superficie)
  ggplot2::ggsave(ruta_pdf, p, device = grDevices::cairo_pdf, width = ancho, height = alto,
                  units = "cm", bg = COLOR$superficie)

  message("  [fig] ", nombre, "  (", ancho, "x", round(alto, 1), " cm)")
  invisible(ruta_png)
}
