# =============================================================================
# salud_seguridad.R — Tablero municipal de seguridad, salud y déficit de vivienda
#
# Reconstruye el derivado que leen las secciones 02 (demografía) y 09 (salud):
# 33 indicadores municipales para los 125 municipios de Antioquia, más las tres
# variables vitales que se calculan aquí (natalidad, mortalidad y crecimiento
# vegetativo).
#
# INPUTS:
#   01_Data/00_Inputs/NATALIDAD.xlsx      (hoja "Natalidad total";  tasa 2023)
#   01_Data/00_Inputs/DATOS SALUD.xlsx    (hoja "tasa mortalidad general"; 2024)
#   01_Data/00_Inputs/curados/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx
#       (hoja "Data") — tablero curado a mano; ver "LIMITACIÓN" más abajo.
# OUTPUTS:
#   01_Data/01_Derived/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.parquet
#   (125 filas x 36 columnas)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/20260504_HOMOGENEIZACIÓN_SALUD_SEGURIDAD.do
#
# El nombre del archivo conserva la errata "DEFICT" (por DÉFICIT) porque es el
# nombre con el que lo buscan 03_tablas/02_demografia.R y 03_tablas/09_salud.R.
#
# -----------------------------------------------------------------------------
# LIMITACIÓN CONOCIDA: el tablero curado no tiene fuente cruda en el repositorio
# -----------------------------------------------------------------------------
# De las 36 columnas del derivado, este script calcula tres (tasa_natalidad,
# tasa_mortalidad y crec_vegetativo) a partir de insumos crudos. Las otras 33
# —el código y el nombre del municipio y 31 indicadores de seguridad, salud,
# vivienda y clima— vienen ya calculadas en la hoja "Data" del propio .xlsx de
# 01_Derived, que se armó a mano en Excel: no hay ningún script (ni .do ni .R)
# que las derive, ni un archivo en 01_Data/00_Inputs del que salgan. Ese archivo
# es, en la práctica, un INSUMO curado que vive en la carpeta equivocada.
#
# Reconstruirlas exigiría rehacer 31 indicadores desde ~10 fuentes distintas sin
# especificación escrita, así que aquí NO se inventan: se leen tal cual.
#
# El .do original leía y reescribía el MISMO archivo, de modo que cada corrida
# acumulaba transformaciones sobre su propia salida. Aquí el problema queda
# cerrado de raíz separando las dos cosas que antes convivían en un archivo:
#   - el tablero curado es un INSUMO y vive en 01_Data/00_Inputs/curados/
#   - el resultado es un DERIVADO y se escribe en parquet en 01_Data/01_Derived/
# Leer y escribir en sitios distintos hace imposible la acumulación.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== seguridad, salud y déficit de vivienda ==")

MAESTRO <- "20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA"

# Columnas que calcula este script. Se descartan al leer el tablero para que
# volver a correr no acumule resultados sobre resultados (ver LIMITACIÓN).
CALCULADAS <- c("tasa_natalidad", "tasa_mortalidad", "crec_vegetativo")

# Orden canónico de las columnas del derivado, tal como lo fija el .do.
ORDEN <- c(
  "ind_mpio", "nvl_label",
  "tasa_natalidad", "tasa_mortalidad", "crec_vegetativo",
  "percepción_seguridad", "tasa_delitos", "IRV",
  "VBG", "VBG_jovenes", "VBG_adolescentes", "homicidios",
  "vinculacion_nna", "mortalidad_desnutrición",
  "bajo_peso", "desnutrición_aguda", "controles_prenatales",
  "fecundidad_niñas", "fecundidad_adolescentes", "camas",
  "IRA", "dengue", "malaria", "leishmaniasis",
  "acueducto_rural", "alcantarillado_rural",
  "acueducto_urbano", "alcantarillado_urbano",
  "deficit_cuali", "deficit_cuanti",
  "hacinamiento_rural", "hacinamiento_urbano",
  "Población_2023", "IRCC", "afectados_dn", "perdida_ca"
)

