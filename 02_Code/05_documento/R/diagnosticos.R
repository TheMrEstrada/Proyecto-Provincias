# =============================================================================
# diagnosticos.R — Medidas derivadas que sostienen la interpretación
#
# La redacción del diagnóstico afirma cosas como «la población está muy
# concentrada» o «los municipios con mayor déficit son contiguos». Este archivo
# calcula lo que hace falta para poder afirmarlas: concentración, brecha
# interna, posición frente a la subregión y el departamento, y contigüidad
# espacial real sobre la cartografía.
#
# POR QUÉ SE CALCULA EN VEZ DE REDACTARSE
#   «Muy concentrada» sin una cifra detrás es una impresión. Aquí cada
#   calificativo sale de un umbral declarado y viaja siempre acompañado del
#   número, para que el lector pueda discrepar del adjetivo sin perder el dato.
#
# LOS UMBRALES SON CONVENCIONES DEL PROYECTO, NO ESTÁNDARES
#   Están fijados aquí, en un solo sitio, y se declaran en el anexo
#   metodológico. Cambiarlos cambia los adjetivos de los once informes a la vez.
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

# --- Umbrales -----------------------------------------------------------------
# Concentración: participación del municipio mayor en el total provincial.
UMBRAL_CONCENTRACION <- c(muy_alta = 0.35, alta = 0.22)
# Brecha interna: razón entre el valor máximo y el mínimo municipal.
UMBRAL_BRECHA <- c(muy_amplia = 5, amplia = 2.5)
# Diferencia relativa que se considera material frente a una referencia.
UMBRAL_DIFERENCIA <- 0.05

.num <- function(x) suppressWarnings(as.numeric(x))

#' Concentración de una magnitud sumable entre los municipios de la provincia.
#'
#' Devuelve la participación del mayor, la de los dos mayores y el índice de
#' Herfindahl (suma de participaciones al cuadrado), que resume en un número si
#' el peso está repartido o en pocas manos.
perfil_concentracion <- function(d, col) {
  d <- solo_municipios(d)
  if (is.null(d) || !col %in% names(d)) return(NULL)
  v <- .num(d[[col]]); ok <- !is.na(v) & v > 0
  if (sum(ok) < 2) return(NULL)
  d <- d[ok, , drop = FALSE]; v <- v[ok]
  o <- order(v, decreasing = TRUE)
  s <- v / sum(v)
  clase <- if (s[o[1]] >= UMBRAL_CONCENTRACION[["muy_alta"]]) "muy concentrada"
           else if (s[o[1]] >= UMBRAL_CONCENTRACION[["alta"]]) "concentrada"
           else "repartida"
  list(mayor = as.character(d[["Municipio"]][o[1]]),
       pct_mayor = s[o[1]],
       pct_dos = sum(s[o[1:2]]),
       nombres_dos = y_lista(as.character(d[["Municipio"]][o[1:2]])),
       hhi = sum(s^2),
       n = length(v),
       clase = clase)
}

#' Brecha interna: cuánto separa al municipio mejor situado del peor.
perfil_brecha <- function(d, col) {
  d <- solo_municipios(d)
  if (is.null(d) || !col %in% names(d)) return(NULL)
  v <- .num(d[[col]]); v <- v[!is.na(v)]
  if (length(v) < 2 || min(v) <= 0) {
    if (length(v) < 2) return(NULL)
    return(list(max = max(v), min = min(v), razon = NA_real_,
                cv = stats::sd(v) / mean(v), clase = "no calculable"))
  }
  razon <- max(v) / min(v)
  clase <- if (razon >= UMBRAL_BRECHA[["muy_amplia"]]) "muy amplia"
           else if (razon >= UMBRAL_BRECHA[["amplia"]]) "amplia"
           else "estrecha"
  list(max = max(v), min = min(v), razon = razon,
       cv = stats::sd(v) / mean(v), clase = clase)
}

#' Posición de la provincia frente a su subregión y al departamento.
#'
#' `en_puntos = TRUE` para indicadores que ya son proporciones: la diferencia se
#' expresa en puntos porcentuales, que es como se lee un indicador de cobertura.
posicion <- function(d, col, en_puntos = FALSE) {
  vp <- valor_agregado(d, col, "provincia")
  vs <- valor_agregado(d, col, "subregion")
  vd <- valor_agregado(d, col, "departamento")
  rel <- function(a, b) if (is.na(a) || is.na(b) || b == 0) NA_real_ else (a - b) / abs(b)
  dif <- function(a, b) if (is.na(a) || is.na(b)) NA_real_ else a - b
  list(prov = vp, sub = vs, dep = vd,
       rel_sub = rel(vp, vs), rel_dep = rel(vp, vd),
       dif_sub = dif(vp, vs), dif_dep = dif(vp, vd),
       en_puntos = en_puntos)
}

