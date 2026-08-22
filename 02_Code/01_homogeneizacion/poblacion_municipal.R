# =============================================================================
# poblacion_municipal.R — Población municipal 2025 (proyecciones DANE PPED)
#
# INPUTS:
#   01_Data/00_Inputs/PPED-AreaSexoEdadMun-2018-2042_VP.xlsx
#     (hoja "PobMunicipalxÁreaSexoEdad"; encabezado en la fila 9; NO versionado)
# OUTPUTS:
#   01_Data/01_Derived/poblacion_total_2025.dta
#     Antioquia 2025 por área geográfica: 125 municipios × 3 filas
#     (Total / Cabecera Municipal / Centros Poblados y Rural Disperso).
#   01_Data/01_Derived/poblacion_municipal_total_2025.dta
#     Una fila por municipio del país con estructura etaria, IDE e índice de
#     envejecimiento, en total / rural / cabecera y como proporción del total.
#   01_Data/01_Derived/poblacion_anual.dta
#     Antioquia, TODOS los años del PPED, por área geográfica. Es el
#     ponderador poblacional de las secciones que no ponderan con 2025 (la 03,
#     con 2022 y 2024). poblacion_total_2025 no se toca: sigue siendo la
#     serie con la que se publicó el informe.
#   01_Data/01_Derived/poblacion_edad_2025.dta
#     Antioquia 2025, área Total: población por sexo y por grupos decenales,
#     que es lo que publica la hoja "estructura_edad" de la sección 02. Antes
#     esa hoja leía POBLACION MUNICIPAL.xlsx —la serie que esta misma cabecera
#     declara descartada— y por eso la pirámide contradecía a la hoja
#     "poblacion" del mismo libro (Yarumal 44.770 vs. 41.884 publicados).
#     Hallazgo de Pablo (F-2-018 / F-2-018-b).
#
# ETAPA DEL PIPELINE: 1. homogeneización
# Migrado de 00_Homogeneizacion_Inputs/poblacion_municipal_2025.do
#
# El insumo no cabe en el repositorio (ver .gitignore y el README de 00_Inputs).
# Si falta, este script se detiene con un mensaje claro y el resto del pipeline
# sigue: las secciones que lo usan trabajan con los derivados ya generados.
#
# `poblacion_total_2025.dta` es la serie con la que se publicó el informe y la
# usan las secciones 02, 03 y 10. No cambie su contenido ni sus nombres de
# columna sin revisar a esos tres lectores.
#
# NOTAS DE MIGRACIÓN
#   1. El .do guardaba seis `_tmp_*.dta` junto al código y los borraba al final;
#      una corrida fallida los dejó en el repositorio. Aquí las seis tablas
#      intermedias son objetos en memoria: no se escribe nada fuera de
#      01_Derived.
#   2. El .do también guardaba `poblacion_total.dta` (todo el país, 2018-2042)
#      como paso intermedio. Nadie lo lee y no está en 01_Derived, así que aquí
#      queda solo en memoria.
#   3. La última línea del .do, `keep if departamento == "Antioquia"`, no puede
#      ejecutarse: `departamento` ya se había descartado en el paso 3. El
#      derivado publicado tiene los 1.123 municipios del país, es decir se
#      generó sin ese filtro. Se reproduce ese comportamiento; si algún día se
#      quiere solo Antioquia, hay que conservar `departamento` antes del paso 3
#      y avisar a quienes leen el archivo.
#   4. `Jov_*_0_14` se copia de `Dep_*_0_14_60_85` (así estaba en el .do y en el
#      R original), de modo que el "índice de envejecimiento" se calcula contra
#      la población dependiente, no contra la de 0 a 14 años. Es una rareza de
#      la fuente publicada; se conserva para no alterar el derivado.
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== población municipal 2025 ==")

ARCHIVO_PPED <- "PPED-AreaSexoEdadMun-2018-2042_VP.xlsx"
HOJA_PPED    <- "PobMunicipalxÁreaSexoEdad"

