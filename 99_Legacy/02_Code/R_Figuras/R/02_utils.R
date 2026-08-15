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
#   value_axis: FALSE (por defecto) oculta el eje de valores y sus guías.
#   label_color: color hex de las etiquetas de dato (p. ej. "FFFFFF" en apiladas oscuras).
#   ref_lines: lista de líneas de referencia punteadas (agregados). Cada una:
#              list(value=<num>, color="4472C4", label="Provincia", line_type="dashed").
.or <- function(a, b) if (is.null(a)) b else a
# Elimina (delete=1) el eje de VALORES del último gráfico agregado (equivale a
# deseleccionar "Primary Horizontal" en Excel). No toca el eje de categorías.
.del_valax <- function(wb) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  x <- sub("(<c:valAx>.*?)<c:delete val=\"0\"/>", "\\1<c:delete val=\"1\"/>", x, perl = TRUE)
  wb$charts$chart[i] <- x
  invisible(wb)
}

# --- Quitar TODAS las líneas guía (major/minor) de un string de chart XML.
#   Los gráficos del diagnóstico no llevan líneas guía (comentario repetido del
#   catálogo). No aplica a radares (sus anillos no son majorGridlines aquí).
.strip_gridlines_str <- function(x) {
  x <- gsub("(?s)<c:majorGridlines>.*?</c:majorGridlines>", "", x, perl = TRUE)
  x <- gsub("<c:majorGridlines/>", "", x, fixed = TRUE)
  x <- gsub("(?s)<c:minorGridlines>.*?</c:minorGridlines>", "", x, perl = TRUE)
  x <- gsub("<c:minorGridlines/>", "", x, fixed = TRUE)
  x
}
.del_gridlines_last <- function(wb) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  wb$charts$chart[i] <- .strip_gridlines_str(wb$charts$chart[i])
  invisible(wb)
}
# --- Recolorea una sola barra (dPt) de la 1a serie del barChart del último chart.
#   idx = índice 0-based de la barra (p.ej. la barra de agregado Provincia).
.recolor_bar_last <- function(wb, idx, color) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  colh <- toupper(sub("^#", "", color))
  dpt <- sprintf(paste0('<c:dPt><c:idx val="%d"/><c:invertIfNegative val="0"/><c:bubble3D val="0"/>',
                        '<c:spPr><a:solidFill><a:srgbClr val="%s"/></a:solidFill></c:spPr></c:dPt>'), idx, colh)
  bc <- regmatches(x, regexpr("(?s)<c:barChart>.*?</c:barChart>", x, perl = TRUE))
  if (!length(bc) || is.na(bc)) return(invisible(wb))
  ser1 <- regmatches(bc, regexpr("(?s)<c:ser>.*?</c:ser>", bc, perl = TRUE))
  nser1 <- sub("(?s)(</c:tx>(<c:spPr>.*?</c:spPr>)?)", paste0("\\1", dpt), ser1, perl = TRUE)
  x <- sub(ser1, nser1, x, fixed = TRUE)
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Mueve la serie de PUNTOS (lineChart) del último chart a un EJE SECUNDARIO
#   (valor derecho visible + eje de categoría secundario oculto). Para combos
#   columna+punto con escalas muy distintas (p. ej. área cosechada vs rendimiento).
.point_to_secondary <- function(wb, point_axis_fmt = "0.00") {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  bar_ax <- regmatches(x, regexpr("<c:barChart>.*?</c:barChart>", x))
  bids <- gsub("\\D", "", regmatches(bar_ax, gregexpr('<c:axId val="(\\d+)"/>', bar_ax))[[1]])
  catA <- bids[1]; valB <- bids[2]; secC <- "900000021"; secD <- "900000022"
  lc <- regmatches(x, regexpr("(?s)<c:lineChart>.*?</c:lineChart>", x, perl = TRUE))
  nlc <- sub(sprintf('<c:axId val="%s"/><c:axId val="%s"/>', catA, valB),
             sprintf('<c:axId val="%s"/><c:axId val="%s"/>', secD, secC), lc, fixed = TRUE)
  x <- sub(lc, nlc, x, fixed = TRUE)
  axC <- sprintf(paste0(
    '<c:valAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/>',
    '<c:axPos val="r"/><c:numFmt formatCode="%s" sourceLinked="0"/><c:majorTickMark val="out"/>',
    '<c:minorTickMark val="none"/><c:tickLblPos val="nextTo"/><c:crossAx val="%s"/><c:crosses val="max"/>',
    '<c:crossBetween val="between"/></c:valAx>'), secC, point_axis_fmt, secD)
  axD <- sprintf(paste0(
    '<c:catAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="1"/>',
    '<c:axPos val="b"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/><c:tickLblPos val="none"/>',
    '<c:crossAx val="%s"/><c:crosses val="autoZero"/><c:auto val="1"/><c:lblAlgn val="ctr"/>',
    '<c:lblOffset val="100"/><c:noMultiLvlLbl val="0"/></c:catAx>'), secD, secC)
  x <- sub('</c:plotArea>', paste0(axC, axD, '</c:plotArea>'), x, fixed = TRUE)
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Series de barra con RELLENO BLANCO + CONTORNO de color (para >3 series y
#   mantener la paleta): reemplaza el spPr de las series 'idxs' del último chart.
.outline_series_last <- function(wb, idxs, colors) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  bc <- regmatches(x, regexpr("(?s)<c:barChart>.*?</c:barChart>", x, perl = TRUE))
  sers <- regmatches(bc, gregexpr("(?s)<c:ser>.*?</c:ser>", bc, perl = TRUE))[[1]]
  for (j in idxs) {
    if (j > length(sers)) next
    col <- toupper(sub("^#", "", colors[((j - 1) %% length(colors)) + 1]))
    newsp <- sprintf(paste0('<c:spPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>',
                            '<a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:ln></c:spPr>'), col)
    ns <- sub("(?s)<c:spPr>.*?</c:spPr>", newsp, sers[j], perl = TRUE)
    x <- sub(sers[j], ns, x, fixed = TRUE)
  }
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Tabla WIDE tipo heatmap por años (p. ej. mortalidad infantil): pivotea la
#   hoja larga (municipio/agregado × año → tasa) a ancha (Municipio + una columna
#   por año) y aplica relleno por TERCILES dinámicos de los valores > 0:
#   alto = #1F3864 (texto blanco), medio = #4472C4 (negro), bajo = #9DC3E6 (negro),
#   cero/NA = blanco. Terciles = 3 rangos de igual ancho entre min(>0) y max.
.heatmap_anios <- function(wb, sheet, val_key, num_fmt = "0.0") {
  d <- openxlsx2::wb_to_df(wb, sheet)
  muncol <- pick_name(d, "municipio"); yrcol <- pick_name(d, "ano"); vcol <- pick_name(d, val_key)
  dane <- tryCatch(pick_name(d, "codigo dane"), error = function(e) NA_character_)
  d[[yrcol]] <- suppressWarnings(as.numeric(d[[yrcol]]))
  d[[vcol]]  <- suppressWarnings(as.numeric(d[[vcol]]))
  yrs <- sort(unique(d[[yrcol]][!is.na(d[[yrcol]])]))
  is_agg <- if (!is.na(dane)) is.na(d[[dane]]) | trimws(as.character(d[[dane]])) == "" else
              grepl("^(PROMEDIO|TOTAL|SUBREGI|DEPARTAMENTO|PROVINCIA)", d[[muncol]], ignore.case = TRUE)
  ent <- c(unique(d[[muncol]][!is_agg]), unique(d[[muncol]][is_agg]))
  short <- function(nm) { n <- .norm(nm)
    if (grepl("provincia", n)) "Provincia" else if (grepl("subregi", n)) "Subregión"
    else if (grepl("departamento", n)) "Departamento" else nm }
  wide <- data.frame(Municipio = vapply(ent, short, ""), check.names = FALSE)
  for (y in yrs) wide[[as.character(y)]] <- vapply(ent, function(e) {
    v <- d[[vcol]][d[[muncol]] == e & d[[yrcol]] == y]; if (length(v)) v[1] else NA_real_ }, 0)
  wb <- .hoja_reescribir(wb, sheet, wide)
  vals <- unlist(wide[, -1, drop = FALSE], use.names = FALSE); vals <- vals[is.finite(vals) & vals > 0]
  lo <- min(vals); hi <- max(vals); wdt <- (hi - lo) / 3; t1 <- lo + wdt; t2 <- lo + 2 * wdt
  m <- ncol(wide); n <- nrow(wide); last <- n + 1
  wb <- openxlsx2::wb_add_border(wb, sheet, dims = openxlsx2::wb_dims(rows = 1:last, cols = 1:m),
          inner_hgrid = "thin", inner_vgrid = "thin",
          inner_hcolor = openxlsx2::wb_color(hex = "FFBFBFBF"), inner_vcolor = openxlsx2::wb_color(hex = "FFBFBFBF"))
  hdr <- openxlsx2::wb_dims(rows = 1, cols = 1:m)
  wb <- openxlsx2::wb_add_fill(wb, sheet, dims = hdr, color = openxlsx2::wb_color(hex = "FF1F3864"))
  wb <- openxlsx2::wb_add_font(wb, sheet, dims = hdr, name = tema$fuente, color = openxlsx2::wb_color(hex = "FFFFFFFF"), bold = TRUE)
  wb <- openxlsx2::wb_add_cell_style(wb, sheet, dims = hdr, horizontal = "center", vertical = "center")
  for (i in seq_len(n)) for (j in 2:m) {
    v <- suppressWarnings(as.numeric(wide[i, j])); cell <- openxlsx2::wb_dims(rows = i + 1, cols = j)
    if (is.na(v) || v == 0) { fill <- "FFFFFF"; txt <- "000000" }
    else if (v <= t1) { fill <- "9DC3E6"; txt <- "000000" }   # bajo
    else if (v <= t2) { fill <- "4472C4"; txt <- "000000" }   # medio
    else              { fill <- "1F3864"; txt <- "FFFFFF" }   # alto
    wb <- openxlsx2::wb_add_fill(wb, sheet, dims = cell, color = openxlsx2::wb_color(hex = paste0("FF", fill)))
    wb <- openxlsx2::wb_add_font(wb, sheet, dims = cell, name = tema$fuente, color = openxlsx2::wb_color(hex = paste0("FF", txt)))
    wb <- openxlsx2::wb_add_numfmt(wb, sheet, dims = cell, numfmt = num_fmt)
    wb <- openxlsx2::wb_add_cell_style(wb, sheet, dims = cell, horizontal = "center")
  }
  wb$set_col_widths(sheet, cols = 1:m, widths = "auto")
  invisible(wb)
}
# --- Consolidar hojas ECV: colapsa cada par "<X> (municipal)" / "<X> (agregado)"
#   en una sola columna "<X>": municipios toman el valor municipal, filas de
#   agregado (DANE vacío) toman el agregado. Deja tabla y gráficos coherentes.
.consolidar_ecv <- function(wb, sheet) {
  d <- openxlsx2::wb_to_df(wb, sheet = sheet)
  bases <- unique(sub("\\s*\\(municipal\\)$", "", grep("\\(municipal\\)$", names(d), value = TRUE)))
  for (base in bases) {
    mc <- paste0(base, " (municipal)"); ac <- paste0(base, " (agregado)")
    if (mc %in% names(d)) {
      m <- suppressWarnings(as.numeric(d[[mc]]))
      a <- if (ac %in% names(d)) suppressWarnings(as.numeric(d[[ac]])) else NA
      d[[mc]] <- ifelse(!is.na(m), m, a)
      names(d)[names(d) == mc] <- base
      if (ac %in% names(d)) d[[ac]] <- NULL
    }
  }
  .hoja_reescribir(wb, sheet, d)
  invisible(wb)
}
# --- Líneas de referencia HORIZONTALES de ancho completo en un gráfico de
#   COLUMNAS (truco scatter transpuesto): scatter xVal=(0,1) en eje inferior
#   secundario 0..1, yVal=(val,val) en eje derecho secundario 0..vmax alineado
#   con el eje de valores primario (fijado a 0..vmax). Líneas punteadas, en
#   leyenda. Evita que la línea se quede corta (a centros de categoría).
.add_href_scatter <- function(wb, aux_name, ref_lines, vmax, start_col) {
  nref <- length(ref_lines); if (!nref) return(invisible(wb))
  amax <- as.character(round(vmax, 6))
  cX <- start_col
  wb <- openxlsx2::wb_add_data(wb, aux_name, data.frame(X = c(0, 1)), start_col = cX, start_row = 1)
  for (k in seq_len(nref))
    wb <- openxlsx2::wb_add_data(wb, aux_name,
      setNames(data.frame(c(ref_lines[[k]]$value, ref_lines[[k]]$value)), .or(ref_lines[[k]]$label, paste0("Ref", k))),
      start_col = cX + k, start_row = 1)
  i <- nrow(wb$charts); x <- wb$charts$chart[i]
  bar_ax <- regmatches(x, regexpr("<c:barChart>.*?</c:barChart>", x))
  ids <- gsub("\\D", "", regmatches(bar_ax, gregexpr('<c:axId val="(\\d+)"/>', bar_ax))[[1]])
  valId <- ids[2]
  secX <- "900000011"; secY <- "900000012"
  x <- .set_scale(x, valId, vmin = 0, vmax = amax)   # eje de valores primario fijo 0..vmax
  sers <- ""
  for (k in seq_len(nref)) {
    refc <- openxlsx2::int2col(cX + k); col <- toupper(sub("^#", "", ref_lines[[k]]$color))
    sers <- paste0(sers, sprintf(paste0(
      '<c:ser><c:idx val="%d"/><c:order val="%d"/>',
      '<c:tx><c:strRef><c:f>\'%s\'!$%s$1</c:f></c:strRef></c:tx>',
      '<c:spPr><a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill><a:prstDash val="sysDash"/></a:ln></c:spPr>',
      '<c:marker><c:symbol val="none"/></c:marker>',
      '<c:xVal><c:numRef><c:f>\'%s\'!$%s$2:$%s$3</c:f></c:numRef></c:xVal>',
      '<c:yVal><c:numRef><c:f>\'%s\'!$%s$2:$%s$3</c:f></c:numRef></c:yVal>',
      '<c:smooth val="0"/></c:ser>'),
      100 + k, 100 + k, aux_name, refc, col,
      aux_name, openxlsx2::int2col(cX), openxlsx2::int2col(cX), aux_name, refc, refc))
  }
  scatter <- paste0('<c:scatterChart><c:scatterStyle val="lineMarker"/><c:varyColors val="0"/>', sers,
                    sprintf('<c:axId val="%s"/><c:axId val="%s"/></c:scatterChart>', secX, secY))
  x <- sub('<c:catAx>', paste0(scatter, '<c:catAx>'), x, fixed = TRUE)
  axX <- sprintf(paste0(
    '<c:valAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/><c:max val="1"/><c:min val="0"/></c:scaling>',
    '<c:delete val="1"/><c:axPos val="b"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/>',
    '<c:tickLblPos val="none"/><c:crossAx val="%s"/><c:crosses val="autoZero"/><c:crossBetween val="midCat"/></c:valAx>'),
    secX, secY)
  axY <- sprintf(paste0(
    '<c:valAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/><c:max val="%s"/><c:min val="0"/></c:scaling>',
    '<c:delete val="1"/><c:axPos val="r"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/>',
    '<c:tickLblPos val="none"/><c:crossAx val="%s"/><c:crosses val="max"/><c:crossBetween val="midCat"/></c:valAx>'),
    secY, amax, secX)
  x <- sub('</c:plotArea>', paste0(axX, axY, '</c:plotArea>'), x, fixed = TRUE)
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Fija minorTickMark=none en todos los ejes (cat/val) del último chart
#   (radares: visual más limpia). Reemplaza el existente, o lo inserta justo
#   antes de <c:tickLblPos> (posición válida por esquema OOXML) si falta.
.set_minor_ticks_none <- function(wb) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  fix_block <- function(b) {
    if (grepl("<c:minorTickMark", b, fixed = TRUE))
      gsub('<c:minorTickMark val="[^"]*"/>', '<c:minorTickMark val="none"/>', b)
    else
      sub("<c:tickLblPos", '<c:minorTickMark val="none"/><c:tickLblPos', b, fixed = TRUE)
  }
  for (tag in c("catAx", "valAx")) {
    pat <- sprintf("(?s)<c:%s>.*?</c:%s>", tag, tag)
    blks <- regmatches(x, gregexpr(pat, x, perl = TRUE))[[1]]
    for (b in blks) x <- sub(b, fix_block(b), x, fixed = TRUE)
  }
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Estandariza la apariencia de las series del radar (último chart) por su
#   orden: línea de color sólido, marcador circular con RELLENO BLANCO y contorno
#   del color de la serie. dashes[j] (p.ej "sysDash") -> línea punteada. Fuerza
#   el color por srgbClr para que Excel no re-coloree con el tema (naranja).
.style_radar <- function(wb, colors, dashes = NULL, marker_symbol = "circle", marker_size = 10) {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  rc <- regmatches(x, regexpr("(?s)<c:radarChart>.*?</c:radarChart>", x, perl = TRUE))
  if (!length(rc) || is.na(rc)) return(invisible(wb))
  sers <- regmatches(rc, gregexpr("(?s)<c:ser>.*?</c:ser>", rc, perl = TRUE))[[1]]
  ns <- length(sers)
  if (is.null(dashes)) dashes <- c("", rep("sysDash", max(0, ns - 1)))  # 1a sólida, resto punteadas
  for (j in seq_along(sers)) {
    b <- sers[j]
    cc <- toupper(sub("^#", "", colors[((j - 1) %% length(colors)) + 1]))
    dsh <- if (j <= length(dashes) && nzchar(dashes[j])) sprintf('<a:prstDash val="%s"/>', dashes[j]) else ""
    line_sp <- sprintf('<c:spPr><a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill>%s</a:ln></c:spPr>', cc, dsh)
    # radar: marcador círculo tamaño 10 (caso propio; el default diamante/15 es
    # para series de punto de otras secciones).
    mk <- sprintf(paste0('<c:marker><c:symbol val="%s"/><c:size val="%d"/>',
                         '<c:spPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>',
                         '<a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:ln></c:spPr></c:marker>'),
                  marker_symbol, marker_size, cc)
    # limpiar marker (con su spPr interno) y TODOS los spPr de la serie —incluido
    # el <c:spPr/> vacío que emite encharter tras el marker, que viola el orden de
    # esquema (spPr debe ir ANTES de marker) y hace que Excel "repare" el dibujo—.
    # Luego reinsertar spPr+marker en orden correcto (justo tras </c:tx>).
    nb <- gsub("(?s)<c:marker>.*?</c:marker>", "", b, perl = TRUE)
    nb <- gsub("(?s)<c:spPr>.*?</c:spPr>", "", nb, perl = TRUE)
    nb <- gsub("<c:spPr/>", "", nb, fixed = TRUE)
    nb <- sub("(?s)(</c:tx>)", paste0("\\1", line_sp, mk), nb, perl = TRUE)
    x <- sub(b, nb, x, fixed = TRUE)
  }
  wb$charts$chart[i] <- x
  invisible(wb)
}
# --- Inyecta <c:max>/<c:min> en el <c:scaling> del eje 'axId'.
.set_scale <- function(x, axId, vmin = NULL, vmax = NULL) {
  pat <- sprintf('(<c:valAx><c:axId val="%s"/><c:scaling>)(<c:orientation val="minMax"/>)', axId)
  ins <- ""
  if (!is.null(vmax)) ins <- paste0(ins, sprintf('<c:max val="%s"/>', vmax))
  if (!is.null(vmin)) ins <- paste0(ins, sprintf('<c:min val="%s"/>', vmin))
  sub(pat, paste0("\\1\\2", ins), x, perl = TRUE)
}

# ----------------------------------------------------------------------------
# .add_ref_scatter: líneas de referencia VERTICALES en una barra horizontal,
#   con el truco nativo "Scatter with Straight Lines" (validado en Excel).
#   La barra queda intacta; se añade un scatterChart (una serie por agregado):
#   xVal = valor constante del agregado, yVal = (0,1); ejes secundarios propios
#   (derecho max=1 -> altura completa; inferior con la MISMA escala 0..máx que
#   el eje de valores de las barras -> alineación horizontal exacta). El eje de
#   valores primario queda delete=1; se quitan las líneas guía. Sin combos
#   barra+línea (que corrompen el .xlsx).
#   ref_lines: list(list(value=, color=, label=), ...)  (1..N líneas)
# ----------------------------------------------------------------------------
.add_ref_scatter <- function(wb, aux_name, ref_lines, nv, data_vals) {
  nref <- length(ref_lines)
  vmax <- max(c(as.numeric(unlist(data_vals)),
                vapply(ref_lines, function(r) as.numeric(r$value), 0)), na.rm = TRUE)
  if (!is.finite(vmax) || vmax <= 0) vmax <- 1
  mag <- 10^floor(log10(vmax)); axis_max <- round(ceiling(vmax / (mag / 2)) * (mag / 2), 6)
  amax <- as.character(axis_max)
  # celdas auxiliares en la hoja oculta: Y=(0,1) y una X=(refval,refval) por línea
  cY <- nv + 3                       # (cat + nv valores) + 1 col de separación
  wb <- openxlsx2::wb_add_data(wb, aux_name, data.frame(Y = c(0, 1)),
                               start_col = cY, start_row = 1)
  for (k in seq_len(nref)) {
    wb <- openxlsx2::wb_add_data(wb, aux_name,
      setNames(data.frame(c(ref_lines[[k]]$value, ref_lines[[k]]$value)),
               .or(ref_lines[[k]]$label, paste0("Ref", k))),
      start_col = cY + k, start_row = 1)
  }
  # --- cirugía XML del último chart ---
  i <- nrow(wb$charts); x <- wb$charts$chart[i]
  bar_ax <- regmatches(x, regexpr("<c:barChart>.*?</c:barChart>", x))
  ids <- gsub("\\D", "", regmatches(bar_ax, gregexpr('<c:axId val="(\\d+)"/>', bar_ax))[[1]])
  valId <- ids[2]
  secB <- "900000001"; secR <- "900000002"
  # normalizar axPos al esquema probado (catAx=l, valAx=b)
  x <- sub('(<c:catAx>.*?)<c:axPos val="b"/>', '\\1<c:axPos val="__L__"/>', x, perl = TRUE)
  x <- sub('(<c:valAx>.*?)<c:axPos val="l"/>',  '\\1<c:axPos val="b"/>',    x, perl = TRUE)
  x <- gsub('<c:axPos val="__L__"/>', '<c:axPos val="l"/>', x)
  # eje de valores primario: ocultar (delete=1) y fijar escala 0..axis_max
  x <- sub('(<c:valAx>.*?)<c:delete val="0"/>', '\\1<c:delete val="1"/>', x, perl = TRUE)
  x <- .set_scale(x, valId, vmin = 0, vmax = amax)
  # sin líneas guía
  x <- .strip_gridlines_str(x)
  # scatterChart: una serie de línea recta punteada por agregado
  sers <- ""
  for (k in seq_len(nref)) {
    ref <- openxlsx2::int2col(cY + k)
    col <- toupper(sub("^#", "", ref_lines[[k]]$color))
    sers <- paste0(sers, sprintf(paste0(
      '<c:ser><c:idx val="%d"/><c:order val="%d"/>',
      '<c:tx><c:strRef><c:f>\'%s\'!$%s$1</c:f></c:strRef></c:tx>',
      '<c:spPr><a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill>',
      '<a:prstDash val="sysDash"/></a:ln></c:spPr>',
      '<c:marker><c:symbol val="none"/></c:marker>',
      '<c:xVal><c:numRef><c:f>\'%s\'!$%s$2:$%s$3</c:f></c:numRef></c:xVal>',
      '<c:yVal><c:numRef><c:f>\'%s\'!$%s$2:$%s$3</c:f></c:numRef></c:yVal>',
      '<c:smooth val="0"/></c:ser>'),
      nv + k - 1, nv + k - 1, aux_name, ref, col,
      aux_name, ref, ref, aux_name, openxlsx2::int2col(cY), openxlsx2::int2col(cY)))
  }
  scatter <- paste0('<c:scatterChart><c:scatterStyle val="lineMarker"/><c:varyColors val="0"/>',
                    sers,
                    sprintf('<c:axId val="%s"/><c:axId val="%s"/></c:scatterChart>', secB, secR))
  x <- sub('<c:catAx>', paste0(scatter, '<c:catAx>'), x, fixed = TRUE)
  # ejes secundarios: derecho (0..1 oculto, altura completa) e inferior (0..máx oculto)
  axR <- sprintf(paste0(
    '<c:valAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/>',
    '<c:max val="1"/><c:min val="0"/></c:scaling><c:delete val="1"/><c:axPos val="r"/>',
    '<c:majorTickMark val="none"/><c:minorTickMark val="none"/><c:tickLblPos val="none"/>',
    '<c:crossAx val="%s"/><c:crosses val="max"/><c:crossBetween val="midCat"/></c:valAx>'),
    secR, secB)
  axB <- sprintf(paste0(
    '<c:valAx><c:axId val="%s"/><c:scaling><c:orientation val="minMax"/>',
    '<c:max val="%s"/><c:min val="0"/></c:scaling><c:delete val="1"/><c:axPos val="b"/>',
    '<c:majorTickMark val="none"/><c:minorTickMark val="none"/><c:tickLblPos val="none"/>',
    '<c:crossAx val="%s"/><c:crosses val="autoZero"/><c:crossBetween val="midCat"/></c:valAx>'),
    secB, amax, secR)
  x <- sub('</c:plotArea>', paste0(axR, axB, '</c:plotArea>'), x, fixed = TRUE)
  wb$charts$chart[i] <- x
  invisible(wb)
}
enc_hbar <- function(wb, target_sheet, anchor, aux_name, data,
                     cat_col, value_cols, colors, titulo,
                     grouping = "standard", label_series = 1, num_fmt = "0.0",
                     legend = NULL, sort = TRUE, sort_desc = TRUE,
                     value_axis = FALSE, label_color = NULL, ref_lines = NULL,
                     agg_bar = NULL, outline_series = integer(0),
                     no_legend = FALSE, label_colors = NULL) {
  if (isTRUE(sort)) {  # asc en la tabla -> mayor arriba en barra horizontal
    ord <- order(data[[value_cols[1]]], decreasing = !sort_desc)
    data <- data[ord, , drop = FALSE]
  }
  data <- data[, c(cat_col, value_cols), drop = FALSE]
  if (!is.null(agg_bar)) {                       # barra de agregado (p.ej. Provincia)
    arow <- data[1, , drop = FALSE]; arow[] <- NA
    arow[[cat_col]] <- agg_bar$label; arow[[value_cols[1]]] <- agg_bar$value
    data <- rbind(data, arow)
  }
  nv <- length(value_cols)
  # descartar líneas de referencia sin dato (agregado inexistente en la hoja):
  # evita series vacías que aparecerían en la leyenda pero no en el gráfico.
  if (length(ref_lines))
    ref_lines <- Filter(function(r) is.finite(suppressWarnings(as.numeric(r$value))), ref_lines)
  nref <- length(ref_lines)
  .hoja_aux(wb, aux_name, data)
  n <- nrow(data); r1 <- 2; r2 <- n + 1
  stacked <- grouping %in% c("stacked", "percentStacked")
  # formato por columna: las series en label_series muestran etiqueta (num_fmt);
  # las demás se ocultan (";;;") -> así label_series controla qué serie lleva etiqueta
  for (j in seq_len(nv)) {
    wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
            dims = openxlsx2::wb_dims(rows = r1:r2, cols = 1 + j),
            numfmt = if (j %in% label_series) num_fmt else ";;;")
  }
  ch <- encharter::encharter("barChart")
  for (j in seq_len(nv)) {
    ch$add_series(
      name  = .ref(aux_name, 1 + j, 1), data = .ref(aux_name, 1 + j, r1, r2),
      label = .ref(aux_name, 1, r1, r2),
      color = colors[((j - 1) %% length(colors)) + 1], dir = "bar", grouping = grouping,
      overlap = if (stacked) 100 else NULL, show_val = j %in% label_series)
  }
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_data_label_style(show_val = TRUE, pos = if (stacked) "ctr" else "outEnd",
                          format = num_fmt, color = label_color)
  if (!value_axis) ch$set_y_axis(grid_lines = FALSE, label_pos = "none", major_tick = "none", line_width = 0)
  else ch$set_y_axis(format = num_fmt, grid_lines = FALSE)
  # los gráficos barra + línea(s) de referencia llevan leyenda por defecto (para
  # identificar la serie de barra y cada agregado), salvo no_legend explícito.
  if (isTRUE(no_legend)) legend <- FALSE
  else if (nref > 0) legend <- TRUE
  else if (is.null(legend)) legend <- (nv > 1)
  ch$set_legend_style(pos = if (legend) "b" else "none")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  if (nref) {
    # líneas de referencia verticales con el truco scatter (nativo, sin combos)
    wb <- .add_ref_scatter(wb, aux_name, ref_lines, nv = nv,
                           data_vals = data[, value_cols, drop = FALSE])
  } else {
    if (!value_axis) wb <- .del_valax(wb) # elimina el eje de valores (no solo etiquetas)
    wb <- .del_gridlines_last(wb)         # sin líneas guía (consistente en todo el catálogo)
  }
  if (!is.null(agg_bar) && !is.null(agg_bar$color))
    wb <- .recolor_bar_last(wb, idx = n - 1, color = agg_bar$color)  # barra agregado resaltada
  if (length(outline_series))
    wb <- .outline_series_last(wb, outline_series, colors)           # series contorno + relleno blanco
  if (!is.null(label_colors))
    wb <- .set_series_label_colors(wb, label_colors, num_fmt, pos = if (stacked) "ctr" else "outEnd")
  invisible(wb)
}
# --- Color de etiqueta de dato POR SERIE (p. ej. apiladas con contraste por
#   segmento). Inyecta un <c:dLbls> propio en cada serie de barra con su txPr.
.set_series_label_colors <- function(wb, label_colors, num_fmt, pos = "ctr") {
  i <- nrow(wb$charts); if (is.null(i) || i < 1) return(invisible(wb))
  x <- wb$charts$chart[i]
  bc <- regmatches(x, regexpr("(?s)<c:barChart>.*?</c:barChart>", x, perl = TRUE))
  sers <- regmatches(bc, gregexpr("(?s)<c:ser>.*?</c:ser>", bc, perl = TRUE))[[1]]
  for (j in seq_along(sers)) {
    if (j > length(label_colors) || is.na(label_colors[j])) next
    col <- toupper(sub("^#", "", label_colors[j]))
    dl <- sprintf(paste0('<c:dLbls><c:numFmt formatCode="%s" sourceLinked="0"/>',
                  '<c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr>',
                  '<c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr>',
                  '<a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:defRPr></a:pPr><a:endParaRPr lang="es"/></a:p></c:txPr>',
                  '<c:dLblPos val="%s"/><c:showLegendKey val="0"/><c:showVal val="1"/><c:showCatName val="0"/>',
                  '<c:showSerName val="0"/><c:showPercent val="0"/><c:showBubbleSize val="0"/></c:dLbls>'), num_fmt, col, pos)
    s <- sers[j]
    ns <- if (grepl("<c:dLbls>", s, fixed = TRUE)) sub("(?s)<c:dLbls>.*?</c:dLbls>", dl, s, perl = TRUE)
          else sub("(?s)(<c:cat>)", paste0(dl, "\\1"), s, perl = TRUE)
    x <- sub(s, ns, x, fixed = TRUE)
  }
  wb$charts$chart[i] <- x
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_piramide: pirámide poblacional nativa (barras horizontales apiladas,
#   hombres en negativo -> izquierda, mujeres positivo -> derecha).
#   bandas: vector de etiquetas de edad (orden ascendente: "0 a 9" ... "80 o más")
# ----------------------------------------------------------------------------
enc_piramide <- function(wb, target_sheet, anchor, aux_name, bandas, hombres, mujeres,
                         titulo, col_h, col_m, num_fmt = "#,##0", labels = FALSE) {
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
                dir = "bar", grouping = "stacked", overlap = 100, show_val = labels)
  ch$add_series(name = .ref(aux_name, 3, 1), data = .ref(aux_name, 3, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = col_m,
                dir = "bar", grouping = "stacked", overlap = 100, show_val = labels)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  if (labels) ch$set_data_label_style(show_val = TRUE, pos = "inEnd", format = fmt)
  maxv  <- max(abs(c(as.numeric(hombres), as.numeric(mujeres))), na.rm = TRUE)
  bound <- ceiling(maxv / 2000) * 2000
  ch$set_y_axis(min = -bound, max = bound, major = bound / 3, format = fmt)  # eje de valores
  ch$set_x_axis(font_color = "FFFFFF")  # etiquetas de banda de edad en blanco (sobre las barras)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  wb <- .fix_invert_negativos(wb)   # hombres navy en Excel (no blancos)
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
                     legend = TRUE, markers = TRUE, show_val = FALSE,
                     value_axis = TRUE, grid = TRUE, label_pos = "t") {
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
                  marker = if (markers) "circle" else "none", marker_size = 5, show_val = show_val)
  }
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  if (show_val) ch$set_data_label_style(show_val = TRUE, pos = label_pos, format = num_fmt)
  if (value_axis) ch$set_y_axis(format = num_fmt, grid_lines = grid)
  else ch$set_y_axis(grid_lines = FALSE, label_pos = "none", major_tick = "none", line_width = 0)
  if (legend) ch$set_legend_style(pos = "b") else ch$set_legend_style(pos = "none")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  if (!value_axis) {
    i <- nrow(wb$charts); x <- wb$charts$chart[i]
    x <- sub("(<c:valAx>.*?)<c:delete val=\"0\"/>", "\\1<c:delete val=\"1\"/>", x, perl = TRUE)
    wb$charts$chart[i] <- x
  }
  if (!grid) wb <- .del_gridlines_last(wb)
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
                color = color, marker = tema$marker_symbol, marker_size = tema$marker_size, show_line = FALSE)
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
                marker = tema$marker_symbol, marker_size = tema$marker_size, show_line = FALSE)
  ch$add_series(name = .ref(aux_name, 3, 1), data = .ref(aux_name, 3, r1, r2),
                label = .ref(aux_name, 1, r1, r2), color = colors[2],
                marker = tema$marker_symbol, marker_size = tema$marker_size, show_line = FALSE)
  ch$high_low_lines <- TRUE
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_col_point: columnas verticales (1+ series) + (opcional) serie de PUNTOS
#   (marcador diamante/círculo, relleno blanco, contorno de color) + (opcional)
#   líneas de referencia HORIZONTALES punteadas + (opcional) barra de agregado
#   (p.ej. Provincia) resaltada por color. Combo nativo columna+línea (seguro).
#   bar_cols/bar_colors: columnas y colores. point_col: serie de puntos (o NULL).
#   agg_bar: list(label=, values=c(por bar_col), color=NULL) -> barra extra.
#   ref_lines: list(list(value=, color=, label=), ...) -> líneas horizontales.
# ----------------------------------------------------------------------------
enc_col_point <- function(wb, target_sheet, anchor, aux_name, data, cat_col,
                          bar_cols, bar_colors, point_col = NULL, titulo, num_fmt = "0.0",
                          point_name = NULL, point_outline = tema$light, point_fill = "FFFFFF",
                          point_symbol = tema$marker_symbol, point_size = tema$marker_size,
                          point_labels = TRUE, bar_labels = FALSE,
                          label_pos = "t", label_color = NULL,
                          sort = FALSE, sort_col = NULL, agg_bar = NULL, ref_lines = NULL,
                          legend = TRUE, point_secondary = FALSE, point_axis_fmt = "0.00") {
  nb <- length(bar_cols); pt <- !is.null(point_col)
  cols <- c(cat_col, bar_cols, if (pt) point_col)
  d <- data[, cols, drop = FALSE]
  if (isTRUE(sort)) {
    sc <- if (!is.null(sort_col)) sort_col else bar_cols[1]
    d <- d[order(d[[sc]], decreasing = TRUE), , drop = FALSE]
  }
  if (!is.null(agg_bar)) {                       # barra de agregado al final
    row <- setNames(vector("list", ncol(d)), names(d)); row[[cat_col]] <- agg_bar$label
    for (j in seq_len(nb)) row[[bar_cols[j]]] <- agg_bar$values[j]
    if (pt) row[[point_col]] <- if (!is.null(agg_bar$point)) agg_bar$point else NA
    d <- rbind(d, as.data.frame(row, check.names = FALSE))
  }
  if (length(ref_lines))
    ref_lines <- Filter(function(r) is.finite(suppressWarnings(as.numeric(r$value))), ref_lines)
  if (!is.null(point_name) && pt) names(d)[names(d) == point_col] <- point_name
  n <- nrow(d); r1 <- 2; r2 <- n + 1
  nref <- length(ref_lines)
  aux_df <- d
  .hoja_aux(wb, aux_name, aux_df)
  ncoldata <- 1 + nb + (if (pt) 1 else 0)
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
          dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:ncoldata), numfmt = num_fmt)
  ch <- encharter::encharter("barChart")
  for (j in seq_len(nb))
    ch$add_series(name = .ref(aux_name, 1 + j, 1), data = .ref(aux_name, 1 + j, r1, r2),
                  label = .ref(aux_name, 1, r1, r2), color = bar_colors[j],
                  dir = "col", grouping = "clustered", show_val = bar_labels)
  if (pt)
    ch$add_series(name = .ref(aux_name, 1 + nb + 1, 1), data = .ref(aux_name, 1 + nb + 1, r1, r2),
                  label = .ref(aux_name, 1, r1, r2), type = "lineChart", color = point_outline,
                  marker = point_symbol, marker_size = point_size,
                  marker_fill = point_fill, marker_line = point_outline,
                  show_line = FALSE, show_val = point_labels)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_legend_style(pos = if (legend) "b" else "none")
  ch$set_y_axis(grid_lines = FALSE)
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  wb <- .del_gridlines_last(wb)
  i <- nrow(wb$charts); x <- wb$charts$chart[i]
  # --- serie de PUNTOS: marcador exacto (+ etiqueta) ---
  if (pt) {
    lc <- regmatches(x, regexpr("(?s)<c:lineChart>.*?</c:lineChart>", x, perl = TRUE))
    ser <- regmatches(lc, regexpr("(?s)<c:ser>.*?</c:ser>", lc, perl = TRUE))  # 1a = puntos
    if (length(ser) && nzchar(ser)) {
      col <- toupper(sub("^#", "", point_outline)); fil <- toupper(sub("^#", "", point_fill))
      mk <- sprintf(paste0('<c:marker><c:symbol val="%s"/><c:size val="%d"/>',
                           '<c:spPr><a:solidFill><a:srgbClr val="%s"/></a:solidFill>',
                           '<a:ln w="19050"><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:ln></c:spPr></c:marker>'),
                    point_symbol, point_size, fil, col)
      nser <- if (grepl("<c:marker>", ser, fixed = TRUE))
        sub("(?s)<c:marker>.*?</c:marker>", mk, ser, perl = TRUE)
      else sub("(?s)(</c:tx>)", paste0("\\1", mk), ser, perl = TRUE)
      if (point_labels) {
        txpr <- if (!is.null(label_color))
          sprintf(paste0('<c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr>',
                         '<a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:defRPr></a:pPr>',
                         '<a:endParaRPr lang="es"/></a:p></c:txPr>'),
                  toupper(sub("^#", "", label_color))) else ""
        dlbls <- sprintf(paste0(
          '<c:dLbls><c:numFmt formatCode="%s" sourceLinked="0"/>',
          '<c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr>%s',
          '<c:dLblPos val="%s"/><c:showLegendKey val="0"/><c:showVal val="1"/>',
          '<c:showCatName val="0"/><c:showSerName val="0"/><c:showPercent val="0"/>',
          '<c:showBubbleSize val="0"/></c:dLbls>'), num_fmt, txpr, label_pos)
        nser <- sub("(?s)(</c:marker>)", paste0("\\1", dlbls), nser, perl = TRUE)
      }
      x <- sub(ser, nser, x, fixed = TRUE)
    }
  }
  # --- etiquetas en las columnas (encharter no las emite para el combo) ---
  if (bar_labels) {
    bdl <- sprintf(paste0('<c:dLbls><c:numFmt formatCode="%s" sourceLinked="0"/>',
                   '<c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr><c:dLblPos val="outEnd"/>',
                   '<c:showLegendKey val="0"/><c:showVal val="1"/><c:showCatName val="0"/>',
                   '<c:showSerName val="0"/><c:showPercent val="0"/><c:showBubbleSize val="0"/></c:dLbls>'), num_fmt)
    bc <- regmatches(x, regexpr("(?s)<c:barChart>.*?</c:barChart>", x, perl = TRUE))
    sers <- regmatches(bc, gregexpr("(?s)<c:ser>.*?</c:ser>", bc, perl = TRUE))[[1]]
    for (s in sers) {
      if (grepl("<c:dLbls>", s, fixed = TRUE)) next
      ns <- sub("(?s)(<c:cat>)", paste0(bdl, "\\1"), s, perl = TRUE)
      x <- sub(s, ns, x, fixed = TRUE)
    }
  }
  # --- barra de agregado resaltada (dPt) si es serie única de barras ---
  if (!is.null(agg_bar) && !is.null(agg_bar$color) && nb == 1) {
    colh <- toupper(sub("^#", "", agg_bar$color)); idx <- n - 1
    dpt <- sprintf(paste0('<c:dPt><c:idx val="%d"/><c:invertIfNegative val="0"/><c:bubble3D val="0"/>',
                          '<c:spPr><a:solidFill><a:srgbClr val="%s"/></a:solidFill></c:spPr></c:dPt>'), idx, colh)
    bc <- regmatches(x, regexpr("(?s)<c:barChart>.*?</c:barChart>", x, perl = TRUE))
    ser1 <- regmatches(bc, regexpr("(?s)<c:ser>.*?</c:ser>", bc, perl = TRUE))
    nser1 <- sub("(?s)(</c:tx>(<c:spPr>.*?</c:spPr>)?)", paste0("\\1", dpt), ser1, perl = TRUE)
    x <- sub(ser1, nser1, x, fixed = TRUE)
  }
  wb$charts$chart[i] <- x
  # --- líneas de referencia horizontales de ancho completo (scatter) ---
  if (nref) {
    vals <- suppressWarnings(as.numeric(unlist(d[, c(bar_cols, if (pt) point_col)], use.names = FALSE)))
    vmax <- max(c(vals, vapply(ref_lines, function(r) as.numeric(r$value), 0)), na.rm = TRUE)
    if (!is.finite(vmax) || vmax <= 0) vmax <- 1
    mag <- 10^floor(log10(vmax)); vmax <- ceiling(vmax / (mag / 2)) * (mag / 2)
    wb <- .add_href_scatter(wb, aux_name, ref_lines, vmax, start_col = ncoldata + 2)
  }
  if (point_secondary && pt) wb <- .point_to_secondary(wb, point_axis_fmt)  # puntos en eje derecho
  invisible(wb)
}

