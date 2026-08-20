# =============================================================================
# 00_mapas.R — Mapas del diagnóstico provincial
#
# MAPAS (uno por pregunta de localización, no uno por indicador disponible):
#   mapa_00_localizacion        dónde queda la provincia dentro de Antioquia
#   mapa_01_area                extensión de cada municipio
#   mapa_02_densidad            densidad poblacional (hab/km²)
#   mapa_03_deficit_vivienda    déficit cuantitativo de vivienda
#   mapa_05_va_percapita        valor agregado per cápita
#   mapa_07_perdida_cobertura   pérdida de cobertura arbórea 2001-2023, como
#                               porcentaje de la cobertura de 2000
#   mapa_08_cobertura_neta      cobertura neta educativa
#   mapa_09_mortalidad_infantil tasa de mortalidad infantil
#   mapa_10_homicidios          homicidios por 100.000 habitantes
#   mapa_10_homicidios_dpto     el mismo indicador en todo el departamento
#                               (único mapa que no sale de la hoja de la
#                                provincia; ver su función más abajo)
#
# DE DÓNDE SALEN LAS CIFRAS
#   De las hojas .xlsx que ya generó la sección — nunca de los derivados ni de
#   los crudos. El mapa pinta EXACTAMENTE lo que dice la tabla publicada: si
#   recalculara, podría discrepar de ella y el informe tendría dos cifras para
#   el mismo hecho. Por eso este script corre DESPUÉS de las diez secciones.
#
#   UNA EXCEPCIÓN: mapa_10_homicidios_dpto necesita el departamento entero, que
#   ninguna hoja provincial contiene. No lo arma leyendo las once hojas —eso lo
#   hacía antes y lo dejaba truncado (F-2-035)—, sino llamando a las MISMAS
#   funciones que producen la hoja `delitos`. No recalcula: reutiliza. Es la
#   forma de cumplir la regla mientras se necesita más de lo que hay en la hoja.
#
# INPUTS:  03_Outputs/<Provincia>/<NN_Seccion>/*.xlsx
# OUTPUTS: 03_Outputs/<Provincia>/<NN_Seccion>/figuras/mapa_*.{png,pdf}
#
# ETAPA DEL PIPELINE: 4. figuras
# Diseño: 02_Code/04_figuras/DISENO.md · cartografía: 02_Code/R/03_mapas.R
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Alto de los mapas: 11 cm deja el norte de Antioquia legible al ancho de caja
# de 16 cm sin que el mapa domine la página.
ALTO_MAPA <- 11

#' Una hoja ya exportada de una sección de esta provincia.
#' Devuelve NULL —sin abortar— si la sección no se generó: un mapa que falta no
#' debe tumbar los nueve que sí se pueden hacer.
.hoja_de <- function(prov, seccion, archivo, hoja) {
  ruta <- file.path(RUTAS$outputs, prov$carpeta, seccion, archivo)
  if (!file.exists(ruta)) return(NULL)
  d <- tryCatch(openxlsx2::wb_to_df(openxlsx2::wb_load(ruta), sheet = hoja),
                error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)
  # Solo municipios: las filas de total no tienen geometría.
  d[!is.na(suppressWarnings(as.integer(d[["Código DANE"]]))), , drop = FALSE]
}

#' Última observación disponible cuando la hoja trae varios años.
.ultimo_anio <- function(d) {
  if (is.null(d) || !"Año" %in% names(d)) return(d)
  anios <- suppressWarnings(as.numeric(d[["Año"]]))
  d[!is.na(anios) & anios == max(anios, na.rm = TRUE), , drop = FALSE]
}

#' Genera un mapa, lo guarda en PNG+PDF y deja sus datos en el .xlsx de la
#' sección, igual que cualquier otra figura (DISENO.md §8).
.emitir <- function(p, id, prov, seccion, archivo, datos, columnas) {
  if (is.null(p)) return(invisible(NULL))
  guardar_fig(p, id, dir_figuras(prov, seccion), alto = ALTO_MAPA)
  escribir_datos_figura(
    datos[, intersect(columnas, names(datos)), drop = FALSE],
    file.path(dir_seccion(prov, seccion), archivo),
    sub("^mapa_", "mapa", id)
  )
  invisible(id)
}

