# Indicadores IRCA ----
## 1. Con base en los datos cargados en el sharepoint de proantioquia
## 2. Con base en datos descargados del SIVICAP

## Homogenización municipios

### Autor: Miguel Espinal

### Fecha: 05/04/2025

# Librerías ----
library(openxlsx)
library(dplyr)
library(stringi)
library(stringr)

# Cargar datos ----
DANE <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/00_input/cod_DANE.csv")

datos <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/00_input/Indice de riesgo de calidad del agua (IRCA) 2023.xlsx")


# Limpieza general de datos ----

DANE <- DANE |> 
  mutate(
    CODIGO_MUNICIPIO = as.numeric(CODIGO_MUNICIPIO)
  )

datos_base <- datos |> 
 rename(
    ind_mpio = "MunicipioCodigo",
    nvl_label = "Municipio"
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

# Total municipio ----
datos_total <- datos_base |> 
  select(
    ind_mpio,
    nvl_label,
    IRCA,
    IRCAurbano,
    IRCArural
  ) |> 
  mutate(
    ind_mpio = as.numeric(ind_mpio)
  ) |>  # Eliminar la fila que dice #TODOS en ind_mpio
  filter(ind_mpio != "#TODOS")

faltantes_datos_total <- DANE |> 
  filter(!(CODIGO_MUNICIPIO %in% datos_total$ind_mpio)) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO) |> 
  rename(
    ind_mpio = "CODIGO_MUNICIPIO",
    nvl_label = "NOMBRE_MPIO"
  ) |>
  mutate(
    IRCA = NA_real_,
    IRCAurbano = NA_real_,
    IRCArural = NA_real_
  )

# Unir con los datos ya existentes
datos_total_completo <- bind_rows(datos_total, faltantes_datos_total)

# guardar CSV
write.csv(datos_total_completo, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/02_output/IRCA.csv", row.names = FALSE)


# Metodología 2: tomar los valores más recientes directamente desde el SIVICAP

# Cargar datos anuales decreto 1575 del 2007 SIVICAP ----
datos_decreto <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/00_input/inf_IRCA_anual_mun_Dec.1575.2007.csv", sep = ";")

# Limpieza general de datos ----
datos_base_decreto <- datos_decreto |>
  select(-starts_with("X")) |>
  group_by(Codigo.Mun, Ubicacion) |>
  slice_max(order_by = Anio, n = 1) |>
  ungroup() |> 
  rename(
    ind_mpio = "Codigo.Mun",
    nvl_label = "Nombre.Mun",
    time = "Anio"
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


# Urbano decreto ----
datos_urbano_decreto <- datos_base_decreto |> 
  filter(Ubicacion == "URBANO") |>
  select(
    ind_mpio,
    nvl_label,
    IRCA,
    time
  ) |> 
  mutate(
    ind_mpio = as.numeric(ind_mpio)
  ) |> 
  rename(
    IRCAurbano_dec = "IRCA",
    time_urbano_dec = "time"
  )


faltantes_datos_dec_urbano <- DANE |> 
  filter(!(CODIGO_MUNICIPIO %in% datos_urbano_decreto$ind_mpio)) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO) |> 
  rename(
    ind_mpio = "CODIGO_MUNICIPIO",
    nvl_label = "NOMBRE_MPIO"
  ) |>
  mutate(
    IRCAurbano_dec = NA,
    time_urbano_dec = NA_real_
  )

# Unir con los datos ya existentes
datos_urbano_decreto_completo <- bind_rows(datos_urbano_decreto, faltantes_datos_dec_urbano)

# Rural decreto ----
datos_rural_decreto <- datos_base_decreto |> 
  filter(Ubicacion == "RURAL") |>
  select(
    ind_mpio,
    nvl_label,
    IRCA,
    time
  ) |> 
  mutate(
    ind_mpio = as.numeric(ind_mpio)
  ) |> 
  rename(
    IRCArural_dec = "IRCA",
    time_rural_dec = "time"
  )


faltantes_datos_dec_rural <- DANE |> 
  filter(!(CODIGO_MUNICIPIO %in% datos_rural_decreto$ind_mpio)) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO) |> 
  rename(
    ind_mpio = "CODIGO_MUNICIPIO",
    nvl_label = "NOMBRE_MPIO"
  ) |>
  mutate(
    IRCArural_dec = NA,
    time_rural_dec = NA_real_
  )

