# fig/06_desarrollo_rural.R  (fig57 suelo rural = fuera de alcance)
figuras_desarrollo_rural <- function(wb) {
  wb <- .try("fig54 participacion pecuaria", wb, { s<-"participacion_municipal"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"participacion en el total provincial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_ppec",df,"Municipio","V",tema$navy,"Participación en el inventario pecuario",num_fmt="0.0%") })

  wb <- .try("fig55 composicion especies", wb, { s<-"composicion_especies"; d<-ultimo_anio(leer_municipios(wb,s))
    esp<-c("Bovinos","Búfalos","Caprinos","Ovinos","Equinos","Porcinos")
    cols<-vapply(esp, function(e) pick_name(d, paste0(.norm(e)," (%)")), character(1))
    df<-data.frame(Municipio=pick(d,"municipio")); for(k in seq_along(esp)) df[[esp[k]]]<-as.numeric(d[[cols[k]]])
    enc_hbar(wb,s,.anchor(wb,s),"_f_cesp",df,"Municipio",esp,tema$serie,"Composición del inventario pecuario",grouping="percentStacked",label_series=0,num_fmt="0.0%",sort=FALSE) })

  wb <- .try("fig58 composicion agricola municipio", wb, { s<-"composicion_agricola"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"),
                   Permanentes=pick(d,"proporcion de cultivos permanentes"),
                   Transitorios=pick(d,"proporcion de cultivos transitorios"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_cagr",df,"Municipio",c("Permanentes","Transitorios"),c(tema$navy,tema$blue),
             "Producción agrícola por tipo de cultivo",grouping="percentStacked",label_series=0,num_fmt="0.0%",sort=FALSE) })

  wb <- .try("fig59 composicion agricola PAP (torta)", wb, { s<-"composicion_agricola"; d<-ultimo_anio(leer_municipios(wb,s))
    perm<-sum(as.numeric(pick(d,"produccion de cultivos permanentes")),na.rm=TRUE)
    tran<-sum(as.numeric(pick(d,"produccion de cultivos transitorios")),na.rm=TRUE); tot<-perm+tran
    enc_pie(wb,s,.anchor(wb,s,1),"_f_cagrP",c("Permanentes","Transitorios"),c(perm/tot,tran/tot),
            titulo="Composición de la producción agrícola (PAP)") })

  wb <- .try("fig61 rendimiento", wb, { s<-"rendimiento"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"rendimiento (t/ha)"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_rend",df,"Municipio","V",tema$navy,"Rendimiento agrícola (t/ha)",num_fmt="0.00") })

  # -- Tablas --
  wb <- .try("tabla fig53 inventario pecuario", wb, { .hoja_ultimo_anio(wb,"inventario_pecuario") })
  wb <- .try("tabla fig53 estilo", wb, estilo_tabla(wb,"inventario_pecuario", formats=list("ano"="0"), num_default="#,##0"))
  wb <- .try("tabla fig56 extension", wb, estilo_tabla(wb,"area_km2", formats=list("area"="#,##0.0")))
  wb <- .try("tabla fig60 permanentes", wb, estilo_tabla(wb,"permanentes", formats=list("area"="#,##0.0","produccion"="#,##0.0","rendimiento"="0.00","ano"="0")))
  wb <- .try("tabla fig60 transitorios", wb, estilo_tabla(wb,"transitorios", formats=list("area"="#,##0.0","produccion"="#,##0.0","rendimiento"="0.00","ano"="0")))
  wb
}