#' Bloque de textos de un mapa.
#'
#' Igual que `textos_fig()`, pero ajustando el texto a 12,5 cm en vez de a los
#' 16 cm de ancho de caja: la leyenda vertical de la rampa ocupa unos 3 cm a la
#' derecha, y un título calculado sobre el ancho completo se saldría del papel.
.textos_mapa <- function(...) textos_fig(..., ancho_cm = 12.5)

#' El año que rotula el subtítulo, tomado de los propios datos.
.anio_de <- function(d) {
  if (is.null(d) || !"Año" %in% names(d)) return(NULL)
  a <- suppressWarnings(as.numeric(d[["Año"]]))
  if (all(is.na(a))) NULL else as.integer(max(a, na.rm = TRUE))
}

mapas_provincia <- function(prov) {
  if (!HAY_CARTOGRAFIA) {
    message("  [mapas] sin 'sf': se omiten los mapas de ", prov$etiqueta)
    return(invisible(NULL))
  }
  message("== mapas — ", prov$etiqueta, " ==")
  hechos <- character(0)

  # --- 00 Localización ------------------------------------------------------
  # El único mapa que no codifica magnitud. Va en Generalidades porque es lo
  # primero que un lector necesita: qué territorio está leyendo.
  p <- mapa_localizacion(prov) +
    .textos_mapa(
      titulo = sprintf("La provincia %s en Antioquia", prov$etiqueta),
      subtitulo = sprintf(
        "Municipios de la provincia, resto de la subregión %s y resto del departamento",
        subregion_dominante(prov)),
      fuente = "DANE, Marco Geoestadístico Nacional. Cálculos propios."
    )
  # Su dato es la composición territorial: qué municipio pertenece a qué. Se
  # guarda como cualquier otra figura para que ninguna pieza publicada quede sin
  # su hoja de respaldo.
  composicion <- crosswalk_provincias() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia")
  .emitir(p, "mapa_00_localizacion", prov, "01_Generalidades",
          "distribucion_territorial.xlsx", composicion,
          c("ind_mpio", "municipio", "subregion", "provincia"))
  hechos <- c(hechos, "mapa_00_localizacion")

  # --- 01 Extensión territorial ----------------------------------------------
  d <- .hoja_de(prov, "01_Generalidades", "distribucion_territorial.xlsx",
                "distribucion_territorial")
  if (!is.null(d)) {
    mayor <- d[which.max(suppressWarnings(as.numeric(d[["Área municipal (km²)"]]))), ]
    p <- mapa_coropletico(
      d, `Área municipal (km²)`, prov,
      titulo_leyenda = "km²", formato = function(x) num_co(x, 0)) +
      .textos_mapa(
        titulo = sprintf("%s es el municipio más extenso de la provincia",
                         mayor[["Municipio"]]),
        subtitulo = "Área municipal en kilómetros cuadrados",
        fuente = "Gobernación de Antioquia, Anuario Estadístico. Cálculos propios."
      )
    .emitir(p, "mapa_01_area", prov, "01_Generalidades",
            "distribucion_territorial.xlsx", d,
            c("Código DANE", "Municipio", "Área municipal (km²)"))
    hechos <- c(hechos, "mapa_01_area")
  }

  # --- 02 Densidad poblacional -----------------------------------------------
  d <- .hoja_de(prov, "02_Demografia", "demografia.xlsx", "poblacion")
  if (!is.null(d)) {
    p <- mapa_coropletico(
      d, `Densidad poblacional (hab/km²)`, prov,
      titulo_leyenda = "hab/km²", formato = function(x) num_co(x, 0)) +
      .textos_mapa(
        titulo = "Dónde se concentra la población de la provincia",
        subtitulo = "Habitantes por kilómetro cuadrado, proyecciones 2025",
        fuente = "DANE, proyecciones de población 2018-2042. Cálculos propios."
      )
    .emitir(p, "mapa_02_densidad", prov, "02_Demografia", "demografia.xlsx", d,
            c("Código DANE", "Municipio", "Población total",
              "Densidad poblacional (hab/km²)"))
    hechos <- c(hechos, "mapa_02_densidad")
  }

  # --- 03 Déficit de vivienda ------------------------------------------------
  d <- .hoja_de(prov, "03_Ordenamiento", "ordenamiento.xlsx", "deficit_vivienda")
  if (!is.null(d)) {
    p <- mapa_coropletico(
      d, `Déficit cuantitativo de vivienda`, prov,
      titulo_leyenda = "% de viviendas",
      formato = function(x) pct_co(x * 100, dec = 0)) +
      .textos_mapa(
        titulo = "El déficit cuantitativo de vivienda no se reparte parejo",
        subtitulo = "Porcentaje de viviendas en déficit cuantitativo, 2023",
        fuente = "DANE, déficit habitacional 2023. Cálculos propios."
      )
    .emitir(p, "mapa_03_deficit_vivienda", prov, "03_Ordenamiento",
            "ordenamiento.xlsx", d,
            c("Código DANE", "Municipio", "Déficit cuantitativo de vivienda",
              "Déficit cualitativo de vivienda"))
    hechos <- c(hechos, "mapa_03_deficit_vivienda")
  }

  # --- 05 Valor agregado per cápita ------------------------------------------
  d <- .ultimo_anio(.hoja_de(prov, "05_Economia", "economia.xlsx", "valor_agregado"))
  if (!is.null(d) && nrow(d)) {
    anio <- .anio_de(d)
    p <- mapa_coropletico(
      d, `Valor agregado per cápita (pesos constantes de 2015)`, prov,
      titulo_leyenda = "pesos", formato = function(x) num_co(x, 0)) +
      .textos_mapa(
        titulo = "El valor agregado por habitante marca la geografía económica de la provincia",
        subtitulo = sprintf(
          "Pesos constantes de 2015 por habitante, %s", anio %||% "último año disponible"),
        fuente = "DANE, valor agregado municipal. Cálculos propios."
      )
    .emitir(p, "mapa_05_va_percapita", prov, "05_Economia", "economia.xlsx", d,
            c("Código DANE", "Municipio", "Año",
              "Valor agregado per cápita (pesos constantes de 2015)"))
    hechos <- c(hechos, "mapa_05_va_percapita")
  }

  # --- 07 Pérdida de cobertura arbórea ---------------------------------------
  d <- .hoja_de(prov, "07_Ambiental", "ambiental.xlsx", "perdida_cobertura")
  if (!is.null(d)) {
    p <- mapa_coropletico(
      d, `Pérdida de cobertura arbórea 2001-2023 (%)`, prov,
      # NO es un porcentaje del área del municipio. Global Forest Watch mide la
      # pérdida contra una línea base: la cobertura arbórea del año 2000. Este
      # mapa rotulaba «% del área», y recalcularlo así difiere del valor
      # publicado en 119 de los 124 municipios —Medellín daría 6,6 % y se
      # publica 10,0 %— mientras que la figura 4 de esta misma sección ya lo
      # rotulaba bien (F-4-002).
      titulo_leyenda = "% de la cobertura\narbórea de 2000",
      formato = function(x) pct_co(x * 100, dec = 0)) +
      .textos_mapa(
        titulo = "La pérdida de cobertura arbórea se concentra en unos pocos municipios",
        subtitulo = paste("Pérdida acumulada 2001-2023, como porcentaje de la",
                          "cobertura arbórea que el municipio tenía en 2000"),
        fuente = "Global Forest Watch. Cálculos propios.",
        nota = paste("Cobertura arbórea: superficie con más del 30 % de dosel en",
                     "el año 2000, según Global Forest Watch. Incluye",
                     "plantaciones y cultivos arbóreos.")
      )
    .emitir(p, "mapa_07_perdida_cobertura", prov, "07_Ambiental",
            "ambiental.xlsx", d,
            c("Código DANE", "Municipio",
              "Pérdida de cobertura arbórea 2001-2023 (%)"))
    hechos <- c(hechos, "mapa_07_perdida_cobertura")
  }

  # --- 08 Cobertura neta educativa -------------------------------------------
  d <- .ultimo_anio(.hoja_de(prov, "08_Educacion", "educacion.xlsx", "educacion"))
  if (!is.null(d) && nrow(d)) {
    anio <- .anio_de(d)
    p <- mapa_coropletico(
      d, `Cobertura neta`, prov, titulo_leyenda = "cobertura",
      formato = function(x) pct_co(x * 100, dec = 0)) +
      .textos_mapa(
        titulo = "La cobertura educativa no es homogénea dentro de la provincia",
        subtitulo = sprintf("Cobertura neta, %s", anio %||% "último año disponible"),
        fuente = "Ministerio de Educación Nacional. Cálculos propios.",
        # El propio dato obliga a la advertencia: hay municipios por encima del
        # 100 %, lo que una cobertura NETA no admite (ver 04_Docs).
        nota = paste("Los valores superiores al 100 % provienen de la fuente y",
                     "señalan una inconsistencia entre matrícula y proyección",
                     "de población; se publican sin corregir.")
      )
    .emitir(p, "mapa_08_cobertura_neta", prov, "08_Educacion", "educacion.xlsx",
            d, c("Código DANE", "Municipio", "Año", "Cobertura neta"))
    hechos <- c(hechos, "mapa_08_cobertura_neta")
  }

  # --- 09 Mortalidad infantil ------------------------------------------------
  d <- .ultimo_anio(.hoja_de(prov, "09_Salud", "salud.xlsx", "mortalidad_infantil"))
  if (!is.null(d) && nrow(d)) {
    anio <- .anio_de(d)
    p <- mapa_coropletico(
      d, `Tasa de mortalidad infantil (x 1.000 nacidos vivos)`, prov,
      titulo_leyenda = "por 1.000\nnacidos vivos",
      formato = function(x) num_co(x, 1)) +
      .textos_mapa(
        titulo = "Dónde mueren más niños antes del primer año",
        subtitulo = sprintf(
          "Tasa de mortalidad infantil por cada 1.000 nacidos vivos, %s",
          anio %||% "último año disponible"),
        fuente = "Gobernación de Antioquia, estadísticas vitales. Cálculos propios.",
        nota = paste("En municipios con pocos nacimientos la tasa es muy",
                     "sensible a un solo caso.")
      )
    .emitir(p, "mapa_09_mortalidad_infantil", prov, "09_Salud", "salud.xlsx", d,
            c("Código DANE", "Municipio", "Año",
              "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"))
    hechos <- c(hechos, "mapa_09_mortalidad_infantil")
  }

  # --- 10 Homicidios ---------------------------------------------------------
  d <- .hoja_de(prov, "10_Seguridad", "seguridad.xlsx", "delitos")
  if (!is.null(d)) {
    p <- mapa_coropletico(
      d, `Homicidios por 100.000 hab.`, prov,
      titulo_leyenda = "por 100.000\nhabitantes",
      formato = function(x) num_co(x, 0)) +
      .textos_mapa(
        titulo = "La violencia homicida tiene una geografía dentro de la provincia",
        subtitulo = "Homicidios por cada 100.000 habitantes",
        fuente = "Policía Nacional, SIEDCO. Cálculos propios."
      )
    .emitir(p, "mapa_10_homicidios", prov, "10_Seguridad", "seguridad.xlsx", d,
            c("Código DANE", "Municipio", "Homicidios por 100.000 hab."))
    hechos <- c(hechos, "mapa_10_homicidios")
    hechos <- c(hechos, mapa_departamental_homicidios(prov))
  }

  message("  ", length(hechos), " mapas generados")
  invisible(hechos)
}

