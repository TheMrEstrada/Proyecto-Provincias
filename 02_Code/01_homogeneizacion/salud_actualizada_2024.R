# =============================================================================
# salud_actualizada_2024.R — Bajo peso y vectores con el corte 2024
#
# El tablero curado 20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx (ver
# salud_seguridad.R) publica bajo_peso con el corte 2023p y dengue/malaria/
# leishmaniasis como media móvil 2021-2023, sin que ningún script lo derive.
# Este script construye la MISMA metodología (confirmada en
# INVENTARIO_VARIABLES.xlsx, hoja "Diccionario_Base", columna "Ajuste
# necesario por tasa volátil con población pequeña": bajo_peso sin ajuste,
# los tres vectores con media móvil trianual) pero con el corte más reciente
# disponible en DATOS SALUD.xlsx: bajo_peso 2024 y vectores 2022-2024.
#
# Es DELIBERADAMENTE un derivado aparte, no un reemplazo: entra a las tablas
# de salud como hojas nuevas (bajo_peso_2024, enfermedades_tropicales_2024),
# al lado de las que ya existen, para poder comparar antes de decidir si
# reemplazan al tablero curado.
#
# INPUTS:  01_Data/00_Inputs/DATOS SALUD.xlsx
#            hoja "Peso"                    (bajo peso al nacer, 2005-2024)
#            hoja "enfermedades tropicales" (dengue/malaria/leishmaniasis,
#                                            2018-2024, con cada año aparte)
#          01_Data/00_Inputs/códigos_municipios_clean.dta
#            (125 municipios; estas dos hojas traen el nombre del municipio,
#            no el código DANE, mezclado con filas de subregión y de
#            departamento — se filtra emparejando contra este listado)
# OUTPUTS: 01_Data/01_Derived/salud_actualizada_2024.parquet
#          (hasta 125 filas x 5 columnas)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== salud actualizada 2024 (bajo peso y vectores) ==")

# --- Municipios para emparejar por NOMBRE -------------------------------------
# A diferencia del tablero curado (que trae el código DANE), las hojas de
# DATOS SALUD.xlsx usadas aquí solo traen el nombre, mezclado con filas de
# subregión ("BAJO CAUCA") y de departamento ("TOTAL DEPARTAMENTO") que no
# son municipios: se descartan porque no coinciden con ningún nombre del
# listado oficial de los 125 municipios de Antioquia.
.municipios_125 <- haven::read_dta(entrada("códigos_municipios_clean.dta")) |>
  dplyr::mutate(ind_mpio = as.integer(ind_mpio),
                nvl_label = normalizar_municipio(as.character(nvl_label))) |>
  dplyr::select(ind_mpio, nvl_label)

.emparejar_nombre <- function(nombres) {
  clave <- normalizar_municipio(nombres)
  # El listado del Excel usa nombres cortos para dos municipios (misma
  # corrección puntual que crosswalk_territorial.R hace sobre esta fuente).
  clave <- ifelse(clave == "CAROLINA", "CAROLINA DEL PRINCIPE", clave)
  clave <- ifelse(clave == "SAN VICENTE", "SAN VICENTE FERRER", clave)
  .municipios_125$ind_mpio[match(clave, .municipios_125$nvl_label)]
}

#' Hoja completa sin interpretar encabezados, todo como texto (igual que
#' .leer_hoja_cruda() de 03_tablas/09_salud.R; se repite aquí porque la
#' homogeneización corre antes de que ese script se cargue).
.leer_cruda <- function(ruta, hoja) {
  readxl::read_excel(ruta, sheet = hoja, col_names = FALSE, col_types = "text",
                     .name_repair = "minimal") |>
    as.data.frame(stringsAsFactors = FALSE)
}

#' Arrastra hacia la derecha un encabezado que solo trae valor en la primera
#' columna de cada bloque (año, o nombre de la enfermedad).
.arrastrar <- function(x) {
  for (i in seq_along(x)[-1]) {
    if (is.na(x[i]) || !nzchar(stringr::str_squish(x[i]))) x[i] <- x[i - 1]
  }
  x
}

