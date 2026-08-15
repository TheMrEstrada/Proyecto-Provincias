# =============================================================================
# 10_seguridad.R — Sección 10: Seguridad
#
# TABLAS (13 hojas de un solo .xlsx), por bloque temático:
#   cultivos ilícitos      coca
#   oro de aluvión         evoa
#   delitos alto impacto   delitos
#   conflicto armado       total_victimas, proporcion_hechos
#   restitución de tierras srtdaf, tasas
#   percepción ciudadana   P1A_barrio, P2_cambio_barrio, P4A_municipio,
#                          P6_cambio_municipio
#   riesgo de victimización irv
#   desaparición forzada   desaparecidos
#
# INPUTS:
#   01_Data/01_Derived/CULTILICITOS_PROVINCIAS.xlsx   (hoja "Coca")
#   01_Data/01_Derived/EVOA_PROVINCIAS.xlsx           (hoja "EVOA")
#   01_Data/01_Derived/HECHOSVICTIM_PROVINCIAS.xlsx   (hoja "hechos victim")
#   01_Data/01_Derived/SRDAFT_PROVINCIAS.xlsx         (hoja "SRTDAF")
#       OJO: esos cuatro derivados NO los produce ningún script del pipeline;
#       se arman a mano en Excel. Si se rehace la cadena de derivados hay que
#       reconstruirlos aparte.
#   01_Data/01_Derived/seguridad_policia.parquet      (tabla larga por delito y año)
#   01_Data/01_Derived/poblacion_total_2025.dta
#   01_Data/01_Derived/percepcion_seguridad.dta
#       Este derivado reemplaza el import del crudo "Data anonimizada encuesta
#       percepcion 2018-2025.xlsx" que hacía el .do: el crudo no está en el
#       repositorio (1363 columnas, no versionado) y el derivado contiene
#       exactamente las 8 variables que el .do conservaba. Si falta, el bloque
#       de percepción se omite con un aviso y el resto de la sección sigue.
#   01_Data/00_Inputs/AREA_ORIGINAL.xlsx              (hoja "Area")
#   01_Data/00_Inputs/IRV-2025.xlsx                   (hoja "Datos")
#   01_Data/00_Inputs/UBPD_desaparecidos_Antioquia.xlsx (hoja "Por Municipio")
#   crosswalks territoriales (01_Derived)
#
# OUTPUTS: 03_Outputs/<Provincia>/10_Seguridad/seguridad.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/10_Seguridad.do
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Constantes de la sección -------------------------------------------------

# Código de subregión (1-9) en la encuesta de percepción ciudadana.
SUBREGION_ENCUESTA <- c(
  "BAJO CAUCA" = 1, "MAGDALENA MEDIO" = 2, "NORDESTE" = 3, "NORTE" = 4,
  "OCCIDENTE" = 5, "ORIENTE" = 6, "SUROESTE" = 7, "URABA" = 8,
  "VALLE DE ABURRA" = 9
)

# Etiquetas compartidas por varias hojas.
ETIQUETAS_TERRITORIO <- c(
  ind_mpio  = "Código DANE",
  municipio = "Municipio",
  subregion = "Subregión",
  provincia = "Provincia"
)

# --- Utilidades internas de la sección ----------------------------------------

#' Columnas de datos de una hoja: las que quedan al descartar las llaves.
#'
#' Tres de los insumos (coca, EVOA, hechos victimizantes) traen los encabezados
#' de las columnas de valores con acentos, espacios y hasta el año como nombre
#' ("2023"), y cambian de una entrega a otra. El .do las renombraba por
#' posición tras descartar las llaves; se hace lo mismo aquí para que la
#' migración no se rompa cuando llegue la actualización del año siguiente.
.columnas_de_valor <- function(datos, llaves) {
  reales <- names(datos)
  fuera <- unlist(lapply(llaves, function(k) col(datos, k)))
  setdiff(reales, fuera[!is.na(fuera)])
}

