# =============================================================================
# infraestructura_internet.R — Accesos fijos a internet, Antioquia 2025
#
# INPUTS:  01_Data/00_Inputs/EMPAQUETAMIENTO_FIJO_3.csv  (MinTIC; no versionado)
# OUTPUTS: 01_Data/01_Derived/infraestructura_internet_2025.dta
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/"Infraestructura internet.do"
#
# El insumo no cabe en el repositorio (ver .gitignore y el README de 00_Inputs).
# Si falta, este script se detiene con un mensaje claro y el resto del pipeline
# sigue: la sección que lo usa trabaja con el derivado ya generado.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== infraestructura de internet ==")

ruta <- entrada("EMPAQUETAMIENTO_FIJO_3.csv")   # aborta con mensaje si no está

datos <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE) |>
  as.data.frame()

c_depto <- col_req(datos, "id_departamento")
c_mpio  <- col_req(datos, "id_municipio")
c_anno  <- col_req(datos, "anno", "año", "anio")

antioquia <- datos |>
  dplyr::filter(as.integer(.data[[c_depto]]) == 5L,
                as.integer(.data[[c_anno]]) == 2025L) |>
  dplyr::rename(ind_mpio = dplyr::all_of(c_mpio)) |>
  dplyr::mutate(ind_mpio = as.integer(ind_mpio))

if (nrow(antioquia) == 0) {
  stop("No quedaron registros de Antioquia (departamento 5) para 2025 en ",
       basename(ruta), ". Verifique que el archivo corresponda al año esperado.",
       call. = FALSE)
}

escribir_derivado(antioquia, "infraestructura_internet_2025")
message("  infraestructura_internet_2025.dta: ", nrow(antioquia), " registros")
