# =============================================================================
# frases.R — Redacción factual a partir de las tablas publicadas
#
# Las frases de este archivo están calcadas del Anexo 1: misma voz, misma
# estructura sintáctica, mismo orden de la información. Lo único que cambia es
# que las cifras y los nombres de municipio no se escriben a mano, se leen de
# la tabla que la sección acaba de exportar.
#
# QUÉ HACE Y QUÉ NO
#   Genera el enunciado FACTUAL: quién concentra, quién está arriba, quién
#   abajo, cómo se compara la provincia con su subregión y con el departamento.
#   NO genera interpretación —por qué importa, qué implica para el Plan—, que
#   es donde el borrador deja un marcador ESCRIBIR. Un párrafo interpretativo
#   generado automáticamente sería una afirmación sin autor.
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

# --- Lectura de las tablas publicadas ----------------------------------------

#' Una hoja del .xlsx de una sección. NULL si no está.
hoja_publicada <- function(prov, seccion, archivo, hoja) {
  ruta <- file.path(RUTAS$outputs, prov$carpeta, seccion, archivo)
  if (!file.exists(ruta)) return(NULL)
  d <- tryCatch(openxlsx2::wb_to_df(openxlsx2::wb_load(ruta), sheet = hoja),
                error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)
  d
}

#' Filas de municipio (las que traen código DANE).
solo_municipios <- function(d) {
  if (is.null(d) || !"Código DANE" %in% names(d)) return(d)
  d[!is.na(suppressWarnings(as.integer(d[["Código DANE"]]))), , drop = FALSE]
}

#' Se queda con el año más reciente si la hoja trae serie.
ultimo_anio <- function(d) {
  if (is.null(d) || !"Año" %in% names(d)) return(d)
  a <- suppressWarnings(as.numeric(d[["Año"]]))
  if (all(is.na(a))) return(d)
  d[!is.na(a) & a == max(a, na.rm = TRUE), , drop = FALSE]
}

#' Valor de una fila agregada (provincia, subregión o departamento).
#'
#' Se localiza por el texto de la columna Municipio, que es donde el pipeline
#' declara el ámbito y el método de agregación.
valor_agregado <- function(d, columna, ambito = c("provincia", "subregion",
                                                  "departamento")) {
  ambito <- match.arg(ambito)
  if (is.null(d) || !columna %in% names(d) || !"Municipio" %in% names(d)) return(NA_real_)
  patron <- switch(ambito,
    provincia = "PROVINCIA", subregion = "SUBREGI", departamento = "DEPARTAMENTO")
  i <- which(is.na(suppressWarnings(as.integer(d[["Código DANE"]]))) &
               grepl(patron, toupper(as.character(d[["Municipio"]]))))
  if (!length(i)) return(NA_real_)
  suppressWarnings(as.numeric(d[[columna]][i[1]]))
}

# --- Utilidades de redacción --------------------------------------------------

#' Enumeración en español: "a, b y c". Usa "e" antes de palabra que empieza por
#' i- ("Yarumal e Ituango"), como hace el Anexo.
y_lista <- function(x) {
  x <- x[!is.na(x) & nzchar(x)]
  n <- length(x)
  if (n == 0) return("")
  if (n == 1) return(x)
  ultimo <- x[n]
  nexo <- if (grepl("^[IiHh]i?", ultimo) && grepl("^[Ii]", ultimo)) "e" else "y"
  paste0(paste(x[-n], collapse = ", "), " ", nexo, " ", ultimo)
}

#' Los `n` municipios con mayor (o menor) valor, como texto "Nombre (valor)".
extremos <- function(d, columna, n = 2, mayor = TRUE, fmt = function(x) num_co(x, 0)) {
  d <- solo_municipios(d)
  if (is.null(d) || !columna %in% names(d)) return(NULL)
  v <- suppressWarnings(as.numeric(d[[columna]]))
  ok <- !is.na(v)
  if (!any(ok)) return(NULL)
  d <- d[ok, , drop = FALSE]; v <- v[ok]
  orden <- order(v, decreasing = mayor)
  i <- utils::head(orden, n)
  list(
    nombres = as.character(d[["Municipio"]][i]),
    valores = v[i],
    texto = y_lista(sprintf("%s (%s)", d[["Municipio"]][i], fmt(v[i])))
  )
}

