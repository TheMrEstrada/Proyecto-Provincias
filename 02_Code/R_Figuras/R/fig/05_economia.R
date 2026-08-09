# fig/05_economia.R
figuras_economia <- function(wb) {
  A <- function(full, key, niv) agg_valor(full, key, niv)   # atajo agregado
  wb <- .try("prep valor_agregado ultimo anio", wb, .hoja_ultimo_anio(wb,"valor_agregado"))
  # Consolidar hojas ECV: (municipal)/(agregado) -> una sola columna por variable
  for (s in c("ecv_pobreza","ecv_ipm","ecv_gini","ecv_ocupacion_informal","ecv_desocupacion_nini"))
    wb <- .try(paste("consolidar",s), wb, .consolidar_ecv(wb, s))

  # fig31 dependencia: barra_h + barra Provincia (#4472C4) + línea depto (#9DC3E6)
  wb <- .try("fig31 dependencia economica", wb, { s<-"dependencia_economica"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"indice de dependencia","provincia"); dep<-A(full,"indice de dependencia","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `Índice de Dependencia`=pick(d,"indice de dependencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_dep",df,"Municipio","Índice de Dependencia",tema$navy,
             "Índice de Dependencia Económica", num_fmt="0.00", legend=FALSE,
             agg_bar=list(label="Provincia", value=prov, color=tema$blue),
             ref_lines=list(list(value=dep,color=tema$light,label="Departamento"))) })

  # fig32 NBI: columnas NBI total + barra Provincia + puntos NBI rural (rombo)
  wb <- .try("fig32 NBI", wb, { s<-"ecv_pobreza"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov_t<-A(full,"nbi - total (%)","provincia"); prov_r<-A(full,"nbi - rural (%)","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `NBI total`=pick(d,"nbi - total (%)"), `NBI rural`=pick(d,"nbi - rural (%)"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_nbi",df,"Municipio","NBI total",tema$navy,
                  point_col="NBI rural", titulo="Pobreza por NBI (total y rural)", num_fmt="0.0%",
                  point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="NBI total",
                  agg_bar=list(label="Provincia", values=prov_t, color=tema$blue, point=prov_r)) })

  # fig33 IPM: 2 columnas (Hogares/Personas) + Provincia + 2 líneas depto (ancho completo)
  wb <- .try("fig33 IPM", wb, { s<-"ecv_ipm"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    hog_p<-A(full,"hogares en pobreza ipm - total (%)","provincia"); per_p<-A(full,"personas en pobreza ipm - total (%)","provincia")
    hog_d<-A(full,"hogares en pobreza ipm - total (%)","departamento"); per_d<-A(full,"personas en pobreza ipm - total (%)","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Hogares IPM`=pick(d,"hogares en pobreza ipm - total (%)"),
                   `Personas IPM`=pick(d,"personas en pobreza ipm - total (%)"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_ipm",df,"Municipio",
                  c("Hogares IPM","Personas IPM"), c(tema$navy,tema$blue), point_col=NULL,
                  titulo="Pobreza por IPM (hogares y personas)", num_fmt="0.0%",
                  agg_bar=list(label="Provincia", values=c(hog_p,per_p)),
                  ref_lines=list(list(value=hog_d,color=tema$light,label="Depto (hogares)"),
                                 list(value=per_d,color=tema$gris,label="Depto (personas)"))) })

  # fig34 Gini: columnas gini hogar + puntos gini laboral (rombo)
  wb <- .try("fig34 Gini", wb, { s<-"ecv_gini"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Gini hogar`=pick(d,"gini ingresos del hogar - total"), `Gini laboral`=pick(d,"gini laboral - total"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_gini",df,"Municipio","Gini hogar",tema$navy,
                  point_col="Gini laboral", titulo="Gini ingresos del hogar (barras) vs Gini laboral (puntos)",
                  num_fmt="0.00", point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="Gini hogar") })

  # fig36 ocupación: columnas ocupación + Provincia (barra + punto) + puntos informalidad
  wb <- .try("fig36 ocupacion-informalidad", wb, { s<-"ecv_ocupacion_informal"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov_o<-A(full,"tasa de ocupacion - total","provincia"); prov_i<-A(full,"tasa de informalidad laboral - total","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Tasa de ocupación`=pick(d,"tasa de ocupacion - total"),
                   `Tasa de informalidad`=pick(d,"tasa de informalidad laboral - total"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_ocu",df,"Municipio","Tasa de ocupación",tema$navy,
                  point_col="Tasa de informalidad", titulo="Ocupación (barras) vs Informalidad (puntos)",
                  num_fmt="0.0%", point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="Tasa de ocupación",
                  agg_bar=list(label="Provincia", values=prov_o, color=tema$blue, point=prov_i)) })

  # fig38 desocupación: columnas desoc total + Provincia (barra + punto) + puntos jóvenes
  wb <- .try("fig38 desocupacion", wb, { s<-"ecv_desocupacion_nini"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov_t<-A(full,"tasa de desocupacion - total","provincia"); prov_j<-A(full,"tasa de desocupacion jovenes (15-28)","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Desocupación total`=pick(d,"tasa de desocupacion - total"),
                   `Desocupación jóvenes`=pick(d,"tasa de desocupacion jovenes (15-28)"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_des",df,"Municipio","Desocupación total",tema$navy,
                  point_col="Desocupación jóvenes", titulo="Desocupación total (barras) vs jóvenes (puntos)",
                  num_fmt="0.0%", point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="Desocupación total",
                  agg_bar=list(label="Provincia", values=prov_t, color=tema$blue, point=prov_j)) })

  # fig39 NiNi: barra_h + Provincia (#4472C4) + líneas subregión/departamento
  wb <- .try("fig39 NiNi", wb, { s<-"ecv_desocupacion_nini"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"(nini) (%)","provincia"); sub<-A(full,"(nini) (%)","subregi"); dep<-A(full,"(nini) (%)","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `NiNi`=pick(d,"(nini) (%)"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_nini",df,"Municipio","NiNi",tema$navy,"Jóvenes que no estudian ni trabajan (NiNi)",
             num_fmt="0.0%", legend=FALSE, agg_bar=list(label="Provincia", value=prov, color=tema$blue),
             ref_lines=list(list(value=sub,color=tema$blue,label="Subregión"),
                            list(value=dep,color=tema$light,label="Departamento"))) })

  # fig41 VA per cápita: barra_h + (línea depto si existe en export)
  wb <- .try("fig41 VA per capita", wb, { s<-"valor_agregado"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    dep<-A(full,"per capita","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `VA per cápita`=pick(d,"per capita"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_vapc",df,"Municipio","VA per cápita",tema$navy,"Valor Agregado per cápita",
             num_fmt="#,##0", ref_lines=list(list(value=dep,color=tema$light,label="Departamento"))) })

  # fig42 peso relativo VA: barra_h (proporción municipal sobre provincial)
  wb <- .try("fig42 peso relativo VA", wb, { s<-"valor_agregado"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"proporcion del va municipal sobre total provincial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_vapeso",df,"Municipio","V",tema$navy,"Peso relativo del Valor Agregado (sobre provincia)",num_fmt="0.0%",legend=FALSE) })

  # fig43 VA % sectores: apilada 100% (3 series), todos los municipios, etiquetas blancas
  wb <- .try("fig43 VA % sectores (apilada)", wb, { s<-"valor_agregado"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),
                   Primarias=pick(d,"participacion % del va - primarias"),
                   Secundarias=pick(d,"participacion % del va - secundarias"),
                   Terciarias=pick(d,"participacion % del va - terciarias"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,2),"_f_vasec",df,"Municipio",c("Primarias","Secundarias","Terciarias"),
             c(tema$navy,tema$blue,tema$light),"Distribución % del VA por sectores",
             grouping="percentStacked", label_series=c(1,2,3), num_fmt="0.0%", sort=FALSE, label_color="FFFFFF") })

  # fig44 VA por actividades: agrupado y coloreado por SECTOR, etiquetas a la derecha
  wb <- .try("fig44 VA por actividades", wb, { s<-"va_actividades"; d<-ultimo_anio(openxlsx2::wb_to_df(wb,s))
    dane<-pick(d,"codigo dane"); prov<-d[(is.na(dane)|trimws(as.character(dane))=="") & grepl("provincia",.norm(pick(d,"municipio"))),,drop=FALSE][1,]
    prim<-c("Agricultura, ganadería","Explotación de minas"); seco<-c("Industrias manufactureras","Construcción")
    va<-grep("^VA ",names(d),value=TRUE)
    so<-function(nm){ n2<-.norm(nm)
      if(any(sapply(.norm(prim), function(p) grepl(p,n2,fixed=TRUE)))) "Primario"
      else if(any(sapply(.norm(seco), function(p) grepl(p,n2,fixed=TRUE)))) "Secundario" else "Terciario" }
    sec<-vapply(va, so, ""); ord<-order(factor(sec,levels=c("Primario","Secundario","Terciario"))); va<-va[ord]; sec<-sec[ord]
    enc_hbar_sector(wb,s,.anchor(wb,s),"_f_vaact", sub("^VA ","",va), as.numeric(prov[va]), sec,
                    c("Primario","Secundario","Terciario"),
                    list(Primario=tema$navy, Secundario=tema$blue, Terciario=tema$light),
                    "VA por actividades económicas, por sector (provincia)", num_fmt="#,##0.0") })

  # fig45 densidad empresarial: barra_h + línea promedio provincia
  wb <- .try("fig45 densidad empresarial", wb, { s<-"densidad_empresarial"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"densidad empresarial","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Densidad empresarial`=pick(d,"densidad empresarial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_dens",df,"Municipio","Densidad empresarial",tema$navy,"Densidad empresarial",
             num_fmt="0.0", legend=FALSE, ref_lines=list(list(value=prov,color=tema$light,label="Promedio provincia"))) })

  # fig49 títulos mineros: barra_h simple, sin eje/guías
  wb <- .try("fig49 titulos mineros", wb, { s<-"titulos_mineros"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"numero de titulos")),,drop=FALSE]
    df<-data.frame(Mineral=pick(d,"tipo de mineral"), N=pick(d,"numero de titulos"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_min",df,"Mineral","N",tema$navy,"Títulos mineros por tipo de mineral",num_fmt="0",legend=FALSE) })

  # fig50 evolución visitantes: UNA línea = total provincia por año, etiquetas, sin eje Y/guías
  wb <- .try("fig50 evolucion visitantes (linea)", wb, { s<-"extranjeros_municipio"; d<-leer_municipios(wb,s)
    yr<-suppressWarnings(as.numeric(pick(d,"ano"))); val<-as.numeric(pick(d,"visitantes extranjeros"))
    tot<-tapply(val, yr, sum, na.rm=TRUE)
    wide<-data.frame(Anio=as.numeric(names(tot)), `Provincia`=as.numeric(tot), check.names=FALSE)
    enc_line(wb,s,.anchor(wb,s),"_f_extr",wide,"Anio","Provincia",titulo="Evolución de visitantes extranjeros de la provincia",
             num_fmt="#,##0", colors=tema$navy, legend=FALSE, show_val=TRUE, value_axis=FALSE, grid=FALSE) })

  # fig51 visitantes PAP vs Departamento: barras (Antioquia, etiqueta negra) + puntos (Provincia, etiqueta blanca)
  wb <- .try("fig51 visitantes PAP vs depto", wb, { s<-"comparativo_pap_antioquia"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"ano")),,drop=FALSE]
    df<-data.frame(`Año`=pick(d,"ano"),
                   `Antioquia`=pick(d,"visitantes extranjeros antioquia"),
                   `Provincia`=pick(d,"visitantes extranjeros provincia"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_comp",df,"Año","Antioquia",tema$navy,
                  point_col="Provincia", titulo="Visitantes Extranjeros PAP y Departamento",
                  num_fmt="#,##0", point_outline=tema$light, bar_labels=TRUE, point_labels=TRUE,
                  label_color="FFFFFF", sort=FALSE) })

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
