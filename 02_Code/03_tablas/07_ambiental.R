# =============================================================================
# 07_ambiental.R — Sección 7: Ambiental
#
# TABLAS (hojas del .xlsx de la sección):
#   detalle             áreas protegidas por municipio (nombre, categoría, área
#                       sobre el municipio) con total provincial y departamental
#   irca                Índice de Riesgo de la Calidad del Agua por municipio y
#                       año (total, urbano y rural) con el promedio provincial
#   eventos_tipo        emergencias por municipio y tipo de evento, 2019-2024
#   eventos_año         emergencias por municipio y año, 2019-2024
#   desastres_selectos  los seis desastres de interés por municipio, la
#                       emergencia más prevalente, y los totales de provincia y
#                       de la subregión mayoritaria
#   imrc                Índice Municipal de Riesgo de Desastres ajustado por
#                       capacidades (exceso y déficit de lluvias), con los
#                       promedios provincial y departamental
#   perdida_cobertura   pérdida de cobertura arbórea 2001-2023 por municipio,
#                       como porcentaje de la cobertura de 2000
#
# INPUTS:  01_Data/01_Derived/AREAPROTEGIDA_PROVINCIAS.xlsx (hoja "Hoja1")
#          01_Data/01_Derived/IRCA_PROVINCIAS.xlsx          (hoja "Data")
#          01_Data/01_Derived/EMERGENCIAS_PROVINCIAS.xlsx   (hoja "Data")
#          01_Data/01_Derived/IMRC_PROVINCIAS.xlsx          (hoja "IMRC")
#          01_Data/00_Inputs/Pérdida de cobertura árborea.xlsx
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/07_Ambiental/ambiental.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/07_Ambiental.do
#
# NOTA SOBRE LOS INSUMOS: los cuatro *_PROVINCIAS.xlsx de esta sección
# (AREAPROTEGIDA, IRCA, EMERGENCIAS, IMRC) viven en 01_Data/01_Derived pero
# NINGÚN script del pipeline los construye: se arman a mano en Excel a partir de
# los crudos. Se leen con derivado() y se tratan como insumo dado.
#
# NOTA METODOLÓGICA: los agregados de área protegida y de número de eventos son
# SUMAS; los del IRCA, el IMRC y la pérdida de cobertura arbórea son PROMEDIOS
# SIMPLES entre municipios (así los publica el informe), no ponderados.
#
# UNIDADES: AREAPROTEGIDA_PROVINCIAS.xlsx trae el área en km² y así se exporta,
# igual que en el .do. El Anexo 1 publica esa misma cifra en hectáreas
# (1 km² = 100 ha); la comparación contra la referencia lo tiene en cuenta.
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

# --- Utilidades locales -------------------------------------------------------

#' Renombra las filas agregadas para dejar explícito que son promedios simples
#' entre municipios, como en el .do original ("PROMEDIO SIMPLE PROVINCIA …").
.marcar_promedio <- function(datos) {
  dplyr::mutate(datos, municipio = ifelse(
    .data$tipo_fila == "Municipio",
    .data$municipio,
    stringr::str_replace(.data$municipio, "^TOTAL ", "PROMEDIO SIMPLE ")
  ))
}

#' Orden de las filas del informe: primero los municipios, después los agregados.
.orden_fila <- function(tipo_fila) {
  match(tipo_fila,
        c("Municipio", "Total provincia", "Total subregión", "Total departamento"))
}

#' Clave de ordenación alfabética de nombres con tildes. Sin esto, el orden
#' depende del locale: en C, "Gómez Plata" cae después de "Guadalupe" porque
#' compara bytes. El informe usa el orden del español.
.clave_alfabetica <- function(x) norm_txt(x)

