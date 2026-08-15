# =============================================================================
# generar_esqueleto.R — Esqueleto del diagnóstico de una provincia
#
# Produce, para cada provincia, un borrador en Markdown con:
#   - la estructura del Anexo 1 (10 secciones y sus subsecciones),
#   - las cifras de encuadre ya resueltas desde el crosswalk y las tablas,
#   - el inventario real de tablas, figuras y mapas disponibles por sección,
#   - un marcador <!-- ESCRIBIR: ... --> en cada punto que exige interpretación,
#   - las advertencias que la sección debe recoger (04_Docs/plan_escritura).
#
# Lo que este script NO hace es redactar. Genera lo que se puede derivar del
# dato y deja marcado, punto por punto, lo que hay que escribir. Un párrafo
# interpretativo generado automáticamente sería una afirmación sin autor.
#
# USO:
#   Rscript 02_Code/05_documento/generar_esqueleto.R        # las once
#   Rscript 02_Code/05_documento/generar_esqueleto.R 2 4    # solo estas
#
# REQUIERE: haber corrido el pipeline (Rscript 02_Code/run_all.R)
# SALIDA:   04_Docs/borradores/<Provincia>/esqueleto.md
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

DIR_BORRADORES <- file.path(RUTAS$raiz, "04_Docs", "borradores")

# --- Estructura del Anexo 1 ---------------------------------------------------
# Los diez encabezados y sus subsecciones, tal como están en el documento
# publicado. El campo `escribir` es lo que hay que redactar en esa sección: no
# es una sugerencia de estilo, es el encargo.

ESTRUCTURA <- list(
  list(carpeta = "01_Generalidades", titulo = "Generalidades — contexto departamental y provincial",
       sub = character(0),
       escribir = c(
         "Encuadre: qué es esta provincia, qué la distingue en Antioquia y contra qué se compara en todo el documento.",
         "Lectura del mapa de localización: qué rodea a la provincia y qué implica esa posición.",
         "Excepciones administrativas: municipios que no pertenecen a la subregión mayoritaria.")),
  list(carpeta = "02_Demografia", titulo = "Demografía", sub = character(0),
       escribir = c(
         "Dónde se concentra la población y por qué (mapa de densidad).",
         "Qué dice la estructura por edad sobre la próxima década.",
         "Migración: hacia dónde y desde dónde, y qué municipios pierden población.")),
  list(carpeta = "03_Ordenamiento", titulo = "Ordenamiento del Territorio",
       sub = c("Planes de Ordenamiento Territorial", "Tránsito y transporte",
               "Ciencia, Tecnología e Innovación", "Vivienda y servicios"),
       escribir = c(
         "Estado de los instrumentos de ordenamiento y qué implica para la formulación del Plan.",
         "Conectividad vial: qué municipios quedan aislados y respecto de qué corredor.",
         "Déficit de vivienda: si el patrón es contiguo o disperso (mapa).",
         "Brecha digital: acceso a internet fijo y gobierno digital.")),
  list(carpeta = "04_Gobernabilidad", titulo = "Gobernabilidad y capacidades territoriales",
       sub = c("Gobernabilidad", "Finanzas territoriales",
               "Índice de Ciudades Modernas (ICM)"),
       escribir = c(
         "Capacidad institucional: qué municipios pueden ejecutar y cuáles no.",
         "Sostenibilidad fiscal y margen de maniobra para el Plan.",
         "Lectura del ICM y de sus dimensiones en el tiempo.")),
  list(carpeta = "05_Economia", titulo = "Economía y desarrollo",
       sub = c("Pobreza y mercado laboral", "Productividad y competitividad",
               "Mercado minero-energético", "Turismo"),
       escribir = c(
         "Estructura productiva: de qué vive la provincia y qué tan concentrada está.",
         "Pobreza y mercado laboral: dónde se concentra la informalidad.",
         "Geografía del valor agregado per cápita (mapa) y su relación con la población.",
         "Vocación minero-energética y turística: activos reales frente a potencial declarado.")),
  list(carpeta = "06_Desarrollo_Rural", titulo = "Desarrollo Rural", sub = character(0),
       escribir = c(
         "Vocación agropecuaria: qué produce la provincia y con qué rendimiento.",
         "Concentración de la producción en pocos municipios o reparto amplio.",
         "Relación entre uso actual del suelo y uso adecuado.")),
  list(carpeta = "07_Ambiental", titulo = "Ambiental",
       sub = c("Recursos naturales", "Sostenibilidad ambiental y cambio climático"),
       escribir = c(
         "Áreas protegidas: qué proporción del territorio y bajo qué figura.",
         "Pérdida de cobertura arbórea: dónde y a qué ritmo (mapa).",
         "Riesgo de desastres y calidad del agua: municipios críticos.")),
  list(carpeta = "08_Educacion", titulo = "Educación", sub = character(0),
       escribir = c(
         "Cobertura, deserción y repitencia: brechas internas de la provincia (mapa).",
         "Tránsito a la educación superior y qué lo condiciona.")),
  list(carpeta = "09_Salud", titulo = "Salud", sub = character(0),
       escribir = c(
         "Aseguramiento: composición por régimen y qué dice sobre la estructura del empleo.",
         "Mortalidad infantil y bajo peso al nacer: dónde se concentran (mapa).",
         "Enfermedades transmitidas por vectores: qué municipios y por qué.")),
  list(carpeta = "10_Seguridad", titulo = "Seguridad, Paz y Derechos Humanos",
       sub = c("Seguridad y convivencia ciudadana", "Paz", "Derechos Humanos"),
       escribir = c(
         "Geografía interna de la violencia homicida (mapa provincial).",
         "La provincia frente al departamento (mapa departamental): patrón propio o regional.",
         "Huella del conflicto armado: hechos victimizantes y restitución de tierras.",
         "Economías ilegales: coca y explotación de oro de aluvión."))
)

