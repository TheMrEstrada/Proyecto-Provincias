# fig/08_educacion.R
figuras_educacion <- function(wb) {
  s <- "educacion"
  wb <- .try("fig68 cobertura neta", wb, { d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"cobertura neta"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,0),"_f_cob",df,"Municipio","V",tema$navy,"Cobertura neta en educación",num_fmt="0.0%") })
  wb <- .try("fig69 desercion", wb, { d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"desercion"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,1),"_f_des",df,"Municipio","V",tema$navy,"Deserción escolar",num_fmt="0.0%") })
  wb <- .try("fig70 repitencia", wb, { d<-ultimo_anio(leer_municipios(wb,s))
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"repitencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s,2),"_f_rep",df,"Municipio","V",tema$navy,"Repitencia escolar",num_fmt="0.0%") })
  wb
}