#' El mismo indicador de homicidios en todo el departamento: dice si la
#' provincia es un caso aparte o parte de un patrón regional. Es la lectura que
#' ninguna tabla provincial puede dar.
#'
#' ES EL ÚNICO MAPA QUE NO SALE DE LA HOJA DE SU PROVINCIA, porque necesita el
#' departamento entero. Antes lo armaba leyendo el .xlsx de las once provincias,
#' y como esos archivos los va escribiendo el propio pipeline, cuando corría la
#' provincia k solo existían las hojas 1..k: diez de los once informes lo
#' publicaban truncado, bajo una nota que afirmaba que los municipios grises no
#' pertenecen a ninguna provincia (F-2-035).
#'
#' Ahora lo calcula desde el derivado, con las MISMAS funciones que producen la
#' hoja `delitos` —`universo_delitos()` y `tasas_delitos()`, en
#' 03_tablas/10_seguridad.R—, así que no hay dos implementaciones de la cuenta y
#' el mapa no puede discrepar de la tabla (regla 1 del anexo). Y al no depender
#' de 03_Outputs, sale igual de correcto con una provincia que con las once.
mapa_departamental_homicidios <- function(prov) {
  if (!HAY_CARTOGRAFIA) return(invisible(NULL))
  if (!exists("universo_delitos")) {
    source(file.path(RUTAS$codigo, "03_tablas", "10_seguridad.R"), encoding = "UTF-8")
  }

  # Se colorean los municipios que pertenecen a algún esquema asociativo; el
  # resto del departamento queda en gris, que es el criterio con el que se
  # publicó. id_provincia viene de con_territorio(), o sea del crosswalk: el
  # universo no está escrito a mano en ningún lado.
  todos <- universo_delitos() |>
    dplyr::filter(!is.na(.data$id_provincia)) |>
    tasas_delitos() |>
    dplyr::transmute(
      `Código DANE`                 = .data$ind_mpio,
      Municipio                     = .data$municipio,
      `Homicidios por 100.000 hab.` = .data$homicidios
    )

  cargados <- nrow(todos)
  esperados <- nrow(crosswalk_provincias())
  if (cargados == 0L) {
    message("  [mapa dpto] ", prov$etiqueta,
            ": omitido, el derivado de policía no trae ningún municipio.")
    return(invisible(NULL))
  }
  if (cargados < esperados) {
    message("  [mapa dpto] aviso: el derivado de policía cubre ", cargados,
            " de los ", esperados, " municipios del sistema provincial.")
  }

  p <- mapa_departamental(
    todos, `Homicidios por 100.000 hab.`, prov = prov,
    titulo_leyenda = "por 100.000\nhabitantes",
    formato = function(x) num_co(x, 0)) +
    .textos_mapa(
      titulo = "La provincia en el mapa departamental de homicidios",
      subtitulo = sprintf(
        "Homicidios por cada 100.000 habitantes; %s va delineada en rojo",
        prov$etiqueta),
      fuente = "Policía Nacional, SIEDCO. Cálculos propios.",
      # La cifra va escrita: es la que el guarda de arriba comprueba, y sin ella
      # el lector no puede saber si el mapa está completo (regla 11).
      nota = sprintf(paste("Se colorean los %s municipios que pertenecen a alguna",
                           "de las once provincias; el resto queda en gris."),
                     num_co(cargados, 0))
    )
  .emitir(p, "mapa_10_homicidios_dpto", prov, "10_Seguridad",
          "seguridad.xlsx", todos,
          c("Código DANE", "Municipio", "Homicidios por 100.000 hab."))
  invisible("mapa_10_homicidios_dpto")
}
