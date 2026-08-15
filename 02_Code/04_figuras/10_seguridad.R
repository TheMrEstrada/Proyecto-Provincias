# =============================================================================
# 10_seguridad.R — Figuras de la Sección 10: Seguridad
#
# FIGURAS:
#   fig_01_percepcion_seguridad     — percepción de inseguridad en el barrio o
#                                     vereda y en el municipio, 2018-2025
#   fig_02_restitucion_tierras      — tasa de solicitudes de restitución de
#                                     tierras por cada 1.000 habitantes
#   fig_03_personas_desaparecidas   — distribución municipal de las personas
#                                     dadas por desaparecidas
#   fig_04_victimas_ocurrencia      — victimizaciones registradas por municipio
#   fig_05_hechos_victimizantes     — composición por hecho victimizante
#
# Son datos sensibles (víctimas, desapariciones): los títulos describen lo que
# muestran los datos y evitan cualquier lectura dramatizada.
#
# INPUTS:  la lista de hojas que devuelve 02_Code/03_tablas/10_seguridad.R
# OUTPUTS: 03_Outputs/<Provincia>/10_Seguridad/figuras/*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Fuentes de la sección ----------------------------------------------------
FUENTE_RUV       <- "Registro Único de Víctimas (RUV), Unidad para las Víctimas (2026)."
FUENTE_UBPD      <- paste("Unidad de Búsqueda de Personas dadas por Desaparecidas",
                          "(UBPD), Portal de Datos (2026).")
FUENTE_URT       <- paste("Unidad de Restitución de Tierras (URT), acumulado a 2026;",
                          "DANE, proyecciones de población 2025.")
FUENTE_ENCUESTA  <- paste("Gobernación de Antioquia, encuesta de percepción",
                          "ciudadana 2018-2025.")

# Nombres cortos de los hechos victimizantes: los del RUV no caben en el eje.
# Se emparejan sin tildes ni mayúsculas para no depender de cómo los escriba
# la entrega del año.
HECHOS_CORTOS <- c(
  "abandono o despojo forzado de tierras" = "Abandono o despojo de tierras",
  "acto terrorista / atentados / combates / enfrentamientos / hostigamientos" =
    "Acto terrorista/atentados/combates",
  "amenaza (conflicto)" = "Amenaza",
  "confinamiento (conflicto)" = "Confinamiento",
  "delitos contra la libertad y la integridad sexual en desarrollo del conflicto armado" =
    "Delitos contra libertad/integridad sexual",
  "desaparicion forzada" = "Desaparición forzada",
  "desplazamiento forzado" = "Desplazamiento forzado",
  "homicidio (conflicto)" = "Homicidio",
  "lesiones personales fisicas" = "Lesiones personales físicas",
  "lesiones personales psicologicas" = "Lesiones personales psicológicas",
  "minas antipersonal, municion sin explotar y artefacto explosivo improvisado" =
    "Minas antipersonal/MUSE",
  "perdida de bienes muebles o inmuebles" = "Pérdida de bienes muebles/inmuebles",
  "secuestro (conflicto)" = "Secuestro",
  "sin informacion (conflicto)" = "Sin información",
  "tortura (conflicto)" = "Tortura",
  "vinculacion de ninos ninas y adolescentes a actividades relacionadas con grupos armados" =
    "Vinculación de NNA a grupos armados"
)

#' Nombre corto de un hecho victimizante; si no está en la lista, se limpia el
#' sufijo "(Conflicto)" y se recorta.
.hecho_corto <- function(x) {
  clave <- norm_txt(x)
  corto <- unname(HECHOS_CORTOS[clave])
  crudo <- stringr::str_squish(stringr::str_remove(x, "\\s*\\(Conflicto\\)"))
  ifelse(is.na(corto), stringr::str_trunc(crudo, 42), corto)
}

#' Nombre de subregión para mostrar: los crosswalks la guardan en MAYÚSCULAS y
#' así grita dentro de un título. Se capitaliza cada palabra dejando en
#' minúscula las preposiciones ("VALLE DE ABURRA" -> "Valle de Aburra"), que es
#' lo que str_to_title() haría mal.
.subregion_visible <- function(x) {
  menores <- c("de", "del", "la", "las", "los", "y")
  vapply(strsplit(tolower(x), " ", fixed = TRUE), function(palabras) {
    capitalizadas <- ifelse(
      palabras %in% menores & seq_along(palabras) > 1,
      palabras,
      paste0(toupper(substr(palabras, 1, 1)), substr(palabras, 2, nchar(palabras)))
    )
    paste(capitalizadas, collapse = " ")
  }, character(1))
}