#' Rellena provincia/subregión de las filas agregadas que produce
#' agregar_totales() (esa utilidad solo rotula el nombre del territorio).
.rotular_agregados <- function(tabla, prov, subreg_dom) {
  dplyr::mutate(
    tabla,
    subregion = dplyr::case_when(
      .data$tipo_fila == "Total subregión" ~ subreg_dom,
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

#' Ordena como el .do: primero los municipios (alfabéticos), después provincia,
#' subregión y departamento.
.ordenar_filas <- function(tabla, ...) {
  orden <- c("Municipio", "Total provincia", "Total subregión", "Total departamento")
  tabla |>
    dplyr::mutate(.orden = match(.data$tipo_fila, orden)) |>
    dplyr::arrange(.data$.orden, ...) |>
    dplyr::select(-".orden")
}

#' Población municipal 2025, área geográfica "Total" (denominador de las tasas).
.poblacion_2025 <- function() {
  leer_derivado("poblacion_total_2025") |>
    dplyr::filter(.data$area_geo == "Total") |>
    dplyr::transmute(
      ind_mpio = as.integer(.data$ind_mpio),
      pob      = as.numeric(.data$Total)
    )
}

# --- Bloque 1: cultivos ilícitos (coca) ---------------------------------------
# El archivo solo trae los municipios con coca, así que una provincia puede no
# tener ninguna fila; en ese caso la hoja queda con la sola fila de total en 0.
# Dos proporciones distintas: (A) la coca del municipio sobre el área TOTAL del
# municipio y (B) sobre el total departamental de coca. El denominador de la
# fila de provincia en (A) es el área de la provincia completa, no la de los
# municipios con coca.

.hoja_coca <- function(prov, archivo) {
  # Área municipal de todo el departamento
  area <- leer_excel(entrada("AREA_ORIGINAL.xlsx"), hoja = "Area")
  areas <- area |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[col_req(area, "COD_MPIO", "ind_mpio")]])),
      area_km2 = a_numero(.data[[col_req(area, "AREA KM2", "AREAKM2", "area_km2")]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()

  area_provincia <- sum(areas$area_km2[areas$id_provincia %in% prov$id], na.rm = TRUE)

  # Hectáreas de coca: la única columna de valor del archivo (el encabezado es
  # el año, "2023" en la entrega vigente).
  bruto <- leer_excel(entrada("curados", "CULTILICITOS_PROVINCIAS.xlsx"), hoja = "Coca")
  c_ha <- .columnas_de_valor(
    bruto, c("CODMPIO", "MUNICIPIO", "CODDEPTO", "DEPARTAMENTO", "subreg", "prov")
  )[1]

  coca <- bruto |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[col_req(bruto, "CODMPIO", "ind_mpio")]])),
      coca_ha  = a_numero(.data[[c_ha]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio))

  # Total departamental: todas las filas del archivo, antes de filtrar
  coca_departamento <- sum(coca$coca_ha, na.rm = TRUE)

  municipios <- coca |>
    con_territorio() |>
    dplyr::filter(.data$id_provincia %in% prov$id) |>
    dplyr::left_join(dplyr::select(areas, "ind_mpio", "area_km2"), by = "ind_mpio") |>
    dplyr::arrange(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "coca_ha", "area_km2")

  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov,
    columnas = c("coca_ha", "area_km2"), como = "suma"
  ) |>
    # El área de la fila de provincia es la de TODOS sus municipios, no solo la
    # de los que registran coca.
    dplyr::mutate(
      area_km2  = ifelse(.data$tipo_fila == "Total provincia", area_provincia, .data$area_km2),
      provincia = ifelse(.data$tipo_fila == "Total provincia", prov$nombre_datos, .data$provincia),
      subregion = ifelse(.data$tipo_fila == "Total provincia", NA_character_, .data$subregion),
      pct_coca_area_mun           = .data$coca_ha / (.data$area_km2 * 100),
      participacion_coca_dept_pct = .data$coca_ha / coca_departamento
    ) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "coca_ha",
                  "pct_coca_area_mun", "participacion_coca_dept_pct", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "coca",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      coca_ha = sprintf("Hectáreas de coca (%s)", c_ha),
      pct_coca_area_mun = "Coca sobre área del municipio (%)",
      participacion_coca_dept_pct = "Coca sobre el total departamental de coca (%)"
    ),
    formatos = c(coca_ha = "#,##0.00", pct_coca_area_mun = "0.00%",
                 participacion_coca_dept_pct = "0.00%")
  )

  tabla
}

