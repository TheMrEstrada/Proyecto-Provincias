# =============================================================================
# 05_economia.R — Sección 5: Economía
#
# TABLAS (16 hojas de un mismo economia.xlsx, las mismas del .do original):
#   5.4 turismo receptivo   extranjeros_municipio, comparativo_pap_antioquia,
#                           turismo_instrumentos
#   5.1 condiciones de vida ecv_pobreza, ecv_ipm, ecv_gini,
#       y mercado laboral   ecv_ocupacion_informal, ecv_desocupacion_nini,
#                           dependencia_economica
#   5.2 estructura          densidad_empresarial, valor_agregado, va_actividades
#       productiva
#   5.3 minero-energético   energia_tecnologia, energia_centrales,
#                           energia_participacion, titulos_mineros
#
# INPUTS:
#   01_Data/01_Derived/EXTRANJEROS_PROVINCIAS.xlsx            (hoja "Extranjeros")
#   01_Data/01_Derived/VALOR_AGREGADO_20152024_MUNICIPIOS.xlsx (hoja "PIB Mpal 2015-2024 Cons")
#       OJO: estos dos derivados NO los produce ningún script del pipeline; se
#       arman a mano en Excel. Si se rehace la cadena de derivados hay que
#       construirlos aparte (mismo caso que EDUCACION_PROVINCIAS.xlsx).
#   01_Data/01_Derived/ECV_nbi_pobreza.dta
#   01_Data/01_Derived/ECV_oficial_agregados.dta
#   01_Data/00_Inputs/POBLACION MUNICIPAL.xlsx  (hojas "Total_Municipios" y
#                                                "Rangos_Quintenios")
#   01_Data/00_Inputs/instrumentos_planificacion_turistica_antioquia.xlsx
#   01_Data/00_Inputs/DATALAKE DEyC.xlsx
#   01_Data/00_Inputs/Energia_NorteAntioquia.xlsx
#   01_Data/00_Inputs/Actualización/Fuentes/TITULOSMINAS_ORIGINAL.xlsx
#   crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/05_Economia/economia.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/05_Economia.do
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Insumos que se leen una sola vez por sesión (POBLACION MUNICIPAL.xlsx son
# ~19.000 filas × 190 columnas y la sección lo necesita cuatro veces).
.cache_eco <- new.env(parent = emptyenv())

# =============================================================================
# 0. Utilidades locales de la sección
# =============================================================================

#' Lee una hoja SIN encabezado y nombra las columnas A, B, C… igual que hace
#' Stata con `import excel, cellrange(...)` sin `firstrow`. Varias fuentes de
#' esta sección se leen por posición porque sus encabezados traen tildes,
#' puntos y celdas combinadas que ninguna de las dos herramientas sanea igual.
.leer_por_posicion <- function(ruta, hoja, saltar) {
  d <- as.data.frame(readxl::read_excel(
    ruta, sheet = hoja, skip = saltar, col_names = FALSE, .name_repair = "minimal"
  ))
  names(d) <- LETTERS[seq_len(ncol(d))]
  d
}

#' Población municipal total (área geográfica "Total") de los años pedidos.
#'
#' NOTA SOBRE LA SERIE DE POBLACIÓN (F-2-018, decidido el 2026-08-20).
#' Este bloque pondera con POBLACION MUNICIPAL.xlsx, que NO es la serie con la
#' que se publica la población del informe: la cabecera de 02_demografia.R la
#' declara descartada porque difiere entre −3 % y +10 % por municipio.
#'
#' Las secciones 03 y 09 sí se pasaron al PPED (derivados poblacion_anual y
#' poblacion_total_2025). Esta NO, y la razón es de datos: el PPED cubre
#' 2018-2042 y el valor agregado se publica desde 2015, así que repuntarla dejaría esos años sin
#' población y sin indicador. POBLACION MUNICIPAL.xlsx cubre 1985-2035.
#'
#' Se cierra el día que se consiga la retroproyección del DANE 1985-2017 de la
#' vigencia del PPED: se añade como segundo insumo de poblacion_municipal.R y
#' poblacion_anual pasa a cubrir el rango completo. Entonces esta función lee el
#' derivado, como ya hacen .poblacion_peso() y .pesos_poblacion().
.poblacion <- function(anios) {
  if (is.null(.cache_eco$poblacion)) {
    pm <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = "Total_Municipios")
    c_cod  <- col_req(pm, "DPMP")
    c_anio <- col_req(pm, "AÑO", "ANO")
    c_area <- col_req(pm, "ÁREA GEOGRÁFICA", "AREA GEOGRAFICA")
    c_tot  <- col_req(pm, "Total General", "TotalGeneral")
    .cache_eco$poblacion <- data.frame(
      ind_mpio  = as.integer(a_numero(pm[[c_cod]])),
      anio      = as.integer(a_numero(pm[[c_anio]])),
      area      = stringr::str_squish(as.character(pm[[c_area]])),
      poblacion = a_numero(pm[[c_tot]]),
      stringsAsFactors = FALSE
    ) |>
      dplyr::filter(.data$area == "Total", !is.na(.data$ind_mpio)) |>
      dplyr::select("ind_mpio", "anio", "poblacion")
  }
  dplyr::filter(.cache_eco$poblacion, .data$anio %in% anios)
}

#' Peso poblacional para los promedios ponderados: población total de 2025.
.pesos_poblacion <- function() {
  .poblacion(2025) |>
    dplyr::transmute(ind_mpio = .data$ind_mpio, pob_peso = .data$poblacion)
}

#' Territorio de las filas agregadas, con la convención del .do: la fila de
#' provincia lleva el nombre de la provincia, la de subregión el de la
#' subregión y la de departamento "DEPARTAMENTO DE ANTIOQUIA".
.territorio_agregados <- function(datos, prov, subreg) {
  dplyr::mutate(
    datos,
    subregion = dplyr::case_when(
      .data$tipo_fila == "Total subregión" ~ subreg,
      .data$tipo_fila %in% c("Total provincia", "Total departamento") ~ NA_character_,
      TRUE ~ .data$subregion
    ),
    provincia = dplyr::case_when(
      .data$tipo_fila == "Total provincia"    ~ prov$nombre_datos,
      .data$tipo_fila == "Total departamento" ~ "DEPARTAMENTO DE ANTIOQUIA",
      .data$tipo_fila == "Total subregión"    ~ NA_character_,
      TRUE ~ .data$provincia
    )
  )
}

