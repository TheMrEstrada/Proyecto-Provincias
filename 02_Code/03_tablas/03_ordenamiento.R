# =============================================================================
# 03_ordenamiento.R — Sección 3: Ordenamiento del territorio
#
# TABLAS (hojas del .xlsx de la sección, en el orden en que las escribe el .do):
#   deficit_vivienda    déficit cuantitativo y cualitativo de vivienda (2023)
#   servicios_publicos  coberturas ECV 2023 de los seis servicios domiciliarios
#   vias_area           km de vía primaria/secundaria/terciaria por km²
#   vias_habitantes     km de vía primaria/secundaria/terciaria por 1.000 hab.
#   catastro            avalúo catastral urbano/rural y estado del catastro
#   imca                Índice Municipal de Competitividad de Antioquia 2022
#   gobierno_digital    Índice de Gobierno Digital 2024 y componentes FURAG
#   tti_edsup           tasa de tránsito inmediato a la educación superior
#   internet_2025       líneas de internet fijo y fibra óptica (MinTIC 2025)
#   uso_suelo_rural     % de predios rurales con uso adecuado del suelo (POTA)
#
# INPUTS (01_Data/00_Inputs — crudos):
#   deficit cuantitativo por municipio 2023.xlsx
#   deficit cualitativo por municipio 2023.xlsx
#   poblacion_anual.dta (01_Derived)  (pesos poblacionales 2022, 2024 y 2025)
#   AREA_ORIGINAL.xlsx  (hoja "Area")
#   CATASTRO.xlsx       (hoja "Consolidado Urb + Rural")
# INPUTS (01_Data/01_Derived — derivados):
#   ECV_nbi_pobreza.dta, ECV_oficial_agregados.dta,
#   infraestructura_municipios_dicc.dta, imca_2022.dta,
#   indice_gobierno_digital_2024.dta, 20250506 EDUCACION.xlsx,
#   infraestructura_internet_2025.dta, poblacion_total_2025.dta,
#   uso_del_suelo_pota.xlsx, ESTADO_CATASTRO.xlsx
#   + crosswalks territoriales
#
#   OJO: ESTADO_CATASTRO.xlsx y indice_gobierno_digital_2024.dta viven en
#   01_Derived pero NINGÚN script del pipeline los produce: se arman a mano en
#   Excel a partir del inventario de actualizaciones catastrales y de
#   Indice_gobierno_digital_2024.xlsx. Se leen con derivado() igual que el resto,
#   pero no se regeneran con run_all.R.
#
# OUTPUTS: 03_Outputs/<Provincia>/03_Ordenamiento/ordenamiento.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/03_Ordenamiento.do
#
# NOTAS METODOLÓGICAS (vienen del .do y se respetan tal cual):
#   - Déficit de vivienda: los agregados son TASA AGREGADA
#     (Σ viviendas con déficit / Σ viviendas), no promedio de tasas.
#   - Servicios públicos: el detalle municipal sale de ECV_nbi_pobreza (0-100,
#     se pasa a fracción) y los agregados del valor OFICIAL de
#     ECV_oficial_agregados (ya en fracción). Por eso cada indicador se exporta
#     partido en dos columnas, `_mun` (municipal) y `_ofi` (agregado): son dos
#     fuentes distintas y mezclarlas en una sola columna las haría parecer
#     comparables. Solo 6 de las 11 provincias tienen fila oficial; en las otras
#     5 la provincia se calcula como promedio ponderado por población.
#   - Vías: el agregado de IDV (km/km²) se pondera por ÁREA y el de VPC
#     (km/1.000 hab) por POBLACIÓN.
#   - IMCA y Gobierno Digital son índices 0-100: NO se pasan a fracción. Sus
#     agregados provinciales son promedios PONDERADOS por población (2022 y 2024
#     respectivamente); el informe publicado usó promedio simple.
#   - Uso del suelo rural: SIN agregados. La fuente POTA cubre 88 de los 125
#     municipios y la ausencia no es aleatoria; un promedio del subconjunto con
#     dato se leería como el valor del territorio.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Insumos y utilidades compartidas por varios bloques ---------------------

.cache_ordenamiento <- new.env(parent = emptyenv())