# Advertencias obligatorias por sección (ver 04_Docs/plan_escritura_provincial.md).
ADVERTENCIAS <- list(
  "05_Economia" = c(
    "El valor agregado va a precios constantes de 2015; el Anexo 1 lo publicó a corrientes. No son comparables entre sí.",
    "Las cifras de turismo receptivo cuentan visitantes extranjeros no residentes, no turistas totales."),
  "08_Educacion" = c(
    "La cobertura neta supera el 100 % en varios municipios-año. Viene así de la fuente: una cobertura NETA no puede exceder el 100 %. Declararlo."),
  "09_Salud" = c(
    "En municipios con pocos nacimientos, la mortalidad infantil se mueve mucho con un solo caso: no leerla como tendencia.",
    "Los cortes de salud son posteriores al informe de 2026 (2023 y diciembre de 2025)."),
  "10_Seguridad" = c(
    "La encuesta de percepción es representativa a nivel de SUBREGIÓN, no de provincia. Rotularla así.",
    "Los hechos victimizantes son VICTIMIZACIONES, no personas: una persona puede aparecer en más de un hecho."),
  "03_Ordenamiento" = c(
    "El catastro no cubre todos los municipios: declarar los que faltan en vez de dejarlos en blanco.")
)

# --- Inventario real de la provincia -----------------------------------------

#' Hojas de tabla de una sección (excluye las hojas de datos de figura).
.hojas_de <- function(prov, seccion) {
  dir_sec <- file.path(RUTAS$outputs, prov$carpeta, seccion)
  if (!dir.exists(dir_sec)) return(character(0))
  xlsx <- list.files(dir_sec, pattern = "\\.xlsx$", full.names = TRUE)
  unlist(lapply(xlsx, function(f) {
    hojas <- tryCatch(openxlsx2::wb_load(f)$get_sheet_names(),
                      error = function(e) character(0))
    hojas <- hojas[!startsWith(hojas, "_")]
    if (!length(hojas)) return(character(0))
    paste0(basename(f), " :: ", hojas)
  }))
}

#' Figuras y mapas exportados de una sección.
.piezas_de <- function(prov, seccion) {
  dir_fig <- file.path(RUTAS$outputs, prov$carpeta, seccion, "figuras")
  if (!dir.exists(dir_fig)) return(list(figuras = character(0), mapas = character(0)))
  png <- sort(sub("\\.png$", "", list.files(dir_fig, pattern = "\\.png$")))
  list(figuras = png[!startsWith(png, "mapa_")],
       mapas   = png[startsWith(png, "mapa_")])
}