# Encabezados territoriales, iguales en casi todas las hojas de la sección.
ETIQUETAS_TERRITORIO <- c(
  ind_mpio  = "Código DANE",
  municipio = "Municipio",
  subregion = "Subregión",
  provincia = "Provincia"
)

# =============================================================================
# 1. Turismo receptivo — visitantes extranjeros no residentes (5.1 y 5.2 del .do)
# =============================================================================

#' Serie de visitantes extranjeros de TODOS los municipios de Antioquia.
.extranjeros_universo <- function() {
  if (is.null(.cache_eco$extranjeros)) {
    x <- leer_excel(entrada("curados", "EXTRANJEROS_PROVINCIAS.xlsx"), hoja = "Extranjeros")
    c_cod  <- col_req(x, "CODIGO_MUN")
    c_anio <- col_req(x, "Año", "ANO")
    c_ext  <- col_req(x, "Cant Extranjeros no Residentes",
                      "CantExtranjerosnoResidentes")
    .cache_eco$extranjeros <- data.frame(
      ind_mpio    = as.integer(a_numero(x[[c_cod]])),
      anio        = as.integer(a_numero(x[[c_anio]])),
      extranjeros = a_numero(x[[c_ext]]),
      stringsAsFactors = FALSE
    ) |>
      dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$anio)) |>
      con_territorio()
  }
  .cache_eco$extranjeros
}

#' Hoja "extranjeros_municipio": un bloque de filas por año con los municipios
#' de la provincia y los totales de provincia, subregión y departamento.
.hoja_extranjeros_municipio <- function(prov, universo) {
  subreg <- subregion_dominante(prov)
  detalle <- filtrar_provincia(universo, prov)
  anios <- sort(unique(detalle$anio))

  purrr::map_dfr(anios, function(a) {
    agregar_totales(
      dplyr::arrange(dplyr::filter(detalle, .data$anio == a), .data$municipio),
      universo = dplyr::filter(universo, .data$anio == a),
      prov     = prov,
      columnas = "extranjeros",
      como     = "suma"
    ) |>
      dplyr::mutate(anio = a)
  }) |>
    .territorio_agregados(prov, subreg) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "tipo_fila", "anio", "extranjeros")
}

#' Hoja "comparativo_pap_antioquia": total provincial frente al departamental.
.hoja_comparativo_extranjeros <- function(prov, universo) {
  dpto <- universo |>
    dplyr::group_by(.data$anio) |>
    dplyr::summarise(total_antioquia = sum(.data$extranjeros, na.rm = TRUE),
                     .groups = "drop")

  filtrar_provincia(universo, prov) |>
    dplyr::group_by(.data$anio) |>
    dplyr::summarise(total_provincia = sum(.data$extranjeros, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::left_join(dpto, by = "anio") |>
    dplyr::mutate(
      provincia = prov$nombre_datos,
      participacion = .data$total_provincia / .data$total_antioquia
    ) |>
    dplyr::select("anio", "provincia", "total_provincia", "total_antioquia",
                  "participacion")
}

# =============================================================================
# 2. Condiciones de vida y mercado laboral (ECV 2023)
# -----------------------------------------------------------------------------
# El detalle municipal sale de ECV_nbi_pobreza.dta; los agregados de provincia,
# subregión y departamento salen de ECV_oficial_agregados.dta cuando existen.
# Cada hoja separa las dos fuentes en columnas `_mun` y `_ofi` para que no se
# lean como una misma serie, tal como hace el .do.
# =============================================================================

#' Municipios de la provincia con los indicadores ECV y el peso poblacional.
.ecv_municipios <- function(prov) {
  if (is.null(.cache_eco$ecv)) {
    e <- leer_derivado("ECV_nbi_pobreza")
    e$ind_mpio <- as.integer(e$ind_mpio)
    .cache_eco$ecv <- con_territorio(as.data.frame(e))
  }
  filtrar_provincia(.cache_eco$ecv, prov) |>
    dplyr::left_join(.pesos_poblacion(), by = "ind_mpio")
}

#' Fila de ECV_oficial_agregados para un nivel territorial (0 filas si no hay).
.ecv_oficial <- function(nivel, clave) {
  if (is.null(.cache_eco$ecv_ofi)) {
    .cache_eco$ecv_ofi <- as.data.frame(
      leer_derivado("ECV_oficial_agregados")
    )
  }
  d <- .cache_eco$ecv_ofi
  d[d$nivel == nivel & d$key == as.character(clave), , drop = FALSE]
}

#' ¿La provincia está entre las que sí tienen agregado oficial de la ECV?
.hay_ecv_oficial_provincia <- function(prov) nrow(.ecv_oficial("PROVINCIA", prov$id)) > 0

#' Promedio ponderado por población de los municipios de la provincia.
#' Se apoya en agregar_totales() para no repetir la fórmula de ponderación.
.ecv_fila_ponderada <- function(municipios, prov, vars) {
  t <- agregar_totales(municipios, universo = NULL, prov = prov,
                       columnas = vars, como = "promedio_ponderado",
                       pesos = "pob_peso")
  t[t$tipo_fila == "Total provincia", vars, drop = FALSE]
}

#' Une el detalle municipal con las filas agregadas y parte cada indicador en
#' `_mun` (municipal) y `_ofi` (agregado).
#'
#' @param agregados lista de filas; cada una con etiqueta, tipo, provincia,
#'   subregion y `valores` (data.frame de 1 fila con las columnas de `vars`,
#'   o NULL cuando el indicador no está disponible en ese nivel).
.ecv_ensamblar <- function(municipios, vars, agregados) {
  base <- municipios |>
    dplyr::arrange(.data$municipio) |>
    dplyr::mutate(tipo_fila = "Municipio") |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "tipo_fila",
                  dplyr::all_of(vars))

  filas <- lapply(agregados, function(a) {
    fila <- data.frame(
      ind_mpio  = NA_integer_,
      municipio = a$etiqueta,
      subregion = a$subregion %||% NA_character_,
      provincia = a$provincia %||% NA_character_,
      tipo_fila = a$tipo,
      stringsAsFactors = FALSE
    )
    for (v in vars) {
      fila[[v]] <- if (!is.null(a$valores) && nrow(a$valores) && v %in% names(a$valores)) {
        as.numeric(a$valores[[v]][1])
      } else {
        NA_real_
      }
    }
    fila
  })

  d <- dplyr::bind_rows(c(list(base), filas))
  for (v in vars) {
    d[[paste0(v, "_mun")]] <- ifelse(d$tipo_fila == "Municipio", d[[v]], NA_real_)
    d[[paste0(v, "_ofi")]] <- ifelse(d$tipo_fila != "Municipio", d[[v]], NA_real_)
  }
  d
}

#' Columnas de una hoja ECV en el orden del .do: territorio y, por indicador,
#' primero el valor municipal y después el agregado.
.ecv_columnas <- function(vars) {
  c("ind_mpio", "municipio", "subregion", "provincia",
    as.vector(rbind(paste0(vars, "_mun"), paste0(vars, "_ofi"))))
}

#' Etiquetas `_mun`/`_ofi` a partir de un vector nombrado indicador -> texto.
.ecv_etiquetas <- function(base) {
  et <- ETIQUETAS_TERRITORIO
  for (v in names(base)) {
    et[paste0(v, "_mun")] <- paste0(base[[v]], " (municipal)")
    et[paste0(v, "_ofi")] <- paste0(base[[v]], " (agregado)")
  }
  et
}

#' Formatos `_mun`/`_ofi` iguales para todos los indicadores de una hoja.
.ecv_formatos <- function(vars, formato) {
  stats::setNames(rep(formato, 2 * length(vars)),
                  as.vector(rbind(paste0(vars, "_mun"), paste0(vars, "_ofi"))))
}

# --- 2.1 Pobreza por NBI e IPM ------------------------------------------------
# Los indicadores municipales vienen en porcentaje (0-100) y se publican como
# proporción, igual que los oficiales. La provincia usa el agregado oficial si
# lo tiene y, si no, el promedio ponderado por población (válido para % de
# personas; para IPM de hogares lo correcto sería ponderar por hogares, y así
# está anotado en la propia etiqueta de la fila).
.hoja_ecv_porcentajes <- function(prov, vars) {
  subreg <- subregion_dominante(prov)
  municipios <- .ecv_municipios(prov)
  for (v in vars) municipios[[v]] <- municipios[[v]] / 100

  oficial_prov <- .ecv_oficial("PROVINCIA", prov$id)
  if (nrow(oficial_prov)) {
    valores_prov <- oficial_prov
    etiqueta_prov <- sprintf("PROVINCIA %s (ECV oficial)", toupper(prov$etiqueta))
  } else {
    valores_prov <- .ecv_fila_ponderada(municipios, prov, vars)
    etiqueta_prov <- sprintf("PROVINCIA %s (promedio ponderado; sin ECV oficial)",
                             toupper(prov$etiqueta))
  }

  .ecv_ensamblar(municipios, vars, list(
    list(etiqueta = etiqueta_prov, tipo = "Provincia",
         provincia = prov$nombre_datos, valores = valores_prov),
    list(etiqueta = sprintf("SUBREGIÓN %s (ECV oficial)", subreg), tipo = "Subregión",
         subregion = subreg, valores = .ecv_oficial("SUBREGION", subreg)),
    list(etiqueta = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)", tipo = "Departamento",
         provincia = "DEPARTAMENTO DE ANTIOQUIA",
         valores = .ecv_oficial("DEPARTAMENTO", "ANTIOQUIA"))
  ))
}