# --- 1. Tablero curado --------------------------------------------------------

ruta_maestro <- entrada("curados", paste0(MAESTRO, ".xlsx"), obligatorio = FALSE)
if (!file.exists(ruta_maestro)) {
  stop("Falta el tablero curado:\n  ", ruta_maestro, "\n",
       "No se puede reconstruir: 31 de sus 36 columnas no tienen fuente cruda ",
       "en el repositorio (ver la nota LIMITACIÓN en la cabecera de este script). ",
       "Pídalo al equipo antes de volver a correr esta homogeneización.",
       call. = FALSE)
}

maestro <- leer_excel(ruta_maestro, "Data")
maestro <- maestro[, setdiff(names(maestro), CALCULADAS), drop = FALSE]

faltantes <- setdiff(setdiff(ORDEN, CALCULADAS), names(maestro))
if (length(faltantes)) {
  stop("Al tablero curado le faltan columnas que el derivado debe tener:\n  ",
       paste(faltantes, collapse = ", "), call. = FALSE)
}

# El código llega como texto con cero a la izquierda ("05001"), que es la forma
# con la que se cruza contra las fuentes de tasas. Se normaliza por si alguna
# versión del tablero lo trajera ya como número (5001).
maestro$ind_mpio <- sprintf("%05d", as.integer(a_numero(maestro$ind_mpio)))

# --- 2. Tasas vitales desde los insumos crudos --------------------------------
# Las dos hojas vienen con encabezados de dos pisos (año arriba, "Total"/"Tasa"
# abajo) y sin nombres utilizables, así que el .do referencia las columnas por
# su letra de Excel: AL en NATALIDAD y AQ en DATOS SALUD. Aquí no se puede usar
# la letra directamente —readxl recorta las columnas vacías de la izquierda, y
# en DATOS SALUD la columna A lo está—, así que se localiza la columna de
# códigos y se aplica el mismo desplazamiento que separa las dos letras.

#' Índice de la columna que trae los códigos DIVIPOLA de Antioquia ("05xxx").
.columna_codigo <- function(datos) {
  cuantos <- vapply(datos, function(x) {
    sum(grepl("^05\\d{3}$", stringr::str_squish(as.character(x))), na.rm = TRUE)
  }, integer(1))
  if (max(cuantos) == 0) {
    stop("Ninguna columna de la hoja trae códigos DIVIPOLA de Antioquia (05xxx).",
         call. = FALSE)
  }
  unname(which.max(cuantos))
}

#' Lee una tasa municipal de una hoja con encabezado de dos pisos.
#'
#' @param ruta,hoja  archivo y hoja de la fuente
#' @param saltar     filas que se saltan para que el encabezado quede en la fila
#'                   que nombra la columna ("Tasa …")
#' @param desplazamiento  columnas entre la del código y la de la tasa, según
#'                   las letras de Excel que usa el .do
#' @param nombre     nombre de la variable resultante
.leer_tasa <- function(ruta, hoja, saltar, desplazamiento, nombre) {
  hoja_datos <- leer_excel(ruta, hoja, saltar = saltar)
  i_cod  <- .columna_codigo(hoja_datos)
  i_tasa <- i_cod + desplazamiento

  if (i_tasa > ncol(hoja_datos)) {
    stop("La hoja \"", hoja, "\" de ", basename(ruta), " tiene ",
         ncol(hoja_datos), " columnas y se esperaba la tasa en la ", i_tasa,
         ". Probablemente la fuente añadió o quitó años.", call. = FALSE)
  }
  encabezado <- names(hoja_datos)[i_tasa]
  if (!grepl("tasa", norm_txt(encabezado %||% ""))) {
    stop("La columna ", i_tasa, " de la hoja \"", hoja, "\" se llama \"",
         encabezado, "\" y debería ser una tasa. La fuente cambió de estructura.",
         call. = FALSE)
  }

  tasas <- data.frame(
    ind_mpio = stringr::str_squish(as.character(hoja_datos[[i_cod]])),
    valor    = a_numero(hoja_datos[[i_tasa]]),
    stringsAsFactors = FALSE
  )
  # Solo municipios: el archivo trae también el departamento ("05") y las
  # subregiones ("SR01"…), que no tienen código de cinco dígitos.
  tasas <- tasas[grepl("^\\d{5}$", tasas$ind_mpio), , drop = FALSE]
  names(tasas)[2] <- nombre
  message("  ", nombre, ": ", nrow(tasas), " municipios (columna \"",
          encabezado, "\")")
  tasas
}