AREA_TOTAL    <- "Total"
AREA_RURAL    <- "Centros Poblados y Rural Disperso"
AREA_CABECERA <- "Cabecera Municipal"

# --- Lectura del insumo -------------------------------------------------------
# `cellrange(A9) firstrow` del .do = encabezado en la fila 9 -> saltar 8.
ruta <- entrada(ARCHIVO_PPED)   # aborta con mensaje si no está
pped <- leer_excel(ruta, hoja = HOJA_PPED, saltar = 8)

# Las seis primeras columnas no traen nombre en la fila de encabezado; el .do
# las renombra por posición (rename A cod_dpto, rename B departamento, ...).
if (ncol(pped) < 6) {
  stop("La hoja '", HOJA_PPED, "' de ", basename(ruta), " trae ", ncol(pped),
       " columnas; se esperaban al menos 6 de identificación.", call. = FALSE)
}
names(pped)[1:6] <- c("cod_dpto", "departamento", "ind_mpio", "nvl_label",
                      "año", "area_geo")

pped <- pped |>
  dplyr::mutate(
    cod_dpto     = as.character(.data$cod_dpto),
    departamento = as.character(.data$departamento),
    nvl_label    = as.character(.data$nvl_label),
    año          = a_numero(.data$año),
    area_geo     = as.character(.data$area_geo)
  )

pob_2025 <- dplyr::filter(pped, .data$año == 2025)
if (nrow(pob_2025) == 0) {
  stop("No hay filas de 2025 en ", basename(ruta),
       ". Revise el año de la proyección o el anclaje del encabezado.",
       call. = FALSE)
}

# --- 1. poblacion_total_2025.dta (Antioquia, por área geográfica) -------------
c_total   <- col_req(pob_2025, "Total")
c_hombres <- col_req(pob_2025, "Hombres")
c_mujeres <- col_req(pob_2025, "Mujeres")

poblacion_total_2025 <- pob_2025 |>
  dplyr::filter(.data$cod_dpto == "05") |>
  dplyr::transmute(
    cod_dpto     = .data$cod_dpto,
    departamento = .data$departamento,
    ind_mpio     = a_numero(.data$ind_mpio),
    nvl_label    = .data$nvl_label,
    año          = .data$año,
    area_geo     = .data$area_geo,
    Total        = a_numero(.data[[c_total]]),
    Hombres      = a_numero(.data[[c_hombres]]),
    Mujeres      = a_numero(.data[[c_mujeres]])
  )

if (nrow(poblacion_total_2025) == 0) {
  stop("Ningún municipio con cod_dpto = \"05\" (Antioquia) en ", basename(ruta),
       ".", call. = FALSE)
}

# --- 1b. poblacion_anual.dta (Antioquia, todos los años del PPED) -------------
# Lo mismo que poblacion_total_2025 pero SIN filtrar el año. Existe porque los
# ponderadores de la sección 03 no son todos de 2025: pondera con 2022 y 2024
# además. Hasta ahora esa sección leía POBLACION MUNICIPAL.xlsx —la serie
# descartada, ver nota de cabecera— para esos dos años. Hallazgo de Pablo
# (F-2-018-b), adoptado también aquí.
poblacion_anual <- pped |>
  dplyr::filter(.data$cod_dpto == "05") |>
  dplyr::transmute(
    ind_mpio  = a_numero(.data$ind_mpio),
    nvl_label = .data$nvl_label,
    anio      = as.integer(.data$año),
    area_geo  = .data$area_geo,
    Total     = a_numero(.data[[c_total]]),
    Hombres   = a_numero(.data[[c_hombres]]),
    Mujeres   = a_numero(.data[[c_mujeres]])
  )

# --- 2. Grupos etarios --------------------------------------------------------
# Los encabezados de la fuente son "Hombres 0 años", "Hombres 1 año", ...,
# "Hombres 100 años y más". col_req() tolera las variantes de escritura.

SEXOS <- c(H = "Hombres", M = "Mujeres", T = "Total")