#' Año de una columna de fecha que puede llegar como datetime, Date, serial de
#' Excel o texto. El .do resuelve lo mismo con `dofc()`/`date()`.
.anio_de <- function(x) {
  if (inherits(x, "POSIXt") || inherits(x, "Date")) {
    return(as.integer(format(x, "%Y")))
  }
  if (is.numeric(x)) {
    return(as.integer(format(as.Date(x, origin = "1899-12-30"), "%Y")))
  }
  as.integer(stringr::str_extract(as.character(x), "\\d{4}"))
}

# --- Insumos ------------------------------------------------------------------

#' Áreas protegidas de todo el departamento: una fila por (municipio, área).
.areas_protegidas <- function() {
  d <- leer_excel(entrada("curados", "AREAPROTEGIDA_PROVINCIAS.xlsx"), hoja = "Hoja1")
  c_cod  <- col_req(d, "COD_MPIO", "ind_mpio")
  c_nom  <- col_req(d, "Nombre Area Protegida", "NombreAreaProtegida")
  c_cat  <- col_req(d, "categori_1", "Categoría")
  c_area <- col_req(d, "Area_Sobre_Municipio", "area_km2")

  d |>
    dplyr::transmute(
      ind_mpio  = as.integer(a_numero(.data[[c_cod]])),
      area_prot = as.character(.data[[c_nom]]),
      categoria = as.character(.data[[c_cat]]),
      area_km2  = a_numero(.data[[c_area]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()
}

#' IRCA de todos los municipios y todos los años disponibles.
.irca <- function() {
  d <- leer_excel(entrada("curados", "IRCA_PROVINCIAS.xlsx"), hoja = "Data")
  c_cod <- col_req(d, "MunicipioCodigo", "DIVIPOLA", "ind_mpio")
  c_ano <- col_req(d, "Año", "Anio")
  c_it  <- col_req(d, "IRCA")
  c_nt  <- col_req(d, "Nivel de riesgo")
  c_iu  <- col_req(d, "IRCAurbano")
  c_nu  <- col_req(d, "Nivel de riesgo urbano")
  c_ir  <- col_req(d, "IRCArural")
  c_nr  <- col_req(d, "Nivel de riesgo rural")

  d |>
    dplyr::transmute(
      ind_mpio            = as.integer(a_numero(.data[[c_cod]])),
      anio                = as.integer(a_numero(.data[[c_ano]])),
      irca                = a_numero(.data[[c_it]]),
      nivel_riesgo        = as.character(.data[[c_nt]]),
      irca_urbano         = a_numero(.data[[c_iu]]),
      nivel_riesgo_urbano = as.character(.data[[c_nu]]),
      irca_rural          = a_numero(.data[[c_ir]]),
      nivel_riesgo_rural  = as.character(.data[[c_nr]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$anio)) |>
    con_territorio()
}

#' Emergencias registradas por la UNGRD: una fila por evento, con municipio,
#' tipo de evento y año.
.emergencias <- function() {
  d <- leer_excel(entrada("curados", "EMERGENCIAS_PROVINCIAS.xlsx"), hoja = "Data")
  c_cod <- col_req(d, "CODIFICACIÓN SEGUN DIVIPOLA",
                   "CODIFICACIÓN SEGUN DIVIPOLA DEPART", "ind_mpio")
  c_ev  <- col_req(d, "EVENTO")
  c_fec <- col_req(d, "FECHA")

  d |>
    dplyr::transmute(
      ind_mpio   = as.integer(a_numero(.data[[c_cod]])),
      emergencia = stringr::str_squish(as.character(.data[[c_ev]])),
      anio       = .anio_de(.data[[c_fec]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio), !is.na(.data$emergencia)) |>
    con_territorio()
}

#' IMRC ajustado por capacidades de los 125 municipios.
#' Los dos encabezados son largos y casi idénticos ("… (IMRC_E)" / "… (IMRC_D)"):
#' se identifican por posición entre las columnas que no son territoriales,
#' igual que en el .do.
.imrc <- function() {
  d <- leer_excel(entrada("curados", "IMRC_PROVINCIAS.xlsx"), hoja = "IMRC")
  c_cod <- col_req(d, "DIVIPOLA", "ind_mpio")
  territoriales <- c(c_cod, col(d, "Municipio"), col(d, "subreg"), col(d, "prov"))
  indices <- setdiff(names(d), stats::na.omit(territoriales))
  if (length(indices) < 2) {
    stop("IMRC_PROVINCIAS.xlsx no trae las dos columnas de índice (exceso y déficit).",
         call. = FALSE)
  }

  d |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      imrc_e   = a_numero(.data[[indices[1]]]),
      imrc_d   = a_numero(.data[[indices[2]]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()
}

#' Pérdida de cobertura arbórea 2001-2023, como fracción de la cobertura que
#' el municipio tenía en 2000 (Global Forest Watch, dosel > 30 %). NO es una
#' fracción del área del municipio: recalcularla así difiere del valor
#' publicado en 119 de los 124 municipios. Hallazgo de Pablo (F-4-002),
#' adoptado también aquí.
#'
#' El rótulo de la columna (más abajo) se deja como está: "... (%)" no
#' afirma nada falso —dice «%», no «% del área»— y precisarlo rompería en
#' SILENCIO a sus tres lectores, que la buscan por el nombre exacto: la
#' prosa de la sección (05_documento/R/secciones.R), el panel comparativo
#' (06_comparativo/panel_provincial.R, que devuelve NA sin avisar si no la
#' encuentra) y 99_checks/comparar_referencia.R.
.perdida_cobertura <- function() {
  d <- leer_excel(entrada("Pérdida de cobertura árborea.xlsx"),
                  hoja = "Pérdida cobertura árborea")
  c_cod <- col_req(d, "Cod_mpio", "ind_mpio")
  c_val <- col_req(d, "% Pérdida de cobertura árborea 2001-2023", "% Pérdida")

  d |>
    dplyr::transmute(
      ind_mpio   = as.integer(a_numero(.data[[c_cod]])),
      perdida_ca = a_numero(.data[[c_val]])
    ) |>
    dplyr::filter(!is.na(.data$ind_mpio)) |>
    con_territorio()
}

# --- Hoja 1: áreas protegidas (detalle) --------------------------------------

.hoja_detalle <- function(prov, archivo) {
  universo <- .areas_protegidas()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.clave_alfabetica(.data$municipio), .data$area_prot) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  area_prot, categoria, area_km2)

  # Denominadores fijos de la participación (no dependen de la fila)
  tot_prov <- sum(municipios$area_km2, na.rm = TRUE)
  tot_dep  <- sum(universo$area_km2, na.rm = TRUE)

  # El informe publica solo provincia y departamento en esta tabla
  tabla <- agregar_totales(municipios, universo = universo, prov = prov,
                           columnas = "area_km2", como = "suma") |>
    dplyr::filter(.data$tipo_fila != "Total subregión") |>
    dplyr::mutate(
      provincia = dplyr::case_when(
        .data$tipo_fila == "Municipio"       ~ .data$provincia,
        .data$tipo_fila == "Total provincia" ~ prov$nombre_datos,
        TRUE                                 ~ "DEPARTAMENTO DE ANTIOQUIA"
      ),
      # Detalle: sobre el total provincial. Total provincia: sobre el total
      # departamental. Total departamento: es la base, queda vacío.
      participacion_area_prot_pct = dplyr::case_when(
        .data$tipo_fila == "Municipio"       ~ .data$area_km2 / tot_prov,
        .data$tipo_fila == "Total provincia" ~ .data$area_km2 / tot_dep,
        TRUE                                 ~ NA_real_
      )
    ) |>
    dplyr::arrange(.orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio), .data$area_prot) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, area_prot, categoria,
                  area_km2, participacion_area_prot_pct, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "detalle",
    etiquetas = c(
      ind_mpio                    = "Código DANE",
      municipio                   = "Municipio",
      subregion                   = "Subregión",
      provincia                   = "Provincia",
      area_prot                   = "Nombre Área Protegida",
      categoria                   = "Categoría",
      area_km2                    = "Área sobre municipio (km²)",
      participacion_area_prot_pct = "Participación del área protegida (%)"
    ),
    formatos = c(area_km2 = "#,##0.00", participacion_area_prot_pct = "0.00%")
  )

  tabla
}

# --- Hoja 2: IRCA -------------------------------------------------------------

.hoja_irca <- function(prov, archivo) {
  base <- .irca()

  municipios <- base |>
    filtrar_provincia(prov) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  irca, nivel_riesgo, irca_urbano, nivel_riesgo_urbano,
                  irca_rural, nivel_riesgo_rural)

  columnas <- c("irca", "irca_urbano", "irca_rural")

  # Un promedio provincial por año (el .do colapsa by(prov Año))
  tabla <- municipios |>
    split(municipios$anio) |>
    lapply(function(g) {
      agregar_totales(g, universo = NULL, prov = prov,
                      columnas = columnas, como = "promedio") |>
        .marcar_promedio() |>
        dplyr::mutate(anio = g$anio[1])
    }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$anio, .orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, anio,
                  irca, nivel_riesgo, irca_urbano, nivel_riesgo_urbano,
                  irca_rural, nivel_riesgo_rural, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "irca",
    etiquetas = c(
      ind_mpio            = "Código DANE",
      municipio           = "Municipio",
      subregion           = "Subregión",
      provincia           = "Provincia",
      anio                = "Año",
      irca                = "IRCA",
      nivel_riesgo        = "Nivel de riesgo",
      irca_urbano         = "IRCA urbano",
      nivel_riesgo_urbano = "Nivel riesgo urbano",
      irca_rural          = "IRCA rural",
      nivel_riesgo_rural  = "Nivel riesgo rural"
    ),
    formatos = c(irca = "0.00", irca_urbano = "0.00", irca_rural = "0.00")
  )

  tabla
}

# --- Hoja 3: emergencias por tipo de evento -----------------------------------

.hoja_eventos_tipo <- function(prov, archivo, eventos) {
  conteo <- eventos |>
    filtrar_provincia(prov) |>
    dplyr::count(.data$ind_mpio, .data$municipio, .data$subregion,
                 .data$provincia, .data$emergencia, name = "n_eventos")

  tabla <- conteo |>
    split(conteo$emergencia) |>
    lapply(function(g) {
      agregar_totales(g, universo = NULL, prov = prov,
                      columnas = "n_eventos", como = "suma") |>
        dplyr::mutate(emergencia = g$emergencia[1])
    }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$emergencia, .orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  emergencia, n_eventos, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "eventos_tipo",
    etiquetas = c(
      ind_mpio   = "Código DANE",
      municipio  = "Municipio",
      subregion  = "Subregión",
      provincia  = "Provincia",
      emergencia = "Tipo de evento",
      n_eventos  = "Número de eventos"
    ),
    formatos = c(n_eventos = "#,##0")
  )

  tabla
}

# --- Hoja 4: emergencias por año ----------------------------------------------

.hoja_eventos_anio <- function(prov, archivo, eventos) {
  conteo <- eventos |>
    filtrar_provincia(prov) |>
    dplyr::filter(!is.na(.data$anio)) |>
    dplyr::count(.data$ind_mpio, .data$municipio, .data$subregion,
                 .data$provincia, .data$anio, name = "n_eventos")

  tabla <- conteo |>
    split(conteo$anio) |>
    lapply(function(g) {
      agregar_totales(g, universo = NULL, prov = prov,
                      columnas = "n_eventos", como = "suma") |>
        dplyr::mutate(anio = g$anio[1])
    }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$anio, .orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  anio, n_eventos, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "eventos_año",
    etiquetas = c(
      ind_mpio  = "Código DANE",
      municipio = "Municipio",
      subregion = "Subregión",
      provincia = "Provincia",
      anio      = "Año",
      n_eventos = "Número de eventos"
    ),
    formatos = c(n_eventos = "#,##0")
  )

  tabla
}

# --- Hoja 5: desastres selectos y emergencia más prevalente -------------------

# Los seis eventos que publica el informe, con su etiqueta. El orden importa:
# ante un empate, gana el PRIMERO de esta lista (en el .do lo consigue haciendo
# los `replace` en orden inverso).
.SELECTOS <- c(
  av  = "AVENIDA TORRENCIAL",
  mm  = "MOVIMIENTO EN MASA",
  icv = "INCENDIO DE COBERTURA VEGETAL",
  inu = "INUNDACION",
  seq = "SEQUIA",
  sis = "SISMO"
)
.ETIQUETA_SELECTOS <- c(
  av  = "Avenida torrencial",
  mm  = "Movimiento en masa",
  icv = "Incendio de cobertura vegetal",
  inu = "Inundación",
  seq = "Sequía",
  sis = "Sismo"
)

#' Emergencia más prevalente entre los seis eventos selectos; vacía si el
#' municipio no registró ninguno.
.mas_prevalente <- function(datos) {
  m <- as.matrix(datos[, names(.SELECTOS), drop = FALSE])
  maximo <- apply(m, 1, max, na.rm = TRUE)
  ganador <- apply(m, 1, function(fila) names(.SELECTOS)[which.max(fila)])
  ifelse(maximo == 0, "", unname(.ETIQUETA_SELECTOS[ganador]))
}

.hoja_desastres_selectos <- function(prov, archivo, eventos) {
  clave <- toupper(stringi::stri_trans_general(eventos$emergencia, "Latin-ASCII"))
  marcas <- as.data.frame(lapply(.SELECTOS, function(e) as.integer(clave == e)))

  universo <- dplyr::bind_cols(dplyr::select(eventos, ind_mpio), marcas) |>
    dplyr::group_by(.data$ind_mpio) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(names(.SELECTOS)), sum),
                     .groups = "drop") |>
    con_territorio()

  # Todos los municipios de la provincia, también los que no registran eventos
  municipios <- crosswalk_provincias() |>
    filtrar_provincia(prov) |>
    dplyr::left_join(dplyr::select(universo, ind_mpio, dplyr::all_of(names(.SELECTOS))),
                     by = "ind_mpio") |>
    dplyr::mutate(dplyr::across(dplyr::all_of(names(.SELECTOS)),
                                ~ tidyr::replace_na(.x, 0L))) |>
    dplyr::arrange(.clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, dplyr::all_of(names(.SELECTOS)))

  # El informe publica provincia y subregión mayoritaria (no departamento)
  tabla <- agregar_totales(municipios, universo = universo, prov = prov,
                           columnas = names(.SELECTOS), como = "suma") |>
    dplyr::filter(.data$tipo_fila != "Total departamento") |>
    dplyr::arrange(.orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio))

  tabla$prevalente <- .mas_prevalente(tabla)
  tabla <- dplyr::select(tabla, ind_mpio, municipio, subregion,
                         dplyr::all_of(names(.SELECTOS)), prevalente, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "desastres_selectos",
    etiquetas = c(
      ind_mpio   = "Código DANE",
      municipio  = "Municipio",
      subregion  = "Subregión",
      .ETIQUETA_SELECTOS,
      prevalente = "Emergencia más prevalente"
    ),
    formatos = stats::setNames(rep("#,##0", length(.SELECTOS)), names(.SELECTOS))
  )

  tabla
}

