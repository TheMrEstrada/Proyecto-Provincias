# =============================================================================
# ecv.R — Indicadores de la Encuesta de Calidad de Vida (ECV) 2023, Antioquia
#
# Apila las hojas de la ECV municipal y las pasa a formato ancho: una fila por
# municipio y, por cada indicador, tres columnas (total / urbano / rural). Es el
# insumo de las secciones de pobreza, empleo y servicios públicos.
#
# INPUTS:
#   01_Data/00_Inputs/INDICADORES ECV 2023 MUNICIPIOS.xlsx  (10 hojas temáticas)
# OUTPUTS:
#   01_Data/01_Derived/ECV_raw.dta          (las 10 hojas apiladas, formato largo)
#   01_Data/01_Derived/ECV_nbi_pobreza.dta  (125 municipios x 43 indicadores)
#
# ETAPA DEL PIPELINE: 1. homogeneización
#
# Migrado de 00_Homogeneizacion_Inputs/
#   "20260518_HOMOGENEIZACIÓN INDICADORES ECV.do", con una corrección:
#
#   El .do guardaba ECV_raw.dta en $rawdata (01_Data/00_Inputs). Esa carpeta
#   guarda fuentes, no resultados del pipeline, así que aquí el archivo se
#   escribe en 01_Data/01_Derived. La copia heredada en 00_Inputs se deja
#   intacta (no se toca ningún archivo de la carpeta de crudos).
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== ECV 2023 ==")

ruta <- entrada("INDICADORES ECV 2023 MUNICIPIOS.xlsx")   # aborta si no está

# Las diez hojas que usa el diagnóstico, en el orden en que las lista el .do.
HOJAS_ECV <- c("IPM", "NBI", "POBREZA", "INSEGURIDAD ALIMENTARIA", "GINI_HOG",
               "GINI_LAB", "DEMOGRAFÍA", "EMPLEO", "EDUCACIÓN", "VIVIENDA")

# --- Lectura y apilado --------------------------------------------------------
# Los encabezados del Excel traen puntos ("IC.2.5_tot") y Stata los elimina al
# importar ("IC25_tot"); se replica esa limpieza para que ECV_raw.dta conserve
# los nombres con los que ya se conoce el archivo. Las columnas sin encabezado
# (la hoja VIVIENDA trae dos) reciben la letra de su columna en Excel, como
# también hace Stata.

.letra_excel <- function(i) {
  s <- ""
  while (i > 0) {
    r <- (i - 1) %% 26
    s <- paste0(LETTERS[r + 1], s)
    i <- (i - 1) %/% 26
  }
  s
}

.nombres_stata <- function(nombres) {
  n <- stringr::str_remove_all(nombres, "\\.")
  vacios <- which(is.na(n) | !nzchar(stringr::str_squish(n)))
  if (length(vacios)) n[vacios] <- vapply(vacios, .letra_excel, character(1))
  n
}

# Encabezado original de cada columna, para conservarlo como etiqueta.
etiquetas <- character(0)

hojas <- lapply(HOJAS_ECV, function(h) {
  d <- leer_excel(ruta, hoja = h)
  originales <- names(d)
  names(d) <- .nombres_stata(originales)
  nuevos <- setdiff(names(d), names(etiquetas))
  if (length(nuevos)) {
    etiquetas[nuevos] <<- originales[match(nuevos, names(d))]
  }
  # Una columna totalmente vacía llega como lógica; en el .dta es numérica.
  d[] <- lapply(d, function(x) if (is.logical(x)) as.numeric(x) else x)
  d
})
names(hojas) <- HOJAS_ECV

# El .do apila cada hoja *sobre* lo acumulado (`append using`), de modo que el
# archivo termina en el orden inverso al de la lista: VIVIENDA primero e IPM
# último. Se conserva ese orden para que ECV_raw.dta salga idéntico.
crudo <- dplyr::bind_rows(rev(hojas))

# Stata rellena las columnas de texto ausentes con cadena vacía, no con missing.
crudo[] <- lapply(crudo, function(x) if (is.character(x)) ifelse(is.na(x), "", x) else x)

for (cl in names(crudo)) {
  et <- etiquetas[[cl]]
  if (!is.null(et) && nzchar(et)) attr(crudo[[cl]], "label") <- et
}

escribir_derivado(crudo, "ECV_raw")
message("  ECV_raw.dta: ", nrow(crudo), " filas x ", ncol(crudo), " columnas")

