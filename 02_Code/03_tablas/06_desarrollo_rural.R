# =============================================================================
# 06_desarrollo_rural.R — Sección 6: Desarrollo Rural
#
# TABLAS (siete hojas de un único .xlsx, las mismas del .do original):
#   inventario_pecuario     — cabezas por especie y municipio-año, con los
#                             totales de provincia, subregión y departamento.
#   participacion_municipal — peso de cada municipio en el inventario pecuario
#                             provincial.
#   composicion_especies    — reparto porcentual de las especies dentro de cada
#                             municipio.
#   area_km2                — extensión municipal (km²) y total provincial.
#   principales_cultivos    — por municipio-año, el cultivo permanente y el
#                             transitorio de mayor producción.
#   composicion_agricola    — producción por tipo de cultivo, participación del
#                             municipio en la provincia y reparto
#                             permanentes/transitorios.
#   rendimiento             — rendimiento agregado (Σ producción / Σ área
#                             cosechada) por municipio y para la provincia.
#
# INPUTS:  01_Data/01_Derived/PECUARIO_PROVINCIAS.xlsx
#            (hojas "InvBovino", "InvBufalino", "InvCaprinoOvinoEquino",
#             "InvPorcino")
#          01_Data/01_Derived/CULTIVOS_PROVINCIAS.xlsx  (hoja "BasePagina")
#            OJO: ninguno de los dos derivados lo produce un script del
#            pipeline; se arman a mano en Excel a partir de UPRA/EVA. Si se
#            rehace la cadena de derivados hay que construirlos aparte.
#          01_Data/00_Inputs/AREA_ORIGINAL.xlsx  (hoja "Area")
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/06_Desarrollo_Rural/desarrollo_rural.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/06_Desarrollo_Rural.do
#
# DIFERENCIAS DELIBERADAS FRENTE AL .do (todas documentadas en el informe de
# migración):
#   - El nombre de municipio sale del crosswalk (columna `municipio`, con
#     tildes) y no de `nvl_label` ni de la columna `Municipio` del derivado de
#     cultivos, que trae nombres truncados ("Carolina") y capitalización
#     inconsistente ("San José de La Montaña").
#   - Los municipios de la provincia se seleccionan por código DANE
#     (`filtrar_provincia`) en vez de por la cadena `prov` del archivo de
#     cultivos. El conjunto resultante es el mismo.
#   - La hoja `principales_cultivos` del .do exportaba dos columnas con el
#     MISMO encabezado ("Producción total (t)"). Aquí se distinguen
#     ("… del cultivo permanente/transitorio") porque un encabezado repetido
#     rompe el mapeo de formatos y es ambiguo al leer la hoja.
#   - Las filas agregadas se rotulan con la convención única del pipeline
#     ("TOTAL PROVINCIA …"); el .do usaba "PROVINCIA …" solo en la hoja de
#     rendimiento.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# Especies del inventario pecuario, en el orden en que van en la tabla del
# informe. El archivo NO trae aves: la columna "Aves" del Anexo 1 viene de otra
# fuente que no está en el repositorio (pendiente conocido del proyecto).
ESPECIES_PECUARIAS <- c(
  bovinos  = "Bovinos",
  bufalos  = "Búfalos",
  caprinos = "Caprinos",
  ovinos   = "Ovinos",
  equinos  = "Equinos",
  porcinos = "Porcinos"
)

# --- Lectura de insumos -------------------------------------------------------

