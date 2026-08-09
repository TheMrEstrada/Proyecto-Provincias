# ============================================================================
# 00_config.R  —  Configuración del pipeline de figuras (portable entre usuarios)
# ============================================================================
# Este archivo define DOS cosas: qué provincia procesar y dónde está el proyecto.
# Está pensado para funcionar SIN cambios en cualquier clon del repo (cualquier ruta).

# ----------------------------------------------------------------------------
# 1. PROVINCIA A PROCESAR  (1..11)
#    La elige el usuario en run_provincia.R (variable id_provincia).
#    Este archivo solo la valida; NO la fija.
#    Prioridad: variable de entorno ID_PROVINCIA > id_provincia de run_provincia.R > 4.
# ----------------------------------------------------------------------------
.env_prov <- Sys.getenv("ID_PROVINCIA", unset = "")
if (nzchar(.env_prov)) {
  id_provincia <- as.integer(.env_prov)          # override opcional para automatizar
} else if (!exists("id_provincia")) {
  id_provincia <- 4L                              # respaldo si se corre config suelto
}
id_provincia <- as.integer(id_provincia)
stopifnot(id_provincia %in% 1:11)

# ----------------------------------------------------------------------------
# 2. RAÍZ DEL PROYECTO  (se detecta sola; no requiere configurar rutas)
#    Regla: se sube desde la ubicación del script hasta la carpeta que contiene
#    "03_Outputs" — esa es la raíz del repo, en cualquier máquina.
#    Escape: si defines la variable de entorno PROVINCIAS_ROOT, se usa esa.
# ----------------------------------------------------------------------------
.script_dir <- function() {
  a <- commandArgs(FALSE)                                  # caso: Rscript archivo.R
  f <- grep("^--file=", a, value = TRUE)
  if (length(f)) return(dirname(normalizePath(sub("^--file=", "", f[1]))))
  for (fr in rev(sys.frames())) {                          # caso: source() en RStudio
    of <- tryCatch(fr$ofile, error = function(e) NULL)
    if (!is.null(of)) return(dirname(normalizePath(of)))
  }
  normalizePath(getwd())                                   # último recurso
}
.find_root <- function(start) {
  d <- start
  repeat {
    if (dir.exists(file.path(d, "03_Outputs"))) return(d)
    p <- dirname(d)
    if (identical(p, d))
      stop("No encuentro la raíz del proyecto (una carpeta que contenga '03_Outputs'). ",
           "Corre el script desde dentro del repo, o define PROVINCIAS_ROOT.")
    d <- p
  }
}
PROJ_ROOT <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
if (!nzchar(PROJ_ROOT)) PROJ_ROOT <- .find_root(.script_dir())

# ----------------------------------------------------------------------------
# 3. Derivados (no modificar)
# ----------------------------------------------------------------------------
.carpetas <- c("Agroindustrial_Occidente","Bioenergetica_Norte","Rio_Grande",
               "Turistica_Agroecologica","Agua_Bosques_Turismo","Cartama",
               "De_la_Paz","San_Juan","Minero_Agroecologica",
               "Penderisco_Sinifana","Area_Metropolitana")
provincia_carpeta <- .carpetas[id_provincia]
OUT_DIR <- file.path(PROJ_ROOT, "03_Outputs", provincia_carpeta)

# Ruta del .xlsx de una sección; valida existencia con mensaje claro.
xlsx_seccion <- function(subcarpeta, archivo) {
  f <- file.path(OUT_DIR, subcarpeta, archivo)
  if (!file.exists(f))
    stop("No existe:\n  ", f,
         "\n¿Corriste el flujo de Stata para la provincia ", id_provincia,
         " (", provincia_carpeta, ")? El export de esa sección debe existir antes de correr R.")
  f
}

message(sprintf("Proyecto: %s", PROJ_ROOT))
message(sprintf("Provincia %d -> %s", id_provincia, provincia_carpeta))
