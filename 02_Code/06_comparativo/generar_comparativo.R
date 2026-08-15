# =============================================================================
# generar_comparativo.R — El documento comparativo de las once provincias
#
# Produce un .docx que lee las once provincias juntas: cuánto del departamento
# cubre el sistema provincial, cómo se ordenan las provincias en cada dimensión
# y qué perfil dibuja cada una. Es la lectura que ningún informe provincial
# puede dar por sí solo.
#
# Comparte estilos, sistema visual y reglas de redacción con los borradores
# provinciales: la prosa sale del panel y cada afirmación se apoya en una cifra
# calculada; lo que exige conocimiento de campo queda marcado para verificar.
#
# USO:    Rscript 02_Code/06_comparativo/generar_comparativo.R
# SALIDA: 04_Docs/comparativo/Comparativo_provincias.docx
#
# ETAPA DEL PIPELINE: comparativo
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
source(file.path(RUTAS$codigo, "05_documento", "R", "diagnosticos.R"), encoding = "UTF-8")
source(file.path(RUTAS$codigo, "06_comparativo", "figuras_comparativas.R"),
       encoding = "UTF-8")
source(file.path(RUTAS$codigo, "05_documento", "generar_borrador.R"),
       encoding = "UTF-8")

DIR_COMP <- file.path(RUTAS$raiz, "04_Docs", "comparativo")

# --- Utilidades de lectura del panel ------------------------------------------

.f0 <- function(x) num_co(x, 0)
.f1 <- function(x) num_co(x, 1)
.f2 <- function(x) num_co(x, 2)
.fp <- function(x) pct_co(x * 100, dec = 1)

#' Provincia con el valor extremo de una columna del panel.
.extremo_panel <- function(panel, columna, mayor = TRUE, fmt = .f0, n = 1) {
  d <- panel[!is.na(panel[[columna]]), , drop = FALSE]
  if (!nrow(d)) return(NULL)
  i <- utils::head(order(d[[columna]], decreasing = mayor), n)
  list(nombres = d$provincia[i], valores = d[[columna]][i],
       texto = y_lista(sprintf("%s (%s)", d$provincia[i], fmt(d[[columna]][i]))))
}

#' Razón entre el valor máximo y el mínimo del panel para una columna.
.razon_panel <- function(panel, columna) {
  v <- panel[[columna]]; v <- v[!is.na(v) & v > 0]
  if (length(v) < 2) return(NA_real_)
  max(v) / min(v)
}

# --- Composición del documento ------------------------------------------------

