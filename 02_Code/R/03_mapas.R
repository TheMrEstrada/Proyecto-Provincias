# =============================================================================
# 03_mapas.R — Cartografía del Proyecto Provincias
#
# Extiende el sistema visual de 02_tema.R al mapa. Las reglas no cambian por
# ser un mapa: la rampa secuencial del Azul Zafre para magnitud (DISENO.md
# §2.2), resalte/contexto para "este municipio frente a sus pares" (§2.4), y un
# máximo de tres series categóricas (§2.1, que lo dice explícitamente para
# mapas). El mapa es otra forma de la misma gramática, no un lenguaje aparte.
#
# QUÉ APORTA UN MAPA QUE NO APORTE UNA BARRA
#   La barra ordena; el mapa localiza. Solo vale la pena cuando la pregunta es
#   DÓNDE: contigüidad (los municipios con déficit alto, ¿son vecinos?),
#   frontera (¿el patrón se corta en el límite provincial?), accesibilidad
#   (¿los peores están lejos del corredor vial?). Si la lectura es "quién tiene
#   más", la barra es mejor y el mapa es decoración cara.
#
# CARTOGRAFÍA BASE
#   01_Data/00_Inputs/maps/MGN_MPIO_POLITICO.shp   125 municipios de Antioquia
#     (DANE, Marco Geoestadístico Nacional; DIVIPOLA en MPIO_CCDGO)
#   01_Data/00_Inputs/maps/mapa_departamentos_colombia.shp  contexto nacional
#
# ETAPA DEL PIPELINE: infraestructura (lo carga 00_config.R)
# =============================================================================

# `sf` es la única dependencia que añade este módulo. Se carga solo si está: un
# clon sin sf debe seguir generando tablas y figuras no cartográficas.
HAY_CARTOGRAFIA <- requireNamespace("sf", quietly = TRUE)

if (!HAY_CARTOGRAFIA) {
  message("[mapas] El paquete 'sf' no está instalado: los mapas se omitirán. ",
          "Instálelo con  install.packages(\"sf\")  para generarlos.")
}

.cache_mapas <- new.env(parent = emptyenv())

# --- Cartografía base ---------------------------------------------------------

#' Los 125 municipios de Antioquia con su código DANE y su territorio.
#'
#' Se lee una vez por sesión. El shapefile no trae `.cpg`, así que el encoding
#' se declara explícitamente: sin eso los nombres pierden las tildes y el cruce
#' por nombre fallaría (aquí se cruza por código, pero las etiquetas se leen).
cartografia_municipios <- function() {
  if (!HAY_CARTOGRAFIA) return(NULL)
  if (!is.null(.cache_mapas$mpios)) return(.cache_mapas$mpios)

  ruta <- entrada("maps", "MGN_MPIO_POLITICO.shp")
  capa <- sf::st_read(ruta, quiet = TRUE, options = "ENCODING=UTF-8")
  capa <- sf::st_make_valid(capa)

  capa$ind_mpio <- as.integer(capa$MPIO_CCDGO)
  cw <- crosswalk_provincias()
  sub <- crosswalk_subregiones()

  capa <- merge(capa, cw[, c("ind_mpio", "municipio", "subregion", "provincia",
                             "id_provincia")],
                by = "ind_mpio", all.x = TRUE)
  capa <- merge(capa, sub, by = "ind_mpio", all.x = TRUE)
  # Los municipios que no pertenecen a ninguna provincia conservan su nombre
  # oficial del MGN: son el contexto del mapa departamental.
  capa$municipio <- ifelse(is.na(capa$municipio),
                           stringr::str_to_title(as.character(capa$MPIO_CNMBR)),
                           capa$municipio)

  .cache_mapas$mpios <- capa
  capa
}

#' Municipios de una provincia.
cartografia_provincia <- function(prov) {
  capa <- cartografia_municipios()
  if (is.null(capa)) return(NULL)
  capa[!is.na(capa$id_provincia) & capa$id_provincia == prov$id, ]
}

# --- Tema del mapa ------------------------------------------------------------

#' Tema para mapas: sin ejes, sin grilla, sin coordenadas.
#'
#' Un mapa temático no lleva ejes de latitud y longitud. El lector no localiza
#' por coordenada sino por forma, y los números del eje son tinta que compite
#' con el dato (DISENO.md §1.2).
theme_mapa <- function() {
  theme_provincias(grilla = "ninguna") +
    ggplot2::theme(
      # Hay que anular `axis.text.x` y `axis.text.y` por separado: theme_provincias
      # ya los fijó, y en ggplot2 el ajuste específico gana sobre el genérico
      # `axis.text`, así que blanquear solo el padre no borra nada.
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      legend.position = "right",
      legend.direction = "vertical",
      legend.title = ggplot2::element_text(size = PT$leyenda, color = COLOR$tinta_2),
      legend.key.height = grid::unit(0.9, "cm"),
      legend.key.width = grid::unit(0.35, "cm")
    )
}

# --- Etiquetas ----------------------------------------------------------------