#' Frase de brecha frente a una referencia, con la magnitud de la diferencia.
#' Devuelve "" cuando la referencia no existe: se prefiere callar a comparar
#' contra un número que la hoja no publica.
frase_brecha <- function(pos, referencia = c("sub", "dep"), etiqueta, fmt) {
  referencia <- match.arg(referencia)
  v <- pos[[referencia]]
  rel <- pos[[if (referencia == "sub") "rel_sub" else "rel_dep"]]
  dif <- pos[[if (referencia == "sub") "dif_sub" else "dif_dep"]]
  if (is.na(v) || is.na(rel)) return("")
  # «de + el» se contrae: sin esto sale «por debajo de el departamento».
  nombre <- if (referencia == "sub") "de la subregión" else "del departamento"
  if (abs(rel) < UMBRAL_DIFERENCIA) {
    return(sprintf("en un nivel prácticamente igual al %s (%s)", nombre, fmt(v)))
  }
  sentido <- if (rel > 0) "por encima" else "por debajo"
  magnitud <- if (isTRUE(pos$en_puntos)) {
    sprintf("%s puntos porcentuales", num_co(abs(dif) * 100, 1))
  } else {
    sprintf("%s", pct_co(abs(rel) * 100, dec = 0))
  }
  sprintf("%s %s (%s), con una diferencia de %s",
          sentido, nombre, fmt(v), magnitud)
}

#' Signo de una serie municipal: si tiene negativos, ceros o solo positivos.
#'
#' Existe porque un indicador que se llama «tasa neta» no siempre lo es. En la
#' ECV, la tasa neta de migración no toma valores negativos en ningún municipio,
#' de modo que describirla como un saldo entre quienes llegan y quienes se van
#' sería atribuirle una propiedad que el dato no tiene.
perfil_signo <- function(d, col) {
  d <- solo_municipios(d)
  if (is.null(d) || !col %in% names(d)) return(NULL)
  v <- .num(d[[col]]); v <- v[!is.na(v)]
  if (!length(v)) return(NULL)
  list(n = length(v), negativos = sum(v < 0), ceros = sum(v == 0),
       positivos = sum(v > 0), min = min(v), max = max(v),
       hay_negativos = any(v < 0))
}

#' Cuántos municipios superan un valor de referencia.
cuantos_superan <- function(d, col, referencia) {
  d <- solo_municipios(d)
  if (is.null(d) || !col %in% names(d) || is.na(referencia)) return(NA_integer_)
  v <- .num(d[[col]])
  sum(v > referencia, na.rm = TRUE)
}

#' Códigos DANE de unos municipios, por nombre.
codigos_de <- function(d, nombres) {
  d <- solo_municipios(d)
  suppressWarnings(as.integer(d[["Código DANE"]][match(nombres, d[["Municipio"]])]))
}

#' ¿Los municipios señalados forman una mancha contigua?
#'
#' Se responde sobre la cartografía, no a ojo: se cuentan las fronteras
#' compartidas entre ellos y se compara con las que tendrían si estuvieran todos
#' pegados. Es la única forma honesta de escribir «el patrón es contiguo».
contiguidad <- function(prov, codigos) {
  if (!HAY_CARTOGRAFIA) return(NULL)
  codigos <- codigos[!is.na(codigos)]
  if (length(codigos) < 2) return(NULL)
  capa <- cartografia_provincia(prov)
  if (is.null(capa)) return(NULL)
  sel <- capa[capa$ind_mpio %in% codigos, ]
  if (nrow(sel) < 2) return(NULL)

  vecinos <- suppressMessages(sf::st_touches(sel))
  pares <- sum(lengths(vecinos)) / 2
  # Un grupo de n polígonos pegados en cadena tiene al menos n-1 fronteras
  # internas; con menos, hay al menos un municipio suelto.
  minimo_cadena <- nrow(sel) - 1
  aislados <- sum(lengths(vecinos) == 0)
  list(n = nrow(sel), pares = pares, aislados = aislados,
       clase = if (pares == 0) "sin vecindad entre sí"
               else if (aislados == 0 && pares >= minimo_cadena) "una mancha contigua"
               else "un patrón parcialmente contiguo")
}

#' Frase sobre la geografía del fenómeno, para acompañar al mapa.
frase_contiguidad <- function(prov, d, col, n = 3, mayor = TRUE) {
  ext <- extremos(d, col, n, mayor, function(x) num_co(x, 1))
  if (is.null(ext)) return("")
  cont <- contiguidad(prov, codigos_de(d, ext$nombres))
  if (is.null(cont)) return("")
  sprintf("En el mapa, los %d municipios con los valores más %s forman %s.",
          cont$n, if (mayor) "altos" else "bajos", cont$clase)
}

#' Reparto urbano-rural de la provincia, para el encuadre demográfico.
grado_ruralidad <- function(ctx) {
  if (is.na(ctx$rural) || is.na(ctx$poblacion) || ctx$poblacion == 0) return(NULL)
  p <- ctx$rural / ctx$poblacion
  list(pct = p,
       clase = if (p >= 0.6) "predominantemente rural"
               else if (p >= 0.4) "de equilibrio urbano-rural"
               else "predominantemente urbana")
}

#' Nota de verificación: lo que el dato no puede sostener por sí solo.
#' Son pocas y explícitas a propósito; cada una señala una afirmación que el
#' informe querría hacer y que exige conocimiento de campo.
verificar <- function(...) {
  sprintf("> **Verificar con el equipo** — %s", paste0(...))
}