# ----------------------------------------------------------------------------
# enc_hbar_sector: barra horizontal de UNA serie, cada barra coloreada por su
#   SECTOR (dPt), etiquetas de dato a la DERECHA (outEnd), sin eje/guías, y una
#   leyenda de 3 entradas por sector (series "dummy" superpuestas, sin datos, con
#   la entrada de la serie real oculta). Para fig44 (VA por actividad, por sector).
# ----------------------------------------------------------------------------
enc_hbar_sector <- function(wb, target_sheet, anchor, aux_name, cats, values, sectors,
                            sector_levels, sector_colors, titulo, num_fmt = "#,##0.0") {
  # Una columna por sector: valor en la del sector de la actividad, 0 en las otras
  # (superpuestas con overlap=100 -> una sola barra visible por actividad). Las
  # etiquetas ocultan el 0 (formato con sección de cero vacía). Leyenda = sectores.
  d <- data.frame(Actividad = cats, check.names = FALSE)
  for (s in sector_levels) d[[s]] <- ifelse(sectors == s, as.numeric(values), NA_real_)
  .hoja_aux(wb, aux_name, d)
  n <- nrow(d); r1 <- 2; r2 <- n + 1; ns <- length(sector_levels)
  fmt_lbl <- num_fmt
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name, dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:(1 + ns)), numfmt = num_fmt)
  ch <- encharter::encharter("barChart")
  for (j in seq_along(sector_levels))
    ch$add_series(name = .ref(aux_name, 1 + j, 1), data = .ref(aux_name, 1 + j, r1, r2), label = .ref(aux_name, 1, r1, r2),
                  color = sector_colors[[sector_levels[j]]], dir = "bar", grouping = "clustered", overlap = 100, show_val = TRUE)
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_data_label_style(show_val = TRUE, pos = "outEnd", format = fmt_lbl)
  ch$set_y_axis(grid_lines = FALSE, label_pos = "none", major_tick = "none", line_width = 0)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  wb <- .del_valax(wb); wb <- .del_gridlines_last(wb)
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

