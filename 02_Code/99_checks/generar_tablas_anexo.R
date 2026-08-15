# =============================================================================
# generar_tablas_anexo.R — Tablas del anexo metodológico, desde los datos
#
# El anexo de 04_Docs no lleva ninguna cifra escrita a mano. Todas sus tablas
# se generan aquí, a partir de los CSV que produce la auditoría y del propio
# repositorio, y se escriben como fragmentos .tex que el documento incluye con
# \input{}. Si el pipeline cambia, se vuelve a correr esto y el anexo queda al
# día; nadie tiene que acordarse de actualizar un número dentro del texto.
#
# REQUIERE, en este orden:
#   Rscript 02_Code/run_all.R
#   Rscript 02_Code/99_checks/auditoria_end_to_end.R
#   Rscript 02_Code/99_checks/diccionario_indicadores.R
#
# USO:    Rscript 02_Code/99_checks/generar_tablas_anexo.R
# SALIDA: 04_Docs/tablas/*.tex  +  04_Docs/tablas/cifras.tex (macros)
#
# ETAPA DEL PIPELINE: verificación / documentación
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

DIR_AUDIT   <- file.path(RUTAS$raiz, "04_Docs", "auditoria")
DIR_TABLAS  <- file.path(RUTAS$raiz, "04_Docs", "tablas")
dir.create(DIR_TABLAS, recursive = TRUE, showWarnings = FALSE)

.csv <- function(nombre) {
  ruta <- file.path(DIR_AUDIT, nombre)
  if (!file.exists(ruta)) {
    stop("Falta ", nombre, ". Corra antes la auditoría:\n",
         "  Rscript 02_Code/99_checks/auditoria_end_to_end.R", call. = FALSE)
  }
  utils::read.csv(ruta, encoding = "UTF-8", stringsAsFactors = FALSE)
}

# --- Escapado de LaTeX --------------------------------------------------------
# Los nombres de archivo del proyecto traen guiones bajos, ampersands y signos
# de porcentaje. Sin escapar, cualquiera de los tres rompe la compilación.
.tex <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x
}

#' Escapa para LaTeX y permite cortar el texto después de cada guion bajo.
#' Un nombre como 20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA no tiene ningún otro
#' punto por donde partirse y se sale de su columna.
.partible <- function(x) gsub("\\\\_", "\\\\_\\\\allowbreak{}", .tex(x))

