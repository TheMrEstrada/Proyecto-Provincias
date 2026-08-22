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

# La entrega del MinTIC cambió de formato respecto de la que se usó para
# armar el derivado versionado: antes venía con comas y encabezados en
# minúscula; hoy viene con PUNTO Y COMA y encabezados en MAYÚSCULA.
# read_csv() (separador coma fijo) no fallaba con el separador equivocado:
# devolvía una tabla de una sola columna, y col_req() abortaba después con un
# mensaje que parecía decir "faltan columnas" cuando en realidad sobraba
# separador. Hallazgo de Pablo (F-3-005), adoptado también aquí.

# 1. El separador se detecta, no se supone.
cabecera <- readLines(ruta, n = 1L, warn = FALSE)
sep <- if (stringr::str_count(cabecera, ";") > stringr::str_count(cabecera, ",")) ";" else ","

# 2. Los nombres se resuelven sobre una muestra, no sobre el archivo completo
#    (717 MB). col_req() sigue siendo el guarda si faltara una columna.
muestra <- readr::read_delim(ruta, delim = sep, n_max = 100,
                             col_types = readr::cols(.default = readr::col_character()),
                             show_col_types = FALSE, progress = FALSE)
names(muestra) <- tolower(names(muestra))
c_depto <- col_req(muestra, "id_departamento")
c_mpio  <- col_req(muestra, "id_municipio")
c_anno  <- col_req(muestra, "anno", "año", "anio")

# 3. Lectura por trozos, descartando lo que no es Antioquia 2025 sobre la
#    marcha: evita traer a memoria las filas de los demás departamentos.
#    Todo se lee como texto (si cada trozo adivinara sus tipos por su cuenta,
#    dos trozos podrían adivinar distinto y no se podrían unir) y se convierte
#    al final, sobre las filas que quedan, no sobre las 3,6 millones del país.
recorte <- function(x, pos) {
  names(x) <- tolower(names(x))
  d <- suppressWarnings(as.integer(x[[c_depto]]))
  a <- suppressWarnings(as.integer(x[[c_anno]]))
  x[!is.na(d) & d == 5L & !is.na(a) & a == 2025L, , drop = FALSE]
}
antioquia <- readr::read_delim_chunked(
  ruta, delim = sep,
  callback = readr::DataFrameCallback$new(recorte),
  chunk_size = 200000,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE, progress = FALSE) |>
  as.data.frame() |>
  dplyr::rename(ind_mpio = dplyr::all_of(c_mpio))

# 4. Vuelven a número las columnas que lo son, con el conversor del pipeline
#    (a_numero() resuelve separadores locales; si una entrega futura trae
#    decimales con coma, no hay que tocar nada aquí).
NUMERICAS <- c("anno", "trimestre", "id_empresa", "ind_mpio", "id_departamento",
               "id_segmento", "id_servicio_paquete", "id_tecnologia", "id_estado",
               "cantidad_lineas_accesos", "valor_facturado_o_cobrado",
               "otros_valores_facturados", "valor_total_plan_tarifario")
for (v in intersect(NUMERICAS, names(antioquia))) {
  antioquia[[v]] <- a_numero(antioquia[[v]])
}
antioquia$ind_mpio <- as.integer(antioquia$ind_mpio)

if (nrow(antioquia) == 0) {
  stop("No quedaron registros de Antioquia (departamento 5) para 2025 en ",
       basename(ruta), ". Verifique que el archivo corresponda al año esperado.",
       call. = FALSE)
}

escribir_derivado(antioquia, "infraestructura_internet_2025")
message("  infraestructura_internet_2025: ", nrow(antioquia), " registros",
        "  (separador «", sep, "»)")