#' Población total municipal de un año, para todos los municipios del
#' departamento. Es el peso de todos los promedios ponderados de la sección.
#' El derivado se lee una sola vez por sesión (la usan cuatro bloques).
#'
#' Prefiere poblacion_anual (serie PPED) a POBLACION MUNICIPAL.xlsx: esa es
#' la serie que 02_demografia.R declara descartada porque no reproduce el
#' Anexo 1 (Yarumal 44.770 vs. 41.884 publicados). Hallazgo de Pablo
#' (F-2-018-b), adoptado también aquí.
#'
#' poblacion_anual se arma con el insumo PPED, que pesa 131 MB, no está
#' versionado y no cabe en este entorno (ver poblacion_municipal.R). Si
#' nadie lo ha generado todavía, se cae a POBLACION MUNICIPAL.xlsx —con el
#' mismo aviso que ya usa 02_demografia.R— para que el pipeline pueda
#' correr hoy. En cuanto alguien corra poblacion_municipal.R con el insumo
#' disponible, esta función empieza a usar la serie correcta sin que haga
#' falta tocar nada más.
.poblacion_peso <- function(anio_pedido) {
  if (is.null(.cache_ordenamiento$pob)) {
    if (existe_derivado("poblacion_anual")) {
      d <- leer_derivado("poblacion_anual")
      c_cod  <- col_req(d, "ind_mpio")
      c_ano  <- col_req(d, "anio")
      c_area <- col_req(d, "area_geo")
      c_pob  <- col_req(d, "Total")
    } else {
      warning("No está el derivado poblacion_anual; se usa ",
              "POBLACION MUNICIPAL.xlsx, cuya serie NO reproduce el Anexo 1 ",
              "(Yarumal 44.770 vs. 41.884 publicados).", call. = FALSE)
      d <- leer_excel(entrada("POBLACION MUNICIPAL.xlsx"), hoja = 1)
      c_cod  <- col_req(d, "DPMP")
      c_ano  <- col_req(d, "AÑO")
      c_area <- col_req(d, "ÁREA GEOGRÁFICA")
      c_pob  <- col_req(d, "Total General")
    }
    .cache_ordenamiento$pob <- d |>
      dplyr::filter(.data[[c_area]] == "Total") |>
      dplyr::transmute(
        anio     = a_numero(.data[[c_ano]]),
        ind_mpio = as.integer(a_numero(.data[[c_cod]])),
        pob_peso = a_numero(.data[[c_pob]])
      ) |>
      dplyr::filter(!is.na(.data$ind_mpio))
  }
  d <- .cache_ordenamiento$pob |>
    dplyr::filter(.data$anio == anio_pedido) |>
    dplyr::select("ind_mpio", "pob_peso")
  if (nrow(d) == 0) {
    anios <- sort(unique(.cache_ordenamiento$pob$anio))
    stop("No hay población de ", anio_pedido, " en el derivado poblacion_anual; ",
         "el PPED cubre ", min(anios), "-", max(anios), ".", call. = FALSE)
  }
  d
}

#' Sustituye las etiquetas genéricas que pone agregar_totales() por las del .do,
#' que declaran el método de agregación en el propio nombre de la fila.
#' @param etiquetas vector nombrado tipo_fila -> texto de la fila.
.etiquetar_agregados <- function(datos, etiquetas) {
  i <- match(datos$tipo_fila, names(etiquetas))
  dplyr::mutate(datos, municipio = ifelse(is.na(i), .data$municipio,
                                          unname(etiquetas[i])))
}

# Encabezados que comparten todas las hojas de la sección.
.ETIQ_TERRITORIO <- c(
  ind_mpio  = "Código DANE",
  municipio = "Municipio",
  subregion = "Subregión",
  provincia = "Provincia"
)

# =============================================================================
# BLOQUE 1 — Déficit de vivienda 2023 (3.5.1 del .do)
# =============================================================================
# Déficit municipal = Σ viviendas con déficit / Σ viviendas (urbana + rural).
# Provincia, subregión y departamento se calculan con la MISMA fórmula sobre la
# suma de sus municipios: es una tasa agregada, no el promedio de las tasas
# municipales (que daría más peso a los municipios pequeños).