# Una matriz por sexo con las 101 edades simples ya en numérico. Se resuelve
# una sola vez porque col_req() recorre todos los encabezados en cada llamada.
.matriz_edades <- function(sexo) {
  etiquetas <- c(paste0(sexo, 0:99, ifelse(0:99 == 1, "año", "años")),
                 paste0(sexo, "100añosymás"))
  columnas <- vapply(etiquetas, function(e) col_req(pob_2025, e), character(1),
                     USE.NAMES = FALSE)
  m <- vapply(columnas, function(cl) a_numero(pob_2025[[cl]]),
              numeric(nrow(pob_2025)))
  m <- matrix(m, nrow = nrow(pob_2025))
  colnames(m) <- c(as.character(0:99), "100ymas")
  m
}

EDADES <- lapply(SEXOS, .matriz_edades)

#' Suma por fila de un grupo etario (equivale a `egen rowtotal`: los vacíos
#' cuentan como cero).
.total_grupo <- function(sexo, edades, incluir_100 = FALSE) {
  claves <- c(as.character(edades), if (incluir_100) "100ymas")
  rowSums(EDADES[[sexo]][, claves, drop = FALSE], na.rm = TRUE)
}

# "Inf" va entre comillas porque en R es una constante reservada.
grupos <- list(
  "Inf"  = list(edades = 0:11,  cien = FALSE),  # infancia
  "Juv"  = list(edades = 12:28, cien = FALSE),  # juventud
  "Ad"   = list(edades = 29:59, cien = FALSE),  # adultez
  "V"    = list(edades = 60:99, cien = TRUE),   # vejez (60 y más)
  "Dep"  = list(edades = c(0:14, 60:99), cien = TRUE),  # dependientes
  "Act"  = list(edades = 15:59, cien = FALSE),  # población activa
  "Enve" = list(edades = 65:99, cien = TRUE)    # envejecimiento (65 y más)
)

base <- pob_2025 |>
  dplyr::transmute(
    ind_mpio  = as.character(.data$ind_mpio),
    nvl_label = .data$nvl_label,
    area_geo  = .data$area_geo,
    T_T       = a_numero(.data[[c_total]]),
    H_T       = a_numero(.data[[c_hombres]]),
    M_T       = a_numero(.data[[c_mujeres]])
  )

for (g in names(grupos)) {
  for (s in names(SEXOS)) {
    base[[paste0(g, "_", s)]] <-
      .total_grupo(s, grupos[[g]]$edades, grupos[[g]]$cien)
  }
}

# El .do define Jov_*_0_14 como copia de Dep_*_0_14_60_85 (ver nota 4).
for (s in names(SEXOS)) base[[paste0("Jov_", s)]] <- base[[paste0("Dep_", s)]]

# --- 3. Indicadores por área geográfica ---------------------------------------
# Mismo cálculo para las tres áreas; sólo cambia el sufijo de las columnas.

.indicadores <- function(datos, area, sufijo) {
  d <- dplyr::filter(datos, .data$area_geo == area)
  s <- function(nombre) paste0(nombre, sufijo)
  porcentaje <- function(x) x / d$T_T * 100

  salida <- data.frame(ind_mpio = d$ind_mpio, nvl_label = d$nvl_label,
                       stringsAsFactors = FALSE)
  salida[[s("P_T")]] <- porcentaje(d$T_T)
  salida[[s("P_H")]] <- porcentaje(d$H_T)
  salida[[s("P_M")]] <- porcentaje(d$M_T)
  ciclos <- c(Inf_ = "P_inf_%s_0_11",  Juv_ = "P_j_%s_12_28",
              Ad_  = "P_ad_%s_29_59", V_   = "P_v_%s_60_85")
  for (s_sexo in c("T", "H", "M")) {
    for (grupo in names(ciclos)) {
      destino <- s(sprintf(ciclos[[grupo]], s_sexo))
      salida[[destino]] <- porcentaje(d[[paste0(grupo, s_sexo)]])
    }
  }
  # Índice de dependencia económica
  for (s_sexo in c("T", "H", "M")) {
    salida[[s(paste0("IDE_", s_sexo))]] <-
      d[[paste0("Dep_", s_sexo)]] / d[[paste0("Act_", s_sexo)]] * 100
  }
  # Índice de envejecimiento
  for (s_sexo in c("T", "H", "M")) {
    salida[[s(paste0("I_enve_", s_sexo))]] <-
      d[[paste0("Enve_", s_sexo)]] / d[[paste0("Jov_", s_sexo)]] * 100
  }
  salida
}

