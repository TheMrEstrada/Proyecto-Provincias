# =============================================================================
# 03_ordenamiento.R — Figuras de la Sección 3: Ordenamiento del territorio
#
# FIGURAS (una por bloque temático de la sección; ver el orden en el .do):
#   fig_01_uso_suelo_rural          predios rurales con uso adecuado del suelo
#   fig_02_catastro_avaluo_rural    peso del suelo rural en el avalúo catastral
#   fig_03_vias_area                km de vía por km², por jerarquía de la vía
#   fig_04_vias_habitantes          km de vía por 1.000 hab., por jerarquía
#   fig_05_deficit_cuantitativo     déficit cuantitativo de vivienda 2023
#   fig_06_deficit_cualitativo      déficit cualitativo de vivienda 2023
#   fig_07_servicios_publicos       coberturas ECV: provincia vs departamento
#   fig_08_imca_dimensiones         IMCA por dimensión: provincia vs subregión
#   fig_09_imca_adopcion_tic        IMCA adopción TIC por municipio
#   fig_10_gobierno_digital         Índice de Gobierno Digital por municipio
#   fig_11_gobierno_digital_componentes  componentes FURAG de la provincia
#   fig_12_tti_edsup                tránsito inmediato a la educación superior
#   fig_13_internet_1000hab         líneas de internet fijo por 1.000 hab.
#   fig_14_internet_fibra           proporción de líneas sobre fibra óptica
#
# INPUTS:  las hojas que produce 02_Code/03_tablas/03_ordenamiento.R
# OUTPUTS: 03_Outputs/<Provincia>/03_Ordenamiento/figuras/*.{png,pdf}
#          + una hoja `_fig_NN` por figura en ordenamiento.xlsx (DISENO.md §8)
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Utilidades locales -------------------------------------------------------

#' Filas de municipio de una hoja (las agregadas van sin código DANE).
.solo_municipios <- function(tabla) dplyr::filter(tabla, !is.na(.data$ind_mpio))

#' Valor de una columna en la fila agregada del tipo indicado, o NULL si la hoja
#' no trae esa fila (p. ej. uso del suelo, que no lleva agregados).
.valor_fila <- function(tabla, columna, tipo) {
  f <- dplyr::filter(tabla, .data$tipo_fila == tipo)
  if (nrow(f) == 0 || is.na(f[[columna]][1])) return(NULL)
  as.numeric(f[[columna]][1])
}

#' Barras horizontales con varias series: apiladas (composición de un total) o
#' agrupadas (comparación de dos ámbitos). Complementa fig_barras(), que solo
#' resuelve el caso de una serie.
#'
#' @param datos data.frame con las columnas `categoria`, `serie` y `valor`.
#' @param apiladas TRUE apila y etiqueta el total; FALSE agrupa y etiqueta cada
#'   barra. En las apiladas la etiqueta va fuera, en tinta primaria, y la
#'   composición la lee la leyenda (DISENO.md §2.5: el texto nunca lleva el
#'   color de la serie).
.barras_series <- function(datos, apiladas = TRUE, etiqueta = num_co) {
  d <- datos[!is.na(datos$valor), , drop = FALSE]
  d$serie <- factor(d$serie, levels = unique(datos$serie))

  totales <- stats::aggregate(valor ~ categoria, data = d, FUN = sum, na.rm = TRUE)
  orden <- totales$categoria[order(totales$valor)]
  d$categoria <- factor(d$categoria, levels = orden)
  totales$categoria <- factor(totales$categoria, levels = orden)

  ancho_grupo <- 0.78
  tope <- if (apiladas) max(totales$valor) else max(d$valor)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$valor, y = .data$categoria,
                                       fill = .data$serie))
  if (apiladas) {
    p <- p +
      ggplot2::geom_col(width = 0.68,
                        position = ggplot2::position_stack(reverse = TRUE)) +
      ggplot2::geom_text(
        data = totales,
        ggplot2::aes(x = .data$valor, y = .data$categoria,
                     label = etiqueta(.data$valor)),
        inherit.aes = FALSE, hjust = -0.15, size = PT$valor / .pt,
        family = FUENTE, color = COLOR$tinta_1
      )
  } else {
    p <- p +
      ggplot2::geom_col(width = ancho_grupo * 0.9,
                        position = ggplot2::position_dodge(width = ancho_grupo)) +
      ggplot2::geom_text(
        ggplot2::aes(label = etiqueta(.data$valor)),
        position = ggplot2::position_dodge(width = ancho_grupo),
        hjust = -0.15, size = PT$valor / .pt, family = FUENTE,
        color = COLOR$tinta_1
      )
  }

  p +
    scale_fill_provincias() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.16)),
                                limits = c(0, tope * 1.18)) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_provincias(grilla = "ninguna", eje_x_visible = FALSE)
}

