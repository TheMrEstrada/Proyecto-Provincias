# fig/07_ambiental.R  (fig62 clima = fuera de alcance)
figuras_ambiental <- function(wb) {
  A <- function(full, key, niv) agg_valor(full, key, niv)

  # fig65 pérdida de cobertura: barra_h (municipios) + 3 líneas de referencia
  #   verticales (provincia/subregión/departamento), sin eje/guías.
  wb <- .try("fig65 perdida cobertura", wb, { s<-"perdida_cobertura"; full<-openxlsx2::wb_to_df(wb,s); d<-leer_municipios(wb,s)
    prov<-A(full,"perdida de cobertura","provincia"); sub<-A(full,"perdida de cobertura","subregi"); dep<-A(full,"perdida de cobertura","departamento")
    df<-data.frame(Municipio=pick(d,"municipio"), `Pérdida de cobertura`=pick(d,"perdida de cobertura"), check.names=FALSE)
    enc_hbar(wb,s,.anchor(wb,s),"_f_cob",df,"Municipio","Pérdida de cobertura",tema$navy,
             "Pérdida de cobertura arbórea 2001-2023", num_fmt="0.0%",
             ref_lines=list(list(value=prov,color=tema$blue, label="Provincia"),
                            list(value=sub, color=tema$light,label="Subregión"),
                            list(value=dep, color=tema$navy, label="Departamento"))) })

  # fig67 IMRC: dos rankings independientes lado a lado (exceso y déficit),
  #   cada uno con su propio orden de municipios (sin match por fila).
  wb <- .try("fig67 IMRC (reestructura ranking)", wb, { s<-"imrc"; d<-leer_municipios(wb,s)
    mun<-pick(d,"municipio"); ex<-as.numeric(pick(d,"exceso de lluvias")); de<-as.numeric(pick(d,"deficit de lluvias"))
    oe<-order(ex, decreasing=TRUE); od<-order(de, decreasing=TRUE)
    tab<-data.frame(`Municipio (exceso)`=mun[oe], `IMRC Exceso de lluvias`=round(ex[oe],2),
                    `Municipio (déficit)`=mun[od], `IMRC Déficit de lluvias`=round(de[od],2), check.names=FALSE)
    wb2<-.hoja_reescribir(wb, s, tab)
    estilo_tabla(wb2, s, formats=list("imrc"="0.0"), hide_cols=character(0)) })

  # -- Tablas --
  wb <- .try("tabla fig63 areas protegidas", wb, estilo_tabla(wb,"detalle", formats=list("area"="#,##0.00","participacion"="0.0%")))
  wb <- .try("tabla fig64 IRCA", wb, { .hoja_ultimo_anio(wb,"irca") })
  wb <- .try("tabla fig64 estilo", wb, estilo_tabla(wb,"irca", formats=list("irca"="0.0","ano"="0")))
  wb <- .try("tabla fig66 desastres", wb, estilo_tabla(wb,"desastres_selectos", num_default="#,##0"))
  wb
}
