# ============================================================================
# run_provincia.R  —  Orquestador: regenera TODAS las figuras de una provincia.
# REQUISITO: correr DESPUÉS del flujo Stata (que reescribe los .xlsx sin figuras).
# Funciona desde cualquier carpeta y en cualquier clon del repo.
# ============================================================================

# ┌──────────────────────────────────────────────────────────────────────────┐
# │  ELIGE AQUÍ LA PROVINCIA A PROCESAR  (1..11)                               │
# │    1 Agroindustrial Occidente   2 Bioenergética Norte    3 Río Grande      │
# │    4 Turística y Agroecológica  5 Agua, Bosques y Turismo 6 Cartama        │
# │    7 De la Paz   8 San Juan   9 Minero Agroecológica                       │
# │   10 Penderisco y Sinifana     11 Área Metropolitana                       │
# └──────────────────────────────────────────────────────────────────────────┘
id_provincia <- 4

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
source(R("R/00_setup.R")); source(R("R/00_config.R")); source(R("R/01_tema.R")); source(R("R/02_utils.R"))
for (f in list.files(R("R/fig"), pattern = "\\.R$", full.names = TRUE)) source(f)

# Secciones: subcarpeta, archivo, función(es) que insertan figuras+tablas
# FASE DE VALIDACIÓN: activas solo las secciones ya validadas.
# Se van descomentando a medida que se validan (evita sobrescribir con versión previa).
.secciones <- list(
  list("01_Generalidades",   "distribucion_territorial.xlsx", "figuras_generalidades"),
  list("02_Demografia",      "demografia.xlsx",               c("figuras_demografia","tablas_demografia"))
  , list("03_Ordenamiento",    "ordenamiento.xlsx",             "figuras_ordenamiento")
  , list("04_Gobernabilidad",  "gobernabilidad.xlsx",           "figuras_gobernabilidad")
  , list("05_Economia",        "economia.xlsx",                 "figuras_economia")
    , list("06_Desarrollo_Rural","desarrollo_rural.xlsx",         "figuras_desarrollo_rural")
    , list("07_Ambiental",       "ambiental.xlsx",                "figuras_ambiental")
    , list("08_Educacion",       "educacion.xlsx",                "figuras_educacion")
    , list("09_Salud",           "salud.xlsx",                    "figuras_salud")
    , list("10_Seguridad",       "seguridad.xlsx",                "figuras_seguridad")
)

message(sprintf(">> Provincia %d (%s)", id_provincia, provincia_carpeta))
for (sec in .secciones) {
  f <- xlsx_seccion(sec[[1]], sec[[2]])
  message("== ", sec[[1]])
  wb <- openxlsx2::wb_load(f)
  for (fn in sec[[3]]) wb <- get(fn)(wb)
  openxlsx2::wb_save(wb, f)
}
message(">> Listo. Figuras y tablas insertadas en 03_Outputs/", provincia_carpeta, "/")