#' Valor de una fila agregada de la tabla (NA si esa fila no existe).
.agregado <- function(tabla, tipo, columna) {
  v <- tabla[[columna]][tabla$tipo_fila == tipo]
  if (length(v)) v[1] else NA_real_
}

# --- Bloque: percepción de seguridad ------------------------------------------
# Serie de tiempo con dos ámbitos (barrio o vereda / municipio). La encuesta es
# representativa a nivel de SUBREGIÓN, no de provincia; el subtítulo lo dice.

.fig_percepcion <- function(prov, tabla, destino, archivo) {
  barrio    <- tabla$P1A_barrio
  municipio <- tabla$P4A_municipio
  if (is.null(barrio) || is.null(municipio)) {
    message("  [aviso] Sin hojas de percepción: se omite fig_01.")
    return(invisible(NULL))
  }

  # La pregunta tiene cuatro categorías; la figura resume las dos negativas.
  inseguridad <- function(d, ambito) {
    data.frame(
      periodo = d$periodo,
      orden   = seq_len(nrow(d)),
      ambito  = ambito,
      valor   = d$inseguro + d$muy_inseguro,
      n_resp  = d$n_resp,
      stringsAsFactors = FALSE
    )
  }
  d <- dplyr::bind_rows(
    inseguridad(barrio,    "En su barrio o vereda"),
    inseguridad(municipio, "En su municipio")
  )
  d$periodo <- factor(d$periodo, levels = barrio$periodo)
  d$ambito  <- factor(d$ambito, levels = c("En su barrio o vereda", "En su municipio"))

  # Etiquetas directas en el primer y el último punto de cada serie (DISENO §5).
  # La serie de arriba lleva la etiqueta encima y la de abajo debajo: cuando
  # las dos curvas se juntan (pasa en varias provincias) si no, se solapan.
  extremos <- d |>
    dplyr::group_by(.data$ambito) |>
    dplyr::filter(.data$orden %in% range(.data$orden)) |>
    dplyr::group_by(.data$orden) |>
    dplyr::mutate(vjust = ifelse(.data$valor == max(.data$valor), -1.1, 2.0)) |>
    dplyr::ungroup()

  ultimo <- dplyr::filter(d, .data$ambito == "En su municipio",
                          .data$orden == max(.data$orden))
  subreg <- .subregion_visible(barrio$subregion[1])

  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$periodo, y = .data$valor,
                                       group = .data$ambito, color = .data$ambito)) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::geom_point(data = extremos, size = 1.6) +
    ggplot2::geom_text(
      data = extremos,
      ggplot2::aes(label = pct_co(.data$valor * 100, dec = 1), vjust = .data$vjust),
      size = PT$valor / .pt, family = FUENTE,
      color = COLOR$tinta_1, show.legend = FALSE
    ) +
    scale_color_provincias() +
    ggplot2::scale_y_continuous(
      limits = c(0, max(d$valor, na.rm = TRUE) * 1.35),
      # Los valores son proporciones (0-1): hay que llevarlos a % antes de
      # formatear, porque pct_co() no reescala.
      labels = function(x) pct_co(x * 100, dec = 0),
      expand = ggplot2::expansion(mult = c(0, 0.02))
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    # Sin recorte: una etiqueta puede caer justo por debajo del punto más bajo.
    ggplot2::coord_cartesian(clip = "off") +
    theme_provincias(grilla = "y") +
    textos_fig(
      titulo = sprintf(
        "En %s, %s de las personas de la subregión %s declaró sentirse insegura en su municipio",
        ultimo$periodo, pct_co(ultimo$valor * 100, dec = 1), subreg
      ),
      subtitulo = sprintf(
        paste("Porcentaje ponderado de respuestas «inseguro» o «muy inseguro», por periodo.",
              "La encuesta es representativa por subregión, no por provincia: los datos",
              "corresponden a la subregión %s, donde está la mayoría de municipios de la provincia %s."),
        subreg, prov$etiqueta
      ),
      fuente = FUENTE_ENCUESTA,
      nota = sprintf(
        "Cálculos propios con el factor de ponderación. Entre %s y %s respuestas por periodo.",
        num_co(min(d$n_resp), 0), num_co(max(d$n_resp), 0)
      )
    )

  guardar_fig(p, "fig_01_percepcion_seguridad", destino, alto = 8)
  escribir_datos_figura(
    d[, c("periodo", "ambito", "valor", "n_resp")], archivo, "fig_01"
  )
}

