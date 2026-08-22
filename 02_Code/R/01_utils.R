# =============================================================================
# 01_utils.R — Utilidades comunes del pipeline
#
# Operaciones que se repiten en las 10 secciones: leer insumos, cruzar con los
# crosswalks territoriales, filtrar por provincia, añadir las filas de total y
# escribir el .xlsx de la sección con encabezados legibles.
#
# ETAPA DEL PIPELINE: infraestructura (lo carga 00_config.R)
# =============================================================================

# --- Texto y nombres ---------------------------------------------------------

#' Normaliza texto para comparar: sin tildes, sin espacios extra, en minúsculas.
#' Se usa para emparejar nombres de columna y de municipio entre fuentes que
#' escriben distinto la misma cosa.
norm_txt <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_squish() |>
    tolower()
}

#' Nombre real de una columna a partir de una búsqueda insensible a acentos,
#' mayúsculas, espacios y separadores. Devuelve NA si no hay coincidencia.
#'
#' Tolera que la misma columna se llame "AREA KM2", "AREAKM2" o "area_km2":
#' Stata compacta los espacios al importar con `firstrow` y readxl no, así que
#' el mismo archivo produce nombres distintos según quién lo lea.
#'
#' @param datos data.frame
#' @param ... una o más alternativas; se devuelve la primera que exista
#' @examples col(datos, "Código DANE", "cod_dane", "ind_mpio")
col <- function(datos, ...) {
  compacto <- function(x) stringr::str_remove_all(norm_txt(x), "[ _.\\-]")
  alternativas <- c(...)
  reales <- names(datos)
  for (a in alternativas) {
    i <- which(norm_txt(reales) == norm_txt(a))          # exacta
    if (length(i)) return(reales[i[1]])
    i <- which(compacto(reales) == compacto(a))          # ignorando separadores
    if (length(i)) return(reales[i[1]])
    i <- which(startsWith(compacto(reales), compacto(a)))# por prefijo
    if (length(i)) return(reales[i[1]])
  }
  NA_character_
}

#' Igual que col(), pero aborta con un mensaje que dice qué columnas sí hay.
col_req <- function(datos, ...) {
  nombre <- col(datos, ...)
  if (is.na(nombre)) {
    stop("No encuentro ninguna de estas columnas: ", paste(c(...), collapse = ", "),
         "\n  Columnas disponibles: ", paste(names(datos), collapse = " | "),
         call. = FALSE)
  }
  nombre
}

#' Nombres de municipio en la forma canónica del proyecto: MAYÚSCULAS, sin
#' tildes, con las correcciones de nomenclatura que difieren entre fuentes.
#' (Este bloque estaba copiado literalmente en cuatro scripts de homogeneización.)
normalizar_municipio <- function(x) {
  y <- x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_squish() |>
    toupper()
  correcciones <- c(
    "SANTAFE DE ANTIOQUIA"   = "SANTA FE DE ANTIOQUIA",
    "SANTA FE DE ANTIOQUIA"  = "SANTA FE DE ANTIOQUIA",
    "SAN PEDRO"              = "SAN PEDRO DE LOS MILAGROS",
    "SAN ANDRES"             = "SAN ANDRES DE CUERQUIA",
    "CIUDAD BOLIVAR"         = "CIUDAD BOLIVAR",
    "EL CARMEN DE VIBORAL"   = "CARMEN DE VIBORAL",
    "SAN JOSE DE LA MONTANA" = "SAN JOSE DE LA MONTANA",
    "EL PENOL"               = "PENOL",
    "EL RETIRO"              = "RETIRO"
  )
  ifelse(y %in% names(correcciones), correcciones[y], y)
}

#' Nombre de municipio para mostrar en tablas y figuras: con tildes y
#' preposiciones en minúscula ("Carolina del Príncipe"), tal como lo trae el
#' listado oficial. Nunca derivar esto con str_to_title() sobre el nombre
#' normalizado: produce "Carolina Del Principe".
etiqueta_municipio <- function(codigos) {
  cw <- crosswalk_provincias()
  cw$municipio[match(as.integer(codigos), cw$ind_mpio)]
}

