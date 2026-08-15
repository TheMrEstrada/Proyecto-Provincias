# =============================================================================
# panel_provincial.R — Las once provincias en una sola tabla
#
# Reúne, para cada provincia, el valor de un conjunto de indicadores comparables,
# leídos de las salidas que el flujo ya publicó. Es la base de todo el análisis
# comparativo: sin una tabla común, comparar once informes exige abrirlos uno a
# uno y confiar en que cada uno calculó igual.
#
# DE DÓNDE SALE CADA VALOR
#   De la hoja .xlsx de la sección correspondiente, no de los derivados. Si el
#   informe provincial dice una cifra, el panel dice exactamente la misma: son
#   la misma celda leída dos veces.
#
# TRES FORMAS DE OBTENER EL VALOR PROVINCIAL, DECLARADAS POR INDICADOR
#   fila        el valor que la propia hoja publica en su fila de provincia,
#               con el método de agregación que la sección decidió;
#   suma        la suma de los municipios (para magnitudes sumables que la hoja
#               no agrega);
#   promedio    el promedio simple de los municipios (solo donde la hoja no
#               publica agregado y el promedio es la lectura correcta).
#   Nunca se inventa un agregado: si la hoja no lo publica y no es sumable, el
#   indicador se queda fuera del panel.
#
# USO:    Rscript 02_Code/06_comparativo/panel_provincial.R
# SALIDA: 04_Docs/comparativo/panel_provincial.csv
#         03_Outputs/_Comparativo/panel_provincial.xlsx
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
source(file.path(RUTAS$codigo, "05_documento", "R", "frases.R"), encoding = "UTF-8")

DIR_COMP <- file.path(RUTAS$raiz, "04_Docs", "comparativo")
DIR_SALIDA_COMP <- file.path(RUTAS$outputs, "_Comparativo")

# --- Catálogo de indicadores comparables --------------------------------------
# `sentido`: +1 si más es mejor, -1 si más es peor, 0 si no tiene orientación
# normativa (extensión, población). Es lo que permite decir «ocupa el puesto 3
# de 11» sin que el puesto signifique lo contrario de lo que parece.

IND <- function(id, etiqueta, seccion, archivo, hoja, columna, via = "fila",
                sentido = 0, formato = "num", dominio = "") {
  list(id = id, etiqueta = etiqueta, seccion = seccion, archivo = archivo,
       hoja = hoja, columna = columna, via = via, sentido = sentido,
       formato = formato, dominio = dominio)
}