#' Centroides para rotular. `st_point_on_surface` en vez de `st_centroid`: el
#' centroide de un municipio en herradura puede caer fuera de su polígono y la
#' etiqueta acabaría sobre el vecino.
.puntos_de_etiqueta <- function(capa, etiquetas = NULL) {
  suppressWarnings({
    p <- sf::st_point_on_surface(sf::st_geometry(capa))
    xy <- sf::st_coordinates(p)
  })
  data.frame(x = xy[, 1], y = xy[, 2],
             etiqueta = etiquetas %||% capa$municipio,
             stringsAsFactors = FALSE)
}

# Con 13 municipios apiñados, las etiquetas en el centroide se montan unas sobre
# otras y el mapa deja de leerse. `ggrepel` las separa y traza el hilo hasta su
# polígono. Es una dependencia opcional: sin ella se rotula en el centroide, que
# es peor pero sigue siendo un mapa.
HAY_REPEL <- requireNamespace("ggrepel", quietly = TRUE)

#' Capa de etiquetas de municipio, separadas si `ggrepel` está disponible.
#'
#' @param color color del texto.
#' @param halo TRUE dibuja un contorno del color de la superficie alrededor de
#'   cada letra, para que el nombre se lea sobre cualquier tono de la rampa.
.capa_etiquetas <- function(et, color = COLOR$tinta_1, halo = TRUE) {
  aes_txt <- ggplot2::aes(x = .data$x, y = .data$y, label = .data$etiqueta)
  if (HAY_REPEL) {
    ggrepel::geom_text_repel(
      data = et, mapping = aes_txt,
      size = PT$fuente / .pt, family = FUENTE, color = color,
      bg.color = if (halo) COLOR$superficie else NA, bg.r = 0.12,
      min.segment.length = 0.2, segment.size = 0.25,
      segment.color = COLOR$tinta_3, box.padding = 0.18,
      max.overlaps = Inf, seed = 1
    )
  } else {
    ggplot2::geom_text(
      data = et, mapping = aes_txt,
      size = PT$fuente / .pt, family = FUENTE, color = color)
  }
}

# --- Mapa coroplético ---------------------------------------------------------

#' Mapa de magnitud de una provincia.
#'
#' @param datos data.frame con una columna de código DANE y una de valor. Debe
#'   venir de la tabla ya exportada de la sección: el mapa no recalcula nada,
#'   pinta lo mismo que dice la tabla.
#' @param valor nombre (sin comillas) de la columna de valor.
#' @param prov lista de provincia().
#' @param titulo_leyenda unidad del dato, que en el mapa va en la leyenda y no
#'   en el subtítulo (el subtítulo ya carga año y ámbito).
#' @param etiquetar TRUE rotula el nombre de cada municipio.
#' @param formato función que formatea los valores de la leyenda.
#' @param codigo nombre de la columna de código DANE si no se detecta sola.
mapa_coropletico <- function(datos, valor, prov, titulo_leyenda = NULL,
                             etiquetar = TRUE, formato = num_co,
                             codigo = NULL) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  capa <- cartografia_provincia(prov)
  if (is.null(capa) || !nrow(capa)) return(NULL)

  val <- rlang::as_string(rlang::ensym(valor))
  cc <- codigo %||% col(datos, "ind_mpio", "Código DANE", "cod_dane")
  if (is.na(cc)) stop("No encuentro la columna de código de municipio.", call. = FALSE)

  d <- data.frame(
    ind_mpio = suppressWarnings(as.integer(datos[[cc]])),
    ..valor = suppressWarnings(as.numeric(datos[[val]]))
  )
  d <- d[!is.na(d$ind_mpio), , drop = FALSE]
  capa <- merge(capa, d, by = "ind_mpio", all.x = TRUE)

  p <- ggplot2::ggplot(capa) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data[["..valor"]]),
                     color = COLOR$superficie, linewidth = 0.35) +
    scale_fill_provincias_c(
      name = titulo_leyenda, labels = formato,
      # Un municipio sin dato NO se pinta como un cero: va en gris y la leyenda
      # lo dice (DISENO.md §7, "cero real y dato faltante no se representan igual").
      na.value = "#E8E8E6"
    ) +
    # `datum = NA` quita la retícula de latitud y longitud: en un mapa temático
    # el lector no localiza por coordenada.
    ggplot2::coord_sf(datum = NA) +
    theme_mapa()

  if (etiquetar) p <- p + .capa_etiquetas(.puntos_de_etiqueta(capa))
  p
}

# --- Mapa de localización -----------------------------------------------------