# Unir con los datos ya existentes
datos_rural_decreto_completo <- bind_rows(datos_rural_decreto, faltantes_datos_dec_rural)


# Cargar datos anuales resolución 622 del 2020 SIVICAP ----
datos_resolucion <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/00_input/inf_IRCA_anual_mun_Res.622.2020.csv", sep = ";")

# Limpieza general de datos ----
datos_base_resolucion <- datos_resolucion |> 
  select(-starts_with("X")) |>
  group_by(Codigo.Mun, Ubicacion) |>
  slice_max(order_by = Anio, n = 1) |>
  ungroup() |> 
  rename(
    ind_mpio = "Codigo.Mun",
    nvl_label = "Nombre.Mun",
    time = "Anio"
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


# Urbano resolucion ----
datos_urbano_resolucion <- datos_base_resolucion |> 
  filter(Ubicacion == "URBANO") |>
  select(
    ind_mpio,
    nvl_label,
    IRCA,
    time
  ) |> 
  mutate(
    ind_mpio = as.numeric(ind_mpio)
  ) |> 
  rename(
    IRCAurbano_res = "IRCA",
    time_urbano_res = "time"
  )


faltantes_datos_resolucion_urbano <- DANE |>
  filter(!(CODIGO_MUNICIPIO %in% datos_urbano_resolucion$ind_mpio)) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO) |> 
  rename(
    ind_mpio = "CODIGO_MUNICIPIO",
    nvl_label = "NOMBRE_MPIO"
  ) |>
  mutate(
    IRCAurbano_res = NA,
    time_urbano_res = NA_real_
  )

# Unir con los datos ya existentes
datos_urbano_resolucion_completo <- bind_rows(datos_urbano_resolucion, faltantes_datos_resolucion_urbano)

# Rural resolucion ----
datos_rural_resolucion <- datos_base_resolucion |> 
  filter(Ubicacion == "RURAL") |>
  select(
    ind_mpio,
    nvl_label,
    IRCA,
    time
  ) |> 
  mutate(
    ind_mpio = as.numeric(ind_mpio)
  ) |> 
  rename(
    IRCArural_res = "IRCA",
    time_rural_res = "time"
  )

faltantes_datos_resolucion_rural <- DANE |>
  filter(!(CODIGO_MUNICIPIO %in% datos_rural_resolucion$ind_mpio)) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO) |> 
  rename(
    ind_mpio = "CODIGO_MUNICIPIO",
    nvl_label = "NOMBRE_MPIO"
  ) |>
  mutate(
    IRCArural_res = NA,
    time_rural_res = NA_real_
  )

# Unir con los datos ya existentes
datos_rural_resolucion_completo <- bind_rows(datos_rural_resolucion, faltantes_datos_resolucion_rural)

# Unir todos los datos ----
datos_completos_dec_res <- datos_urbano_decreto_completo |> 
  left_join(datos_rural_decreto_completo, by = c("ind_mpio", "nvl_label")) |> 
  left_join(datos_urbano_resolucion_completo, by = c("ind_mpio", "nvl_label")) |> 
  left_join(datos_rural_resolucion_completo, by = c("ind_mpio", "nvl_label"))

datos_completos_dec_res <- datos_completos_dec_res |> 
  mutate(
    IRCAurbano_dec = as.numeric(gsub(",", ".", IRCAurbano_dec)),
    IRCArural_dec = as.numeric(gsub(",", ".", IRCArural_dec)),
    IRCAurbano_res = as.numeric(gsub(",", ".", IRCAurbano_res)),
    IRCArural_res = as.numeric(gsub(",", ".", IRCArural_res))
  )



# guardar CSV
write.csv(datos_completos_dec_res, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/irca/02_output/IRCA_decreto_y_resolucion.csv", row.names = FALSE)

