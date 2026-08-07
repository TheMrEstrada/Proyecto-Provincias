# ============================================================================
# 02_utils.R  —  Helpers para leer datos y escribir figuras nativas
# ============================================================================
suppressMessages({ library(openxlsx2); library(encharter) })


# --- Normalizar texto (sin acentos, minúsculas) para casar nombres en cualquier locale/OS
.norm <- function(x) tolower(iconv(x, to = "ASCII//TRANSLIT"))
# --- Seleccionar una columna por coincidencia insensible a acentos
pick_name <- function(df, key) {
  cn <- names(df); i <- which(grepl(.norm(key), .norm(cn), fixed = TRUE))
  if (length(i) == 0) stop("Columna no encontrada: ", key); cn[i[1]]
}
pick <- function(df, key) {
  cn <- names(df); i <- which(grepl(.norm(key), .norm(cn), fixed = TRUE))
  if (length(i) == 0) stop("Columna no encontrada: ", key)
  df[[cn[i[1]]]]
}

# --- Referencia de celda estilo "'hoja'!$C$2:$C$8"
.ref <- function(sheet, col, r1, r2 = NULL) {
  L <- openxlsx2::int2col(col)
  if (is.null(r2)) sprintf("'%s'!$%s$%s", sheet, L, r1)
  else             sprintf("'%s'!$%s$%s:$%s$%s", sheet, L, r1, L, r2)
}

# --- Leer una hoja de datos y quedarse SOLO con municipios (quita agregados).
#   Criterio robusto: municipio = fila con Código DANE no vacío.
leer_municipios <- function(wb, sheet) {
  df <- openxlsx2::wb_to_df(wb, sheet = sheet)
  dane <- tryCatch(pick_name(df, "codigo dane"), error = function(e) NA_character_)
  if (!is.na(dane)) {
    keep <- !is.na(df[[dane]]) & trimws(as.character(df[[dane]])) != ""
    return(df[keep, , drop = FALSE])
  }
  mun <- pick_name(df, "municipio"); df <- df[!is.na(df[[mun]]), , drop = FALSE]
  df[!grepl("^(TOTAL|PROMEDIO|SUBREGI|DEPARTAMENTO|PROVINCIA)", df[[mun]], ignore.case = TRUE), , drop = FALSE]
}

