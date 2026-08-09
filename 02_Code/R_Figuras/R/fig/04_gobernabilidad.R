# fig/04_gobernabilidad.R
figuras_gobernabilidad <- function(wb) {
  # fig27 MDM: columnas Gestión/Resultados + punto MDM (diamante, relleno blanco).
  #   Colores específicos pedidos: Gestión #4472C4, Resultados #1F3864.
  wb <- .try("fig27 MDM", wb, { s<-"mdm"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), `Gestión`=pick(d,"gestion"),
                   Resultados=pick(d,"resultados"), MDM=pick(d,"mdm"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_mdm",df,"Municipio",
                  c("Gestión","Resultados"), c(tema$blue,tema$navy), "MDM",
                  "Medición de Desempeño Municipal (MDM)", num_fmt="0.0",
                  label_pos="b", label_color="FFFFFF") })   # etiqueta MDM debajo, blanca (específico)

  # fig28 IDF: mismo patrón (mapeo de color provisional a revisar por el usuario).
  wb <- .try("fig28 IDF", wb, { s<-"idf"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), `Gestión`=pick(d,"gestion"),
                   Resultados=pick(d,"resultados"), IDF=pick(d,"idf"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_idf",df,"Municipio",
                  c("Gestión","Resultados"), c(tema$blue,tema$navy), "IDF",
                  "Índice de Desempeño Fiscal (IDF)", num_fmt="0.0") })

  wb <- .try("fig29 ultimo anio ley617", wb, .hoja_ultimo_anio(wb,"ley617"))
  wb <- .try("tabla fig29 ley617", wb, estilo_tabla(wb,"ley617",
        formats=list("icdl"="#,##0","gastos"="#,##0","indicador ley 617"="0.0%","ano"="0")))
  wb <- .try("fig30 ultimo anio ICM", wb, .hoja_ultimo_anio(wb,"icm"))
  wb <- .try("tabla fig30 ICM", wb, estilo_tabla(wb,"icm", formats=list("ano"="0"), num_default="0.0"))
  wb
}