# --- Indicadores priorizados: nombre largo -> nombre corto --------------------
# Solo estos 43 pasan al derivado ancho; el resto se descarta (en el .do, con
# `keep if regexm(NomIndicador, "^[A-Za-z0-9_]+$")`, que deja fuera todo lo que
# no se haya renombrado porque los nombres largos traen espacios y tildes).

RENOMBRE_ECV <- c(
  # Demografía y población campesina
  "Porcentaje de hogares con jefe de hogar mujer sin presencia de cónyuge y con hijos menores de 18 años" = "hog_mono_fem",
  "Porcentaje de personas de 15 años o más que pertenecen a la población campesina" = "pbl_camp",
  # Mercado laboral
  "Tasa bruta de participación de las mujeres"          = "tgp_mujeres",
  "Tasa de ocupación"                                   = "to",
  "Tasa de ocupación de los hombres"                    = "to_hombres",
  "Tasa de ocupación de las mujeres"                    = "to_mujeres",
  "Tasa de empleo informal"                             = "emp_informal",
  "Tasa de empleo informal en hombres"                  = "emp_informal_hombres",
  "Tasa de empleo informal en mujeres"                  = "emp_informal_mujeres",
  "Tasa de desocupados"                                 = "td",
  "Tasa de desocupados en los hombres"                  = "td_hombres",
  "Tasa de desocupados en las mujeres"                  = "td_mujeres",
  "Tasa de desocupados para personas entre 15 y 28 años" = "td_15_28",
  "Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados" = "nini",
  # Desigualdad
  "Gini: Ingresos de los hogares"                       = "gini_hog",
  "Gini: Ingresos laborales de las personas ocupadas"   = "gini_lab",
  # Inseguridad alimentaria
  "Inseguridad alimentaria_moderada"                    = "ins_alim_mod",
  "Inseguridad alimentaria_moderada para hogares con personas de 5 años o menos"  = "ins_alim_mod_5",
  "Inseguridad alimentaria_moderada para hogares con personas menores de 18 años" = "ins_alim_mod_18",
  "Inseguridad alimentaria_severa"                      = "ins_alim_sev",
  "Inseguridad alimentaria_severa para hogares con personas de 5 años o menos"    = "ins_alim_sev_5",
  "Inseguridad alimentaria_severa para hogares con personas menores de 18 años"   = "ins_alim_sev_18",
  # Pobreza multidimensional (IPM)
  "Porcentaje de personas pobres - IPM"                 = "pob_ipm",
  "Porcentaje de hombres pobres - IPM"                  = "pob_ipm_hombres",
  "Porcentaje de mujeres pobres - IPM"                  = "pob_ipm_mujeres",
  "Porcentaje de hogares pobres - IPM"                  = "pob_ipm_hogares",
  # Pobreza por NBI
  "Porcentaje de personas en condición de pobreza por NBI" = "pob_nbi",
  "Porcentaje de hombres en condición de pobreza por NBI"  = "pob_nbi_hombres",
  "Porcentaje de mujeres en condición de pobreza por NBI"  = "pob_nbi_mujeres",
  "Porcentaje de hogares en condición de pobreza por NBI"  = "pob_nbi_hogares",
  # Pobreza monetaria y extrema
  "Porcentaje de personas con ingreso per cápita por debajo de la LI" = "pob_ext",
  "Porcentaje de hombres con ingreso per cápita por debajo de la LI"  = "pob_ext_hombres",
  "Porcentaje de mujeres con ingreso per cápita por debajo de la LI"  = "pob_ext_mujeres",
  "Porcentaje de personas con ingreso per cápita por debajo de la LP" = "pob_mon",
  "Porcentaje de hombres con ingreso per cápita por debajo de la LP"  = "pob_mon_hombres",
  "Porcentaje de mujeres con ingreso per cápita por debajo de la LP"  = "pob_mon_mujeres",
  # Servicios públicos de la vivienda
  "Porcentaje de viviendas con SP Alcantarillado"       = "pob_alcantarillado",
  "Porcentaje de viviendas con SP Energía"              = "pob_energia",
  "Porcentaje de viviendas con SP Acueducto"            = "pob_acueducto",
  "Porcentaje de viviendas con SP Recolección Basuras"  = "pob_recoleccion_basuras",
  "Porcentaje de viviendas con servicio de internet"    = "pob_internet",
  "Porcentaje de viviendas con servicio de gas natural por red"  = "pob_gas_natural",
  "Porcentaje de viviendas con servicio de gas licuado en pipeta" = "pob_gas_pipeta"
)