#' Aire extra arriba para que el rótulo de la línea de referencia, que se dibuja
#' fuera del panel, no quede pegado al subtítulo.
.aire_referencia <- function(p) {
  p + ggplot2::theme(plot.margin = ggplot2::margin(t = 16, r = 6, b = 2, l = 2))
}

#' Etiquetas de porcentaje a partir de una fracción 0-1.
.pct <- function(dec = 0) function(x) pct_co(x * 100, dec = dec)

# =============================================================================
# BLOQUE 9 — Uso adecuado del suelo rural (POTA)
# =============================================================================

.fig_uso_suelo <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data$pct_uso_adecuado_rural)) |>
    dplyr::select(categoria = "municipio", valor = "pct_uso_adecuado_rural")
  if (nrow(d) == 0) return(invisible(NULL))

  sin_dato <- nrow(.solo_municipios(tabla)) - nrow(d)
  lider <- d[which.max(d$valor), ]
  bajos <- sum(d$valor < 1 / 3)

  titulo <- if (bajos >= ceiling(nrow(d) / 2)) {
    sprintf("En %s de %s municipios menos de un tercio de los predios rurales tiene uso adecuado del suelo",
            num_co(bajos), num_co(nrow(d)))
  } else {
    sprintf("%s encabeza el uso adecuado del suelo rural, con %s de sus predios",
            lider$categoria, pct_co(lider$valor * 100, dec = 0))
  }

  p <- fig_barras(d, categoria = categoria, valor = valor,
                  resaltar = lider$categoria, etiqueta = .pct(0)) +
    textos_fig(
      titulo = titulo,
      subtitulo = sprintf(
        "Porcentaje de predios rurales con uso adecuado del suelo, 2025 · municipios de la provincia %s",
        prov$etiqueta),
      fuente = "Gobernación de Antioquia, Plan de Ordenamiento Territorial Agropecuario (POTA), 2025. Cálculos propios.",
      nota = if (sin_dato > 0) sprintf(
        "La fuente no cubre %s municipio(s) de la provincia; se omiten del gráfico",
        num_co(sin_dato)) else NULL
    )

  guardar_fig(p, "fig_01_uso_suelo_rural", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_01")
}

# =============================================================================
# BLOQUE 4 — Catastro: peso del suelo rural en el avalúo
# =============================================================================

