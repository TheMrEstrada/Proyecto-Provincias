# Indicadores DATALAKE GESTION PUBLICA ----
## Con base en los datos cargados en el sharepoint de proantioquia
## Homogenización municipios

### Autor: Miguel Espinal

### Fecha: 05/04/2025

# Librerías ----
library(openxlsx)
library(dplyr)
library(stringi)
library(stringr)
library(purrr)
library(tidyr)

# Cargar datos ----
datos <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/datalake_gestion_publica/00_input/DATALAKE GESTION PUBLICA.xlsx")

# Limpieza de datos ----
datos_base <- datos |> 
  group_by(Código_Unidad_Geográfica, Indicador) |>
  slice_max(order_by = Año, n = 1) |>
  ungroup() |> 
  rename(
    ind_mpio = "Código_Unidad_Geográfica",
    nvl_label = "Nombre_Unidad_Geográfica"
  ) |> 
  mutate(
    nvl_label = toupper(stri_trans_general(nvl_label, "Latin-ASCII")),
    nvl_label = gsub("�", "N", nvl_label)
  ) |> 
  mutate(
    # Reemplazo manual de tildes y otros caracteres especiales
    nvl_label = str_replace_all(nvl_label, c(
      "Á" = "A",
      "É" = "E",
      "Í" = "I",
      "Ó" = "O",
      "Ú" = "U",
      "Ñ" = "N",
      "Ü" = "U",
      "a" = "A",
      "i" = "I"
    )),
    
    # Asegurarse de que todo esté en mayúsculas (por si quedó alguna minúscula)
    nvl_label = toupper(nvl_label),
    
    # Correcciones específicas de nombres
    nvl_label = case_when(
      nvl_label == "CARMEN DE VIBORAL" ~ "EL CARMEN DE VIBORAL",
      nvl_label == "PENOL" ~ "EL PENOL",
      nvl_label == "RETIRO" ~ "EL RETIRO",
      nvl_label == "SANTUARIO" ~ "EL SANTUARIO",
      nvl_label == "DON MATIAS" ~ "DONMATIAS",
      nvl_label == "SAN ANDRES" ~ "SAN ANDRES DE CUERQUIA",
      nvl_label == "SAN PEDRO" ~ "SAN PEDRO DE LOS MILAGROS",
      nvl_label == "SANTAFE DE ANTIOQUIA" ~ "SANTA FE DE ANTIOQUIA",

      TRUE ~ nvl_label
    )

  )

# Datos categoría municipio
datos_cat_mun <-  datos_base |> 
  filter(Indicador == "Categoría municipios") |>
  select(
    ind_mpio,
    nvl_label,
    Dato_Numérico
  ) |> 
  rename(
    cat_mun = "Dato_Numérico"
  )

# Datos medicion de desempeño municipal
datos_med_d_mun <-  datos_base |> 
  filter(Indicador == "Medición de desempeño municipal") |>
  select(
    ind_mpio,
    nvl_label,
    Dato_Numérico
  ) |> 
  rename(
    med_d_mun = "Dato_Numérico"
  )

# Datos Índice de desempeño fiscal
datos_idf <-  datos_base |> 
  filter(Indicador == "Índice de desempeño fiscal") |>
  select(
    ind_mpio,
    nvl_label,
    Dato_Numérico
  ) |> 
  rename(
    idf = "Dato_Numérico"
  )

datos_total <- datos_cat_mun |> 
  left_join(datos_med_d_mun, by = c("ind_mpio", "nvl_label")) |>
  left_join(datos_idf, by = c("ind_mpio", "nvl_label"))
  

# Guardar datos ----
write.csv(datos_total, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/datalake_gestion_publica/02_output/i_datalake_ges_pub.csv", row.names = FALSE)

