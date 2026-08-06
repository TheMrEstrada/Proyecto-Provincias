# fig/09_salud.R
figuras_salud <- function(wb) {
  wb <- .try("fig71 aseguramiento SGSSS", wb, { s<-"aseguramiento_sgsss"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),
                   Contributivo=pick(d,"% afiliados regimen contributivo"),
                   Subsidiado=pick(d,"% afiliados regimen subsidiado"),
                   Especial=pick(d,"% afiliados regimen especial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_sgsss",df,"Municipio",c("Contributivo","Subsidiado","Especial"),
             tema$serie,"Composición de afiliados al SGSSS",grouping="percentStacked",label_series=0,num_fmt="0.0%",sort=FALSE) })

  wb <- .try("fig72 bajo peso", wb, { s<-"bajo_peso"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"bajo peso"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_bp",df,"Municipio","V",tema$navy,"Bajo peso al nacer",num_fmt="0.0%") })

  wb <- .try("fig74 enfermedades tropicales", wb, { s<-"enfermedades_tropicales"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), Dengue=pick(d,"dengue"), Malaria=pick(d,"malaria"), Leishmaniasis=pick(d,"leishmaniasis"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_enf",df,"Municipio",c("Dengue","Malaria","Leishmaniasis"),tema$serie,
             "Tasa por 100 mil hab. (ETV)",grouping="clustered",label_series=0,num_fmt="0.0",sort=FALSE) })

  wb <- .try("fig75 suicidios", wb, { s<-"suicidios"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), Intento=pick(d,"intento de suicidio"), Consumado=pick(d,"suicidio consumado"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_sui",df,"Municipio",c("Intento","Consumado"),c(tema$navy,tema$blue),
             "Intento vs suicidio consumado (100 mil hab.)",grouping="clustered",label_series=0,num_fmt="0.0",sort=FALSE) })

  wb <- .try("tabla fig73 mortalidad infantil", wb, estilo_tabla(wb,"mortalidad_infantil", formats=list("tasa"="0.0","ano"="0")))
  wb
}
