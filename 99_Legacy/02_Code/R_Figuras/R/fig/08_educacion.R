# fig/08_educacion.R
figuras_educacion <- function(wb) {
  s <- "educacion"
  A <- function(full, key, niv) agg_valor(full, key, niv)
  # 3 líneas de referencia (provincia/subregión/departamento) de la variable dada
  refs3 <- function(full, col) list(
    list(value=A(full,col,"provincia"),    color=tema$blue,  label="Provincia"),
    list(value=A(full,col,"subregi"),      color=tema$light, label="Subregión"),
    list(value=A(full,col,"departamento"), color=tema$gris,  label="Departamento"))

  wb <- .try("fig68 cobertura neta", wb, { full<-ultimo_anio(openxlsx2::wb_to_df(wb,s)); d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), `Cobertura neta`=pick(d,"cobertura neta"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,0),"_f_cob",df,"Municipio","Cobertura neta",tema$navy,"Cobertura neta en educación",
             num_fmt="0.0%", ref_lines=refs3(full,"cobertura neta")) })

  wb <- .try("fig69 desercion", wb, { full<-ultimo_anio(openxlsx2::wb_to_df(wb,s)); d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), `Tasa de deserción`=pick(d,"desercion"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_des",df,"Municipio","Tasa de deserción",tema$navy,"Deserción escolar",
             num_fmt="0.0%", ref_lines=refs3(full,"desercion")) })

  wb <- .try("fig70 repitencia", wb, { full<-ultimo_anio(openxlsx2::wb_to_df(wb,s)); d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), `Tasa de repitencia`=pick(d,"repitencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,2),"_f_rep",df,"Municipio","Tasa de repitencia",tema$navy,"Repitencia escolar",
             num_fmt="0.0%", ref_lines=refs3(full,"repitencia")) })
  wb
}
