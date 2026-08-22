# =============================================================================
# crosswalk_territorial.R — Crosswalk municipio → provincia → subregión
#
# Produce la tabla que usan casi todas las secciones del diagnóstico para saber
# a qué provincia y subregión pertenece cada municipio.
#
# INPUTS:
#   01_Data/00_Inputs/MUNICIPIOS_SUBREG_PROV.xlsx   (125 municipios de Antioquia)
#   01_Data/00_Inputs/códigos_municipios_clean.dta  (código DANE por municipio)
# OUTPUTS:
#   01_Data/01_Derived/codigos_provincias.dta  (90 municipios en las 11 provincias)
#   01_Data/01_Derived/subreg_completo.dta     (los 125, con su subregión DANE)
#
# ETAPA DEL PIPELINE: 1. homogeneización
#
# Migrado de 00_BuildData.do (líneas 164-256), con dos correcciones:
#
#   1. El derivado se escribe en 01_Derived, no en 00_Inputs. La carpeta de
#      insumos guarda fuentes, no resultados del pipeline.
#   2. El emparejamiento provincia → id ya no depende de la grafía exacta. El
#      código Stata compara contra la cadena literal
#      "POVINCIA DEL AGUA, BOSQUES Y TURISMO" (sin la R), que era como venía el
#      Excel; el Excel se corrigió después ("Update MUNICIPIOS_SUBREG_PROV.xlsx",
#      2026-08-05) y hoy dice "PROVINCIA DEL AGUA...". Con el código Stata
#      original, esos 12 municipios se quedarían hoy sin id_provincia y la
#      provincia 5 desaparecería del crosswalk. Aquí el emparejamiento normaliza
#      el texto y acepta ambas grafías.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== crosswalk territorial ==")

# --- Insumos ------------------------------------------------------------------
mpios <- leer_excel(entrada("MUNICIPIOS_SUBREG_PROV.xlsx"))
codigos <- haven::read_dta(entrada("códigos_municipios_clean.dta")) |>
  dplyr::mutate(
    ind_mpio = as.integer(ind_mpio),
    nvl_label = normalizar_municipio(as.character(nvl_label))
  ) |>
  dplyr::select(ind_mpio, nvl_label)

# --- Emparejar el nombre de provincia con su id -------------------------------
# Se compara sobre texto normalizado y tolerando "POVINCIA"/"PROVINCIA", para
# que el cruce no dependa de erratas de la fuente.
.clave_provincia <- function(x) {
  norm_txt(x) |>
    stringr::str_replace("^povincia\\b", "provincia") |>
    stringr::str_remove_all("[^a-z ]") |>
    stringr::str_squish()
}

referencia <- data.frame(
  clave = .clave_provincia(PROVINCIAS$nombre_datos),
  id_provincia = PROVINCIAS$id,
  stringsAsFactors = FALSE
)

crosswalk <- mpios |>
  dplyr::rename(provincia = `Esquema asociativo`, subregion = `Subregión`) |>
  dplyr::filter(!is.na(provincia), stringr::str_squish(provincia) != "") |>
  dplyr::mutate(
    nvl_label = normalizar_municipio(MPIO),
    # el listado del Excel usa nombres cortos para dos municipios
    nvl_label = ifelse(nvl_label == "CAROLINA", "CAROLINA DEL PRINCIPE", nvl_label),
    nvl_label = ifelse(nvl_label == "SAN VICENTE", "SAN VICENTE FERRER", nvl_label),
    provincia = as.character(provincia),
    subregion = as.character(subregion),
    clave = .clave_provincia(provincia)
  ) |>
  dplyr::left_join(referencia, by = "clave")

sin_id <- dplyr::filter(crosswalk, is.na(id_provincia))
if (nrow(sin_id)) {
  stop("Hay esquemas asociativos que no coinciden con ninguna de las 11 provincias:\n  ",
       paste(unique(sin_id$provincia), collapse = "\n  "),
       "\nRevise la tabla PROVINCIAS en 02_Code/R/00_config.R.", call. = FALSE)
}