markdown_comparativo <- function(panel) {
  .contador$fig <- 0; .contador$tab <- 0
  cob <- cobertura_sistema(panel)
  ref <- referencia_departamental()
  pos <- tabla_posiciones(panel)
  fig_dir <- file.path(RUTAS$outputs, "_Comparativo", "figuras")
  medio <- stats::aggregate(puesto ~ provincia, pos, stats::median)
  medio <- medio[order(medio$puesto), ]

  L <- c(
    "---",
    'title: "Las once provincias de Antioquia, comparadas"',
    'subtitle: "Análisis comparativo del sistema provincial"',
    'author: "Proyecto Provincias · Planes Estratégicos Provinciales de Antioquia"',
    sprintf('date: "%s"', .fecha_es()),
    "lang: es",
    "---",
    "",
    "> **Cómo leer este documento.** Compara las once Provincias Administrativas",
    "> y de Planificación entre sí y frente al departamento. Todas las cifras",
    "> salen de las mismas tablas que publican los informes provinciales: si una",
    "> provincia dice un número en su informe, aquí dice exactamente el mismo.",
    "> Las notas **Verificar con el equipo** marcan lo que el dato no sostiene",
    "> por sí solo.",
    "")

  # --- 1. El sistema provincial dentro del departamento ----------------------
  L <- c(L, .bloque(2, "El sistema provincial dentro de Antioquia"))
  L <- c(L, .p(
    sprintf(paste(
      "Las once Provincias Administrativas y de Planificación agrupan %d de los",
      "%d municipios de Antioquia. Ese %s de los municipios reúne el %s de la",
      "población departamental y el %s de su territorio. La diferencia entre",
      "las tres cifras ya dice algo sobre el diseño del esquema: cubre más",
      "población que territorio, porque los municipios que quedan fuera son en",
      "promedio más extensos y menos poblados."),
      cob$municipios_provincia, cob$municipios_departamento,
      pct_co(cob$municipios_provincia / cob$municipios_departamento * 100, dec = 1),
      pct_co(cob$poblacion_provincias / cob$poblacion_departamento * 100, dec = 1),
      pct_co(cob$area_provincias / cob$area_departamento * 100, dec = 1)),

    sprintf(paste(
      "Los %d municipios que no pertenecen a ninguna provincia ocupan %s km² y",
      "albergan %s habitantes. No son un residuo: son casi la mitad del",
      "territorio del departamento. Cualquier lectura de los Planes",
      "Estratégicos Provinciales como instrumento de ordenamiento departamental",
      "tiene que decir qué ocurre con ese resto."),
      cob$municipios_departamento - cob$municipios_provincia,
      .f0(cob$area_departamento - cob$area_provincias),
      .f0(cob$poblacion_departamento - cob$poblacion_provincias))
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c01_cobertura_sistema.png"),
                    "Cobertura del sistema provincial sobre el departamento"))
  L <- c(L, .figura(file.path(fig_dir, "fig_c02_mapa_densidad.png"),
                    "Las once provincias y su densidad poblacional"))

  # --- 2. Tamaño y forma ------------------------------------------------------
  L <- c(L, .bloque(2, "Tamaño y forma de las provincias"))
  pob_alto <- .extremo_panel(panel, "poblacion", TRUE, .f0, 1)
  pob_bajo <- .extremo_panel(panel, "poblacion", FALSE, .f0, 2)
  area_alto <- .extremo_panel(panel, "area_km2", TRUE, function(x) paste0(.f0(x), " km²"), 2)
  rur_alto <- .extremo_panel(panel, "pct_rural", TRUE, .fp, 2)
  n_rural <- sum(panel$pct_rural >= 0.5, na.rm = TRUE)

  L <- c(L, .p(
    sprintf(paste(
      "El sistema es profundamente asimétrico. %s concentra por sí sola %s",
      "habitantes, mientras que %s no llegan a esa escala. La razón entre la",
      "provincia más poblada y la menos poblada es de %s a 1; en extensión, la",
      "razón es de %s a 1, con %s a la cabeza."),
      pob_alto$nombres[1], .f0(pob_alto$valores[1]), pob_bajo$texto,
      .f0(.razon_panel(panel, "poblacion")),
      .f1(.razon_panel(panel, "area_km2")), area_alto$texto),

    sprintf(paste(
      "Esa asimetría no es un defecto de diseño sino el reflejo de que el",
      "Área Metropolitana entra al esquema con la lógica de una conurbación y",
      "las otras diez con la de un territorio rural. De hecho, %d de las once",
      "provincias tienen más de la mitad de su población en centros poblados y",
      "rural disperso; las más rurales son %s. Comparar la primera con las",
      "otras diez en cualquier indicador per cápita exige tener presente esta",
      "diferencia de naturaleza."),
      n_rural, rur_alto$texto)
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c04_poblacion.png"),
                    "Población por provincia"))
  L <- c(L, .figura(file.path(fig_dir, "fig_c05_ruralidad.png"),
                    "Ruralidad por provincia"))
  L <- c(L, .tabla_panel(panel, c("provincia", "n_municipios", "poblacion",
                                  "area_km2", "densidad", "pct_rural"),
                         c("Provincia", "Municipios", "Población 2025",
                           "Extensión (km²)", "Densidad (hab/km²)",
                           "Población rural"),
                         "Tamaño y forma de las once provincias",
                         "DANE y Gobernación de Antioquia. Cálculos propios.",
                         porcentaje = "Población rural"))

  # --- 3. Condiciones de vida -------------------------------------------------
  L <- c(L, .bloque(2, "Condiciones de vida y desarrollo territorial"))
  nbi_alto <- .extremo_panel(panel, "nbi", TRUE, .fp, 3)
  nbi_bajo <- .extremo_panel(panel, "nbi", FALSE, .fp, 2)
  icm_alto <- .extremo_panel(panel, "icm", TRUE, .f1, 2)
  icm_bajo <- .extremo_panel(panel, "icm", FALSE, .f1, 2)
  sobre_dep <- sum(panel$nbi > ref$nbi, na.rm = TRUE)

  L <- c(L, .p(
    sprintf(paste(
      "La pobreza por Necesidades Básicas Insatisfechas separa al sistema en",
      "dos bloques. En el extremo alto están %s; en el bajo, %s. De las once",
      "provincias, %d superan la incidencia departamental de %s."),
      nbi_alto$texto, nbi_bajo$texto, sobre_dep, .fp(ref$nbi)),

    sprintf(paste(
      "El Índice de Ciudades Modernas ordena a las provincias de forma",
      "parecida pero no idéntica: encabezan %s y cierran %s, frente a un valor",
      "departamental de %s. Que los dos ordenamientos no coincidan del todo es",
      "informativo: el ICM incorpora dimensiones de gestión pública, seguridad",
      "y sostenibilidad que el NBI no mide, de modo que una provincia puede",
      "tener carencias materiales y aun así una institucionalidad relativamente",
      "sólida, o al revés."),
      icm_alto$texto, icm_bajo$texto, .f1(ref$icm))
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c06_nbi.png"),
                    "Pobreza por NBI en las once provincias"))
  L <- c(L, .figura(file.path(fig_dir, "fig_c03_mapa_nbi.png"),
                    "Geografía provincial de la pobreza por NBI"))
  L <- c(L, .figura(file.path(fig_dir, "fig_c07_icm.png"),
                    "Índice de Ciudades Modernas por provincia"))

  # --- 4. Las relaciones entre dimensiones ------------------------------------
  L <- c(L, .bloque(2, "Cómo se relacionan las dimensiones"))
  sin_am <- panel[panel$id_provincia != 11, ]
  r_rur <- stats::cor(panel$pct_rural, panel$nbi, use = "complete.obs")
  r_rur_s <- stats::cor(sin_am$pct_rural, sin_am$nbi, use = "complete.obs")
  r_icm_nbi <- stats::cor(sin_am$icm, sin_am$nbi, use = "complete.obs")
  r_int_imca <- stats::cor(sin_am$internet, sin_am$imca, use = "complete.obs")
  r_dens_def <- stats::cor(sin_am$densidad, sin_am$deficit_cuali, use = "complete.obs")
  r_dep_mi <- stats::cor(sin_am$dependencia, sin_am$mortalidad_infantil,
                         use = "complete.obs")

  L <- c(L, .p(
    sprintf(paste(
      "Una comparación entre once territorios permite ver qué indicadores se",
      "mueven juntos. Conviene empezar por una relación que **no** aparece. La",
      "ruralidad y la pobreza por NBI muestran una correlación de %s entre las",
      "once provincias, pero al excluir al Área Metropolitana —que está en un",
      "extremo de las dos variables— la relación cae a %s, es decir, %s. Entre",
      "las diez provincias rurales, ser más rural no predice tener más pobreza."),
      num_co(r_rur, 2), num_co(r_rur_s, 2), describir_r(r_rur_s)),

    paste(
      "El resultado importa para la formulación: si la ruralidad explicara la",
      "pobreza, la política sería la misma en las diez provincias y variaría",
      "solo en intensidad. Como no la explica, lo que diferencia a una",
      "provincia pobre de una menos pobre hay que buscarlo en otra parte."),

    sprintf(paste(
      "Las relaciones que sí son fuertes entre esas diez provincias apuntan en",
      "esa dirección. El Índice de Ciudades Modernas y la pobreza por NBI se",
      "mueven en direcciones opuestas con una correlación de %s; el acceso a",
      "internet fijo y la competitividad medida por el IMCA van juntos (%s); la",
      "densidad poblacional y el déficit cualitativo de vivienda se oponen",
      "(%s); y la dependencia económica acompaña a la mortalidad infantil (%s).",
      "El patrón que dibujan no es la ruralidad sino la **capacidad**:",
      "institucional, de infraestructura y de servicios."),
      num_co(r_icm_nbi, 2), num_co(r_int_imca, 2),
      num_co(r_dens_def, 2), num_co(r_dep_mi, 2)),

    paste(
      "**Estas correlaciones describen, no explican.** Con diez u once",
      "observaciones no sostienen ninguna inferencia causal, y no se presentan",
      "como tal. Sirven para dos cosas concretas: saber qué indicadores son",
      "redundantes al construir un tablero de seguimiento, y detectar",
      "regularidades que valga la pena investigar con otros métodos.")
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c09_ruralidad_nbi.png"),
                    "Ruralidad y pobreza por NBI"))
  L <- c(L, .figura(file.path(fig_dir, "fig_c10_icm_nbi.png"),
                    "Desarrollo territorial y pobreza por NBI"))

  # --- 5. Seguridad -----------------------------------------------------------
  L <- c(L, .bloque(2, "Seguridad y huella del conflicto"))
  hom_alto <- .extremo_panel(panel, "homicidios", TRUE, .f1, 3)
  hom_bajo <- .extremo_panel(panel, "homicidios", FALSE, .f1, 2)
  vic_alto <- .extremo_panel(panel, "victimas_pc", TRUE, .f1, 2)

  L <- c(L, .p(
    sprintf(paste(
      "La violencia homicida es la dimensión donde el sistema muestra mayor",
      "dispersión. Las tasas más altas corresponden a %s y las más bajas a %s,",
      "frente a un valor departamental de %s por cada cien mil habitantes. La",
      "razón entre el extremo alto y el bajo es de %s a 1: ninguna otra",
      "dimensión de este panel separa tanto a las provincias entre sí."),
      hom_alto$texto, hom_bajo$texto, .f1(ref$homicidios),
      .f1(.razon_panel(panel, "homicidios"))),

    sprintf(paste(
      "La huella del conflicto armado sigue una geografía propia. Medidas por",
      "cada mil habitantes, las victimizaciones por ocurrencia son más altas en",
      "%s. Conviene recordar que son victimizaciones y no personas, y que",
      "corresponden a hechos acumulados a lo largo de décadas: describen el",
      "daño histórico, no la situación de seguridad presente."),
      vic_alto$texto)
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c08_homicidios.png"),
                    "Homicidios por provincia"))

  # --- 6. El perfil de cada provincia -----------------------------------------
  L <- c(L, .bloque(2, "El perfil de cada provincia"))
  mejor <- medio$provincia[1]
  peor <- medio$provincia[nrow(medio)]

  L <- c(L, .p(
    sprintf(paste(
      "Ordenando a cada provincia en cada indicador y tomando su puesto",
      "mediano, %s ocupa la mejor posición del conjunto y %s la última. Pero el",
      "promedio esconde lo importante: **ninguna provincia está bien o mal en",
      "todo**. La figura siguiente muestra el puesto de cada una en los %d",
      "indicadores con orientación normativa, y lo que se ve es un mosaico, no",
      "una escalera."),
      mejor, peor, length(unique(pos$indicador))),

    paste(
      "Esa heterogeneidad es la justificación práctica del esquema asociativo.",
      "Si todas las provincias tuvieran el mismo perfil, la respuesta correcta",
      "sería una política departamental uniforme. Como no lo tienen, cada Plan",
      "Estratégico tiene que priorizar de forma distinta, y el sistema en su",
      "conjunto puede aprovechar que la fortaleza de una es la debilidad de",
      "otra.")
  ), "")
  L <- c(L, .figura(file.path(fig_dir, "fig_c11_perfil_posiciones.png"),
                    "Puesto de cada provincia, indicador por indicador"))

  # --- 7. Cómo leer estas comparaciones ---------------------------------------
  L <- c(L, .bloque(2, "Cómo leer estas comparaciones"))
  L <- c(L, .p(
    paste(
      "**Los agregados provinciales no se calculan igual en todos los",
      "indicadores.** Cada uno usa el ponderador que le corresponde: población",
      "para las tasas por habitante, nacimientos para las medidas por",
      "nacimiento, población escolar para las educativas, y suma directa para",
      "los conteos. El anexo metodológico documenta la regla de cada uno."),
    paste(
      "**Los cortes no son simultáneos.** Los indicadores de la ECV son de",
      "2023, los de salud llegan hasta diciembre de 2025, el valor agregado va",
      "a precios constantes de 2015 y los delitos son de 2025. Comparar",
      "provincias en un mismo indicador es válido —todas usan el mismo corte—;",
      "sumar indicadores de cortes distintos en un índice compuesto, no."),
    paste(
      "**El Área Metropolitana es un caso aparte.** Entra al sistema con una",
      "escala y una naturaleza distintas de las otras diez. En varias figuras",
      "aparece en un extremo, y ese extremo describe una diferencia de tipo,",
      "no de grado."),
    paste(
      "**Los puestos son ordinales.** Que una provincia ocupe el puesto 3 no",
      "dice a qué distancia está de la 2 ni de la 4. Para eso están las cifras",
      "del panel, que acompañan a cada figura.")
  ), "")
  L <- c(L, verificar(
    "si el esquema asociativo tiene hoy instancias de coordinación entre ",
    "provincias, y si los Hechos Provinciales de los once Planes preliminares ",
    "coinciden entre sí. Este panel compara resultados; no dice nada sobre las ",
    "apuestas que cada Provincia ya definió."), "")

  L
}