.fig_catastro <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data$prop_avaluo_rural)) |>
    dplyr::select(categoria = "municipio", valor = "prop_avaluo_rural")
  if (nrow(d) == 0) return(invisible(NULL))

  ref <- .valor_fila(tabla, "prop_avaluo_rural", "Total provincia")
  mayoria <- sum(d$valor > 0.5)
  lider <- d[which.max(d$valor), ]

  titulo <- if (mayoria > 0) {
    sprintf("En %s de %s municipios el suelo rural concentra más de la mitad del avalúo catastral",
            num_co(mayoria), num_co(nrow(d)))
  } else {
    sprintf("El avalúo catastral es predominantemente urbano en toda la provincia; %s es el municipio más rural (%s)",
            lider$categoria, pct_co(lider$valor * 100, dec = 0))
  }

  p <- fig_barras(
    d, categoria = categoria, valor = valor, resaltar = lider$categoria,
    etiqueta = .pct(0), referencia = ref,
    etiqueta_referencia = if (!is.null(ref)) paste0("Provincia: ", pct_co(ref * 100, dec = 0)) else NULL
  ) +
    textos_fig(
      titulo = titulo,
      subtitulo = sprintf(
        "Participación del avalúo catastral rural en el avalúo total del municipio, 2026 · provincia %s",
        prov$etiqueta),
      fuente = "Gobernación de Antioquia, catastro departamental, 2026. Cálculos propios."
    )
  if (!is.null(ref)) p <- .aire_referencia(p)

  guardar_fig(p, "fig_02_catastro_avaluo_rural", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_02")
}

# =============================================================================
# BLOQUE 3 — Kilómetros de vía (dos figuras apiladas por jerarquía)
# =============================================================================

.JERARQUIA_VIA <- c(pri = "Primaria", sec = "Secundaria", ter = "Terciaria")

.fig_vias <- function(prov, tabla, destino, archivo, prefijo, id, nombre,
                      unidad, subtitulo, decimales) {
  columnas <- paste0(prefijo, "_", names(.JERARQUIA_VIA))
  base <- .solo_municipios(tabla)
  if (nrow(base) == 0) return(invisible(NULL))

  d <- base |>
    dplyr::select("municipio", dplyr::all_of(columnas)) |>
    tidyr::pivot_longer(dplyr::all_of(columnas), names_to = "serie",
                        values_to = "valor") |>
    dplyr::mutate(
      categoria = .data$municipio,
      serie = unname(.JERARQUIA_VIA[stringr::str_remove(.data$serie,
                                                        paste0(prefijo, "_"))])
    ) |>
    dplyr::select("categoria", "serie", "valor")

  totales <- stats::aggregate(valor ~ categoria, data = d, FUN = sum, na.rm = TRUE)
  lider <- totales[which.max(totales$valor), ]

  p <- .barras_series(d, apiladas = TRUE,
                      etiqueta = function(x) num_co(x, dec = decimales)) +
    textos_fig(
      titulo = sprintf("%s tiene la mayor dotación vial de la provincia: %s %s",
                       lider$categoria, num_co(lider$valor, dec = decimales), unidad),
      subtitulo = subtitulo,
      fuente = "Gobernación de Antioquia, Anuario Estadístico (infraestructura vial). Cálculos propios.",
      nota = "La etiqueta muestra el total del municipio; el color, la jerarquía de la vía"
    )

  guardar_fig(p, nombre, destino, n_barras = nrow(totales) + 1)
  escribir_datos_figura(d, archivo, id)
}

# =============================================================================
# BLOQUE 1 — Déficit de vivienda (cuantitativo y cualitativo)
# =============================================================================

.fig_deficit <- function(prov, tabla, destino, archivo, columna, id, nombre,
                         tipo_deficit, definicion) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data[[columna]])) |>
    dplyr::select(categoria = "municipio", valor = dplyr::all_of(columna))
  if (nrow(d) == 0) return(invisible(NULL))

  ref <- .valor_fila(tabla, columna, "Total provincia")
  lider <- d[which.max(d$valor), ]

  p <- fig_barras(
    d, categoria = categoria, valor = valor, resaltar = lider$categoria,
    etiqueta = .pct(1), referencia = ref,
    etiqueta_referencia = if (!is.null(ref)) paste0("Provincia: ", pct_co(ref * 100, dec = 1)) else NULL
  ) +
    textos_fig(
      titulo = sprintf("%s tiene el mayor déficit %s de vivienda de la provincia (%s)",
                       lider$categoria, tipo_deficit, pct_co(lider$valor * 100, dec = 1)),
      subtitulo = sprintf(
        "Porcentaje de viviendas en déficit %s (%s), 2023 · provincia %s",
        tipo_deficit, definicion, prov$etiqueta),
      fuente = "Gobernación de Antioquia, déficit habitacional municipal, 2023. Cálculos propios.",
      nota = "El valor provincial es la tasa agregada (suma de viviendas en déficit sobre suma de viviendas)"
    )
  if (!is.null(ref)) p <- .aire_referencia(p)

  guardar_fig(p, nombre, destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, id)
}

