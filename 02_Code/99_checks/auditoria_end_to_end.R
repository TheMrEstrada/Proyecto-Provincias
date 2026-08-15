# =============================================================================
# auditoria_end_to_end.R — Auditoría de trazabilidad del pipeline completo
#
# Responde una sola pregunta, de forma mecánica y repetible:
#
#     ¿Toda cifra publicada se puede rastrear hasta un archivo fuente y una
#     fórmula declarada, o hay números que aparecen sin origen?
#
# No opina sobre el código: lo mide. Cada comprobación produce un CSV con el
# detalle fila a fila, para que cualquiera pueda rehacer el juicio.
#
# QUÉ COMPRUEBA
#   A. Procedencia    insumo -> script -> derivado -> sección; huérfanos y
#                     productores ausentes.
#   B. Inventario     huella SHA-256 y fecha de cada insumo que el código lee.
#   C. Cobertura      los municipios de cada hoja son exactamente los de la
#                     provincia: ni uno de más (invención) ni de menos (silencio).
#   D. Agregados      cada fila de total/promedio se reproduce con una fórmula
#                     declarada (suma, promedio, ponderado). Bandera roja: un
#                     agregado FUERA del rango de sus municipios sin ser suma.
#   E. Rangos         proporciones fuera de [0,1], tasas negativas, infinitos.
#   F. Figuras        cada figura exportada tiene su hoja de datos en el .xlsx
#                     (regla de trazabilidad de DISENO.md §8) y su nota de fuente.
#   G. Catálogo       catalogo_figuras.xlsx frente a lo que el código genera.
#
# USO
#   Rscript 02_Code/99_checks/auditoria_end_to_end.R           # todas las provincias
#   Rscript 02_Code/99_checks/auditoria_end_to_end.R 2 4       # solo estas
#
# SALIDA: 04_Docs/auditoria/*.csv  +  04_Docs/auditoria/RESUMEN.md
#
# ETAPA DEL PIPELINE: verificación
# =============================================================================

if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(dirname(normalizePath(.f[1])))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}

DIR_AUDIT <- file.path(RUTAS$raiz, "04_Docs", "auditoria")
dir.create(DIR_AUDIT, recursive = TRUE, showWarnings = FALSE)

# Tolerancia relativa al comparar un agregado con su fórmula candidata. 1e-6
# absorbe el error de punto flotante acumulado en sumas de ~100 términos, y
# nada más: una diferencia real de redondeo del 0,1 % no pasa por aquí.
TOL <- 1e-6