# NATALIDAD: código en A, tasa bruta de natalidad 2023 en AL  (AL - A = 37).
natalidad <- .leer_tasa(entrada("NATALIDAD.xlsx"), "Natalidad total",
                        saltar = 1, desplazamiento = 37, nombre = "tasa_natalidad")

# DATOS SALUD: código en B, tasa de mortalidad general 2024 en AQ (AQ - B = 41).
# OJO: la natalidad es de 2023 y la mortalidad de 2024, así que el crecimiento
# vegetativo mezcla dos años. Es lo que hace el .do original; se conserva para
# no cambiar las cifras publicadas.
mortalidad <- .leer_tasa(entrada("DATOS SALUD.xlsx"), "tasa mortalidad general",
                         saltar = 4, desplazamiento = 41, nombre = "tasa_mortalidad")

# --- 3. Armar el derivado -----------------------------------------------------
# El .do hace `merge 1:1` y luego `drop if _merge == 1`: se queda con todos los
# municipios del tablero y descarta los que solo están en la fuente de tasas.
# Eso es exactamente un left join sobre el tablero.

salud_seguridad <- maestro |>
  dplyr::left_join(natalidad,  by = "ind_mpio") |>
  dplyr::left_join(mortalidad, by = "ind_mpio") |>
  dplyr::mutate(
    crec_vegetativo = .data$tasa_natalidad - .data$tasa_mortalidad,
    ind_mpio        = a_numero(.data$ind_mpio)   # `destring ind_mpio, replace`
  )

sin_tasa <- salud_seguridad$ind_mpio[is.na(salud_seguridad$tasa_natalidad) |
                                     is.na(salud_seguridad$tasa_mortalidad)]
if (length(sin_tasa)) {
  warning("Municipios del tablero sin tasa vital en las fuentes crudas: ",
          paste(sin_tasa, collapse = ", "), call. = FALSE)
}

salud_seguridad <- salud_seguridad[order(salud_seguridad$ind_mpio), ORDEN, drop = FALSE]
rownames(salud_seguridad) <- NULL

# Etiquetas de variable: Stata importaba el tablero con `firstrow`, que deja
# como etiqueta el encabezado de la hoja (idéntico al nombre de la variable).
# Las tres columnas calculadas aquí no llevan etiqueta, igual que en el .do.
for (cl in setdiff(names(salud_seguridad), c(CALCULADAS, "ind_mpio"))) {
  attr(salud_seguridad[[cl]], "label") <- cl
}

# --- Verificaciones -----------------------------------------------------------
stopifnot(
  "el derivado debe tener los 125 municipios de Antioquia" = nrow(salud_seguridad) == 125L,
  "hay municipios duplicados"                              = !any(duplicated(salud_seguridad$ind_mpio)),
  "faltan columnas del orden canónico"                     = identical(names(salud_seguridad), ORDEN)
)

# --- Guardar ------------------------------------------------------------------
# El código de municipio va numérico. En el .xlsx del que se lee viene como
# texto con cero a la izquierda ("05001"), pero eso era necesario cuando el
# script releía su propia salida; ahora la entrada y la salida son archivos
# distintos y el tipo puede ser el correcto.
escribir_derivado(salud_seguridad, MAESTRO)

message("  ", MAESTRO, ": ", nrow(salud_seguridad), " municipios x ",
        ncol(salud_seguridad), " columnas")