# --- 2.2 Gini -----------------------------------------------------------------
# El Gini NO es promediable entre municipios: un promedio ignora la desigualdad
# ENTRE municipios y la subestima. Por eso solo se muestran los valores
# oficiales, y donde la ECV no publica agregado la fila queda vacía (provincias
# sin dato oficial y departamento, que la ECV no calcula).
.hoja_ecv_gini <- function(prov) {
  vars <- c("tot_gini_hog", "urb_gini_hog", "rur_gini_hog",
            "tot_gini_lab", "urb_gini_lab", "rur_gini_lab")
  subreg <- subregion_dominante(prov)
  municipios <- .ecv_municipios(prov)

  oficial_prov <- .ecv_oficial("PROVINCIA", prov$id)
  etiqueta_prov <- if (nrow(oficial_prov)) {
    sprintf("PROVINCIA %s (Gini ECV oficial)", toupper(prov$etiqueta))
  } else {
    sprintf("PROVINCIA %s (Gini ECV oficial: no disponible)", toupper(prov$etiqueta))
  }

  .ecv_ensamblar(municipios, vars, list(
    list(etiqueta = etiqueta_prov, tipo = "Provincia (ECV oficial)",
         provincia = prov$nombre_datos, valores = oficial_prov),
    list(etiqueta = sprintf("SUBREGIÓN %s (Gini ECV oficial)", subreg),
         tipo = "Subregión (ECV oficial)", subregion = subreg,
         valores = .ecv_oficial("SUBREGION", subreg)),
    list(etiqueta = "DEPARTAMENTO (ANTIOQUIA) (Gini ECV oficial: no disponible)",
         tipo = "Departamento (ECV oficial)",
         provincia = "DEPARTAMENTO DE ANTIOQUIA", valores = NULL)
  ))
}

# --- 2.3 Ocupación e informalidad ---------------------------------------------
# La ECV no publica agregado provincial de mercado laboral: la provincia
# siempre es promedio ponderado por población.
.hoja_ecv_ocupacion <- function(prov) {
  vars <- c("tot_to", "urb_to", "rur_to",
            "tot_emp_informal", "urb_emp_informal", "rur_emp_informal")
  subreg <- subregion_dominante(prov)
  municipios <- .ecv_municipios(prov)
  for (v in vars) municipios[[v]] <- municipios[[v]] / 100

  .ecv_ensamblar(municipios, vars, list(
    list(etiqueta = sprintf(
           "PROVINCIA %s (promedio ponderado; sin ECV oficial de provincia)",
           toupper(prov$etiqueta)),
         tipo = "Provincia", provincia = prov$nombre_datos,
         valores = .ecv_fila_ponderada(municipios, prov, vars)),
    list(etiqueta = sprintf("SUBREGIÓN %s (ECV oficial)", subreg), tipo = "Subregión",
         subregion = subreg, valores = .ecv_oficial("SUBREGION", subreg)),
    list(etiqueta = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)", tipo = "Departamento",
         provincia = "DEPARTAMENTO DE ANTIOQUIA",
         valores = .ecv_oficial("DEPARTAMENTO", "ANTIOQUIA"))
  ))
}