# --- Crosswalks territoriales -------------------------------------------------
# Se leen una sola vez por sesión.

.cache <- new.env(parent = emptyenv())

#' Municipios con provincia y subregión (90 municipios en las 11 provincias).
crosswalk_provincias <- function() {
  if (is.null(.cache$prov)) {
    .cache$prov <- leer_derivado("codigos_provincias") |>
      dplyr::mutate(
        ind_mpio = as.integer(ind_mpio),
        nvl_label = as.character(nvl_label),
        municipio = as.character(municipio),
        provincia = as.character(provincia),
        subregion = as.character(subregion),
        id_provincia = as.integer(id_provincia)
      ) |>
      dplyr::select(ind_mpio, nvl_label, municipio, subregion, provincia,
                    id_provincia)
  }
  .cache$prov
}

#' Subregión DANE de los 125 municipios de Antioquia (para totales subregionales
#' completos, no solo los municipios que pertenecen a alguna provincia).
crosswalk_subregiones <- function() {
  if (is.null(.cache$subreg)) {
    .cache$subreg <- leer_derivado("subreg_completo") |>
      dplyr::mutate(ind_mpio = as.integer(ind_mpio),
                    subregion_full = as.character(subregion_full))
  }
  .cache$subreg
}

#' Añade provincia, subregión y subregión DANE completa a partir del código DANE.
#' @param datos data.frame con una columna de código de municipio
#' @param columna_codigo nombre de esa columna (por defecto se busca sola)
con_territorio <- function(datos, columna_codigo = NULL) {
  cc <- columna_codigo %||% col(datos, "ind_mpio", "cod_mpio", "codigo dane", "cod_dane", "divipola")
  if (is.na(cc)) stop("No encuentro la columna de código de municipio en los datos.", call. = FALSE)
  datos |>
    dplyr::mutate(ind_mpio = as.integer(.data[[cc]])) |>
    dplyr::left_join(crosswalk_provincias(), by = "ind_mpio") |>
    dplyr::left_join(crosswalk_subregiones(), by = "ind_mpio")
}

#' Municipios de una provincia.
#'
#' El id se extrae antes del filtro: varias fuentes traen una columna llamada
#' `prov`, que dentro de `dplyr::filter()` enmascararía el argumento `prov` de
#' esta función y produciría "$ operator is invalid for atomic vectors".
filtrar_provincia <- function(datos, prov) {
  id <- prov$id
  d <- dplyr::filter(datos, .data$id_provincia == .env$id)
  if (nrow(d) == 0) {
    stop("Ningún municipio quedó tras filtrar por la provincia ", prov$id, " (", prov$etiqueta, "). ",
         "Verifique que los datos traigan el código DANE y que el cruce territorial se hizo.",
         call. = FALSE)
  }
  d
}

#' Subregión a la que pertenece la mayoría de municipios de la provincia.
subregion_dominante <- function(prov) {
  crosswalk_provincias() |>
    dplyr::filter(.data$id_provincia == prov$id) |>
    dplyr::left_join(crosswalk_subregiones(), by = "ind_mpio") |>
    dplyr::count(.data$subregion_full, sort = TRUE) |>
    dplyr::slice(1) |>
    dplyr::pull(.data$subregion_full)
}

# --- Filas de total -----------------------------------------------------------