#' Cifras de encuadre de la provincia, leídas de las tablas ya generadas.
#' Devuelve NA en lo que no esté: el esqueleto dice "sin dato", no inventa.
.encuadre <- function(prov) {
  cw <- crosswalk_provincias()
  m <- cw[cw$id_provincia == prov$id, ]
  fuera <- m[m$subregion != subregion_dominante(prov), ]

  leer <- function(seccion, archivo, hoja) {
    ruta <- file.path(RUTAS$outputs, prov$carpeta, seccion, archivo)
    if (!file.exists(ruta)) return(NULL)
    tryCatch(openxlsx2::wb_to_df(openxlsx2::wb_load(ruta), sheet = hoja),
             error = function(e) NULL)
  }
  suma_mpios <- function(d, columna) {
    if (is.null(d) || !columna %in% names(d)) return(NA_real_)
    cod <- suppressWarnings(as.integer(d[["Código DANE"]]))
    sum(suppressWarnings(as.numeric(d[[columna]][!is.na(cod)])), na.rm = TRUE)
  }

  pob <- leer("02_Demografia", "demografia.xlsx", "poblacion")
  area <- leer("01_Generalidades", "distribucion_territorial.xlsx",
               "distribucion_territorial")

  list(
    municipios = m,
    n = nrow(m),
    subregion = subregion_dominante(prov),
    subregiones = sort(unique(m$subregion)),
    fuera_de_subregion = fuera,
    poblacion = suma_mpios(pob, "Población total"),
    urbana = suma_mpios(pob, "Población urbana"),
    rural = suma_mpios(pob, "Población rural"),
    area_km2 = suma_mpios(area, "Área municipal (km²)")
  )
}

# --- Escritura del esqueleto --------------------------------------------------