# =============================================================================
# BLOQUE 2 — Acceso a servicios públicos: provincia frente al departamento
# =============================================================================

.fig_servicios <- function(prov, tabla, destino, archivo) {
  servicios <- c(
    tot_pob_energia             = "Energía",
    tot_pob_acueducto           = "Acueducto",
    tot_pob_alcantarillado      = "Alcantarillado",
    tot_pob_recoleccion_basuras = "Recolección de basuras",
    tot_pob_internet            = "Internet",
    tot_pob_gas_natural         = "Gas natural"
  )
  ambitos <- c(Provincia = "Provincia", Departamento = "Departamento")
  filas <- c(Provincia = "Provincia", Departamento = "Departamento")

  extraer <- function(tipo) {
    f <- dplyr::filter(tabla, .data$tipo_fila == tipo)
    if (nrow(f) == 0) return(NULL)
    vapply(paste0(names(servicios), "_ofi"),
           function(cl) as.numeric(f[[cl]][1]), numeric(1))
  }
  v_prov <- extraer(filas[["Provincia"]])
  v_dep  <- extraer(filas[["Departamento"]])
  if (is.null(v_prov) || is.null(v_dep)) return(invisible(NULL))

  d <- rbind(
    data.frame(categoria = unname(servicios), serie = "Provincia",
               valor = unname(v_prov), stringsAsFactors = FALSE),
    data.frame(categoria = unname(servicios), serie = "Departamento (Antioquia)",
               valor = unname(v_dep), stringsAsFactors = FALSE)
  )

  brecha <- v_dep - v_prov
  peor <- names(servicios)[which.max(brecha)]

  p <- .barras_series(d, apiladas = FALSE, etiqueta = .pct(0)) +
    textos_fig(
      titulo = sprintf("La provincia se rezaga frente al departamento sobre todo en %s (%s puntos porcentuales)",
                       tolower(servicios[[peor]]), num_co(max(brecha) * 100, dec = 0)),
      subtitulo = sprintf(
        "Porcentaje de viviendas con acceso a cada servicio público domiciliario, 2023 · provincia %s y departamento",
        prov$etiqueta),
      fuente = "DANE – Gobernación de Antioquia, Encuesta de Calidad de Vida 2023. Cálculos propios.",
      nota = "Valores oficiales de la ECV para el departamento; la provincia es el promedio ponderado por población de sus municipios"
    )

  guardar_fig(p, "fig_07_servicios_publicos", destino, n_barras = nrow(d) + 1)
  escribir_datos_figura(d, archivo, "fig_07")
}

# =============================================================================
# BLOQUE 5 — IMCA 2022
# =============================================================================

.DIM_IMCA <- c(
  imca_adop_tic        = "Adopción TIC",
  imca_capacidades     = "Capacidades",
  imca_dinam_neg       = "Dinamismo de los negocios",
  imca_infraestructura = "Infraestructura",
  imca_innovacion      = "Innovación",
  imca_instituciones   = "Instituciones",
  imca_merc_bienes     = "Mercado de bienes",
  imca_merc_laboral    = "Mercado laboral",
  imca_salud           = "Salud",
  imca_sist_financiero = "Sistema financiero",
  imca_tam_mercado     = "Tamaño del mercado"
)