.hoja_deficit_vivienda <- function(prov, archivo) {
  leer_deficit <- function(ruta, col_viviendas, nombres) {
    d <- leer_excel(ruta, saltar = 1)
    c_cod  <- col_req(d, "Cod_mpio")
    c_zona <- col_req(d, "zona")
    c_viv  <- col_req(d, col_viviendas)
    c_def  <- col_req(d, "viviendas_con_deficit")
    d |>
      # El insumo trae filas mal formadas (totales y encabezados repetidos);
      # las válidas son exactamente las de zona urbana o rural.
      dplyr::filter(.data[[c_zona]] %in% c("Urbana", "Rural")) |>
      dplyr::transmute(
        ind_mpio = as.integer(a_numero(.data[[c_cod]])),
        viviendas = a_numero(.data[[c_viv]]),
        con_deficit = a_numero(.data[[c_def]])
      ) |>
      dplyr::filter(!is.na(.data$ind_mpio)) |>
      dplyr::group_by(.data$ind_mpio) |>
      dplyr::summarise(dplyr::across(dplyr::everything(), \(x) sum(x, na.rm = TRUE)),
                       .groups = "drop") |>
      stats::setNames(c("ind_mpio", nombres))
  }

  cuanti <- leer_deficit(entrada("deficit cuantitativo por municipio 2023.xlsx"),
                         "Total viviendas", c("viv_cuanti", "vdef_cuanti"))
  cuali  <- leer_deficit(entrada("deficit cualitativo por municipio 2023.xlsx"),
                         "Total de viviendas", c("viv_cuali", "vdef_cuali"))

  universo <- dplyr::full_join(cuali, cuanti, by = "ind_mpio") |>
    con_territorio()

  columnas <- c("vdef_cuanti", "viv_cuanti", "vdef_cuali", "viv_cuali")

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas))

  # Se suman los conteos y las tasas se recalculan al final: así la fila de
  # municipio y la de agregado salen de la misma fórmula.
  tabla <- agregar_totales(municipios, universo = universo, prov = prov,
                           columnas = columnas, como = "suma") |>
    dplyr::mutate(
      deficit_cuanti = .data$vdef_cuanti / .data$viv_cuanti,
      deficit_cuali  = .data$vdef_cuali / .data$viv_cuali
    ) |>
    .etiquetar_agregados(c(
      "Total provincia"   = paste0("PROVINCIA ", toupper(prov$etiqueta),
                                   " (tasa agregada: Σ viviendas con déficit / Σ viviendas)"),
      "Total subregión"   = paste0("SUBREGIÓN ", subregion_dominante(prov), " (tasa agregada)"),
      "Total departamento" = "DEPARTAMENTO (ANTIOQUIA) (tasa agregada)"
    )) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "deficit_cuanti", "deficit_cuali", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "deficit_vivienda",
    etiquetas = c(.ETIQ_TERRITORIO,
                  deficit_cuanti = "Déficit cuantitativo de vivienda",
                  deficit_cuali  = "Déficit cualitativo de vivienda"),
    formatos = c(deficit_cuanti = "0.0%", deficit_cuali = "0.0%")
  )

  tabla
}

# =============================================================================
# BLOQUE 2 — Acceso a servicios públicos, ECV 2023 (3.5.2 del .do)
# =============================================================================
# Municipios: cobertura de la ECV municipal (llega 0-100 -> fracción).
# Agregados: valor OFICIAL de la ECV para subregión, departamento y las seis
# provincias que tienen fila propia; en las otras cinco, promedio ponderado por
# población 2025 de sus municipios. Municipal y agregado NO son la misma serie,
# por eso van en columnas separadas (_mun / _ofi).

.SERVICIOS <- c(
  tot_pob_energia             = "Cobertura de energía",
  tot_pob_acueducto           = "Cobertura de acueducto",
  tot_pob_alcantarillado      = "Cobertura de alcantarillado",
  tot_pob_recoleccion_basuras = "Cobertura de recolección de basuras",
  tot_pob_internet            = "Cobertura de internet",
  tot_pob_gas_natural         = "Cobertura de gas natural"
)

.hoja_servicios_publicos <- function(prov, archivo) {
  svars <- names(.SERVICIOS)

  ecv <- leer_derivado("ECV_nbi_pobreza") |>
    dplyr::select("ind_mpio", dplyr::all_of(svars)) |>
    dplyr::mutate(
      ind_mpio = as.integer(.data$ind_mpio),
      # La ECV municipal viene en 0-100; los agregados oficiales ya en fracción.
      dplyr::across(dplyr::all_of(svars), \(x) as.numeric(x) / 100)
    ) |>
    dplyr::left_join(.poblacion_peso(2025), by = "ind_mpio") |>
    con_territorio()

  municipios <- ecv |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "pob_peso",
                  dplyr::all_of(svars))

  # Fila provincial de respaldo: promedio ponderado por población.
  fallback <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = svars,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(svars))), svars),
    pesos = "pob_peso"
  ) |>
    dplyr::filter(.data$tipo_fila == "Total provincia")

  oficial <- leer_derivado("ECV_oficial_agregados")
  fila_oficial <- function(nivel, clave, etiqueta, tipo) {
    d <- dplyr::filter(oficial, .data$nivel == !!nivel, .data$key == !!clave)
    if (nrow(d) == 0) return(NULL)
    d |>
      dplyr::select(dplyr::all_of(svars)) |>
      dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric),
                    ind_mpio = NA_integer_, municipio = etiqueta, tipo_fila = tipo)
  }

  subreg <- subregion_dominante(prov)
  f_prov <- fila_oficial("PROVINCIA", as.character(prov$id),
                         paste0("PROVINCIA ", toupper(prov$etiqueta), " (ECV oficial)"),
                         "Provincia")
  if (is.null(f_prov)) {
    f_prov <- fallback |>
      dplyr::mutate(municipio = paste0("PROVINCIA ", toupper(prov$etiqueta),
                                       " (promedio ponderado; sin ECV oficial)"),
                    tipo_fila = "Provincia") |>
      dplyr::select(dplyr::all_of(svars), "ind_mpio", "municipio", "tipo_fila")
  }

  tabla <- dplyr::bind_rows(
    dplyr::mutate(dplyr::select(municipios, -"pob_peso"), tipo_fila = "Municipio"),
    f_prov,
    fila_oficial("SUBREGION", subreg, paste0("SUBREGIÓN ", subreg, " (ECV oficial)"), "Subregión"),
    fila_oficial("DEPARTAMENTO", "ANTIOQUIA",
                 "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)", "Departamento")
  )

  # Partición municipal / agregado: la misma cobertura, pero de dos fuentes.
  for (v in svars) {
    tabla[[paste0(v, "_mun")]] <- ifelse(tabla$tipo_fila == "Municipio", tabla[[v]], NA_real_)
    tabla[[paste0(v, "_ofi")]] <- ifelse(tabla$tipo_fila != "Municipio", tabla[[v]], NA_real_)
  }
  tabla <- dplyr::select(tabla, -dplyr::all_of(svars))

  columnas_par <- as.vector(rbind(paste0(svars, "_mun"), paste0(svars, "_ofi")))
  tabla <- dplyr::select(tabla, "ind_mpio", "municipio", "subregion", "provincia",
                         dplyr::all_of(columnas_par), "tipo_fila")

  etiquetas <- c(.ETIQ_TERRITORIO,
                 stats::setNames(paste0(.SERVICIOS, " (municipal)"), paste0(svars, "_mun")),
                 stats::setNames(paste0(.SERVICIOS, " (agregado)"), paste0(svars, "_ofi")))

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "servicios_publicos",
    etiquetas = etiquetas,
    formatos  = stats::setNames(rep("0.0%", length(columnas_par)), columnas_par)
  )

  tabla
}

