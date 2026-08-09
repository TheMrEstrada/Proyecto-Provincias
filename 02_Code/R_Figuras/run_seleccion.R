# ============================================================================
# run_seleccion.R  —  Fase 4 (verificación): corre TODAS las secciones para una
#   SELECCIÓN de provincias y reporta si el código se ejecuta sin errores.
#   REQUISITO: correr DESPUÉS del flujo Stata de cada provincia (exports frescos).
# ============================================================================

# ┌──────────────────────────────────────────────────────────────────────────┐
# │  EDITA AQUÍ las provincias a probar (incluye la 4 de ejemplo). 1..11       │
# └──────────────────────────────────────────────────────────────────────────┘
provincias <- c(4, 3, 1)   # <-- cámbialas por tu selección

# ---------------------------------------------------------------------------
# (De aquí para abajo no hay que modificar nada)
# ---------------------------------------------------------------------------
.self <- (function() {
  a <- commandArgs(FALSE); f <- grep("^--file=", a, value = TRUE)
  if (length(f)) return(dirname(normalizePath(sub("^--file=", "", f[1]))))
  for (fr in rev(sys.frames())) { of <- tryCatch(fr$ofile, error = function(e) NULL); if (!is.null(of)) return(dirname(normalizePath(of))) }
  normalizePath(getwd())
})()
R <- function(x) file.path(.self, x)
id_provincia <- provincias[1]
source(R("R/00_setup.R")); source(R("R/00_config.R")); source(R("R/01_tema.R")); source(R("R/02_utils.R"))
for (f in list.files(R("R/fig"), pattern = "\\.R$", full.names = TRUE)) source(f)

.carpetas <- c("Agroindustrial_Occidente","Bioenergetica_Norte","Rio_Grande",
               "Turistica_Agroecologica","Agua_Bosques_Turismo","Cartama",
               "De_la_Paz","San_Juan","Minero_Agroecologica",
               "Penderisco_Sinifana","Area_Metropolitana")
.secciones <- list(
  list("01_Generalidades",   "distribucion_territorial.xlsx", "figuras_generalidades"),
  list("02_Demografia",      "demografia.xlsx",               c("figuras_demografia","tablas_demografia")),
  list("03_Ordenamiento",    "ordenamiento.xlsx",             "figuras_ordenamiento"),
  list("04_Gobernabilidad",  "gobernabilidad.xlsx",           "figuras_gobernabilidad"),
  list("05_Economia",        "economia.xlsx",                 "figuras_economia"),
  list("06_Desarrollo_Rural","desarrollo_rural.xlsx",         "figuras_desarrollo_rural"),
  list("07_Ambiental",       "ambiental.xlsx",                "figuras_ambiental"),
  list("08_Educacion",       "educacion.xlsx",                "figuras_educacion"),
  list("09_Salud",           "salud.xlsx",                    "figuras_salud"),
  list("10_Seguridad",       "seguridad.xlsx",                "figuras_seguridad")
)

resumen <- list()
for (pid in provincias) {
  carp <- .carpetas[pid]; outdir <- file.path(PROJ_ROOT, "03_Outputs", carp)
  message("\n################  PROVINCIA ", pid, " (", carp, ")  ################")
  for (sec in .secciones) {
    f <- file.path(outdir, sec[[1]], sec[[2]]); tag <- sprintf("P%02d/%s", pid, sec[[1]])
    if (!file.exists(f)) { message("  SALTA (no existe export): ", f); resumen[[tag]] <- "sin_export"; next }
    message("== ", sec[[1]])
    ok <- tryCatch({
      wb <- openxlsx2::wb_load(f); for (fn in sec[[3]]) wb <- get(fn)(wb); openxlsx2::wb_save(wb, f); TRUE
    }, error = function(e) { message("  ERROR ", tag, ": ", conditionMessage(e)); FALSE })
    resumen[[tag]] <- if (ok) "ok" else "ERROR"
  }
}

message("\n=====================  RESUMEN  =====================")
for (k in names(resumen)) message(sprintf("  %-28s %s", k, resumen[[k]]))
if (any(unlist(resumen) == "ERROR")) {
  message("\n>> Hubo ERRORES de ejecución (ver arriba).")
} else {
  message("\n>> Todas las secciones de las provincias seleccionadas corrieron SIN errores de ejecución.")
}
