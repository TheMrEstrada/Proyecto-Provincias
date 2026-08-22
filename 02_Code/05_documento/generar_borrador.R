# =============================================================================
# generar_borrador.R — Borrador en Word del diagnóstico de cada provincia
#
# Produce, para cada provincia, un .docx con la estructura del Anexo 1, sus
# figuras y mapas, y una redacción factual generada desde las tablas ya
# publicadas. Los estilos salen del propio Anexo 1, que se usa como plantilla,
# de modo que los once borradores se ven como el informe entregado.
#
# QUÉ ESCRIBE EL SCRIPT Y QUÉ QUEDA POR ESCRIBIR
#   Escribe el enunciado factual —quién concentra, quién está arriba y abajo,
#   cómo se compara la Provincia con su subregión y con el departamento— con
#   las cifras leídas de las tablas. Deja marcado con ESCRIBIR todo lo
#   interpretativo. Un párrafo de interpretación generado automáticamente sería
#   una afirmación sin autor, y este proyecto no publica cifras ni juicios sin
#   respaldo.
#
# USO:
#   Rscript 02_Code/05_documento/generar_borrador.R          # las once
#   Rscript 02_Code/05_documento/generar_borrador.R 2 4      # solo estas
#
# REQUIERE: el pipeline corrido (Rscript 02_Code/run_all.R) y `pandoc`.
# SALIDA:   04_Docs/borradores/<Provincia>/<Provincia>_diagnostico.docx
#           (y el .md intermedio, que es el que se regenera)
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(dirname(normalizePath(.f[1])))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}

source(file.path(RUTAS$codigo, "05_documento", "R", "frases.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "05_documento", "R", "diagnosticos.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "05_documento", "R", "secciones.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "05_documento", "R", "resumenes.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "06_comparativo", "figuras_comparativas.R"),
       encoding = "UTF-8")
source(file.path(RUTAS$codigo, "05_documento", "R", "posicion_sistema.R"),
       encoding = "UTF-8")

# El panel de las once provincias se calcula una vez por sesión: cada informe
# lo consulta para situarse, y así los once dicen la misma posición.
.panel_cache <- new.env(parent = emptyenv())
panel_comparativo <- function() {
  if (is.null(.panel_cache$panel)) .panel_cache$panel <- construir_panel()
  .panel_cache$panel
}

DIR_BORRADORES <- file.path(RUTAS$raiz, "04_Docs", "borradores")
ANEXO1 <- file.path(RUTAS$documentos,
                    "Anexo 1. Contexto departamental y provincial extendido.docx")
PLANTILLA <- file.path(RUTAS$codigo, "05_documento", "plantilla_estilos.docx")

#' Añade a un styles.xml los estilos que pandoc referencia y que le falten.
#'
#' Pandoc marca cada elemento con un estilo por nombre (`Table`, `ImageCaption`,
#' `Compact`…). Si el documento de referencia no lo define, el elemento pierde
#' su formato: las tablas, en concreto, se quedan sin rejilla y se leen como una
#' lista de celdas. Se copian del `reference.docx` que trae el propio pandoc
#' SOLO los que falten; los que el Anexo 1 ya define mandan sobre ellos.
.completar_estilos <- function(ruta_styles) {
  ref <- tempfile(fileext = ".docx")
  ok <- tryCatch({
    system2(.ruta_pandoc(), c("--print-default-data-file", "reference.docx"),
            stdout = ref)
    file.exists(ref) && file.size(ref) > 0
  }, error = function(e) FALSE)
  if (!ok) return(invisible(FALSE))

  tmp_ref <- file.path(tempdir(), "ref_pandoc")
  unlink(tmp_ref, recursive = TRUE); dir.create(tmp_ref, recursive = TRUE)
  utils::unzip(ref, files = "word/styles.xml", exdir = tmp_ref)
  origen <- file.path(tmp_ref, "word", "styles.xml")
  if (!file.exists(origen)) return(invisible(FALSE))

  leer <- function(f) paste(readLines(f, warn = FALSE, encoding = "UTF-8"),
                            collapse = "\n")
  destino <- leer(ruta_styles)
  fuente  <- leer(origen)

  ya <- regmatches(destino, gregexpr('w:styleId="[^"]+"', destino))[[1]]
  ya <- gsub('.*"(.*)"', "\\1", ya)

  bloques <- regmatches(fuente, gregexpr("<w:style [^>]*>.*?</w:style>", fuente))[[1]]
  faltan <- Filter(function(b) {
    id <- regmatches(b, regexpr('w:styleId="[^"]+"', b))
    length(id) && !(gsub('.*"(.*)"', "\\1", id) %in% ya)
  }, bloques)
  if (!length(faltan)) return(invisible(TRUE))

  destino <- sub("</w:styles>", paste0(paste(faltan, collapse = ""), "</w:styles>"),
                 destino, fixed = TRUE)
  writeLines(destino, ruta_styles, useBytes = TRUE)
  message("  [plantilla] estilos añadidos desde pandoc: ", length(faltan))
  invisible(TRUE)
}