# =============================================================================
# BLOQUE 3 — Kilómetros de vía (3.3 del .do)
# =============================================================================
# Dos hojas de la misma fuente: IDV_* son km de vía por km² del municipio y
# VPC_* km de vía por cada 1.000 habitantes. El agregado provincial de cada una
# se pondera por su propio denominador (área y población), que es lo mismo que
# Σ km / Σ área y Σ km / Σ población.

.vias_provincia <- function(prov) {
  area <- leer_excel(entrada("AREA_ORIGINAL.xlsx"), hoja = "Area")
  c_cod  <- col_req(area, "COD_MPIO", "ind_mpio")
  c_area <- col_req(area, "AREA KM2", "AREAKM2", "area_km2")
  area <- area |>
    dplyr::transmute(ind_mpio = as.integer(a_numero(.data[[c_cod]])),
                     area_km2 = a_numero(.data[[c_area]])) |>
    dplyr::filter(!is.na(.data$ind_mpio))

  vias <- haven::read_dta(entrada("curados", "infraestructura_municipios_dicc.dta"))
  # El derivado trae TODAS las columnas como texto, incluido el código DANE.
  vias |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data$ind_mpio)),
      idv_pri = a_numero(.data$IDV_pri), idv_sec = a_numero(.data$IDV_sec),
      idv_ter = a_numero(.data$IDV_ter),
      vpc_pri = a_numero(.data$VPC_pri), vpc_sec = a_numero(.data$VPC_sec),
      vpc_ter = a_numero(.data$VPC_ter)
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(area, by = "ind_mpio") |>
    dplyr::left_join(.poblacion_peso(2025), by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label)
}

.hoja_vias <- function(prov, archivo, base, prefijo, peso, hoja, sufijo_fila,
                       etiquetas_valor) {
  columnas <- paste0(prefijo, c("_pri", "_sec", "_ter"))

  municipios <- dplyr::select(base, "ind_mpio", "municipio", "subregion", "provincia",
                              dplyr::all_of(peso), dplyr::all_of(columnas))

  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = peso
  ) |>
    .etiquetar_agregados(stats::setNames(
      paste0("PROMEDIO PONDERADO PROVINCIA ", toupper(prov$etiqueta), " ", sufijo_fila),
      "Total provincia"
    )) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, hoja,
    etiquetas = c(.ETIQ_TERRITORIO, stats::setNames(etiquetas_valor, columnas)),
    formatos  = stats::setNames(rep("0.000", length(columnas)), columnas)
  )

  tabla
}

# =============================================================================
# BLOQUE 4 — Caracterización del catastro municipal (3.1 del .do)
# =============================================================================
# Dos fuentes: CATASTRO.xlsx aporta los avalúos (se leen POR POSICIÓN: C = código
# DANE, M = avalúo urbano, V = avalúo rural, W = avalúo total; el archivo trae
# encabezados repetidos por vigencia y no se puede seleccionar por nombre) y
# ESTADO_CATASTRO.xlsx el estado del catastro, que es categórico y por eso NO
# tiene fila agregada. Ninguna de las dos cubre 10 municipios de la PAP
# (provincia 5: Marinilla y San Vicente Ferrer; provincia 11 completa).