# --- 1. Bajo peso al nacer, 2024 (sin ajuste) ---------------------------------
# Hoja "Peso": un bloque de 3 columnas por año (nacimientos totales, N° con
# bajo peso, %). El año solo aparece en la primera columna del bloque, así
# que se localiza por su valor, no por posición fija (si la fuente agrega un
# año nuevo, este código lo sigue encontrando).
.bajo_peso_2024 <- function() {
  crudo <- .leer_cruda(entrada("DATOS SALUD.xlsx"), "Peso")
  anio  <- suppressWarnings(as.numeric(unlist(crudo[1, ])))
  j <- which(anio == 2024)
  if (!length(j)) {
    stop("No encuentro el bloque de 2024 en la hoja 'Peso' de DATOS SALUD.xlsx.",
         call. = FALSE)
  }
  col_pct <- j[1] + 2   # el bloque es [Total, N°, %]

  datos <- crudo[4:nrow(crudo), , drop = FALSE]
  tabla <- data.frame(
    ind_mpio       = .emparejar_nombre(datos[[2]]),
    bajo_peso_2024 = a_numero(datos[[col_pct]]) / 100
  )
  tabla <- tabla[!is.na(tabla$ind_mpio), , drop = FALSE]
  if (any(duplicated(tabla$ind_mpio))) {
    stop("Hay municipios duplicados al leer bajo peso 2024 ('Peso').", call. = FALSE)
  }
  message("  bajo_peso_2024: ", nrow(tabla), " municipios")
  tabla
}

# --- 2. Dengue, malaria y leishmaniasis, media móvil 2022-2024 ---------------
# Hoja "enfermedades tropicales": un bloque de 6 columnas por año (Casos y
# Tasa de cada una de las tres enfermedades); el nombre del municipio va en
# la columna que trae el rótulo "Subregión/Municipio". La hoja también trae
# un promedio 2021-2023 ya calculado (es la fuente del tablero curado, ver
# cabecera); aquí se recalcula el mismo promedio simple pero con 2022-2024.
.vectores_2022_2024 <- function() {
  crudo <- .leer_cruda(entrada("DATOS SALUD.xlsx"), "enfermedades tropicales")

  anio   <- suppressWarnings(as.numeric(.arrastrar(as.character(unlist(crudo[1, ])))))
  bloque <- norm_txt(.arrastrar(as.character(unlist(crudo[3, ]))))
  sub    <- norm_txt(as.character(unlist(crudo[4, ])))
  # La etiqueta "Subregión/Municipio" se repite en la hoja (encabeza también
  # los bloques de años más viejos, con su propia columna de nombre); se
  # toma la primera, que es la del bloque 2021-2024 usado aquí.
  nombre_col <- which(norm_txt(as.character(unlist(crudo[2, ]))) == "subregion/municipio")
  if (!length(nombre_col)) {
    stop("No encuentro la columna 'Subregión/Municipio' en 'enfermedades tropicales'.",
         call. = FALSE)
  }
  nombre_col <- nombre_col[1]

  col_tasa <- function(a, patron) {
    j <- which(!is.na(anio) & anio == a & stringr::str_detect(bloque, patron) &
                 stringr::str_detect(sub, "^tasa"))
    if (!length(j)) {
      stop("No encuentro la tasa de '", patron, "' del año ", a,
           " en la hoja 'enfermedades tropicales'.", call. = FALSE)
    }
    j[1]
  }

  datos <- crudo[5:nrow(crudo), , drop = FALSE]
  tabla <- data.frame(
    ind_mpio = .emparejar_nombre(datos[[nombre_col]])
  )
  # Se conserva el dato crudo de cada año (dengue_2022, dengue_2023, …), no
  # solo el promedio: para que el promedio se pueda auditar cifra por cifra,
  # y porque el año más reciente solo (2024) es por sí mismo un dato de
  # interés aparte de la media móvil.
  for (enf in c("dengue", "malaria", "leishmaniasis")) {
    for (a in c(2022, 2023, 2024)) {
      tabla[[paste0(enf, "_", a)]] <- a_numero(datos[[col_tasa(a, enf)]])
    }
  }
  tabla <- tabla[!is.na(tabla$ind_mpio), , drop = FALSE]
  if (any(duplicated(tabla$ind_mpio))) {
    stop("Hay municipios duplicados al leer vectores 2022-2024.", call. = FALSE)
  }

  tabla$dengue_2022_2024 <- rowMeans(tabla[c("dengue_2022", "dengue_2023", "dengue_2024")])
  tabla$malaria_2022_2024 <- rowMeans(tabla[c("malaria_2022", "malaria_2023", "malaria_2024")])
  tabla$leishmaniasis_2022_2024 <- rowMeans(tabla[c("leishmaniasis_2022", "leishmaniasis_2023", "leishmaniasis_2024")])

  message("  vectores 2022-2024 (crudo + promedio): ", nrow(tabla), " municipios")
  tabla
}

# --- Guardar --------------------------------------------------------------
salud_actualizada_2024 <- dplyr::full_join(.bajo_peso_2024(), .vectores_2022_2024(),
                                           by = "ind_mpio")

stopifnot(
  "hay municipios duplicados" = !any(duplicated(salud_actualizada_2024$ind_mpio))
)

escribir_derivado(salud_actualizada_2024, "salud_actualizada_2024")

message("  salud_actualizada_2024: ", nrow(salud_actualizada_2024), " municipios x ",
        ncol(salud_actualizada_2024), " columnas")