INDICADORES <- list(
  IND("area_km2", "Extensión territorial (km²)", "01_Generalidades",
      "distribucion_territorial.xlsx", "distribucion_territorial",
      "Área municipal (km²)", "suma", 0, "num", "Territorio"),
  IND("poblacion", "Población total (2025)", "02_Demografia",
      "demografia.xlsx", "poblacion", "Población total", "suma", 0, "num",
      "Territorio"),
  IND("pob_rural", "Población rural (2025)", "02_Demografia",
      "demografia.xlsx", "poblacion", "Población rural", "suma", 0, "num",
      "Territorio"),
  IND("envejecimiento", "Índice de envejecimiento", "02_Demografia",
      "demografia.xlsx", "natalidad_mortalidad", "Índice de Envejecimiento",
      "fila", 0, "num", "Demografía"),
  IND("natalidad", "Tasa de natalidad", "02_Demografia",
      "demografia.xlsx", "natalidad_mortalidad", "Tasa de Natalidad",
      "fila", 0, "num", "Demografía"),
  IND("dependencia", "Índice de dependencia económica", "05_Economia",
      "economia.xlsx", "dependencia_economica", "Índice de Dependencia Económica",
      "fila", -1, "num", "Demografía"),

  IND("deficit_cuanti", "Déficit cuantitativo de vivienda", "03_Ordenamiento",
      "ordenamiento.xlsx", "deficit_vivienda", "Déficit cuantitativo de vivienda",
      "fila", -1, "pct", "Ordenamiento"),
  IND("deficit_cuali", "Déficit cualitativo de vivienda", "03_Ordenamiento",
      "ordenamiento.xlsx", "deficit_vivienda", "Déficit cualitativo de vivienda",
      "fila", -1, "pct", "Ordenamiento"),
  IND("acueducto", "Cobertura de acueducto", "03_Ordenamiento",
      "ordenamiento.xlsx", "servicios_publicos", "Cobertura de acueducto (municipal)",
      "promedio", 1, "pct", "Ordenamiento"),
  IND("alcantarillado", "Cobertura de alcantarillado", "03_Ordenamiento",
      "ordenamiento.xlsx", "servicios_publicos",
      "Cobertura de alcantarillado (municipal)", "promedio", 1, "pct",
      "Ordenamiento"),
  IND("internet", "Internet fijo por 1.000 hab.", "03_Ordenamiento",
      "ordenamiento.xlsx", "internet_2025",
      "Líneas de acceso a internet fijo por cada 1.000 habitantes", "fila", 1,
      "num", "Ordenamiento"),
  IND("via_terciaria", "Km de vía terciaria por km²", "03_Ordenamiento",
      "ordenamiento.xlsx", "vias_area", "Km de vía terciaria por km² del municipio",
      "fila", 1, "num3", "Ordenamiento"),
  IND("gob_digital", "Índice de Gobierno Digital", "03_Ordenamiento",
      "ordenamiento.xlsx", "gobierno_digital", "Índice de Gobierno Digital",
      "fila", 1, "num", "Gobernabilidad"),
  IND("imca", "IMCA total", "03_Ordenamiento", "ordenamiento.xlsx", "imca",
      "IMCA total", "fila", 1, "num", "Gobernabilidad"),
  IND("icm", "Índice de Ciudades Modernas", "04_Gobernabilidad",
      "gobernabilidad.xlsx", "icm", "ICM", "fila", 1, "num", "Gobernabilidad"),

  IND("nbi", "Pobreza por NBI", "05_Economia", "economia.xlsx", "ecv_pobreza",
      "Personas en pobreza por NBI - total (agregado)", "fila", -1, "pct",
      "Economía"),
  IND("ipm", "Pobreza multidimensional (IPM)", "05_Economia", "economia.xlsx",
      "ecv_ipm", "Personas en pobreza IPM - total (agregado)", "fila", -1, "pct",
      "Economía"),
  IND("informalidad", "Informalidad laboral", "05_Economia", "economia.xlsx",
      "ecv_ocupacion_informal", "Tasa de informalidad laboral - total (municipal)",
      "promedio", -1, "pct", "Economía"),
  IND("va_pc", "Valor agregado per cápita ($ de 2015)", "05_Economia",
      "economia.xlsx", "valor_agregado",
      "Valor agregado per cápita (pesos constantes de 2015)", "fila", 1, "num",
      "Economía"),
  IND("dens_emp", "Densidad empresarial (x 1.000 hab.)", "05_Economia",
      "economia.xlsx", "densidad_empresarial",
      "Densidad empresarial (empresas por cada 1.000 hab.)", "fila", 1, "num2",
      "Economía"),

  IND("rendimiento", "Rendimiento agrícola (t/ha)", "06_Desarrollo_Rural",
      "desarrollo_rural.xlsx", "rendimiento", "Rendimiento (t/ha)", "fila", 1,
      "num2", "Rural"),
  IND("pecuario", "Inventario pecuario (cabezas)", "06_Desarrollo_Rural",
      "desarrollo_rural.xlsx", "inventario_pecuario", "Total especies pecuarias",
      "fila", 0, "num", "Rural"),

  IND("area_protegida", "Área protegida (km²)", "07_Ambiental",
      "ambiental.xlsx", "detalle", "Área sobre municipio (km²)", "suma", 0, "num",
      "Ambiental"),
  IND("perdida_cobertura", "Pérdida de cobertura arbórea 2001-2023",
      "07_Ambiental", "ambiental.xlsx", "perdida_cobertura",
      "Pérdida de cobertura arbórea 2001-2023 (%)", "fila", -1, "pct", "Ambiental"),
  IND("irca", "IRCA (riesgo de calidad del agua)", "07_Ambiental",
      "ambiental.xlsx", "irca", "IRCA", "fila", -1, "num", "Ambiental"),

  IND("cobertura_neta", "Cobertura neta educativa", "08_Educacion",
      "educacion.xlsx", "educacion", "Cobertura neta", "fila", 1, "pct",
      "Educación"),
  IND("desercion", "Deserción escolar", "08_Educacion", "educacion.xlsx",
      "educacion", "Tasa de deserción", "fila", -1, "pct", "Educación"),

  IND("mortalidad_infantil", "Mortalidad infantil (x 1.000 n.v.)", "09_Salud",
      "salud.xlsx", "mortalidad_infantil",
      "Tasa de mortalidad infantil (x 1.000 nacidos vivos)", "fila", -1, "num2",
      "Salud"),
  IND("bajo_peso", "Bajo peso al nacer", "09_Salud", "salud.xlsx", "bajo_peso",
      "Nacidos con bajo peso al nacer (%)", "fila", -1, "pct", "Salud"),
  IND("subsidiado", "Afiliación al régimen subsidiado", "09_Salud",
      "salud.xlsx", "aseguramiento_sgsss", "% afiliados régimen subsidiado",
      "fila", 0, "pct", "Salud"),

  IND("homicidios", "Homicidios por 100.000 hab.", "10_Seguridad",
      "seguridad.xlsx", "delitos", "Homicidios por 100.000 hab.", "fila", -1,
      "num1", "Seguridad"),
  IND("hurtos", "Hurtos por 100.000 hab.", "10_Seguridad", "seguridad.xlsx",
      "delitos", "Hurtos por 100.000 hab.", "fila", -1, "num1", "Seguridad"),
  IND("victimas", "Victimizaciones por ocurrencia", "10_Seguridad",
      "seguridad.xlsx", "total_victimas", "Víctimas por ocurrencia", "fila", -1,
      "num", "Seguridad"),
  IND("desaparecidos", "Personas dadas por desaparecidas", "10_Seguridad",
      "seguridad.xlsx", "desaparecidos", "Personas dadas por desaparecidas",
      "fila", -1, "num", "Seguridad")
)

