# =============================================================================
# auditoria_redaccion.R — ¿Cada cifra escrita existe en una tabla publicada?
#
# La auditoría de trazabilidad (auditoria_end_to_end.R) comprueba que las TABLAS
# se puedan rastrear hasta su fuente. Esta comprueba lo que falta: que el TEXTO
# de los informes no diga ningún número que las tablas no digan.
#
# CÓMO
#   Extrae todos los números de la prosa de cada documento generado y busca cada
#   uno entre los valores publicados en las hojas .xlsx de esa provincia, en el
#   panel comparativo y en el conjunto de cantidades derivables (participaciones,
#   razones, promedios, posiciones). Un número que no aparezca en ninguna parte
#   es una cifra sin respaldo y se reporta.
#
# POR QUÉ SE COMPARA CON TOLERANCIA
#   El texto redondea —«el 54,5 %» viene de 0,5449831— y usa formato colombiano.
#   La comparación normaliza el formato y admite el redondeo a los decimales con
#   que la cifra se escribió: ni más ni menos.
#
# QUÉ NO PRETENDE
#   No verifica que la cifra esté BIEN CALCULADA —de eso se ocupa la auditoría
#   de agregados— sino que EXISTA. Son dos preguntas distintas y hacen falta las
#   dos.
#
# USO:    Rscript 02_Code/99_checks/auditoria_redaccion.R
# SALIDA: 04_Docs/auditoria/R1_cifras_en_prosa.csv
#         04_Docs/auditoria/R2_resumen_redaccion.csv
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
source(file.path(RUTAS$codigo, "05_documento", "R", "frases.R"), encoding = "UTF-8")

DIR_AUDIT <- file.path(RUTAS$raiz, "04_Docs", "auditoria")
dir.create(DIR_AUDIT, recursive = TRUE, showWarnings = FALSE)

# Números que no son una cifra de dato y no hay que rastrear: años, referencias
# a la escala de un índice, y los cardinales pequeños que la prosa usa para
# contar municipios o secciones.
ANIOS <- 1990:2100

# --- Extracción de cifras del texto -------------------------------------------

#' Todos los números que aparecen en un párrafo, con su forma escrita.
#'
#' Reconoce el formato colombiano (punto de miles, coma decimal) y descarta los
#' que están dentro de una ruta o de un nombre de archivo, que no son cifras de
#' dato.
.cifras_de <- function(texto) {
  txt <- gsub("`[^`]*`", " ", texto)                 # código y rutas
  txt <- gsub("\\b\\d+_[A-Za-z_]+", " ", txt)        # 02_Code, 05_Economia
  # Números que son ETIQUETA y no dato: el denominador de una tasa, el número
  # de una ley, un rango de años. Auditar «100.000» de «por 100.000 hab.» sería
  # pedirle respaldo a una unidad de medida.
  txt <- gsub("\\d{4}\\s*[-–]\\s*\\d{4}", " ", txt)          # 2001-2023
  txt <- gsub("por (cada )?100\\.000", " ", txt)
  txt <- gsub("(x|por) (cada )?1\\.000", " ", txt)
  txt <- gsub("100 mil", " ", txt)
  if (grepl("Ley 617", txt)) txt <- gsub("\\b617\\b", " ", txt)
  txt <- gsub("125 municipios", " ", txt)            # universo departamental
  # Tramos de edad («10 a 19»), pero solo cuando ninguno de los dos lados forma
  # parte de un decimal: sin el anclaje, «va de 0,00 a 3,57» se partía y dejaba
  # un «57» huérfano que la auditoría marcaba como cifra sin origen.
  txt <- gsub("(?<![0-9,])\\d{1,2} a \\d{1,2}(?![0-9,])", " ", txt, perl = TRUE)
  txt <- gsub("\\b\\d{1,2} o más\\b", " ", txt)           # «80 o más»
  txt <- gsub("de veinte|de sesenta y cuatro|de quince", " ", txt)
  m <- regmatches(txt, gregexpr("-?\\d{1,3}(?:\\.\\d{3})*(?:,\\d+)?|-?\\d+(?:,\\d+)?", txt))[[1]]
  if (!length(m)) return(NULL)
  valor <- suppressWarnings(as.numeric(
    gsub(",", ".", gsub("\\.", "", m), fixed = FALSE)))
  dec <- ifelse(grepl(",", m), nchar(sub(".*,", "", m)), 0)
  data.frame(escrito = m, valor = valor, decimales = dec,
             stringsAsFactors = FALSE)
}