#' Tabla del panel como tabla de Markdown.
.tabla_panel <- function(panel, columnas, encabezados, titulo, fuente_txt,
                         porcentaje = character(0)) {
  d <- panel[, columnas, drop = FALSE]
  names(d) <- encabezados
  .contador$tab <- (.contador$tab %||% 0) + 1
  fmt <- function(x, es_pct) {
    if (!is.numeric(x)) return(ifelse(is.na(x), "—", as.character(x)))
    if (es_pct) return(ifelse(is.na(x), "—", pct_co(x * 100, dec = 1)))
    dec <- if (all(abs(x - round(x)) < 1e-9, na.rm = TRUE)) 0 else 1
    ifelse(is.na(x), "—", num_co(x, dec))
  }
  cuerpo <- as.data.frame(mapply(fmt, d, encabezados %in% porcentaje,
                                 SIMPLIFY = FALSE), stringsAsFactors = FALSE)
  names(cuerpo) <- encabezados
  c(sprintf("**Tabla %d.** %s", .contador$tab, titulo), "",
    paste0("| ", paste(encabezados, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(encabezados)), collapse = "|"), "|"),
    apply(cuerpo, 1, function(f) paste0("| ", paste(f, collapse = " | "), " |")),
    "", sprintf("*%s*", fuente(fuente_txt)), "")
}