.fig_imca_dimensiones <- function(prov, tabla, destino, archivo) {
  fila_prov <- dplyr::filter(tabla, .data$tipo_fila == "Total provincia")
  fila_sub  <- dplyr::filter(tabla, .data$tipo_fila == "Subregión (IMCA oficial)")
  if (nrow(fila_prov) == 0 || nrow(fila_sub) == 0) return(invisible(NULL))
  # Si la provincia toca varias subregiones se compara con la mayoritaria.
  subreg <- subregion_dominante(prov)
  fila_sub <- if (any(fila_sub$subregion == subreg)) {
    dplyr::filter(fila_sub, .data$subregion == subreg)
  } else {
    fila_sub[1, ]
  }

  valores <- function(f) vapply(names(.DIM_IMCA),
                                function(cl) as.numeric(f[[cl]][1]), numeric(1))
  v_prov <- valores(fila_prov)
  v_sub  <- valores(fila_sub)

  d <- rbind(
    data.frame(categoria = unname(.DIM_IMCA), serie = "Provincia",
               valor = unname(v_prov), stringsAsFactors = FALSE),
    data.frame(categoria = unname(.DIM_IMCA),
               serie = paste0("Subregión ", stringr::str_to_title(fila_sub$subregion[1])),
               valor = unname(v_sub), stringsAsFactors = FALSE)
  )

  debajo <- sum(v_prov < v_sub, na.rm = TRUE)
  titulo <- if (debajo > 0) {
    sprintf("La provincia queda por debajo de su subregión en %s de las %s dimensiones del IMCA",
            num_co(debajo), num_co(length(.DIM_IMCA)))
  } else {
    "La provincia iguala o supera a su subregión en todas las dimensiones del IMCA"
  }

  p <- .barras_series(d, apiladas = FALSE,
                      etiqueta = function(x) num_co(x, dec = 1)) +
    textos_fig(
      titulo = titulo,
      subtitulo = sprintf(
        "Índice Municipal de Competitividad de Antioquia por dimensión (escala 0 a 100), 2022 · provincia %s",
        prov$etiqueta),
      fuente = "Gobernación de Antioquia, Índice Municipal de Competitividad de Antioquia (IMCA), 2022. Cálculos propios.",
      nota = "El valor provincial es el promedio ponderado por población de sus municipios; el subregional es el oficial del IMCA"
    )

  guardar_fig(p, "fig_08_imca_dimensiones", destino, n_barras = nrow(d) + 1)
  escribir_datos_figura(d, archivo, "fig_08")
}

.fig_imca_tic <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data$imca_adop_tic)) |>
    dplyr::select(categoria = "municipio", valor = "imca_adop_tic")
  if (nrow(d) == 0) return(invisible(NULL))

  ref <- .valor_fila(tabla, "imca_adop_tic", "Total provincia")
  lider <- d[which.max(d$valor), ]

  p <- fig_barras(
    d, categoria = categoria, valor = valor, resaltar = lider$categoria,
    etiqueta = function(x) num_co(x, dec = 1), referencia = ref,
    etiqueta_referencia = if (!is.null(ref)) paste0("Provincia: ", num_co(ref, dec = 1)) else NULL
  ) +
    textos_fig(
      titulo = sprintf("%s concentra la adopción de TIC de la provincia (%s de 100)",
                       lider$categoria, num_co(lider$valor, dec = 1)),
      subtitulo = sprintf(
        "Dimensión de adopción de TIC del IMCA (escala 0 a 100), 2022 · municipios de la provincia %s",
        prov$etiqueta),
      fuente = "Gobernación de Antioquia, Índice Municipal de Competitividad de Antioquia (IMCA), 2022. Cálculos propios."
    )
  if (!is.null(ref)) p <- .aire_referencia(p)

  guardar_fig(p, "fig_09_imca_adopcion_tic", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_09")
}

# =============================================================================
# BLOQUE 6 — Gobierno Digital 2024 (FURAG)
# =============================================================================

