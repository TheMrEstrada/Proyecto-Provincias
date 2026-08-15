# =============================================================================
# posicion_sistema.R — La provincia dentro del sistema de once
#
# Sección que se inserta en cada informe provincial para responder la pregunta
# que ese informe, por sí solo, no puede: ¿cómo se ve esta provincia al lado de
# las otras diez?
#
# Se apoya en el panel comparativo (02_Code/06_comparativo/panel_provincial.R),
# de modo que la posición que aquí se afirma es exactamente la misma que publica
# el documento comparativo. Dos textos distintos, una sola fuente.
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

#' Puestos de una provincia en todos los indicadores con orientación normativa.
.puestos_de <- function(panel, id) {
  pos <- tabla_posiciones(panel)
  if (is.null(pos) || !nrow(pos)) return(NULL)
  nombre <- panel$provincia[panel$id_provincia == id]
  p <- pos[pos$provincia == nombre, ]
  p[order(p$puesto), ]
}

#' Sección «La Provincia en el sistema provincial».
seccion_posicion_sistema <- function(prov, ctx, panel) {
  fila <- panel[panel$id_provincia == prov$id, ]
  if (!nrow(fila)) return(character(0))
  n <- nrow(panel)
  p <- .puestos_de(panel, prov$id)
  if (is.null(p) || !nrow(p)) return(character(0))

  cob <- cobertura_sistema(panel)
  rank_pob <- rank(-panel$poblacion)[panel$id_provincia == prov$id]
  rank_area <- rank(-panel$area_km2)[panel$id_provincia == prov$id]
  mediana <- stats::median(p$puesto)
  medianas <- vapply(panel$id_provincia, function(i) {
    q <- .puestos_de(panel, i); if (is.null(q)) NA_real_ else stats::median(q$puesto)
  }, numeric(1))
  rank_global <- rank(medianas, ties.method = "min")[panel$id_provincia == prov$id]

  fuertes <- utils::head(p, 3)
  debiles <- utils::tail(p, 3)
  debiles <- debiles[order(-debiles$puesto), ]

  .p(
    sprintf(paste(
      "La Provincia %s es una de las once Provincias Administrativas y de",
      "Planificación de Antioquia. En conjunto, esas once agrupan %d de los %d",
      "municipios del departamento, el %s de su población y el %s de su",
      "territorio; los %d municipios restantes no pertenecen a ningún esquema",
      "asociativo."),
      prov$etiqueta, cob$municipios_provincia, cob$municipios_departamento,
      pct_co(cob$poblacion_provincias / cob$poblacion_departamento * 100, dec = 1),
      pct_co(cob$area_provincias / cob$area_departamento * 100, dec = 1),
      cob$municipios_departamento - cob$municipios_provincia),

    sprintf(paste(
      "Dentro de ese sistema, esta Provincia ocupa el puesto %d de %d en",
      "población y el %d de %d en extensión, con %d municipios. Tomando su",
      "puesto mediano en los %d indicadores comparables, se sitúa en el lugar",
      "%d de %d del conjunto."),
      as.integer(rank_pob), n, as.integer(rank_area), n, ctx$n,
      nrow(p), as.integer(rank_global), n),

    sprintf(paste(
      "Su posición no es uniforme. Donde mejor se sitúa es en %s. Donde peor,",
      "en %s. Esa asimetría es lo que distingue a esta Provincia de sus pares y",
      "lo que el Plan Estratégico debería tener en cuenta al priorizar: hay",
      "dimensiones en las que puede aportar experiencia al sistema y otras en",
      "las que le conviene aprender de él."),
      # Sin tolower(): las etiquetas llevan siglas (IRCA, IMCA, ICM, NBI) que
      # en minúscula dejan de reconocerse. Y el puesto va tras coma, no entre
      # paréntesis, porque varias etiquetas ya traen los suyos.
      y_lista(sprintf("%s, puesto %d", fuertes$indicador,
                      as.integer(fuertes$puesto))),
      y_lista(sprintf("%s, puesto %d", debiles$indicador,
                      as.integer(debiles$puesto)))),

    paste(
      "El documento comparativo del proyecto —«Las once provincias de",
      "Antioquia, comparadas»— desarrolla esta lectura para todo el sistema y",
      "recoge las figuras que la sostienen.")
  )
}