# --- Generación ---------------------------------------------------------------

generar_comparativo <- function() {
  message("== Documento comparativo ==")
  dir.create(DIR_COMP, recursive = TRUE, showWarnings = FALSE)
  construir_plantilla()

  panel <- construir_panel()
  guardar_panel(panel)
  generar_figuras_comparativas(panel)

  md <- file.path(DIR_COMP, "Comparativo_provincias.md")
  writeLines(markdown_comparativo(panel), md, useBytes = TRUE)

  if (!nzchar(Sys.which("pandoc"))) {
    message("  [comparativo] solo Markdown (falta pandoc)")
    return(invisible(md))
  }
  docx <- file.path(DIR_COMP, "Comparativo_provincias.docx")
  args <- c(shQuote(md), "-o", shQuote(docx),
            "--from", "markdown+pipe_tables+yaml_metadata_block",
            "--toc", "--toc-depth=2",
            "--resource-path", shQuote(RUTAS$raiz))
  if (file.exists(PLANTILLA)) args <- c(args, "--reference-doc", shQuote(PLANTILLA))
  salida <- suppressWarnings(system2("pandoc", args, stdout = TRUE, stderr = TRUE))
  if (!file.exists(docx)) {
    message("  [comparativo] FALLÓ pandoc:\n    ",
            paste(utils::head(salida, 5), collapse = "\n    "))
    return(invisible(md))
  }
  message("  [comparativo] ", basename(docx), "  (",
          format(structure(file.size(docx), class = "object_size"),
                 units = "auto", digits = 0), ")")
  invisible(docx)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "generar_comparativo.R") {
  generar_comparativo()
}
