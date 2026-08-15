rm(list = ls())
gc()

# 0. Librerías ----

library(readxl)
library(data.table)
library(rpivotTable)
library(lubridate)
library(pivottabler)
library(devtools)
library(usethis)
library(ggplot2)
library(sf)
library(dplyr)
library(openxlsx)
library(stringr)
library(reshape)
library(tidyr)
library(readr)
library(gridExtra)
library(haven)
library(fixest)
library(haven)
library(readr)

# 1. Datos ----

## 1.1. Shapefile de los municipios de Antioquia ----

# Polígono de Municipios de Antioquia
setwd("C:/Users/espin/Desktop/Asistencia_Investigacion/Barranquilla_parceros/00_Datos/Input/MGN2024_MPIO_POLITICO")
mapa_antioquia <- st_read("MGN_ADM_MPIO_GRAFICO.shp") |> st_transform(crs = 4326) |> 
  filter(dpto_ccdgo == "05")


## 1.2. Datos de vías primarias ----
setwd("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/infraestructura/00_input")
"C:\Users\espin\Desktop\Asistencia_Investigacion\Antioquias\infraestructura\00_input\Red_vial_Primaria_A.shp"
vias_primarias <- st_read("Red_vial_Primaria_A.shp") |> 
  st_transform(crs = 4326)

## 1.3. Datos de vías secundarias ----
vias_secundarias <- st_read("Red_vial_Secundaria_A.shp") |> 
  st_transform(crs = 4326)

## 1.4. Datos de vías terciarias ----
vias_terciarias <- st_read("Red_vial_Terciaria_Act.shp") |> 
  st_transform(crs = 4326)

## 1.5. Datos de poblacion ----
poblacion_total <- read_dta("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/poblacion_total_edad.dta") |> 
  select(NOMBRE_MPIO, CODIGO_MUNICIPIO, Total)

# 2. Vías en los municipios ----

## 2.1. Vías primarias en los municipios ----
vias_primarias_municipio <- st_intersection(vias_primarias, mapa_antioquia)

### 2.1.1. Transformación de CRS y cálculo de longitud
vias_primarias_municipio <- st_transform(vias_primarias_municipio, 3116)
vias_primarias_municipio$longitud_m <- st_length(vias_primarias_municipio)
# kms
vias_primarias_municipio$longitud_km <- as.numeric(vias_primarias_municipio$longitud_m) / 1000

km_via_primaria_municipio <- vias_primarias_municipio |> 
  group_by(mpio_cdpmp) |> 
  summarise(total_km_primarias = sum(longitud_km, na.rm = TRUE)) |> 
  st_drop_geometry()

## 2.2. Vías secundarias en los municipios ----
vias_secundarias_municipio <- st_intersection(vias_secundarias, mapa_antioquia)

### 2.2.1. Transformación de CRS y cálculo de longitud
vias_secundarias_municipio <- st_transform(vias_secundarias_municipio, 3116)
vias_secundarias_municipio$longitud_m <- st_length(vias_secundarias_municipio)
# kms
vias_secundarias_municipio$longitud_km <- as.numeric(vias_secundarias_municipio$longitud_m) / 1000

km_via_secundaria_municipio <- vias_secundarias_municipio |> 
  group_by(mpio_cdpmp) |> 
  summarise(total_km_secundarias = sum(longitud_km, na.rm = TRUE)) |> 
  st_drop_geometry()

## 2.3. Vías terciarias en los municipios ----
vias_terciarias_municipio <- st_intersection(vias_terciarias, mapa_antioquia)

### 2.3.1. Transformación de CRS y cálculo de longitud
vias_terciarias_municipio <- st_transform(vias_terciarias_municipio, 3116)
vias_terciarias_municipio$longitud_m <- st_length(vias_terciarias_municipio)
# kms
vias_terciarias_municipio$longitud_km <- as.numeric(vias_terciarias_municipio$longitud_m) / 1000

km_via_terciaria_municipio <- vias_terciarias_municipio |> 
  group_by(mpio_cdpmp) |> 
  summarise(total_km_terciarias = sum(longitud_km, na.rm = TRUE)) |> 
  st_drop_geometry()

# 3. Unir datos de vías ----
km_vias_municipio <- mapa_antioquia |> 
  left_join(km_via_primaria_municipio, by = "mpio_cdpmp") |> 
  left_join(km_via_secundaria_municipio, by = "mpio_cdpmp") |> 
  left_join(km_via_terciaria_municipio, by = "mpio_cdpmp") |> 
  select(mpio_cdpmp, mpio_cnmbr, mpio_narea, total_km_primarias, total_km_secundarias, total_km_terciarias) |> 
  mutate(
    total_km = rowSums(
      across(c(total_km_primarias, total_km_secundarias, total_km_terciarias), ~replace_na(.x, 0))
    )
  ) |> 
  st_drop_geometry() |> 
  dplyr::rename(
    CODIGO_MUNICIPIO = mpio_cdpmp,
    NOMBRE_MPIO = mpio_cnmbr
  )

# 4. Unir datos de vías con población ----
# Igualar tipos de datos
poblacion_total$CODIGO_MUNICIPIO <- as.character(poblacion_total$CODIGO_MUNICIPIO)
km_vias_municipio$CODIGO_MUNICIPIO <- as.character(km_vias_municipio$CODIGO_MUNICIPIO)

# Quitar espacios por si acaso
poblacion_total$NOMBRE_MPIO <- trimws(poblacion_total$NOMBRE_MPIO)
km_vias_municipio$NOMBRE_MPIO <- trimws(km_vias_municipio$NOMBRE_MPIO)

# Hacer el join
base_total <- poblacion_total |> 
  left_join(km_vias_municipio, by = "CODIGO_MUNICIPIO") |> 
  select(-NOMBRE_MPIO.y) |> 
  dplyr::rename(NOMBRE_MPIO = NOMBRE_MPIO.x) |> 
  mutate(across(
    c(total_km, total_km_primarias, total_km_secundarias, total_km_terciarias),
    ~replace_na(.x, 0)
  ))

# 5. Base final ----
base_final <- base_total |> 
  mutate(
    VPC_pri = (total_km_primarias / as.numeric(Total)) * 1000, #km de carretera por cada mil habitantes
    VPC_sec = (total_km_secundarias / as.numeric(Total)) * 1000,
    VPC_ter = (total_km_terciarias / as.numeric(Total)) * 1000,
    VPC_total = (total_km / as.numeric(Total)) * 1000,
    
    IDV_pri = total_km_primarias / mpio_narea,
    IDV_sec = total_km_secundarias / mpio_narea,
    IDV_ter = total_km_terciarias / mpio_narea,
    IDV_total = total_km / mpio_narea
  ) |> 
  select(
    CODIGO_MUNICIPIO, NOMBRE_MPIO,
    VPC_pri, VPC_sec, VPC_ter, VPC_total,
    IDV_pri, IDV_sec, IDV_ter, IDV_total
  ) |> 
  dplyr::rename(
    ind_mpio = CODIGO_MUNICIPIO,
    nvl_label = NOMBRE_MPIO)

# 6. Guardar base final ----
write.xlsx(base_final, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/infraestructura/02_output/infraestructura_municipios.xlsx",
           rowNames = FALSE)