# --- Formato ancho ------------------------------------------------------------
c_mpio <- col_req(crudo, "Municipio")
c_nom  <- col_req(crudo, "NomMunicipio")
c_ind  <- col_req(crudo, "NomIndicador")
c_tot  <- col_req(crudo, "Valor_tot")
c_urb  <- col_req(crudo, "Valor_urb")
c_rur  <- col_req(crudo, "Valor_rur")

# El emparejamiento se hace sobre texto normalizado (sin tildes ni dobles
# espacios) para que no dependa de cómo venga escrito el encabezado en la
# fuente; el conteo de indicadores se verifica más abajo.
.dicc <- stats::setNames(unname(RENOMBRE_ECV), norm_txt(names(RENOMBRE_ECV)))

largo <- crudo |>
  dplyr::transmute(
    ind_mpio     = as.integer(a_numero(.data[[c_mpio]])),
    NomMunicipio = as.character(.data[[c_nom]]),
    ind          = unname(.dicc[norm_txt(as.character(.data[[c_ind]]))]),
    tot_         = a_numero(.data[[c_tot]]),
    urb_         = a_numero(.data[[c_urb]]),
    rur_         = a_numero(.data[[c_rur]])
  ) |>
  dplyr::filter(!is.na(ind), stringr::str_detect(ind, "^[A-Za-z0-9_]+$"))

indicadores <- sort(unique(largo$ind), method = "radix")   # orden ASCII, como Stata
if (length(indicadores) != length(RENOMBRE_ECV)) {
  faltan <- setdiff(unname(RENOMBRE_ECV), indicadores)
  stop("Se esperaban ", length(RENOMBRE_ECV), " indicadores de la ECV y se encontraron ",
       length(indicadores), ".\n  Sin datos en la fuente: ", paste(faltan, collapse = ", "),
       "\nRevise si cambiaron los nombres de los indicadores en el Excel.", call. = FALSE)
}

duplicadas <- largo |>
  dplyr::count(ind_mpio, NomMunicipio, ind) |>
  dplyr::filter(n > 1)
if (nrow(duplicadas)) {
  stop("Hay ", nrow(duplicadas), " combinaciones municipio-indicador repetidas en la ECV; ",
       "el paso a formato ancho no es posible.\n  Ejemplo: municipio ",
       duplicadas$ind_mpio[1], ", indicador ", duplicadas$ind[1], call. = FALSE)
}

# Una columna por indicador y zona, agrupadas por indicador (tot, urb, rur).
orden <- unlist(lapply(indicadores, function(i) paste0(c("tot_", "urb_", "rur_"), i)))

ancho <- largo |>
  tidyr::pivot_wider(
    id_cols     = c(ind_mpio, NomMunicipio),
    names_from  = ind,
    values_from = c(tot_, urb_, rur_),
    names_glue  = "{.value}{ind}"
  ) |>
  dplyr::select(ind_mpio, NomMunicipio, dplyr::all_of(orden)) |>
  dplyr::arrange(ind_mpio) |>
  as.data.frame()

# --- Etiquetas y formatos (los que fijaba el .do) -----------------------------
attr(ancho$ind_mpio, "label")     <- "Municipio"
attr(ancho$NomMunicipio, "label") <- "NomMunicipio"
for (i in indicadores) {
  for (z in c("tot_", "urb_", "rur_")) {
    cl <- paste0(z, i)
    attr(ancho[[cl]], "label")        <- paste(i, z)
    attr(ancho[[cl]], "format.stata") <- "%9.1f"
  }
}

# --- Verificaciones -----------------------------------------------------------
esperado_mpios <- 125L
if (nrow(ancho) != esperado_mpios) {
  stop("El derivado quedó con ", nrow(ancho), " municipios y se esperaban ",
       esperado_mpios, " (los de Antioquia).", call. = FALSE)
}
stopifnot(
  "hay municipios duplicados"      = !any(duplicated(ancho$ind_mpio)),
  "faltan columnas de indicadores" = ncol(ancho) == 2L + 3L * length(indicadores)
)

escribir_derivado(ancho, "ECV_nbi_pobreza")
message("  ECV_nbi_pobreza.dta: ", nrow(ancho), " municipios x ",
        length(indicadores), " indicadores (tot/urb/rur)")
