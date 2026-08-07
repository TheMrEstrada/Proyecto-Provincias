# ============================================================================
# fig/02_demografia.R  —  Figuras nativas de la sección Demografía
# Requiere: wb (workbook cargado del export), tema, utils
# ============================================================================
figuras_demografia <- function(wb) {

  # Fig 5 — Composición urbana-rural por municipio (apilada 100%)
  d <- leer_municipios(wb, "poblacion")
  d5 <- data.frame(Municipio = pick(d, "municipio"),
                   `% Urbana` = pick(d, "porcentaje de poblacion urbana"),
                   `% Rural`  = pick(d, "porcentaje de poblacion rural"),
                   check.names = FALSE)
  wb <- enc_hbar(wb, "poblacion", "O2", "_fig_urbanarural", d5,
                 cat_col = "Municipio", value_cols = c("% Urbana", "% Rural"),
                 colors = c(tema$navy, tema$blue),
                 titulo = "Composición urbana-rural por municipio (%)",
                 grouping = "percentStacked", label_series = 1, num_fmt = "0.0%", legend = TRUE)

  # Fig 6 — Densidad poblacional por municipio (barra simple)
  d6 <- data.frame(Municipio = pick(d, "municipio"),
                   Densidad = pick(d, "densidad poblacional"), check.names = FALSE)
  wb <- enc_hbar(wb, "poblacion", "O24", "_fig_densidad", d6,
                 cat_col = "Municipio", value_cols = "Densidad",
                 colors = tema$navy,
                 titulo = "Densidad poblacional por municipio - 2025 (hab/km²)",
                 grouping = "standard", num_fmt = "0.0", legend = FALSE)

  # Fig 9 — Índice de envejecimiento por municipio (barra simple)
  e <- leer_municipios(wb, "natalidad_mortalidad")
  d9 <- data.frame(Municipio = pick(e, "municipio"),
                   `Índice` = pick(e, "indice de envejecimiento"), check.names = FALSE)
  wb <- enc_hbar(wb, "natalidad_mortalidad", "I2", "_fig_envejecimiento", d9,
                 cat_col = "Municipio", value_cols = "Índice",
                 colors = tema$navy,
                 titulo = "Índice de envejecimiento por municipio - 2024",
                 grouping = "standard", num_fmt = "0.0", legend = FALSE)

  # Fig 7 — Pirámide poblacional (género × grupos de edad), nivel provincia
  ee <- openxlsx2::wb_to_df(wb, sheet = "estructura_edad")
  mun_ee <- pick_name(ee, "municipio")
  tot <- ee[grepl("^TOTAL PROVINCIA", ee[[mun_ee]], ignore.case = TRUE), , drop = FALSE][1, ]
  bandas <- c("0 a 9","10 a 19","20 a 29","30 a 39","40 a 49","50 a 59","60 a 69","70 a 79","80 o más")
  h <- vapply(bandas, function(b) as.numeric(pick(tot, paste0("hombres ", b))), numeric(1))
  m <- vapply(bandas, function(b) as.numeric(pick(tot, paste0("mujeres ", b))), numeric(1))
  wb <- enc_piramide(wb, "estructura_edad", "AI2", "_fig_piramide", bandas, h, m,
                     titulo = "Distribución por género y grupos de edad",
                     col_h = tema$navy, col_m = tema$light, num_fmt = "#,##0")

  invisible(wb)
}


# ----------------------------------------------------------------------------
# Tablas de Demografía con formato del Anexo
# ----------------------------------------------------------------------------
tablas_demografia <- function(wb) {
  pct <- "0.0%"; miles <- "#,##0"; dec2 <- "0.00"

  # Tabla — Proyecciones de población 2025 (hoja poblacion)
  wb <- estilo_tabla(wb, "poblacion", formats = list(
    "poblacion total" = miles, "poblacion urbana" = miles, "poblacion rural" = miles,
    "participacion"   = pct,   "porcentaje"       = pct,   "densidad" = "0.0",
    "codigo dane"     = "0"))

  # Tabla — Natalidad, Mortalidad, Índice de Envejecimiento
  wb <- estilo_tabla(wb, "natalidad_mortalidad", formats = list(
    "tasa de natalidad" = dec2, "tasa de mortalidad" = dec2,
    "indice de envejecimiento" = dec2, "codigo dane" = "0"))

  # Tabla — Tasa neta de migración
  wb <- estilo_tabla(wb, "migracion", formats = list(
    "tasa neta de migracion" = dec2, "codigo dane" = "0"))

  invisible(wb)
}
