# =============================================================================
# deyc.R — Desarrollo Económico y Competitividad: estructura productiva e IMCA
#
# El DATALAKE de DEyC viene en formato largo (una fila por unidad geográfica,
# indicador y año). Aquí se extraen dos recortes y se pasan a formato ancho:
#
#   1. estructura_productiva: siete indicadores priorizados, cada uno en su
#      año más reciente disponible (el año puede diferir entre indicadores).
#   2. imca_2022: los once pilares del Índice Municipal de Competitividad en
#      Antioquia y su total, todos de 2022.
#
# INPUTS:
#   01_Data/00_Inputs/DATALAKE DEyC.xlsx   (hoja "Sheet1", formato largo)
# OUTPUTS:
#   01_Data/01_Derived/estructura_productiva.{dta,xlsx}   (135 filas)
#   01_Data/01_Derived/imca_2022.{dta,xlsx}               (134 filas)
#
# ETAPA DEL PIPELINE: 1. homogeneización
#
# Migrado de 00_Homogeneizacion_Inputs/"Homogeneizacion DeyC.do", que en
# realidad son dos programas pegados (hay un `clear all` en la línea 86) y por
# eso produce dos derivados. Aquí van como dos bloques del mismo script porque
# leen el mismo insumo.
#
# NOTAS SOBRE LA UNIDAD GEOGRÁFICA
#   El .do solo descarta las filas "Nacional", así que los derivados NO son
#   puramente municipales: conservan las nueve subregiones (códigos "SR01"…
#   "SR09") y, en estructura_productiva, también el departamento ("05").
#   Eso es intencional: 03_tablas/03_ordenamiento.R usa justamente las filas
#   "SR.." del IMCA como valor oficial subregional. Por eso `ind_mpio` es texto
#   y no un código DANE numérico.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== DEyC: estructura productiva e IMCA ==")

# --- Insumo -------------------------------------------------------------------
datalake <- leer_excel(entrada("DATALAKE DEyC.xlsx"), "Sheet1")

c_ug   <- col_req(datalake, "Unidad Geográfica")
c_cod  <- col_req(datalake, "Código Unidad Geográfica")
c_ind  <- col_req(datalake, "Indicador")
c_anno <- col_req(datalake, "Año", "anno", "anio")
c_dato <- col_req(datalake, "Dato Numérico", "dato_numerico")

# Solo se descartan las filas nacionales (ver nota del encabezado).
largo_base <- datalake |>
  dplyr::filter(as.character(.data[[c_ug]]) != "Nacional") |>
  dplyr::transmute(
    ind_mpio  = as.character(.data[[c_cod]]),
    indicador = as.character(.data[[c_ind]]),
    anno      = a_numero(.data[[c_anno]]),
    valor     = a_numero(.data[[c_dato]])
  )

# --- Utilidades locales -------------------------------------------------------

#' Traduce los nombres largos del DATALAKE a los nombres cortos del derivado y
#' se detiene si alguno de los indicadores pedidos no está en la fuente (es la
#' forma silenciosa en que el .do se quedaba con columnas de menos).
.seleccionar_indicadores <- function(largo, mapa) {
  ausentes <- setdiff(names(mapa), unique(largo$indicador))
  if (length(ausentes)) {
    stop("El DATALAKE de DEyC no trae estos indicadores:\n  ",
         paste(ausentes, collapse = "\n  "),
         "\nRevise si la fuente cambió la redacción del nombre.", call. = FALSE)
  }
  largo |>
    dplyr::filter(.data$indicador %in% names(mapa)) |>
    dplyr::mutate(variable = unname(mapa[.data$indicador]))
}

#' Equivalente de `reshape wide` de Stata: una fila por código y una columna por
#' indicador. Stata deja las columnas nuevas en orden alfabético y las filas
#' ordenadas por el identificador; `method = "radix"` ordena por bytes, que es
#' como ordena Stata (los códigos "05…" van antes que los "SR…").
.a_formato_ancho <- function(largo) {
  repetidos <- largo[duplicated(largo[, c("ind_mpio", "variable")]), ]
  if (nrow(repetidos)) {
    stop("Hay más de un dato para el mismo código e indicador; el paso a formato ",
         "ancho sería ambiguo. Ejemplos:\n  ",
         paste(utils::head(paste(repetidos$ind_mpio, repetidos$variable), 5),
               collapse = "\n  "), call. = FALSE)
  }
  ancho <- largo |>
    dplyr::select("ind_mpio", "variable", "valor") |>
    tidyr::pivot_wider(names_from = "variable", values_from = "valor") |>
    as.data.frame()
  ancho <- ancho[, c("ind_mpio", sort(setdiff(names(ancho), "ind_mpio"))), drop = FALSE]
  ancho <- ancho[order(ancho$ind_mpio, method = "radix"), , drop = FALSE]
  rownames(ancho) <- NULL
  ancho
}