# --- 2.4 Desocupación y jóvenes que no estudian ni trabajan (NiNi) ------------
# Desocupación: no hay oficial de provincia, se pondera. NiNi: la ECV sí publica
# provincia para 6 de las 11; cuando existe, se usa el oficial.
.hoja_ecv_desocupacion <- function(prov) {
  vars <- c("tot_td", "tot_td_15_28", "tot_nini")
  subreg <- subregion_dominante(prov)
  municipios <- .ecv_municipios(prov)
  for (v in vars) municipios[[v]] <- municipios[[v]] / 100

  valores_prov <- .ecv_fila_ponderada(municipios, prov, vars)
  oficial_prov <- .ecv_oficial("PROVINCIA", prov$id)
  if (nrow(oficial_prov)) {
    valores_prov$tot_nini <- as.numeric(oficial_prov$tot_nini[1])
    etiqueta_prov <- sprintf("PROVINCIA %s (desoc.: ponderado; NiNi: ECV oficial)",
                             toupper(prov$etiqueta))
  } else {
    etiqueta_prov <- sprintf(
      "PROVINCIA %s (promedio ponderado; sin ECV oficial de provincia)",
      toupper(prov$etiqueta))
  }

  .ecv_ensamblar(municipios, vars, list(
    list(etiqueta = etiqueta_prov, tipo = "Provincia",
         provincia = prov$nombre_datos, valores = valores_prov),
    list(etiqueta = sprintf("SUBREGIÓN %s (ECV oficial)", subreg), tipo = "Subregión",
         subregion = subreg, valores = .ecv_oficial("SUBREGION", subreg)),
    list(etiqueta = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)", tipo = "Departamento",
         provincia = "DEPARTAMENTO DE ANTIOQUIA",
         valores = .ecv_oficial("DEPARTAMENTO", "ANTIOQUIA"))
  ))
}

# =============================================================================
# 3. Índice de Dependencia Económica (IDE)
# -----------------------------------------------------------------------------
# IDE = (población <15 + población 65+) / población 15-64 × 100.
# Los agregados se recomputan desde las sumas de los grupos de edad (exacto):
# promediar los IDE municipales daría otro número.
# =============================================================================

.hoja_dependencia_economica <- function(prov) {
  pq <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = "Rangos_Quintenios")
  c_cod  <- col_req(pq, "DPMP")
  c_anio <- col_req(pq, "AÑO", "ANO")
  c_area <- col_req(pq, "ÁREA GEOGRÁFICA", "AREA GEOGRAFICA")

  rangos <- function(...) vapply(c(...), function(r) col_req(pq, paste0("TOTAL (", r, ")")),
                                 character(1))
  g_men15 <- rangos("0-4", "5-9", "10-14")
  g_1564  <- rangos(paste0(seq(15, 60, 5), "-", seq(19, 64, 5)))
  g_65mas <- rangos("65-69", "70-74", "75-79", "80-84", "85 y más")

  suma <- function(d, columnas) rowSums(sapply(columnas, function(k) a_numero(d[[k]])),
                                        na.rm = TRUE)

  universo <- pq |>
    dplyr::filter(a_numero(.data[[c_anio]]) == 2025,
                  stringr::str_squish(as.character(.data[[c_area]])) == "Total")
  universo <- data.frame(
    ind_mpio  = as.integer(a_numero(universo[[c_cod]])),
    pob_men15 = suma(universo, g_men15),
    pob_1564  = suma(universo, g_1564),
    pob_65mas = suma(universo, g_65mas),
    stringsAsFactors = FALSE
  ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$municipio)

  subreg <- subregion_dominante(prov)
  agregar_totales(municipios, universo = universo, prov = prov,
                  columnas = c("pob_men15", "pob_1564", "pob_65mas"),
                  como = "suma") |>
    dplyr::mutate(
      ide = (.data$pob_men15 + .data$pob_65mas) / .data$pob_1564 * 100,
      municipio = dplyr::case_when(
        .data$tipo_fila == "Total provincia"    ~ sprintf("PROVINCIA %s (agregado)",
                                                          toupper(prov$etiqueta)),
        .data$tipo_fila == "Total subregión"    ~ sprintf("SUBREGIÓN %s (agregado)", subreg),
        .data$tipo_fila == "Total departamento" ~ "DEPARTAMENTO (ANTIOQUIA) (agregado)",
        TRUE ~ .data$municipio
      )
    ) |>
    .territorio_agregados(prov, subreg) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "ide", "tipo_fila")
}

# =============================================================================
# 4. Densidad empresarial (DATALAKE DEyC, 2023)
# -----------------------------------------------------------------------------
# Se lee por posición (A = unidad geográfica, B = código, F = indicador,
# G = año, H = dato). La fila provincial es un promedio ponderado por población
# porque el indicador ya está normalizado por cada mil habitantes.
# =============================================================================

INDICADOR_DENSIDAD <- "Densidad empresarial (número de empresas por cada mil habitantes)"

.hoja_densidad_empresarial <- function(prov) {
  d <- .leer_por_posicion(entrada("DATALAKE DEyC.xlsx"), "Sheet1", saltar = 1)

  municipios <- d |>
    dplyr::filter(.data$A == "Municipal",
                  .data$F == INDICADOR_DENSIDAD,
                  a_numero(.data$G) == 2023) |>
    dplyr::transmute(ind_mpio = as.integer(a_numero(.data$B)),
                     dens_emp = a_numero(.data$H)) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(.pesos_poblacion(), by = "ind_mpio") |>
    dplyr::arrange(.data$municipio)

  agregar_totales(municipios, universo = NULL, prov = prov,
                  columnas = "dens_emp", como = "promedio_ponderado",
                  pesos = "pob_peso") |>
    dplyr::mutate(
      municipio = ifelse(
        .data$tipo_fila == "Total provincia",
        sprintf("PROMEDIO PONDERADO PROVINCIA %s (por población)", toupper(prov$etiqueta)),
        .data$municipio
      )
    ) |>
    .territorio_agregados(prov, NA_character_) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "dens_emp", "tipo_fila")
}

