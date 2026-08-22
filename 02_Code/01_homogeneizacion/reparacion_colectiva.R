# =============================================================================
# reparacion_colectiva.R — Sujetos de Reparación Colectiva (UARIV), Antioquia
#
# Punto 8 de los "Verificar con el equipo" de la revisión del 21/08/2026: no
# había ninguna fuente en el repositorio para el estado de implementación de
# los instrumentos de paz (PDET, PNIS, reparación colectiva). Búsqueda web
# confirmó que UARIV no publica un dataset abierto (RUV/RNI son solo mapas
# interactivos), pero el visor ArcGIS de la UARIV
# (vgv.unidadvictimas.gov.co/sujetos/) sí permite exportar la tabla de
# atributos — Laura capturó esa consulta con el navegador (archivo .har) y
# este script reconstruye el insumo a partir de esa captura.
#
# El archivo .har en sí NO es un insumo del pipeline (no es un formato que
# entrada() sepa leer y depende de una sesión de navegador irrepetible); el
# insumo real es el .xlsx que se reconstruyó UNA VEZ a partir de él con
# 02_Code/01_homogeneizacion/externos/reparacion_colectiva_har_a_xlsx.R (ver
# ese script para cómo se hizo, igual que el resto de 01_homogeneizacion/
# externos/ documenta scripts que no corre el pipeline).
#
# HALLAZGO — responde la duda del comentario original ("no estoy segura que
# haya una relación 1 a 1" entre sujetos y planes): SÍ es prácticamente 1 a 1.
# Cada sujeto de reparación colectiva trae su propio % de avance del Plan
# Integral de Reparación Colectiva (PIRC) en una de 7 fases (Identificación →
# Caracterización del Daño → Diagnóstico del Daño → Diseño y Formulación →
# Alistamiento → Implementación → Implementado). "No Aplica" en el avance del
# PIRC significa que ese sujeto concreto no tiene todavía un plan activo (fase
# temprana), no que la relación sea de varios a uno.
#
# INPUTS:  01_Data/00_Inputs/UARIV_sujetos_reparacion_colectiva.xlsx (hoja "Datos")
#            (1.034 sujetos a nivel nacional; aquí se filtra a Antioquia)
#          01_Data/00_Inputs/códigos_municipios_clean.dta (verificación del
#            universo de 125 municipios; el insumo ya trae código DANE, así
#            que no hace falta emparejar por nombre)
# OUTPUTS: 01_Data/01_Derived/reparacion_colectiva.parquet
#          (82 filas x 8 columnas: un sujeto por fila)
#
# ETAPA DEL PIPELINE: 1. homogeneización
# =============================================================================

if (!exists("RUTAS")) {
  stop("Cargue primero la configuración:\n",
       "  source(\"02_Code/R/00_config.R\")\n",
       "o ejecute el pipeline con  Rscript 02_Code/run_all.R", call. = FALSE)
}

message("== reparación colectiva (UARIV) ==")

FASES_PIRC <- c("IDENTIFICACIÓN", "CARACTERIZACIÓN DEL DAÑO", "DIAGNÓSTICO DEL DAÑO",
                "DISEÑO Y FORMULACIÓN", "ALISTAMIENTO", "IMPLEMENTACIÓN", "IMPLEMENTADO")

bruto <- leer_excel(entrada("UARIV_sujetos_reparacion_colectiva.xlsx"), hoja = "Datos")

reparacion_colectiva <- bruto |>
  dplyr::filter(.data$dpto_cod == "05") |>
  dplyr::transmute(
    ind_mpio         = as.integer(a_numero(.data$mpio_cod)),
    nombre_sujeto    = as.character(.data$nombre_sujeto),
    tipo             = as.character(.data$tipo),
    categoria        = as.character(.data$categoria),
    estado_fase      = factor(toupper(as.character(.data$estado_fase)), levels = FASES_PIRC),
    implementado     = .data$estado_fase == "IMPLEMENTADO",
    porc_avance_pirc = a_numero(.data$porc_avance_pirc),
    pdet             = as.character(.data$pdet)
  ) |>
  dplyr::filter(!is.na(.data$ind_mpio))

stopifnot(
  "hay sujetos con fase no reconocida" = !any(is.na(reparacion_colectiva$estado_fase))
)

.municipios_125_rc <- haven::read_dta(entrada("códigos_municipios_clean.dta")) |>
  dplyr::transmute(ind_mpio = as.integer(ind_mpio))
fuera_de_universo <- setdiff(reparacion_colectiva$ind_mpio, .municipios_125_rc$ind_mpio)
if (length(fuera_de_universo)) {
  stop("Hay ind_mpio de reparación colectiva fuera de los 125 municipios de Antioquia: ",
       paste(fuera_de_universo, collapse = ", "), call. = FALSE)
}

escribir_derivado(reparacion_colectiva, "reparacion_colectiva")

message("  reparacion_colectiva: ", nrow(reparacion_colectiva), " sujetos en ",
        dplyr::n_distinct(reparacion_colectiva$ind_mpio), " municipios")