# --- Bloque 2: explotación de oro de aluvión (EVOA) ---------------------------
# Detalle municipio × año, y por cada año las filas de provincia, subregión
# mayoritaria y departamento. Las cuatro columnas de hectáreas traen
# encabezados largos y se toman por posición.

.hoja_evoa <- function(prov, archivo) {
  bruto <- leer_excel(entrada("curados", "EVOA_PROVINCIAS.xlsx"), hoja = "EVOA")
  valores <- .columnas_de_valor(
    bruto, c("codigo municipio", "Municipio", "Subregión", "Provincia", "Año")
  )
  if (length(valores) < 4) {
    stop("EVOA_PROVINCIAS.xlsx no trae las 4 columnas de hectáreas esperadas.",
         call. = FALSE)
  }

  universo <- bruto |>
    dplyr::transmute(
      ind_mpio    = as.integer(a_numero(.data[[col_req(bruto, "codigo municipio", "cod_mun")]])),
      anio        = as.integer(a_numero(.data[[col_req(bruto, "Año", "anio")]])),
      ha_permisos = a_numero(.data[[valores[1]]]),
      ha_transito = a_numero(.data[[valores[2]]]),
      ha_ilicita  = a_numero(.data[[valores[3]]]),
      total_evoa  = a_numero(.data[[valores[4]]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()

  columnas <- c("ha_permisos", "ha_transito", "ha_ilicita", "total_evoa")
  subreg_dom <- subregion_dominante(prov)
  anios <- sort(unique(universo$anio))

  tabla <- purrr::map_dfr(anios, function(a) {
    universo_anio <- dplyr::filter(universo, .data$anio == a)
    detalle <- universo_anio |>
      dplyr::filter(.data$id_provincia %in% prov$id) |>
      dplyr::arrange(.data$municipio) |>
      dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                    dplyr::all_of(columnas))
    agregar_totales(detalle, universo = universo_anio, prov = prov,
                    columnas = columnas, como = "suma") |>
      dplyr::mutate(anio = a)
  }) |>
    .rotular_agregados(prov, subreg_dom) |>
    .ordenar_filas(.data$anio, .data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "anio",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "evoa",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      anio = "Año",
      ha_permisos = "Hectáreas con permisos",
      ha_transito = "Hectáreas en tránsito",
      ha_ilicita  = "Hectáreas ilícita",
      total_evoa  = "Total EVOA (ha)"
    ),
    formatos = c(anio = "0", ha_permisos = "#,##0.00", ha_transito = "#,##0.00",
                 ha_ilicita = "#,##0.00", total_evoa = "#,##0.00")
  )

  tabla
}

# --- Bloque 3: delitos de alto impacto ----------------------------------------
# Cuatro tasas por 100.000 habitantes en una sola hoja. Las filas agregadas
# llevan TASA AGREGADA (Σ delitos / Σ población × 100.000), no el promedio de
# las tasas municipales: es el criterio del .do y difiere del informe
# publicado, que promedió las tasas municipales (ver el informe de migración).

# El derivado trae los cuatro delitos en una tabla larga (columnas `delito` y
# `anio`); aquí se toma el año más reciente y se pasa a ancho.
DELITOS <- c(
  n_hurtos     = "hurtos_personas",
  n_homicidios = "homicidios",
  n_violencia  = "violencia_intrafamiliar",
  n_sexuales   = "delitos_sexuales"
)
ANIO_DELITOS <- 2025

.hoja_delitos <- function(prov, archivo) {
  policia <- leer_derivado("seguridad_policia")
  policia <- policia[policia$anio == ANIO_DELITOS, , drop = FALSE]
  col_total <- col_req(policia, paste0("total_", ANIO_DELITOS))

  conteos <- purrr::reduce(names(DELITOS), function(acumulado, nombre) {
    filas <- policia[policia$delito == DELITOS[[nombre]], , drop = FALSE]
    d <- data.frame(
      ind_mpio = as.integer(a_numero(filas[[col_req(filas, "ind_mpio")]])),
      valor    = a_numero(filas[[col_total]])
    )
    names(d)[2] <- nombre
    if (is.null(acumulado)) d else dplyr::full_join(acumulado, d, by = "ind_mpio")
  }, .init = NULL)

  columnas <- c(names(DELITOS), "pob")
  universo <- conteos |>
    dplyr::inner_join(.poblacion_2025(), by = "ind_mpio") |>
    con_territorio() |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "id_provincia", "subregion_full", dplyr::all_of(columnas))

  detalle <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas))

  subreg_dom <- subregion_dominante(prov)

  # Se agregan los CONTEOS y la población; la tasa se calcula después, así que
  # municipios y agregados usan la misma fórmula.
  tabla <- agregar_totales(detalle, universo = universo, prov = prov,
                           columnas = columnas, como = "suma") |>
    .rotular_agregados(prov, subreg_dom) |>
    dplyr::mutate(
      hurtos                  = .data$n_hurtos     / .data$pob * 1e5,
      homicidios              = .data$n_homicidios / .data$pob * 1e5,
      violencia_intrafamiliar = .data$n_violencia  / .data$pob * 1e5,
      delitos_sexuales        = .data$n_sexuales   / .data$pob * 1e5
    ) |>
    .ordenar_filas(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "hurtos", "homicidios",
                  "violencia_intrafamiliar", "delitos_sexuales", "pob", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"pob", -"tipo_fila"), archivo, "delitos",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      hurtos                  = "Hurtos por 100.000 hab.",
      homicidios              = "Homicidios por 100.000 hab.",
      violencia_intrafamiliar = "Violencia intrafamiliar por 100.000 hab.",
      delitos_sexuales        = "Delitos sexuales por 100.000 hab."
    ),
    formatos = c(hurtos = "#,##0.0", homicidios = "#,##0.0",
                 violencia_intrafamiliar = "#,##0.0", delitos_sexuales = "#,##0.0")
  )

  tabla
}