#' Guarda el derivado. Antes se escribía en .dta y .xlsx a la vez; ahora es un
#' único parquet (el formato de todos los derivados del pipeline).
.guardar <- function(datos, nombre) {
  escribir_derivado(datos, nombre)
}

#' Los formatos de visualización de Stata (`format var %4.1f`) no viajan en
#' parquet y no los usa nadie: la función se conserva como identidad para no
#' alterar el resto del script.
.sin_formato_stata <- function(datos, columnas, formato) datos

# =============================================================================
# 1. Estructura productiva — indicadores priorizados, año más reciente
# =============================================================================

INDICADORES_ESTRUCTURA <- c(
  "Valor agregado per capita"                                                      = "va_pc",
  "Participacion por actidad economica del Valor agregado - Actividades Primarias" = "va_primario",
  "Número de corresponsalespor cada 1.000 habitantes"                              = "fin_banc_pc",
  "Número de microcréditopor cada 1.000 habitantes"                                = "fin_microcr_pc",
  "Tasa de natalidad empresarial neta"                                             = "tnat_emp",
  "Densidad empresarial (número de empresas por cada mil habitantes)"              = "dens_emp",
  "Creación neta de empresas"                                                      = "creacion_emp"
)

# El año más reciente se calcula por unidad geográfica Y por indicador: no todos
# los indicadores llegan hasta el mismo año, y algunos (corresponsales,
# microcrédito) solo existen para un año.
estructura_productiva <- largo_base |>
  .seleccionar_indicadores(INDICADORES_ESTRUCTURA) |>
  dplyr::group_by(.data$ind_mpio, .data$indicador) |>
  dplyr::filter(.data$anno == max(.data$anno)) |>
  dplyr::ungroup() |>
  .a_formato_ancho() |>
  .sin_formato_stata(unname(INDICADORES_ESTRUCTURA), "%4.1f")

.guardar(estructura_productiva, "estructura_productiva")

# =============================================================================
# 2. IMCA 2022 — once pilares y el índice total
# =============================================================================

INDICADORES_IMCA <- c(
  "IMCA según pilar: adopción TIC"                         = "imca_adop_tic",
  "IMCA según pilar: capacidades"                          = "imca_capacidades",
  "IMCA según pilar: dinamismo de los negocios"            = "imca_dinam_neg",
  "IMCA según pilar: infraestructura"                      = "imca_infraestructura",
  "IMCA según pilar: innovación"                           = "imca_innovacion",
  "IMCA según pilar: instituciones"                        = "imca_instituciones",
  "IMCA según pilar: mercado de bienes"                    = "imca_merc_bienes",
  "IMCA según pilar: mercado laboral"                      = "imca_merc_laboral",
  "IMCA según pilar: salud"                                = "imca_salud",
  "IMCA según pilar: sistema financiero"                   = "imca_sist_financiero",
  "IMCA según pilar: tamaño del mercado"                   = "imca_tam_mercado",
  "Índice Municipal de Competitividad en Antioquia (IMCA)" = "imca_total"
)

imca_2022 <- largo_base |>
  dplyr::filter(.data$anno == 2022) |>
  .seleccionar_indicadores(INDICADORES_IMCA) |>
  .a_formato_ancho() |>
  .sin_formato_stata(unname(INDICADORES_IMCA), "%4.2f")

# El .do conserva `Año` (constante en 2022) como última columna del derivado.
imca_2022[["Año"]] <- 2022

.guardar(imca_2022, "imca_2022")

# --- Verificaciones -----------------------------------------------------------
# Antioquia tiene 125 municipios y 9 subregiones; el IMCA los cubre todos y la
# estructura productiva añade además la fila del departamento.
stopifnot(
  "estructura_productiva perdió municipios" = nrow(estructura_productiva) == 135L,
  "imca_2022 perdió municipios"             = nrow(imca_2022) == 134L,
  "faltan las filas subregionales del IMCA" =
    sum(grepl("^SR", imca_2022$ind_mpio)) == 9L
)
