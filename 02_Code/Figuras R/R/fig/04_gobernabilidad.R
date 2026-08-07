# fig/04_gobernabilidad.R
figuras_gobernabilidad <- function(wb) {
  wb <- .try("fig27 MDM", wb, { s<-"mdm"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"mdm"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_mdm",df,"Municipio","V",tema$navy,"Medición de Desempeño Municipal",num_fmt="0.0") })

  wb <- .try("fig28 IDF", wb, { s<-"idf"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"idf"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_idf",df,"Municipio","V",tema$navy,"Índice de Desempeño Fiscal",num_fmt="0.0") })

  wb <- .try("fig29 ultimo anio ley617", wb, .hoja_ultimo_anio(wb,"ley617"))
  wb <- .try("tabla fig29 ley617", wb, estilo_tabla(wb,"ley617",
        formats=list("icdl"="0.0%","gastos"="0.0%","indicador ley 617"="0.0%","ano"="0")))
  wb <- .try("fig30 ultimo anio ICM", wb, .hoja_ultimo_anio(wb,"icm"))
  wb <- .try("tabla fig30 ICM", wb, estilo_tabla(wb,"icm", formats=list("ano"="0"), num_default="0.0"))
  wb
}