# --- Hoja 6: IMRC (exceso y déficit de lluvias) -------------------------------

.hoja_imrc <- function(prov, archivo) {
  universo <- .imrc()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, imrc_e, imrc_d)

  # El informe publica municipios y departamento (no subregión)
  tabla <- agregar_totales(municipios, universo = universo, prov = prov,
                           columnas = c("imrc_e", "imrc_d"), como = "promedio") |>
    dplyr::filter(.data$tipo_fila != "Total subregión") |>
    .marcar_promedio() |>
    dplyr::mutate(provincia = dplyr::case_when(
      .data$tipo_fila == "Municipio"       ~ .data$provincia,
      .data$tipo_fila == "Total provincia" ~ prov$nombre_datos,
      TRUE                                 ~ "DEPARTAMENTO DE ANTIOQUIA"
    )) |>
    dplyr::arrange(.orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, imrc_e, imrc_d, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "imrc",
    etiquetas = c(
      ind_mpio  = "Código DANE",
      municipio = "Municipio",
      subregion = "Subregión",
      provincia = "Provincia",
      imrc_e    = "IMRC Exceso de lluvias",
      imrc_d    = "IMRC Déficit de lluvias"
    ),
    formatos = c(imrc_e = "0.00", imrc_d = "0.00")
  )

  tabla
}

