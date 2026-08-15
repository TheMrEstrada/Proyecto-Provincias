# =============================================================================
# comparar_referencia.R — Valida las tablas generadas contra el informe publicado
#
# El Anexo 1 (00_Documentos) es la salida final del pipeline anterior para la
# provincia Bioenergética del Norte: 52 tablas ya curadas. Este script compara,
# municipio por municipio, los valores que produce el pipeline R contra los que
# se publicaron, y reporta las diferencias.
#
# Es el criterio de aceptación de la migración: una sección no se da por
# migrada mientras no reproduzca las cifras publicadas (o mientras la diferencia
# no esté explicada).
#
# USO:
#   Rscript 02_Code/99_checks/comparar_referencia.R
#
# REQUIERE: tests/referencia/ (generar con tests/extraer_referencia_anexo1.py)
# ETAPA DEL PIPELINE: verificación
# =============================================================================

if (!exists("RUTAS")) {
  source(file.path(getwd(), "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}

#' Convierte texto de una tabla del informe a número.
#'
#' El informe usa sobre todo formato colombiano ("2.841", "38%", "1.234,5"),
#' pero algunas tablas quedaron con decimal anglosajón ("13.89"). Borrar el
#' punto siempre convertiría 13.89 en 1389, así que se decide por el contexto:
#' con coma presente el punto es separador de miles; sin coma, un punto seguido
#' de exactamente tres dígitos es de miles y en los demás casos es decimal.
.num_ref <- function(x) {
  y <- stringr::str_squish(as.character(x))
  y <- stringr::str_remove_all(y, "[%$\\s]")

  punto_de_miles <- stringr::str_detect(y, ",") |
    stringr::str_detect(y, "\\.\\d{3}(\\.|$)")

  y <- ifelse(punto_de_miles, stringr::str_remove_all(y, "\\."), y)
  y <- stringr::str_replace(y, ",", ".")
  suppressWarnings(as.numeric(y))
}

#' Ruta del CSV de una tabla del Anexo, buscada por su título.
#'
#' Se busca por título y no por número de archivo: el orden de los archivos
#' depende de cuántas tablas sin título (contenedores de mapas) haya antes, así
#' que un número fijo se desactualiza en cuanto cambia el documento.
#'
#' @param patron texto o expresión regular que identifica la tabla,
#'   p. ej. "Tabla 45." o "Cobertura neta".
tabla_referencia <- function(patron) {
  indice <- utils::read.csv(file.path(RUTAS$referencia, "tablas", "indice.csv"),
                            encoding = "UTF-8", stringsAsFactors = FALSE)
  i <- grep(patron, indice$titulo, ignore.case = TRUE, fixed = FALSE)
  if (length(i) == 0) {
    warning("Ninguna tabla del Anexo coincide con: ", patron, call. = FALSE)
    return(NA_character_)
  }
  if (length(i) > 1) {
    warning(length(i), " tablas coinciden con '", patron, "'; se usa la primera: ",
            indice$titulo[i[1]], call. = FALSE)
  }
  file.path(RUTAS$referencia, "tablas", indice$archivo[i[1]])
}

#' Año al que se refiere una tabla del informe, tomado de su título
#' ("… del Norte de Antioquia - 2024" → 2024). NA si el título no lo dice o
#' menciona un rango de años.
.anio_del_titulo <- function(patron) {
  indice <- utils::read.csv(file.path(RUTAS$referencia, "tablas", "indice.csv"),
                            encoding = "UTF-8", stringsAsFactors = FALSE)
  i <- grep(patron, indice$titulo, ignore.case = TRUE)
  if (!length(i)) return(NA_real_)
  titulo <- indice$titulo[i[1]]
  if (grepl("\\d{4}\\s*[-–]\\s*\\d{4}", titulo)) return(NA_real_)  # es un rango
  anios <- as.numeric(unlist(regmatches(titulo, gregexpr("\\b20\\d{2}\\b", titulo))))
  if (!length(anios)) NA_real_ else max(anios)
}

#' Extrae de una tabla del Anexo los pares (municipio, valor) de cada columna
#' numérica, emparejando los municipios por nombre normalizado.
#'
#' @param csv ruta del CSV extraído del Anexo (use `tabla_referencia()`).
#' @param municipios nombres de municipio esperados (los de la provincia).
leer_tabla_referencia <- function(csv, municipios) {
  if (is.na(csv) || !file.exists(csv)) return(NULL)
  crudo <- utils::read.csv(csv, header = FALSE, colClasses = "character",
                           encoding = "UTF-8")
  clave <- norm_txt(municipios)

  # Puede haber MÁS DE UNA columna de municipios: varias tablas del informe
  # ponen dos rankings lado a lado (municipio+valor | municipio+valor), cada uno
  # ordenado por su propia columna. Cada columna numérica se asocia entonces con
  # la columna de municipios que tenga inmediatamente a su izquierda.
  # Umbral bajo a propósito: algunas tablas solo listan los municipios donde el
  # fenómeno existe (p. ej. 6 de 13 con cultivos de coca) y aun así son
  # comparables.
  aciertos <- vapply(crudo, function(cl) sum(norm_txt(cl) %in% clave), integer(1))
  cols_mun <- which(aciertos >= max(3, length(municipios) * 0.25))
  if (!length(cols_mun)) return(NULL)  # no es una tabla municipal comparable

  columnas <- list()
  decimales <- integer(0)
  for (j in seq_along(crudo)) {
    if (j %in% cols_mun) next
    anteriores <- cols_mun[cols_mun < j]
    if (!length(anteriores)) next
    j_mun <- max(anteriores)

    filas <- which(norm_txt(crudo[[j_mun]]) %in% clave)
    if (!length(filas)) next
    v <- .num_ref(crudo[[j]][filas])
    if (sum(!is.na(v)) < length(filas) * 0.6) next

    nombre <- paste0("col_", j)
    columnas[[nombre]] <- data.frame(
      municipio_norm = norm_txt(crudo[[j_mun]][filas]),
      valor = v, stringsAsFactors = FALSE
    )
    names(columnas[[nombre]])[2] <- nombre

    # Con cuántos decimales se publicó: el informe redondea (1,57 % sale como
    # 2 %), así que la comparación se hace a esa precisión, no a la del pipeline.
    dec <- stringr::str_match(stringr::str_squish(crudo[[j]][filas]), ",(\\d+)")[, 2]
    decimales[nombre] <- max(c(0L, nchar(dec[!is.na(dec)])))
  }
  if (!length(columnas)) return(NULL)

  salida <- Reduce(function(a, b) merge(a, b, by = "municipio_norm", all = TRUE),
                   columnas)
  attr(salida, "decimales") <- decimales
  salida
}

#' Compara una columna generada contra la columna de la referencia que mejor le
#' corresponda, y reporta el resultado.
#'
#' @param generada data.frame con `municipio` y la columna de valores.
#' @param columna nombre de la columna de valores en `generada`.
#' @param referencia salida de leer_tabla_referencia().
#' @param tolerancia diferencia relativa admitida (por defecto 0,5 %, que
#'   absorbe el redondeo con que se publicaron las cifras).
comparar_columna <- function(generada, columna, referencia, tolerancia = 0.005) {
  g <- data.frame(
    municipio_norm = norm_txt(generada$municipio),
    valor = as.numeric(generada[[columna]]),
    stringsAsFactors = FALSE
  )
  g <- g[!is.na(g$valor), , drop = FALSE]

  decimales <- attr(referencia, "decimales")
  mejor <- NULL
  for (cl in setdiff(names(referencia), "municipio_norm")) {
    m <- merge(g, referencia[, c("municipio_norm", cl)], by = "municipio_norm")
    if (nrow(m) == 0) next
    # Las celdas vacías del informe no son diferencias: son datos que no se
    # publicaron. Se excluyen de la comparación y se cuentan aparte. Solo
    # cuentan las filas que sí cruzaron con la referencia; las de total no
    # aparecen en el informe y no son "datos faltantes".
    sin_publicar <- sum(is.na(m[[cl]]))
    m <- m[!is.na(m[[cl]]), , drop = FALSE]
    if (nrow(m) == 0) next
    ref <- m[[cl]]
    dec <- decimales[[cl]] %||% 2L
    # La referencia puede venir en % (38) donde el pipeline da proporción (0,38)
    for (k in c(1, 100, 1 / 100, 1 / 10, 1e-6, 1e-3)) {
      # Se compara a la precisión con que se publicó la cifra
      gen <- round(m$valor * k, dec)
      dif <- abs(gen - ref) / pmax(abs(ref), 1e-9)
      dif[is.na(dif)] <- Inf
      ok <- mean(dif <= tolerancia)
      if (is.null(mejor) || ok > mejor$ok) {
        mejor <- list(ok = ok, col = cl, escala = k, decimales = dec, n = nrow(m),
                      sin_publicar = sin_publicar,
                      peor = if (all(is.infinite(dif))) NA else max(dif[is.finite(dif)]),
                      detalle = data.frame(municipio = m$municipio_norm,
                                           generado = gen, publicado = ref,
                                           dif_rel = dif))
      }
    }
  }
  mejor
}

# Diferencias verificadas una a una que NO son fallos de la migración: el valor
# del pipeline es el correcto según la fuente y el publicado tiene una errata.
# Formato: "seccion|columna|municipio" -> explicación.
DIFERENCIAS_CONOCIDAS <- c(
  "09_Salud|Tasa de mortalidad infantil (x 1.000 nacidos vivos)|angostura" = paste(
    "El informe intercambió las filas de Angostura y Anorí en la Tabla 50.",
    "MORTALIDAD_INFANTIL.xlsx da para Angostura (05038) 7,9/17,1/0,0/11,6/13,9",
    "y para Anorí (05040) 18,1/17,2/8,8/0,0/5,5; el informe las publica al revés."
  ),
  "09_Salud|Tasa de mortalidad infantil (x 1.000 nacidos vivos)|anori" = paste(
    "Misma errata: filas de Angostura y Anorí intercambiadas en la Tabla 50."
  ),
  "01_Generalidades|Área municipal (km²)|toledo" = paste(
    "AREA_ORIGINAL.xlsx da 122,578 km², que redondea a 123; el Anexo 1 publica",
    "122. Los otros 15 valores de la tabla sí redondean bien, así que es una",
    "errata del informe."
  )
)

#' Informe de comparación de una columna, listo para leer en consola.
reportar <- function(etiqueta, resultado, seccion = "") {
  if (is.null(resultado)) {
    cat(sprintf("  %-40s SIN REFERENCIA COMPARABLE\n", etiqueta))
    return(invisible(FALSE))
  }
  malos <- resultado$detalle[which(resultado$detalle$dif_rel > 0.005), ]
  malos <- malos[order(-malos$dif_rel), ]
  # paste() con un vector vacío devuelve un elemento, no cero: sin este guard,
  # una columna sin diferencias reportaría una diferencia inexistente.
  clave <- if (nrow(malos)) {
    paste(seccion, etiqueta, malos$municipio, sep = "|")
  } else {
    character(0)
  }
  explicadas <- clave %in% names(DIFERENCIAS_CONOCIDAS)

  n_ok <- resultado$n - sum(!explicadas)
  estado <- if (n_ok == resultado$n) {
    if (any(explicadas)) "COINCIDE (con erratas del informe registradas)" else "COINCIDE"
  } else {
    "DIFIERE"
  }
  nota <- if (isTRUE(resultado$sin_publicar > 0)) {
    sprintf(", %d sin dato en el informe", resultado$sin_publicar)
  } else ""
  cat(sprintf("  %-40s %s  (%d/%d municipios%s)\n", etiqueta, estado, n_ok,
              resultado$n, nota))

  for (i in seq_len(nrow(malos))) {
    marca <- if (explicadas[i]) "errata conocida" else "REVISAR"
    cat(sprintf("      [%s] %-24s pipeline %10.3f   publicado %10.3f\n",
                marca, malos$municipio[i], malos$generado[i], malos$publicado[i]))
    if (explicadas[i]) {
      cat("          ", DIFERENCIAS_CONOCIDAS[[clave[i]]], "\n")
    }
  }
  invisible(n_ok == resultado$n)
}

# --- Qué comparar --------------------------------------------------------------
# Una entrada por tabla del informe que el pipeline debe reproducir. `referencia`
# es el patrón con el que se busca la tabla en el índice del Anexo (por título,
# nunca por número de archivo). `columnas` son las de la hoja generada.
COMPARACIONES <- list(
  list(seccion = "01_Generalidades", archivo = "distribucion_territorial.xlsx",
       hoja = "distribucion_territorial", referencia = "Extensión territorial",
       columnas = c("Área municipal (km²)", "Participación en el área provincial")),
  list(seccion = "02_Demografia", archivo = "demografia.xlsx", hoja = "poblacion",
       referencia = "Proyecciones de población",
       columnas = c("Población total", "Población urbana", "Población rural")),
  list(seccion = "02_Demografia", archivo = "demografia.xlsx", hoja = "poblacion",
       referencia = "Densidad Poblacional",
       columnas = "Densidad poblacional (hab/km²)"),
  list(seccion = "02_Demografia", archivo = "demografia.xlsx",
       hoja = "natalidad_mortalidad", referencia = "Tasa de Natalidad",
       columnas = c("Tasa de Natalidad", "Tasa de Mortalidad",
                    "Índice de Envejecimiento")),
  list(seccion = "04_Gobernabilidad", archivo = "gobernabilidad.xlsx", hoja = "mdm",
       referencia = "Medición de Desempeño Municipal", columnas = "MDM"),
  list(seccion = "04_Gobernabilidad", archivo = "gobernabilidad.xlsx", hoja = "idf",
       referencia = "Índice de Desempeño Fiscal", columnas = "IDF"),
  list(seccion = "04_Gobernabilidad", archivo = "gobernabilidad.xlsx", hoja = "icm",
       referencia = "Índice de Ciudades Modernas", columnas = "ICM"),
  list(seccion = "03_Ordenamiento", archivo = "ordenamiento.xlsx",
       hoja = "vias_area", referencia = "Kilómetros de vía según el área",
       columnas = c("Km de vía primaria por km² del municipio",
                    "Km de vía secundaria por km² del municipio",
                    "Km de vía terciaria por km² del municipio")),
  list(seccion = "03_Ordenamiento", archivo = "ordenamiento.xlsx",
       hoja = "deficit_vivienda",
       referencia = "Déficit cualitativo y cuantitativo",
       columnas = c("Déficit cuantitativo de vivienda",
                    "Déficit cualitativo de vivienda")),
  list(seccion = "03_Ordenamiento", archivo = "ordenamiento.xlsx",
       hoja = "catastro", referencia = "Caracterización del catastro",
       # El informe publica los avalúos en millones de pesos y el pipeline en
       # pesos, como el .do; lo absorbe el factor de escala del comparador.
       columnas = "Avalúo catastral total ($)"),
  ## 05 Economía. El valor agregado NO entra: el Anexo se publicó a precios
  ## corrientes y el derivado solo trae la serie a constantes de 2015 (la razón
  ## publicado/pipeline es 1,714 en los 13 municipios). Lo invariante al
  ## deflactor —el peso relativo de cada municipio— sí reproduce el informe.
  list(seccion = "05_Economia", archivo = "economia.xlsx", hoja = "ecv_gini",
       referencia = "Medición del GINI",
       columnas = c("Gini ingresos del hogar - total (municipal)",
                    "Gini laboral - total (municipal)")),
  list(seccion = "05_Economia", archivo = "economia.xlsx",
       hoja = "ecv_desocupacion_nini",
       referencia = "Desocupación general y para jóvenes",
       columnas = c("Tasa de desocupación - total (municipal)",
                    "Tasa de desocupación jóvenes (15-28) (municipal)",
                    "Jóvenes que no estudian ni trabajan (NiNi) (municipal)")),
  list(seccion = "06_Desarrollo_Rural", archivo = "desarrollo_rural.xlsx",
       hoja = "inventario_pecuario",
       referencia = "Inventario de especies pecuarias",
       # La columna "Total" del informe incluye Aves, que PECUARIO_PROVINCIAS.xlsx
       # no trae; no es comparable. Se validan las especies que sí están.
       columnas = c("Bovinos", "Porcinos", "Equinos")),
  list(seccion = "07_Ambiental", archivo = "ambiental.xlsx", hoja = "irca",
       referencia = "IRCA en los municipios", columnas = "IRCA urbano"),
  list(seccion = "07_Ambiental", archivo = "ambiental.xlsx",
       hoja = "perdida_cobertura",
       referencia = "pérdida de la cobertura arbórea",
       columnas = "Pérdida de cobertura arbórea 2001-2023 (%)"),
  list(seccion = "07_Ambiental", archivo = "ambiental.xlsx", hoja = "imrc",
       referencia = "Índice Municipal de Gestión del Riesgo",
       columnas = c("IMRC Exceso de lluvias", "IMRC Déficit de lluvias")),
  list(seccion = "08_Educacion", archivo = "educacion.xlsx", hoja = "educacion",
       referencia = "Cobertura neta en educación", columnas = "Cobertura neta"),
  list(seccion = "08_Educacion", archivo = "educacion.xlsx", hoja = "educacion",
       referencia = "Deserción escolar", columnas = "Tasa de deserción"),
  list(seccion = "08_Educacion", archivo = "educacion.xlsx", hoja = "educacion",
       referencia = "Repitencia escolar", columnas = "Tasa de repitencia"),
  # 09 Salud: solo la mortalidad infantil es comparable. Bajo peso, vectores,
  # suicidios y aseguramiento usan cortes de datos POSTERIORES al informe
  # (2023 y diciembre de 2025 frente a 2024/2025 publicados), así que no
  # tienen contra qué validarse hasta que se actualicen los derivados.
  list(seccion = "09_Salud", archivo = "salud.xlsx", hoja = "mortalidad_infantil",
       referencia = "Mortalidad infantil", anio = 2024,
       columnas = "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"),
  list(seccion = "10_Seguridad", archivo = "seguridad.xlsx", hoja = "coca",
       referencia = "Densidad de cultivos ilícitos",
       columnas = c("Hectáreas de coca (2023)",
                    "Coca sobre el total departamental de coca (%)")),
  list(seccion = "10_Seguridad", archivo = "seguridad.xlsx", hoja = "delitos",
       referencia = "Tasa delitos de alto impacto",
       columnas = c("Hurtos por 100.000 hab.", "Homicidios por 100.000 hab.",
                    "Violencia intrafamiliar por 100.000 hab.",
                    "Delitos sexuales por 100.000 hab.")),
  list(seccion = "10_Seguridad", archivo = "seguridad.xlsx", hoja = "irv",
       referencia = "riesgo de victimización",
       columnas = "Índice de Riesgo de Victimización"),
  list(seccion = "10_Seguridad", archivo = "seguridad.xlsx", hoja = "srtdaf",
       referencia = "tierras despojadas",
       columnas = c("Número de solicitudes", "Número de predios"))
)

#' Corre todas las comparaciones declaradas y devuelve el resumen.
comparar_todo <- function(id = 2) {
  if (!dir.exists(file.path(RUTAS$referencia, "tablas"))) {
    stop("No hay referencia extraída. Ejecute primero:\n",
         "  python3 tests/extraer_referencia_anexo1.py", call. = FALSE)
  }
  prov <- provincia(id)   # el Anexo 1 corresponde a la provincia 2
  municipios <- crosswalk_provincias() |>
    filtrar_provincia(prov) |>
    dplyr::pull(municipio)

  cat("== Comparación contra el Anexo 1 —", prov$etiqueta, "==\n")
  resultados <- list()
  seccion_previa <- ""

  for (cmp in COMPARACIONES) {
    ruta <- file.path(RUTAS$outputs, prov$carpeta, cmp$seccion, cmp$archivo)
    if (!file.exists(ruta)) {
      if (cmp$seccion != seccion_previa) {
        cat("\n", cmp$seccion, " — sin generar todavía\n", sep = "")
        seccion_previa <- cmp$seccion
      }
      next
    }
    if (cmp$seccion != seccion_previa) {
      cat("\n", cmp$seccion, "\n", sep = "")
      seccion_previa <- cmp$seccion
    }

    generada <- openxlsx2::wb_to_df(openxlsx2::wb_load(ruta), sheet = cmp$hoja)
    names(generada)[names(generada) == "Municipio"] <- "municipio"
    csv_ref <- tabla_referencia(cmp$referencia)
    ref <- leer_tabla_referencia(csv_ref, municipios)

    # Las hojas con varios años traen una fila por municipio y año. El año a
    # comparar sale del título de la tabla publicada ("… - 2024"), no del
    # último disponible: la fuente suele traer años posteriores al informe.
    if ("Año" %in% names(generada)) {
      anio <- cmp$anio %||% .anio_del_titulo(cmp$referencia)
      anios <- suppressWarnings(as.numeric(generada[["Año"]]))
      if (is.na(anio) || !anio %in% anios) anio <- max(anios, na.rm = TRUE)
      generada <- generada[which(anios == anio), ]
      cat(sprintf("  (año comparado: %d)\n", as.integer(anio)))
    }

    for (columna in cmp$columnas) {
      if (!columna %in% names(generada)) {
        cat(sprintf("  %-40s COLUMNA NO ENCONTRADA EN LA HOJA\n", columna))
        next
      }
      ok <- reportar(columna, comparar_columna(generada, columna, ref), cmp$seccion)
      resultados[[length(resultados) + 1]] <- data.frame(
        seccion = cmp$seccion, columna = columna, coincide = isTRUE(ok)
      )
    }
  }

  resumen <- if (length(resultados)) do.call(rbind, resultados) else NULL
  if (!is.null(resumen)) {
    cat(sprintf("\n%d de %d columnas reproducen el informe.\n",
                sum(resumen$coincide), nrow(resumen)))
    fallan <- resumen[!resumen$coincide, ]
    if (nrow(fallan)) {
      cat("Pendientes de explicar:\n")
      for (i in seq_len(nrow(fallan))) {
        cat("  - ", fallan$seccion[i], " / ", fallan$columna[i], "\n", sep = "")
      }
    }
  }
  invisible(resumen)
}

# --- Ejecución ----------------------------------------------------------------
.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "comparar_referencia.R") {
  comparar_todo()
}