#' Escribe un `tabularx` a un fragmento .tex.
#'
#' @param d data.frame ya en el orden y con las columnas finales.
#' @param archivo nombre del fragmento.
#' @param encabezados textos de encabezado.
#' @param alineacion cadena de columnas de tabularx ("lXr").
#' @param nota texto al pie de la tabla (opcional).
escribir_tabla <- function(d, archivo, encabezados, alineacion, nota = NULL) {
  ruta <- file.path(DIR_TABLAS, archivo)
  con <- file(ruta, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  # Todo —celdas, encabezados y nota— entra como texto plano y se escapa aquí,
  # una sola vez. Preescapar en el origen imprimía la barra invertida.
  # Además se permite el corte tras cada guion bajo: los nombres de archivo del
  # proyecto no tienen otro punto por donde partirse y desbordan su columna.
  esc <- .partible

  wr <- function(...) cat(..., "\n", sep = "", file = con)
  wr("% Generado por 02_Code/99_checks/generar_tablas_anexo.R — no editar a mano.")
  wr("\\begin{tabularx}{\\linewidth}{", alineacion, "}")
  wr("\\toprule")
  wr(paste(paste0("\\textbf{", esc(encabezados), "}"), collapse = " & "), " \\\\")
  wr("\\midrule")
  for (i in seq_len(nrow(d))) {
    wr(paste(esc(unlist(d[i, ])), collapse = " & "), " \\\\")
  }
  wr("\\bottomrule")
  if (!is.null(nota)) {
    wr("\\addlinespace[2pt]")
    wr("\\multicolumn{", ncol(d), "}{@{}p{\\linewidth}@{}}{\\footnotesize ",
       .tex(nota), "} \\\\")
  }
  wr("\\end{tabularx}")
  message("  [tabla] ", archivo, "  (", nrow(d), " filas)")
  invisible(ruta)
}

#' Igual que `escribir_tabla()`, pero para tablas que ocupan varias páginas.
#' Repite el encabezado en cada una: un esquema de 460 filas es ilegible si hay
#' que volver a la primera página para saber qué columna se está mirando.
escribir_longtable <- function(d, archivo, encabezados, alineacion) {
  ruta <- file.path(DIR_TABLAS, archivo)
  con <- file(ruta, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  wr <- function(...) cat(..., "\n", sep = "", file = con)

  cab <- paste(paste0("\\textbf{", .tex(encabezados), "}"), collapse = " & ")
  wr("% Generado por 02_Code/99_checks/generar_tablas_anexo.R — no editar a mano.")
  wr("\\begin{longtable}{", alineacion, "}")
  wr("\\toprule ", cab, " \\\\ \\midrule")
  wr("\\endfirsthead")
  wr("\\multicolumn{", ncol(d), "}{@{}l}{\\footnotesize\\itshape ",
     "(continúa de la página anterior)} \\\\")
  wr("\\toprule ", cab, " \\\\ \\midrule")
  wr("\\endhead")
  wr("\\midrule \\multicolumn{", ncol(d), "}{r@{}}{\\footnotesize\\itshape ",
     "continúa en la página siguiente} \\\\")
  wr("\\endfoot")
  wr("\\bottomrule")
  wr("\\endlastfoot")
  for (i in seq_len(nrow(d))) {
    wr(paste(.partible(unlist(d[i, ])), collapse = " & "), " \\\\")
  }
  wr("\\end{longtable}")
  message("  [tabla] ", archivo, "  (", nrow(d), " filas, longtable)")
  invisible(ruta)
}

#' Macros con las cifras que el texto cita. El anexo escribe \cifraInsumos,
#' no "44": así ninguna cifra del documento puede quedar desactualizada.
escribir_macros <- function(macros) {
  ruta <- file.path(DIR_TABLAS, "cifras.tex")
  con <- file(ruta, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  cat("% Generado por 02_Code/99_checks/generar_tablas_anexo.R — no editar.\n",
      file = con)
  for (n in names(macros)) {
    cat("\\newcommand{\\", n, "}{", macros[[n]], "}\n", sep = "", file = con)
  }
  message("  [macros] cifras.tex  (", length(macros), " valores)")
  invisible(ruta)
}

#' Formato colombiano para las cifras del texto.
.n <- function(x) formatC(x, format = "d", big.mark = ".")

# =============================================================================
# ESTRUCTURA DE DATOS — esquemas y llaves de los derivados
# =============================================================================
# Todo se lee de los archivos, no de la documentación. Un esquema escrito a mano
# describe lo que el autor creía que había; este describe lo que hay.

.tipo_legible <- function(x) {
  switch(class(x)[1],
    integer = "entero", numeric = "decimal", double = "decimal",
    character = "texto", logical = "lógico", Date = "fecha",
    factor = "categórico", POSIXct = "fecha-hora", class(x)[1])
}

#' Llave mínima de una tabla: el conjunto más pequeño de columnas cuya
#' combinación no se repite.
#'
#' Se BUSCA, no se declara. Una llave escrita a mano puede haber dejado de serlo
#' tras una actualización de la fuente y nadie se enteraría; buscarla en cada
#' corrida convierte la llave en una propiedad verificada.
#'
#' Se prueban combinaciones de hasta `max_k` columnas, empezando por las de
#' menor cardinalidad relativa (las que parecen identificadores).
.llave_minima <- function(d, max_k = 3) {
  n <- nrow(d)
  if (!n) return(NA_character_)

  # Una columna de MEDIDA nunca es llave, aunque sus valores no se repitan: que
  # ninguna pareja (Total, Hombres) coincida es una casualidad de los datos, no
  # una propiedad de la tabla. Se excluyen los decimales, que siempre son
  # medidas, y se da preferencia a los identificadores conocidos del proyecto.
  IDENTIFICADORES <- c("ind_mpio", "codmpio", "divipola", "cod_mpio",
                       "id_provincia", "anio", "año", "ano", "area_geo",
                       "nivel", "key", "delito", "especie", "cultivo",
                       "estudio", "indicador", "municipio", "periodo")
  completas <- vapply(d, function(x) !any(is.na(x)), logical(1))
  # Es candidata si su nombre es de identificador —aunque venga como decimal,
  # que le pasa a `ind_mpio` en varios derivados— o si no es un decimal.
  es_id <- tolower(names(d)) %in% IDENTIFICADORES
  decimal <- vapply(d, function(x) is.double(x) && !is.integer(x), logical(1))
  cand <- names(d)[completas & (es_id | !decimal)]
  if (!length(cand)) return(NA_character_)

  # Primero los identificadores declarados, después el resto por cardinalidad.
  card <- vapply(d[cand], function(x) length(unique(x)) / n, numeric(1))
  es_id <- tolower(cand) %in% IDENTIFICADORES
  cand <- cand[order(!es_id, -card)]
  cand <- utils::head(cand, 12)          # el coste crece como C(n, k)

  for (k in seq_len(min(max_k, length(cand)))) {
    combos <- utils::combn(cand, k, simplify = FALSE)
    for (cl in combos) {
      if (!anyDuplicated(d[, cl, drop = FALSE])) {
        return(paste(cl, collapse = " + "))
      }
    }
  }
  NA_character_
}

#' Granularidad legible a partir de la llave detectada.
.granularidad <- function(llave) {
  if (is.na(llave)) return("no determinada")
  partes <- strsplit(llave, " \\+ ")[[1]]
  etiqueta <- c(ind_mpio = "municipio", codmpio = "municipio",
                DIVIPOLA = "municipio", Municipio = "municipio",
                anio = "año", `año` = "año", ano = "año",
                area_geo = "área geográfica", delito = "delito",
                nivel = "nivel territorial", key = "territorio",
                id_provincia = "provincia", ESTUDIO = "ola de encuesta",
                Indicador = "indicador")
  legibles <- ifelse(partes %in% names(etiqueta), etiqueta[partes], partes)
  paste("una fila por", paste(unique(legibles), collapse = " × "))
}

#' Esquema completo de los derivados: una fila por (derivado, columna).
esquemas_derivados <- function() {
  archivos <- list.files(RUTAS$derived, pattern = "\\.parquet$", full.names = TRUE)
  resumen <- list(); columnas <- list()

  for (p in archivos) {
    nombre <- sub("\\.parquet$", "", basename(p))
    d <- as.data.frame(arrow::read_parquet(p))
    llave <- .llave_minima(d)

    resumen[[length(resumen) + 1]] <- data.frame(
      derivado = nombre, filas = nrow(d), columnas = ncol(d),
      llave = if (is.na(llave)) "sin llave única" else llave,
      granularidad = .granularidad(llave),
      peso = format(structure(file.size(p), class = "object_size"),
                    units = "auto", digits = 0),
      stringsAsFactors = FALSE
    )

    for (cl in names(d)) {
      x <- d[[cl]]
      vacios <- 100 * sum(is.na(x)) / max(1, length(x))
      # Un ejemplo real vale más que la descripción del tipo: enseña la unidad,
      # la escala y el formato de una vez.
      ej <- x[!is.na(x)][1]
      ej <- if (length(ej) == 0) "" else {
        v <- if (is.numeric(ej)) formatC(ej, format = "g", digits = 6) else as.character(ej)
        if (nchar(v) > 28) paste0(substr(v, 1, 25), "...") else v
      }
      columnas[[length(columnas) + 1]] <- data.frame(
        derivado = nombre, columna = cl, tipo = .tipo_legible(x),
        distintos = length(unique(x)),
        pct_vacios = round(vacios, 1), ejemplo = ej,
        stringsAsFactors = FALSE
      )
    }
  }
  list(resumen = do.call(rbind, resumen), columnas = do.call(rbind, columnas))
}

# =============================================================================
# DAG — el grafo de procesamiento, dibujado desde la procedencia real
# =============================================================================
# Los nodos y las aristas salen de A1_procedencia.csv, que a su vez sale de leer
# el código. Un diagrama dibujado a mano envejece en silencio: este no puede
# discrepar del pipeline porque se deriva de él.

#' Ordena una capa por el baricentro de sus vecinos en la otra, que es la
#' heurística clásica para reducir cruces en un grafo por capas. Dos pasadas
#' bastan: la tercera ya casi no mueve nada.
.ordenar_por_baricentro <- function(nodos, vecinos_de, orden_otra) {
  pos <- stats::setNames(seq_along(orden_otra), orden_otra)
  bary <- vapply(nodos, function(n) {
    v <- vecinos_de[[n]]
    if (!length(v)) return(Inf)
    mean(pos[v], na.rm = TRUE)
  }, numeric(1))
  nodos[order(bary, nodos)]
}

#' Escribe un DAG por capas como figura TikZ.
#'
#' @param izq,der vectores de etiquetas de cada capa, ya ordenados.
#' @param aristas data.frame con `origen` y `destino` (etiquetas).
#' @param estilo_izq,estilo_der nombres de estilo TikZ declarados en el preámbulo.
#' @param destacar aristas que deben ir en el estilo de excepción.
.escribir_dag <- function(archivo, izq, der, aristas, estilo_izq, estilo_der,
                          ancho_izq = 6.2, ancho_der = 5.0, x_der = 10.4,
                          paso = 0.62, destacar = NULL) {
  ruta <- file.path(DIR_TABLAS, archivo)
  con <- file(ruta, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  wr <- function(...) cat(..., "\n", sep = "", file = con)

  id_izq <- stats::setNames(paste0("i", seq_along(izq)), izq)
  id_der <- stats::setNames(paste0("d", seq_along(der)), der)

  # Un nombre como 20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA no tiene ningún
  # punto donde LaTeX pueda partirlo, así que se sale de la caja. Se permite el
  # corte después de cada guion bajo, sin añadir guion de separación.
  etiqueta <- function(x) gsub("\\\\_", "\\\\_\\\\allowbreak{}", .tex(x))

  # Cada capa se centra verticalmente respecto de la otra: si una tiene 30 nodos
  # y la otra 10, dejar las dos arrancando arriba las desalinea y las aristas
  # salen todas en diagonal.
  alto <- max(length(izq), length(der)) * paso
  y0_izq <- (alto - length(izq) * paso) / 2
  y0_der <- (alto - length(der) * paso) / 2

  wr("% Generado por 02_Code/99_checks/generar_tablas_anexo.R — no editar a mano.")
  wr("\\begin{tikzpicture}[x=1cm, y=1cm]")
  for (i in seq_along(izq)) {
    wr(sprintf("\\node[%s, text width=%.1fcm] (%s) at (0,%.3f) {%s};",
               estilo_izq, ancho_izq, id_izq[[i]],
               -(y0_izq + (i - 1) * paso), etiqueta(izq[i])))
  }
  for (i in seq_along(der)) {
    wr(sprintf("\\node[%s, text width=%.1fcm] (%s) at (%.1f,%.3f) {%s};",
               estilo_der, ancho_der, id_der[[i]], x_der,
               -(y0_der + (i - 1) * paso), etiqueta(der[i])))
  }
  for (i in seq_len(nrow(aristas))) {
    o <- id_izq[[aristas$origen[i]]]; d <- id_der[[aristas$destino[i]]]
    if (is.null(o) || is.null(d)) next
    est <- if (!is.null(destacar) && destacar[i]) "flujoexcepcion" else "flujo"
    wr(sprintf("\\draw[%s] (%s.east) -- (%s.west);", est, o, d))
  }
  wr("\\end{tikzpicture}")
  message("  [dag] ", archivo, "  (", length(izq), " + ", length(der),
          " nodos, ", nrow(aristas), " aristas)")
  invisible(ruta)
}

#' Los dos DAG del anexo: la cadena de homogeneización y el consumo por sección.
generar_dags <- function(proc) {
  seccion_de <- function(script) {
    m <- regmatches(script, regexpr("03_tablas/[0-9]{2}_[a-z_]+\\.R$", script))
    if (!length(m)) return(NA_character_)
    gsub("_", " ", sub("\\.R$", "", sub("03_tablas/", "", m)))
  }

  # --- DAG 1: script de homogeneización -> derivado --------------------------
  escribe <- proc[proc$tipo == "derivado" & proc$rol == "escribe", ]
  escribe$script_corto <- basename(escribe$script)
  a1 <- data.frame(origen = escribe$script_corto, destino = escribe$recurso,
                   stringsAsFactors = FALSE)

  vecinos_der <- split(a1$origen, a1$destino)
  vecinos_izq <- split(a1$destino, a1$origen)
  izq1 <- sort(unique(a1$origen))
  der1 <- sort(unique(a1$destino))
  der1 <- .ordenar_por_baricentro(der1, vecinos_der, izq1)
  izq1 <- .ordenar_por_baricentro(izq1, vecinos_izq, der1)

  .escribir_dag("DAG1_homogeneizacion.tex", izq1, der1, a1,
                "nodoscript", "nododerivado", ancho_izq = 5.2, ancho_der = 6.8,
                x_der = 8.8, paso = 0.72)

  # --- DAG 2: recurso -> sección --------------------------------------------
  # Se dibujan las dos rutas de entrada a una sección: la que pasa por un
  # derivado del pipeline y la que lee directamente un tablero curado. Esa
  # distinción es el hallazgo estructural del proyecto y por eso el DAG la
  # marca con un estilo propio en vez de esconderla.
  lee <- proc[proc$rol == "lee" &
                grepl("03_tablas/", proc$script), ]
  lee$seccion <- vapply(lee$script, seccion_de, character(1))
  lee <- lee[!is.na(lee$seccion), ]
  # La etiqueta NO repite "(curado)": esa condición ya la lleva la arista, en
  # rojo y discontinua a la vez, así que sobrevive a una impresión en blanco y
  # negro. Repetirla en el texto solo alargaba los nombres hasta desbordar.
  lee$recurso_corto <- sub("^curados/", "", lee$recurso)
  lee <- lee[!duplicated(paste(lee$recurso_corto, lee$seccion)), ]

  a2 <- data.frame(origen = lee$recurso_corto, destino = lee$seccion,
                   curado = lee$tipo == "insumo", stringsAsFactors = FALSE)

  # Las secciones leen de tres sitios distintos y el grafo completo suma casi
  # cincuenta recursos: en una sola página los nodos quedarían a menos de 4 mm y
  # el diagrama dejaría de leerse. Se parte por grupos de secciones —no se
  # agrupan recursos— para que ninguna arista desaparezca del dibujo.
  grupos <- list(
    c("01 generalidades", "02 demografia", "03 ordenamiento",
      "04 gobernabilidad", "05 economia"),
    c("06 desarrollo rural", "07 ambiental", "08 educacion", "09 salud",
      "10 seguridad")
  )
  archivos <- c("DAG2a_consumo.tex", "DAG2b_consumo.tex")

  for (g in seq_along(grupos)) {
    sub <- a2[a2$destino %in% grupos[[g]], ]
    der2 <- sort(unique(sub$destino))
    izq2 <- .ordenar_por_baricentro(sort(unique(sub$origen)),
                                    split(sub$destino, sub$origen), der2)
    sub <- sub[order(match(sub$origen, izq2)), ]
    .escribir_dag(archivos[g], izq2, der2, sub[, c("origen", "destino")],
                  "nodorecurso", "nodoseccion", ancho_izq = 7.8, ancho_der = 4.2,
                  x_der = 11.4, paso = 0.62, destacar = sub$curado)
  }

  invisible(list(dag1 = a1, dag2 = a2))
}

# =============================================================================
generar <- function() {
  message("== Tablas del anexo metodológico ==")
  macros <- list()
  proc <- .csv("A1_procedencia.csv")

  # --- T1. Provincias y municipios -------------------------------------------
  cw <- crosswalk_provincias()
  t1 <- do.call(rbind, lapply(PROVINCIAS$id, function(i) {
    m <- cw[cw$id_provincia == i, ]
    data.frame(
      id = i,
      provincia = PROVINCIAS$etiqueta[PROVINCIAS$id == i],
      n = nrow(m),
      subregiones = paste(sort(unique(m$subregion)), collapse = ", "),
      stringsAsFactors = FALSE
    )
  }))
  escribir_tabla(
    t1, "T1_provincias.tex",
    c("Id", "Provincia", "Mpios.", "Subregiones que la componen"),
    "r>{\\raggedright\\arraybackslash}p{4.6cm}rX")
  macros$cifraMunicipios <- .n(nrow(cw))
  macros$cifraProvincias <- nrow(PROVINCIAS)

  # --- T2. Catálogo de fuentes ------------------------------------------------
  inv <- .csv("B1_inventario_insumos.csv")
  inv$carpeta <- ifelse(grepl("^curados/", inv$insumo), "Curado",
                        ifelse(grepl("/", inv$insumo), "Actualización", "Crudo"))
  inv$archivo <- basename(inv$insumo)
  # `format.object_size` no está vectorizado: hay que formatear archivo a
  # archivo, no pasarle el vector entero.
  inv$peso <- vapply(inv$bytes, function(b) {
    if (is.na(b)) return("—")
    format(structure(b, class = "object_size"), units = "auto", digits = 0)
  }, character(1))
  inv$estado <- ifelse(inv$existe == "TRUE" | inv$existe == TRUE,
                       inv$modificado, "no versionado")
  t2 <- inv[order(inv$carpeta, inv$archivo),
            c("archivo", "carpeta", "peso", "estado", "n_lectores")]
  escribir_tabla(
    t2, "T2_fuentes.tex",
    c("Archivo", "Tipo", "Peso", "Última modificación", "Scripts"),
    ">{\\raggedright\\arraybackslash}X l r l r",
    nota = paste("«Crudo»: fuente original, solo lectura. «Curado»: tablero",
                 "que el equipo arma a mano en Excel y ningún script regenera.",
                 "«Scripts»: cuántos scripts del pipeline leen el archivo.",
                 "El listado con la huella MD5 de cada archivo está en",
                 "04_Docs/auditoria/B1_inventario_insumos.csv."))
  macros$cifraInsumos <- .n(nrow(inv))
  macros$cifraInsumosPresentes <- .n(sum(inv$existe == "TRUE" | inv$existe == TRUE))
  macros$cifraInsumosAusentes <- .n(sum(!(inv$existe == "TRUE" | inv$existe == TRUE)))
  macros$cifraCurados <- .n(sum(inv$carpeta == "Curado"))

  # --- T3. Derivados y su productor -------------------------------------------
  der <- .csv("A2_derivados.csv")
  t3 <- der[order(der$productor == "SIN PRODUCTOR", der$derivado),
            c("derivado", "productor", "n_consumidores")]
  t3$productor <- ifelse(t3$productor == "SIN PRODUCTOR", "sin productor",
                         basename(gsub(";.*", "", t3$productor)))
  escribir_tabla(
    t3, "T3_derivados.tex",
    c("Derivado", "Script que lo produce", "Consumidores"),
    ">{\\raggedright\\arraybackslash}X l r",
    nota = paste("Todos los derivados se guardan en Parquet en",
                 "01_Data/01_Derived y se leen con leer_derivado()."))
  macros$cifraDerivados <- .n(sum(der$existe_en_disco == "TRUE" | der$existe_en_disco == TRUE))

  # --- T4. Reglas de agregación efectivamente usadas --------------------------
  agr <- .csv("D1_agregados.csv")
  prov_rows <- agr[agr$ambito == "provincia", ]
  tab <- as.data.frame(table(prov_rows$formula_que_lo_reproduce),
                       stringsAsFactors = FALSE)
  names(tab) <- c("formula", "celdas")
  # Texto plano: `escribir_tabla()` escapa lo que haga falta. Prescapar aquí
  # produciría dobles barras invertidas en el .tex.
  tab$pct <- formatC(100 * tab$celdas / sum(tab$celdas), format = "f", digits = 1,
                     decimal.mark = ",")
  tab$formula <- c(suma = "Suma de los municipios",
                   promedio = "Promedio simple",
                   mediana = "Mediana",
                   ponderado_poblacion = "Promedio ponderado por población",
                   OTRA = "Otro ponderador declarado en el script")[tab$formula]
  tab$celdas <- .n(tab$celdas)
  escribir_tabla(
    tab[order(-as.numeric(gsub("\\.", "", tab$celdas))), ],
    "T4_agregaciones.tex",
    c("Fórmula que reproduce el valor publicado", "Celdas", "% del total"),
    "X r r",
    nota = paste("Verificación sobre las filas de total PROVINCIAL de todas las",
                 "hojas de las once provincias. «Otro ponderador» reúne los casos",
                 "en que el pipeline pondera por nacimientos, población escolar,",
                 "área o matrícula, o recalcula una tasa agregada sobre la suma",
                 "de numeradores y denominadores."))
  macros$cifraAgregados <- .n(nrow(prov_rows))
  rojas <- prov_rows[prov_rows$formula_que_lo_reproduce == "OTRA" &
                       (prov_rows$dentro_del_rango_municipal == "FALSE" |
                          prov_rows$dentro_del_rango_municipal == FALSE), ]
  macros$cifraBanderasRojas <- .n(nrow(rojas))

  # --- T5. Cobertura documental por sección -----------------------------------
  if (file.exists(file.path(DIR_AUDIT, "H3_cobertura_documental.csv"))) {
    h3 <- .csv("H3_cobertura_documental.csv")
    h3$seccion <- gsub("_", " ", h3$seccion)
    escribir_tabla(
      h3[, c("seccion", "indicadores_publicados", "con_ficha_tecnica",
             "en_inventario")],
      "T5_cobertura_documental.tex",
      c("Sección", "Indicadores publicados", "Con ficha técnica",
        "En el inventario"),
      "X r r r",
      nota = paste("El cruce es EXACTO sobre el nombre normalizado del",
                   "indicador. Un indicador que no case queda sin respaldo",
                   "documental, que es lo que este anexo pide corregir."))
    macros$cifraIndicadores <- .n(sum(h3$indicadores_publicados))
    macros$cifraConFicha <- .n(sum(h3$con_ficha_tecnica))
  }

  # --- T6. Fuentes no versionadas ---------------------------------------------
  ausentes <- inv[!(inv$existe == "TRUE" | inv$existe == TRUE), ]
  if (nrow(ausentes)) {
    escribir_tabla(
      ausentes[, c("archivo", "lectores")], "T6_fuentes_ausentes.tex",
      c("Archivo", "Script que lo necesita"), ">{\\raggedright\\arraybackslash}X X",
      nota = paste("Estas fuentes no caben en el repositorio o contienen",
                   "microdatos que no se versionan. El pipeline sigue corriendo",
                   "sin ellas: la etapa que las usa se detiene con un mensaje",
                   "que dice cuál falta, y el resto continúa."))
  }

  # --- T7. Vacíos de cobertura municipal --------------------------------------
  cob <- .csv("C1_cobertura_municipal.csv")
  huecos <- cob[cob$n_faltantes > 0, ]
  if (nrow(huecos)) {
    resumen_huecos <- do.call(rbind, lapply(split(huecos, huecos$hoja), function(g) {
      data.frame(hoja = g$hoja[1], provincias = nrow(g),
                 faltantes = sum(g$n_faltantes), stringsAsFactors = FALSE)
    }))
    resumen_huecos <- resumen_huecos[order(-resumen_huecos$faltantes), ]
    escribir_tabla(
      resumen_huecos, "T7_cobertura_municipal.tex",
      c("Hoja", "Provincias afectadas", "Municipios sin fila"),
      "X r r",
      nota = paste("Un municipio sin fila no es un cero: es un municipio del",
                   "que la fuente no dice nada. En coca, EVOA, centrales de",
                   "generación y áreas protegidas la ausencia es informativa",
                   "—el fenómeno no existe allí—; en catastro, gobierno digital",
                   "y restitución es un vacío de la fuente."))
    macros$cifraHojasConVacios <- .n(nrow(huecos))
  }

  # --- T8. Figuras y mapas por sección ----------------------------------------
  fig <- .csv("F1_figuras.csv")
  fig$tipo <- ifelse(grepl("^mapa_", fig$figura), "Mapa", "Figura")
  por_seccion <- do.call(rbind, lapply(split(fig, fig$seccion), function(g) {
    data.frame(seccion = gsub("_", " ", g$seccion[1]),
               figuras = sum(g$tipo == "Figura") / length(unique(g$provincia)),
               mapas = sum(g$tipo == "Mapa") / length(unique(g$provincia)),
               total = nrow(g), stringsAsFactors = FALSE)
  }))
  por_seccion$figuras <- round(por_seccion$figuras)
  por_seccion$mapas <- round(por_seccion$mapas)
  escribir_tabla(
    por_seccion, "T8_figuras.tex",
    c("Sección", "Figuras por provincia", "Mapas por provincia",
      "Archivos generados"),
    "X r r r",
    nota = paste("Cada pieza se exporta en PNG a 300 dpi y en PDF vectorial, y",
                 "deja sus datos exactos en una hoja del .xlsx de la sección."))
  macros$cifraFiguras <- .n(nrow(fig))
  macros$cifraMapas <- .n(sum(fig$tipo == "Mapa"))

  # --- T9-T11. Estructura de datos -------------------------------------------
  esq <- esquemas_derivados()

  escribir_tabla(
    esq$resumen[, c("derivado", "filas", "columnas", "llave", "granularidad")],
    "T9_estructura_derivados.tex",
    c("Tabla", "Filas", "Cols.", "Llave detectada", "Granularidad"),
    ">{\\raggedright\\arraybackslash}p{4.9cm} r r >{\\raggedright\\arraybackslash}p{3.0cm} X",
    nota = paste("La llave no se declara: se busca en cada corrida probando",
                 "combinaciones de columnas hasta encontrar la más pequeña sin",
                 "repeticiones. Así deja de ser una promesa y pasa a ser una",
                 "propiedad verificada."))
  macros$cifraTablasDerivadas <- .n(nrow(esq$resumen))
  macros$cifraColumnasDerivadas <- .n(nrow(esq$columnas))
  macros$cifraSinLlave <- .n(sum(esq$resumen$llave == "sin llave única"))

  # El esquema columna a columna es largo por naturaleza: va como longtable en
  # el apéndice y, en paralelo, como CSV legible por máquina.
  utils::write.csv(esq$columnas,
                   file.path(DIR_AUDIT, "H4_esquemas_derivados.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")
  # El nombre de la tabla solo se imprime cuando cambia: repetirlo en cada una
  # de sus columnas triplicaba la altura de las filas y no añadía información.
  cols_apendice <- esq$columnas[, c("derivado", "columna", "tipo", "distintos",
                                    "pct_vacios", "ejemplo")]
  repetido <- c(FALSE, cols_apendice$derivado[-1] ==
                  cols_apendice$derivado[-nrow(cols_apendice)])
  cols_apendice$derivado[repetido] <- ""
  escribir_longtable(
    cols_apendice,
    "T10_esquemas.tex",
    c("Tabla", "Columna", "Tipo", "Distintos", "% vacíos", "Ejemplo"),
    ">{\\raggedright\\arraybackslash}p{3.1cm} >{\\raggedright\\arraybackslash}p{3.6cm} l r r >{\\raggedright\\arraybackslash}p{2.7cm}")

  # Dominio de las llaves territoriales, leído del crosswalk.
  cw2 <- crosswalk_provincias()
  sub2 <- crosswalk_subregiones()
  t11 <- data.frame(
    llave = c("ind_mpio", "id_provincia", "nvl_label", "subregion",
              "subregion_full"),
    tipo = c("entero", "entero", "texto", "texto", "texto"),
    dominio = c(
      sprintf("%d--%d (DIVIPOLA de Antioquia)",
              min(sub2$ind_mpio), max(sub2$ind_mpio)),
      sprintf("1--%d", nrow(PROVINCIAS)),
      "MAYÚSCULAS sin tildes",
      "nombre de subregión del municipio",
      "subregión DANE de los 125 municipios"),
    cardinalidad = c(
      sprintf("%d en las provincias; %d en el departamento",
              nrow(cw2), nrow(sub2)),
      .n(nrow(PROVINCIAS)),
      .n(nrow(cw2)),
      .n(length(unique(cw2$subregion))),
      .n(length(unique(sub2$subregion_full)))),
    fuente = c("códigos_municipios_clean.dta", "tabla PROVINCIAS de 00_config.R",
               "códigos_municipios_clean.dta", "MUNICIPIOS_SUBREG_PROV.xlsx",
               "MUNICIPIOS_SUBREG_PROV.xlsx"),
    stringsAsFactors = FALSE
  )
  escribir_tabla(
    t11, "T11_llaves.tex",
    c("Llave", "Tipo", "Dominio", "Cardinalidad", "Fuente de verdad"),
    "l l X >{\\raggedright\\arraybackslash}p{2.9cm} >{\\raggedright\\arraybackslash}p{3.5cm}",
    nota = paste("Todo cruce entre fuentes se hace por ind_mpio. Los nombres",
                 "solo se usan cuando la fuente no trae código, y siempre",
                 "contra el listado oficial."))

  # --- DAG -------------------------------------------------------------------
  generar_dags(proc)

  # --- Auditoría de la redacción y panel comparativo --------------------------
  if (file.exists(file.path(DIR_AUDIT, "R2_resumen_redaccion.csv"))) {
    r2 <- .csv("R2_resumen_redaccion.csv")
    macros$cifraProsaAuditada <- .n(r2$cifras_auditadas)
    macros$cifraProsaSinOrigen <- .n(r2$sin_respaldo)
    macros$cifraProsaPct <- formatC(r2$pct_con_respaldo, format = "f", digits = 2,
                                    decimal.mark = ",")
  }
  if (file.exists(file.path(DIR_AUDIT, "R3_poder_deteccion.csv"))) {
    r3 <- .csv("R3_poder_deteccion.csv")
    macros$cifraPoderDeteccion <- formatC(r3$poder_pct, format = "f", digits = 1,
                                          decimal.mark = ",")
    macros$cifraFalsasProbadas <- .n(r3$probadas)
  }
  ruta_panel <- file.path(RUTAS$raiz, "04_Docs", "comparativo",
                          "panel_provincial.csv")
  if (file.exists(ruta_panel)) {
    pp <- utils::read.csv(ruta_panel, encoding = "UTF-8", stringsAsFactors = FALSE)
    macros$cifraPanelIndicadores <- .n(sum(vapply(pp, is.numeric, logical(1))) - 1)
  }

  escribir_macros(macros)
  message("  Listo: 04_Docs/tablas/")
  invisible(macros)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "generar_tablas_anexo.R") {
  generar()
}