# --- Bloque: restitución de tierras -------------------------------------------

.fig_restitucion <- function(prov, tabla, destino, archivo) {
  d <- tabla$tasas
  municipios <- dplyr::filter(d, .data$tipo_fila == "Municipio", !is.na(.data$tasa_solicitudes))
  if (nrow(municipios) == 0) {
    message("  [aviso] Sin municipios con tasa de restitución: se omite fig_02.")
    return(invisible(NULL))
  }

  foco   <- municipios[which.max(municipios$tasa_solicitudes), ]
  t_prov <- .agregado(d, "Total provincia", "tasa_solicitudes")
  t_sub  <- .agregado(d, "Total subregión", "tasa_solicitudes")
  t_dep  <- .agregado(d, "Total departamento", "tasa_solicitudes")
  n_prov <- .agregado(d, "Total provincia", "n_solicitudes")

  p <- fig_barras(
    municipios, categoria = municipio, valor = tasa_solicitudes,
    resaltar = foco$municipio,
    etiqueta = function(x) num_co(x, 1),
    referencia = t_prov,
    etiqueta_referencia = paste0("Provincia: ", num_co(t_prov, 1))
  ) +
    textos_fig(
      titulo = sprintf(
        "%s registra la mayor tasa de solicitudes de restitución de tierras de la provincia: %s por cada 1.000 habitantes",
        foco$municipio, num_co(foco$tasa_solicitudes, 1)
      ),
      subtitulo = sprintf(
        paste("Solicitudes de inscripción en el Registro de Tierras Despojadas y Abandonadas",
              "Forzosamente por cada 1.000 habitantes (acumulado histórico; población proyectada 2025).",
              "Municipios de la provincia %s. Tasa agregada: provincia %s, subregión %s, Antioquia %s."),
        prov$etiqueta, num_co(t_prov, 1), num_co(t_sub, 1), num_co(t_dep, 1)
      ),
      fuente = FUENTE_URT,
      nota = sprintf("Cálculos propios. Total provincial: %s solicitudes.",
                     num_co(n_prov, 0))
    )

  guardar_fig(p, "fig_02_restitucion_tierras", destino, n_barras = nrow(municipios))
  escribir_datos_figura(
    municipios[, c("municipio", "n_solicitudes", "pob", "tasa_solicitudes")],
    archivo, "fig_02"
  )
}

# --- Bloque: personas dadas por desaparecidas ---------------------------------

.fig_desaparecidos <- function(prov, tabla, destino, archivo) {
  d <- tabla$desaparecidos
  municipios <- dplyr::filter(d, .data$tipo_fila == "Municipio", !is.na(.data$desaparecidos))
  if (nrow(municipios) == 0) {
    message("  [aviso] Sin registros de personas desaparecidas: se omite fig_03.")
    return(invisible(NULL))
  }

  foco  <- municipios[which.max(municipios$prop_desaparecidos), ]
  total <- .agregado(d, "Total provincia", "desaparecidos")

  p <- fig_barras(
    municipios, categoria = municipio, valor = prop_desaparecidos,
    resaltar = foco$municipio,
    etiqueta = function(x) pct_co(x * 100, dec = 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s concentra el %s de las personas dadas por desaparecidas registradas en la provincia",
        foco$municipio, pct_co(foco$prop_desaparecidos * 100, dec = 0)
      ),
      subtitulo = sprintf(
        paste("Distribución por municipio de las %s personas dadas por desaparecidas",
              "con lugar de ocurrencia en la provincia %s. Registro acumulado."),
        num_co(total, 0), prov$etiqueta
      ),
      fuente = FUENTE_UBPD,
      nota = "Cálculos propios."
    )

  guardar_fig(p, "fig_03_personas_desaparecidas", destino, n_barras = nrow(municipios))
  escribir_datos_figura(
    municipios[, c("municipio", "desaparecidos", "prop_desaparecidos")], archivo, "fig_03"
  )
}

