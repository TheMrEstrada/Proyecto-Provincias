# =============================================================================
# 01_generalidades.R — Sección 1: Generalidades
#
# TABLA: distribución territorial de la provincia por municipio
#        (área en km² y participación en el total provincial), con los totales
#        de provincia, subregión mayoritaria y departamento.
#
# INPUTS:  01_Data/00_Inputs/AREA_ORIGINAL.xlsx  (hoja "Area")
#          crosswalks territoriales (01_Derived)
# OUTPUTS: 03_Outputs/<Provincia>/01_Generalidades/distribucion_territorial.xlsx
#
# ETAPA DEL PIPELINE: 3. tablas de diagnóstico
# Migrado de Tablas_Diagnostico/01_Generalidades.do
# =============================================================================

if (!exists("RUTAS")) stop("Cargue 02_Code/R/00_config.R antes de este script.", call. = FALSE)

tabla_generalidades <- function(prov) {
  message("== 01 Generalidades — ", prov$etiqueta, " ==")

  archivo <- file.path(dir_seccion(prov, "01_Generalidades"),
                       "distribucion_territorial.xlsx")
  if (file.exists(archivo)) unlink(archivo)

  # --- Área municipal de todo el departamento -------------------------------
  area <- leer_excel(entrada("AREA_ORIGINAL.xlsx"), hoja = "Area")
  c_cod  <- col_req(area, "COD_MPIO", "ind_mpio")
  c_area <- col_req(area, "AREA KM2", "AREAKM2", "area_km2")

  universo <- area |>
    dplyr::transmute(
      ind_mpio = as.integer(a_numero(.data[[c_cod]])),
      area_km2 = a_numero(.data[[c_area]])
    ) |>
    dplyr::filter(!is.na(ind_mpio)) |>
    con_territorio()

  # --- Municipios de la provincia y su participación ------------------------
  municipios <- universo |>
    filtrar_provincia(prov) |>
    dplyr::mutate(
      participacion_area_prov_pct = area_km2 / sum(area_km2, na.rm = TRUE)
    ) |>
    dplyr::arrange(dplyr::desc(area_km2)) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  area_km2, participacion_area_prov_pct)

  # --- Filas de total --------------------------------------------------------
  # La participación del total provincial es 1 por definición; para subregión y
  # departamento no aplica (el denominador es la provincia), y queda vacía.
  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov,
    columnas = "area_km2", como = "suma"
  ) |>
    dplyr::mutate(
      participacion_area_prov_pct = dplyr::case_when(
        tipo_fila == "Municipio"       ~ participacion_area_prov_pct,
        tipo_fila == "Total provincia" ~ 1,
        TRUE                           ~ NA_real_
      )
    ) |>
    dplyr::select(ind_mpio, municipio, subregion, provincia,
                  area_km2, participacion_area_prov_pct)

  escribir_hoja(
    tabla, archivo, "distribucion_territorial",
    etiquetas = c(
      ind_mpio = "Código DANE",
      municipio = "Municipio",
      subregion = "Subregión",
      provincia = "Provincia",
      area_km2 = "Área municipal (km²)",
      participacion_area_prov_pct = "Participación en el área provincial"
    ),
    formatos = c(area_km2 = "#,##0.0", participacion_area_prov_pct = "0.0%")
  )

  invisible(tabla)
}