# El orden de columnas del .do es: los 15 porcentajes, luego IDE, luego el
# índice de envejecimiento. `.indicadores()` ya los genera en ese orden salvo
# que agrupa por sexo; se reordena para calcar el derivado.
.orden_bloque <- function(sufijo) {
  s <- function(x) paste0(x, sufijo)
  c(s("P_T"), s("P_H"), s("P_M"),
    s("P_inf_T_0_11"), s("P_j_T_12_28"), s("P_ad_T_29_59"), s("P_v_T_60_85"),
    s("P_inf_H_0_11"), s("P_j_H_12_28"), s("P_ad_H_29_59"), s("P_v_H_60_85"),
    s("P_inf_M_0_11"), s("P_j_M_12_28"), s("P_ad_M_29_59"), s("P_v_M_60_85"),
    s("IDE_T"), s("IDE_H"), s("IDE_M"),
    s("I_enve_T"), s("I_enve_H"), s("I_enve_M"))
}

datos_general  <- .indicadores(base, AREA_TOTAL,    "")
datos_rural    <- .indicadores(base, AREA_RURAL,    "_r")
datos_cabecera <- .indicadores(base, AREA_CABECERA, "_c")

datos_general  <- datos_general[, c("ind_mpio", "nvl_label", .orden_bloque(""))]
datos_rural    <- datos_rural[,   c("ind_mpio", .orden_bloque("_r"))]
datos_cabecera <- datos_cabecera[, c("ind_mpio", .orden_bloque("_c"))]

# El .do nombró la variable de la cabecera `I_enve_c_T` (y no `I_enve_T_c`).
# Es una inconsistencia del original, pero está en el derivado publicado.
names(datos_cabecera)[names(datos_cabecera) == "I_enve_T_c"] <- "I_enve_c_T"

# --- 4. Peso del área rural y de la cabecera sobre el total -------------------

.peso_sobre_total <- function(area, prefijo) {
  columnas <- c(T = "T_T", H = "H_T", M = "M_T",
                inf_T_0_11 = "Inf_T", j_T_12_28 = "Juv_T",
                ad_T_29_59 = "Ad_T", v_T_60_85 = "V_T",
                inf_H_0_11 = "Inf_H", j_H_12_28 = "Juv_H",
                ad_H_29_59 = "Ad_H", v_H_60_85 = "V_H",
                inf_M_0_11 = "Inf_M", j_M_12_28 = "Juv_M",
                ad_M_29_59 = "Ad_M", v_M_60_85 = "V_M")

  parte <- dplyr::filter(base, .data$area_geo == area)
  total <- dplyr::filter(base, .data$area_geo == AREA_TOTAL)
  emparejado <- match(parte$ind_mpio, total$ind_mpio)

  salida <- data.frame(ind_mpio = parte$ind_mpio, stringsAsFactors = FALSE)
  for (nombre in names(columnas)) {
    cl <- columnas[[nombre]]
    salida[[paste0(prefijo, "_", nombre)]] <-
      parte[[cl]] / total[[cl]][emparejado] * 100
  }
  salida
}

datos_p_rural  <- .peso_sobre_total(AREA_RURAL,    "PR")
datos_p_urbano <- .peso_sobre_total(AREA_CABECERA, "PU")