#' La provincia dentro de Antioquia: dónde queda lo que el informe describe.
#'
#' Es el primer mapa de cualquier informe provincial y el único que no codifica
#' magnitud: solo pertenencia. Tres niveles, que es el máximo categórico que
#' DISENO.md admite en mapas.
mapa_localizacion <- function(prov, etiquetar = TRUE) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  capa <- cartografia_municipios()
  if (is.null(capa)) return(NULL)

  subreg <- subregion_dominante(prov)
  capa$..rol <- ifelse(
    !is.na(capa$id_provincia) & capa$id_provincia == prov$id, "Provincia",
    ifelse(!is.na(capa$subregion_full) & capa$subregion_full == subreg,
           "Resto de la subregión", "Resto de Antioquia")
  )
  capa$..rol <- factor(capa$..rol,
                       levels = c("Provincia", "Resto de la subregión",
                                  "Resto de Antioquia"))

  p <- ggplot2::ggplot(capa) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data[["..rol"]]),
                     color = COLOR$superficie, linewidth = 0.2) +
    ggplot2::scale_fill_manual(
      values = c("Provincia" = COLOR$resalte,
                 "Resto de la subregión" = "#A1B4DB",
                 "Resto de Antioquia" = "#E8E8E6"),
      name = NULL
    ) +
    ggplot2::coord_sf(datum = NA) +
    theme_mapa() +
    ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

  if (etiquetar) {
    prov_capa <- capa[capa$..rol == "Provincia", ]
    p <- p + .capa_etiquetas(.puntos_de_etiqueta(prov_capa))
  }
  p
}

# --- Mapa departamental -------------------------------------------------------

#' Los 125 municipios de Antioquia con una magnitud, y la provincia delineada.
#'
#' Responde la pregunta que el mapa provincial no puede: si el patrón de la
#' provincia es excepcional en el departamento o es el de toda su región.
mapa_departamental <- function(datos, valor, prov = NULL, titulo_leyenda = NULL,
                               formato = num_co, codigo = NULL) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  capa <- cartografia_municipios()
  if (is.null(capa)) return(NULL)

  val <- rlang::as_string(rlang::ensym(valor))
  cc <- codigo %||% col(datos, "ind_mpio", "Código DANE", "cod_dane")
  if (is.na(cc)) stop("No encuentro la columna de código de municipio.", call. = FALSE)

  d <- data.frame(
    ind_mpio = suppressWarnings(as.integer(datos[[cc]])),
    ..valor = suppressWarnings(as.numeric(datos[[val]]))
  )
  d <- d[!is.na(d$ind_mpio), , drop = FALSE]
  capa <- merge(capa, d, by = "ind_mpio", all.x = TRUE)

  p <- ggplot2::ggplot(capa) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data[["..valor"]]),
                     color = COLOR$superficie, linewidth = 0.12)

  # El contorno provincial va ANTES de fijar el sistema de coordenadas: cada
  # geom_sf que se añade después trae su propio coord_sf y reemplaza al que ya
  # estaba, con aviso en consola y con el datum por defecto.
  if (!is.null(prov)) {
    borde <- capa[!is.na(capa$id_provincia) & capa$id_provincia == prov$id, ]
    if (nrow(borde)) {
      contorno <- sf::st_union(sf::st_geometry(borde))
      p <- p + ggplot2::geom_sf(data = sf::st_sf(geometry = contorno),
                                fill = NA, color = COLOR$referencia,
                                linewidth = 0.7)
    }
  }

  p +
    scale_fill_provincias_c(name = titulo_leyenda, labels = formato,
                            na.value = "#E8E8E6") +
    ggplot2::coord_sf(datum = NA) +
    theme_mapa()
}

# --- Mapa de las once provincias ---------------------------------------------

#' Las 11 provincias de Antioquia en un solo mapa, con la de interés resaltada.
#'
#' Once categorías superan por mucho el máximo de la paleta, así que las
#' provincias NO se distinguen por color: se distinguen por su límite, y el
#' color solo separa "provincia de interés / resto / sin provincia".
mapa_provincias <- function(prov = NULL, etiquetar = TRUE) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  capa <- cartografia_municipios()
  if (is.null(capa)) return(NULL)

  capa$..rol <- ifelse(is.na(capa$id_provincia), "Sin provincia",
                       if (is.null(prov)) "Provincia" else
                         ifelse(capa$id_provincia == prov$id,
                                "Provincia de interés", "Otras provincias"))

  valores <- c("Provincia de interés" = COLOR$resalte,
               "Otras provincias" = "#A1B4DB",
               "Sin provincia" = "#E8E8E6",
               "Provincia" = "#A1B4DB")

  limites <- capa[!is.na(capa$id_provincia), ]
  contornos <- do.call(rbind, lapply(split(limites, limites$id_provincia),
                                     function(g) {
    sf::st_sf(id_provincia = g$id_provincia[1],
              geometry = sf::st_union(sf::st_geometry(g)))
  }))

  p <- ggplot2::ggplot(capa) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data[["..rol"]]),
                     color = COLOR$superficie, linewidth = 0.12) +
    ggplot2::geom_sf(data = contornos, fill = NA, color = COLOR$tinta_2,
                     linewidth = 0.4) +
    # coord_sf va después del último geom_sf; si no, este lo reemplazaría.
    ggplot2::scale_fill_manual(values = valores, name = NULL,
                               breaks = intersect(names(valores),
                                                  unique(capa$..rol))) +
    ggplot2::coord_sf(datum = NA) +
    theme_mapa() +
    ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

  if (etiquetar) {
    et <- .puntos_de_etiqueta(
      contornos,
      etiquetas = PROVINCIAS$etiqueta[match(contornos$id_provincia, PROVINCIAS$id)])
    p <- p + .capa_etiquetas(et)
  }
  p
}
