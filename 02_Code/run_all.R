# =============================================================================
# run_all.R — Pipeline completo: de los datos crudos a las salidas por provincia
#
# USO:
#   Rscript 02_Code/run_all.R              # las 11 provincias
#   Rscript 02_Code/run_all.R 2 4 5        # solo estas provincias
#
# ETAPAS
#   1. Homogeneización  01_Data/00_Inputs  -> 01_Data/01_Derived
#   2. Tablas           derivados          -> 03_Outputs/<Prov>/<NN>/*.xlsx
#   3. Figuras          tablas             -> .../figuras/*.{png,pdf}
#
# Es idempotente: se puede volver a correr las veces que haga falta. Una etapa
# que falle por un insumo ausente no detiene el resto; el resumen final dice
# qué quedó sin correr y por qué.
# =============================================================================

# La configuración puede venir ya cargada (p. ej. si otro script hizo source de
# este); en ese caso no se vuelve a resolver la raíz.
if (!exists("RUTAS")) {
  .raiz <- Sys.getenv("PROVINCIAS_ROOT", unset = "")
  if (!nzchar(.raiz)) {
    .args <- commandArgs(trailingOnly = FALSE)
    .f <- sub("^--file=", "", .args[grepl("^--file=", .args)])
    .raiz <- if (length(.f)) dirname(dirname(normalizePath(.f[1]))) else getwd()
  }
  source(file.path(.raiz, "02_Code", "R", "00_config.R"), encoding = "UTF-8")
}
source(file.path(RUTAS$codigo, "run_provincia.R"), encoding = "UTF-8")

inicio <- Sys.time()

# --- Etapa 1: homogeneización -------------------------------------------------
# Los scripts se descubren solos: añadir una homogeneización es dejar el .R en
# 02_Code/01_homogeneizacion/, sin tocar este archivo. Lo único fijo es que el
# crosswalk territorial va primero, porque casi todo lo demás lo usa.
PRIMERO <- "crosswalk_territorial.R"
HOMOGENEIZACION <- {
  todos <- list.files(file.path(RUTAS$codigo, "01_homogeneizacion"),
                      pattern = "\\.R$")
  c(intersect(PRIMERO, todos), sort(setdiff(todos, PRIMERO)))
}

message("\n#########################################################")
message("#  ETAPA 1 — Homogeneización de insumos")
message("#########################################################")

estado_homog <- lapply(HOMOGENEIZACION, function(s) {
  ruta <- file.path(RUTAS$codigo, "01_homogeneizacion", s)
  if (!file.exists(ruta)) return(c(script = s, estado = "NO EXISTE", detalle = ""))
  r <- tryCatch({ source(ruta, encoding = "UTF-8"); NULL }, error = function(e) e)
  if (is.null(r)) {
    return(c(script = s, estado = "OK", detalle = ""))
  }
  # Que falte una de las fuentes grandes no versionadas es una situación
  # prevista, no un fallo del código: se distingue para no alarmar.
  msg <- conditionMessage(r)
  if (grepl("Falta el insumo", msg, fixed = TRUE)) {
    fuente <- basename(trimws(strsplit(msg, "\n")[[1]][2]))
    message("  [sin insumo] ", s, " — falta ", fuente)
    c(script = s, estado = "SIN INSUMO", detalle = fuente)
  } else {
    message("  [FALLO] ", s, ": ", msg)
    c(script = s, estado = "FALLO", detalle = msg)
  }
})
estado_homog <- as.data.frame(do.call(rbind, estado_homog), stringsAsFactors = FALSE)

# --- Etapas 2 y 3: tablas y figuras por provincia -----------------------------
cli <- commandArgs(trailingOnly = TRUE)
ids <- if (length(cli)) as.integer(cli) else PROVINCIAS$id

message("\n#########################################################")
message("#  ETAPAS 2 y 3 — Tablas y figuras (", length(ids), " provincias)")
message("#########################################################")

resumen <- do.call(rbind, lapply(ids, function(i) {
  r <- correr_provincia(i)
  cbind(provincia = provincia(i)$etiqueta, r)
}))

# --- Resumen final ------------------------------------------------------------
duracion <- round(as.numeric(difftime(Sys.time(), inicio, units = "mins")), 1)

message("\n#########################################################")
message("#  RESUMEN  (", duracion, " min)")
message("#########################################################")

message("\nHomogeneización:")
for (i in seq_len(nrow(estado_homog))) {
  message(sprintf("  %-30s %-11s %s", estado_homog$script[i],
                  estado_homog$estado[i], estado_homog$detalle[i]))
}
if (any(estado_homog$estado == "SIN INSUMO")) {
  message("\n  'SIN INSUMO' no es un error: son las fuentes que no caben en el",
          " repositorio.\n  Pídalas al equipo (ver el README) o siga con los",
          " derivados ya generados.")
}

message("\nSecciones por estado:")
conteo <- table(resumen$estado)
for (e in names(conteo)) message(sprintf("  %-12s %d", e, conteo[[e]]))

pendientes <- unique(resumen$seccion[resumen$estado == "PENDIENTE"])
if (length(pendientes)) {
  message("\nSecciones sin migrar todavía: ", paste(pendientes, collapse = ", "))
}
errores <- resumen[resumen$estado == "ERROR", ]
if (nrow(errores)) {
  message("\nErrores:")
  for (i in seq_len(nrow(errores))) {
    message(sprintf("  %-28s %-22s %s", errores$provincia[i], errores$seccion[i],
                    errores$detalle[i]))
  }
}
message("")
invisible(resumen)
