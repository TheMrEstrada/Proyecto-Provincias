# fig/01_generalidades.R
figuras_generalidades <- function(wb) {
  s <- "distribucion_territorial"
  # Fig 3 — gráfico (barra %); eje/guías ocultos por convención global
  wb <- .try("fig3 distribucion territorial (gráfico)", wb, {
    d <- leer_municipios(wb, s)
    df <- data.frame(Municipio = pick(d, "municipio"),
                     Prop = pick(d, "proporcion del territorio"), check.names = FALSE)
    enc_hbar(wb, s, .anchor(wb, s), "_f_distrib", df, "Municipio", "Prop", tema$navy,
             "Distribución territorial por municipio (%)", num_fmt = "0.0%")
  })
  # Tabla 6 (Anexo) — misma hoja, formato de tabla; incluye agregados prov/subreg/depto
  wb <- .try("fig3 tabla distribucion territorial", wb,
             estilo_tabla(wb, s, formats = list("area municipal" = "#,##0.0",
                                                "proporcion del territorio" = "0.0%")))
  wb
}