# --- Escribir una hoja auxiliar OCULTA con los datos exactos a graficar
.hoja_aux <- function(wb, name, data) {
  if (name %in% wb$get_sheet_names()) wb$remove_worksheet(name)
  wb$add_worksheet(name, visible = FALSE)
  wb$add_data(sheet = name, x = data, col_names = TRUE)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_hbar: barra horizontal nativa (simple o apilada 100%), ordenada, con
#           etiquetas de dato y estilo de la plantilla.
#   data: data.frame con 1a col = categoría (Municipio) y >=1 col de valores
#   value_cols: nombres de columnas de valor (en orden de apilado)
#   colors: colores por serie
#   percent: TRUE -> percentStacked 100%; FALSE -> barra simple
#   label_series: índice(s) de serie que muestran etiqueta de dato
#   num_fmt: formato de número para etiquetas (p.ej "0.0%" o "0.0")
# ----------------------------------------------------------------------------
#   grouping: "standard" (barra simple), "percentStacked" (apilada 100%),
#             "stacked" (apilada absoluta), "clustered" (agrupada, multi-serie)
enc_hbar <- function(wb, target_sheet, anchor, aux_name, data,
                     cat_col, value_cols, colors, titulo,
                     grouping = "standard", label_series = 1, num_fmt = "0.0",
                     legend = TRUE, sort = TRUE, sort_desc = TRUE) {
  if (isTRUE(sort)) {  # asc en la tabla -> mayor arriba en barra horizontal
    ord <- order(data[[value_cols[1]]], decreasing = !sort_desc)
    data <- data[ord, , drop = FALSE]
  }
  data <- data[, c(cat_col, value_cols), drop = FALSE]
  .hoja_aux(wb, aux_name, data)
  n  <- nrow(data); r1 <- 2; r2 <- n + 1
  stacked <- grouping %in% c("stacked", "percentStacked")
  # formatear celdas fuente -> las etiquetas de dato heredan el formato en Excel
  dims_val <- openxlsx2::wb_dims(rows = r1:r2, cols = 2:(1 + length(value_cols)))
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name, dims = dims_val, numfmt = num_fmt)
  ch <- encharter::encharter("barChart")
  for (j in seq_along(value_cols)) {
    ch$add_series(
      name  = .ref(aux_name, 1 + j, 1),
      data  = .ref(aux_name, 1 + j, r1, r2),
      label = .ref(aux_name, 1, r1, r2),
      color = colors[((j - 1) %% length(colors)) + 1], dir = "bar", grouping = grouping,
      overlap = if (stacked) 100 else NULL,
      show_val = j %in% label_series
    )
  }
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_data_label_style(show_val = TRUE, pos = if (stacked) "ctr" else "outEnd", format = num_fmt)
  if (legend) ch$set_legend_style(pos = "b") else ch$set_legend_style(pos = "none")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_piramide: pirámide poblacional nativa (barras horizontales apiladas,
#   hombres en negativo -> izquierda, mujeres positivo -> derecha).
#   bandas: vector de etiquetas de edad (orden ascendente: "0 a 9" ... "80 o más")
# ----------------------------------------------------------------------------
enc_piramide <- function(wb, target_sheet, anchor, aux_name, bandas, hombres, mujeres,
                         titulo, col_h, col_m, num_fmt = "#,##0") {
  df <- data.frame(Banda = bandas,
                   Hombres = -abs(as.numeric(hombres)),
                   Mujeres =  abs(as.numeric(mujeres)), check.names = FALSE)
  .hoja_aux(wb, aux_name, df)
  n <- nrow(df); r1 <- 2; r2 <- n + 1
  fmt <- paste0(num_fmt, ";", num_fmt)   # positivo;negativo -> ambos sin signo
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
                                 dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:3), numfmt = fmt)
  ch <- encharter::encharter("barChart")
  ch$add_series(name = .ref(aux_name, 2, 1), data = .ref(aux_name, 2, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = col_h,
                dir = "bar", grouping = "stacked", overlap = 100, show_val = TRUE)
  ch$add_series(name = .ref(aux_name, 3, 1), data = .ref(aux_name, 3, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = col_m,
                dir = "bar", grouping = "stacked", overlap = 100, show_val = TRUE)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_data_label_style(show_val = TRUE, pos = "inEnd", format = fmt)
  maxv  <- max(abs(c(as.numeric(hombres), as.numeric(mujeres))), na.rm = TRUE)
  bound <- ceiling(maxv / 2000) * 2000
  ch$set_y_axis(min = -bound, max = bound, major = bound / 3, format = fmt)  # eje de valores
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# estilo_tabla: da formato tipo Anexo a la hoja de datos (encabezado navy,
#   bordes finos, formatos de número por columna, filas TOTAL resaltadas).
#   Reutilizable para las ~30 tablas del diagnóstico.
#   formats: lista nombrada patrón(sin acentos) -> código de formato Excel
# ----------------------------------------------------------------------------
estilo_tabla <- function(wb, sheet, formats = list(), num_default = NULL,
                         hide_cols = c("codigo dane", "subregion", "provincia"),
                         header_fill = "FF002060", header_font = "FFFFFFFF",
                         total_fill = "FFD9E1F2", grid = "FFBFBFBF") {
  df <- openxlsx2::wb_to_df(wb, sheet = sheet, col_names = TRUE)
  n <- nrow(df); m <- ncol(df); cn <- names(df); last <- n + 1

  # bordes (contorno + rejilla interna)
  full <- openxlsx2::wb_dims(rows = 1:last, cols = 1:m)
  wb <- openxlsx2::wb_add_border(wb, sheet, dims = full,
          inner_hgrid = "thin", inner_vgrid = "thin",
          inner_hcolor = openxlsx2::wb_color(hex = grid),
          inner_vcolor = openxlsx2::wb_color(hex = grid))

  # encabezado
  hdr <- openxlsx2::wb_dims(rows = 1, cols = 1:m)
  wb <- openxlsx2::wb_add_fill(wb, sheet, dims = hdr, color = openxlsx2::wb_color(hex = header_fill))
  wb <- openxlsx2::wb_add_font(wb, sheet, dims = hdr, name = tema$fuente,
          color = openxlsx2::wb_color(hex = header_font), bold = TRUE, size = "11")
  wb <- openxlsx2::wb_add_cell_style(wb, sheet, dims = hdr,
          horizontal = "center", vertical = "center", wrap_text = TRUE)

  # formatos de número por columna
  for (j in seq_len(m)) {
    fmt <- NULL
    for (pat in names(formats)) if (grepl(.norm(pat), .norm(cn[j]), fixed = TRUE)) { fmt <- formats[[pat]]; break }
    if (is.null(fmt) && is.numeric(df[[j]]) && !is.null(num_default)) fmt <- num_default
    if (!is.null(fmt))
      wb <- openxlsx2::wb_add_numfmt(wb, sheet,
              dims = openxlsx2::wb_dims(rows = 2:last, cols = j), numfmt = fmt)
  }

  # filas agregadas resaltadas (TOTAL / PROMEDIO PONDERADO / etc.)
  # criterio robusto: fila agregada = sin Código DANE
  dane <- tryCatch(pick_name(df, "codigo dane"), error = function(e) NA_character_)
  if (!is.na(dane)) {
    agg <- which(is.na(df[[dane]]) | trimws(as.character(df[[dane]])) == "")
  } else {
    mun <- tryCatch(pick_name(df, "municipio"), error = function(e) NA_character_)
    agg <- if (is.na(mun)) integer(0) else
             which(grepl("^(TOTAL|PROMEDIO|SUBREGI|DEPARTAMENTO)", df[[mun]], ignore.case = TRUE))
  }
  tot <- agg + 1
  for (r in tot) {
    d <- openxlsx2::wb_dims(rows = r, cols = 1:m)
    wb <- openxlsx2::wb_add_fill(wb, sheet, dims = d, color = openxlsx2::wb_color(hex = total_fill))
    wb <- openxlsx2::wb_add_font(wb, sheet, dims = d, name = tema$fuente, bold = TRUE)
  }

  # ocultar columnas de bookkeeping para replicar el Anexo (Municipio + indicadores)
  if (length(hide_cols)) {
    hide_idx <- which(vapply(cn, function(x) any(vapply(hide_cols,
                      function(p) grepl(.norm(p), .norm(x), fixed = TRUE), logical(1))), logical(1)))
    if (length(hide_idx)) wb$set_col_widths(sheet, cols = hide_idx, hidden = TRUE)
    vis <- setdiff(seq_len(m), hide_idx)
  } else vis <- seq_len(m)
  # ancho automático de columnas visibles
  if (length(vis)) wb$set_col_widths(sheet, cols = vis, widths = "auto")
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_line: líneas nativas (series temporales). df: 1a col = eje X (año/periodo),
#   columnas siguientes = series. Colores de tema$serie por defecto.
# ----------------------------------------------------------------------------
enc_line <- function(wb, target_sheet, anchor, aux_name, df, x_col, series_cols,
                     colors = tema$serie, titulo = "", num_fmt = "#,##0",
                     legend = TRUE, markers = TRUE) {
  d <- df[, c(x_col, series_cols), drop = FALSE]
  .hoja_aux(wb, aux_name, d)
  n <- nrow(d); r1 <- 2; r2 <- n + 1
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
          dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:(1 + length(series_cols))), numfmt = num_fmt)
  ch <- encharter::encharter("lineChart")
  for (j in seq_along(series_cols)) {
    ch$add_series(name = .ref(aux_name, 1 + j, 1), data = .ref(aux_name, 1 + j, r1, r2),
                  label = .ref(aux_name, 1, r1, r2),
                  color = colors[((j - 1) %% length(colors)) + 1],
                  marker = if (markers) "circle" else "none", marker_size = 5)
  }
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_y_axis(format = num_fmt)
  if (legend) ch$set_legend_style(pos = "b") else ch$set_legend_style(pos = "none")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_pie: torta nativa. labels + values (nivel provincia). Colores por porción.
# ----------------------------------------------------------------------------
enc_pie <- function(wb, target_sheet, anchor, aux_name, labels, values,
                    colors = tema$serie, titulo = "", num_fmt = "0.0%", hole = 0) {
  d <- data.frame(Categoria = labels, Valor = as.numeric(values), check.names = FALSE)
  .hoja_aux(wb, aux_name, d)
  n <- nrow(d); r1 <- 2; r2 <- n + 1
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
          dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2), numfmt = num_fmt)
  ch <- encharter::encharter(if (hole > 0) "doughnutChart" else "pieChart")
  ch$add_series(name = .ref(aux_name, 2, 1), data = .ref(aux_name, 2, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = colors[seq_len(n)])
  if (hole > 0) ch$set_pie_options(hole_size = hole)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_data_label_style(show_val = TRUE, show_cat = TRUE, pos = "outEnd", format = num_fmt)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_scatter: dispersión nativa. x, y numéricos; labels = etiquetas de punto.
#   (scatter en encharter: data = Y, label = X)
# ----------------------------------------------------------------------------
enc_scatter <- function(wb, target_sheet, anchor, aux_name, x, y, labels,
                        titulo = "", x_title = "", y_title = "",
                        color = tema$navy, num_fmt = "0.0") {
  d <- data.frame(Etiqueta = labels, X = as.numeric(x), Y = as.numeric(y), check.names = FALSE)
  .hoja_aux(wb, aux_name, d)
  n <- nrow(d); r1 <- 2; r2 <- n + 1
  ch <- encharter::encharter("scatterChart")
  ch$add_series(name = titulo, data = .ref(aux_name, 3, r1, r2), label = .ref(aux_name, 2, r1, r2),
                color = color, marker = "circle", marker_size = 7, show_line = FALSE)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  if (nzchar(x_title)) ch$set_x_title(x_title, font_size = tema$size_eje)
  if (nzchar(y_title)) ch$set_y_title(y_title, font_size = tema$size_eje)
  ch$set_legend_style(pos = "none")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_dumbbell: aproximación nativa editable (lineChart con 2 series de puntos
#   sin línea + líneas verticales de conexión high/low). cats en eje de categorías.
# ----------------------------------------------------------------------------
enc_dumbbell <- function(wb, target_sheet, anchor, aux_name, cats, v1, v2,
                         name1, name2, colors = c(tema$navy, tema$blue),
                         titulo = "", num_fmt = "0.0", sort = TRUE) {
  d <- data.frame(Categoria = cats, S1 = as.numeric(v1), S2 = as.numeric(v2), check.names = FALSE)
  if (isTRUE(sort)) d <- d[order(d$S1), , drop = FALSE]
  names(d) <- c("Categoria", name1, name2)
  .hoja_aux(wb, aux_name, d)
  n <- nrow(d); r1 <- 2; r2 <- n + 1
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
          dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:3), numfmt = num_fmt)
  ch <- encharter::encharter("lineChart")
  ch$add_series(name = .ref(aux_name, 2, 1), data = .ref(aux_name, 2, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = colors[1],
                marker = "circle", marker_size = 7, show_line = FALSE)
  ch$add_series(name = .ref(aux_name, 3, 1), data = .ref(aux_name, 3, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = colors[2],
                marker = "circle", marker_size = 7, show_line = FALSE)
  ch$high_low_lines <- TRUE
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# Utilidades de apoyo para los módulos de sección
# ----------------------------------------------------------------------------
# Filtrar un data.frame al último año disponible (si hay columna de año)
ultimo_anio <- function(df) {
  yc <- tryCatch(pick_name(df, "ano"), error = function(e) NA_character_)
  if (is.na(yc)) return(df)
  y <- suppressWarnings(as.numeric(df[[yc]]))
  if (all(is.na(y))) return(df)
  df[is.na(y) | y == max(y, na.rm = TRUE), , drop = FALSE]
}
# Ancla para un chart a la derecha de los datos, apilando por 'slot'
.anchor <- function(wb, sheet, slot = 0, gap = 20) {
  d <- openxlsx2::wb_to_df(wb, sheet = sheet)
  paste0(openxlsx2::int2col(ncol(d) + 2), 2 + slot * gap)
}
# Envoltorio: construye una figura; si falla, avisa y devuelve el wb sin cambios.
#   Uso:  wb <- .try("tag", wb, enc_hbar(wb, ...))
.try <- function(tag, wb, expr) {
  tryCatch({ r <- force(expr); message("   ok  ", tag); r },
           error = function(e) { message("   FALLO ", tag, ": ", conditionMessage(e)); wb })
}

# Reescribir una hoja dejando solo el último año (para tablas de un solo año).
# Llamar ANTES de anclar gráficos en esa hoja.
.hoja_ultimo_anio <- function(wb, sheet) {
  d <- openxlsx2::wb_to_df(wb, sheet = sheet)
  d2 <- ultimo_anio(d)
  if (nrow(d2) == nrow(d)) return(wb)
  wb$remove_worksheet(sheet); wb$add_worksheet(sheet)
  wb$add_data(sheet = sheet, x = d2, col_names = TRUE)
  invisible(wb)
}
