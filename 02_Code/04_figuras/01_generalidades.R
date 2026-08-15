# =============================================================================
# 01_generalidades.R — Figuras de la Sección 1: Generalidades
#
# FIGURAS:
#   fig_01_distribucion_territorial — área de cada municipio y su participación
#                                     en el territorio provincial
#
# INPUTS:  la tabla que produce 02_Code/03_tablas/01_generalidades.R
# OUTPUTS: 03_Outputs/<Provincia>/01_Generalidades/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

figuras_generalidades <- function(prov, tabla) {
  message("== figuras 01 Generalidades — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "01_Generalidades")

  municipios <- dplyr::filter(tabla, !is.na(ind_mpio))
  n <- nrow(municipios)
  mayor <- municipios[which.max(municipios$participacion_area_prov_pct), ]

  # --- fig 01: participación en el área provincial --------------------------
  p <- fig_barras(
    municipios,
    categoria = municipio,
    valor = participacion_area_prov_pct,
    resaltar = mayor$municipio,
    etiqueta = function(x) pct_co(x * 100, dec = 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s concentra el %s del territorio de la provincia",
        mayor$municipio, pct_co(mayor$participacion_area_prov_pct * 100, dec = 0)
      ),
      subtitulo = sprintf(
        "Participación de cada municipio en los %s km² de la provincia %s",
        num_co(sum(municipios$area_km2, na.rm = TRUE), 0), prov$etiqueta
      ),
      fuente = "Gobernación de Antioquia, Anuario Estadístico. Cálculos propios."
    )

  guardar_fig(p, "fig_01_distribucion_territorial", destino, n_barras = n)

  # Los datos exactos de la figura quedan en el .xlsx de la sección
  escribir_datos_figura(
    municipios[, c("municipio", "area_km2", "participacion_area_prov_pct")],
    file.path(dir_seccion(prov, "01_Generalidades"), "distribucion_territorial.xlsx"),
    "fig_01"
  )

  invisible(destino)
}
