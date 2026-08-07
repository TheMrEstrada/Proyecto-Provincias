# fig/01_generalidades.R
figuras_generalidades <- function(wb) {
  s <- "distribucion_territorial"
  wb <- .try("fig3 distribucion territorial", wb, {
    d <- leer_municipios(wb, s)
    df <- data.frame(Municipio = pick(d, "municipio"),
                     Prop = pick(d, "proporcion del territorio"), check.names = FALSE)
    enc_hbar(wb, s, .anchor(wb, s), "_f_distrib", df, "Municipio", "Prop", tema$navy,
             "Distribución territorial por municipio (%)", num_fmt = "0.0%")
  })
  wb
}
