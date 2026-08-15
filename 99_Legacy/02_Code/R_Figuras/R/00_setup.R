# ============================================================================
# 00_setup.R  —  Dependencias del pipeline de figuras (instala en R fresco)
#   Replicable: en una instalación limpia instala lo necesario desde CRAN.
#   Se ejecuta al inicio de run_provincia.R (no requiere acción manual).
# ============================================================================

# Paquetes requeridos y versión mínima probada
.pkgs_pipeline <- c(
  openxlsx2 = "1.28",   # workbook + gráficos nativos + estilos de celda
  encharter = "0.10"    # API de gráficos nativos de Excel (familia openxlsx2)
)
# Nota: openxlsx2 arrastra R6, Rcpp y stringi automáticamente;
#       encharter depende de R6 + openxlsx2 (>= 1.26).

# Fijar un mirror de CRAN si la sesión no tiene uno
local({
  r <- getOption("repos")
  if (is.null(r[["CRAN"]]) || is.na(r[["CRAN"]]) || r[["CRAN"]] == "@CRAN@")
    options(repos = c(CRAN = "https://cloud.r-project.org"))
})

# Aviso de versión de R (las versiones nuevas de estos paquetes piden R >= 4.4)
if (getRversion() < "4.4.0")
  warning("Se recomienda R >= 4.4. Con R más antiguo puede que CRAN no ofrezca ",
          "la versión requerida de openxlsx2/encharter.")

# Instalar lo que falte (o esté por debajo de la versión mínima) y cargar todo
local({
  for (p in names(.pkgs_pipeline)) {
    faltante <- !requireNamespace(p, quietly = TRUE) ||
                utils::packageVersion(p) < .pkgs_pipeline[[p]]
    if (faltante) {
      message(sprintf(">> Instalando %s (>= %s) desde CRAN ...", p, .pkgs_pipeline[[p]]))
      utils::install.packages(p)
    }
  }
  ok <- vapply(names(.pkgs_pipeline),
               function(p) requireNamespace(p, quietly = TRUE), logical(1))
  if (!all(ok))
    stop("No se pudieron instalar: ", paste(names(.pkgs_pipeline)[!ok], collapse = ", "),
         ". Revisa tu conexión a CRAN y la versión de R.")
  suppressMessages(invisible(lapply(names(.pkgs_pipeline), library, character.only = TRUE)))
  message(sprintf("Dependencias listas: %s",
          paste(sprintf("%s %s", names(.pkgs_pipeline),
                        vapply(names(.pkgs_pipeline),
                               function(p) as.character(utils::packageVersion(p)), character(1))),
                collapse = " | ")))
})