# =============================================================================
# 5. Valor agregado municipal 2015-2024
# -----------------------------------------------------------------------------
# Precios constantes de 2015, MILES DE MILLONES de pesos (la unidad del insumo;
# se conserva y se declara en los encabezados y en los subtítulos de las
# figuras). El per cápita sí va en pesos corrientes de la serie constante, por
# eso multiplica por 1e9.
# Se lee por posición desde la fila 4 (A = año, E = código de municipio,
# H..U = ramas, J/M/V = agregados sectoriales, W = VA total).
# NOTA 1: los tres agregados sectoriales NO suman el VA total en la serie a
# precios constantes (queda un remanente sin distribuir de ~5 %); las
# distribuciones porcentuales se calculan siempre sobre el VA total, igual que
# en el .do, y la figura de composición muestra ese remanente aparte.
# NOTA 2: el Anexo 1 publicó esta tabla a PRECIOS CORRIENTES (hoja
# "PIB-Mpal 2015-2024 Corrient" del libro original PIB-VA_Mpal_...xlsm), no a
# precios constantes. El derivado que usa el flujo solo trae la hoja de
# constantes, así que las cifras de este pipeline y las del Anexo difieren por
# el deflactor (2024: 134.481 vs 230.524 miles de millones en el departamento).
# =============================================================================

# Columna del insumo (posición) -> nombre interno.
COLUMNAS_VA <- c(
  A = "anio", E = "ind_mpio",
  H = "va_agricultura", I = "va_minas", J = "va_primario",
  K = "va_manufactura", L = "va_construccion", M = "va_secundario",
  N = "va_electricidad", O = "va_comercio", P = "va_informacion",
  Q = "va_financieras", R = "va_inmobiliarias", S = "va_profesionales",
  T = "va_administracion", U = "va_artisticas", V = "va_terciario", W = "va_total"
)

# Ramas detalladas, en miles de millones de pesos constantes de 2015.
RAMAS_VA <- c(
  va_agricultura    = "VA Agricultura, ganadería, caza, silvicultura y pesca",
  va_minas          = "VA Explotación de minas y canteras",
  va_manufactura    = "VA Industrias manufactureras",
  va_construccion   = "VA Construcción",
  va_electricidad   = "VA Suministro de electricidad, gas y agua",
  va_comercio       = "VA Comercio, transporte y alojamiento",
  va_informacion    = "VA Información y comunicaciones",
  va_financieras    = "VA Actividades financieras y de seguros",
  va_inmobiliarias  = "VA Actividades inmobiliarias",
  va_profesionales  = "VA Actividades profesionales, científicas y técnicas",
  va_administracion = "VA Administración pública, educación y salud",
  va_artisticas     = "VA Actividades artísticas y de entretenimiento"
)

.valor_agregado <- function(prov) {
  bruto <- .leer_por_posicion(
    entrada("curados", "VALOR_AGREGADO_20152024_MUNICIPIOS.xlsx"),
    "PIB Mpal 2015-2024 Cons", saltar = 3
  )

  va <- as.data.frame(lapply(names(COLUMNAS_VA), function(k) a_numero(bruto[[k]])))
  names(va) <- unname(COLUMNAS_VA)
  va <- va |>
    dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$anio),
                  .data$anio >= 2015, .data$anio <= 2024) |>
    dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio),
                  anio = as.integer(.data$anio))

  # El total departamental se calcula sobre TODOS los municipios del insumo,
  # antes de recortar a las provincias.
  va <- va |>
    dplyr::group_by(.data$anio) |>
    dplyr::mutate(dpto_va_total = sum(.data$va_total, na.rm = TRUE)) |>
    dplyr::ungroup()

  municipios <- va |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::group_by(.data$anio) |>
    dplyr::mutate(prov_va_total = sum(.data$va_total, na.rm = TRUE)) |>
    dplyr::ungroup() |>
    dplyr::left_join(.poblacion(2015:2024), by = c("ind_mpio", "anio")) |>
    dplyr::mutate(tipo_fila = "Municipio")

  sectores <- c("va_primario", "va_secundario", "va_terciario")
  ramas <- names(RAMAS_VA)

  # Fila provincial por año: se suman los niveles y se recomputan proporciones
  # y per cápita (no se promedian).
  total_prov <- municipios |>
    dplyr::group_by(.data$anio) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(c("va_total", sectores, ramas, "poblacion")),
                    ~ sum(.x, na.rm = TRUE)),
      dpto_va_total = mean(.data$dpto_va_total, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      ind_mpio  = NA_integer_,
      municipio = sprintf("TOTAL PROVINCIA %s", toupper(prov$etiqueta)),
      subregion = NA_character_,
      provincia = prov$nombre_datos,
      tipo_fila = "Total provincia"
    )

  dplyr::bind_rows(municipios, total_prov) |>
    dplyr::mutate(
      prop_va_prov = ifelse(.data$tipo_fila == "Total provincia", 1,
                            .data$va_total / .data$prov_va_total),
      prop_va_dpto = .data$va_total / .data$dpto_va_total,
      va_pc        = .data$va_total * 1e9 / .data$poblacion,
      prop_va_primario   = .data$va_primario   / .data$va_total,
      prop_va_secundario = .data$va_secundario / .data$va_total,
      prop_va_terciario  = .data$va_terciario  / .data$va_total
    ) |>
    dplyr::arrange(.data$anio,
                   match(.data$tipo_fila, c("Municipio", "Total provincia")),
                   .data$municipio)
}

# =============================================================================
# 6. Minero-energético: capacidad instalada de generación (XM)
# -----------------------------------------------------------------------------
# El insumo no trae código DANE: el cruce con la provincia se hace por NOMBRE
# de municipio normalizado contra el crosswalk, que es la fuente de verdad del
# flujo. Por eso la capacidad de la provincia puede diferir de los totales
# precalculados del propio archivo (que usan otra lista de municipios).
# =============================================================================

.hoja_energia_tecnologia <- function() {
  d <- .leer_por_posicion(entrada("Energia_NorteAntioquia.xlsx"),
                          "SIN por Tecnología", saltar = 2)
  d |>
    dplyr::transmute(tecnologia    = stringr::str_squish(as.character(.data$A)),
                     cap_mw        = a_numero(.data$B),
                     participacion = a_numero(.data$C)) |>
    dplyr::filter(!is.na(.data$tecnologia), .data$tecnologia != "NA",
                  !stringr::str_detect(.data$tecnologia, "Fuente"))
}