# --- Bloque 4: hechos victimizantes del conflicto armado ----------------------
# Dos hojas del mismo insumo: el agregado por municipio (suma de todos los
# hechos) y la composición provincial por hecho. Las cifras son
# VICTIMIZACIONES, no personas: una misma persona puede aparecer en más de un
# hecho, así que las sumas por municipio no se leen como conteo de víctimas.

.hojas_victimas <- function(prov, archivo) {
  bruto <- leer_excel(entrada("curados", "HECHOSVICTIM_PROVINCIAS.xlsx"), hoja = "hechos victim")
  valores <- .columnas_de_valor(
    bruto, c("Código DANE", "Municipio", "subreg", "prov", "Tipo de fila",
             "Hecho victimizante")
  )
  if (length(valores) < 5) {
    stop("HECHOSVICTIM_PROVINCIAS.xlsx no trae las 5 columnas de conteo esperadas.",
         call. = FALSE)
  }
  columnas <- c("victimas_ocurrencia", "victimas_declaracion", "victimas_ubicacion",
                "sujetos_atencion", "eventos")

  # `prov` es también el nombre de una columna del archivo: dentro de filter()
  # la máscara de datos gana, así que el valor buscado se saca antes.
  nombre_provincia <- prov$nombre_datos

  datos <- bruto |>
    dplyr::filter(.data[[col_req(bruto, "prov")]] == nombre_provincia) |>
    dplyr::transmute(
      ind_mpio             = as.integer(a_numero(.data[[col_req(bruto, "Código DANE", "cod_dane")]])),
      hecho_victim         = as.character(.data[[col_req(bruto, "Hecho victimizante")]]),
      victimas_ocurrencia  = a_numero(.data[[valores[1]]]),
      victimas_declaracion = a_numero(.data[[valores[2]]]),
      victimas_ubicacion   = a_numero(.data[[valores[3]]]),
      sujetos_atencion     = a_numero(.data[[valores[4]]]),
      eventos              = a_numero(.data[[valores[5]]])
    ) |>
    con_territorio()

  # -- Hoja "total_victimas": agregado por municipio + total provincial --------
  por_municipio <- datos |>
    dplyr::group_by(.data$ind_mpio, .data$municipio, .data$subregion, .data$provincia) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(columnas), ~ sum(.x, na.rm = TRUE)),
                     .groups = "drop") |>
    dplyr::arrange(.data$municipio)

  total_victimas <- agregar_totales(
    por_municipio, universo = NULL, prov = prov, columnas = columnas, como = "suma"
  ) |>
    dplyr::mutate(
      provincia = ifelse(.data$tipo_fila == "Total provincia", prov$nombre_datos, .data$provincia),
      subregion = ifelse(.data$tipo_fila == "Total provincia", NA_character_, .data$subregion)
    ) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(total_victimas, -"tipo_fila"), archivo, "total_victimas",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      victimas_ocurrencia  = "Víctimas por ocurrencia",
      victimas_declaracion = "Víctimas por declaración",
      victimas_ubicacion   = "Víctimas por ubicación",
      sujetos_atencion     = "Sujetos de atención",
      eventos              = "Eventos"
    ),
    formatos = stats::setNames(rep("#,##0", length(columnas)), columnas)
  )

  # -- Hoja "proporcion_hechos": composición por hecho -------------------------
  por_hecho <- datos |>
    dplyr::group_by(.data$hecho_victim) |>
    dplyr::summarise(victimas_ocurrencia = sum(.data$victimas_ocurrencia, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::arrange(dplyr::desc(.data$victimas_ocurrencia))

  total_ocurrencia <- sum(por_hecho$victimas_ocurrencia, na.rm = TRUE)

  proporcion_hechos <- por_hecho |>
    dplyr::mutate(proporcion_pct = .data$victimas_ocurrencia / total_ocurrencia,
                  tipo_fila = "Hecho") |>
    dplyr::bind_rows(data.frame(
      hecho_victim        = paste0("TOTAL PROVINCIA ", toupper(prov$etiqueta)),
      victimas_ocurrencia = total_ocurrencia,
      proporcion_pct      = 1,
      tipo_fila           = "Total provincia",
      stringsAsFactors    = FALSE
    ))

  escribir_hoja(
    dplyr::select(proporcion_hechos, -"tipo_fila"), archivo, "proporcion_hechos",
    etiquetas = c(
      hecho_victim        = "Hecho victimizante",
      victimas_ocurrencia = "Víctimas por ocurrencia",
      proporcion_pct      = "Proporción sobre el total (%)"
    ),
    formatos = c(victimas_ocurrencia = "#,##0", proporcion_pct = "0.0%")
  )

  list(total_victimas = total_victimas, proporcion_hechos = proporcion_hechos)
}

# --- Bloque 5: restitución de tierras (SRTDAF) --------------------------------
# Dos hojas del mismo insumo: los conteos (solicitudes, predios, titulares) y
# la tasa de solicitudes por 1.000 habitantes. Las columnas `prov` y `subreg`
# del archivo vienen corruptas (un solo valor para todo), así que el territorio
# sale siempre del crosswalk.

.hojas_srtdaf <- function(prov, archivo) {
  bruto <- leer_excel(entrada("curados", "SRDAFT_PROVINCIAS.xlsx"), hoja = "SRTDAF")
  columnas <- c("n_solicitudes", "n_predios", "n_titulares")

  universo <- bruto |>
    dplyr::transmute(
      ind_mpio      = as.integer(a_numero(.data[[col_req(bruto, "CodigoDANE", "ind_mpio")]])),
      n_solicitudes = a_numero(.data[[col_req(bruto, "NumeroDeSolicitudes")]]),
      n_predios     = a_numero(.data[[col_req(bruto, "NumeroDePredios")]]),
      n_titulares   = a_numero(.data[[col_req(bruto, "NumeroDeTitulares")]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    dplyr::left_join(.poblacion_2025(), by = "ind_mpio")

  detalle <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "pob")

  subreg_dom <- subregion_dominante(prov)

  completa <- agregar_totales(
    detalle, universo = universo, prov = prov,
    columnas = c(columnas, "pob"), como = "suma"
  ) |>
    .rotular_agregados(prov, subreg_dom) |>
    .ordenar_filas(.data$municipio)

  # -- Hoja "srtdaf": conteos ---------------------------------------------------
  srtdaf <- dplyr::select(completa, "ind_mpio", "municipio", "subregion",
                          "provincia", dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(srtdaf, -"tipo_fila"), archivo, "srtdaf",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      n_solicitudes = "Número de solicitudes",
      n_predios     = "Número de predios",
      n_titulares   = "Número de titulares"
    ),
    formatos = c(n_solicitudes = "#,##0", n_predios = "#,##0", n_titulares = "#,##0")
  )

  # -- Hoja "tasas": solicitudes por 1.000 habitantes ---------------------------
  # Tasa agregada en las filas de provincia, subregión y departamento
  # (Σ solicitudes / Σ población × 1.000).
  tasas <- completa |>
    dplyr::mutate(
      tasa_solicitudes = ifelse(.data$pob > 0, .data$n_solicitudes / .data$pob * 1000, NA_real_)
    ) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "n_solicitudes", "pob", "tasa_solicitudes", "tipo_fila")

  escribir_hoja(
    dplyr::select(tasas, -"tipo_fila"), archivo, "tasas",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      n_solicitudes    = "Número de solicitudes",
      pob              = "Población (2025)",
      tasa_solicitudes = "Tasa de solicitudes (por 1.000 hab.)"
    ),
    formatos = c(n_solicitudes = "#,##0", pob = "#,##0", tasa_solicitudes = "#,##0.00")
  )

  list(srtdaf = srtdaf, tasas = tasas)
}

