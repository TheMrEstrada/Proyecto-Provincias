# ==============================================================================#
# ANTIOQUIAS - mortalidad_iam.R
# HOMOGENIZACIÓN: Mortalidad por Infarto Agudo de Miocardio (IAM)
#
# OBJETIVO:
# Procesar datos de tasa de mortalidad por IAM (2005-2024) a nivel municipal
# para Antioquia, calculando promedio histórico de toda la serie
#
# INPUTS:  01_Data/00_Inputs/20260130_MORTALIDAD POR ENFERMEDADES NO TRANSMISIBLES TASA 05-24p.xlsx
# OUTPUTS: 01_Data/01_Derived/mortalidad_iam_dicc.xlsx (con sheet "Data")
#
# ETAPA DEL PIPELINE: 1 - Preparación y reshaping de datos
# ==============================================================================#

# ---- packages ----
rm(list = ls())
gc()

pacman::p_load(
  openxlsx,
  readxl,
  dplyr,
  stringr
)

# ---- lectura de datos ----
cat("Cargando datos de mortalidad por IAM (2005-2024)...\n")

datos_raw <- read_excel(
  "01_Data/00_Inputs/20260130_MORTALIDAD POR ENFERMEDADES NO TRANSMISIBLES TASA 05-24p.xlsx",
  sheet = "Infarto"
)

# ---- limpieza y transformación ----
cat("Filtrando y procesando municipios de Antioquia...\n")

datos_final <- datos_raw %>%
  # Filtrar solo municipios (código de 5 dígitos que empiece con "05")
  filter(
    str_detect(Código.Unidad.Geográfica, "^05"),
    nchar(Código.Unidad.Geográfica) == 5,
    Código.Unidad.Geográfica != "05000"
  ) %>%
  # Calcular promedio histórico 2005-2024
  mutate(
    tasa_iam = rowMeans(select(., `2005`:`2024`), na.rm = TRUE)
  ) %>%
  # Seleccionar y renombrar columnas finales
  select(
    ind_mpio = Código.Unidad.Geográfica,
    nvl_label = Nombre.Unidad.Geográfica,
    tasa_iam
  ) %>%
  # Normalizar nombre de municipio (mayúsculas, sin tildes)
  mutate(
    nvl_label = toupper(nvl_label),
    nvl_label = iconv(nvl_label, from = "UTF-8", to = "ASCII//TRANSLIT"),
    # Convertir a character para compatibilidad con 00_BuildData.do
    tasa_iam = as.character(round(tasa_iam, 2))
  ) %>%
  # Reemplazar "NaN" por NA si existe
  mutate(
    tasa_iam = ifelse(tasa_iam == "NaN", NA_character_, tasa_iam)
  )

cat("  ✓ Municipios procesados:", nrow(datos_final), "\n")

# ---- diagnóstico de calidad ----
tasa_num <- as.numeric(datos_final$tasa_iam)
n_validos <- sum(!is.na(tasa_num))
n_faltantes <- sum(is.na(tasa_num))

cat("\n--- DIAGNÓSTICO DE DATOS ---\n")
cat("  Municipios con datos válidos:", n_validos, "\n")
cat("  Municipios con valores faltantes:", n_faltantes, "\n")

if (n_faltantes > 0) {
  municipios_sin_dato <- datos_final %>%
    filter(is.na(as.numeric(tasa_iam))) %>%
    pull(nvl_label)
  cat("\n  Municipios sin datos:\n")
  cat(paste("    -", municipios_sin_dato, collapse = "\n"), "\n")
}

# ---- estadísticas descriptivas ----
cat("\n--- ESTADÍSTICAS (Promedio histórico 2005-2024) ---\n")
cat("  Media:              ", round(mean(tasa_num, na.rm = TRUE), 2), "\n")
cat("  Mediana:            ", round(median(tasa_num, na.rm = TRUE), 2), "\n")
cat("  Desviación estándar:", round(sd(tasa_num, na.rm = TRUE), 2), "\n")
cat("  Mínimo:             ", round(min(tasa_num, na.rm = TRUE), 2), "\n")
cat("  Máximo:             ", round(max(tasa_num, na.rm = TRUE), 2), "\n")

# Municipios extremos
muni_max <- datos_final %>%
  filter(as.numeric(tasa_iam) == max(tasa_num, na.rm = TRUE))

muni_min <- datos_final %>%
  filter(!is.na(as.numeric(tasa_iam))) %>%
  filter(as.numeric(tasa_iam) == min(tasa_num, na.rm = TRUE))

cat("\n  Tasa más alta: ", muni_max$nvl_label, " (", muni_max$tasa_iam, ")\n")
cat("  Tasa más baja: ", muni_min$nvl_label, " (", muni_min$tasa_iam, ")\n")

# ---- exportación ----
path_output <- "01_Data/01_Derived/mortalidad_iam_dicc.xlsx"

cat("\n--- EXPORTANDO DATOS ---\n")

# Crear workbook con sheet "Data" (formato requerido por 00_BuildData.do)
wb <- createWorkbook()
addWorksheet(wb, "Data")
writeData(wb, sheet = "Data", x = datos_final, startRow = 1, startCol = 1)
saveWorkbook(wb, path_output, overwrite = TRUE)

cat("  ✓ Archivo guardado:", path_output, "\n")
cat("  ✓ Sheet: 'Data'\n")
cat("  ✓ Dimensiones:", nrow(datos_final), "municipios x", ncol(datos_final), "columnas\n")

# ---- vista previa ----
cat("\n--- PRIMEROS 5 MUNICIPIOS ---\n")
print(head(datos_final, 5))

cat("\n✓ Proceso completado exitosamente!\n")
cat("\nVariable generada: tasa_iam (promedio histórico 2005-2024)\n")