#' Plantas de generación de Antioquia con el municipio cruzado al crosswalk.
.energia_plantas <- function() {
  d <- .leer_por_posicion(entrada("Energia_NorteAntioquia.xlsx"),
                          "Antioquia – Todas las plantas", saltar = 2)
  cw <- crosswalk_provincias() |>
    dplyr::mutate(clave = normalizar_municipio(.data$nvl_label))

  d |>
    dplyr::transmute(
      nombre_fuente = stringr::str_squish(as.character(.data$A)),
      central       = as.character(.data$B),
      tecnologia    = as.character(.data$C),
      estado        = as.character(.data$D),
      empresa       = as.character(.data$F),
      cap_mw        = a_numero(.data$G)
    ) |>
    dplyr::filter(
      !is.na(.data$nombre_fuente), .data$nombre_fuente != "NA",
      !stringr::str_detect(.data$nombre_fuente, "Total|Resumen|Fuente|Nota"),
      !is.na(.data$cap_mw)
    ) |>
    dplyr::mutate(clave = normalizar_municipio(.data$nombre_fuente)) |>
    dplyr::left_join(cw, by = "clave")
}

.hojas_energia <- function(prov, tecnologia) {
  sin_total <- sum(tecnologia$cap_mw[tecnologia$tecnologia == "Total SIN"], na.rm = TRUE)
  plantas   <- .energia_plantas()
  ant_total <- sum(plantas$cap_mw, na.rm = TRUE)

  centrales <- plantas |>
    dplyr::filter(!is.na(.data$id_provincia), .data$id_provincia == prov$id) |>
    dplyr::mutate(part_sin = .data$cap_mw / sin_total,
                  part_ant = .data$cap_mw / ant_total,
                  tipo_fila = "Central") |>
    dplyr::arrange(dplyr::desc(.data$cap_mw))

  prov_total <- sum(centrales$cap_mw, na.rm = TRUE)

  # El total provincial es SIEMPRE una fila, aunque la provincia no tenga
  # centrales (entonces vale 0 MW).
  fila_total <- data.frame(
    ind_mpio = NA_integer_, municipio = sprintf("TOTAL PROVINCIA %s", toupper(prov$etiqueta)),
    subregion = NA_character_, provincia = prov$nombre_datos,
    central = NA_character_, tecnologia = NA_character_, estado = NA_character_,
    empresa = NA_character_, cap_mw = prov_total,
    part_sin = prov_total / sin_total, part_ant = prov_total / ant_total,
    tipo_fila = "Total provincia", stringsAsFactors = FALSE
  )

  hoja_centrales <- dplyr::bind_rows(
    dplyr::select(centrales, "ind_mpio", "municipio", "subregion", "provincia",
                  "central", "tecnologia", "estado", "empresa",
                  "cap_mw", "part_sin", "part_ant", "tipo_fila"),
    fila_total
  )

  hoja_participacion <- data.frame(
    ambito = c(sprintf("PROVINCIA %s", prov$etiqueta),
               "Departamento de Antioquia",
               "Sistema Interconectado Nacional (SIN)"),
    cap_mw = c(prov_total, ant_total, sin_total),
    part_sin = c(prov_total / sin_total, ant_total / sin_total, 1),
    part_ant = c(prov_total / ant_total, 1, NA_real_),
    stringsAsFactors = FALSE
  )

  list(centrales = hoja_centrales, participacion = hoja_participacion)
}

# =============================================================================
# 7. Minero-energético: títulos mineros vigentes por tipo de mineral
# -----------------------------------------------------------------------------
# Fuente ANM (catastro minero). No trae código DANE: cruce por nombre de
# municipio normalizado. Se cuentan los títulos ACTIVOS distintos por mineral;
# un título con varios minerales cuenta en cada uno y uno que cubre varios
# municipios cuenta una sola vez. Los minerales vienen en una lista dentro de
# una celda, con paréntesis que a su vez contienen comas.
#
# DIFERENCIA DELIBERADA CON EL .do: allí el cruce se hace contra la celda
# `Municipios` COMPLETA, así que los títulos que cubren varios municipios
# ("REMEDIOS, SEGOVIA") nunca casan y se pierden — 47 de los 102 títulos
# activos de la provincia 2. Aquí la celda se separa por comas antes de cruzar,
# que es lo que dice el propio comentario del .do y lo que reproduce las cifras
# publicadas en el Anexo 1 (oro 49, plata 11, oro y concentrados 10).
# =============================================================================

.hoja_titulos_mineros <- function(prov) {
  d <- leer_excel(entrada("Actualización", "Fuentes", "TITULOSMINAS_ORIGINAL.xlsx"),
                  hoja = "Título Vigente (1)")
  c_exp <- col_req(d, "CODIGO_EXPEDIENTE")
  c_est <- col_req(d, "Estado")
  c_min <- col_req(d, "Minerales")
  c_mun <- col_req(d, "Municipios")

  cw <- crosswalk_provincias() |>
    dplyr::filter(.data$id_provincia == prov$id) |>
    dplyr::mutate(clave = normalizar_municipio(.data$nvl_label))

  titulos <- data.frame(
    expediente = as.character(d[[c_exp]]),
    estado     = stringr::str_squish(as.character(d[[c_est]])),
    minerales  = as.character(d[[c_min]]),
    municipios = as.character(d[[c_mun]]),
    stringsAsFactors = FALSE
  ) |>
    dplyr::filter(.data$estado == "Activo") |>
    tidyr::separate_rows("municipios", sep = ",") |>
    dplyr::mutate(clave = normalizar_municipio(.data$municipios)) |>
    dplyr::filter(.data$clave %in% cw$clave) |>
    dplyr::distinct(.data$expediente, .data$minerales)

  if (nrow(titulos) == 0) {
    return(data.frame(grupo_mineral = "SIN TÍTULOS EN LA PROVINCIA",
                      n_titulos = 0,
                      provincia = prov$nombre_datos,
                      stringsAsFactors = FALSE))
  }

  titulos |>
    # Los paréntesis traen comas internas ("ARENAS (DE RIO), GRAVAS"): se
    # eliminan antes de separar, si no cada paréntesis generaría un mineral.
    dplyr::mutate(minerales = stringr::str_remove_all(.data$minerales, "\\([^)]*\\)")) |>
    tidyr::separate_rows("minerales", sep = ",") |>
    dplyr::mutate(mineral = stringr::str_squish(toupper(.data$minerales))) |>
    dplyr::filter(.data$mineral != "") |>
    dplyr::distinct(.data$expediente, .data$mineral) |>
    dplyr::count(.data$mineral, name = "n_titulos") |>
    dplyr::arrange(dplyr::desc(.data$n_titulos), .data$mineral) |>
    dplyr::transmute(grupo_mineral = .data$mineral,
                     n_titulos = .data$n_titulos,
                     provincia = prov$nombre_datos)
}

