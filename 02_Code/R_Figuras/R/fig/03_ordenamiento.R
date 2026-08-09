# fig/03_ordenamiento.R   (fig11 POT y fig14 POMCA/PORH = fuera de alcance)
figuras_ordenamiento <- function(wb) {
  PROV<-"4472C4"; SUB<-"9DC3E6"; DEP<-"7f7f7f"

  # fig12 uso adecuado del suelo rural (sin agregado, sin leyenda ni eje)
  wb <- .try("fig12 uso suelo rural", wb, { s<-"uso_suelo_rural"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"predios con uso adecuado"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_uso",df,"Municipio","V",tema$navy,"Uso adecuado del suelo rural",
             num_fmt="0.0%", legend=FALSE) })

  # fig15 / fig16 vías: apiladas absolutas, SIN etiquetas de datos
  wb <- .try("fig15 vias por area", wb, { s<-"vias_area"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), Primaria=pick(d,"primaria por km"),
                   Secundaria=pick(d,"secundaria por km"), Terciaria=pick(d,"terciaria por km"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_viasA",df,"Municipio",c("Primaria","Secundaria","Terciaria"),
             tema$serie,"Km de vía por km² del municipio",grouping="stacked",label_series=0,num_fmt="0.000",sort=FALSE) })
  wb <- .try("fig16 vias por hab", wb, { s<-"vias_habitantes"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), Primaria=pick(d,"primaria por cada 1.000"),
                   Secundaria=pick(d,"secundaria por cada 1.000"), Terciaria=pick(d,"terciaria por cada 1.000"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_viasH",df,"Municipio",c("Primaria","Secundaria","Terciaria"),
             tema$serie,"Km de vía por cada mil habitantes",grouping="stacked",label_series=0,num_fmt="0.00",sort=FALSE) })

  # fig17 tti educación superior + línea promedio provincia (#9DC3E6), sin leyenda
  wb <- .try("fig17 tti edsup", wb, { s<-"tti_edsup"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-agg_valor(full,"tasa de transito","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Tasa de tránsito`=pick(d,"tasa de transito"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_tti",df,"Municipio","Tasa de tránsito",tema$navy,"Tránsito inmediato a educación superior",
             num_fmt="0.0%", ref_lines=list(list(value=prov,color=SUB,label="Promedio provincia"))) })

  # fig18 IMCA prov vs subregión -> RADAR (sin total)
  wb <- .try("fig18 IMCA radar", wb, { s<-"imca"; full<-openxlsx2::wb_to_df(wb,s)
    dims<-grep("^IMCA ",names(full),value=TRUE); dims<-dims[.norm(dims)!="imca total"]
    prov<-sapply(dims,function(cc) agg_valor(full,cc,"provincia")); sub<-sapply(dims,function(cc) agg_valor(full,cc,"subregi"))
    labs<-sub("(?i)^imca ","",dims,perl=TRUE)
    enc_radar(wb,s,.anchor(wb,s),"_f_imcaPS",labs,list(Provincia=prov,Subregión=sub),
              colors=c(tema$navy,tema$light),titulo="IMCA por dimensiones: Provincia vs Subregión") })

  # fig19 IMCA adopción TIC + línea promedio provincia
  wb <- .try("fig19 IMCA adopcion TIC", wb, { s<-"imca"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-agg_valor(full,"adopcion tic","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Adopción de TIC`=pick(d,"adopcion tic"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_imcaTIC",df,"Municipio","Adopción de TIC",tema$navy,"IMCA: Adopción de TIC",
             num_fmt="0.0", ref_lines=list(list(value=prov,color=SUB,label="Promedio provincia"))) })

  # fig20 IGD índice + línea promedio provincia
  wb <- .try("fig20 IGD indice", wb, { s<-"gobierno_digital"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-agg_valor(full,"indice de gobierno digital","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Índice de Gobierno Digital`=pick(d,"indice de gobierno digital"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_igd",df,"Municipio","Índice de Gobierno Digital",tema$navy,"Índice de Gobierno Digital",
             num_fmt="0.0", ref_lines=list(list(value=prov,color=SUB,label="Promedio provincia"))) })

  # fig21 IGD por componente -> RADAR (sin total)
  wb <- .try("fig21 IGD radar", wb, { s<-"gobierno_digital"; full<-openxlsx2::wb_to_df(wb,s)
    comp<-setdiff(names(full)[6:ncol(full)], pick_name(full,"indice de gobierno digital"))
    prov<-sapply(comp,function(cc) agg_valor(full,cc,"provincia")); sub<-sapply(comp,function(cc) agg_valor(full,cc,"subregi"))
    enc_radar(wb,s,.anchor(wb,s,1),"_f_igdR",comp,list(Provincia=prov,Subregión=sub),
              colors=c(tema$navy,tema$light),titulo="IGD por componente FURAG: Provincia vs Subregión") })

  # fig22 internet por 1000 + línea promedio provincia
  wb <- .try("fig22 internet por 1000", wb, { s<-"internet_2025"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-agg_valor(full,"por cada 1.000 habitantes","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Líneas por 1.000 hab.`=pick(d,"por cada 1.000 habitantes"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_int1000",df,"Municipio","Líneas por 1.000 hab.",tema$navy,"Líneas de internet fijo por 1.000 hab.",
             num_fmt="0.0", ref_lines=list(list(value=prov,color=SUB,label="Promedio provincia"))) })

  # fig23 proporción fibra + línea promedio provincia
  wb <- .try("fig23 proporcion fibra", wb, { s<-"internet_2025"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-agg_valor(full,"proporcion de lineas sobre fibra","provincia")
    df<-data.frame(Municipio=pick(d,"municipio"), `Proporción sobre fibra óptica`=pick(d,"proporcion de lineas sobre fibra"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_fibra",df,"Municipio","Proporción sobre fibra óptica",tema$navy,"Proporción de líneas sobre fibra óptica",
             num_fmt="0.0%", ref_lines=list(list(value=prov,color=SUB,label="Promedio provincia"))) })

  # fig24 / fig25 déficit vivienda: barras navy + 3 líneas (prov/subreg/depto) + leyenda
  refs_def<-function(full,col) list(
    list(value=agg_valor(full,col,"provincia"),   color=PROV,label="Provincia"),
    list(value=agg_valor(full,col,"subregi"),     color=SUB, label="Subregión"),
    list(value=agg_valor(full,col,"departamento"),color=DEP, label="Departamento"))
  wb <- .try("fig24 deficit cualitativo", wb, { s<-"deficit_vivienda"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), `Déficit cualitativo`=pick(d,"deficit cualitativo"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_defcual",df,"Municipio","Déficit cualitativo",tema$navy,
             "Déficit cualitativo de vivienda",num_fmt="0.0%",legend=TRUE,
             ref_lines=refs_def(full,"deficit cualitativo")) })
  wb <- .try("fig25 deficit cuantitativo", wb, { s<-"deficit_vivienda"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), `Déficit cuantitativo`=pick(d,"deficit cuantitativo"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_defcuan",df,"Municipio","Déficit cuantitativo",tema$navy,
             "Déficit cuantitativo de vivienda",num_fmt="0.0%",legend=TRUE,
             ref_lines=refs_def(full,"deficit cuantitativo")) })

  # fig13 catastro (OK) -> tabla
  wb <- .try("tabla fig13 catastro", wb, estilo_tabla(wb,"catastro", formats=list("avaluo"="#,##0","proporcion"="0.0%")))

  # fig26 servicios públicos: fusionar (municipal/agregado) -> una columna por servicio
  wb <- .try("fig26 servicios publicos (reestructura)", wb, { s<-"servicios_publicos"; full<-openxlsx2::wb_to_df(wb,s)
    base<-data.frame(`Código DANE`=full[[pick_name(full,"codigo dane")]],
                     Municipio=full[[pick_name(full,"municipio")]],
                     Subregión=full[[pick_name(full,"subregion")]],
                     Provincia=full[[pick_name(full,"provincia")]], check.names=FALSE)
    servs<-list("energia"="Cobertura de energía (%)","acueducto"="Cobertura de acueducto (%)",
                "alcantarillado"="Cobertura de alcantarillado (%)","recoleccion de basuras"="Cobertura de recolección de basuras (%)",
                "internet"="Cobertura de internet (%)","gas natural"="Cobertura de gas natural (%)")
    for(k in names(servs)){
      m<-suppressWarnings(as.numeric(pick(full, paste0("cobertura de ",k," (%) (municipal)"))))
      a<-suppressWarnings(as.numeric(pick(full, paste0("cobertura de ",k," (%) (agregado)"))))
      base[[servs[[k]]]]<-ifelse(!is.na(m), m, a)
    }
    wb <- .hoja_reescribir(wb, s, base)
    estilo_tabla(wb, s, formats=list("cobertura"="0.0%")) })
  wb
}