# --- Estructura por sexo y grupos decenales (Antioquia, área Total) ----------
# Lo que publica la hoja "estructura_edad" de la sección 02: población por
# sexo y por décadas. Hasta ahora esa hoja la tomaba de POBLACION
# MUNICIPAL.xlsx, la serie descartada (ver nota de cabecera) — Yarumal
# aparecía con 44.770 habitantes en esa hoja y con 41.884 en la de
# "poblacion" del mismo libro, ambas del mismo informe. Se construye aquí
# desde el PPED sumando las edades simples que la fuente ya trae; los grupos
# decenales son sumas exactas, no aproximación. Hallazgo de Pablo (F-2-018),
# adoptado también aquí.
DECENIOS <- list(
  edad_0_9    = list(edades =  0:9,  cien = FALSE),
  edad_10_19  = list(edades = 10:19, cien = FALSE),
  edad_20_29  = list(edades = 20:29, cien = FALSE),
  edad_30_39  = list(edades = 30:39, cien = FALSE),
  edad_40_49  = list(edades = 40:49, cien = FALSE),
  edad_50_59  = list(edades = 50:59, cien = FALSE),
  edad_60_69  = list(edades = 60:69, cien = FALSE),
  edad_70_79  = list(edades = 70:79, cien = FALSE),
  edad_80_mas = list(edades = 80:99, cien = TRUE)
)

poblacion_edad_2025 <- pob_2025 |>
  dplyr::transmute(
    ind_mpio  = a_numero(.data$ind_mpio),
    nvl_label = .data$nvl_label,
    cod_dpto  = .data$cod_dpto,
    area_geo  = .data$area_geo,
    pob_masc  = a_numero(.data[[c_hombres]]),
    pob_fem   = a_numero(.data[[c_mujeres]])
  )

for (g in names(DECENIOS)) {
  edades <- DECENIOS[[g]]$edades
  cien   <- DECENIOS[[g]]$cien
  poblacion_edad_2025[[g]] <- .total_grupo("T", edades, cien)
  poblacion_edad_2025[[sub("^edad", "h_edad", g)]] <- .total_grupo("H", edades, cien)
  poblacion_edad_2025[[sub("^edad", "m_edad", g)]] <- .total_grupo("M", edades, cien)
}

poblacion_edad_2025 <- poblacion_edad_2025 |>
  dplyr::filter(.data$cod_dpto == "05", .data$area_geo == AREA_TOTAL) |>
  dplyr::select(-"cod_dpto", -"area_geo")

# --- 5. Unir y guardar --------------------------------------------------------
poblacion_municipal <- datos_general |>
  dplyr::left_join(datos_rural,    by = "ind_mpio") |>
  dplyr::left_join(datos_cabecera, by = "ind_mpio") |>
  dplyr::left_join(datos_p_rural,  by = "ind_mpio") |>
  dplyr::left_join(datos_p_urbano, by = "ind_mpio") |>
  dplyr::arrange(.data$ind_mpio) |>
  dplyr::mutate(ind_mpio = a_numero(.data$ind_mpio))

escribir_derivado(poblacion_total_2025, "poblacion_total_2025")
escribir_derivado(poblacion_anual, "poblacion_anual")
escribir_derivado(poblacion_edad_2025, "poblacion_edad_2025")
escribir_derivado(poblacion_municipal, "poblacion_municipal_total_2025")

message("  poblacion_total_2025.dta: ", nrow(poblacion_total_2025),
        " filas (", dplyr::n_distinct(poblacion_total_2025$ind_mpio),
        " municipios de Antioquia × área geográfica)")
message("  poblacion_anual.dta: ", dplyr::n_distinct(poblacion_anual$anio),
        " años x ", dplyr::n_distinct(poblacion_anual$ind_mpio), " municipios")
message("  poblacion_edad_2025.dta: ", nrow(poblacion_edad_2025), " municipios x ",
        ncol(poblacion_edad_2025), " columnas")
message("  poblacion_municipal_total_2025.dta: ", nrow(poblacion_municipal),
        " municipios × ", ncol(poblacion_municipal), " columnas")