# =============================================================================
# 8. Turismo: instrumentos de planificación
# -----------------------------------------------------------------------------
# Tabla categórica por municipio (no tiene agregado provincial). Se lee por
# posición (A = código de municipio, C = indicador, D = formalización de la
# mesa) para no depender de encabezados con acentos y puntos.
# =============================================================================

.hoja_turismo_instrumentos <- function(prov) {
  archivo <- entrada("instrumentos_planificacion_turistica_antioquia.xlsx")

  hoja <- function(nombre, columnas, nuevos) {
    d <- .leer_por_posicion(archivo, nombre, saltar = 1)
    out <- data.frame(ind_mpio = as.integer(a_numero(d$A)), stringsAsFactors = FALSE)
    for (i in seq_along(columnas)) out[[nuevos[i]]] <- as.character(d[[columnas[i]]])
    dplyr::filter(out, !is.na(.data$ind_mpio))
  }

  crosswalk_provincias() |>
    dplyr::filter(.data$id_provincia == prov$id) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia") |>
    dplyr::left_join(hoja("Inventario Turístico", "C", "inventario_turistico"),
                     by = "ind_mpio") |>
    dplyr::left_join(hoja("Plan Local de Turismo", "C", "plan_local_turismo"),
                     by = "ind_mpio") |>
    dplyr::left_join(hoja("Mesa Local de Turismo", c("C", "D"),
                          c("mesa_local_turismo", "mesa_formalizada")),
                     by = "ind_mpio") |>
    dplyr::arrange(.data$municipio)
}

# =============================================================================
# 9. Orquestación: arma el economia.xlsx completo
# =============================================================================

