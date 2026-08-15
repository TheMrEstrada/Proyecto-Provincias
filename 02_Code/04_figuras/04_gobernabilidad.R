# =============================================================================
# 04_gobernabilidad.R — Figuras de la Sección 4: Gobernabilidad
#
# FIGURAS:
#   fig_01_mdm              — Medición de Desempeño Municipal por municipio
#   fig_02_idf              — Índice de Desempeño Fiscal por municipio
#   fig_03_ley617           — indicador de la Ley 617 (gastos func. / ICLD)
#   fig_04_icm              — Índice de Ciudades Modernas por municipio
#   fig_05_icm_dimensiones  — las seis dimensiones del ICM: provincia frente a
#                             subregión y departamento
#
# INPUTS:  la lista que devuelve 02_Code/03_tablas/04_gobernabilidad.R
# OUTPUTS: 03_Outputs/<Provincia>/04_Gobernabilidad/figuras/*.{png,pdf}
#          + las hojas "_fig_NN" del .xlsx de la sección
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Nombre de las seis dimensiones del ICM, para ejes y leyendas.
.ICM_ETIQUETAS <- c(
  pcc = "Productividad y competitividad (PCC)",
  gpi = "Gobernanza e instituciones (GPI)",
  eis = "Equidad e inclusión social (EIS)",
  cti = "Ciencia, tecnología e innovación (CTI)",
  seg = "Seguridad (SEG)",
  sos = "Sostenibilidad (SOS)"
)

#' Último año con dato en una tabla de la sección.
.ultimo_anio <- function(d, columna) {
  max(d$anio[!is.na(d[[columna]])], na.rm = TRUE)
}

#' Nombre de subregión en capitalización normal para el texto de una figura:
#' los crosswalks la guardan en MAYÚSCULAS y DISENO.md §3 prohíbe las versalitas
#' sostenidas ("Valle de Aburra", no "VALLE DE ABURRA").
.subregion_legible <- function(x) {
  stringr::str_to_title(tolower(x)) |>
    stringr::str_replace_all(c(" De " = " de ", " Del " = " del ", " Y " = " y "))
}

