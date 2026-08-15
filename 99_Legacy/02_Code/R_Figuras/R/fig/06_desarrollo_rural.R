# fig/06_desarrollo_rural.R  (fig57 suelo rural = fuera de alcance)
figuras_desarrollo_rural <- function(wb) {
  A <- function(full, key, niv) agg_valor(full, key, niv)

  # fig54 participación en inventario pecuario: barra_h simple, sin eje/guías
  wb <- .try("fig54 participacion pecuaria", wb, { s<-"participacion_municipal"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"participacion en el total provincial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_ppec",df,"Municipio","V",tema$navy,"Participación en el inventario pecuario",num_fmt="0.0%", legend=FALSE) })

  # fig55 composición pecuaria: apilada 100%, 6 especies (3 sólidas + 3 contorno/relleno blanco), sin etiquetas
  wb <- .try("fig55 composicion especies", wb, { s<-"composicion_especies"; d<-ultimo_anio(leer_municipios(wb,s))
    esp<-c("Bovinos","Búfalos","Caprinos","Ovinos","Equinos","Porcinos")
    df<-data.frame(Municipio=pick(d,"municipio"), check.names=FALSE)
    for(e in esp) df[[e]]<-as.numeric(pick(d, paste0(.norm(e)," (%)")))
    enc_hbar(wb,s,.anchor(wb,s),"_f_cesp",df,"Municipio",esp,
             tema$serie6,   # 6 colores sólidos: navy, azul profundo, blue, azul medio, light, gris
             "Composición del inventario pecuario",grouping="percentStacked",label_series=0,num_fmt="0.0%",sort=FALSE) })

  # fig58 composición agrícola por municipio: apilada 100%, etiqueta solo Permanentes (blanca)
  wb <- .try("fig58 composicion agricola municipio", wb, { s<-"composicion_agricola"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"),
                   Permanentes=pick(d,"proporcion de cultivos permanentes"),
                   Transitorios=pick(d,"proporcion de cultivos transitorios"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_cagr",df,"Municipio",c("Permanentes","Transitorios"),c(tema$navy,tema$blue),
             "Producción agrícola por tipo de cultivo",grouping="percentStacked",label_series=1,num_fmt="0.0%",sort=FALSE,
             label_color="FFFFFF") })

  # fig59 participación del municipio en la producción agrícola de la provincia (2025): barra_h (no torta)
  wb <- .try("fig59 participacion produccion agricola", wb, { s<-"composicion_agricola"; d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"participacion del municipio en la produccion de la provincia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_pagr",df,"Municipio","V",tema$navy,
             "Participación del municipio en la producción agrícola de la provincia",num_fmt="0.0%", legend=FALSE) })

  # fig61 área cosechada (columnas, eje principal) + rendimiento (diamantes, eje secundario)
  wb <- .try("fig61 area cosechada vs rendimiento", wb, { s<-"rendimiento"; full<-openxlsx2::wb_to_df(wb,s); d<-ultimo_anio(leer_municipios(wb,s))
    prov_a<-A(full,"area cosechada total","provincia"); prov_r<-A(full,"rendimiento (t/ha)","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Área cosechada (ha)`=pick(d,"area cosechada total"),
                   `Rendimiento (t/ha)`=pick(d,"rendimiento (t/ha)"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_rend",df,"Municipio","Área cosechada (ha)",tema$navy,
                  point_col="Rendimiento (t/ha)", titulo="Área cosechada (barras) y rendimiento (puntos)",
                  num_fmt="#,##0", point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="Área cosechada (ha)",
                  agg_bar=list(label="Provincia", values=prov_a, color=tema$blue, point=prov_r),
                  point_secondary=TRUE, point_axis_fmt="0.0") })

  # -- Tablas --
  wb <- .try("fig53 ultimo anio pecuario", wb, .hoja_ultimo_anio(wb,"inventario_pecuario"))
  wb <- .try("tabla fig53 inventario pecuario", wb, estilo_tabla(wb,"inventario_pecuario", formats=list("ano"="0"), num_default="#,##0"))
  wb <- .try("tabla fig56 extension", wb, estilo_tabla(wb,"area_km2", formats=list("area"="#,##0.0")))
  wb <- .try("fig60 ultimo anio cultivos", wb, .hoja_ultimo_anio(wb,"principales_cultivos"))
  wb <- .try("tabla fig60 principales cultivos", wb, estilo_tabla(wb,"principales_cultivos",
        formats=list("produccion"="#,##0.0","ano"="0"), hide_cols=character(0)))
  wb
}