tabla_economia <- function(prov) {
  message("== 05 Economía — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "05_Economia"), "economia.xlsx")
  # El .do borraba el archivo previo para no dejar hojas obsoletas.
  if (file.exists(archivo)) unlink(archivo)

  hojas <- list()

  # --- 9.1 Visitantes extranjeros -------------------------------------------
  universo_ext <- .extranjeros_universo()
  hojas$extranjeros_municipio <- .hoja_extranjeros_municipio(prov, universo_ext)
  escribir_hoja(
    hojas$extranjeros_municipio, archivo, "extranjeros_municipio",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  tipo_fila = "Tipo de fila", anio = "Año",
                  extranjeros = "Visitantes extranjeros no residentes"),
    formatos = c(anio = "0", extranjeros = "#,##0")
  )

  hojas$comparativo_pap_antioquia <- .hoja_comparativo_extranjeros(prov, universo_ext)
  escribir_hoja(
    hojas$comparativo_pap_antioquia, archivo, "comparativo_pap_antioquia",
    etiquetas = c(anio = "Año", provincia = "Provincia",
                  total_provincia = "Visitantes extranjeros provincia",
                  total_antioquia = "Visitantes extranjeros Antioquia",
                  participacion = "Participación de la provincia en el total departamental"),
    formatos = c(anio = "0", total_provincia = "#,##0",
                 total_antioquia = "#,##0", participacion = "0.00%")
  )

  # --- 9.2 Pobreza y mercado laboral (ECV) ----------------------------------
  vars_nbi <- c("tot_pob_nbi", "urb_pob_nbi", "rur_pob_nbi")
  hojas$ecv_pobreza <- .hoja_ecv_porcentajes(prov, vars_nbi)
  escribir_hoja(
    dplyr::select(hojas$ecv_pobreza, dplyr::all_of(.ecv_columnas(vars_nbi))),
    archivo, "ecv_pobreza",
    etiquetas = .ecv_etiquetas(c(
      tot_pob_nbi = "Personas en pobreza por NBI - total",
      urb_pob_nbi = "Personas en pobreza por NBI - urbana",
      rur_pob_nbi = "Personas en pobreza por NBI - rural")),
    formatos = .ecv_formatos(vars_nbi, "0.0%")
  )

  vars_ipm <- c("tot_pob_ipm_hogares", "tot_pob_ipm")
  hojas$ecv_ipm <- .hoja_ecv_porcentajes(prov, vars_ipm)
  escribir_hoja(
    dplyr::select(hojas$ecv_ipm, dplyr::all_of(.ecv_columnas(vars_ipm))),
    archivo, "ecv_ipm",
    etiquetas = .ecv_etiquetas(c(
      tot_pob_ipm_hogares = "Hogares en pobreza IPM - total",
      tot_pob_ipm         = "Personas en pobreza IPM - total")),
    formatos = .ecv_formatos(vars_ipm, "0.0%")
  )

  vars_gini <- c("tot_gini_hog", "urb_gini_hog", "rur_gini_hog",
                 "tot_gini_lab", "urb_gini_lab", "rur_gini_lab")
  hojas$ecv_gini <- .hoja_ecv_gini(prov)
  escribir_hoja(
    dplyr::select(hojas$ecv_gini, dplyr::all_of(.ecv_columnas(vars_gini))),
    archivo, "ecv_gini",
    etiquetas = .ecv_etiquetas(c(
      tot_gini_hog = "Gini ingresos del hogar - total",
      urb_gini_hog = "Gini ingresos del hogar - urbano",
      rur_gini_hog = "Gini ingresos del hogar - rural",
      tot_gini_lab = "Gini laboral - total",
      urb_gini_lab = "Gini laboral - urbano",
      rur_gini_lab = "Gini laboral - rural")),
    formatos = .ecv_formatos(vars_gini, "0.000")
  )

  vars_oi <- c("tot_to", "urb_to", "rur_to",
               "tot_emp_informal", "urb_emp_informal", "rur_emp_informal")
  hojas$ecv_ocupacion_informal <- .hoja_ecv_ocupacion(prov)
  escribir_hoja(
    dplyr::select(hojas$ecv_ocupacion_informal, dplyr::all_of(.ecv_columnas(vars_oi))),
    archivo, "ecv_ocupacion_informal",
    etiquetas = .ecv_etiquetas(c(
      tot_to           = "Tasa de ocupación - total",
      urb_to           = "Tasa de ocupación - urbano",
      rur_to           = "Tasa de ocupación - rural",
      tot_emp_informal = "Tasa de informalidad laboral - total",
      urb_emp_informal = "Tasa de informalidad laboral - urbano",
      rur_emp_informal = "Tasa de informalidad laboral - rural")),
    formatos = .ecv_formatos(vars_oi, "0.0%")
  )

  vars_dn <- c("tot_td", "tot_td_15_28", "tot_nini")
  hojas$ecv_desocupacion_nini <- .hoja_ecv_desocupacion(prov)
  escribir_hoja(
    dplyr::select(hojas$ecv_desocupacion_nini, dplyr::all_of(.ecv_columnas(vars_dn))),
    archivo, "ecv_desocupacion_nini",
    etiquetas = .ecv_etiquetas(c(
      tot_td       = "Tasa de desocupación - total",
      tot_td_15_28 = "Tasa de desocupación jóvenes (15-28)",
      tot_nini     = "Jóvenes que no estudian ni trabajan (NiNi)")),
    formatos = .ecv_formatos(vars_dn, "0.0%")
  )

  # --- 9.3 Turismo: instrumentos de planificación ---------------------------
  hojas$turismo_instrumentos <- .hoja_turismo_instrumentos(prov)
  escribir_hoja(
    hojas$turismo_instrumentos, archivo, "turismo_instrumentos",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  inventario_turistico = "Inventario turístico",
                  plan_local_turismo   = "Plan Local de Turismo",
                  mesa_local_turismo   = "Mesa Local de Turismo",
                  mesa_formalizada     = paste("Mesa Local de Turismo formalizada",
                                               "(constituida y reglamentada)"))
  )

  # --- 9.4 Índice de dependencia económica ----------------------------------
  hojas$dependencia_economica <- .hoja_dependencia_economica(prov)
  escribir_hoja(
    dplyr::select(hojas$dependencia_economica, -"tipo_fila"),
    archivo, "dependencia_economica",
    etiquetas = c(ETIQUETAS_TERRITORIO, ide = "Índice de Dependencia Económica"),
    formatos = c(ide = "#,##0.0")
  )

  # --- 9.5 Densidad empresarial ---------------------------------------------
  hojas$densidad_empresarial <- .hoja_densidad_empresarial(prov)
  escribir_hoja(
    dplyr::select(hojas$densidad_empresarial, -"tipo_fila"),
    archivo, "densidad_empresarial",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  dens_emp = "Densidad empresarial (empresas por cada 1.000 hab.)"),
    formatos = c(dens_emp = "#,##0.00")
  )

  # --- 9.6 Valor agregado ----------------------------------------------------
  va <- .valor_agregado(prov)
  hojas$valor_agregado <- va
  escribir_hoja(
    dplyr::select(va, "ind_mpio", "municipio", "subregion", "provincia", "anio",
                  "va_total", "va_primario", "va_secundario", "va_terciario",
                  "prop_va_primario", "prop_va_secundario", "prop_va_terciario",
                  "prop_va_prov", "prop_va_dpto", "va_pc"),
    archivo, "valor_agregado",
    etiquetas = c(ETIQUETAS_TERRITORIO, anio = "Año",
                  va_total      = "Valor agregado total (miles de millones $ constantes de 2015)",
                  va_primario   = "VA actividades primarias (miles de millones $ constantes de 2015)",
                  va_secundario = "VA actividades secundarias (miles de millones $ constantes de 2015)",
                  va_terciario  = "VA actividades terciarias (miles de millones $ constantes de 2015)",
                  prop_va_primario   = "Participación del VA - primarias",
                  prop_va_secundario = "Participación del VA - secundarias",
                  prop_va_terciario  = "Participación del VA - terciarias",
                  prop_va_prov = "Proporción del VA municipal sobre total provincial",
                  prop_va_dpto = "Proporción del VA municipal sobre total departamental",
                  va_pc = "Valor agregado per cápita (pesos constantes de 2015)"),
    formatos = c(anio = "0", va_total = "#,##0.0", va_primario = "#,##0.0",
                 va_secundario = "#,##0.0", va_terciario = "#,##0.0",
                 prop_va_primario = "0.0%", prop_va_secundario = "0.0%",
                 prop_va_terciario = "0.0%", prop_va_prov = "0.0%",
                 prop_va_dpto = "0.00%", va_pc = "#,##0")
  )

  hojas$va_actividades <- va
  escribir_hoja(
    dplyr::select(va, "ind_mpio", "municipio", "subregion", "provincia", "anio",
                  dplyr::all_of(names(RAMAS_VA))),
    archivo, "va_actividades",
    etiquetas = c(ETIQUETAS_TERRITORIO, anio = "Año", RAMAS_VA),
    formatos = c(stats::setNames(rep("#,##0.0", length(RAMAS_VA)), names(RAMAS_VA)),
                 anio = "0")
  )

  # --- 9.7 Minero-energético: capacidad instalada ---------------------------
  hojas$energia_tecnologia <- .hoja_energia_tecnologia()
  escribir_hoja(
    hojas$energia_tecnologia, archivo, "energia_tecnologia",
    etiquetas = c(tecnologia = "Tecnología",
                  cap_mw = "Capacidad instalada (MW)",
                  participacion = "Participación en el SIN"),
    formatos = c(cap_mw = "#,##0.00", participacion = "0.0%")
  )

  energia <- .hojas_energia(prov, hojas$energia_tecnologia)
  hojas$energia_centrales <- energia$centrales
  escribir_hoja(
    dplyr::select(energia$centrales, -"tipo_fila"), archivo, "energia_centrales",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  central = "Central / Planta", tecnologia = "Tecnología",
                  estado = "Estado", empresa = "Empresa operadora",
                  cap_mw = "Capacidad efectiva neta (MW)",
                  part_sin = "Participación en el SIN",
                  part_ant = "Participación en Antioquia"),
    formatos = c(cap_mw = "#,##0.00", part_sin = "0.000%", part_ant = "0.000%")
  )

  hojas$energia_participacion <- energia$participacion
  escribir_hoja(
    energia$participacion, archivo, "energia_participacion",
    etiquetas = c(ambito = "Ámbito", cap_mw = "Capacidad instalada (MW)",
                  part_sin = "Participación en el SIN",
                  part_ant = "Participación en Antioquia"),
    formatos = c(cap_mw = "#,##0.00", part_sin = "0.000%", part_ant = "0.000%")
  )

  # --- 9.8 Minero-energético: títulos mineros -------------------------------
  hojas$titulos_mineros <- .hoja_titulos_mineros(prov)
  escribir_hoja(
    hojas$titulos_mineros, archivo, "titulos_mineros",
    etiquetas = c(grupo_mineral = "Tipo de mineral",
                  n_titulos = "Número de títulos mineros",
                  provincia = "Provincia"),
    formatos = c(n_titulos = "#,##0")
  )

  attr(hojas, "archivo") <- archivo
  invisible(hojas)
}