#' Participación de los `n` municipios más grandes en el total provincial.
concentracion <- function(d, columna, n = 2) {
  d <- solo_municipios(d)
  v <- suppressWarnings(as.numeric(d[[columna]]))
  ok <- !is.na(v); d <- d[ok, , drop = FALSE]; v <- v[ok]
  if (!length(v)) return(NULL)
  i <- utils::head(order(v, decreasing = TRUE), n)
  list(nombres = y_lista(as.character(d[["Municipio"]][i])),
       pct = sum(v[i]) / sum(v))
}

#' "inferior al" / "superior al" / "similar al", según la comparación.
#' El umbral de 1 % evita llamar diferencia a lo que es ruido de redondeo.
comparativo <- function(valor, referencia, umbral = 0.01) {
  if (is.na(valor) || is.na(referencia) || referencia == 0) return(NA_character_)
  rel <- (valor - referencia) / abs(referencia)
  if (abs(rel) < umbral) "similar al" else if (rel > 0) "superior al" else "inferior al"
}

#' Frase de comparación con subregión y departamento, en la forma del Anexo 1.
#' Devuelve "" si la hoja no publica esos agregados: preferimos callar antes que
#' comparar contra un número que no existe.
frase_comparacion <- function(d, columna, etiqueta, fmt, subreg) {
  vp <- valor_agregado(d, columna, "provincia")
  vs <- valor_agregado(d, columna, "subregion")
  vd <- valor_agregado(d, columna, "departamento")
  if (is.na(vp)) return("")

  partes <- character(0)
  if (!is.na(vs)) {
    partes <- c(partes, sprintf("%s el promedio de la subregión %s, que alcanza %s",
                                comparativo(vp, vs), subreg, fmt(vs)))
  }
  if (!is.na(vd)) {
    partes <- c(partes, sprintf("%s el promedio departamental, ubicado en %s",
                                comparativo(vp, vd), fmt(vd)))
  }
  base <- sprintf("La Provincia registra %s de %s", etiqueta, fmt(vp))
  if (!length(partes)) return(paste0(base, "."))
  paste0(base, ", ", paste(partes, collapse = ", y "), ".")
}

#' Marcador de redacción pendiente. Es un encargo, no una sugerencia.
escribir <- function(...) sprintf("> **ESCRIBIR** — %s", paste0(...))

#' Nota de fuente, con el mismo formato que usa el Anexo 1.
fuente <- function(x) sprintf("Fuente: %s", x)

# =============================================================================
# Registro de procedencia de las cifras
# =============================================================================
# Toda cifra que aparece en la prosa pasa por `num_co()` o `pct_co()`. Con el
# registro activo, cada llamada anota el valor de entrada y la cadena que se
# imprimió. Eso convierte la pregunta «¿esta cifra existe en los datos?» —que
# solo se puede responder buscándola en un conjunto grande, con poca potencia—
# en «¿la calculó el generador?», que se responde de forma exacta.

.registro <- new.env(parent = emptyenv())
.registro$activo <- FALSE
.registro$cifras <- character(0)
.registro$valores <- numeric(0)

#' Enciende o apaga el registro, sustituyendo los formateadores por versiones
#' que anotan lo que imprimen. Se restauran los originales al apagarlo.
registrar_cifras <- function(activo = TRUE) {
  if (activo) {
    if (isTRUE(.registro$activo)) return(invisible(NULL))
    .registro$cifras <- character(0)
    .registro$valores <- numeric(0)
    .registro$num_co <- get("num_co", envir = globalenv())
    .registro$pct_co <- get("pct_co", envir = globalenv())
    assign("num_co", function(x, dec = 0) {
      r <- .registro$num_co(x, dec)
      .registro$cifras <- c(.registro$cifras, r)
      .registro$valores <- c(.registro$valores, as.numeric(x))
      r
    }, envir = globalenv())
    assign("pct_co", function(x, dec = 1, ya_en_pct = TRUE) {
      r <- .registro$pct_co(x, dec, ya_en_pct)
      .registro$cifras <- c(.registro$cifras, r)
      .registro$valores <- c(.registro$valores, as.numeric(x))
      r
    }, envir = globalenv())
    .registro$activo <- TRUE
  } else {
    if (!isTRUE(.registro$activo)) return(invisible(NULL))
    assign("num_co", .registro$num_co, envir = globalenv())
    assign("pct_co", .registro$pct_co, envir = globalenv())
    .registro$activo <- FALSE
  }
  invisible(NULL)
}

#' Las cadenas numéricas que el generador imprimió desde que se activó.
cifras_registradas <- function() unique(.registro$cifras)