# --- Hoja 7: pérdida de cobertura arbórea 2001-2023 ---------------------------

.hoja_perdida_cobertura <- function(prov, archivo) {
  universo <- .perdida_cobertura()

  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::arrange(.clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, perdida_ca)

  # El .do no agregaba: la pérdida es una fracción y no se puede sumar. El Anexo
  # 1 sí publica provincia, subregión y departamento, y lo hace con el PROMEDIO
  # SIMPLE entre municipios (verificado: 7,83 % / 7,01 % / 9,30 %).
  tabla <- agregar_totales(municipios, universo = universo, prov = prov,
                           columnas = "perdida_ca", como = "promedio") |>
    .marcar_promedio() |>
    dplyr::arrange(.orden_fila(.data$tipo_fila), .clave_alfabetica(.data$municipio)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia, perdida_ca, tipo_fila)

  escribir_hoja(
    dplyr::select(tabla, -tipo_fila), archivo, "perdida_cobertura",
    etiquetas = c(
      ind_mpio   = "Código DANE",
      municipio  = "Municipio",
      subregion  = "Subregión",
      provincia  = "Provincia",
      perdida_ca = "Pérdida de cobertura arbórea 2001-2023 (%)"
    ),
    formatos = c(perdida_ca = "0.0%")
  )

  tabla
}

