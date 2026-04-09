# ==============================================================================#
# ANTIOQUIAS - 01_BuildFinalData.R
# TRANSFORMACIÓN A FORMATO LARGO Y CONSTRUCCIÓN DE DATASETS INICIALES
#
# OBJETIVO:
# Convertir datos anchos a formato largo, estandarizar nombres de variables,
# integrar diccionario metodológico y generar datasets específicos para PCA.
#
# INPUTS:  01_Data/01_Derived/01_final_data.dta
#          01_Data/00_Inputs/INVENTARIO_VARIABLES.xlsx
# OUTPUTS: 01_DATOS_INICIALES.xlsx (base limpia)
#          01_DATOS_INICIALES_dim.xlsx (con subdimensión)
#          01_DATOS_INICIALES_dim_signo.xlsx (con subdimensión y sentido)
#          label.xlsx (diccionario var_id -> variable)
#
# ETAPA DEL PIPELINE: 1 - Preparación y reshaping de datos
# ==============================================================================#

# ---- packages ----
rm(list = ls())

pacman::p_load(
  haven,
  tidyr,
  dplyr,
  stringi,
  writexl,
  readxl
)

# ---- paths ----
path_in  <- "01_Data"
path_out <- "01_Data/01_Derived"

# ---- lectura de datos ----
# Dataset consolidado desde Stata
datos <- read_dta(file.path(path_in, "01_Derived/01_final_data.dta"))

# Diccionario metodológico con subdimensiones y sentido de variables
labels <- read_excel(
  file.path(path_in, "00_Inputs/INVENTARIO_VARIABLES.xlsx"), 
  sheet = "Diccionario_Base"
)

# ---- transformación a formato largo ----
# Convertir de formato ancho (una columna por variable) a formato largo
# Mantener ind_mpio y nvl_label como identificadores

datos_long <- datos %>%
  pivot_longer(
    cols = -c(ind_mpio, nvl_label),  
    names_to = "var0",                
    values_to = "valor"             
  )

# ---- limpieza y estandarización de nombres ----
# Eliminar tildes, convertir espacios a guiones bajos, minúsculas

# Limpiar nvl_label (nivel territorial)
datos_long$nvl_label <- datos_long$nvl_label |>
  stri_trans_general(id = "Latin-ASCII") |>  
  gsub(" ", "_", x = _) |>                   
  tolower()

# Limpiar var0 (nombre de variable)
datos_long$var0 <- datos_long$var0 |>
  stri_trans_general(id = "Latin-ASCII") |>
  gsub(" ", "_", x = _) |>
  tolower()

# ---- conversión y filtrado ----
# Convertir valores a numérico (elimina "NA" strings automáticamente)
datos_long$valor <- as.numeric(datos_long$valor)

# Filtrar variables temporales que no se usan en el análisis
datos_long <- datos_long[!grepl("^time_", datos_long$var0), ]

# ---- integración con diccionario metodológico ----
# Merge con labels para incorporar subdimensión, sentido, descripción

labels <- labels %>%
  rename(var0 = var_id)

datos_long2 <- left_join(datos_long, labels, by = "var0")

# Eliminar columna innecesaria
datos_long2 <- datos_long2 %>% 
  select(-`Unidad de medida_descriptiva`)

# Guardar versión intermedia con metadata completa
write_xlsx(datos_long2, file.path(path_out, "01_final_data_long.xlsx"))

# ---- construcción de datasets finales para PCA ----
# Generar versiones específicas según necesidades del análisis

ds_ind <- read_excel(file.path(path_out, "01_final_data_long.xlsx"))

# Renombrar y crear ID numérico para variables
ds_ind <- ds_ind %>%
  rename(value = valor) %>%
  mutate(var_id = as.integer(factor(var0)))

# ---- generación de diccionario de variables ----
# Mapeo var0 -> descripción legible
label <- ds_ind %>%
  select(var0, variable) %>%
  distinct(var0, .keep_all = TRUE) %>%
  rename(
    terms = var0,
    lab = variable
  )

# ---- datasets específicos para diferentes análisis ----

# 1. Dataset completo: subdimensión + sentido (para PCA con dirección)
ds_ind3 <- ds_ind %>%
  select(ind_mpio, nvl_label, var0, value, var_id, Subdimensión, Sentido) %>%
  rename(Subdimension = Subdimensión)

# 2. Dataset intermedio: subdimensión sin sentido
ds_ind2 <- ds_ind %>%
  select(ind_mpio, nvl_label, var0, value, var_id, Subdimensión) %>%
  rename(Subdimension = Subdimensión)

# 3. Dataset base: solo variables esenciales para PCA
ds_ind <- ds_ind %>%
  mutate(nvl_label = toupper(nvl_label)) %>%
  select(ind_mpio, nvl_label, var0, value, var_id)

# ---- exportación de datasets finales ----
write_xlsx(ds_ind, file.path(path_out, "01_DATOS_INICIALES.xlsx"))
write_xlsx(ds_ind2, file.path(path_out, "01_DATOS_INICIALES_dim.xlsx"))
write_xlsx(ds_ind3, file.path(path_out, "01_DATOS_INICIALES_dim_signo.xlsx"))
write_xlsx(label, file.path(path_out, "label.xlsx"))