# ----------------------------------------------------------------------------
# .fix_invert_negativos: fuerza invertIfNegative=0 en las series de BARRAS del
#   workbook (Excel pinta blancas las barras de valor negativo, p. ej. la
#   pirámide). Edita el XML de los gráficos EN MEMORIA (wb$charts$chart),
#   acotado a bloques <c:barChart> (no toca líneas/áreas). Sin dependencias.
# ----------------------------------------------------------------------------
.fix_invert_negativos <- function(wb) {
  ch <- wb$charts
  if (is.null(ch) || !nrow(ch)) return(invisible(wb))
  for (i in seq_len(nrow(ch))) {
    x <- ch$chart[i]
    if (is.na(x) || !nzchar(x) || !grepl("<c:barChart>", x, fixed = TRUE)) next
    blocks <- regmatches(x, gregexpr("<c:barChart>.*?</c:barChart>", x, perl = TRUE))[[1]]
    for (b in blocks) {
      if (grepl("invertIfNegative", b, fixed = TRUE)) next
      nb <- gsub("</c:spPr>", "</c:spPr><c:invertIfNegative val=\"0\"/>", b, fixed = TRUE)
      x <- sub(b, nb, x, fixed = TRUE)
    }
    wb$charts$chart[i] <- x
  }
  invisible(wb)
}