#' Una hoja del archivo pecuario con una sola especie por columna, colapsada a
#' municipio-año.
.hoja_pecuaria <- function(ruta, hoja, columna_valor, nombre) {
  d <- leer_excel(ruta, hoja = hoja)
  c_cod <- col_req(d, "Código Dane municipio", "ind_mpio")
  c_ano <- col_req(d, "Año")
  c_val <- col_req(d, columna_valor)

  d |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      anio     = as.integer(a_numero(.data[[c_ano]])),
      valor    = a_numero(.data[[c_val]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    dplyr::group_by(.data$ind_mpio, .data$anio) |>
    dplyr::summarise(valor = sum(.data$valor, na.rm = TRUE), .groups = "drop") |>
    dplyr::rename(!!nombre := "valor")
}

#' Hoja de caprinos, ovinos y equinos: viene en formato largo (una fila por
#' especie) y se pasa a ancho, igual que el `reshape wide` del .do.
.hoja_pecuaria_larga <- function(ruta) {
  d <- leer_excel(ruta, hoja = "InvCaprinoOvinoEquino")
  c_cod <- col_req(d, "Código Dane municipio", "ind_mpio")
  c_ano <- col_req(d, "Año")
  c_esp <- col_req(d, "Especie")
  c_val <- col_req(d, "Total")

  d |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      anio     = as.integer(a_numero(.data[[c_ano]])),
      especie  = norm_txt(.data[[c_esp]]),   # "Caprinos" -> "caprinos"
      valor    = a_numero(.data[[c_val]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$especie),
                  .data$especie %in% names(ESPECIES_PECUARIAS)) |>
    dplyr::group_by(.data$ind_mpio, .data$anio, .data$especie) |>
    dplyr::summarise(valor = sum(.data$valor, na.rm = TRUE), .groups = "drop") |>
    tidyr::pivot_wider(names_from = "especie", values_from = "valor")
}

#' Inventario pecuario de TODOS los municipios de Antioquia (125), por año.
#' Una especie sin registro en un municipio-año queda en 0, como en el .do.
.universo_pecuario <- function() {
  ruta <- entrada("curados", "PECUARIO_PROVINCIAS.xlsx")
  partes <- list(
    .hoja_pecuaria(ruta, "InvBovino",   "Total bovinos",  "bovinos"),
    .hoja_pecuaria(ruta, "InvBufalino", "Total búfalos",  "bufalos"),
    .hoja_pecuaria(ruta, "InvPorcino",  "Total porcinos", "porcinos"),
    .hoja_pecuaria_larga(ruta)
  )

  d <- Reduce(function(a, b) dplyr::full_join(a, b, by = c("ind_mpio", "anio")), partes)

  faltantes <- setdiff(names(ESPECIES_PECUARIAS), names(d))
  for (v in faltantes) d[[v]] <- 0

  d |>
    dplyr::mutate(dplyr::across(dplyr::all_of(names(ESPECIES_PECUARIAS)),
                                \(x) dplyr::coalesce(x, 0))) |>
    dplyr::mutate(
      total_especies = rowSums(dplyr::pick(dplyr::all_of(names(ESPECIES_PECUARIAS))))
    ) |>
    con_territorio()
}

#' Base de cultivos (UPRA/EVA) de los municipios de una provincia.
.base_cultivos <- function(prov) {
  d <- leer_excel(entrada("curados", "CULTIVOS_PROVINCIAS.xlsx"), hoja = "BasePagina")

  c_cod <- col_req(d, "Código Dane municipio", "cod_mun")
  c_cul <- col_req(d, "Cultivo")
  c_cic <- col_req(d, "Ciclo del cultivo")
  c_ano <- col_req(d, "Año")
  c_per <- col_req(d, "Periodo")
  c_sem <- col_req(d, "Área sembrada (ha)")
  c_cos <- col_req(d, "Área cosechada (ha)")
  c_pro <- col_req(d, "Producción (t)")

  d |>
    dplyr::transmute(
      ind_mpio           = as.integer(a_numero(.data[[c_cod]])),
      cultivo            = as.character(.data[[c_cul]]),
      ciclo              = as.character(.data[[c_cic]]),
      anio               = as.integer(a_numero(.data[[c_ano]])),
      periodo            = as.character(.data[[c_per]]),
      area_sembrada      = a_numero(.data[[c_sem]]),
      area_cosechada     = a_numero(.data[[c_cos]]),
      produccion_cultivo = a_numero(.data[[c_pro]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov)
}

# --- Utilidades locales -------------------------------------------------------

#' Orden alfabético estable e independiente del locale (sin tildes).
.alfabetico <- function(datos, columna = "municipio") {
  datos[order(norm_txt(datos[[columna]])), , drop = FALSE]
}

#' Rellena subregión y provincia de las filas agregadas, que `agregar_totales()`
#' deja vacías porque solo sabe agregar las columnas numéricas.
.territorio_filas_total <- function(datos, prov) {
  subreg_dom <- subregion_dominante(prov)
  dplyr::mutate(
    datos,
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

ETIQUETAS_TERRITORIO <- c(
  ind_mpio  = "Código DANE",
  municipio = "Municipio",
  subregion = "Subregión",
  provincia = "Provincia",
  anio      = "Año"
)

# --- Tabla de la sección ------------------------------------------------------

tabla_desarrollo_rural <- function(prov) {
  message("== 06 Desarrollo Rural — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "06_Desarrollo_Rural"),
                       "desarrollo_rural.xlsx")
  # El .do borraba el archivo previo para no dejar hojas obsoletas.
  if (file.exists(archivo)) unlink(archivo)

  # ==========================================================================
  # 6.1 Inventario pecuario
  # ==========================================================================
  universo_pec <- .universo_pecuario()
  detalle_pec  <- filtrar_provincia(universo_pec, prov)
  anios_pec    <- sort(unique(detalle_pec$anio))
  columnas_pec <- c(names(ESPECIES_PECUARIAS), "total_especies")

  # --- Hoja 1: conteos por especie + agregados ------------------------------
  # Los totales de subregión y departamento se calculan sobre TODOS los
  # municipios de Antioquia del archivo (125), no solo los de la provincia.
  inventario <- purrr::map_dfr(anios_pec, function(a) {
    agregar_totales(
      .alfabetico(dplyr::filter(detalle_pec, .data$anio == a)),
      universo = dplyr::filter(universo_pec, .data$anio == a),
      prov     = prov,
      columnas = columnas_pec,
      como     = "suma"
    ) |>
      dplyr::mutate(anio = a)
  }) |>
    .territorio_filas_total(prov) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  dplyr::all_of(columnas_pec), tipo_fila)

  escribir_hoja(
    dplyr::select(inventario, -"tipo_fila"), archivo, "inventario_pecuario",
    etiquetas = c(ETIQUETAS_TERRITORIO, ESPECIES_PECUARIAS,
                  total_especies = "Total especies pecuarias"),
    formatos = c(anio = "0",
                 stats::setNames(rep("#,##0", length(columnas_pec)), columnas_pec))
  )

  # --- Hojas 2 y 3: participación y composición (solo municipios) -----------
  municipal_pec <- detalle_pec |>
    dplyr::group_by(.data$anio) |>
    dplyr::mutate(
      total_prov_especies = sum(.data$total_especies, na.rm = TRUE),
      participacion_pecuario_prov_pct = dplyr::if_else(
        .data$total_prov_especies == 0, NA_real_,
        .data$total_especies / .data$total_prov_especies
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(names(ESPECIES_PECUARIAS)),
      \(x) dplyr::if_else(.data$total_especies == 0, NA_real_, x / .data$total_especies),
      .names = "{.col}_pct"
    ))

  # Orden: por año y, dentro del año, alfabético (igual que el .do).
  municipal_pec <- municipal_pec[order(municipal_pec$anio,
                                       norm_txt(municipal_pec$municipio)), ]

  participacion <- dplyr::select(
    municipal_pec, ind_mpio, municipio, subregion, provincia, anio,
    total_especies, participacion_pecuario_prov_pct
  )

  escribir_hoja(
    participacion, archivo, "participacion_municipal",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  total_especies = "Total especies pecuarias",
                  participacion_pecuario_prov_pct =
                    "Participación en el total provincial (%)"),
    formatos = c(anio = "0", total_especies = "#,##0",
                 participacion_pecuario_prov_pct = "0.0%")
  )

  columnas_pct <- paste0(names(ESPECIES_PECUARIAS), "_pct")
  composicion_especies <- dplyr::select(
    municipal_pec, ind_mpio, municipio, subregion, provincia, anio,
    dplyr::all_of(columnas_pct)
  )

  escribir_hoja(
    composicion_especies, archivo, "composicion_especies",
    etiquetas = c(ETIQUETAS_TERRITORIO,
                  stats::setNames(paste0(ESPECIES_PECUARIAS, " (%)"), columnas_pct)),
    formatos = c(anio = "0",
                 stats::setNames(rep("0.0%", length(columnas_pct)), columnas_pct))
  )

  # ==========================================================================
  # 6.2 Extensión municipal (km²)
  # NOTA: el suelo rural sigue sin fuente en el repositorio (pendiente
  # conocido); la tabla 35 del Anexo 1 lo publica, aquí solo va el área total.
  # ==========================================================================
  area <- leer_excel(entrada("AREA_ORIGINAL.xlsx"), hoja = "Area")
  c_cod  <- col_req(area, "COD_MPIO", "ind_mpio")
  c_area <- col_req(area, "AREA KM2", "AREAKM2", "area_km2")

  area_municipios <- area |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      area_km2 = a_numero(.data[[c_area]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio() |>
    filtrar_provincia(prov) |>
    .alfabetico() |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, area_km2)

  # `universo = NULL`: el .do solo añade el total provincial a esta hoja.
  area_tabla <- agregar_totales(
    area_municipios, universo = NULL, prov = prov,
    columnas = "area_km2", como = "suma"
  ) |>
    .territorio_filas_total(prov) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, area_km2, tipo_fila)

  escribir_hoja(
    dplyr::select(area_tabla, -"tipo_fila"), archivo, "area_km2",
    etiquetas = c(ETIQUETAS_TERRITORIO, area_km2 = "Área municipal (km²)"),
    formatos = c(area_km2 = "#,##0.0")
  )

  # ==========================================================================
  # 6.3 Cultivos y producción agrícola
  # ==========================================================================
  cultivos <- .base_cultivos(prov)
  anios_cul <- sort(unique(cultivos$anio))

  # --- 6.3.1 Principal cultivo permanente y transitorio ---------------------
  # Por municipio-año, el cultivo de MAYOR producción de cada ciclo (sumada
  # sobre los periodos del año).
  principal_por_ciclo <- function(ciclo_objetivo, sufijo) {
    cultivos |>
      dplyr::filter(.data$ciclo == ciclo_objetivo) |>
      dplyr::group_by(.data$ind_mpio, .data$municipio, .data$anio, .data$cultivo) |>
      dplyr::summarise(produccion = sum(.data$produccion_cultivo, na.rm = TRUE),
                       .groups = "drop") |>
      dplyr::filter(!is.na(.data$produccion)) |>
      dplyr::group_by(.data$ind_mpio, .data$anio) |>
      dplyr::slice_max(.data$produccion, n = 1, with_ties = FALSE) |>
      dplyr::ungroup() |>
      stats::setNames(c("ind_mpio", "municipio", "anio",
                        paste0("cultivo_", sufijo), paste0("prod_", sufijo)))
  }

  principales <- dplyr::full_join(
    principal_por_ciclo("Permanente", "perm"),
    principal_por_ciclo("Transitorio", "tran"),
    by = c("ind_mpio", "municipio", "anio")
  )
  principales <- principales[order(principales$anio,
                                   norm_txt(principales$municipio)), ] |>
    dplyr::select(municipio, anio, cultivo_perm, prod_perm, cultivo_tran, prod_tran)

  escribir_hoja(
    principales, archivo, "principales_cultivos",
    etiquetas = c(
      municipio    = "Municipio",
      anio         = "Año",
      cultivo_perm = "Principal cultivo permanente",
      prod_perm    = "Producción total del cultivo permanente (t)",
      cultivo_tran = "Principal cultivo transitorio",
      prod_tran    = "Producción total del cultivo transitorio (t)"
    ),
    formatos = c(anio = "0", prod_perm = "#,##0.0", prod_tran = "#,##0.0")
  )

  # --- 6.3.2 Composición agrícola por municipio -----------------------------
  produccion_mun <- cultivos |>
    dplyr::group_by(.data$ind_mpio, .data$municipio, .data$subregion,
                    .data$provincia, .data$anio) |>
    dplyr::summarise(
      prod_perm = sum(.data$produccion_cultivo[.data$ciclo == "Permanente"], na.rm = TRUE),
      prod_tran = sum(.data$produccion_cultivo[.data$ciclo == "Transitorio"], na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(prod_total = .data$prod_perm + .data$prod_tran)

  composicion_agricola <- purrr::map_dfr(anios_cul, function(a) {
    agregar_totales(
      dplyr::arrange(dplyr::filter(produccion_mun, .data$anio == a),
                     dplyr::desc(.data$prod_total)),
      universo = NULL, prov = prov,
      columnas = c("prod_perm", "prod_tran", "prod_total"), como = "suma"
    ) |>
      dplyr::mutate(anio = a)
  }) |>
    .territorio_filas_total(prov) |>
    dplyr::group_by(.data$anio) |>
    dplyr::mutate(
      prod_total_prov = sum(.data$prod_total[.data$tipo_fila == "Municipio"], na.rm = TRUE)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      pct_prod_prov   = dplyr::if_else(.data$prod_total_prov == 0, NA_real_,
                                       .data$prod_total / .data$prod_total_prov),
      pct_permanente  = dplyr::if_else(.data$prod_total == 0, NA_real_,
                                       .data$prod_perm / .data$prod_total),
      pct_transitorio = dplyr::if_else(.data$prod_total == 0, NA_real_,
                                       .data$prod_tran / .data$prod_total)
    ) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  prod_perm, prod_tran, prod_total, prod_total_prov,
                  pct_prod_prov, pct_permanente, pct_transitorio, tipo_fila)

  escribir_hoja(
    dplyr::select(composicion_agricola, -"tipo_fila"), archivo, "composicion_agricola",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      prod_perm       = "Producción de cultivos permanentes (t)",
      prod_tran       = "Producción de cultivos transitorios (t)",
      prod_total      = "Producción agrícola total del municipio (t)",
      prod_total_prov = "Producción agrícola total de la provincia (t)",
      pct_prod_prov   = "Participación del municipio en la producción de la provincia",
      pct_permanente  = "Proporción de cultivos permanentes",
      pct_transitorio = "Proporción de cultivos transitorios"
    ),
    formatos = c(anio = "0", prod_perm = "#,##0.0", prod_tran = "#,##0.0",
                 prod_total = "#,##0.0", prod_total_prov = "#,##0.0",
                 pct_prod_prov = "0.0%", pct_permanente = "0.0%",
                 pct_transitorio = "0.0%")
  )

  # --- 6.3.3 Rendimiento agrícola por municipio -----------------------------
  # Rendimiento agregado = Σ producción / Σ área cosechada. Se recalcula sobre
  # los totales (no se promedian rendimientos municipales).
  # NOTA: el .do eliminó del flujo la variable de "área perdida" (decisión de
  # Pablo, 2026-08-05); el Anexo 1 sí la publica.
  rendimiento_mun <- cultivos |>
    dplyr::group_by(.data$ind_mpio, .data$municipio, .data$subregion,
                    .data$provincia, .data$anio) |>
    dplyr::summarise(
      produccion_cultivo = sum(.data$produccion_cultivo, na.rm = TRUE),
      area_cosechada     = sum(.data$area_cosechada, na.rm = TRUE),
      .groups = "drop"
    )

  rendimiento <- purrr::map_dfr(anios_cul, function(a) {
    agregar_totales(
      dplyr::filter(rendimiento_mun, .data$anio == a),
      universo = NULL, prov = prov,
      columnas = c("produccion_cultivo", "area_cosechada"), como = "suma"
    ) |>
      dplyr::mutate(anio = a)
  }) |>
    .territorio_filas_total(prov) |>
    dplyr::mutate(
      rendimiento = dplyr::if_else(.data$area_cosechada == 0, NA_real_,
                                   .data$produccion_cultivo / .data$area_cosechada)
    )

  # Orden del .do: por año, municipios primero y dentro de cada bloque por
  # rendimiento descendente.
  rendimiento <- rendimiento[order(rendimiento$anio,
                                   rendimiento$tipo_fila != "Municipio",
                                   -rendimiento$rendimiento), ] |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  produccion_cultivo, area_cosechada, rendimiento, tipo_fila)

  escribir_hoja(
    dplyr::select(rendimiento, -"tipo_fila"), archivo, "rendimiento",
    etiquetas = c(
      ETIQUETAS_TERRITORIO,
      produccion_cultivo = "Producción total (t)",
      area_cosechada     = "Área cosechada total (ha)",
      rendimiento        = "Rendimiento (t/ha)"
    ),
    formatos = c(anio = "0", produccion_cultivo = "#,##0.0",
                 area_cosechada = "#,##0.0", rendimiento = "#,##0.00")
  )

  invisible(list(
    archivo              = archivo,
    inventario           = inventario,
    participacion        = participacion,
    composicion_especies = composicion_especies,
    area                 = area_tabla,
    principales          = principales,
    composicion_agricola = composicion_agricola,
    rendimiento          = rendimiento
  ))
}