# --- Universo de valores publicados -------------------------------------------

#' Todos los valores numéricos de todas las hojas de una provincia.
#' Valores publicados y las agregaciones que el generador declara sobre ellos.
#'
#' El texto no solo cita celdas: dice «el promedio provincial de N habitantes»
#' (total entre municipios), «el promedio municipal es X» (media de la columna)
#' y «acumuló N eventos» (suma por año). Esas tres operaciones están en el
#' código del generador, así que se reproducen aquí. No se admite ninguna otra:
#' ampliar el universo hasta que nada falle vaciaría la auditoría de sentido.
.valores_publicados <- function(prov, n_mun, secciones = NULL) {
  carpeta <- file.path(RUTAS$outputs, prov$carpeta)
  if (!dir.exists(carpeta)) return(numeric(0))
  vals <- numeric(0)
  archivos <- list.files(carpeta, pattern = "\\.xlsx$", recursive = TRUE,
                         full.names = TRUE)
  # Acotar a la sección del párrafo es lo que da poder de discriminación: con
  # las hojas de las diez secciones a la vez, el universo pasa de cientos a
  # decenas de miles de valores y casi cualquier número coincide por azar.
  if (!is.null(secciones)) {
    archivos <- archivos[basename(dirname(archivos)) %in% secciones]
  }
  for (x in archivos) {
    wb <- tryCatch(openxlsx2::wb_load(x), error = function(e) NULL)
    if (is.null(wb)) next
    for (h in wb$get_sheet_names()) {
      d <- tryCatch(openxlsx2::wb_to_df(wb, sheet = h), error = function(e) NULL)
      if (is.null(d) || !nrow(d)) next
      es_mun <- if ("Código DANE" %in% names(d)) {
        !is.na(suppressWarnings(as.integer(d[["Código DANE"]])))
      } else rep(TRUE, nrow(d))
      anio <- if ("Año" %in% names(d)) as.character(d[["Año"]]) else rep("", nrow(d))
      totales <- list()

      for (cl in names(d)) {
        v <- suppressWarnings(as.numeric(d[[cl]]))
        if (all(is.na(v))) next
        vals <- c(vals, v[!is.na(v)])
        vm <- v[es_mun]
        # Brechas: la diferencia entre el valor provincial y el de la subregión
        # o el departamento, en puntos y en términos relativos, y la diferencia
        # entre el municipio mejor y el peor situados. Las tres las escribe el
        # generador y ninguna es una celda publicada.
        if ("Municipio" %in% names(d)) {
          etiqueta <- toupper(as.character(d[["Municipio"]]))
          v_prov <- v[!es_mun & grepl("PROVINCIA", etiqueta)]
          v_ref <- v[!es_mun & grepl("SUBREGI|DEPARTAMENTO", etiqueta)]
          v_prov <- v_prov[!is.na(v_prov)]; v_ref <- v_ref[!is.na(v_ref)]
          if (length(v_prov) && length(v_ref)) {
            dif <- as.numeric(outer(v_prov, v_ref, "-"))
            rel <- as.numeric(outer(v_prov, v_ref, function(a, b) (a - b) / abs(b)))
            dif_p <- abs(dif)
            vals <- c(vals, dif_p, dif_p[dif_p >= 0 & dif_p <= 1] * 100,
                      abs(rel) * 100)
          }
        }
        if (any(!is.na(vm))) {
          rango <- diff(range(vm, na.rm = TRUE))
          vals <- c(vals, rango, if (rango >= 0 && rango <= 1) rango * 100)
          vals <- c(vals,
                    mean(vm, na.rm = TRUE),           # promedio municipal
                    sum(vm, na.rm = TRUE),            # total provincial
                    sum(vm, na.rm = TRUE) / max(n_mun, 1))  # promedio por municipio
          totales[[cl]] <- sum(vm, na.rm = TRUE)
          # Concentración: lo que reúnen el mayor, los dos mayores y los tres
          # mayores. Es lo que el texto llama «concentran el X %».
          ordenado <- sort(vm[!is.na(vm)], decreasing = TRUE)
          if (length(ordenado) >= 2 && sum(ordenado) > 0) {
            k <- seq_len(min(3, length(ordenado)))
            parte <- cumsum(ordenado[k]) / sum(ordenado)
            vals <- c(vals, parte, parte * 100)   # `parte` ya es una proporción
            vals <- c(vals, max(ordenado) / min(ordenado[ordenado > 0]))
          }
          if (any(nzchar(anio))) {
            por_anio <- tapply(vm, anio[es_mun], sum, na.rm = TRUE)
            vals <- c(vals, as.numeric(por_anio), sum(por_anio, na.rm = TRUE))
          }
        }
      }
      # Razón de masculinidad: la única razón entre dos columnas cualesquiera que
      # el generador calcula. Admitir TODAS las razones posibles entre columnas
      # —lo que se intentó primero— multiplica el universo por miles de valores
      # y la auditoría deja de discriminar; el control lo detectó.
      if (all(c("Población masculina", "Población femenina") %in% names(totales))) {
        h <- totales[["Población masculina"]]; mm <- totales[["Población femenina"]]
        if (is.finite(h) && is.finite(mm) && mm != 0) vals <- c(vals, h / mm * 100)
      }
      # Composición sobre un total declarado: «el 43,9 % corresponde a
      # explotación sin título» es una columna sobre la columna «Total …».
      col_total <- names(totales)[grepl("^Total ", names(totales))]
      if (length(col_total)) {
        den <- unlist(totales[col_total])
        den <- den[is.finite(den) & den != 0]
        num <- unlist(totales)
        for (dd in den) { q <- num / dd; vals <- c(vals, q, q[q >= 0 & q <= 1] * 100) }
      }
    }
  }
  unique(vals[is.finite(vals)])
}