esqueleto_provincia <- function(id) {
  prov <- provincia(id)
  destino <- file.path(DIR_BORRADORES, prov$carpeta)
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  ruta <- file.path(destino, "esqueleto.md")

  e <- .encuadre(prov)
  con <- file(ruta, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  L <- function(...) cat(..., "\n", sep = "", file = con)

  pct <- function(x, y) if (is.na(x) || is.na(y) || y == 0) "—" else
    pct_co(x / y * 100, dec = 1)
  n_ <- function(x) if (is.na(x)) "—" else num_co(x, 0)

  # --- Cabecera ---------------------------------------------------------------
  L("<!-- Generado por 02_Code/05_documento/generar_esqueleto.R el ",
    format(Sys.Date(), "%Y-%m-%d"), ". -->")
  L("<!-- Las cifras de encuadre salen de las tablas ya generadas; no se editan",
    " a mano. -->")
  L("<!-- Cada marcador ESCRIBIR es un encargo de redacción, no una sugerencia. -->")
  L("")
  L("# Diagnóstico Integral Territorial")
  L("## Provincia ", prov$etiqueta)
  L("")
  L("> **Cómo usar este archivo.** Redacte sobre los marcadores `ESCRIBIR`. Las",
    " cifras de encuadre y los inventarios ya están resueltos: si una cifra es",
    " incorrecta, se corrige en el pipeline y se regenera este esqueleto, no se",
    " edita aquí. Antes de dar una sección por terminada, pase la lista de",
    " verificación de `04_Docs/plan_escritura_provincial.md` §7.")
  L("")

  # --- Encuadre ---------------------------------------------------------------
  L("---")
  L("")
  L("## Cifras de encuadre")
  L("")
  L("| | |")
  L("|---|---|")
  L("| Municipios | ", e$n, " |")
  L("| Subregión mayoritaria | ", e$subregion, " |")
  L("| Subregiones que la componen | ", paste(e$subregiones, collapse = ", "), " |")
  L("| Población total (2025) | ", n_(e$poblacion), " |")
  L("| Población urbana | ", n_(e$urbana), " (", pct(e$urbana, e$poblacion), ") |")
  L("| Población rural | ", n_(e$rural), " (", pct(e$rural, e$poblacion), ") |")
  L("| Extensión | ", n_(e$area_km2), " km² |")
  L("| Densidad | ",
    if (is.na(e$poblacion) || is.na(e$area_km2) || e$area_km2 == 0) "—"
    else paste0(num_co(e$poblacion / e$area_km2, 1), " hab/km²"), " |")
  L("")
  L("**Municipios:** ", paste(sort(e$municipios$municipio), collapse = ", "), ".")
  L("")
  if (nrow(e$fuera_de_subregion)) {
    L("**Excepción administrativa.** ",
      paste(e$fuera_de_subregion$municipio, "pertenece a la subregión",
            e$fuera_de_subregion$subregion, collapse = "; "),
      ", y no a ", e$subregion, ".")
  } else {
    L("**Excepción administrativa.** Ninguna: los ", e$n,
      " municipios pertenecen a la subregión ", e$subregion, ".")
  }
  L("")
  L("<!-- ESCRIBIR: encuadre de la provincia. Qué la distingue en Antioquia,",
    " qué la articula internamente y contra qué se compara en todo el documento.",
    " Referencia obligatoria: Guía Metodológica del DNP y Hechos Provinciales de",
    " la versión preliminar del Plan. -->")
  L("")

  # --- Secciones --------------------------------------------------------------
  for (s in ESTRUCTURA) {
    hojas <- .hojas_de(prov, s$carpeta)
    piezas <- .piezas_de(prov, s$carpeta)

    L("---")
    L("")
    L("## ", s$titulo)
    L("")
    plural <- function(n, sing, plur) paste(n, if (n == 1) sing else plur)
    L("<details><summary>Material disponible (",
      plural(length(hojas), "tabla", "tablas"), " · ",
      plural(length(piezas$figuras), "figura", "figuras"), " · ",
      plural(length(piezas$mapas), "mapa", "mapas"), ")</summary>")
    L("")
    if (length(hojas)) {
      L("**Tablas** — `03_Outputs/", prov$carpeta, "/", s$carpeta, "/`")
      L("")
      for (h in hojas) L("- `", h, "`")
      L("")
    }
    if (length(piezas$mapas)) {
      L("**Mapas** — `.../", s$carpeta, "/figuras/`")
      L("")
      for (f in piezas$mapas) L("- `", f, ".png`")
      L("")
    }
    if (length(piezas$figuras)) {
      L("**Figuras**")
      L("")
      for (f in piezas$figuras) L("- `", f, ".png`")
      L("")
    }
    if (!length(hojas) && !length(piezas$figuras)) {
      L("_Sin material generado. Corra `Rscript 02_Code/run_all.R`._")
      L("")
    }
    L("</details>")
    L("")

    adv <- ADVERTENCIAS[[s$carpeta]]
    if (!is.null(adv)) {
      L("> **Advertencias que esta sección debe recoger**")
      L(">")
      for (a in adv) L("> - ", a)
      L("")
    }

    if (length(s$sub)) {
      for (sub in s$sub) {
        L("### ", sub)
        L("")
        L("<!-- ESCRIBIR -->")
        L("")
      }
      L("**Encargos de la sección completa:**")
      L("")
    }
    for (enc in s$escribir) L("<!-- ESCRIBIR: ", enc, " -->")
    L("")
  }

  # --- Cierre -----------------------------------------------------------------
  L("---")
  L("")
  L("## Verificación antes de entregar")
  L("")
  L("- [ ] Cada cifra del texto está en una hoja del `.xlsx` de su sección")
  L("- [ ] Cada afirmación lleva su año en la primera mención")
  L("- [ ] Cada figura y cada mapa del cuerpo tienen un párrafo que los usa")
  L("- [ ] Hay comparación explícita contra subregión y departamento")
  L("- [ ] Los municipios sin dato están declarados, no leídos como cero")
  L("- [ ] Se nombraron las excepciones territoriales")
  L("- [ ] Ninguna conclusión va más allá de lo que el dato sostiene")
  L("- [ ] Se recogieron las advertencias marcadas en cada sección")

  message("  [esqueleto] ", prov$etiqueta, " -> 04_Docs/borradores/",
          prov$carpeta, "/esqueleto.md")
  invisible(ruta)
}

generar_esqueletos <- function(ids = PROVINCIAS$id) {
  message("== Esqueletos de redacción ==")
  invisible(lapply(ids, esqueleto_provincia))
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "generar_esqueleto.R") {
  .cli <- commandArgs(trailingOnly = TRUE)
  generar_esqueletos(if (length(.cli)) as.integer(.cli) else PROVINCIAS$id)
}
