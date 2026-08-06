# fig/07_ambiental.R  (fig62 clima = fuera de alcance)
figuras_ambiental <- function(wb) {
  wb <- .try("fig65 perdida cobertura", wb, { s<-"perdida_cobertura"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"perdida de cobertura"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_cob",df,"Municipio","V",tema$navy,"Pérdida de cobertura arbórea 2001-2023",num_fmt="0.0%") })

  # -- Tablas --
  wb <- .try("tabla fig63 areas protegidas", wb, estilo_tabla(wb,"detalle", formats=list("area"="#,##0.00","participacion"="0.0%")))
  wb <- .try("tabla fig64 IRCA", wb, { .hoja_ultimo_anio(wb,"irca") })
  wb <- .try("tabla fig64 estilo", wb, estilo_tabla(wb,"irca", formats=list("irca"="0.0","ano"="0")))
  wb <- .try("tabla fig66 desastres", wb, estilo_tabla(wb,"desastres_selectos", num_default="#,##0"))
  wb <- .try("tabla fig67 IMRC", wb, estilo_tabla(wb,"imrc", num_default="0.000"))
  wb
}