#' Añade a una tabla municipal las filas de total provincial, de subregión y de
#' departamento, en el orden en que van en el informe.
#'
#' Las filas agregadas se distinguen por tener `ind_mpio` vacío: es la convención
#' que ya usaban las tablas del proyecto y de la que dependen los formatos.
#'
#' @param datos tabla de municipios de UNA provincia, con ind_mpio y nvl_label.
#' @param universo tabla equivalente con TODOS los municipios de Antioquia
#'   (necesaria para los totales de subregión y departamento). Si es NULL solo
#'   se agrega el total provincial.
#' @param prov lista devuelta por provincia().
#' @param columnas nombre de las columnas numéricas a agregar.
#' @param como "suma" o una función de agregación por columna, p. ej.
#'   list(area_km2 = "suma", tasa = "promedio_ponderado").
#' @param pesos nombre de la columna de ponderación si alguna agregación la
#'   usa, o una lista columna -> peso si distintas columnas necesitan
#'   denominadores distintos (p. ej. una tasa rural ponderada por población
#'   rural junto a otras ponderadas por población total). Simétrico con
#'   `como`. Hallazgo de Pablo (F-2-027), adoptado también aquí.
agregar_totales <- function(datos, universo = NULL, prov, columnas,
                            como = "suma", pesos = NULL) {
  agregacion <- if (is.character(como) && length(como) == 1) {
    stats::setNames(as.list(rep(como, length(columnas))), columnas)
  } else {
    como
  }

  resumir <- function(d, etiqueta, tipo) {
    valores <- lapply(columnas, function(cl) {
      x <- suppressWarnings(as.numeric(d[[cl]]))
      metodo <- agregacion[[cl]] %||% "suma"
      switch(metodo,
        suma = sum(x, na.rm = TRUE),
        promedio = mean(x, na.rm = TRUE),
        mediana = stats::median(x, na.rm = TRUE),
        promedio_ponderado = {
          # `pesos` admite un nombre de columna, o una lista columna -> peso,
          # igual que `como` admite un método o una lista columna -> método.
          col_peso <- if (is.list(pesos)) pesos[[cl]] else pesos
          w <- suppressWarnings(as.numeric(d[[col_peso]]))
          ok <- !is.na(x) & !is.na(w)
          if (any(ok)) stats::weighted.mean(x[ok], w[ok]) else NA_real_
        },
        stop("Método de agregación desconocido: ", metodo, call. = FALSE)
      )
    })
    fila <- stats::setNames(as.data.frame(valores), columnas)
    fila$ind_mpio <- NA_integer_
    fila$tipo_fila <- tipo
    # La etiqueta va en la columna de nombre que traiga la tabla: `municipio`
    # (nombre de presentación) y/o `nvl_label` (nombre normalizado).
    if ("municipio" %in% names(datos)) fila$municipio <- etiqueta
    if ("nvl_label" %in% names(datos)) fila$nvl_label <- etiqueta
    fila
  }

  filas <- list(dplyr::mutate(datos, tipo_fila = "Municipio"))
  filas[[length(filas) + 1]] <- resumir(
    datos, paste0("TOTAL PROVINCIA ", toupper(prov$etiqueta)), "Total provincia"
  )

  if (!is.null(universo)) {
    subreg <- subregion_dominante(prov)
    d_sub <- dplyr::filter(universo, .data$subregion_full == subreg)
    if (nrow(d_sub)) {
      filas[[length(filas) + 1]] <- resumir(
        d_sub, paste0("TOTAL SUBREGIÓN ", subreg), "Total subregión"
      )
    }
    filas[[length(filas) + 1]] <- resumir(
      universo, "TOTAL DEPARTAMENTO (ANTIOQUIA)", "Total departamento"
    )
  }

  dplyr::bind_rows(filas)
}

#' TRUE en las filas agregadas (código DANE vacío).
es_fila_total <- function(datos) {
  cc <- col(datos, "ind_mpio", "codigo dane", "cod_dane")
  if (is.na(cc)) return(rep(FALSE, nrow(datos)))
  is.na(datos[[cc]]) | datos[[cc]] == ""
}

# --- Escritura de tablas ------------------------------------------------------

