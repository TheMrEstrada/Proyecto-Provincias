# fig/05_economia.R
figuras_economia <- function(wb) {
  # valor_agregado: dejar solo último año (tabla + gráficos usan ese año)
  wb <- .try("prep valor_agregado ultimo anio", wb, .hoja_ultimo_anio(wb,"valor_agregado"))

  wb <- .try("fig31 dependencia economica", wb, { s<-"dependencia_economica"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"indice de dependencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_dep",df,"Municipio","V",tema$navy,"Índice de Dependencia Económica",num_fmt="0.00") })

  wb <- .try("fig32 NBI", wb, { s<-"ecv_pobreza"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"nbi - total (%) (municipal)"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_nbi",df,"Municipio","V",tema$navy,"Pobreza por NBI",num_fmt="0.0%") })

  wb <- .try("fig33 IPM", wb, { s<-"ecv_ipm"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"personas en pobreza ipm - total (%) (municipal)"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_ipm",df,"Municipio","V",tema$navy,"Pobreza por IPM (personas)",num_fmt="0.0%") })

  wb <- .try("fig34 dumbbell Gini", wb, { s<-"ecv_gini"; d<-leer_municipios(wb,s)
    enc_dumbbell(wb,s,.anchor(wb,s),"_f_gini",pick(d,"municipio"),
      pick(d,"gini ingresos del hogar - total (municipal)"), pick(d,"gini laboral - total (municipal)"),
      "Gini hogar","Gini laboral",titulo="Gini hogar vs laboral",num_fmt="0.00") })

  wb <- .try("fig36 dumbbell ocupacion-informalidad", wb, { s<-"ecv_ocupacion_informal"; d<-leer_municipios(wb,s)
    enc_dumbbell(wb,s,.anchor(wb,s),"_f_ocu",pick(d,"municipio"),
      pick(d,"tasa de ocupacion - total (municipal)"), pick(d,"tasa de informalidad laboral - total (municipal)"),
      "Ocupación","Informalidad",titulo="Ocupación vs Informalidad",num_fmt="0.0%") })

  wb <- .try("fig38 dumbbell desocupacion", wb, { s<-"ecv_desocupacion_nini"; d<-leer_municipios(wb,s)
    enc_dumbbell(wb,s,.anchor(wb,s),"_f_des",pick(d,"municipio"),
      pick(d,"tasa de desocupacion - total (municipal)"), pick(d,"tasa de desocupacion jovenes"),
      "Desoc. total","Desoc. jóvenes",titulo="Desocupación: total vs jóvenes",num_fmt="0.0%") })

  wb <- .try("fig39 NiNi", wb, { s<-"ecv_desocupacion_nini"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"nini"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_nini",df,"Municipio","V",tema$navy,"Jóvenes NiNi",num_fmt="0.0%") })

  wb <- .try("fig41 VA per capita", wb, { s<-"valor_agregado"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"per capita"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_vapc",df,"Municipio","V",tema$navy,"Valor Agregado per cápita",num_fmt="#,##0") })

  wb <- .try("fig42 peso relativo VA", wb, { s<-"valor_agregado"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"proporcion del va municipal sobre total provincial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_vapeso",df,"Municipio","V",tema$navy,"Peso relativo del Valor Agregado",num_fmt="0.0%") })

  wb <- .try("fig43 VA % sectores (torta)", wb, { s<-"valor_agregado"; d<-openxlsx2::wb_to_df(wb,s)
    dane<-pick(d,"codigo dane"); prov<-d[(is.na(dane)|trimws(as.character(dane))=="") & grepl("provincia",.norm(pick(d,"municipio"))),,drop=FALSE][1,]
    cols<-c(pick_name(d,"participacion % del va - primarias"),pick_name(d,"participacion % del va - secundarias"),pick_name(d,"participacion % del va - terciarias"))
    enc_pie(wb,s,.anchor(wb,s,2),"_f_vasec",c("Primarias","Secundarias","Terciarias"),as.numeric(prov[cols]),
            titulo="Distribución % del VA por sectores") })

  wb <- .try("fig44 VA por actividades", wb, { s<-"va_actividades"; d<-ultimo_anio(openxlsx2::wb_to_df(wb,s))
    dane<-pick(d,"codigo dane"); prov<-d[(is.na(dane)|trimws(as.character(dane))=="") & grepl("provincia",.norm(pick(d,"municipio"))),,drop=FALSE][1,]
    acts<-grep("^VA ",names(d),value=TRUE)
    df<-data.frame(Actividad=sub("^VA ","",acts), Valor=as.numeric(prov[acts]), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_vaact",df,"Actividad","Valor",tema$navy,"VA por actividades económicas (provincia)",num_fmt="#,##0") })

  wb <- .try("fig45 densidad empresarial", wb, { s<-"densidad_empresarial"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"densidad empresarial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_dens",df,"Municipio","V",tema$navy,"Densidad empresarial",num_fmt="0.0") })

  wb <- .try("fig49 titulos mineros", wb, { s<-"titulos_mineros"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"numero de titulos")),,drop=FALSE]
    df<-data.frame(Mineral=pick(d,"tipo de mineral"), N=pick(d,"numero de titulos"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_min",df,"Mineral","N",tema$navy,"Títulos mineros por tipo de mineral",num_fmt="0",legend=FALSE) })

  wb <- .try("fig50 evolucion visitantes (linea)", wb, { s<-"extranjeros_municipio"; d<-leer_municipios(wb,s)
    yr<-suppressWarnings(as.numeric(pick(d,"ano"))); mun<-pick(d,"municipio"); val<-as.numeric(pick(d,"visitantes extranjeros"))
    m<-tapply(val, list(yr, mun), sum, na.rm=TRUE); m[is.na(m)]<-0
    wide<-data.frame(Anio=as.numeric(rownames(m)), m, check.names=FALSE)
    enc_line(wb,s,.anchor(wb,s),"_f_extr",wide,"Anio",colnames(m),titulo="Evolución de visitantes extranjeros",num_fmt="#,##0") })

  wb <- .try("fig51 comparativo visitantes (linea)", wb, { s<-"comparativo_pap_antioquia"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"ano")),,drop=FALSE]
    wide<-data.frame(Anio=pick(d,"ano"), PAP=pick(d,"visitantes extranjeros provincia"), Antioquia=pick(d,"visitantes extranjeros antioquia"), check.names=FALSE)
    enc_line(wb,s,.anchor(wb,s),"_f_comp",wide,"Anio",c("PAP","Antioquia"),titulo="Visitantes: PAP vs Antioquia",num_fmt="#,##0") })

  # -- Tablas --
  wb <- .try("tabla fig35 gini", wb, estilo_tabla(wb,"ecv_gini", num_default="0.000"))
  wb <- .try("tabla fig37 ocupacion informal", wb, estilo_tabla(wb,"ecv_ocupacion_informal", formats=list("tasa"="0.0%")))
  wb <- .try("tabla fig40 valor agregado", wb, estilo_tabla(wb,"valor_agregado", formats=list("participacion"="0.0%","proporcion"="0.0%","per capita"="#,##0","ano"="0"), num_default="#,##0.0"))
  wb <- .try("tabla fig46 energia tecnologia", wb, estilo_tabla(wb,"energia_tecnologia", formats=list("participacion"="0.0%","capacidad"="#,##0.0"), hide_cols=character(0)))
  wb <- .try("tabla fig47 energia centrales", wb, estilo_tabla(wb,"energia_centrales", formats=list("participacion"="0.0%","capacidad"="#,##0.0")))
  wb <- .try("tabla fig48 energia participacion", wb, estilo_tabla(wb,"energia_participacion", formats=list("participacion"="0.0%","capacidad"="#,##0.0"), hide_cols=character(0)))
  wb <- .try("tabla fig52 turismo instrumentos", wb, estilo_tabla(wb,"turismo_instrumentos"))
  wb
}