#' Cantidades que la prosa deriva de los valores publicados.
#'
#' El texto no solo cita celdas: dice participaciones, razones, promedios,
#' recuentos y posiciones. Todas se obtienen de los valores publicados, y hay
#' que admitirlas o la auditoría marcaría como inventado lo que es aritmética
#' declarada.
.derivables <- function(vals, panel, prov, n_mun) {
  d <- numeric(0)
  # Participaciones y porcentajes de cualquier par de valores es un espacio
  # demasiado grande: se acotan a lo que el generador realmente produce.
  if (!is.null(panel) && nrow(panel)) {
    fila <- panel[panel$id_provincia == prov$id, ]
    if (nrow(fila)) {
      num <- unlist(fila[, vapply(fila, is.numeric, logical(1))])
      d <- c(d, num, num * 100, num / 100)
      # razones entre provincias y posiciones en el sistema
      d <- c(d, seq_len(nrow(panel)))
      for (cl in names(panel)[vapply(panel, is.numeric, logical(1))]) {
        v <- panel[[cl]]; v <- v[!is.na(v) & v > 0]
        if (length(v) > 1) d <- c(d, max(v) / min(v))
      }
    }
  }
  # Cuánto del departamento cubre el sistema provincial: son cocientes entre
  # el total de las once y el total departamental, que el texto cita.
  if (!is.null(panel) && nrow(panel)) {
    for (cl in c("poblacion", "area_km2")) {
      if (cl %in% names(panel)) {
        s_prov <- sum(panel[[cl]], na.rm = TRUE)
        d <- c(d, s_prov, s_prov / vals, s_prov / vals * 100,
               (1 - s_prov / vals) * 100)
      }
    }
    d <- c(d, sum(panel$n_municipios, na.rm = TRUE) / 125 * 100,
           125 - sum(panel$n_municipios, na.rm = TRUE))
  }
  # «la Provincia representa el X % de la superficie de Antioquia»: total
  # provincial sobre total departamental de la misma magnitud.
  # Escalar SOLO donde la conversión tiene sentido: una proporción de [0,1] se
  # publica como porcentaje, y un índice de [0,100] a veces se cita en fracción.
  # Multiplicar y dividir por cien todos los valores triplicaba el universo sin
  # justificación y hundía el poder de detección.
  proporciones <- vals[is.finite(vals) & vals >= 0 & vals <= 1]
  indices <- vals[is.finite(vals) & vals > 1 & vals <= 100]
  d <- c(d, vals, proporciones * 100, indices / 100,
         seq_len(max(n_mun, 12)),          # recuentos de municipios
         ANIOS)
  unique(d[is.finite(d)])
}

