# =============================================================================
# check_pipeline.R — Verificación estática del repositorio
#
# Revisa, sin ejecutar el pipeline, que el repositorio siga sano:
#   1. Ningún script vigente tiene rutas absolutas de una máquina concreta
#   2. Los insumos que el código referencia existen (o están en la lista de
#      fuentes ausentes conocidas)
#   3. No hay nombres en forma descompuesta (NFD) ni colisiones que solo
#      difieren en mayúsculas — rompen en Linux y al mover entre macOS/Windows
#   4. No han reaparecido archivos en carpetas retiradas (pasa al integrar la
#      rama `actualización`, donde el equipo sube por la web de GitHub)
#   5. Las secciones declaradas en run_provincia.R tienen su script o están
#      marcadas como pendientes
#
# USO:  Rscript 02_Code/99_checks/check_pipeline.R
# Termina con código distinto de cero si encuentra errores (no advertencias).
# =============================================================================

.raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
if (!nzchar(.raiz)) {
  .args <- commandArgs(trailingOnly = FALSE)
  .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
  .raiz <- if (length(.f)) dirname(dirname(dirname(normalizePath(.f[1])))) else getwd()
}
source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")

errores <- character(0)
avisos <- character(0)
err <- function(...) errores <<- c(errores, paste0(...))
avi <- function(...) avisos <<- c(avisos, paste0(...))

titulo <- function(x) cat("\n", x, "\n", strrep("-", nchar(x)), "\n", sep = "")

# Scripts vigentes: todo 02_Code menos legacy y el material externo
scripts_vigentes <- function() {
  archivos <- list.files(RUTAS$codigo, pattern = "\\.(R|do)$", recursive = TRUE,
                         full.names = TRUE)
  archivos[!grepl("/externos/|/Tablas_Diagnostico/|/00_Homogeneizacion_Inputs/|/Figuras R/",
                  archivos)]
}

# --- 1. Rutas absolutas -------------------------------------------------------
titulo("1. Rutas absolutas en código vigente")
# La unidad de Windows debe ir pegada a una comilla de apertura; sin eso, un
# texto como "Soluciones:\n" se confundiría con una ruta. El patrón se arma por
# partes para que este archivo no se detecte a sí mismo.
patron_abs <- paste0("[\"'][A-Za-z]:[\\\\/]", "|/", "Us", "ers/", "|/ho", "me/",
                     "|One", "Drive", "|Drop", "box")
n <- 0
for (f in scripts_vigentes()) {
  lineas <- readLines(f, warn = FALSE)
  # se ignoran comentarios: los ejemplos y las notas pueden citar rutas
  codigo <- lineas[!grepl("^\\s*#", lineas)]
  hits <- grep(patron_abs, codigo, value = TRUE)
  if (length(hits)) {
    n <- n + length(hits)
    err("ruta absoluta en ", sub(RUTAS$raiz, "", f, fixed = TRUE), ": ",
        trimws(hits[1]))
  }
}
cat(if (n == 0) "  OK — ninguna\n" else sprintf("  %d referencias absolutas\n", n))

# --- 2. Insumos referenciados -------------------------------------------------
titulo("2. Insumos referenciados por el código")
AUSENTES_CONOCIDAS <- c(
  "PPED-AreaSexoEdadMun-2018-2042_VP.xlsx", "EMPAQUETAMIENTO_FIJO_3.csv",
  "Data anonimizada encuesta percepcion 2018-2025.xlsx",
  "Indicadores_ECV2023.xlsx", "MICRODATOS ECV 2023.dta"
)
citados <- character(0)
for (f in scripts_vigentes()) {
  lineas <- readLines(f, warn = FALSE)
  # Se ignoran los comentarios, igual que en la comprobación 1: la
  # documentación de una función cita ejemplos como entrada("a", "b"), y
  # leerlos como insumos reales produce un error inventado.
  txt <- paste(lineas[!grepl("^\\s*#", lineas)], collapse = "\n")
  m <- regmatches(txt, gregexpr('entrada\\(\\s*"[^"]+"', txt))[[1]]
  citados <- c(citados, sub('entrada\\(\\s*"', "", m))
}
citados <- unique(sub('"$', "", citados))
faltan <- citados[!file.exists(file.path(RUTAS$inputs, citados))]
conocidas <- intersect(faltan, AUSENTES_CONOCIDAS)
inesperadas <- setdiff(faltan, AUSENTES_CONOCIDAS)
cat(sprintf("  %d insumos citados; %d presentes\n", length(citados),
            length(citados) - length(faltan)))
for (x in conocidas) avi("insumo ausente (conocido, ver README): ", x)
for (x in inesperadas) err("insumo citado que no existe: ", x)

# --- 3. Nombres de archivo ----------------------------------------------------
titulo("3. Nombres de archivo (unicode y mayúsculas)")
rastreados <- system2("git", c("-C", shQuote(RUTAS$raiz), "ls-files"),
                      stdout = TRUE, stderr = FALSE)
nfd <- rastreados[rastreados != stringi::stri_trans_nfc(rastreados)]
for (x in nfd) err("nombre en forma descompuesta (NFD): ", x)
dup <- rastreados[duplicated(tolower(rastreados)) |
                    duplicated(tolower(rastreados), fromLast = TRUE)]
for (x in dup) err("colisión que solo difiere en mayúsculas: ", x)
cat(sprintf("  %d archivos rastreados; %d en NFD; %d colisiones\n",
            length(rastreados), length(nfd), length(dup)))

# --- 4. Carpetas retiradas ----------------------------------------------------
titulo("4. Carpetas retiradas en la reestructuración")
RETIRADAS <- c("01_Data/00_Inputs/POTA", "01_Data/00_Inputs/Fichas",
               "02_Code/Tablas_Diagnostico/Figuras R")
for (d in RETIRADAS) {
  reaparecidos <- rastreados[startsWith(rastreados, paste0(d, "/"))]
  if (length(reaparecidos)) {
    err("reaparecieron ", length(reaparecidos), " archivos en ", d,
        " — reubíquelos según MIGRATION.md")
  }
}
cat("  OK — ninguna reapareció\n")

# --- 5. Secciones ------------------------------------------------------------
titulo("5. Estado de las secciones")
source(file.path(RUTAS$codigo, "run_provincia.R"), encoding = "UTF-8")
estado <- vapply(SECCIONES, function(s) {
  t_ok <- !is.na(.script_seccion("03_tablas", s))
  f_ok <- !is.na(.script_seccion("04_figuras", s))
  if (t_ok && f_ok) "completa" else if (t_ok) "solo tablas" else "pendiente"
}, character(1))
for (i in seq_along(SECCIONES)) {
  cat(sprintf("  %-22s %s\n", SECCIONES[[i]]$carpeta, estado[i]))
}
cat(sprintf("  -> %d de %d secciones completas\n", sum(estado == "completa"),
            length(estado)))

# --- Resultado ----------------------------------------------------------------
titulo("Resultado")
if (length(avisos)) {
  cat("Advertencias:\n")
  for (a in avisos) cat("  - ", a, "\n", sep = "")
}
if (length(errores)) {
  cat("\nERRORES:\n")
  for (e in errores) cat("  - ", e, "\n", sep = "")
  cat("\n", length(errores), " error(es).\n", sep = "")
  quit(status = 1)
}
cat("\nSin errores.\n")