figuras_gobernabilidad <- function(prov, tabla) {
  message("== figuras 04 Gobernabilidad — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "04_Gobernabilidad")
  archivo <- tabla$archivo %||%
    file.path(dir_seccion(prov, "04_Gobernabilidad"), "gobernabilidad.xlsx")

  # --- fig 01: Medición de Desempeño Municipal ------------------------------
  # No lleva línea de promedio provincial: el MDM no se promedia (decisión de
  # Pablo, ver 02_Code/03_tablas/04_gobernabilidad.R). El DNP compara cada
  # municipio dentro de su grupo de capacidades iniciales.
  anio_mdm <- .ultimo_anio(tabla$mdm, "mdm")
  d_mdm <- tabla$mdm |>
    dplyr::filter(.data$anio == anio_mdm, !is.na(.data$mdm)) |>
    dplyr::select(municipio, gestion, resultados, mdm)
  lider <- d_mdm[which.max(d_mdm$mdm), ]

  p1 <- fig_barras(
    d_mdm, categoria = municipio, valor = mdm,
    resaltar = lider$municipio,
    etiqueta = function(x) num_co(x, 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s encabeza el desempeño municipal de la provincia con %s puntos",
        lider$municipio, num_co(lider$mdm, 1)
      ),
      subtitulo = sprintf(
        "Medición de Desempeño Municipal (0 a 100), %d · municipios de la provincia %s",
        anio_mdm, prov$etiqueta
      ),
      fuente = sprintf("DNP, Medición de Desempeño Municipal %d.", anio_mdm),
      nota = paste("El MDM no se promedia a escala provincial: cada municipio se",
                   "compara dentro de su grupo de capacidades iniciales.")
    )
  guardar_fig(p1, "fig_01_mdm", destino, n_barras = nrow(d_mdm))
  escribir_datos_figura(d_mdm, archivo, "fig_01")

  # --- fig 02: Índice de Desempeño Fiscal -----------------------------------
  # Tampoco se promedia (misma decisión). La línea de referencia es el umbral
  # del DNP: por debajo de 60 la entidad está en riesgo o deterioro fiscal.
  anio_idf <- .ultimo_anio(tabla$idf, "idf")
  d_idf <- tabla$idf |>
    dplyr::filter(.data$anio == anio_idf, !is.na(.data$idf)) |>
    dplyr::select(municipio, resultados, gestion, idf, rango)
  mejor_idf <- d_idf[which.max(d_idf$idf), ]
  n_riesgo <- sum(d_idf$idf < 60)

  p2 <- fig_barras(
    d_idf, categoria = municipio, valor = idf,
    resaltar = mejor_idf$municipio,
    etiqueta = function(x) num_co(x, 1),
    referencia = 60,
    etiqueta_referencia = "Umbral de riesgo fiscal: 60"
  ) +
    textos_fig(
      titulo = sprintf(
        "%d de los %d municipios de la provincia están en riesgo o deterioro fiscal",
        n_riesgo, nrow(d_idf)
      ),
      subtitulo = sprintf(
        "Índice de Desempeño Fiscal (0 a 100), %d · municipios de la provincia %s",
        anio_idf, prov$etiqueta
      ),
      fuente = sprintf("DNP, Índice de Desempeño Fiscal %d.", anio_idf),
      nota = paste("Rangos del DNP: deterioro (<40), riesgo (40-60),",
                   "vulnerable (60-70), sostenible (70-80), solvente (≥ 80).")
    )
  guardar_fig(p2, "fig_02_idf", destino, n_barras = nrow(d_idf))
  escribir_datos_figura(d_idf, archivo, "fig_02")

  # --- fig 03: indicador de la Ley 617 --------------------------------------
  # Se excluyen las entidades sin certificación (ICLD y gastos en cero): ahí el
  # 0 no es un cero real sino ausencia de dato (DISENO.md §7).
  anio_617 <- .ultimo_anio(tabla$ley617, "ind_617")
  base_617 <- dplyr::filter(tabla$ley617, .data$anio == anio_617)
  d_617 <- base_617 |>
    dplyr::filter(!is.na(.data$ind_617), !is.na(.data$icld), .data$icld > 0) |>
    dplyr::select(municipio, icld, gastos_func, ind_617, observacion)
  sin_dato <- setdiff(base_617$municipio, d_617$municipio)

  if (nrow(d_617)) {
    tope <- d_617[which.max(d_617$ind_617), ]
    nota_617 <- paste("El techo legal depende de la categoría del municipio",
                      "(80 % en las categorías cuarta a sexta).")
    if (length(sin_dato)) {
      nota_617 <- paste0(nota_617, " Se excluye ",
                         paste(sin_dato, collapse = ", "),
                         ": no procede la certificación de la entidad.")
    }

    p3 <- fig_barras(
      d_617, categoria = municipio, valor = ind_617,
      resaltar = tope$municipio,
      etiqueta = function(x) pct_co(x * 100, dec = 1)
    ) +
      textos_fig(
        titulo = sprintf(
          "%s destina el %s de sus ingresos de libre destinación a funcionamiento",
          tope$municipio, pct_co(tope$ind_617 * 100, dec = 1)
        ),
        subtitulo = sprintf(
          "Indicador de la Ley 617: gastos de funcionamiento sobre ICLD, %d · provincia %s",
          anio_617, prov$etiqueta
        ),
        fuente = sprintf("Contraloría General de la República, certificación Ley 617, %d.",
                         anio_617),
        nota = nota_617
      )
    guardar_fig(p3, "fig_03_ley617", destino, n_barras = nrow(d_617))
    escribir_datos_figura(d_617, archivo, "fig_03")
  }

  # --- fig 04: Índice de Ciudades Modernas ----------------------------------
  anio_icm <- .ultimo_anio(tabla$icm, "icm")
  icm_anio <- dplyr::filter(tabla$icm, .data$anio == anio_icm)
  d_icm <- icm_anio |>
    dplyr::filter(.data$tipo_fila == "Municipio", !is.na(.data$icm)) |>
    dplyr::select(municipio, icm, pcc, gpi, eis, cti, seg, sos)
  valor_ambito <- function(tipo, columna) {
    v <- icm_anio[[columna]][icm_anio$tipo_fila == tipo]
    if (length(v)) v[1] else NA_real_
  }
  icm_prov <- valor_ambito("Total provincia", "icm")
  icm_dep  <- valor_ambito("Total departamento", "icm")
  mejor_icm <- d_icm[which.max(d_icm$icm), ]

  p4 <- fig_barras(
    d_icm, categoria = municipio, valor = icm,
    resaltar = mejor_icm$municipio,
    etiqueta = function(x) num_co(x, 1),
    referencia = icm_prov,
    etiqueta_referencia = sprintf("Promedio provincial: %s", num_co(icm_prov, 1))
  ) +
    textos_fig(
      titulo = sprintf(
        "La provincia promedia %s puntos en el ICM, %s por debajo del departamento (%s)",
        num_co(icm_prov, 1), num_co(icm_dep - icm_prov, 1), num_co(icm_dep, 1)
      ),
      subtitulo = sprintf(
        "Índice de Ciudades Modernas (0 a 100), %d · municipios de la provincia %s",
        anio_icm, prov$etiqueta
      ),
      fuente = sprintf("DNP, Índice de Ciudades Modernas %d. Cálculos propios.", anio_icm),
      nota = "El promedio provincial pondera por la población municipal del año."
    )
  guardar_fig(p4, "fig_04_icm", destino, n_barras = nrow(d_icm))
  escribir_datos_figura(d_icm, archivo, "fig_04")

  # --- fig 05: dimensiones del ICM, provincia frente a subregión y depto. ---
  # Etiquetas cortas: la leyenda va en una sola línea y el ámbito completo
  # (nombre de la provincia y de la subregión) queda en el subtítulo.
  subreg <- .subregion_legible(subregion_dominante(prov))
  ambitos <- c("Total provincia" = "Provincia",
               "Total subregión" = "Subregión",
               "Total departamento" = "Departamento")
  d_dim <- icm_anio |>
    dplyr::filter(.data$tipo_fila %in% names(ambitos)) |>
    dplyr::select(tipo_fila, dplyr::all_of(names(.ICM_ETIQUETAS))) |>
    tidyr::pivot_longer(-tipo_fila, names_to = "dimension", values_to = "valor") |>
    dplyr::mutate(
      ambito = factor(unname(ambitos[.data$tipo_fila]), levels = unname(ambitos)),
      etiqueta_dim = stringr::str_wrap(unname(.ICM_ETIQUETAS[.data$dimension]), 24)
    )

  # Las dimensiones se ordenan por el valor provincial: el orden es información.
  orden_dim <- d_dim |>
    dplyr::filter(.data$tipo_fila == "Total provincia") |>
    dplyr::arrange(.data$valor) |>
    dplyr::pull(.data$etiqueta_dim)
  d_dim$etiqueta_dim <- factor(d_dim$etiqueta_dim, levels = orden_dim)

  brecha <- d_dim |>
    dplyr::select(tipo_fila, dimension, valor) |>
    tidyr::pivot_wider(names_from = tipo_fila, values_from = valor) |>
    dplyr::mutate(brecha = .data$`Total departamento` - .data$`Total provincia`)
  peor <- brecha[which.max(brecha$brecha), ]

  ancho_dodge <- 0.8
  p5 <- ggplot2::ggplot(
      d_dim,
      ggplot2::aes(x = .data$valor, y = .data$etiqueta_dim, fill = .data$ambito)
    ) +
    # reverse = TRUE deja la provincia arriba dentro de cada grupo, en el mismo
    # orden en que la leyenda lee los tres ámbitos.
    ggplot2::geom_col(
      width = 0.74,
      position = ggplot2::position_dodge2(width = ancho_dodge, reverse = TRUE,
                                          padding = 0)
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = num_co(.data$valor, 1)),
      position = ggplot2::position_dodge2(width = ancho_dodge, reverse = TRUE,
                                          padding = 0),
      hjust = -0.18, size = PT$valor / .pt, family = FUENTE, color = COLOR$tinta_1
    ) +
    scale_fill_provincias() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.18))) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE) +
    textos_fig(
      titulo = sprintf(
        "La mayor brecha con el departamento está en %s: %s puntos",
        tolower(sub(" \\(.*", "", .ICM_ETIQUETAS[[peor$dimension]])),
        num_co(peor$brecha, 1)
      ),
      subtitulo = sprintf(
        "Dimensiones del Índice de Ciudades Modernas (0 a 100), %d · provincia %s, subregión %s y Antioquia",
        anio_icm, prov$etiqueta, subreg
      ),
      fuente = sprintf("DNP, Índice de Ciudades Modernas %d. Cálculos propios.", anio_icm),
      nota = paste("Provincia y subregión son promedios ponderados por población;",
                   "el dato departamental es el oficial del DNP.")
    )
  guardar_fig(p5, "fig_05_icm_dimensiones", destino, n_barras = nrow(d_dim))
  escribir_datos_figura(
    dplyr::select(d_dim, ambito, dimension, valor), archivo, "fig_05"
  )

  invisible(destino)
}