.COMP_FURAG <- c(
  gobernanza               = "Gobernanza",
  innovacion_digital       = "Innovación Pública Digital",
  arquitectura             = "Arquitectura",
  seguridad_privacidad     = "Seguridad y Privacidad",
  servicios_ciudadanos     = "Servicios Ciudadanos Digitales",
  cultura_apropiacion      = "Cultura y Apropiación",
  servicios_inteligentes   = "Servicios y Procesos Inteligentes",
  estado_abierto           = "Estado Abierto",
  decisiones_datos         = "Decisiones basadas en datos",
  proyectos_transformacion = "Proyectos de Transformación Digital",
  ciudades_territorios     = "Ciudades y Territorios Inteligentes"
)

.fig_gobierno_digital <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data$gobierno_digital)) |>
    dplyr::select(categoria = "municipio", valor = "gobierno_digital")
  if (nrow(d) == 0) return(invisible(NULL))

  ref <- .valor_fila(tabla, "gobierno_digital", "Total provincia")
  lider <- d[which.max(d$valor), ]
  rezagado <- d[which.min(d$valor), ]

  p <- fig_barras(
    d, categoria = categoria, valor = valor, resaltar = lider$categoria,
    etiqueta = function(x) num_co(x, dec = 1), referencia = ref,
    etiqueta_referencia = if (!is.null(ref)) paste0("Provincia: ", num_co(ref, dec = 1)) else NULL
  ) +
    textos_fig(
      titulo = sprintf("El Gobierno Digital va de %s en %s a %s en %s: una brecha de %s puntos dentro de la misma provincia",
                       num_co(rezagado$valor, dec = 1), rezagado$categoria,
                       num_co(lider$valor, dec = 1), lider$categoria,
                       num_co(lider$valor - rezagado$valor, dec = 1)),
      subtitulo = sprintf(
        "Índice de Gobierno Digital (escala 0 a 100), 2024 · municipios de la provincia %s",
        prov$etiqueta),
      fuente = "Función Pública, FURAG — Índice de Gobierno Digital, 2024. Cálculos propios."
    )
  if (!is.null(ref)) p <- .aire_referencia(p)

  guardar_fig(p, "fig_10_gobierno_digital", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_10")
}