# --- Punto de entrada ---------------------------------------------------------

tabla_ambiental <- function(prov) {
  message("== 07 Ambiental — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "07_Ambiental"), "ambiental.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  eventos <- .emergencias()

  # Serie departamental del IRCA: no es una hoja del informe, pero la figura de
  # evolución la usa como referencia.
  irca_departamento <- .irca() |>
    dplyr::group_by(.data$anio) |>
    dplyr::summarise(
      irca        = mean(.data$irca, na.rm = TRUE),
      irca_urbano = mean(.data$irca_urbano, na.rm = TRUE),
      irca_rural  = mean(.data$irca_rural, na.rm = TRUE),
      .groups = "drop"
    )

  resultado <- list(
    detalle            = .hoja_detalle(prov, archivo),
    irca               = .hoja_irca(prov, archivo),
    eventos_tipo       = .hoja_eventos_tipo(prov, archivo, eventos),
    eventos_anio       = .hoja_eventos_anio(prov, archivo, eventos),
    desastres_selectos = .hoja_desastres_selectos(prov, archivo, eventos),
    imrc               = .hoja_imrc(prov, archivo),
    perdida_cobertura  = .hoja_perdida_cobertura(prov, archivo),
    irca_departamento  = irca_departamento,
    archivo            = archivo
  )

  message("  07 Ambiental: 7 hojas en ", basename(archivo))
  invisible(resultado)
}