# --- Bloque 6: percepción ciudadana de seguridad ------------------------------
# La encuesta es representativa a nivel de SUBREGIÓN, no de provincia: la
# unidad de análisis es la subregión mayoritaria de la provincia y así debe
# leerse en el informe. Cuatro preguntas, una hoja cada una, con la proporción
# PONDERADA de cada categoría por periodo (las dos olas de 2019 van separadas).

PREGUNTAS_PERCEPCION <- list(
  list(hoja = "P1A_barrio",          variable = "P1A", codigos = c(1, 2, 3, 4),
       nombres = c("muy_seguro", "seguro", "inseguro", "muy_inseguro")),
  list(hoja = "P2_cambio_barrio",    variable = "P2",  codigos = c(1, 2, 3, 999),
       nombres = c("mas_seguro", "menos_seguro", "igual", "ns_nr")),
  list(hoja = "P4A_municipio",       variable = "P4A", codigos = c(1, 2, 3, 4),
       nombres = c("muy_seguro", "seguro", "inseguro", "muy_inseguro")),
  list(hoja = "P6_cambio_municipio", variable = "P6",  codigos = c(1, 2, 3, 999),
       nombres = c("mas_seguro", "menos_seguro", "igual", "ns_nr"))
)

ETIQUETAS_PERCEPCION <- c(
  subregion    = "Subregión",
  periodo      = "Periodo",
  n_resp       = "N respuestas",
  muy_seguro   = "Muy seguro (%)",
  seguro       = "Seguro (%)",
  inseguro     = "Inseguro (%)",
  muy_inseguro = "Muy inseguro (%)",
  mas_seguro   = "Más seguro (%)",
  menos_seguro = "Menos seguro (%)",
  igual        = "Igual (%)",
  ns_nr        = "No sabe/No responde (%)"
)