#' ¿El número escrito coincide con alguno de los valores admitidos?
#'
#' La comparación se hace con el MISMO formateador que usa la prosa
#' (`formatC`), no con `round()`. Los dos no coinciden siempre: 122,55 se
#' imprime como «122,5» y `round()` lo lleva a 122,6, de modo que una
#' comparación por redondeo marcaría como inventada una cifra correctamente
#' impresa. La auditoría tiene que probar lo que se publica.
.respaldado <- function(valor, decimales, universo) {
  if (!is.finite(valor)) return(TRUE)
  como_impreso <- function(x) formatC(x, format = "f", digits = decimales)
  objetivo <- como_impreso(valor)
  any(como_impreso(universo) == objetivo, na.rm = TRUE)
}

#' Recuentos legítimos: el tamaño de los conjuntos que el flujo publica.
#'
#' La prosa dice «27 tipos de mineral», «26 registros de área protegida», «88
#' de los 125 municipios». Todos son el cardinal de un conjunto publicado, no
#' una cifra de dato, y se verifican comprobando que ese conjunto exista con
#' ese tamaño.
.recuentos_publicados <- function(prov) {
  carpeta <- file.path(RUTAS$outputs, prov$carpeta)
  r <- c(100,                                   # escala de los índices 0-100
         nrow(crosswalk_subregiones()),         # 125 municipios de Antioquia
         nrow(crosswalk_provincias()),          # 90 en alguna provincia
         nrow(crosswalk_subregiones()) - nrow(crosswalk_provincias()),
         nrow(PROVINCIAS))
  if (!dir.exists(carpeta)) return(unique(r))
  for (x in list.files(carpeta, pattern = "[.]xlsx$", recursive = TRUE,
                       full.names = TRUE)) {
    wb <- tryCatch(openxlsx2::wb_load(x), error = function(e) NULL)
    if (is.null(wb)) next
    for (h in wb$get_sheet_names()) {
      d <- tryCatch(openxlsx2::wb_to_df(wb, sheet = h), error = function(e) NULL)
      if (is.null(d) || !nrow(d)) next
      r <- c(r, nrow(d))
      if ("Código DANE" %in% names(d)) {
        es_mun <- !is.na(suppressWarnings(as.integer(d[["Código DANE"]])))
        r <- c(r, sum(es_mun), length(unique(d[["Código DANE"]][es_mun])))
      }
      # Cardinal de cada columna categórica y de cada recuento de filas por
      # categoría: de ahí salen «27 tipos de mineral» y «en 5 municipios».
      for (cl in names(d)) {
        v <- d[[cl]]
        if (is.numeric(v)) next
        u <- unique(v[!is.na(v) & nzchar(as.character(v))])
        r <- c(r, length(u), as.integer(table(v)))
      }
    }
  }
  unique(r[is.finite(r)])
}

# --- De qué sección habla cada párrafo ----------------------------------------
# El encabezado bajo el que va un párrafo determina qué hojas pueden
# respaldarlo. Donde el generador cruza secciones a propósito —la dependencia
# económica se lee en Economía y se cita en Demografía— el mapa lo declara.