.hoja_catastro <- function(prov, archivo) {
  # Ambos archivos se leen sin encabezado desde la fila 2, igual que el .do
  # (cellrange(A2) sin firstrow), y las columnas se toman por posición.
  por_posicion <- function(ruta, hoja, posiciones, nombres) {
    d <- readxl::read_excel(ruta, sheet = hoja, skip = 1, col_names = FALSE,
                            .name_repair = "minimal") |>
      as.data.frame()
    stats::setNames(d[, posiciones, drop = FALSE], nombres)
  }

  estado <- por_posicion(entrada("curados", "ESTADO_CATASTRO.xlsx"), "Catastro_Full",
                         c(2, 4, 6),
                         c("ind_mpio", "estado_catastro_rural", "estado_catastro_urbano")) |>
    dplyr::mutate(ind_mpio = as.integer(a_numero(.data$ind_mpio))) |>
    dplyr::filter(!is.na(.data$ind_mpio))

  avaluos <- por_posicion(entrada("CATASTRO.xlsx"), "Consolidado Urb + Rural",
                          c(3, 13, 22, 23),
                          c("ind_mpio", "avaluo_urbano", "avaluo_rural", "avaluo_total")) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), a_numero),
                  ind_mpio = as.integer(.data$ind_mpio)) |>
    dplyr::filter(!is.na(.data$ind_mpio))

  columnas <- c("avaluo_total", "avaluo_urbano", "avaluo_rural")

  municipios <- avaluos |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(estado, by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas),
                  "estado_catastro_rural", "estado_catastro_urbano")

  tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                           columnas = columnas, como = "suma") |>
    dplyr::mutate(
      prop_avaluo_urbano = .data$avaluo_urbano / .data$avaluo_total,
      prop_avaluo_rural  = .data$avaluo_rural / .data$avaluo_total
    ) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "avaluo_total", "avaluo_urbano", "avaluo_rural",
                  "prop_avaluo_urbano", "prop_avaluo_rural",
                  "estado_catastro_rural", "estado_catastro_urbano", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "catastro",
    etiquetas = c(.ETIQ_TERRITORIO,
      avaluo_total       = "Avalúo catastral total ($)",
      avaluo_urbano      = "Avalúo catastral urbano ($)",
      avaluo_rural       = "Avalúo catastral rural ($)",
      prop_avaluo_urbano = "Proporción del avalúo catastral urbano sobre el total",
      prop_avaluo_rural  = "Proporción del avalúo catastral rural sobre el total",
      estado_catastro_rural  = "Estado del catastro rural",
      estado_catastro_urbano = "Estado del catastro urbano"),
    formatos = c(avaluo_total = "#,##0", avaluo_urbano = "#,##0",
                 avaluo_rural = "#,##0", prop_avaluo_urbano = "0.0%",
                 prop_avaluo_rural = "0.0%")
  )

  tabla
}

# =============================================================================
# BLOQUE 5 — IMCA 2022 (3.4 CTI del .do)
# =============================================================================
# El insumo trae los municipios ("05001") y, además, las filas oficiales de
# subregión ("SR01".."SR09"). El agregado provincial se calcula (promedio
# ponderado por población 2022) y el subregional se toma tal cual del insumo.
# IMCA es un índice 0-100: no se convierte a fracción.

.IMCA <- c(
  imca_total           = "IMCA total",
  imca_adop_tic        = "IMCA adopción TIC",
  imca_capacidades     = "IMCA capacidades",
  imca_dinam_neg       = "IMCA dinamismo de los negocios",
  imca_infraestructura = "IMCA infraestructura",
  imca_innovacion      = "IMCA innovación",
  imca_instituciones   = "IMCA instituciones",
  imca_merc_bienes     = "IMCA mercado de bienes",
  imca_merc_laboral    = "IMCA mercado laboral",
  imca_salud           = "IMCA salud",
  imca_sist_financiero = "IMCA sistema financiero",
  imca_tam_mercado     = "IMCA tamaño del mercado"
)

# Códigos de subregión tal como los rotula el insumo del IMCA.
.SUBREGION_SR <- c(
  SR01 = "VALLE DE ABURRA", SR02 = "BAJO CAUCA", SR03 = "MAGDALENA MEDIO",
  SR04 = "NORDESTE", SR05 = "NORTE", SR06 = "OCCIDENTE", SR07 = "ORIENTE",
  SR08 = "SUROESTE", SR09 = "URABA"
)