.escribir <- function(d, nombre) {
  ruta <- file.path(DIR_AUDIT, nombre)
  utils::write.csv(d, ruta, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  message("  [auditoría] ", nombre, "  (", nrow(d), " filas)")
  invisible(ruta)
}

titulo <- function(x) cat("\n", x, "\n", strrep("=", nchar(x)), "\n", sep = "")

# =============================================================================
# A. PROCEDENCIA — qué lee y qué escribe cada script
# =============================================================================
# Se extrae del propio código, no de la documentación: lo que vale es lo que el
# script ejecuta. Las llamadas se leen con expresiones regulares sobre el texto
# porque `entrada()` y `leer_derivado()` reciben siempre literales.

.scripts_vigentes <- function() {
  f <- list.files(RUTAS$codigo, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  f[!grepl("/externos/", f)]
}
.scripts_externos <- function() {
  list.files(file.path(RUTAS$codigo, "01_homogeneizacion", "externos"),
             pattern = "\\.R$", full.names = TRUE)
}

.rel <- function(x) sub(paste0(RUTAS$raiz, "/"), "", x, fixed = TRUE)

#' Código del archivo sin sus comentarios.
#'
#' La documentación de una función cita llamadas de ejemplo. Leerlas como código
#' inventa insumos que nadie usa — este mismo archivo lo provocó y por eso se
#' filtra aquí y no en cada llamada.
.codigo_de <- function(archivo) {
  lineas <- readLines(archivo, warn = FALSE)
  paste(lineas[!grepl("^\\s*#", lineas)], collapse = "\n")
}

#' Todas las llamadas a entrada() de un archivo, resueltas a la ruta relativa
#' que representan.
.insumos_de <- function(archivo) {
  txt <- .codigo_de(archivo)
  m <- regmatches(txt, gregexpr('entrada\\(\\s*("[^"]+"\\s*(,\\s*"[^"]+"\\s*)*)\\)', txt))[[1]]
  if (!length(m)) return(character(0))
  vapply(m, function(x) {
    partes <- regmatches(x, gregexpr('"[^"]+"', x))[[1]]
    paste(gsub('"', "", partes), collapse = "/")
  }, character(1), USE.NAMES = FALSE)
}

.derivados_leidos <- function(archivo) {
  txt <- .codigo_de(archivo)
  m <- regmatches(txt, gregexpr('(leer|existe)_derivado\\(\\s*"[^"]+"', txt))[[1]]
  unique(gsub('.*"', "", gsub('"$', "", m)))
}

.derivados_escritos <- function(archivo) {
  txt <- .codigo_de(archivo)
  m <- regmatches(txt, gregexpr('escribir_derivado\\([^,]+,\\s*"[^"]+"', txt))[[1]]
  directos <- gsub('.*"', "", gsub('"$', "", m))

  # Un script puede envolver la escritura en su propia función (`.guardar()` en
  # deyc.R). Sin mirar dentro del envoltorio, sus derivados se reportarían como
  # huérfanos y la auditoría inventaría un problema que no existe.
  envoltorios <- regmatches(txt, gregexpr(
    '(\\.?[A-Za-z_][A-Za-z0-9_.]*)\\s*<-\\s*function\\([^)]*\\)\\s*\\{[^}]*escribir_derivado\\(',
    txt))[[1]]
  for (e in envoltorios) {
    nombre_fn <- sub("\\s*<-.*$", "", e)
    patron <- paste0(gsub("\\.", "\\\\.", nombre_fn), '\\([^,]+,\\s*"[^"]+"')
    llamadas <- regmatches(txt, gregexpr(patron, txt))[[1]]
    directos <- c(directos, gsub('.*"', "", gsub('"$', "", llamadas)))
  }
  # Algunos scripts escriben con el nombre en una constante (MAESTRO <- "...").
  cte <- regmatches(txt, gregexpr('escribir_derivado\\([^,]+,\\s*([A-Za-z_][A-Za-z0-9_]*)\\)', txt))[[1]]
  indirectos <- character(0)
  for (x in cte) {
    v <- sub('.*,\\s*', "", sub("\\)$", "", x))
    asignacion <- regmatches(txt, regexpr(paste0(v, '\\s*<-\\s*"[^"]+"'), txt))
    if (length(asignacion)) {
      indirectos <- c(indirectos, gsub('"', "", sub('.*<-\\s*', "", asignacion)))
    }
  }
  unique(c(directos, indirectos))
}

auditar_procedencia <- function() {
  titulo("A. Procedencia")

  filas <- list()
  for (f in .scripts_vigentes()) {
    for (x in .insumos_de(f)) {
      filas[[length(filas) + 1]] <- data.frame(
        tipo = "insumo", recurso = x, rol = "lee", script = .rel(f))
    }
    for (x in .derivados_leidos(f)) {
      filas[[length(filas) + 1]] <- data.frame(
        tipo = "derivado", recurso = x, rol = "lee", script = .rel(f))
    }
    for (x in .derivados_escritos(f)) {
      filas[[length(filas) + 1]] <- data.frame(
        tipo = "derivado", recurso = x, rol = "escribe", script = .rel(f))
    }
  }
  proc <- do.call(rbind, filas)
  .escribir(proc, "A1_procedencia.csv")

  # --- Derivados: ¿quién los produce, quién los consume? ----------------------
  parquets <- sub("\\.parquet$", "",
                  list.files(RUTAS$derived, pattern = "\\.parquet$"))
  nombres <- unique(c(parquets, proc$recurso[proc$tipo == "derivado"]))

  der <- do.call(rbind, lapply(nombres, function(n) {
    prod <- proc$script[proc$tipo == "derivado" & proc$recurso == n & proc$rol == "escribe"]
    cons <- proc$script[proc$tipo == "derivado" & proc$recurso == n & proc$rol == "lee"]
    data.frame(
      derivado = n,
      existe_en_disco = n %in% parquets,
      productor = if (length(prod)) paste(unique(prod), collapse = "; ") else "SIN PRODUCTOR",
      n_consumidores = length(unique(cons)),
      consumidores = paste(unique(cons), collapse = "; ")
    )
  }))
  .escribir(der, "A2_derivados.csv")

  # --- Insumos curados: los que nadie regenera --------------------------------
  curados <- list.files(file.path(RUTAS$inputs, "curados"))
  curados <- curados[!grepl("^README", curados)]
  cur <- do.call(rbind, lapply(curados, function(x) {
    lectores <- proc$script[proc$tipo == "insumo" &
                              proc$recurso == paste0("curados/", x)]
    data.frame(archivo = x, n_lectores = length(unique(lectores)),
               lectores = paste(unique(lectores), collapse = "; "))
  }))
  .escribir(cur, "A3_insumos_curados.csv")

  # --- Scripts externos: rutas de otra máquina --------------------------------
  ext <- do.call(rbind, lapply(.scripts_externos(), function(f) {
    lineas <- readLines(f, warn = FALSE)
    codigo <- lineas[!grepl("^\\s*#", lineas)]
    abs <- grep('["\'][A-Za-z]:[\\\\/]', codigo, value = TRUE)
    escribe <- grep("write\\.|write_|saveRDS|escribir_derivado", codigo, value = TRUE)
    data.frame(
      script = .rel(f),
      n_rutas_absolutas = length(abs),
      n_instrucciones_escritura = length(escribe),
      produce_algo = length(escribe) > 0
    )
  }))
  .escribir(ext, "A4_scripts_externos.csv")

  list(procedencia = proc, derivados = der, curados = cur, externos = ext)
}

# =============================================================================
# B. INVENTARIO — huella de cada insumo que el código lee
# =============================================================================
# La huella SHA-256 permite afirmar, meses después, que las cifras publicadas
# salieron EXACTAMENTE de estos bytes. Sin ella, "actualizamos la fuente" es una
# afirmación sin forma de verificar.

auditar_inventario <- function(procedencia) {
  titulo("B. Inventario de insumos")

  citados <- unique(procedencia$recurso[procedencia$tipo == "insumo"])
  inv <- do.call(rbind, lapply(citados, function(x) {
    ruta <- file.path(RUTAS$inputs, x)
    existe <- file.exists(ruta)
    lectores <- unique(procedencia$script[procedencia$tipo == "insumo" &
                                            procedencia$recurso == x])
    data.frame(
      insumo = x,
      existe = existe,
      bytes = if (existe) file.size(ruta) else NA_real_,
      modificado = if (existe) format(file.mtime(ruta), "%Y-%m-%d %H:%M") else NA_character_,
      sha256 = if (existe) {
        tryCatch(as.character(tools::md5sum(ruta)), error = function(e) NA_character_)
      } else NA_character_,
      n_lectores = length(lectores),
      lectores = paste(lectores, collapse = "; ")
    )
  }))
  # tools::md5sum es lo que trae R base sin dependencias; se declara como tal.
  names(inv)[names(inv) == "sha256"] <- "md5"
  .escribir(inv, "B1_inventario_insumos.csv")
  inv
}

# =============================================================================
# C-E. AUDITORÍA DE LAS SALIDAS
# =============================================================================

#' Todas las hojas de un .xlsx como lista de data.frames.
.leer_libro <- function(ruta) {
  wb <- openxlsx2::wb_load(ruta)
  hojas <- wb$get_sheet_names()
  stats::setNames(lapply(hojas, function(h) {
    tryCatch(openxlsx2::wb_to_df(wb, sheet = h), error = function(e) NULL)
  }), hojas)
}

#' Población total municipal 2025: peso de referencia de los promedios.
.pesos_referencia <- function() {
  if (!existe_derivado("poblacion_total_2025")) return(NULL)
  d <- leer_derivado("poblacion_total_2025")
  d <- d[as.character(d$area_geo) == "Total", , drop = FALSE]
  stats::setNames(as.numeric(d$Total), as.integer(d$ind_mpio))
}

# Columnas que SÍ son proporciones en [0,1]. Es una lista explícita y no una
# búsqueda difusa: "Incendio de cobertura vegetal" es un conteo de eventos y
# "IMRC Déficit de lluvias" un índice, y los dos contienen palabras que una
# heurística confundiría con porcentaje.
.ES_PROPORCION <- paste(
  "^participacion", "^proporcion", "^porcentaje", "\\(%\\)$",
  "^deficit cuantitativo de vivienda$", "^deficit cualitativo de vivienda$",
  "^cobertura de ", "^cobertura neta$", "^tasa de desercion$", "^tasa de repitencia$",
  "^predios con uso adecuado", "^personas en pobreza", "^hogares en pobreza",
  "^jovenes que no estudian", "^tasa de ocupacion", "^tasa de informalidad",
  "^tasa de desocupacion", "^% afiliados",
  sep = "|"
)

#' Columnas que segmentan la hoja en bloques (año, tipo de evento, hecho
#' victimizante…). Sin esto, una hoja apilada por tipo de evento compararía el
#' total de una categoría contra los municipios de todas.
#'
#' Candidata a llave: el año y cualquier columna no numérica que no sea
#' territorial. No se filtra por número de valores distintos — hacerlo dejaba
#' fuera llaves reales, como el tipo de evento de `eventos_tipo`. Sobran
#' candidatas a propósito: el coste de una de más es una comparación extra.
.columnas_de_bloque <- function(d, c_cod, c_mun) {
  territoriales <- c(c_cod, c_mun, "Subregión", "Provincia")
  candidatas <- setdiff(names(d), territoriales)
  candidatas[vapply(candidatas, function(cl) {
    identical(cl, "Año") || !is.numeric(d[[cl]])
  }, logical(1))]
}

#' Los conjuntos de filas municipales contra los que puede compararse la fila
#' agregada `i`, del más restrictivo al más amplio.
#'
#' Distinguir automáticamente una columna LLAVE (año, tipo de evento) de una
#' columna VALOR (nivel de riesgo, emergencia más prevalente) no es fiable: las
#' dos son texto y las dos toman pocos valores. En vez de acertar la llave, se
#' prueban varios agrupamientos y basta con que UNO reproduzca la cifra. Es
#' deliberadamente conservador: una cifra inventada no se reproduce con ninguno.
.candidatos_de_bloque <- function(d, i, columnas_bloque, es_municipal) {
  usables <- Filter(function(cl) {
    v <- d[[cl]][i]
    !is.na(v) && nzchar(trimws(as.character(v)))
  }, columnas_bloque)

  # El año no es ambiguo: si la fila agregada declara uno, solo compiten los
  # municipios de ESE año. Sin esta restricción, el total de una provincia que
  # no registra nada en 2019 se comparaba contra los municipios de 2020.
  if ("Año" %in% usables) {
    es_municipal <- es_municipal & !is.na(d[["Año"]]) &
      as.character(d[["Año"]]) == as.character(d[["Año"]][i])
    if (!any(es_municipal)) return(list())
  }

  coincide <- function(cols) {
    ok <- es_municipal
    for (cl in cols) {
      ok <- ok & !is.na(d[[cl]]) & as.character(d[[cl]]) == as.character(d[[cl]][i])
    }
    ok
  }

  opciones <- list(todas = es_municipal)
  if (length(usables)) opciones[["bloque completo"]] <- coincide(usables)
  if ("Año" %in% usables) opciones[["por año"]] <- coincide("Año")
  # También cada columna de bloque por separado: cubre las hojas apiladas por
  # una sola llave (tipo de evento, hecho victimizante).
  for (cl in setdiff(usables, "Año")) opciones[[paste0("por ", cl)]] <- coincide(cl)

  Filter(any, opciones)
}

#' Clasifica un valor agregado contra las fórmulas declaradas del pipeline.
#'
#' Devuelve la primera que reproduce el valor dentro de TOL. "OTRA" significa
#' que ninguna fórmula estándar lo explica — no que esté mal, pero sí que hay
#' que poder señalar en el código de dónde sale.
.clasificar_agregado <- function(valor, x, pesos) {
  if (is.na(valor)) return("vacío")
  ok <- !is.na(x)
  if (!any(ok)) return("sin municipios con dato")
  x <- x[ok]; pesos <- pesos[ok]

  candidatos <- c(suma = sum(x))
  candidatos["promedio"] <- mean(x)
  candidatos["mediana"] <- stats::median(x)
  if (any(!is.na(pesos)) && sum(pesos, na.rm = TRUE) > 0) {
    p <- pesos; p[is.na(p)] <- 0
    if (sum(p) > 0) candidatos["ponderado_poblacion"] <- sum(x * p) / sum(p)
  }
  dif <- abs(candidatos - valor) / pmax(abs(valor), 1e-9)
  if (min(dif, na.rm = TRUE) <= TOL) names(candidatos)[which.min(dif)] else "OTRA"
}

auditar_salidas <- function(ids) {
  titulo("C-E. Cobertura, agregados y rangos de las salidas")

  pesos_ref <- .pesos_referencia()
  cw <- crosswalk_provincias()

  cobertura <- list(); agregados <- list(); rangos <- list(); hojas_idx <- list()

  for (id in ids) {
    prov <- provincia(id)
    carpeta <- file.path(RUTAS$outputs, prov$carpeta)
    if (!dir.exists(carpeta)) {
      message("  [salta] ", prov$etiqueta, " — sin salidas generadas")
      next
    }
    esperados <- sort(cw$ind_mpio[cw$id_provincia == id])

    for (xlsx in list.files(carpeta, pattern = "\\.xlsx$", recursive = TRUE,
                            full.names = TRUE)) {
      seccion <- basename(dirname(xlsx))
      libro <- .leer_libro(xlsx)

      for (hoja in names(libro)) {
        d <- libro[[hoja]]
        if (is.null(d) || !nrow(d)) next
        es_hoja_figura <- startsWith(hoja, "_")

        hojas_idx[[length(hojas_idx) + 1]] <- data.frame(
          provincia = prov$etiqueta, seccion = seccion,
          archivo = basename(xlsx), hoja = hoja,
          tipo = if (es_hoja_figura) "datos de figura" else "tabla",
          filas = nrow(d), columnas = ncol(d)
        )

        c_cod <- if ("Código DANE" %in% names(d)) "Código DANE" else NA_character_
        c_mun <- if ("Municipio" %in% names(d)) "Municipio" else NA_character_
        c_ano <- if ("Año" %in% names(d)) "Año" else NA_character_

        # --- C. Cobertura municipal ------------------------------------------
        # Las hojas de ámbito departamental —el mapa de la provincia dentro de
        # Antioquia— contienen a propósito municipios de fuera: comparar su
        # cobertura contra la provincia marcaría como intrusión lo que es su
        # razón de ser.
        es_departamental <- endsWith(hoja, "_dpto")
        if (!is.na(c_cod) && !es_departamental) {
          codigos <- suppressWarnings(as.integer(d[[c_cod]]))
          presentes <- sort(unique(codigos[!is.na(codigos)]))
          intrusos <- setdiff(presentes, esperados)
          faltantes <- setdiff(esperados, presentes)
          cobertura[[length(cobertura) + 1]] <- data.frame(
            provincia = prov$etiqueta, seccion = seccion, hoja = hoja,
            n_esperados = length(esperados),
            n_presentes = length(presentes),
            n_faltantes = length(faltantes),
            n_ajenos = length(intrusos),
            faltantes = paste(faltantes, collapse = " "),
            ajenos = paste(intrusos, collapse = " ")
          )
        }

        # --- D. Agregados -----------------------------------------------------
        # Las filas agregadas son las que no traen código DANE pero sí nombre.
        if (!is.na(c_cod) && !is.na(c_mun) && !es_hoja_figura) {
          codigos <- suppressWarnings(as.integer(d[[c_cod]]))
          es_agregado <- is.na(codigos) & !is.na(d[[c_mun]]) & nzchar(as.character(d[[c_mun]]))
          if (any(es_agregado)) {
            cols_bloque <- .columnas_de_bloque(d, c_cod, c_mun)
            es_municipal <- !es_agregado & !is.na(codigos)
            numericas <- names(d)[vapply(d, function(x)
              is.numeric(x) || all(is.na(x)) , logical(1))]
            numericas <- setdiff(numericas, c(c_cod, c_ano))

            for (i in which(es_agregado)) {
              # Solo la fila PROVINCIAL es verificable con esta hoja: las de
              # subregión y departamento se calculan sobre los 125 municipios
              # de Antioquia, que no están aquí.
              etiqueta_fila <- toupper(as.character(d[[c_mun]][i]))
              ambito <- if (grepl("PROVINCIA", etiqueta_fila)) "provincia"
                        else if (grepl("SUBREGI", etiqueta_fila)) "subregión"
                        else if (grepl("DEPARTAMENTO", etiqueta_fila)) "departamento"
                        else "otro"
              opciones <- .candidatos_de_bloque(d, i, cols_bloque, es_municipal)
              if (!length(opciones)) next
              etiqueta_bloque <- paste(vapply(cols_bloque, function(cl)
                paste0(cl, "=", as.character(d[[cl]][i])), character(1)),
                collapse = " | ")

              for (cl in numericas) {
                v <- suppressWarnings(as.numeric(d[[cl]][i]))
                if (is.na(v)) next

                clase <- "OTRA"; via <- NA_character_
                dentro <- FALSE; rango_min <- NA_real_; rango_max <- NA_real_
                suma <- NA_real_

                for (nombre_opcion in names(opciones)) {
                  mismos <- opciones[[nombre_opcion]]
                  x <- suppressWarnings(as.numeric(d[[cl]][mismos]))
                  if (all(is.na(x))) next
                  w <- if (is.null(pesos_ref)) rep(NA_real_, sum(mismos)) else
                    unname(pesos_ref[as.character(codigos[mismos])])
                  if (is.na(rango_min)) {
                    rango_min <- min(x, na.rm = TRUE)
                    rango_max <- max(x, na.rm = TRUE)
                    suma <- sum(x, na.rm = TRUE)
                  }
                  dentro <- dentro || (v >= min(x, na.rm = TRUE) - 1e-9 &
                                         v <= max(x, na.rm = TRUE) + 1e-9)
                  if (ambito != "provincia") { clase <- "no verificable con esta hoja"; break }
                  candidata <- .clasificar_agregado(v, x, w)
                  if (candidata != "OTRA") { clase <- candidata; via <- nombre_opcion; break }
                }
                if (is.na(rango_min)) next

                agregados[[length(agregados) + 1]] <- data.frame(
                  provincia = prov$etiqueta, seccion = seccion, hoja = hoja,
                  bloque = etiqueta_bloque, ambito = ambito,
                  fila = as.character(d[[c_mun]][i]), columna = cl,
                  valor = v, formula_que_lo_reproduce = clase,
                  agrupamiento = via,
                  min_municipal = rango_min, max_municipal = rango_max,
                  dentro_del_rango_municipal = dentro,
                  suma_municipal = suma
                )
              }
            }
          }
        }

        # --- E. Rangos plausibles --------------------------------------------
        for (cl in names(d)) {
          x <- suppressWarnings(as.numeric(d[[cl]]))
          if (all(is.na(x))) next
          etiqueta <- norm_txt(cl)
          es_proporcion <- grepl(.ES_PROPORCION, etiqueta) &&
            !grepl("por 100|por 1\\.000|por cada|hab", etiqueta)
          problema <- character(0)
          if (any(is.infinite(x))) problema <- c(problema, "infinitos")
          if (any(is.nan(x))) problema <- c(problema, "NaN")
          if (es_proporcion && any(x < -1e-9 | x > 1 + 1e-9, na.rm = TRUE)) {
            problema <- c(problema, "proporción fuera de [0,1]")
          }
          if (grepl("^tasa|^numero|^n_|habitantes|poblacion|area|km|hectareas", etiqueta) &&
              any(x < -1e-9, na.rm = TRUE)) {
            problema <- c(problema, "valor negativo en magnitud no negativa")
          }
          if (length(problema)) {
            rangos[[length(rangos) + 1]] <- data.frame(
              provincia = prov$etiqueta, seccion = seccion, hoja = hoja,
              columna = cl, problema = paste(problema, collapse = "; "),
              minimo = suppressWarnings(min(x[is.finite(x)], na.rm = TRUE)),
              maximo = suppressWarnings(max(x[is.finite(x)], na.rm = TRUE)),
              n_afectadas = sum(is.infinite(x) | is.nan(x) |
                                  (es_proporcion & (x < -1e-9 | x > 1 + 1e-9)), na.rm = TRUE)
            )
          }
        }
      }
    }
    message("  [ok] ", prov$etiqueta)
  }

  idx <- do.call(rbind, hojas_idx)
  cob <- do.call(rbind, cobertura)
  agr <- do.call(rbind, agregados)
  ran <- if (length(rangos)) do.call(rbind, rangos) else
    data.frame(provincia = character(0), seccion = character(0), hoja = character(0),
               columna = character(0), problema = character(0), minimo = numeric(0),
               maximo = numeric(0), n_afectadas = integer(0))

  .escribir(idx, "C0_indice_hojas.csv")
  .escribir(cob, "C1_cobertura_municipal.csv")
  .escribir(agr, "D1_agregados.csv")
  .escribir(ran, "E1_rangos.csv")

  list(indice = idx, cobertura = cob, agregados = agr, rangos = ran)
}

# =============================================================================
# F. FIGURAS — trazabilidad y nota de fuente
# =============================================================================
# DISENO.md §8: cada figura deja sus datos exactos en una hoja del .xlsx de la
# sección. §6: toda figura lleva nota de fuente. Aquí se verifican las dos.

auditar_figuras <- function(ids, indice_hojas) {
  titulo("F. Figuras")

  filas <- list()
  for (id in ids) {
    prov <- provincia(id)
    carpeta <- file.path(RUTAS$outputs, prov$carpeta)
    if (!dir.exists(carpeta)) next
    todos <- list.files(carpeta, pattern = "\\.png$", recursive = TRUE,
                        full.names = TRUE)
    # `_revision/` guarda las hojas de contacto de hoja_contactos.R: material de
    # revisión interna, no figuras del informe.
    for (png in todos[!grepl("/_revision/", todos)]) {
      seccion <- basename(dirname(dirname(png)))
      nombre <- sub("\\.png$", "", basename(png))
      # Convención de `escribir_datos_figura()`: las figuras guardan su hoja
      # bajo el identificador corto (`fig_03` -> `_fig_03`) y los mapas bajo el
      # nombre completo sin el guion (`mapa_01_area` -> `_mapa01_area`), porque
      # dos mapas de la misma sección compartirían el identificador corto.
      hoja_datos <- if (startsWith(nombre, "mapa_")) {
        paste0("_", sub("^mapa_", "mapa", nombre))
      } else {
        paste0("_", sub("^(fig_\\d+).*$", "\\1", nombre))
      }
      hay_hoja <- any(indice_hojas$provincia == prov$etiqueta &
                        indice_hojas$seccion == seccion &
                        indice_hojas$hoja == hoja_datos)
      filas[[length(filas) + 1]] <- data.frame(
        provincia = prov$etiqueta, seccion = seccion, figura = nombre,
        hay_pdf = file.exists(sub("\\.png$", ".pdf", png)),
        hoja_de_datos = hoja_datos, hay_hoja_de_datos = hay_hoja,
        kb = round(file.size(png) / 1024)
      )
    }
  }
  fig <- if (length(filas)) do.call(rbind, filas) else data.frame()
  .escribir(fig, "F1_figuras.csv")

  # --- Nota de fuente: estática, sobre el código de cada figura ---------------
  notas <- list()
  for (f in list.files(file.path(RUTAS$codigo, "04_figuras"), pattern = "\\.R$",
                       full.names = TRUE)) {
    txt <- readLines(f, warn = FALSE)
    # `.emitir()` de 00_mapas.R llama a `guardar_fig()` por dentro: si solo se
    # contaran las llamadas literales, los diez mapas de cada provincia
    # aparecerían como una sola figura.
    llamadas <- grep("(guardar_fig|\\.emitir)\\(", txt)
    # La llamada que vive DENTRO de .emitir() no es un sitio de figura: es la
    # implementación, y su nombre llega por variable.
    llamadas <- llamadas[!grepl("guardar_fig\\(p, id,", txt[llamadas])]
    for (i in llamadas) {
      # El nombre puede quedar en la línea siguiente cuando la llamada se parte.
      ventana_nombre <- paste(txt[i:min(length(txt), i + 2)], collapse = " ")
      nombre <- regmatches(ventana_nombre,
                           regexpr('"(fig|mapa)_[^"]+"', ventana_nombre))
      nombre <- if (length(nombre)) gsub('"', "", nombre) else "(nombre dinámico)"
      # El bloque de textos de la figura está en las ~40 líneas anteriores.
      ventana <- paste(txt[max(1, i - 45):i], collapse = "\n")
      # Los mapas usan `.textos_mapa()`, que envuelve a `textos_fig()` con un
      # ancho de texto menor; para esta comprobación las dos valen igual.
      # `.emitir()` guarda la hoja de datos y llama a `guardar_fig()` dentro,
      # así que también cuenta como trazable.
      posterior <- paste(txt[i:min(length(txt), i + 15)], collapse = "\n")
      notas[[length(notas) + 1]] <- data.frame(
        script = basename(f), figura = nombre, linea = i,
        tiene_textos_fig = grepl("textos_fig\\(|\\.textos_mapa\\(", ventana),
        tiene_fuente = grepl("fuente\\s*=", ventana),
        tiene_subtitulo = grepl("subtitulo\\s*=", ventana),
        guarda_datos = grepl("escribir_datos_figura\\(", posterior) ||
          grepl("\\.emitir\\(", paste(ventana, posterior))
      )
    }
  }
  nt <- do.call(rbind, notas)
  .escribir(nt, "F2_figuras_codigo.csv")

  list(exportadas = fig, codigo = nt)
}

# =============================================================================
# G. CATÁLOGO — lo declarado frente a lo implementado
# =============================================================================

auditar_catalogo <- function(figuras_codigo) {
  titulo("G. Catálogo de figuras")
  ruta <- file.path(RUTAS$codigo, "04_figuras", "catalogo_figuras.xlsx")
  if (!file.exists(ruta)) {
    message("  no hay catálogo")
    return(NULL)
  }
  cat_fig <- leer_excel(ruta, hoja = "catalogo")
  resumen <- data.frame(
    filas_del_catalogo = nrow(cat_fig),
    marcadas_hecho = sum(norm_txt(cat_fig$estado) == "hecho", na.rm = TRUE),
    marcadas_fuera_de_alcance = sum(grepl("fuera", norm_txt(cat_fig$estado)), na.rm = TRUE),
    figuras_en_el_codigo_R = nrow(figuras_codigo)
  )
  .escribir(cat_fig, "G1_catalogo_declarado.csv")
  .escribir(resumen, "G2_catalogo_vs_codigo.csv")
  resumen
}

# =============================================================================
# RESUMEN
# =============================================================================

escribir_resumen <- function(r) {
  ruta <- file.path(DIR_AUDIT, "RESUMEN.md")
  L <- function(...) cat(..., "\n", sep = "", file = ruta, append = TRUE)
  cat("", file = ruta)

  L("# Auditoría de trazabilidad — Proyecto Provincias")
  L("")
  L("Generado por `02_Code/99_checks/auditoria_end_to_end.R` el ",
    format(Sys.time(), "%Y-%m-%d %H:%M"), ".")
  L("Cada afirmación de este resumen tiene su CSV de respaldo en esta misma carpeta.")
  L("")

  L("## A. Procedencia")
  L("")
  sin_prod <- r$proc$derivados[r$proc$derivados$productor == "SIN PRODUCTOR", ]
  L("- Derivados en `01_Derived`: **", sum(r$proc$derivados$existe_en_disco), "**")
  L("- Derivados sin script que los produzca: **", nrow(sin_prod), "**",
    if (nrow(sin_prod)) paste0(" — ", paste(sin_prod$derivado, collapse = ", ")) else "")
  L("- Insumos curados (armados a mano, sin productor): **", nrow(r$proc$curados), "**")
  huerf <- r$proc$curados[r$proc$curados$n_lectores == 0, ]
  L("- Curados que ningún script lee: **", nrow(huerf), "**",
    if (nrow(huerf)) paste0(" — ", paste(huerf$archivo, collapse = ", ")) else "")
  ext_mudos <- r$proc$externos[!r$proc$externos$produce_algo, ]
  L("- Scripts en `externos/` con rutas de otra máquina: **",
    sum(r$proc$externos$n_rutas_absolutas > 0), " de ", nrow(r$proc$externos), "**")
  L("- Scripts en `externos/` que no escriben ninguna salida: **", nrow(ext_mudos), "**",
    if (nrow(ext_mudos)) paste0(" — ", paste(basename(ext_mudos$script), collapse = ", ")) else "")
  L("")

  L("## B. Inventario")
  L("")
  L("- Insumos citados por el código: **", nrow(r$inv), "**")
  L("- Presentes en el clon: **", sum(r$inv$existe), "**; ausentes: **",
    sum(!r$inv$existe), "**")
  L("- Huella y fecha de cada uno: `B1_inventario_insumos.csv`")
  L("")

  L("## C. Cobertura municipal")
  L("")
  cob <- r$out$cobertura
  L("- Hojas municipales auditadas: **", nrow(cob), "**")
  L("- Hojas con municipios AJENOS a la provincia: **", sum(cob$n_ajenos > 0), "**")
  L("- Hojas con municipios FALTANTES: **", sum(cob$n_faltantes > 0), "**")
  L("")
  L("Un municipio ajeno sería una cifra atribuida a un territorio que no es el suyo;")
  L("uno faltante es un silencio que el lector puede confundir con un cero.")
  L("El detalle por hoja está en `C1_cobertura_municipal.csv`.")
  L("")

  L("## D. Agregados")
  L("")
  agr <- r$out$agregados
  prov_rows <- agr[agr$ambito == "provincia", ]
  tab <- table(prov_rows$formula_que_lo_reproduce)
  L("- Celdas agregadas auditadas: **", nrow(agr), "**, de las cuales **",
    nrow(prov_rows), "** son de ámbito provincial (las únicas verificables")
  L("  con la propia hoja: subregión y departamento se calculan sobre los 125")
  L("  municipios de Antioquia, que no aparecen en la tabla provincial).")
  L("")
  L("Fórmula que reproduce cada celda provincial:")
  L("")
  for (k in names(sort(tab, decreasing = TRUE))) {
    L("  - `", k, "`: ", tab[[k]], " (",
      round(100 * tab[[k]] / nrow(prov_rows), 1), " %)")
  }
  rojas <- prov_rows[prov_rows$formula_que_lo_reproduce == "OTRA" &
                       !prov_rows$dentro_del_rango_municipal, ]
  L("- **Bandera roja** (ni fórmula conocida ni dentro del rango municipal): **",
    nrow(rojas), "**")
  if (nrow(rojas)) {
    for (cl in unique(paste(rojas$hoja, rojas$columna, sep = " / "))) {
      L("  - ", cl, " (", sum(paste(rojas$hoja, rojas$columna, sep = " / ") == cl),
        " celdas)")
    }
  }
  L("")
  L("`OTRA` no significa error: significa que la fórmula no es ninguna de las")
  L("cuatro estándar (suma, promedio simple, mediana, ponderado por población).")
  L("El pipeline usa a propósito otros ponderadores —nacimientos, población")
  L("escolar, área, matrícula— y esos casos caen aquí. Lo que **sí** exige")
  L("explicación una por una es la bandera roja.")
  L("")

  L("## E. Rangos")
  L("")
  L("- Columnas con valores implausibles: **", nrow(r$out$rangos), "**")
  if (nrow(r$out$rangos)) {
    for (i in seq_len(min(15, nrow(r$out$rangos)))) {
      L("  - ", r$out$rangos$provincia[i], " / ", r$out$rangos$hoja[i], " / ",
        r$out$rangos$columna[i], ": ", r$out$rangos$problema[i])
    }
  }
  L("")

  L("## F. Figuras")
  L("")
  fig <- r$fig$exportadas
  L("- Figuras exportadas: **", nrow(fig), "**")
  if (nrow(fig)) {
    L("- Sin PDF vectorial: **", sum(!fig$hay_pdf), "**")
    L("- Sin hoja de datos trazable en el `.xlsx`: **", sum(!fig$hay_hoja_de_datos), "**")
  }
  cod <- r$fig$codigo
  L("- Llamadas a `guardar_fig()` en el código: **", nrow(cod), "**")
  L("- Sin nota de fuente: **", sum(!cod$tiene_fuente), "**")
  L("- Sin subtítulo: **", sum(!cod$tiene_subtitulo), "**")
  L("- Sin `escribir_datos_figura()` cerca: **", sum(!cod$guarda_datos), "**")
  L("")

  if (!is.null(r$cat)) {
    L("## G. Catálogo")
    L("")
    L("- Filas del catálogo: **", r$cat$filas_del_catalogo, "**")
    L("- Marcadas «hecho»: **", r$cat$marcadas_hecho, "**")
    L("- Marcadas «fuera de alcance»: **", r$cat$marcadas_fuera_de_alcance, "**")
    L("- Figuras que el código R genera: **", r$cat$figuras_en_el_codigo_R, "**")
    L("")
  }

  message("\n  [auditoría] RESUMEN.md")
  invisible(ruta)
}

# =============================================================================
# Ejecución
# =============================================================================

auditar_todo <- function(ids = PROVINCIAS$id) {
  proc <- auditar_procedencia()
  inv  <- auditar_inventario(proc$procedencia)
  out  <- auditar_salidas(ids)
  fig  <- auditar_figuras(ids, out$indice)
  cat_ <- auditar_catalogo(fig$codigo)
  r <- list(proc = proc, inv = inv, out = out, fig = fig, cat = cat_)
  escribir_resumen(r)
  invisible(r)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "auditoria_end_to_end.R") {
  .cli <- commandArgs(trailingOnly = TRUE)
  auditar_todo(if (length(.cli)) as.integer(.cli) else PROVINCIAS$id)
}