#' Escribe (o añade) una hoja al .xlsx de una sección, con encabezados legibles
#' y las filas de total resaltadas.
#'
#' @param datos data.frame ya ordenado y con las columnas finales.
#' @param archivo ruta del .xlsx.
#' @param hoja nombre de la hoja.
#' @param etiquetas vector nombrado columna -> encabezado legible.
#' @param formatos vector nombrado columna -> formato de Excel
#'   ("#,##0", "0,0", "0,0%"); se aplica a la columna completa.
escribir_hoja <- function(datos, archivo, hoja, etiquetas = NULL, formatos = NULL) {
  d <- as.data.frame(datos)
  if (!is.null(etiquetas)) {
    nuevos <- ifelse(names(d) %in% names(etiquetas), etiquetas[names(d)], names(d))
    names(d) <- unname(nuevos)
  }

  wb <- if (file.exists(archivo)) openxlsx2::wb_load(archivo) else openxlsx2::wb_workbook()
  if (hoja %in% wb$get_sheet_names()) wb <- openxlsx2::wb_remove_worksheet(wb, hoja)
  wb <- openxlsx2::wb_add_worksheet(wb, hoja)
  wb <- openxlsx2::wb_add_data(wb, hoja, d, na.strings = "")

  n_fil <- nrow(d) + 1
  n_col <- ncol(d)
  # Encabezado
  wb <- openxlsx2::wb_add_font(wb, hoja, dims = openxlsx2::wb_dims(rows = 1, cols = 1:n_col),
                               bold = "1", color = openxlsx2::wb_color(hex = "FFFFFFFF"))
  wb <- openxlsx2::wb_add_fill(wb, hoja, dims = openxlsx2::wb_dims(rows = 1, cols = 1:n_col),
                               color = openxlsx2::wb_color(hex = "FF4458A6"))
  # Filas de total en negrita
  totales <- which(es_fila_total(datos)) + 1
  if (length(totales)) {
    wb <- openxlsx2::wb_add_font(wb, hoja,
      dims = openxlsx2::wb_dims(rows = totales, cols = 1:n_col), bold = "1")
  }
  # Formatos numéricos
  if (!is.null(formatos)) {
    for (cl in names(formatos)) {
      etiqueta <- if (!is.null(etiquetas) && cl %in% names(etiquetas)) etiquetas[[cl]] else cl
      j <- match(etiqueta, names(d))
      if (!is.na(j)) {
        wb <- openxlsx2::wb_add_numfmt(wb, hoja,
          dims = openxlsx2::wb_dims(rows = 2:n_fil, cols = j), numfmt = formatos[[cl]])
      }
    }
  }
  wb <- openxlsx2::wb_set_col_widths(wb, hoja, cols = 1:n_col, widths = "auto")
  wb <- openxlsx2::wb_freeze_pane(wb, hoja, first_row = TRUE)
  openxlsx2::wb_save(wb, archivo)

  message("  [tabla] ", basename(archivo), " :: ", hoja, "  (", nrow(d), " filas)")
  invisible(archivo)
}

#' Guarda los datos exactos de una figura como hoja auxiliar del .xlsx de la
#' sección, para que la cifra publicada siempre sea trazable (DISENO.md §8).
escribir_datos_figura <- function(datos, archivo, id_figura) {
  escribir_hoja(datos, archivo, paste0("_", id_figura))
}

# --- Lectura y escritura de datos derivados -----------------------------------
# Los derivados del pipeline se guardan en un único formato: Parquet. Es
# columnar, comprimido y tipado — pesa una fracción de lo que pesaban los .dta
# y .xlsx que había antes, conserva los tipos sin reconversiones y se lee
# igual desde R, Python y Stata 18+.
#
# Los insumos siguen en el formato en que los entrega su fuente (Excel casi
# siempre); para esos está `leer_excel()`.

#' Lee un derivado del pipeline.
#'
#' @param nombre nombre sin extensión ("codigos_provincias"). Si el parquet no
#'   está pero sí una versión heredada en .dta o .xlsx, la lee y avisa: así el
#'   pipeline sigue corriendo mientras se termina de convertir todo.
leer_derivado <- function(nombre, hoja = 1) {
  nombre <- sub("\\.(parquet|dta|xlsx)$", "", nombre)
  pq <- derivado(paste0(nombre, ".parquet"))
  if (file.exists(pq)) return(as.data.frame(arrow::read_parquet(pq)))

  for (ext in c(".dta", ".xlsx")) {
    heredado <- derivado(paste0(nombre, ext))
    if (file.exists(heredado)) {
      warning("Se leyó ", basename(heredado), " en vez del parquet. ",
              "Regenere el derivado para convertirlo.", call. = FALSE)
      return(if (ext == ".dta") as.data.frame(haven::read_dta(heredado))
             else leer_excel(heredado, hoja))
    }
  }
  stop("No existe el derivado '", nombre, "' en ", RUTAS$derived, "\n",
       "  Genérelo con:  Rscript 02_Code/run_all.R", call. = FALSE)
}