.hojas_percepcion <- function(prov, archivo) {
  if (!existe_derivado("percepcion_seguridad")) {
    message("  [aviso] Falta el derivado percepcion_seguridad: se omite el ",
            "bloque de percepción de seguridad (4 hojas).")
    return(NULL)
  }

  subreg_dom <- subregion_dominante(prov)
  codigo_subregion <- SUBREGION_ENCUESTA[[subreg_dom]]
  if (is.null(codigo_subregion)) {
    message("  [aviso] La subregión '", subreg_dom, "' no tiene código en la ",
            "encuesta de percepción: se omite el bloque (4 hojas).")
    return(NULL)
  }

  encuesta <- leer_derivado("percepcion_seguridad") |>
    dplyr::mutate(
      B_SUBREGION        = a_numero(.data$B_SUBREGION),
      FACTOR_PONDERACION = a_numero(.data$FACTOR_PONDERACION),
      fecha              = as.Date(as.character(.data$FECHAINI), format = "%d/%m/%Y"),
      anio               = as.integer(format(.data$fecha, "%Y"))
    ) |>
    dplyr::filter(.data$B_SUBREGION == codigo_subregion)

  if (nrow(encuesta) == 0) {
    message("  [aviso] La encuesta de percepción no trae registros de la ",
            "subregión ", subreg_dom, ": se omite el bloque (4 hojas).")
    return(NULL)
  }

  # Periodo = año, y el número de ola cuando hay más de un estudio en el año.
  periodos <- encuesta |>
    dplyr::group_by(.data$ESTUDIO) |>
    dplyr::summarise(fecha = min(.data$fecha, na.rm = TRUE),
                     anio = dplyr::first(.data$anio), .groups = "drop") |>
    dplyr::group_by(.data$anio) |>
    dplyr::arrange(.data$fecha, .by_group = TRUE) |>
    # `ola` y `n_ola` se materializan como columnas: ifelse() devuelve un
    # resultado del largo de su condición, así que dplyr::n() dentro del
    # ifelse colapsaría el año de dos olas a una sola etiqueta.
    dplyr::mutate(ola = dplyr::row_number(), n_ola = dplyr::n()) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      periodo = paste0(.data$anio,
                       ifelse(.data$n_ola > 1, paste0(" (", .data$ola, ")"), ""))
    ) |>
    dplyr::select("ESTUDIO", "periodo", "anio")

  encuesta <- dplyr::left_join(
    dplyr::select(encuesta, -"anio"), periodos, by = "ESTUDIO"
  )

  purrr::map(PREGUNTAS_PERCEPCION, function(p) {
    d <- encuesta |>
      dplyr::mutate(respuesta = a_numero(.data[[p$variable]])) |>
      dplyr::filter(.data$respuesta %in% p$codigos)

    if (nrow(d) == 0) {
      message("  [aviso] Sin respuestas válidas en ", p$variable,
              ": se omite la hoja ", p$hoja, ".")
      return(NULL)
    }

    tabla <- d |>
      dplyr::group_by(.data$periodo, .data$anio) |>
      dplyr::mutate(n_resp = dplyr::n(), peso_total = sum(.data$FACTOR_PONDERACION, na.rm = TRUE)) |>
      dplyr::group_by(.data$periodo, .data$anio, .data$n_resp, .data$respuesta) |>
      dplyr::summarise(prop = sum(.data$FACTOR_PONDERACION, na.rm = TRUE) / dplyr::first(.data$peso_total),
                       .groups = "drop") |>
      # Una categoría sin respuestas en un periodo es un 0 real, no un vacío.
      tidyr::complete(tidyr::nesting(periodo, anio, n_resp),
                      respuesta = p$codigos, fill = list(prop = 0)) |>
      dplyr::mutate(categoria = p$nombres[match(.data$respuesta, p$codigos)]) |>
      dplyr::select(-"respuesta") |>
      tidyr::pivot_wider(names_from = "categoria", values_from = "prop") |>
      dplyr::mutate(subregion = subreg_dom) |>
      dplyr::arrange(.data$anio, .data$periodo) |>
      dplyr::select("subregion", "periodo", "n_resp", dplyr::all_of(p$nombres), "anio")

    escribir_hoja(
      dplyr::select(tabla, -"anio"), archivo, p$hoja,
      etiquetas = ETIQUETAS_PERCEPCION,
      formatos = c(stats::setNames(rep("0.0%", length(p$nombres)), p$nombres),
                   n_resp = "#,##0")
    )
    tabla
  }) |>
    stats::setNames(vapply(PREGUNTAS_PERCEPCION, function(p) p$hoja, character(1)))
}