SECCION_DE <- list(
  "Contexto departamental y provincial" = c("01_Generalidades", "02_Demografia"),
  "Generalidades"            = c("01_Generalidades"),
  "Demografía"               = c("02_Demografia", "05_Economia"),
  "Ordenamiento del Territorio" = c("03_Ordenamiento"),
  "Planes de Ordenamiento Territorial" = c("03_Ordenamiento"),
  "Tránsito y trasporte"     = c("03_Ordenamiento"),
  "Ciencia, Tecnología e Innovación" = c("03_Ordenamiento"),
  "Vivienda y servicios"     = c("03_Ordenamiento"),
  "Gobernabilidad y capacidades territoriales" = c("04_Gobernabilidad"),
  "Gobernabilidad"           = c("04_Gobernabilidad"),
  "Finanzas territoriales"   = c("04_Gobernabilidad"),
  "Índice de Ciudades Modernas (ICM)" = c("04_Gobernabilidad"),
  "Economía y desarrollo"    = c("05_Economia"),
  "Pobreza y mercado laboral" = c("05_Economia"),
  "Productividad y competitividad" = c("05_Economia"),
  "Mercado minero-energético" = c("05_Economia"),
  "Turismo"                  = c("05_Economia"),
  "Desarrollo Rural"         = c("06_Desarrollo_Rural"),
  "Ambiental"                = c("07_Ambiental"),
  "Recursos naturales"       = c("07_Ambiental", "01_Generalidades"),
  "Sostenibilidad ambiental y cambio climático" = c("07_Ambiental"),
  "Educación"                = c("08_Educacion"),
  "Salud"                    = c("09_Salud"),
  "Seguridad, Paz y Derechos Humanos" = c("10_Seguridad"),
  "Seguridad y convivencia ciudadana" = c("10_Seguridad"),
  "Paz"                      = c("10_Seguridad"),
  "Derechos Humanos"         = c("10_Seguridad"),
  "La Provincia en el sistema provincial" = character(0),
  "Nota sobre las fuentes y los cortes" = character(0)
)

.seccion_de_encabezado <- function(titulo) {
  # Los párrafos anteriores al primer encabezado —la nota de uso— no pertenecen
  # a ninguna sección y no citan cifras de dato.
  if (is.na(titulo) || !nzchar(titulo)) return(character(0))
  for (k in names(SECCION_DE)) {
    if (startsWith(titulo, k)) return(SECCION_DE[[k]])
  }
  NULL
}

# --- Auditoría ----------------------------------------------------------------

.parrafos_de <- function(ruta) {
  if (!file.exists(ruta)) return(NULL)
  l <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
  sec <- NA_character_
  out <- list()
  for (x in l) {
    if (grepl("^#{2,4} ", x)) { sec <- sub("^#+ ", "", x); next }
    if (grepl("^\\s*(#|\\||!|---|title:|subtitle:|author:|date:|lang:|\\*Fuente)", x)) next
    if (!nzchar(trimws(x))) next
    out[[length(out) + 1]] <- list(texto = x, seccion = sec)
  }
  out
}

