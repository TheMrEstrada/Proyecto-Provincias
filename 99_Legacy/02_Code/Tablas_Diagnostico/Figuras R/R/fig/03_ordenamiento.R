# fig/03_ordenamiento.R
figuras_ordenamiento <- function(wb) {
  # -- Gráficos --
  wb <- .try("fig12 uso suelo rural", wb, { s<-"uso_suelo_rural"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"predios con uso adecuado"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_uso",df,"Municipio","V",tema$navy,"Uso adecuado del suelo rural",num_fmt="0.0%") })

  wb <- .try("fig15 vias por area", wb, { s<-"vias_area"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),Primaria=pick(d,"primaria por km"),
                   Secundaria=pick(d,"secundaria por km"),Terciaria=pick(d,"terciaria por km"),check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_viasA",df,"Municipio",c("Primaria","Secundaria","Terciaria"),
             tema$serie,"Km de vía por km² del municipio",grouping="stacked",label_series=0,num_fmt="0.000",sort=FALSE) })

  wb <- .try("fig16 vias por hab", wb, { s<-"vias_habitantes"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),Primaria=pick(d,"primaria por cada 1.000"),
                   Secundaria=pick(d,"secundaria por cada 1.000"),Terciaria=pick(d,"terciaria por cada 1.000"),check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_viasH",df,"Municipio",c("Primaria","Secundaria","Terciaria"),
             tema$serie,"Km de vía por cada mil habitantes",grouping="stacked",label_series=0,num_fmt="0.00",sort=FALSE) })

  wb <- .try("fig17 tti educacion superior", wb, { s<-"tti_edsup"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"tasa de transito"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_tti",df,"Municipio","V",tema$navy,"Tránsito inmediato a educación superior",num_fmt="0.0%") })

  wb <- .try("fig18 IMCA prov vs subregion", wb, { s<-"imca"; d<-openxlsx2::wb_to_df(wb,s)
    dane<-pick(d,"codigo dane"); agg<-d[is.na(dane)|trimws(as.character(dane))=="", ,drop=FALSE]
    mun<-pick_name(d,"municipio")
    prov<-agg[grepl("provincia",.norm(agg[[mun]])),,drop=FALSE][1,]
    sub <-agg[grepl("subregi",.norm(agg[[mun]])),,drop=FALSE][1,]
    dims<-grep("^imca ",names(d),ignore.case=TRUE,value=TRUE); dims<-dims[.norm(dims)!="imca total"]
    df<-data.frame(Dimension=sub("(?i)imca ","",dims,perl=TRUE),
                   Provincia=as.numeric(prov[dims]), Subregion=as.numeric(sub[dims]), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_imcaPS",df,"Dimension",c("Provincia","Subregion"),
             c(tema$navy,tema$blue),"IMCA por dimensiones: Provincia vs Subregión",grouping="clustered",label_series=0,num_fmt="0.0",sort=FALSE) })

  wb <- .try("fig19 IMCA adopcion TIC", wb, { s<-"imca"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"adopcion tic"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_imcaTIC",df,"Municipio","V",tema$navy,"IMCA: Adopción de TIC",num_fmt="0.0") })

  wb <- .try("fig20 IGD indice", wb, { s<-"gobierno_digital"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"indice de gobierno digital"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_igd",df,"Municipio","V",tema$navy,"Índice de Gobierno Digital",num_fmt="0.0") })

  wb <- .try("fig21 IGD componentes", wb, { s<-"gobierno_digital"; d<-openxlsx2::wb_to_df(wb,s)
    dane<-pick(d,"codigo dane"); agg<-d[is.na(dane)|trimws(as.character(dane))=="", ,drop=FALSE]
    mun<-pick_name(d,"municipio"); prov<-agg[grepl("provincia",.norm(agg[[mun]])),,drop=FALSE][1,]
    comp<-setdiff(names(d)[6:ncol(d)], pick_name(d,"indice de gobierno digital"))
    df<-data.frame(Componente=comp, Valor=as.numeric(prov[comp]), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_igdC",df,"Componente","Valor",tema$navy,"IGD por componente FURAG (provincia)",num_fmt="0.0") })

  wb <- .try("fig22 internet por 1000", wb, { s<-"internet_2025"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"por cada 1.000 habitantes"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_int1000",df,"Municipio","V",tema$navy,"Líneas de internet fijo por 1.000 hab.",num_fmt="0.0") })

  wb <- .try("fig23 proporcion fibra", wb, { s<-"internet_2025"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"proporcion de lineas sobre fibra"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_fibra",df,"Municipio","V",tema$navy,"Proporción de líneas sobre fibra óptica",num_fmt="0.0%") })

  wb <- .try("fig24 deficit cualitativo", wb, { s<-"deficit_vivienda"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"deficit cualitativo"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_defcual",df,"Municipio","V",tema$navy,"Déficit cualitativo de vivienda",num_fmt="0.0%") })

  wb <- .try("fig25 deficit cuantitativo", wb, { s<-"deficit_vivienda"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"deficit cuantitativo"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_defcuan",df,"Municipio","V",tema$blue,"Déficit cuantitativo de vivienda",num_fmt="0.0%") })

  # -- Tablas --
  wb <- .try("tabla fig13 catastro", wb, estilo_tabla(wb,"catastro",
        formats=list("avaluo"="#,##0","proporcion"="0.0%")))
  wb <- .try("tabla fig26 servicios publicos", wb, estilo_tabla(wb,"servicios_publicos",
        formats=list("cobertura"="0.0%")))
  wb
}