# --- Bloque: víctimas del conflicto armado ------------------------------------
# Dos figuras del mismo insumo: el volumen por municipio y la composición por
# hecho. Las cifras son victimizaciones (una persona puede aparecer en varios
# hechos), y así se advierte en la nota.

NOTA_VICTIMIZACIONES <- paste(
  "Cálculos propios. Una persona puede estar registrada en más de un hecho:",
  "la suma cuenta victimizaciones, no personas."
)

.fig_victimas <- function(prov, tabla, destino, archivo) {
  d <- tabla$total_victimas
  municipios <- dplyr::filter(d, .data$tipo_fila == "Municipio", !is.na(.data$victimas_ocurrencia))
  if (nrow(municipios) == 0) {
    message("  [aviso] Sin registros de víctimas por municipio: se omite fig_04.")
    return(invisible(NULL))
  }

  foco  <- municipios[which.max(municipios$victimas_ocurrencia), ]
  total <- .agregado(d, "Total provincia", "victimas_ocurrencia")

  p <- fig_barras(
    municipios, categoria = municipio, valor = victimas_ocurrencia,
    resaltar = foco$municipio,
    etiqueta = function(x) num_co(x, 0)
  ) +
    textos_fig(
      titulo = sprintf(
        "%s reúne el mayor número de victimizaciones registradas en la provincia: %s",
        foco$municipio, num_co(foco$victimas_ocurrencia, 0)
      ),
      subtitulo = sprintf(
        paste("Víctimas por ocurrencia, sumadas sobre todos los hechos victimizantes del",
              "conflicto armado. Municipios de la provincia %s. Total provincial: %s."),
        prov$etiqueta, num_co(total, 0)
      ),
      fuente = FUENTE_RUV,
      nota = NOTA_VICTIMIZACIONES
    )

  guardar_fig(p, "fig_04_victimas_ocurrencia", destino, n_barras = nrow(municipios))
  escribir_datos_figura(
    municipios[, c("municipio", "victimas_ocurrencia")], archivo, "fig_04"
  )
}

.fig_hechos <- function(prov, tabla, destino, archivo) {
  d <- dplyr::filter(tabla$proporcion_hechos, .data$tipo_fila == "Hecho")
  if (nrow(d) == 0) {
    message("  [aviso] Sin composición por hecho victimizante: se omite fig_05.")
    return(invisible(NULL))
  }
  d$hecho <- .hecho_corto(d$hecho_victim)

  foco  <- d[which.max(d$proporcion_pct), ]
  total <- .agregado(tabla$proporcion_hechos, "Total provincia", "victimas_ocurrencia")

  p <- fig_barras(
    d, categoria = hecho, valor = proporcion_pct,
    resaltar = foco$hecho,
    etiqueta = function(x) pct_co(x * 100, dec = 1)
  ) +
    textos_fig(
      titulo = sprintf(
        "El %s de las victimizaciones registradas en la provincia corresponde a %s",
        pct_co(foco$proporcion_pct * 100, dec = 0), tolower(foco$hecho)
      ),
      subtitulo = sprintf(
        paste("Participación de cada hecho victimizante en las %s víctimas por ocurrencia",
              "registradas en la provincia %s."),
        num_co(total, 0), prov$etiqueta
      ),
      fuente = FUENTE_RUV,
      nota = paste(NOTA_VICTIMIZACIONES,
                   "El catálogo pedía una torta; se sustituye por barras ordenadas (DISENO.md §5).")
    )

  guardar_fig(p, "fig_05_hechos_victimizantes", destino, n_barras = nrow(d))
  escribir_datos_figura(
    d[, c("hecho", "victimas_ocurrencia", "proporcion_pct")], archivo, "fig_05"
  )
}

# --- Orquestador de las figuras de la sección ---------------------------------

figuras_seguridad <- function(prov, tabla) {
  message("== figuras 10 Seguridad — ", prov$etiqueta, " ==")
  destino <- dir_figuras(prov, "10_Seguridad")
  archivo <- tabla$archivo %||%
    file.path(dir_seccion(prov, "10_Seguridad"), "seguridad.xlsx")

  .fig_percepcion(prov, tabla, destino, archivo)
  .fig_restitucion(prov, tabla, destino, archivo)
  .fig_desaparecidos(prov, tabla, destino, archivo)
  .fig_victimas(prov, tabla, destino, archivo)
  .fig_hechos(prov, tabla, destino, archivo)

  invisible(destino)
}