# --- Bloque 7: índice de riesgo de victimización (IRV) ------------------------
# Sin fila de agregado: el índice no se promedia de forma estándar y la
# categoría de riesgo es cualitativa.

.hoja_irv <- function(prov, archivo) {
  bruto <- leer_excel(entrada("IRV-2025.xlsx"), hoja = "Datos")
  # "Código Municipio" es la séptima columna; se toma por posición para no
  # depender del acento del encabezado.
  c_cod <- if (ncol(bruto) >= 7) names(bruto)[7] else col_req(bruto, "Código Municipio")

  tabla <- bruto |>
    dplyr::transmute(
      ind_mpio         = as.integer(a_numero(.data[[c_cod]])),
      irv              = a_numero(.data[[col_req(bruto, "Estimado")]]),
      categoria_riesgo = as.character(.data[[col_req(bruto, "Cluster")]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$municipio) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "irv", "categoria_riesgo")

  escribir_hoja(
    tabla, archivo, "irv",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      irv              = "Índice de Riesgo de Victimización",
      categoria_riesgo = "Categoría de riesgo"
    ),
    formatos = c(irv = "0.0000")
  )

  tabla
}

# --- Bloque 8: personas dadas por desaparecidas (UBPD) ------------------------
# Conteo por municipio y participación dentro del total provincial. El archivo
# trae filas sin código DANE (NO DETERMINADO, SIN INFORMACIÓN y el total
# departamental) que se descartan.