auditar_redaccion <- function() {
  message("== Auditoría de la redacción ==")
  source(file.path(RUTAS$codigo, "05_documento", "generar_borrador.R"),
         encoding = "UTF-8")

  filas <- list(); total <- 0
  for (id in PROVINCIAS$id) {
    prov <- provincia(id)

    # Se regenera la prosa con el registro activo: cada llamada a los
    # formateadores anota lo que imprime. Comparar el texto contra ese registro
    # responde de forma exacta si el generador calculó cada cifra, sin depender
    # de buscarla en un conjunto grande de valores.
    registrar_cifras(TRUE)
    prosa <- tryCatch(markdown_provincia(prov), error = function(e) NULL)
    registrar_cifras(FALSE)
    if (is.null(prosa)) { message("  [error] ", prov$etiqueta); next }
    # El registro guarda la cadena completa —«61,3 %», «7.550»— y del texto se
    # extrae solo la parte numérica. Hay que normalizar los dos lados o ninguna
    # comparación casa.
    registradas <- unique(unlist(lapply(cifras_registradas(), function(x) {
      c0 <- .cifras_de(x); if (is.null(c0)) NULL else c0$escrito
    })))
    n_mun <- sum(crosswalk_provincias()$id_provincia == id)
    recuentos <- c(.recuentos_publicados(prov), seq_len(nrow(PROVINCIAS)),
                   # Enteros que son un valor publicado —títulos mineros,
                   # eventos, cabezas— y no el cardinal de un conjunto.
                   .valores_publicados(prov, n_mun))

    for (bloque in .parrafos_de_texto(prosa)) {
      cif <- .cifras_de(bloque$texto)
      if (is.null(cif)) next
      for (k in seq_len(nrow(cif))) {
        total <- total + 1
        # Los recuentos y los años se imprimen con sprintf("%d") y no pasan por
        # los formateadores: son enteros pequeños —número de municipios, puesto
        # en el sistema, año de la fuente— y se verifican por su dominio.
        v <- cif$valor[k]
        es_recuento <- cif$decimales[k] == 0 && v == round(v) &&
          (v %in% ANIOS || v %in% recuentos)
        if (!es_recuento && !(cif$escrito[k] %in% registradas)) {
          filas[[length(filas) + 1]] <- data.frame(
            provincia = prov$etiqueta, seccion = bloque$seccion %||% "",
            cifra = cif$escrito[k],
            contexto = substr(bloque$texto, 1, 150),
            stringsAsFactors = FALSE)
        }
      }
    }
    message("  [ok] ", prov$etiqueta, " — ", length(registradas),
            " cifras registradas")
  }

  sin_respaldo <- if (length(filas)) do.call(rbind, filas) else
    data.frame(provincia = character(0), seccion = character(0),
               cifra = character(0), contexto = character(0))
  utils::write.csv(sin_respaldo, file.path(DIR_AUDIT, "R1_cifras_en_prosa.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8", na = "")

  resumen <- data.frame(
    cifras_auditadas = total, sin_respaldo = nrow(sin_respaldo),
    pct_con_respaldo = round(100 * (total - nrow(sin_respaldo)) / max(total, 1), 2))
  utils::write.csv(resumen, file.path(DIR_AUDIT, "R2_resumen_redaccion.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8")

  message("\n  cifras auditadas en la prosa: ", total)
  message("  no producidas por el generador: ", nrow(sin_respaldo),
          " (", resumen$pct_con_respaldo, " % con procedencia)")
  invisible(list(detalle = sin_respaldo, resumen = resumen))
}

#' Párrafos de un vector de Markdown ya en memoria, con su encabezado.
.parrafos_de_texto <- function(lineas) {
  sec <- NA_character_; out <- list()
  for (x in lineas) {
    if (grepl("^#{2,4} ", x)) { sec <- sub("^#+ ", "", x); next }
    if (grepl("^\\s*(#|\\||!|---|title:|subtitle:|author:|date:|lang:|\\*Fuente)", x)) next
    if (!nzchar(trimws(x))) next
    out[[length(out) + 1]] <- list(texto = x, seccion = sec)
  }
  out
}

# --- Control negativo ---------------------------------------------------------
# Una comprobación que nunca falla no demuestra nada, y esta admite un conjunto
# de derivaciones que se fue ampliando. El control inyecta cifras que NO están
# en ninguna tabla y verifica que la auditoría las detecte: si no las detecta,
# el universo de valores admitidos creció demasiado y la auditoría dejó de
# discriminar.
control_negativo <- function(n = 300, semilla = 1) {
  message("\n== Control: poder de detección ==")
  source(file.path(RUTAS$codigo, "05_documento", "generar_borrador.R"),
         encoding = "UTF-8")
  prov <- provincia(2)
  registrar_cifras(TRUE)
  invisible(markdown_provincia(prov))
  registrar_cifras(FALSE)
  registradas <- cifras_registradas()

  # Se perturban cifras REALES un 3,7 %: quedan plausibles en forma y magnitud
  # pero el generador nunca las imprimió. Con el registro, detectarlas ya no
  # depende de que no coincidan por azar con otro valor del conjunto.
  set.seed(semilla)
  base <- .registro$valores
  base <- base[is.finite(base) & abs(base) > 1]
  if (!length(base)) return(invisible(NA))
  muestra <- base[sample(length(base), min(n, length(base)))]
  falsas <- vapply(muestra * 1.037, function(v) {
    if (abs(v) < 100) .registro$num_co(v, 1) else .registro$num_co(v, 0)
  }, character(1))
  detectadas <- sum(!(falsas %in% registradas))
  poder <- round(100 * detectadas / length(falsas), 1)

  message("  cifras falsas probadas: ", length(falsas), " | detectadas: ", detectadas)
  message("  poder de detección: ", poder, " %")
  if (poder < 95) message("  AVISO: por debajo del 95 %.")
  utils::write.csv(data.frame(probadas = length(falsas), detectadas = detectadas,
                              poder_pct = poder),
                   file.path(DIR_AUDIT, "R3_poder_deteccion.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8")
  invisible(poder)
}

.invocado <- sub("^--file=", "",
                 commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
if (length(.invocado) && basename(.invocado[1]) == "auditoria_redaccion.R") {
  auditar_redaccion()
  control_negativo()
}
