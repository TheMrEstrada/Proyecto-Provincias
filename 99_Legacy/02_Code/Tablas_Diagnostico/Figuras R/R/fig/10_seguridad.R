# fig/10_seguridad.R
figuras_seguridad <- function(wb) {
  wb <- .try("fig78 percepcion seguridad (linea)", wb, { s<-"P6_cambio_municipio"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"periodo")),,drop=FALSE]
    wide<-data.frame(Periodo=pick(d,"periodo"),
                     `Más seguro`=pick(d,"mas seguro"), `Menos seguro`=pick(d,"menos seguro"),
                     Igual=pick(d,"igual"), check.names=FALSE)
    enc_line(wb,s,.anchor(wb,s),"_f_perc",wide,"Periodo",c("Más seguro","Menos seguro","Igual"),
             titulo="Percepción de seguridad (municipio) vs año anterior",num_fmt="0.0%") })

  wb <- .try("fig79 tasa solicitudes tierras", wb, { s<-"tasas"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"tasa de solicitudes"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_tsr",df,"Municipio","V",tema$navy,"Tasa de solicitudes de restitución (1.000 hab.)",num_fmt="0.0") })

  wb <- .try("fig80 desaparecidos", wb, { s<-"desaparecidos"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"proporcion dentro de la provincia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_desap",df,"Municipio","V",tema$navy,"Proporción de personas desaparecidas",num_fmt="0.0%") })

  wb <- .try("fig81 total victimas", wb, { s<-"total_victimas"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"victimas por ocurrencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_vic",df,"Municipio","V",tema$navy,"Total de víctimas por ocurrencia",num_fmt="#,##0") })

  wb <- .try("fig82 composicion hecho victimizante", wb, { s<-"proporcion_hechos"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"proporcion sobre el total")),,drop=FALSE]
    df<-data.frame(Hecho=pick(d,"hecho victimizante"), V=pick(d,"proporcion sobre el total"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_hecho",df,"Hecho","V",tema$navy,"Composición por hecho victimizante",num_fmt="0.0%",legend=FALSE) })

  # -- Tablas --
  wb <- .try("tabla fig76 coca", wb, estilo_tabla(wb,"coca", formats=list("hectareas"="#,##0.0","%"="0.0%")))
  wb <- .try("tabla fig77 evoa", wb, estilo_tabla(wb,"evoa", formats=list("hectareas"="#,##0.0","total evoa"="#,##0.0","ano"="0")))
  wb <- .try("tabla fig83 delitos", wb, estilo_tabla(wb,"delitos", num_default="0.0"))
  wb <- .try("tabla fig84 IRV", wb, estilo_tabla(wb,"irv", formats=list("indice de riesgo"="0.000")))
  wb <- .try("tabla fig85 SRTDAF", wb, estilo_tabla(wb,"srtdaf", num_default="#,##0"))
  wb
}