.hoja_imca <- function(prov, archivo) {
  columnas <- names(.IMCA)
  crudo <- leer_derivado("imca_2022")

  oficial_subregion <- crudo |>
    dplyr::filter(.data$ind_mpio %in% names(.SUBREGION_SR)) |>
    dplyr::mutate(subregion = unname(.SUBREGION_SR[.data$ind_mpio])) |>
    dplyr::select("subregion", dplyr::all_of(columnas))

  municipios <- crudo |>
    dplyr::transmute(ind_mpio = suppressWarnings(as.integer(.data$ind_mpio)),
                     dplyr::across(dplyr::all_of(columnas), as.numeric)) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(.poblacion_peso(2022), by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "pob_peso",
                  dplyr::all_of(columnas))

  # Una fila por subregión a la que pertenezca algún municipio de la provincia.
  filas_subregion <- data.frame(subregion = unique(municipios$subregion)) |>
    dplyr::inner_join(oficial_subregion, by = "subregion") |>
    dplyr::mutate(
      municipio = paste0("SUBREGIÓN ", .data$subregion, " (IMCA oficial de subregión)"),
      ind_mpio  = NA_integer_,
      tipo_fila = "Subregión (IMCA oficial)"
    )

  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
    .etiquetar_agregados(stats::setNames(
      paste0("PROMEDIO PONDERADO PROVINCIA ", toupper(prov$etiqueta), " (por población 2022)"),
      "Total provincia"
    )) |>
    dplyr::bind_rows(filas_subregion) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "imca",
    etiquetas = c(.ETIQ_TERRITORIO, .IMCA),
    formatos  = stats::setNames(rep("0.00", length(columnas)), columnas)
  )

  tabla
}

# =============================================================================
# BLOQUE 6 — Índice de Gobierno Digital 2024, FURAG (3.4 CTI del .do)
# =============================================================================
# A diferencia del IMCA, el insumo NO trae fila oficial de subregión: la
# subregión también se calcula como promedio ponderado por población 2024, pero
# sobre TODOS sus municipios (no solo los de la provincia).

.GOB_DIGITAL <- c(
  gobierno_digital         = "Índice de Gobierno Digital",
  gobernanza               = "Gobernanza",
  innovacion_digital       = "Innovación Pública Digital",
  arquitectura             = "Arquitectura",
  seguridad_privacidad     = "Seguridad y Privacidad de la Información",
  servicios_ciudadanos     = "Servicios Ciudadanos Digitales",
  cultura_apropiacion      = "Cultura y Apropiación",
  servicios_inteligentes   = "Servicios y Procesos Inteligentes",
  estado_abierto           = "Estado Abierto",
  decisiones_datos         = "Decisiones basadas en datos",
  proyectos_transformacion = "Proyectos de Transformación Digital",
  ciudades_territorios     = "Estrategias de Ciudades y Territorios Inteligentes"
)

.hoja_gobierno_digital <- function(prov, archivo) {
  columnas <- names(.GOB_DIGITAL)

  # El insumo trae su propia columna `municipio`; se descarta para que no choque
  # con el nombre de presentación del crosswalk.
  universo <- haven::read_dta(entrada("curados", "indice_gobierno_digital_2024.dta")) |>
    dplyr::transmute(ind_mpio = as.integer(.data$ind_mpio),
                     dplyr::across(dplyr::all_of(columnas), as.numeric)) |>
    dplyr::left_join(.poblacion_peso(2024), by = "ind_mpio") |>
    con_territorio()

  # Promedio ponderado por subregión sobre los 125 municipios del departamento.
  por_subregion <- universo |>
    dplyr::filter(!is.na(.data$subregion_full)) |>
    dplyr::group_by(subregion = .data$subregion_full) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(columnas),
      \(x) {
        ok <- !is.na(x) & !is.na(.data$pob_peso)
        if (any(ok)) stats::weighted.mean(x[ok], .data$pob_peso[ok]) else NA_real_
      }), .groups = "drop")

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "pob_peso",
                  dplyr::all_of(columnas))

  filas_subregion <- data.frame(subregion = unique(municipios$subregion)) |>
    dplyr::inner_join(por_subregion, by = "subregion") |>
    dplyr::mutate(
      municipio = paste0("PROMEDIO PONDERADO SUBREGIÓN ", .data$subregion,
                         " (por población 2024)"),
      ind_mpio  = NA_integer_,
      tipo_fila = "Subregión (promedio ponderado)"
    )

  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
    .etiquetar_agregados(stats::setNames(
      paste0("PROMEDIO PONDERADO PROVINCIA ", toupper(prov$etiqueta), " (por población 2024)"),
      "Total provincia"
    )) |>
    dplyr::bind_rows(filas_subregion) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "gobierno_digital",
    etiquetas = c(.ETIQ_TERRITORIO, .GOB_DIGITAL),
    formatos  = stats::setNames(rep("0.00", length(columnas)), columnas)
  )

  tabla
}

# =============================================================================
# BLOQUE 7 — Tránsito inmediato a la educación superior (3.4 CTI del .do)
# =============================================================================
# Llega en 0-100 y se pasa a fracción. El agregado provincial es promedio
# SIMPLE: es una tasa de una cohorte pequeña y el .do no la pondera.