.hoja_desaparecidos <- function(prov, archivo) {
  bruto <- leer_excel(entrada("UBPD_desaparecidos_Antioquia.xlsx"),
                      hoja = "Por Municipio", saltar = 1)

  detalle <- bruto |>
    dplyr::transmute(
      ind_mpio      = as.integer(a_numero(.data[[col_req(bruto, "Cód. DANE", "CódDANE", "cod_dane")]])),
      desaparecidos = a_numero(.data[[col_req(bruto, "Personas Desaparecidas")]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(dplyr::desc(.data$desaparecidos)) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "desaparecidos")

  total_provincia <- sum(detalle$desaparecidos, na.rm = TRUE)

  tabla <- agregar_totales(detalle, universo = NULL, prov = prov,
                           columnas = "desaparecidos", como = "suma") |>
    dplyr::mutate(
      provincia = ifelse(.data$tipo_fila == "Total provincia", prov$nombre_datos, .data$provincia),
      subregion = ifelse(.data$tipo_fila == "Total provincia", NA_character_, .data$subregion),
      prop_desaparecidos = .data$desaparecidos / total_provincia
    ) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "desaparecidos", "prop_desaparecidos", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "desaparecidos",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      desaparecidos      = "Personas dadas por desaparecidas",
      prop_desaparecidos = "Proporción dentro de la provincia"
    ),
    formatos = c(desaparecidos = "#,##0", prop_desaparecidos = "0.0%")
  )

  tabla
}

# --- Orquestador de la sección ------------------------------------------------

tabla_seguridad <- function(prov) {
  message("== 10 Seguridad — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "10_Seguridad"), "seguridad.xlsx")
  # El .do borraba el archivo previo para no dejar hojas obsoletas.
  if (file.exists(archivo)) unlink(archivo)

  hojas <- list()
  hojas$coca          <- .hoja_coca(prov, archivo)
  hojas$evoa          <- .hoja_evoa(prov, archivo)
  hojas$delitos       <- .hoja_delitos(prov, archivo)
  hojas <- c(hojas, .hojas_victimas(prov, archivo))
  hojas <- c(hojas, .hojas_srtdaf(prov, archivo))
  percepcion <- .hojas_percepcion(prov, archivo)
  if (!is.null(percepcion)) hojas <- c(hojas, percepcion)
  hojas$irv           <- .hoja_irv(prov, archivo)
  hojas$desaparecidos <- .hoja_desaparecidos(prov, archivo)

  hojas$archivo <- archivo
  invisible(hojas)
}
