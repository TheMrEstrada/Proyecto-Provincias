# fig/10_seguridad.R
figuras_seguridad <- function(wb) {
  A <- function(full, key, niv) agg_valor(full, key, niv)

  # fig78 percepción de seguridad: 4 preguntas -> barra apilada 100% por periodo,
  #   colores y color de etiqueta por serie (contraste con el segmento).
  perc <- function(wb, s, cats, titulo) {
    d <- openxlsx2::wb_to_df(wb, s); d <- d[!is.na(pick(d, "periodo")), , drop = FALSE]
    df <- data.frame(Periodo = pick(d, "periodo"), check.names = FALSE)
    for (c in cats) df[[c]] <- as.numeric(pick(d, paste0(.norm(c), " (%)")))
    enc_hbar(wb, s, .anchor(wb, s), paste0("_f_", substr(s, 1, 6)), df, "Periodo", cats,
             c(tema$navy, tema$blue, tema$light, tema$gris), titulo,
             grouping = "percentStacked", label_series = seq_along(cats), num_fmt = "0.0%", sort = FALSE,
             label_colors = c("FFFFFF", "FFFFFF", "000000", "FFFFFF"))
  }
  wb <- .try("fig78 percepción barrio (nivel)", wb, perc(wb, "P1A_barrio",
        c("Muy seguro","Seguro","Inseguro","Muy inseguro"), "Percepción de seguridad en el barrio"))
  wb <- .try("fig78 cambio percepción barrio", wb, perc(wb, "P2_cambio_barrio",
        c("Más seguro","Menos seguro","Igual","No sabe/No responde"), "Cambio en la percepción de seguridad en el barrio (vs año anterior)"))
  wb <- .try("fig78 percepción municipio (nivel)", wb, perc(wb, "P4A_municipio",
        c("Muy seguro","Seguro","Inseguro","Muy inseguro"), "Percepción de seguridad en el municipio"))
  wb <- .try("fig78 cambio percepción municipio", wb, perc(wb, "P6_cambio_municipio",
        c("Más seguro","Menos seguro","Igual","No sabe/No responde"), "Cambio en la percepción de seguridad en el municipio (vs año anterior)"))

  # fig79 tasa solicitudes tierras: barra_h + Provincia en barras + 2 líneas, SIN leyenda
  wb <- .try("fig79 tasa solicitudes tierras", wb, { s<-"tasas"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"tasa de solicitudes","provincia"); sub<-A(full,"tasa de solicitudes","subregi"); dep<-A(full,"tasa de solicitudes","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `Tasa de solicitudes`=pick(d,"tasa de solicitudes"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_tsr",df,"Municipio","Tasa de solicitudes",tema$navy,"Tasa de solicitudes de restitución (1.000 hab.)",
             num_fmt="0.0", agg_bar=list(label="Provincia", value=prov),
             ref_lines=list(list(value=sub,color=tema$blue,label="Subregión"),
                            list(value=dep,color=tema$light,label="Departamento"))) })

  # fig80 desaparecidos: barra_h simple, sin eje/guías/leyenda
  wb <- .try("fig80 desaparecidos", wb, { s<-"desaparecidos"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"proporcion dentro de la provincia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_desap",df,"Municipio","V",tema$navy,"Proporción de personas desaparecidas",num_fmt="0.0%",legend=FALSE) })

  # fig81 total víctimas: barra_h simple, sin eje/guías, título corregido
  wb <- .try("fig81 total victimas", wb, { s<-"total_victimas"; d<-leer_municipios(wb,s)
    df<-data.frame(Municipio=pick(d,"municipio"), V=pick(d,"victimas por ocurrencia"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_vic",df,"Municipio","V",tema$navy,"Total de víctimas del conflicto armado por municipio en la PAP",num_fmt="#,##0",legend=FALSE) })

  # fig82 composición por hecho victimizante: barra_h, sin eje/guías, % con 2 decimales
  wb <- .try("fig82 composicion hecho victimizante", wb, { s<-"proporcion_hechos"; d<-openxlsx2::wb_to_df(wb,s)
    d<-d[!is.na(pick(d,"proporcion sobre el total")) & !grepl("^total", .norm(pick(d,"hecho victimizante"))),,drop=FALSE]
    df<-data.frame(Hecho=pick(d,"hecho victimizante"), V=pick(d,"proporcion sobre el total"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_hecho",df,"Hecho","V",tema$navy,"Composición por hecho victimizante",num_fmt="0.00%",legend=FALSE) })

  # -- Tablas --
  wb <- .try("tabla fig76 coca", wb, estilo_tabla(wb,"coca", formats=list("hectareas"="#,##0.0","%"="0.0%")))
  wb <- .try("tabla fig77 evoa ultimo anio", wb, { .hoja_ultimo_anio(wb,"evoa") })
  wb <- .try("tabla fig77 evoa estilo", wb, estilo_tabla(wb,"evoa", formats=list("hectareas"="#,##0.0","total evoa"="#,##0.0","ano"="0")))
  wb <- .try("tabla fig83 delitos", wb, estilo_tabla(wb,"delitos", num_default="0.0"))
  wb <- .try("tabla fig84 IRV", wb, estilo_tabla(wb,"irv", formats=list("indice de riesgo"="0.000")))
  wb <- .try("tabla fig85 SRTDAF", wb, estilo_tabla(wb,"srtdaf", num_default="#,##0"))
  wb
}
