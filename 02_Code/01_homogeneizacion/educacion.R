# =============================================================================
# educacion.R — Indicadores educativos municipales (datalake Antioquia Cómo Vamos)
#
# Del datalake de educación se conservan 16 indicadores priorizados, en su año
# más reciente disponible, y se pasan a formato ancho: una fila por municipio.
# Lo lee la sección 03 (bloque de tránsito inmediato a educación superior).
#
# INPUTS:
#   01_Data/00_Inputs/DATALAKE EDUCACION.xlsx   (formato largo, todos los niveles)
# OUTPUTS:
#   01_Data/01_Derived/20250506 EDUCACION.xlsx  (125 municipios x 16 indicadores)
#
# El nombre del archivo de salida conserva el espacio y la fecha del original
# porque así lo busca 02_Code/03_tablas/03_ordenamiento.R.
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/
#   "20250506_HOMOGENEIZACIÓN INDICADORES EDUCACIÓN.do"
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== educación ==")

datos <- leer_excel(entrada("DATALAKE EDUCACION.xlsx"), hoja = "Sheet1")

c_nivel <- col_req(datos, "UnidadGeográfica", "Unidad Geográfica")
c_cod   <- col_req(datos, "CódigoUnidadGeográfica", "Código Unidad Geográfica")
c_nom   <- col_req(datos, "NombreUnidadGeográfica", "Nombre Unidad Geográfica")
c_ind   <- col_req(datos, "Indicador")
c_anno  <- col_req(datos, "Año", "Anno", "Anio")
c_dato  <- col_req(datos, "DatoNumérico", "Dato Numérico")

# --- Indicadores priorizados: nombre largo -> nombre corto --------------------
RENOMBRE_EDU <- c(
  "Proporción de planteles en la clasificación C y D"  = "clas_cole",
  "Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados" = "ninis",
  # Cobertura bruta
  "Tasa de cobertura bruta en transición"              = "tcb_transicion",
  "Tasa de cobertura bruta en primaria"                = "tcb_primaria",
  "Tasa de cobertura bruta en secundaria"              = "tcb_secundaria",
  "Tasa de cobertura bruta en media"                   = "tcb_media",
  "Tasa de cobertura bruta en educación superior"      = "tcb_edsup",
  "Tasa de tránsito inmediato a educación superior"    = "tti_edsup",
  # Deserción intraanual
  "Tasa de deserción intraanual en transición"         = "tdes_transicion",
  "Tasa de deserción intraanual en primaria"           = "tdes_primaria",
  "Tasa de deserción intraanual en secundaria"         = "tdes_secundaria",
  "Tasa de deserción intraanual en media"              = "tdes_media",
  # Repitencia
  "Tasa de repitencia en transición"                   = "trep_transicion",
  "Tasa de repitencia en primaria"                     = "trep_primaria",
  "Tasa de repitencia en secundaria"                   = "trep_secundaria",
  "Tasa de repitencia en media"                        = "trep_media"
)

# Nombres municipales que el datalake escribe de dos formas distintas según el
# año; sin homogeneizarlos, el mismo municipio quedaría con dos etiquetas.
NOMBRES_CORREGIDOS <- c(
  "05647" = "San Andrés de Cuerquia",
  "05658" = "San José de la Montaña",
  "05664" = "San Pedro de los Milagros"
)

# El cruce se hace sobre texto normalizado (sin tildes ni dobles espacios) para
# que no dependa de la grafía exacta de la fuente; el conteo se verifica abajo.
.dicc <- stats::setNames(unname(RENOMBRE_EDU), norm_txt(names(RENOMBRE_EDU)))

municipal <- datos |>
  dplyr::filter(norm_txt(as.character(.data[[c_nivel]])) == "municipal") |>
  dplyr::transmute(
    cod       = stringr::str_squish(as.character(.data[[c_cod]])),
    nvl_label = as.character(.data[[c_nom]]),
    ind       = unname(.dicc[norm_txt(as.character(.data[[c_ind]]))]),
    anno      = a_numero(.data[[c_anno]]),
    valor     = a_numero(.data[[c_dato]])
  ) |>
  dplyr::filter(!is.na(ind))

if (nrow(municipal) == 0) {
  stop("No quedaron registros municipales en el datalake de educación. ",
       "Verifique la columna de unidad geográfica en ", "DATALAKE EDUCACION.xlsx",
       call. = FALSE)
}

encontrados <- sort(unique(municipal$ind))
if (length(encontrados) != length(RENOMBRE_EDU)) {
  stop("Se esperaban ", length(RENOMBRE_EDU), " indicadores priorizados y se encontraron ",
       length(encontrados), ".\n  Sin datos en la fuente: ",
       paste(setdiff(unname(RENOMBRE_EDU), encontrados), collapse = ", "),
       "\nRevise si cambiaron los nombres de los indicadores en el datalake.", call. = FALSE)
}

# --- Observación más reciente de cada indicador en cada municipio -------------
reciente <- municipal |>
  dplyr::group_by(cod, ind) |>
  dplyr::filter(anno == max(anno, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    nvl_label = ifelse(cod %in% names(NOMBRES_CORREGIDOS),
                       unname(NOMBRES_CORREGIDOS[cod]), nvl_label)
  )

duplicadas <- reciente |>
  dplyr::count(cod, ind) |>
  dplyr::filter(n > 1)
if (nrow(duplicadas)) {
  stop("Hay ", nrow(duplicadas), " combinaciones municipio-indicador con más de un ",
       "registro en el año más reciente; el paso a formato ancho no es posible.\n",
       "  Ejemplo: municipio ", duplicadas$cod[1], ", indicador ", duplicadas$ind[1],
       call. = FALSE)
}

varias_etiquetas <- reciente |>
  dplyr::distinct(cod, nvl_label) |>
  dplyr::count(cod) |>
  dplyr::filter(n > 1)
if (nrow(varias_etiquetas)) {
  stop("Estos municipios llegan con más de un nombre y hay que homogeneizarlos ",
       "en NOMBRES_CORREGIDOS: ", paste(varias_etiquetas$cod, collapse = ", "),
       call. = FALSE)
}

# --- Formato ancho ------------------------------------------------------------
ancho <- reciente |>
  tidyr::pivot_wider(id_cols = c(cod, nvl_label), names_from = ind, values_from = valor) |>
  # el código DANE llega como texto con cero a la izquierda ("05001")
  dplyr::mutate(ind_mpio = a_numero(cod)) |>
  dplyr::select(ind_mpio, nvl_label,
                dplyr::all_of(sort(encontrados, method = "radix"))) |>
  dplyr::arrange(ind_mpio) |>
  as.data.frame()

# --- Verificaciones -----------------------------------------------------------
esperado_mpios <- 125L
if (nrow(ancho) != esperado_mpios) {
  stop("El derivado quedó con ", nrow(ancho), " municipios y se esperaban ",
       esperado_mpios, " (los de Antioquia).", call. = FALSE)
}
stopifnot(
  "hay municipios duplicados"      = !any(duplicated(ancho$ind_mpio)),
  "faltan columnas de indicadores" = ncol(ancho) == 2L + length(encontrados)
)

# --- Guardar ------------------------------------------------------------------

escribir_derivado(ancho, "20250506 EDUCACION")

message("  20250506 EDUCACION.xlsx: ", nrow(ancho), " municipios x ",
        length(encontrados), " indicadores")