# ----------------------------------------------------------------------------
# agg_valor: valor de una fila de agregado (provincia/subregión/departamento).
#   nivel: "provincia" | "subregi" | "departamento" (insensible a acentos).
# ----------------------------------------------------------------------------
agg_valor <- function(df, col_key, nivel) {
  dane <- tryCatch(pick_name(df, "codigo dane"), error = function(e) NA_character_)
  mun  <- pick_name(df, "municipio")
  agg  <- if (!is.na(dane)) df[is.na(df[[dane]]) | trimws(as.character(df[[dane]])) == "", , drop = FALSE] else df
  row  <- agg[grepl(.norm(nivel), .norm(agg[[mun]])), , drop = FALSE]
  if (!nrow(row)) return(NA_real_)
  suppressWarnings(as.numeric(pick(row, col_key)))[1]
}

# ----------------------------------------------------------------------------
# enc_radar: radar/spider nativo. categorias (dimensiones) + series (lista
#   nombrada name -> vector alineado a categorias). Líneas por serie.
# ----------------------------------------------------------------------------
enc_radar <- function(wb, target_sheet, anchor, aux_name, categorias, series,
                      colors = tema$serie, titulo = "", num_fmt = "0.0", dashes = NULL) {
  df <- data.frame(Dimension = categorias, check.names = FALSE)
  for (nm in names(series)) df[[nm]] <- as.numeric(series[[nm]])
  .hoja_aux(wb, aux_name, df)
  n <- nrow(df); r1 <- 2; r2 <- n + 1; ns <- length(series)
  wb <- openxlsx2::wb_add_numfmt(wb, sheet = aux_name,
          dims = openxlsx2::wb_dims(rows = r1:r2, cols = 2:(1 + ns)), numfmt = num_fmt)
  ch <- encharter::encharter("radarChart")
  ch$palette <- colors[((seq_len(ns) - 1) %% length(colors)) + 1]
  for (j in seq_len(ns)) {
    cj <- colors[((j - 1) %% length(colors)) + 1]
    ch$add_series(name = .ref(aux_name, 1 + j, 1), data = .ref(aux_name, 1 + j, r1, r2),
                  label = .ref(aux_name, 1, r1, r2),
                  color = cj, line_color = cj, line_width = 2,
                  marker = "circle", marker_size = 4, marker_fill = cj, marker_line = cj)
  }
  ch$set_chart_title(titulo, font_size = tema$size_titulo, font_name = tema$fuente, bold = TRUE)
  ch$set_legend_style(pos = "b")
  wb <- openxlsx2::wb_add_encharter(wb, sheet = target_sheet, dims = anchor, graph = ch)
  wb <- .set_minor_ticks_none(wb)   # radar: tick marks menores = none (visual limpia)
  wb <- .style_radar(wb, colors, dashes)  # línea sólida/punteada + marcador relleno blanco
  invisible(wb)
}

# Reescribir una hoja con un data.frame nuevo (para reestructurar tablas).
.hoja_reescribir <- function(wb, sheet, df) {
  if (sheet %in% wb$get_sheet_names()) wb$remove_worksheet(sheet)
  wb$add_worksheet(sheet); wb$add_data(sheet = sheet, x = df, col_names = TRUE)
  invisible(wb)
}