.hoja_tti_edsup <- function(prov, archivo) {
  d <- leer_derivado("20250506 EDUCACION")
  c_cod <- col_req(d, "ind_mpio")
  c_tti <- col_req(d, "tti_edsup")

  municipios <- d |>
    dplyr::transmute(ind_mpio = as.integer(a_numero(.data[[c_cod]])),
                     tti_edsup = a_numero(.data[[c_tti]]) / 100) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia", "tti_edsup")

  tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                           columnas = "tti_edsup", como = "promedio") |>
    .etiquetar_agregados(stats::setNames(
      paste0("PROMEDIO SIMPLE PROVINCIA ", toupper(prov$etiqueta)), "Total provincia")) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "tti_edsup", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "tti_edsup",
    etiquetas = c(.ETIQ_TERRITORIO,
                  tti_edsup = "Tasa de tránsito inmediato a la educación superior"),
    formatos = c(tti_edsup = "0.0%")
  )

  tabla
}

# =============================================================================
# BLOQUE 8 — Internet fijo, MinTIC 2025 (3.5 del .do)
# =============================================================================
# Solo internet fijo activo. Las líneas de fibra se cuentan con una suma
# condicional (no filtrando por fibra) para no perder los municipios que tienen
# cero líneas de fibra, que son justamente los del mensaje.
# Los conteos se suman y las razones se recalculan sobre las sumas (un conteo
# se suma; una razón entre dos conteos se recalcula sobre las sumas, no se
# promedia). El .do original promediaba las cuatro columnas, también los
# conteos: la fila provincial publicaba la suma dividida por el número de
# municipios (comprobado: la razón entre lo publicado antes y la suma real
# era exactamente 1/n). Hallazgo de Pablo (F-1-027), adoptado también aquí.
#
# El derivado trae los cuatro trimestres de 2025; cantidad_lineas_accesos es
# un STOCK (accesos activos al cierre del trimestre), no un flujo, así que
# sumar los cuatro cuenta cuatro veces el mismo acceso. Y "Internet fijo"
# suelto es solo uno de cuatro paquetes que lo incluyen (el MinTIC cuenta los
# empaquetados como un acceso: Triple Play, Duo Play 1 y 2 también traen
# internet fijo). El filtro no sesgaba parejo: descartaba el 4 % de los
# accesos de una provincia rural típica y el 69 % de los del Área
# Metropolitana. Los dos defectos vienen del .do original (F-5-001,
# F-5-002), adoptados también aquí junto con la corrección.
PAQUETES_CON_INTERNET_FIJO <- c(
  "Internet fijo",
  "Triple Play (Telefonía fija + Internet fijo + TV por suscripción)",
  "Duo Play 1 (Telefonía fija + Internet fijo)",
  "Duo Play 2 (Internet fijo y TV por suscripción)"
)

.hoja_internet <- function(prov, archivo) {
  fuente <- leer_derivado("infraestructura_internet_2025")

  # Si el MinTIC agrega un paquete nuevo con internet fijo (p. ej. un "Quad
  # Play"), el pipeline se detiene en vez de contar de menos en silencio.
  nuevos <- setdiff(
    grep("Internet fijo", unique(fuente$servicio_paquete), value = TRUE),
    PAQUETES_CON_INTERNET_FIJO)
  if (length(nuevos)) {
    stop("La fuente trae paquetes con internet fijo que no están en la lista:\n  ",
         paste(nuevos, collapse = "\n  "),
         "\nAgréguelos a PAQUETES_CON_INTERNET_FIJO o el conteo saldrá corto.",
         call. = FALSE)
  }

  ultimo <- max(a_numero(fuente$trimestre), na.rm = TRUE)
  anio   <- max(a_numero(fuente$anno), na.rm = TRUE)
  message("  [internet] ", anio, " T", ultimo, ", ",
          length(PAQUETES_CON_INTERNET_FIJO), " paquetes con internet fijo")

  crudo <- fuente |>
    dplyr::filter(a_numero(.data$trimestre) == ultimo,
                  .data$servicio_paquete %in% PAQUETES_CON_INTERNET_FIJO,
                  .data$estado == "Activo en funcionamiento") |>
    dplyr::mutate(
      fibra = stringr::str_detect(.data$tecnologia, stringr::fixed("Fiber to the")) |
              .data$tecnologia == "Otras tecnologías de fibra (antes FTTx)",
      lineas = as.numeric(.data$cantidad_lineas_accesos)
    )

  lineas <- crudo |>
    dplyr::group_by(ind_mpio = as.integer(.data$ind_mpio)) |>
    dplyr::summarise(
      lineas_totales = sum(.data$lineas, na.rm = TRUE),
      lineas_fibra   = sum(.data$lineas * .data$fibra, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(prop_fibra = .data$lineas_fibra / .data$lineas_totales)

  poblacion <- leer_derivado("poblacion_total_2025") |>
    dplyr::filter(.data$area_geo == "Total") |>
    dplyr::transmute(ind_mpio = as.integer(.data$ind_mpio),
                     poblacion = as.numeric(.data$Total))

  columnas <- c("lineas_totales", "lineas_fibra", "prop_fibra", "internet_1000hab")
  sumables <- c("lineas_totales", "lineas_fibra", "poblacion")

  municipios <- lineas |>
    dplyr::inner_join(poblacion, by = "ind_mpio") |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(sumables))

  # Se suman los conteos y las razones se recalculan al final: así la fila de
  # municipio y la de agregado salen de la misma fórmula.
  tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                           columnas = sumables, como = "suma") |>
    dplyr::mutate(
      prop_fibra       = .data$lineas_fibra / .data$lineas_totales,
      internet_1000hab = .data$lineas_totales / .data$poblacion * 1000
    ) |>
    .etiquetar_agregados(stats::setNames(
      paste0("PROVINCIA ", toupper(prov$etiqueta),
             " (suma de líneas; razones recalculadas sobre las sumas)"), "Total provincia")) |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  dplyr::all_of(columnas), "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "internet_2025",
    etiquetas = c(.ETIQ_TERRITORIO,
      lineas_totales   = "Líneas de acceso a internet fijo",
      lineas_fibra     = "Líneas de acceso a internet fijo por fibra óptica",
      prop_fibra       = "Proporción de líneas sobre fibra óptica",
      internet_1000hab = "Líneas de acceso a internet fijo por cada 1.000 habitantes"),
    formatos = c(lineas_totales = "#,##0", lineas_fibra = "#,##0",
                 prop_fibra = "0.0%", internet_1000hab = "#,##0.0")
  )

  # El periodo viaja con la tabla para que las figuras (04_figuras/
  # 03_ordenamiento.R) no tengan que adivinarlo ni dejarlo fijo en "2025":
  # el dato es de un trimestre, no del año completo. Hallazgo de Pablo
  # (F-2-049), adoptado también aquí.
  attr(tabla, "periodo") <- sprintf("último trimestre de %d", anio)

  tabla
}