# --- Lectura ------------------------------------------------------------------

.valor_provincial <- function(prov, ind) {
  d <- hoja_publicada(prov, ind$seccion, ind$archivo, ind$hoja)
  if (is.null(d) || !ind$columna %in% names(d)) return(NA_real_)
  d <- ultimo_anio(d)
  switch(ind$via,
    fila = valor_agregado(d, ind$columna, "provincia"),
    suma = sum(suppressWarnings(as.numeric(solo_municipios(d)[[ind$columna]])),
               na.rm = TRUE),
    promedio = mean(suppressWarnings(as.numeric(solo_municipios(d)[[ind$columna]])),
                    na.rm = TRUE),
    NA_real_
  )
}

#' Valor departamental de un indicador, cuando la hoja lo publica.
#' Sirve de referencia: sin él, una comparación entre provincias no dice si el
#' conjunto está por encima o por debajo de Antioquia.
.valor_departamental <- function(ind) {
  for (id in PROVINCIAS$id) {
    d <- hoja_publicada(provincia(id), ind$seccion, ind$archivo, ind$hoja)
    if (is.null(d) || !ind$columna %in% names(d)) next
    v <- valor_agregado(ultimo_anio(d), ind$columna, "departamento")
    if (!is.na(v)) return(v)
  }
  NA_real_
}

