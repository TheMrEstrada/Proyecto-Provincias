# fig/09_salud.R
figuras_salud <- function(wb) {
  A <- function(full, key, niv) agg_valor(full, key, niv)

  # fig71 composición SGSSS: apilada 100%, etiquetas de datos BLANCAS
  wb <- .try("fig71 aseguramiento SGSSS", wb, { s<-"aseguramiento_sgsss"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"),
                   Contributivo=pick(d,"% afiliados regimen contributivo"),
                   Subsidiado=pick(d,"% afiliados regimen subsidiado"),
                   Especial=pick(d,"% afiliados regimen especial"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_sgsss",df,"Municipio",c("Contributivo","Subsidiado","Especial"),
             c(tema$navy,tema$blue,tema$light),"Composición de afiliados al SGSSS",grouping="percentStacked",
             label_series=c(1,2,3),num_fmt="0.0%",sort=FALSE,label_color="FFFFFF") })

  # fig72 bajo peso: barra_h + Provincia (barra #4472C4) + 2 líneas (subregión/departamento)
  wb <- .try("fig72 bajo peso", wb, { s<-"bajo_peso"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"bajo peso","provincia"); sub<-A(full,"bajo peso","subregi"); dep<-A(full,"bajo peso","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `Bajo peso al nacer`=pick(d,"bajo peso"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_bp",df,"Municipio","Bajo peso al nacer",tema$navy,"Bajo peso al nacer",
             num_fmt="0.0%", agg_bar=list(label="Provincia", value=prov, color=tema$blue),
             ref_lines=list(list(value=sub,color=tema$light,label="Subregión"),
                            list(value=dep,color=tema$gris, label="Departamento"))) })

  # fig74 ETV (dengue/malaria/leishmaniasis): agrupada, sin eje/guías
  wb <- .try("fig74 enfermedades tropicales", wb, { s<-"enfermedades_tropicales"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), Dengue=pick(d,"dengue"), Malaria=pick(d,"malaria"), Leishmaniasis=pick(d,"leishmaniasis"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_enf",df,"Municipio",c("Dengue","Malaria","Leishmaniasis"),
             c(tema$navy,tema$blue,tema$light),"Tasa por 100 mil hab. (ETV)",grouping="clustered",label_series=0,num_fmt="0.0",sort=FALSE) })

  # fig75 suicidios: columnas intento (+ Provincia) + puntos consumado (rombo) + 2 líneas horizontales
  wb <- .try("fig75 suicidios", wb, { s<-"suicidios"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"intento de suicidio","provincia"); sub<-A(full,"intento de suicidio","subregi"); dep<-A(full,"intento de suicidio","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"),
                   `Tasa de intento`=pick(d,"intento de suicidio"),
                   `Tasa de suicidio consumado`=pick(d,"suicidio consumado"), check.names=FALSE)
    enc_col_point(wb,s,.anchor(wb,s),"_f_sui",df,"Municipio","Tasa de intento",tema$navy,
                  point_col="Tasa de suicidio consumado", titulo="Intento de suicidio (barras) vs consumado (puntos)",
                  num_fmt="0.0", point_outline=tema$light, point_labels=FALSE, sort=TRUE, sort_col="Tasa de intento",
                  agg_bar=list(label="Provincia", values=prov),
                  ref_lines=list(list(value=sub,color=tema$blue,label="Subregión"),
                                 list(value=dep,color=tema$gris,label="Departamento"))) })

  # fig73 mortalidad infantil 2020-2024: tabla wide tipo heatmap por terciles
  wb <- .try("fig73 mortalidad infantil (heatmap)", wb, .heatmap_anios(wb,"mortalidad_infantil","tasa de mortalidad infantil", num_fmt="0.0"))
  wb
}