# =============================================================================
# BLOQUE 9 — Uso adecuado del suelo rural, POTA (3.1 del .do)
# =============================================================================
# Se exporta ÚNICAMENTE el % de predios rurales con uso adecuado y SIN filas
# agregadas. La base son todos los municipios de la provincia (desde el
# crosswalk): los que la fuente no cubre aparecen con la celda vacía, que es
# información — no un cero.

.hoja_uso_suelo <- function(prov, archivo) {
  pota <- leer_derivado("uso_del_suelo_pota")
  c_cod <- col_req(pota, "codmpio", "ind_mpio")
  c_uso <- col_req(pota, "pct_uso_adecuado_rural")

  pota <- pota |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      # Llega en 0-100 -> fracción, para que Excel lo muestre como porcentaje.
      pct_uso_adecuado_rural = a_numero(.data[[c_uso]]) / 100
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio))

  tabla <- crosswalk_provincias() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(pota, by = "ind_mpio") |>
    dplyr::arrange(.data$nvl_label) |>
    dplyr::mutate(tipo_fila = "Municipio") |>
    dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                  "pct_uso_adecuado_rural", "tipo_fila")

  escribir_hoja(
    dplyr::select(tabla, -"tipo_fila"), archivo, "uso_suelo_rural",
    etiquetas = c(.ETIQ_TERRITORIO,
                  pct_uso_adecuado_rural = "Predios con uso adecuado del suelo rural"),
    formatos = c(pct_uso_adecuado_rural = "0.0%")
  )

  tabla
}

# --- Punto de entrada ---------------------------------------------------------

tabla_ordenamiento <- function(prov) {
  message("== 03 Ordenamiento — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "03_Ordenamiento"), "ordenamiento.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  vias <- .vias_provincia(prov)

  resultado <- list(
    deficit_vivienda   = .hoja_deficit_vivienda(prov, archivo),
    servicios_publicos = .hoja_servicios_publicos(prov, archivo),
    vias_area = .hoja_vias(
      prov, archivo, vias, "idv", "area_km2", "vias_area",
      "(por área del municipio)",
      c("Km de vía primaria por km² del municipio",
        "Km de vía secundaria por km² del municipio",
        "Km de vía terciaria por km² del municipio")
    ),
    vias_habitantes = .hoja_vias(
      prov, archivo, vias, "vpc", "pob_peso", "vias_habitantes",
      "(por población)",
      c("Km de vía primaria por cada 1.000 hab.",
        "Km de vía secundaria por cada 1.000 hab.",
        "Km de vía terciaria por cada 1.000 hab.")
    ),
    catastro         = .hoja_catastro(prov, archivo),
    imca             = .hoja_imca(prov, archivo),
    gobierno_digital = .hoja_gobierno_digital(prov, archivo),
    tti_edsup        = .hoja_tti_edsup(prov, archivo),
    internet_2025    = .hoja_internet(prov, archivo),
    uso_suelo_rural  = .hoja_uso_suelo(prov, archivo)
  )

  message("  03 Ordenamiento: ", length(resultado), " hojas en ", basename(archivo))
  invisible(resultado)
}