construir_panel <- function() {
  message("== Panel provincial ==")
  cw <- crosswalk_provincias()

  filas <- lapply(PROVINCIAS$id, function(id) {
    prov <- provincia(id)
    vals <- vapply(INDICADORES, function(ind) .valor_provincial(prov, ind),
                   numeric(1))
    names(vals) <- vapply(INDICADORES, function(i) i$id, character(1))
    c(list(id_provincia = id, provincia = prov$etiqueta,
           carpeta = prov$carpeta,
           n_municipios = sum(cw$id_provincia == id),
           subregion = subregion_dominante(prov)),
      as.list(vals))
  })
  panel <- do.call(rbind, lapply(filas, function(f) as.data.frame(f,
                                                                 stringsAsFactors = FALSE)))

  # Densidad y ruralidad se derivan del panel, no se leen: así son coherentes
  # con las dos columnas que las componen.
  panel$densidad <- panel$poblacion / panel$area_km2
  panel$pct_rural <- panel$pob_rural / panel$poblacion
  panel$pct_protegida <- panel$area_protegida / panel$area_km2
  panel$victimas_pc <- panel$victimas / panel$poblacion * 1000

  message("  ", nrow(panel), " provincias x ", length(INDICADORES), " indicadores")
  panel
}

#' Fila de referencia departamental, con lo que se puede obtener.
referencia_departamental <- function() {
  vals <- vapply(INDICADORES, .valor_departamental, numeric(1))
  names(vals) <- vapply(INDICADORES, function(i) i$id, character(1))
  as.data.frame(as.list(vals), stringsAsFactors = FALSE)
}

#' Cobertura del sistema provincial sobre el departamento.
#'
#' Los 125 municipios de Antioquia no están todos en una provincia. Cuánto del
#' departamento queda dentro del esquema asociativo —en municipios, en población
#' y en territorio— es la primera pregunta de cualquier lectura comparativa, y
#' ninguna hoja provincial puede responderla.
cobertura_sistema <- function(panel) {
  sub <- crosswalk_subregiones()
  cw <- crosswalk_provincias()

  area_dep <- NA_real_
  pob_dep <- NA_real_
  d <- hoja_publicada(provincia(1), "01_Generalidades",
                      "distribucion_territorial.xlsx", "distribucion_territorial")
  if (!is.null(d)) area_dep <- valor_agregado(d, "Área municipal (km²)", "departamento")
  p <- hoja_publicada(provincia(1), "02_Demografia", "demografia.xlsx", "poblacion")
  if (!is.null(p)) pob_dep <- valor_agregado(p, "Población total", "departamento")

  list(
    municipios_provincia = nrow(cw),
    municipios_departamento = nrow(sub),
    area_provincias = sum(panel$area_km2, na.rm = TRUE),
    area_departamento = area_dep,
    poblacion_provincias = sum(panel$poblacion, na.rm = TRUE),
    poblacion_departamento = pob_dep
  )
}

# --- Escritura ----------------------------------------------------------------

guardar_panel <- function(panel) {
  dir.create(DIR_COMP, recursive = TRUE, showWarnings = FALSE)
  dir.create(DIR_SALIDA_COMP, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(panel, file.path(DIR_COMP, "panel_provincial.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")

  etiquetas <- c(
    stats::setNames(vapply(INDICADORES, function(i) i$etiqueta, character(1)),
                    vapply(INDICADORES, function(i) i$id, character(1))),
    id_provincia = "Id", provincia = "Provincia", carpeta = "Carpeta",
    n_municipios = "Municipios", subregion = "Subregión mayoritaria",
    densidad = "Densidad (hab/km²)", pct_rural = "Población rural (%)",
    pct_protegida = "Área protegida sobre el territorio (%)",
    victimas_pc = "Victimizaciones por 1.000 hab.")

  archivo <- file.path(DIR_SALIDA_COMP, "panel_provincial.xlsx")
  if (file.exists(archivo)) unlink(archivo)
  escribir_hoja(panel[, setdiff(names(panel), "carpeta")], archivo, "panel",
                etiquetas = etiquetas)
  message("  [panel] 04_Docs/comparativo/panel_provincial.csv")
  invisible(panel)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "panel_provincial.R") {
  guardar_panel(construir_panel())
}