#' Plantilla de estilos para pandoc, derivada del Anexo 1.
#'
#' Pandoc construye el .docx SOBRE el documento de referencia, así que si se le
#' pasa el Anexo 1 entero se lleva también sus 62 imágenes —doce megas que no
#' se ven en ninguna página—. Esta plantilla conserva lo que hace falta (los
#' estilos, la numeración, el tema y la configuración de página) y vacía el
#' cuerpo y la carpeta de medios.
#'
#' Se construye una sola vez y se versiona: así el borrador no depende de que
#' el Anexo 1 esté presente en el clon.
construir_plantilla <- function(forzar = FALSE) {
  if (file.exists(PLANTILLA) && !forzar) return(invisible(PLANTILLA))
  if (!file.exists(ANEXO1)) {
    # warning(), no message(): que los .docx salgan sin el estilo del informe
    # entregado es fácil de perder entre el resto del log. Hallazgo de Pablo
    # (F-2-050), adoptado también aquí.
    warning("No está el Anexo 1: los .docx saldrán con los estilos por ",
            "defecto de pandoc, no con los del informe entregado.", call. = FALSE)
    return(invisible(NULL))
  }

  tmp <- file.path(tempdir(), "plantilla_docx")
  unlink(tmp, recursive = TRUE); dir.create(tmp, recursive = TRUE)
  utils::unzip(ANEXO1, exdir = tmp)

  # 1. Cuerpo vacío, conservando <w:sectPr>: ahí viven el tamaño de página, los
  #    márgenes y la orientación, que sí queremos heredar.
  ruta_doc <- file.path(tmp, "word", "document.xml")
  doc <- paste(readLines(ruta_doc, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  cab <- sub("<w:body>.*$", "<w:body>", doc)
  sect <- regmatches(doc, regexpr("<w:sectPr[ >].*?</w:sectPr>", doc))
  if (!length(sect)) sect <- ""
  writeLines(paste0(cab, sect, "</w:body></w:document>"), ruta_doc, useBytes = TRUE)

  # 2. Fuera los medios y las relaciones que apuntan a ellos: una relación
  #    colgando sin archivo hace que Word declare el documento dañado.
  unlink(file.path(tmp, "word", "media"), recursive = TRUE)
  ruta_rels <- file.path(tmp, "word", "_rels", "document.xml.rels")
  if (file.exists(ruta_rels)) {
    rels <- paste(readLines(ruta_rels, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    rels <- gsub("<Relationship[^>]*Target=\"media/[^\"]*\"[^>]*/>", "", rels)
    writeLines(rels, ruta_rels, useBytes = TRUE)
  }

  # 3. Estilos que pandoc referencia y el Anexo 1 no define.
  #    Pandoc marca sus tablas con el estilo `Table`; si no existe, Word y
  #    LibreOffice pierden la rejilla y la tabla se lee como una lista de celdas
  #    una debajo de otra. Se copian del reference.docx que trae pandoc los que
  #    falten, sin tocar los que el Anexo sí trae: esos mandan.
  .completar_estilos(file.path(tmp, "word", "styles.xml"))

  if (file.exists(PLANTILLA)) unlink(PLANTILLA)
  antes <- getwd(); on.exit(setwd(antes), add = TRUE)
  setwd(tmp)
  ok <- tryCatch({
    utils::zip(PLANTILLA, list.files(".", recursive = TRUE, all.files = TRUE),
               flags = "-q -r -X")
    TRUE
  }, error = function(e) FALSE)
  setwd(antes)

  if (!ok || !file.exists(PLANTILLA)) {
    message("  [plantilla] No se pudo empaquetar; se usará el Anexo 1 tal cual.")
    return(invisible(NULL))
  }
  message("  [plantilla] plantilla_estilos.docx  (",
          format(structure(file.size(PLANTILLA), class = "object_size"),
                 units = "auto", digits = 0), ")")
  invisible(PLANTILLA)
}

# --- Utilidades de composición ------------------------------------------------

#' Pie de figura del Anexo 1: número, título y fuente en la línea siguiente.
#' El número se lleva la cuenta por documento, como en el informe.
.contador <- new.env(parent = emptyenv())

#' La ruta de la imagen, relativa a la raíz del proyecto.
#'
#' Escrita en absoluto, la referencia solo funciona en la máquina que generó
#' el documento: eran ~825 rutas /Users/... en los doce entregables. Y el
#' --resource-path que ya se pasa no lo arreglaba, porque pandoc solo lo
#' aplica a rutas RELATIVAS; con absolutas es inerte y pandoc aborta sin
#' escribir nada (no avisa: aborta). Emitiéndolas relativas, ese
#' --resource-path empieza a hacer su trabajo. Hallazgo de Pablo (F-1-006),
#' adoptado también aquí.
.ruta_relativa <- function(ruta) {
  sub(paste0(RUTAS$raiz, "/"), "", ruta, fixed = TRUE)
}

.figura <- function(ruta, titulo, fuente_txt = NULL) {
  if (!file.exists(ruta)) return(character(0))
  .contador$fig <- (.contador$fig %||% 0) + 1
  # Entre <> por si la ruta trae espacios: es la forma que CommonMark define
  # para destinos de enlace y pandoc la entiende.
  c(sprintf("![%s. %s](<%s>)", .contador$fig, titulo, .ruta_relativa(ruta)),
    "",
    if (!is.null(fuente_txt)) sprintf("*%s*", fuente(fuente_txt)) else NULL,
    "")
}

#' Todas las figuras y mapas de una sección, con los mapas primero.
#'
#' El mapa localiza y la figura ordena: leer primero dónde está el fenómeno y
#' después quién tiene más es el orden natural del argumento.
.piezas_seccion <- function(prov, seccion, titulos = list()) {
  dir_fig <- file.path(RUTAS$outputs, prov$carpeta, seccion, "figuras")
  if (!dir.exists(dir_fig)) return(character(0))
  png <- sort(list.files(dir_fig, pattern = "\\.png$", full.names = TRUE))
  png <- c(png[grepl("/mapa_", png)], png[!grepl("/mapa_", png)])
  out <- character(0)
  for (f in png) {
    slug <- sub("\\.png$", "", basename(f))
    titulo <- titulos[[slug]] %||% .titulo_desde_slug(slug)
    out <- c(out, .figura(f, titulo))
  }
  out
}

# El nombre de archivo va sin tildes por diseño (DISENO.md §8), así que para el
# pie de figura hay que devolvérselas. Es un diccionario de palabras, no de
# figuras: cubre cualquier slug nuevo sin tener que ampliarlo.
.ACENTOS <- c(
  distribucion = "distribución", poblacion = "población", densidad = "densidad",
  piramide = "pirámide", migracion = "migración", envejecimiento = "envejecimiento",
  natalidad = "natalidad", mortalidad = "mortalidad", infantil = "infantil",
  deficit = "déficit", vivienda = "vivienda", servicios = "servicios",
  publicos = "públicos", vias = "vías", area = "área", habitantes = "habitantes",
  catastro = "catastro", avaluo = "avalúo", imca = "IMCA", gobierno = "gobierno",
  digital = "digital", internet = "internet", fibra = "fibra", suelo = "suelo",
  rural = "rural", urbano = "urbano", educacion = "educación",
  cobertura = "cobertura", neta = "neta", desercion = "deserción",
  repitencia = "repitencia", transito = "tránsito", superior = "superior",
  economia = "economía", pobreza = "pobreza", nbi = "NBI", ipm = "IPM",
  gini = "Gini", ocupacion = "ocupación", informalidad = "informalidad",
  desocupacion = "desocupación", nini = "NiNi", dependencia = "dependencia",
  economica = "económica", empresarial = "empresarial", valor = "valor",
  agregado = "agregado", percapita = "per cápita", actividades = "actividades",
  energia = "energía", tecnologia = "tecnología", centrales = "centrales",
  participacion = "participación", titulos = "títulos", mineros = "mineros",
  visitantes = "visitantes", extranjeros = "extranjeros", turismo = "turismo",
  pecuario = "pecuario", inventario = "inventario", especies = "especies",
  cultivos = "cultivos", produccion = "producción", rendimiento = "rendimiento",
  agricola = "agrícola", protegidas = "protegidas", irca = "IRCA",
  emergencias = "emergencias", desastres = "desastres", imrc = "IMRC",
  perdida = "pérdida", arborea = "arbórea", salud = "salud",
  aseguramiento = "aseguramiento", sgsss = "SGSSS", peso = "peso",
  bajo = "bajo", vectores = "vectores", suicidios = "suicidios",
  seguridad = "seguridad", percepcion = "percepción", delitos = "delitos",
  homicidios = "homicidios", victimas = "víctimas", ocurrencia = "ocurrencia",
  hechos = "hechos", victimizantes = "victimizantes", restitucion = "restitución",
  tierras = "tierras", personas = "personas", desaparecidas = "desaparecidas",
  localizacion = "localización", territorial = "territorial", dpto = "departamento",
  hab = "hab.", mil = "mil"
)

#' Título legible a partir del nombre del archivo.
#' Es un respaldo razonable: la figura ya lleva su propio título dentro de la
#' imagen, y este pie solo sirve para numerarla y referenciarla en el texto.
.titulo_desde_slug <- function(slug) {
  x <- sub("^(fig|mapa)_\\d+_", "", slug)
  palabras <- strsplit(x, "_")[[1]]
  palabras <- ifelse(palabras %in% names(.ACENTOS),
                     unname(.ACENTOS[palabras]), palabras)
  y <- paste(palabras, collapse = " ")
  paste0(toupper(substr(y, 1, 1)), substr(y, 2, nchar(y)))
}

# Meses en español: format() depende del locale del sistema y en esta máquina
# devuelve "August". La fecha del informe no puede depender de eso.
.MESES <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
            "agosto", "septiembre", "octubre", "noviembre", "diciembre")
.fecha_es <- function(d = Sys.Date()) {
  sprintf("%d de %s de %s", as.integer(format(d, "%d")),
          .MESES[as.integer(format(d, "%m"))], format(d, "%Y"))
}

#' Una hoja publicada como tabla de Markdown, con las columnas declaradas.
.tabla_md <- function(prov, seccion, archivo, hoja, columnas, titulo,
                      fuente_txt = NULL, porcentaje = character(0)) {
  d <- hoja_publicada(prov, seccion, archivo, hoja)
  if (is.null(d)) return(character(0))
  d <- ultimo_anio(d)
  columnas <- intersect(columnas, names(d))
  if (!length(columnas)) return(character(0))
  d <- d[, columnas, drop = FALSE]

  .contador$tab <- (.contador$tab %||% 0) + 1
  # Las proporciones se guardan como fracción y en Excel las muestra el formato
  # de celda. Aquí no hay formato de celda: hay que aplicarlo al escribir, o la
  # tabla publicaría «0,38» donde el informe dice «38,0 %».
  fmt <- function(x, es_pct) {
    if (!is.numeric(x)) return(ifelse(is.na(x), "—", as.character(x)))
    if (es_pct) return(ifelse(is.na(x), "—", pct_co(x * 100, dec = 1)))
    dec <- if (all(abs(x - round(x)) < 1e-9, na.rm = TRUE)) 0 else 2
    ifelse(is.na(x), "—", num_co(x, dec))
  }
  cuerpo <- as.data.frame(
    mapply(fmt, d, columnas %in% porcentaje, SIMPLIFY = FALSE),
    stringsAsFactors = FALSE)
  names(cuerpo) <- columnas

  c(sprintf("**Tabla %d.** %s", .contador$tab, titulo),
    "",
    paste0("| ", paste(columnas, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(columnas)), collapse = "|"), "|"),
    apply(cuerpo, 1, function(f) paste0("| ", paste(f, collapse = " | "), " |")),
    "",
    if (!is.null(fuente_txt)) sprintf("*%s*", fuente(fuente_txt)) else NULL,
    "")
}

#' Bloque de una sección: encabezado, párrafos, tabla y piezas visuales.
.bloque <- function(nivel, titulo, parrafos = character(0), extra = character(0)) {
  c(paste0(strrep("#", nivel), " ", titulo), "",
    unlist(lapply(parrafos, function(p) c(p, ""))),
    extra)
}

# --- Contexto de la provincia -------------------------------------------------

.contexto <- function(prov) {
  cw <- crosswalk_provincias()
  m <- cw[cw$id_provincia == prov$id, ]
  subreg <- subregion_dominante(prov)

  pob <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx", "poblacion")
  area <- hoja_publicada(prov, "01_Generalidades",
                         "distribucion_territorial.xlsx", "distribucion_territorial")
  suma <- function(d, cl) {
    if (is.null(d) || !cl %in% names(d)) return(NA_real_)
    sum(suppressWarnings(as.numeric(solo_municipios(d)[[cl]])), na.rm = TRUE)
  }
  list(
    n = nrow(m), municipios = sort(m$municipio), subregion = subreg,
    subregiones = sort(unique(m$subregion)),
    fuera = m[m$subregion != subreg, ],
    poblacion = suma(pob, "Población total"),
    urbana = suma(pob, "Población urbana"),
    rural = suma(pob, "Población rural"),
    area_km2 = suma(area, "Área municipal (km²)")
  )
}

# --- Documento ----------------------------------------------------------------

#' El resumen de una dimensión como un solo "párrafo" (varias líneas de
#' markdown ya unidas): así .bloque() lo trata como una unidad más y, si no
#' hay bullets para esa dimensión, character(0) desaparece limpio al pegarlo
#' con c() — sin ifs sueltos en cada uno de los 10 puntos de inserción.
.resumen_linea <- function(titulo, bullets) {
  x <- .resumen_box(titulo, bullets)
  if (!length(x)) character(0) else paste(x, collapse = "\n")
}

markdown_provincia <- function(prov) {
  .contador$fig <- 0; .contador$tab <- 0
  ctx <- .contexto(prov)
  resu <- resumen_dimensiones(prov, ctx)
  L <- character(0)

  # --- Portada y nota de uso --------------------------------------------------
  L <- c(L,
    "---",
    sprintf('title: "Diagnóstico Integral Territorial — Provincia %s"', prov$etiqueta),
    'subtitle: "Contexto departamental y provincial extendido"',
    'author: "Proyecto Provincias · Planes Estratégicos Provinciales de Antioquia"',
    sprintf('date: "%s"', .fecha_es()),
    "lang: es",
    "---",
    "",
    "> **Cómo leer este borrador.** La estructura y los encabezados son los del",
    "> Anexo 1. Todo el texto se generó desde las tablas que produce el flujo:",
    "> ninguna cifra está escrita a mano y cada afirmación se apoya en un valor",
    "> calculado. Si una cifra es incorrecta, se corrige en el flujo y se",
    "> regenera el borrador; no se edita aquí.",
    ">",
    "> Las notas **Verificar con el equipo** marcan lo que el dato no puede",
    "> sostener por sí solo —causas, contexto institucional, información de",
    "> campo—. Están donde el informe querría afirmar algo que exige una fuente",
    "> que este flujo no tiene. Resolverlas es el trabajo que queda.",
    ">",
    "> Antes de dar una sección por terminada, pase la lista de verificación de",
    "> `04_Docs/plan_escritura_provincial.md` §7.",
    "")

  # --- Encabezado del capítulo -----------------------------------------------
  L <- c(L, .bloque(2, "Contexto departamental y provincial"))

  L <- c(L, sprintf(
    paste("La Provincia Administrativa y de Planificación %s está conformada por",
          "%d municipios%s. Sobre una extensión de %s km², la Provincia reúne",
          "una población proyectada de %s habitantes para 2025, de los cuales el",
          "%s reside en zona rural."),
    prov$etiqueta, ctx$n,
    if (nrow(ctx$fuera)) sprintf(
      ": %d pertenecen a la subregión %s y %s a la subregión %s",
      ctx$n - nrow(ctx$fuera), ctx$subregion,
      y_lista(ctx$fuera$municipio), y_lista(unique(ctx$fuera$subregion)))
    else sprintf(", todos de la subregión %s", ctx$subregion),
    num_co(ctx$area_km2, 0), num_co(ctx$poblacion, 0),
    pct_co(ctx$rural / ctx$poblacion * 100, dec = 1)),
    "")

  L <- c(L, sprintf("Los municipios que la integran son %s.",
                    y_lista(ctx$municipios)), "")

  # --- 01 Generalidades -------------------------------------------------------
  L <- c(L, .bloque(3, "Generalidades –contexto departamental y provincial-",
                    c(.resumen_linea("Generalidades", resu$generalidades),
                      seccion_generalidades(prov, ctx)),
                    c(.tabla_md(prov, "01_Generalidades",
                                "distribucion_territorial.xlsx",
                                "distribucion_territorial",
                                c("Municipio", "Área municipal (km²)",
                                  "Participación en el área provincial"),
                                sprintf("Extensión territorial de los municipios de la Provincia %s",
                                        prov$etiqueta),
                                "Gobernación de Antioquia, Anuario Estadístico. Cálculos propios.",
                                porcentaje = "Participación en el área provincial"),
                      .piezas_seccion(prov, "01_Generalidades"))))

  # --- 02 Demografía ----------------------------------------------------------
  L <- c(L, .bloque(3, "Demografía",
                    c(.resumen_linea("Demografía", resu$demografia),
                      seccion_demografia(prov, ctx)),
                    c(.tabla_md(prov, "02_Demografia", "demografia.xlsx", "poblacion",
                                c("Municipio", "Población total", "Población urbana",
                                  "Población rural", "Densidad poblacional (hab/km²)"),
                                sprintf("Proyecciones de población 2025 en la Provincia %s",
                                        prov$etiqueta),
                                "DANE, proyecciones de población 2018-2042. Cálculos propios."),
                      .piezas_seccion(prov, "02_Demografia"))))

  # --- 03 Ordenamiento --------------------------------------------------------
  ord <- seccion_ordenamiento(prov, ctx)
  L <- c(L, .bloque(3, "Ordenamiento del Territorio",
                    c(.resumen_linea("Ordenamiento del Territorio", resu$ordenamiento),
                      ord$intro)))
  L <- c(L, .bloque(4, "Planes de Ordenamiento Territorial", ord$pot))
  L <- c(L, .bloque(4, "Tránsito y trasporte", ord$vias))
  L <- c(L, .bloque(4, "Ciencia, Tecnología e Innovación", ord$cti))
  L <- c(L, .bloque(4, "Vivienda y servicios", ord$vivienda,
                    c(.tabla_md(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                                "deficit_vivienda",
                                c("Municipio", "Déficit cuantitativo de vivienda",
                                  "Déficit cualitativo de vivienda"),
                                sprintf("Déficit cuantitativo y cualitativo de vivienda en la Provincia %s",
                                        prov$etiqueta),
                                "DANE, déficit habitacional 2023. Cálculos propios.",
                                porcentaje = c("Déficit cuantitativo de vivienda",
                                               "Déficit cualitativo de vivienda")),
                      .piezas_seccion(prov, "03_Ordenamiento"))))

  # --- 04 Gobernabilidad ------------------------------------------------------
  gob <- seccion_gobernabilidad(prov, ctx)
  L <- c(L, .bloque(3, "Gobernabilidad y capacidades territoriales",
                    .resumen_linea("Gobernabilidad y capacidades territoriales",
                                   resu$gobernabilidad)))
  L <- c(L, .bloque(4, "Gobernabilidad", gob$gob))
  L <- c(L, .bloque(4, "Finanzas territoriales", gob$finanzas))
  L <- c(L, .bloque(4, "Índice de Ciudades Modernas (ICM)", gob$icm,
                    .piezas_seccion(prov, "04_Gobernabilidad")))

  # --- 05 Economía ------------------------------------------------------------
  eco <- seccion_economia(prov, ctx)
  L <- c(L, .bloque(3, "Economía y desarrollo",
                    c(.resumen_linea("Economía y desarrollo", resu$economia),
                      eco$intro)))
  L <- c(L, .bloque(4, "Pobreza y mercado laboral", eco$pobreza))
  L <- c(L, .bloque(4, "Productividad y competitividad", eco$productividad))
  L <- c(L, .bloque(4, "Mercado minero-energético", eco$minero))
  L <- c(L, .bloque(4, "Turismo", eco$turismo,
                    .piezas_seccion(prov, "05_Economia")))

  # --- 06 Desarrollo Rural ----------------------------------------------------
  L <- c(L, .bloque(3, "Desarrollo Rural",
                    c(.resumen_linea("Desarrollo Rural", resu$desarrollo_rural),
                      seccion_desarrollo_rural(prov, ctx)),
                    .piezas_seccion(prov, "06_Desarrollo_Rural")))

  # --- 07 Ambiental -----------------------------------------------------------
  amb <- seccion_ambiental(prov, ctx)
  L <- c(L, .bloque(3, "Ambiental",
                    c(.resumen_linea("Ambiental", resu$ambiental), amb$intro)))
  L <- c(L, .bloque(4, "Recursos naturales", amb$recursos))
  L <- c(L, .bloque(4, "Sostenibilidad ambiental y cambio climático",
                    amb$sostenibilidad, .piezas_seccion(prov, "07_Ambiental")))

  # --- 08 Educación -----------------------------------------------------------
  L <- c(L, .bloque(3, "Educación",
                    c(.resumen_linea("Educación", resu$educacion),
                      seccion_educacion(prov, ctx)),
                    c(.tabla_md(prov, "08_Educacion", "educacion.xlsx", "educacion",
                                c("Municipio", "Cobertura neta", "Tasa de deserción",
                                  "Tasa de repitencia"),
                                sprintf("Indicadores educativos de la Provincia %s",
                                        prov$etiqueta),
                                "Ministerio de Educación Nacional. Cálculos propios.",
                                porcentaje = c("Cobertura neta", "Tasa de deserción",
                                               "Tasa de repitencia")),
                      .piezas_seccion(prov, "08_Educacion"))))

  # --- 09 Salud ---------------------------------------------------------------
  L <- c(L, .bloque(3, "Salud",
                    c(.resumen_linea("Salud", resu$salud),
                      seccion_salud(prov, ctx)),
                    c(.tabla_md(prov, "09_Salud", "salud.xlsx", "mortalidad_infantil",
                                c("Municipio", "Año",
                                  "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"),
                                sprintf("Mortalidad infantil en la Provincia %s",
                                        prov$etiqueta),
                                "Gobernación de Antioquia, estadísticas vitales. Cálculos propios."),
                      .piezas_seccion(prov, "09_Salud"))))

  # --- 10 Seguridad -----------------------------------------------------------
  seg <- seccion_seguridad(prov, ctx)
  L <- c(L, .bloque(3, "Seguridad, Paz y Derechos Humanos",
                    c(.resumen_linea("Seguridad, Paz y Derechos Humanos", resu$seguridad),
                      seg$intro)))
  L <- c(L, .bloque(4, "Seguridad y convivencia ciudadana", seg$convivencia,
                    .tabla_md(prov, "10_Seguridad", "seguridad.xlsx", "delitos",
                              c("Municipio", "Homicidios por 100.000 hab.",
                                "Hurtos por 100.000 hab.",
                                "Violencia intrafamiliar por 100.000 hab.",
                                "Delitos sexuales por 100.000 hab."),
                              sprintf("Tasas de delitos de alto impacto en la Provincia %s",
                                      prov$etiqueta),
                              "Policía Nacional, SIEDCO. Cálculos propios.")))
  L <- c(L, .bloque(4, "Paz", seg$paz))
  L <- c(L, .bloque(4, "Derechos Humanos", seg$ddhh,
                    .piezas_seccion(prov, "10_Seguridad")))

  # --- La provincia dentro del sistema ---------------------------------------
  # Va al final a propósito: sitúa lo que el lector acaba de leer, en vez de
  # anticiparlo.
  L <- c(L, .bloque(2, "La Provincia en el sistema provincial",
                    seccion_posicion_sistema(prov, ctx, panel_comparativo())))

  # --- Cierre -----------------------------------------------------------------
  L <- c(L, .bloque(2, "Nota sobre las fuentes y los cortes",
    c(paste("Las cifras de este borrador provienen de las tablas que produce el",
            "flujo del proyecto y son trazables hasta su fuente: cada figura deja",
            "sus datos exactos en una hoja del `.xlsx` de su sección."),
      paste("El anexo metodológico (`04_Docs/anexo_metodologico.pdf`) documenta",
            "las fuentes, los protocolos de uso, las reglas de limpieza y",
            "agregación, y las limitaciones conocidas que este informe debe",
            "declarar al publicar sus cifras."))))

  L
}

# --- Conversión a Word --------------------------------------------------------

#' Ruta al ejecutable de pandoc, o "" si no aparece por ningún lado.
#'
#' Se busca primero en el PATH y después en RSTUDIO_PANDOC. RStudio trae su
#' propia copia de pandoc y NO la publica en el PATH, así que en una máquina
#' con RStudio —el caso normal de este proyecto— Sys.which("pandoc") decía
#' que no había pandoc cuando sí lo había, y los once informes salían solo
#' en Markdown. Hallazgo de Pablo (F-5-004), adoptado también aquí.
.ruta_pandoc <- function() {
  p <- unname(Sys.which("pandoc"))
  if (nzchar(p)) return(p)
  dir <- Sys.getenv("RSTUDIO_PANDOC", unset = "")
  if (nzchar(dir)) {
    exe <- file.path(dir, if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc")
    if (file.exists(exe)) return(exe)
  }
  ""
}

.hay_pandoc <- function() nzchar(.ruta_pandoc())

#' Por qué NO sirve el .docx que pandoc acaba de intentar producir.
#'
#' Devuelve character(0) si está bien, o el motivo. Son tres cosas que
#' file.exists() no ve:
#'   - pandoc devolvió error;
#'   - el archivo quedó vacío;
#'   - pandoc terminó BIEN pero no encontró alguna imagen y la sustituyó por
#'     su descripción. Ese caso sale con estado 0 y produce un .docx sin
#'     ninguna figura; es el único modo de fallo que queda vivo al emitir
#'     las rutas en relativo, y el estado de salida no lo delata.
#'
#' La usan este generador y el del comparativo, que comparten el bloque.
#' Hallazgo de Pablo (F-2-050), adoptado también aquí.
.falla_pandoc <- function(salida, docx) {
  estado <- attr(salida, "status") %||% 0L
  if (estado != 0L)         return(sprintf("pandoc devolvió %d", estado))
  if (!file.exists(docx))   return("no se creó el archivo")
  if (file.size(docx) == 0) return("el archivo quedó vacío")
  perdidas <- grep("Could not fetch resource", salida, value = TRUE)
  if (length(perdidas))
    return(sprintf("%d imagen(es) no se encontraron: el .docx saldría sin ellas",
                   length(perdidas)))
  character(0)
}

generar_borrador <- function(id) {
  prov <- provincia(id)
  destino <- file.path(DIR_BORRADORES, prov$carpeta)
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)

  md <- file.path(destino, sprintf("%s_diagnostico.md", prov$carpeta))
  writeLines(markdown_provincia(prov), md, useBytes = TRUE)

  if (!.hay_pandoc()) {
    message("  [borrador] ", prov$etiqueta, " — solo Markdown (falta pandoc)")
    return(invisible(md))
  }

  docx <- file.path(destino, sprintf("%s_diagnostico.docx", prov$carpeta))
  args <- c(shQuote(md), "-o", shQuote(docx),
            "--from", "markdown+pipe_tables+yaml_metadata_block",
            "--toc", "--toc-depth=3",
            # Las rutas de las imágenes son relativas a la raíz, así que este
            # --resource-path es lo que permite resolverlas desde donde sea.
            "--resource-path", shQuote(RUTAS$raiz))
  # El propio Anexo 1 hace de plantilla: así los once borradores heredan los
  # estilos del informe entregado en vez de los de Word por defecto.
  if (file.exists(PLANTILLA)) {
    args <- c(args, "--reference-doc", shQuote(PLANTILLA))
  }
  # pandoc no escribe nada si falla: sin este unlink, el .docx de una corrida
  # anterior pasaría la comprobación de abajo y se anunciaría como recién
  # hecho aunque esta corrida no haya producido nada. Hallazgo de Pablo
  # (F-2-050), adoptado también aquí.
  unlink(docx)
  salida <- suppressWarnings(system2(.ruta_pandoc(), args, stdout = TRUE, stderr = TRUE))
  mal <- .falla_pandoc(salida, docx)
  if (length(mal)) {
    unlink(docx)   # que el disco no contradiga al log
    message("  [borrador] ", prov$etiqueta, " — FALLÓ pandoc: ", mal, "\n    ",
            paste(utils::head(salida, 5), collapse = "\n    "))
    return(invisible(md))
  }
  message("  [borrador] ", prov$etiqueta, " -> ", basename(docx), "  (",
          format(structure(file.size(docx), class = "object_size"),
                 units = "auto", digits = 0), ")")
  invisible(docx)
}

generar_borradores <- function(ids = PROVINCIAS$id) {
  message("== Borradores provinciales ==")
  construir_plantilla()
  if (!.hay_pandoc()) {
    # warning(), no message(): que no salga ningún .docx es fácil de perder
    # entre el resto del log (F-2-050). El consejo ya no asume macOS, y
    # nombra RSTUDIO_PANDOC porque es la causa más probable de que esto
    # dispare en este proyecto: RStudio trae su propia copia de pandoc sin
    # publicarla en el PATH (F-5-004). Las dos, adoptadas también aquí.
    warning("no se encuentra pandoc: se generará solo el Markdown y ningún ",
            ".docx. Instálelo desde https://pandoc.org/installing.html, o corra ",
            "esto desde RStudio, que trae su propia copia (RSTUDIO_PANDOC).",
            call. = FALSE)
  }
  invisible(lapply(ids, generar_borrador))
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "generar_borrador.R") {
  .cli <- commandArgs(trailingOnly = TRUE)
  generar_borradores(if (length(.cli)) as.integer(.cli) else PROVINCIAS$id)
}
