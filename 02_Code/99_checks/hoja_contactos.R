# =============================================================================
# hoja_contactos.R — Contacto visual de todas las figuras de una provincia
#
# Junta en una sola imagen las figuras generadas, para revisarlas de un vistazo
# antes de llevarlas al informe: se ven ahí los problemas que ningún chequeo
# numérico detecta (texto cortado, etiquetas encimadas, ejes ilegibles,
# proporciones raras).
#
# USO:
#   ID_PROVINCIA=2 Rscript 02_Code/99_checks/hoja_contactos.R
#
# SALIDA: 03_Outputs/<Provincia>/_revision/hoja_contactos_NN.png
# ETAPA DEL PIPELINE: verificación
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

#' Arma hojas de contacto con las figuras PNG de una provincia.
#'
#' @param id id de provincia (por defecto, el del entorno).
#' @param por_hoja cuántas figuras entran en cada hoja.
hoja_contactos <- function(id = NULL, por_hoja = 6) {
  for (p in c("png", "grid")) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("Falta el paquete '", p, "'. Instálelo con install.packages(\"", p, "\").",
           call. = FALSE)
    }
  }
  prov <- provincia(id)
  base <- file.path(RUTAS$outputs, prov$carpeta)
  figuras <- list.files(base, pattern = "\\.png$", recursive = TRUE, full.names = TRUE)
  figuras <- figuras[!grepl("/_revision/", figuras)]

  if (!length(figuras)) {
    message("No hay figuras generadas para ", prov$etiqueta,
            ". Corra primero: ID_PROVINCIA=", prov$id, " Rscript 02_Code/run_provincia.R")
    return(invisible(NULL))
  }

  destino <- file.path(base, "_revision")
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  unlink(list.files(destino, pattern = "^hoja_contactos_.*\\.png$", full.names = TRUE))

  grupos <- split(figuras, ceiling(seq_along(figuras) / por_hoja))
  columnas <- 2
  rutas <- character(0)

  for (i in seq_along(grupos)) {
    grupo <- grupos[[i]]
    filas <- ceiling(length(grupo) / columnas)
    ruta <- file.path(destino, sprintf("hoja_contactos_%02d.png", i))

    ragg::agg_png(ruta, width = 2000, height = 380 * filas + 90, res = 130)
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(layout = grid::grid.layout(
      filas + 1, columnas, heights = grid::unit(c(1, rep(4, filas)), "null")
    )))
    grid::grid.text(
      sprintf("%s — revisión de figuras (%d de %d)", prov$etiqueta, i, length(grupos)),
      vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1:columnas),
      gp = grid::gpar(fontsize = 15, fontface = "bold")
    )
    for (j in seq_along(grupo)) {
      fila <- ceiling(j / columnas) + 1
      col <- (j - 1) %% columnas + 1
      img <- png::readPNG(grupo[j])
      grid::pushViewport(grid::viewport(layout.pos.row = fila, layout.pos.col = col))
      grid::grid.raster(img, height = grid::unit(0.86, "npc"), just = "centre")
      grid::grid.text(
        # sección/figura, que es lo que hace falta para ubicarla
        file.path(basename(dirname(dirname(grupo[j]))), basename(grupo[j])),
        y = grid::unit(0.02, "npc"), gp = grid::gpar(fontsize = 8, col = "grey30")
      )
      grid::popViewport()
    }
    grDevices::dev.off()
    rutas <- c(rutas, ruta)
    message("  ", sub(RUTAS$raiz, "", ruta, fixed = TRUE), "  (", length(grupo), " figuras)")
  }

  message("\n", length(figuras), " figuras en ", length(grupos), " hoja(s) de contacto.")
  invisible(rutas)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "hoja_contactos.R") {
  hoja_contactos()
}