# Nombre de presentación: como viene del listado oficial, pero con artículos y
# preposiciones en minúscula ("San José de la Montaña") y con los nombres
# completos que el listado abrevia. Es la forma en que aparecen en el informe.
.nombre_presentacion <- function(x) {
  y <- stringr::str_squish(as.character(x))
  y <- stringr::str_replace_all(y, "\\b(De|Del|La|Las|Los|El|Y)\\b", tolower)
  y <- stringr::str_replace(y, "^(de|del|la|las|los|el|y)\\b",
                            function(m) stringr::str_to_title(m))
  completos <- c(
    "Carolina"    = "Carolina del Príncipe",
    "San Vicente" = "San Vicente Ferrer"
  )
  ifelse(y %in% names(completos), completos[y], y)
}

crosswalk <- crosswalk |>
  dplyr::inner_join(codigos, by = "nvl_label") |>
  # `municipio` es el nombre de presentación; `nvl_label` es la forma
  # normalizada (MAYÚSCULAS sin tildes) con la que se cruza contra otras fuentes.
  dplyr::mutate(municipio = .nombre_presentacion(MPIO)) |>
  dplyr::select(ind_mpio, nvl_label, municipio, subregion, provincia, id_provincia) |>
  dplyr::arrange(ind_mpio)

# --- Verificaciones -----------------------------------------------------------
# El universo lo define la fuente, no una constante escrita a mano: si el
# listado incorpora o pierde un municipio, el esperado cambia con él, y una
# pérdida en el cruce deja de ser invisible (con una constante fija, una
# pérdida que por coincidencia cuadrara con el número esperado pasaría sin
# avisar). Hallazgo de Pablo (F-4-003), adoptado también aquí.
con_esquema <- !is.na(mpios$`Esquema asociativo`) &
  stringr::str_squish(mpios$`Esquema asociativo`) != ""
esperado <- sum(con_esquema)
if (nrow(crosswalk) != esperado) {
  # Las mismas dos correcciones de nombre que se aplican arriba al cruzar
  # (CAROLINA -> CAROLINA DEL PRINCIPE, SAN VICENTE -> SAN VICENTE FERRER):
  # sin ellas, el diagnóstico acusa en falso a municipios que sí cruzaron bien.
  claves <- normalizar_municipio(mpios$MPIO[con_esquema])
  claves <- ifelse(claves == "CAROLINA", "CAROLINA DEL PRINCIPE", claves)
  claves <- ifelse(claves == "SAN VICENTE", "SAN VICENTE FERRER", claves)
  perdidos <- setdiff(claves, crosswalk$nvl_label)
  stop("El crosswalk quedó con ", nrow(crosswalk), " municipios y la fuente asigna ", esperado, ".\n",
       "Municipios sin código DANE: ", paste(perdidos, collapse = ", "), call. = FALSE)
}
stopifnot(
  "hay municipios duplicados"  = !any(duplicated(crosswalk$ind_mpio)),
  "faltan provincias"          = setequal(crosswalk$id_provincia, PROVINCIAS$id)
)

# --- Subregión DANE de los 125 municipios -------------------------------------
subreg_completo <- mpios |>
  dplyr::mutate(
    ind_mpio = as.integer(DPMP),
    subregion_full = as.character(`Subregión`)
  ) |>
  dplyr::select(ind_mpio, subregion_full) |>
  dplyr::arrange(ind_mpio)

# --- Guardar ------------------------------------------------------------------
escribir_derivado(crosswalk, "codigos_provincias")
escribir_derivado(subreg_completo, "subreg_completo")

message("  codigos_provincias.dta: ", nrow(crosswalk), " municipios en ",
        dplyr::n_distinct(crosswalk$id_provincia), " provincias")
message("  subreg_completo.dta:    ", nrow(subreg_completo), " municipios de Antioquia")