#' TRUE si el derivado está disponible (en parquet o en un formato heredado).
existe_derivado <- function(nombre) {
  nombre <- sub("\\.(parquet|dta|xlsx)$", "", nombre)
  any(file.exists(derivado(paste0(nombre, c(".parquet", ".dta", ".xlsx")))))
}

#' Escribe un derivado del pipeline en Parquet.
#'
#' @param datos data.frame.
#' @param nombre nombre sin extensión.
#' @param comprimir códec; zstd da el mejor equilibrio tamaño/velocidad.
escribir_derivado <- function(datos, nombre, comprimir = "zstd") {
  nombre <- sub("\\.(parquet|dta|xlsx)$", "", nombre)
  ruta <- derivado(paste0(nombre, ".parquet"))
  d <- as.data.frame(datos)
  # Parquet no admite las columnas etiquetadas de haven; se guardan como su
  # tipo base y la etiqueta se pierde (nadie del pipeline la usa).
  d[] <- lapply(d, function(x) if (inherits(x, "haven_labelled")) as.vector(x) else x)
  arrow::write_parquet(d, ruta, compression = comprimir)
  message("  [derivado] ", basename(ruta), "  (", nrow(d), " x ", ncol(d), ", ",
          format(structure(file.size(ruta), class = "object_size"), units = "auto"), ")")
  invisible(ruta)
}

# --- Lectura de insumos -------------------------------------------------------

#' Lee una hoja de Excel devolviendo nombres de columna tal cual (sin que readxl
#' los altere), que es lo que espera `col()`.
leer_excel <- function(ruta, hoja = 1, saltar = 0) {
  readxl::read_excel(ruta, sheet = hoja, skip = saltar, .name_repair = "minimal") |>
    as.data.frame()
}

#' Convierte a numérico columnas que vienen como texto con separadores locales
#' ("1.234,5" o "1,234.5") o en notación científica ("5.37E-2").
a_numero <- function(x) {
  if (is.numeric(x)) return(x)
  y <- stringr::str_squish(as.character(x))

  # La notación científica se deja pasar tal cual: quitarle la E la convertiría
  # en un número equivocado, y varias fuentes POTA vienen así.
  cientifica <- stringr::str_detect(y, "^[+-]?\\d+(\\.\\d+)?[eE][+-]?\\d+$")

  z <- stringr::str_replace_all(y, "[^0-9,.\\-]", "")

  # Qué separador es el decimal, en orden de prioridad:
  #  1. Un separador repetido siempre es de miles ("1.234.567", "1,234,567").
  #  2. Si aparecen los dos, el decimal es el último ("1.234,5" colombiano;
  #     "1,234.5" anglosajón).
  #  3. Si solo hay un punto, es de miles cuando va seguido de exactamente tres
  #     dígitos ("7.550" son 7.550, no 7,55); si no, es decimal ("13.89").
  #  4. Una coma sola siempre es decimal ("-0,5").
  n_coma  <- stringr::str_count(z, ",")
  n_punto <- stringr::str_count(z, "\\.")
  ult_coma  <- as.integer(regexpr(",[^,]*$", z))
  ult_punto <- as.integer(regexpr("\\.[^.]*$", z))

  decimal_es_coma <- n_coma == 1 &
    (n_punto > 1 | ult_coma > ult_punto)
  decimal_es_punto <- n_punto == 1 & !decimal_es_coma &
    (n_coma > 0 | !stringr::str_detect(z, "\\.\\d{3}$"))

  z <- ifelse(
    decimal_es_coma,
    stringr::str_remove_all(z, "\\.") |> stringr::str_replace(",", "."),
    ifelse(decimal_es_punto,
           stringr::str_remove_all(z, ","),
           stringr::str_remove_all(z, "[.,]"))
  )

  suppressWarnings(as.numeric(ifelse(cientifica, y, z)))
}

`%||%` <- function(a, b) if (is.null(a)) b else a