.fig_furag_componentes <- function(prov, tabla, destino, archivo) {
  fila <- dplyr::filter(tabla, .data$tipo_fila == "Total provincia")
  if (nrow(fila) == 0) return(invisible(NULL))

  d <- data.frame(
    categoria = unname(.COMP_FURAG),
    valor = vapply(names(.COMP_FURAG), function(cl) as.numeric(fila[[cl]][1]),
                   numeric(1)),
    stringsAsFactors = FALSE
  )
  d <- d[!is.na(d$valor), , drop = FALSE]
  if (nrow(d) == 0) return(invisible(NULL))

  debil <- d[which.min(d$valor), ]

  p <- fig_barras(d, categoria = categoria, valor = valor,
                  resaltar = debil$categoria,
                  etiqueta = function(x) num_co(x, dec = 1)) +
    textos_fig(
      titulo = sprintf("%s es el componente más débil del Gobierno Digital en la provincia (%s de 100)",
                       debil$categoria, num_co(debil$valor, dec = 1)),
      subtitulo = sprintf(
        "Componentes del Índice de Gobierno Digital (escala 0 a 100), 2024 · provincia %s",
        prov$etiqueta),
      fuente = "Función Pública, FURAG — Índice de Gobierno Digital, 2024. Cálculos propios.",
      nota = "Promedio ponderado por población de los municipios de la provincia"
    )

  guardar_fig(p, "fig_11_gobierno_digital_componentes", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_11")
}

# =============================================================================
# BLOQUE 7 — Tránsito inmediato a la educación superior
# =============================================================================

.fig_tti <- function(prov, tabla, destino, archivo) {
  d <- .solo_municipios(tabla) |>
    dplyr::filter(!is.na(.data$tti_edsup)) |>
    dplyr::select(categoria = "municipio", valor = "tti_edsup")
  if (nrow(d) == 0) return(invisible(NULL))

  ref <- .valor_fila(tabla, "tti_edsup", "Total provincia")
  lider <- d[which.max(d$valor), ]
  rezagado <- d[which.min(d$valor), ]

  p <- fig_barras(
    d, categoria = categoria, valor = valor, resaltar = lider$categoria,
    etiqueta = .pct(1), referencia = ref,
    etiqueta_referencia = if (!is.null(ref)) paste0("Provincia: ", pct_co(ref * 100, dec = 1)) else NULL
  ) +
    textos_fig(
      titulo = sprintf("En %s solo %s de los bachilleres pasa de inmediato a la educación superior, frente a %s en %s",
                       rezagado$categoria, pct_co(rezagado$valor * 100, dec = 0),
                       pct_co(lider$valor * 100, dec = 0), lider$categoria),
      subtitulo = sprintf(
        "Tasa de tránsito inmediato a la educación superior · municipios de la provincia %s",
        prov$etiqueta),
      fuente = "Gobernación de Antioquia, datalake de Educación. Cálculos propios."
    )
  if (!is.null(ref)) p <- .aire_referencia(p)

  guardar_fig(p, "fig_12_tti_edsup", destino, n_barras = nrow(d))
  escribir_datos_figura(d, archivo, "fig_12")
}

# =============================================================================
# BLOQUE 8 — Internet fijo (MinTIC 2025)
# =============================================================================

.fig_internet <- function(prov, tabla, destino, archivo) {
  base <- .solo_municipios(tabla)
  if (nrow(base) == 0) return(invisible(NULL))

  # El dato es de un trimestre, no del año completo (ver corrección 18 en
  # 03_tablas/03_ordenamiento.R); el subtítulo lo dice en vez de fijar
  # "2025". Hallazgo de Pablo (F-2-049), adoptado también aquí.
  periodo <- attr(tabla, "periodo") %||% "2025"

  # --- fig 13: líneas por cada 1.000 habitantes ------------------------------
  d1 <- base |>
    dplyr::filter(!is.na(.data$internet_1000hab)) |>
    dplyr::select(categoria = "municipio", valor = "internet_1000hab")
  ref1 <- .valor_fila(tabla, "internet_1000hab", "Total provincia")
  lider1 <- d1[which.max(d1$valor), ]

  p1 <- fig_barras(
    d1, categoria = categoria, valor = valor, resaltar = lider1$categoria,
    etiqueta = function(x) num_co(x, dec = 0), referencia = ref1,
    etiqueta_referencia = if (!is.null(ref1)) paste0("Provincia: ", num_co(ref1, dec = 0)) else NULL
  ) +
    textos_fig(
      titulo = sprintf("%s tiene %s líneas de internet fijo por cada 1.000 habitantes, el mayor acceso de la provincia",
                       lider1$categoria, num_co(lider1$valor, dec = 0)),
      subtitulo = sprintf(
        "Líneas de acceso a internet fijo por cada 1.000 habitantes, %s · municipios de la provincia %s",
        periodo, prov$etiqueta),
      fuente = "MinTIC – Comisión de Regulación de Comunicaciones (CRC), 2025. Cálculos propios.",
      nota = paste("Se cuentan los accesos activos del último trimestre, en los",
                   "cuatro paquetes de servicio que incluyen internet fijo.")
    )
  if (!is.null(ref1)) p1 <- .aire_referencia(p1)

  guardar_fig(p1, "fig_13_internet_1000hab", destino, n_barras = nrow(d1))
  escribir_datos_figura(d1, archivo, "fig_13")

  # --- fig 14: proporción de líneas sobre fibra óptica -----------------------
  d2 <- base |>
    dplyr::filter(!is.na(.data$prop_fibra)) |>
    dplyr::select(categoria = "municipio", valor = "prop_fibra")
  ref2 <- .valor_fila(tabla, "prop_fibra", "Total provincia")
  lider2 <- d2[which.max(d2$valor), ]
  mayoria <- sum(d2$valor > 0.5)
  titulo2 <- if (mayoria > 0) {
    sprintf("En %s de %s municipios la fibra óptica ya es la mayoría de las líneas de internet fijo",
            num_co(mayoria), num_co(nrow(d2)))
  } else {
    sprintf("En ningún municipio la fibra óptica llega a la mitad de las líneas de internet fijo; %s es el que más avanza (%s)",
            lider2$categoria, pct_co(lider2$valor * 100, dec = 0))
  }

  p2 <- fig_barras(
    d2, categoria = categoria, valor = valor, resaltar = lider2$categoria,
    etiqueta = .pct(0), referencia = ref2,
    etiqueta_referencia = if (!is.null(ref2)) paste0("Provincia: ", pct_co(ref2 * 100, dec = 0)) else NULL
  ) +
    textos_fig(
      titulo = titulo2,
      subtitulo = sprintf(
        "Porcentaje de líneas de internet fijo sobre fibra óptica, %s · municipios de la provincia %s",
        periodo, prov$etiqueta),
      fuente = "MinTIC – Comisión de Regulación de Comunicaciones (CRC), 2025. Cálculos propios.",
      nota = paste("El valor provincial es el total de líneas de fibra sobre el",
                   "total de líneas de la provincia, no el promedio de los",
                   "municipios. Se cuentan los accesos activos del último",
                   "trimestre, en los cuatro paquetes de servicio que incluyen",
                   "internet fijo.")
    )
  if (!is.null(ref2)) p2 <- .aire_referencia(p2)

  guardar_fig(p2, "fig_14_internet_fibra", destino, n_barras = nrow(d2))
  escribir_datos_figura(d2, archivo, "fig_14")
}

# --- Punto de entrada ---------------------------------------------------------

figuras_ordenamiento <- function(prov, tabla) {
  message("== figuras 03 Ordenamiento — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "03_Ordenamiento")
  archivo <- file.path(dir_seccion(prov, "03_Ordenamiento"), "ordenamiento.xlsx")

  .fig_uso_suelo(prov, tabla$uso_suelo_rural, destino, archivo)
  .fig_catastro(prov, tabla$catastro, destino, archivo)

  .fig_vias(
    prov, tabla$vias_area, destino, archivo, "idv", "fig_03", "fig_03_vias_area",
    "km/km²",
    sprintf("Kilómetros de vía por km² de área municipal, por jerarquía de la vía · provincia %s",
            prov$etiqueta),
    decimales = 2
  )
  .fig_vias(
    prov, tabla$vias_habitantes, destino, archivo, "vpc", "fig_04",
    "fig_04_vias_habitantes", "km por cada 1.000 habitantes",
    sprintf("Kilómetros de vía por cada 1.000 habitantes, por jerarquía de la vía · provincia %s",
            prov$etiqueta),
    decimales = 1
  )

  .fig_deficit(prov, tabla$deficit_vivienda, destino, archivo, "deficit_cuanti",
               "fig_05", "fig_05_deficit_cuantitativo", "cuantitativo",
               "hogares sin vivienda propia o en vivienda irrecuperable")
  .fig_deficit(prov, tabla$deficit_vivienda, destino, archivo, "deficit_cuali",
               "fig_06", "fig_06_deficit_cualitativo", "cualitativo",
               "viviendas con carencias subsanables")

  .fig_servicios(prov, tabla$servicios_publicos, destino, archivo)
  .fig_imca_dimensiones(prov, tabla$imca, destino, archivo)
  .fig_imca_tic(prov, tabla$imca, destino, archivo)
  .fig_gobierno_digital(prov, tabla$gobierno_digital, destino, archivo)
  .fig_furag_componentes(prov, tabla$gobierno_digital, destino, archivo)
  .fig_tti(prov, tabla$tti_edsup, destino, archivo)
  .fig_internet(prov, tabla$internet_2025, destino, archivo)

  invisible(destino)
}
