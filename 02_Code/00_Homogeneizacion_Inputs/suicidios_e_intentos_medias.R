# Tasas de suicidios Municipal media de 3 periodos ----

### Autor: Miguel Espinal

### Fecha: 20/06/2025

rm(list = ls())
gc()

# Librerías ----
library(openxlsx)
library(dplyr)
library(stringi)
library(stringr)
library(purrr)
library(tidyr)

# Cargar datos ----
poblacion_general <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/POBLACION MUNICIPAL.xlsx")

suicidios_2021 <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/Procesamiento_suicidios_2021.xlsx")

suicidios_2022 <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/Procesamiento_suicidios_2022.xlsx")

suicidios_2023 <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/Procesamiento DATOS SALUD.xlsx")

intento_suicidios_15_29_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_1529.csv")

intento_suicidios_30_59_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_3059.csv")

intento_suicidios_15_64_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_1564.csv")

intento_suicidios_hombres_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_hombres.csv")

intento_suicidios_mujeres_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_mujeres.csv")

intento_suicidios_total_2021 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2021_total.csv")

intento_suicidios_15_29_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_1529.csv")

intento_suicidios_30_59_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_3059.csv")

intento_suicidios_15_64_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_1564.csv")

intento_suicidios_hombres_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_hombres.csv")

intento_suicidios_mujeres_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_mujeres.csv")

intento_suicidios_total_2022 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2022_total.csv")

intento_suicidios_15_29_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_1529.csv")

intento_suicidios_30_59_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_3059.csv")

intento_suicidios_15_64_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_1564.csv")

intento_suicidios_hombres_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_hombres.csv")

intento_suicidios_mujeres_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_mujeres.csv")

intento_suicidios_total_2023 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_total.csv")

# Limpieza de datos ----

poblacion_general <- poblacion_general |> 
  filter(AÑO == 2023 | AÑO == 2022 | AÑO == 2021) |> 
  filter(ÁREA.GEOGRÁFICA == "Total")


## Agrupación de las poblaciones ----

poblacion_agrupada <- poblacion_general |> 
  mutate(
    edad_15_29 = rowSums(across(c(`TOTAL.(15-19)`, `TOTAL.(20-24)`, `TOTAL.(25-29)`))),
    edad_30_59 = rowSums(across(c(`TOTAL.(30-34)`, `TOTAL.(35-39)`, `TOTAL.(40-44)`, 
                                  `TOTAL.(45-49)`, `TOTAL.(50-54)`, `TOTAL.(55-59)`))),
    edad_15_64 = rowSums(across(c(`TOTAL.(60-64)`, `TOTAL.(15-19)`, `TOTAL.(20-24)`, `TOTAL.(25-29)`,
                                  `TOTAL.(30-34)`, `TOTAL.(35-39)`, `TOTAL.(40-44)`, 
                                  `TOTAL.(45-49)`, `TOTAL.(50-54)`, `TOTAL.(55-59)`))),
    hombres = rowSums(across(c(`Hombre.(0-4)`, `Hombre.(5-9)`, `Hombre.(10-14)`, 
                               `Hombre.(15-19)`, `Hombre.(20-24)`, `Hombre.(25-29)`, 
                               `Hombre.(30-34)`, `Hombre.(35-39)`, `Hombre.(40-44)`, 
                               `Hombre.(45-49)`, `Hombre.(50-54)`, `Hombre.(55-59)`, 
                               `Hombre.(60-64)`, `Hombre.(65-69)`, `Hombre.(70-74)`,
                               `Hombre.(75-79)`, `Hombre.(80-84)`, `Hombre.(85.y.más)`))),
    mujeres = rowSums(across(c(`Mujeres.(0-4)`, `Mujeres.(5-9)`, `Mujeres.(10-14)`, 
                               `Mujeres.(15-19)`, `Mujeres.(20-24)`, `Mujeres.(25-29)`, 
                               `Mujeres.(30-34)`, `Mujeres.(35-39)`, `Mujeres.(40-44)`, 
                               `Mujeres.(45-49)`, `Mujeres.(50-54)`, `Mujeres.(55-59)`, 
                               `Mujeres.(60-64)`, `Mujeres.(65-69)`, `Mujeres.(70-74)`,
                               `Mujeres.(75-79)`, `Mujeres.(80-84)`, `Mujeres.(85.y.más)`))),
    total = rowSums(across(c(`TOTAL.(0-4)`, `TOTAL.(5-9)`, `TOTAL.(10-14)`,
                             `TOTAL.(15-19)`, `TOTAL.(20-24)`, `TOTAL.(25-29)`, 
                             `TOTAL.(30-34)`, `TOTAL.(35-39)`, `TOTAL.(40-44)`, 
                             `TOTAL.(45-49)`, `TOTAL.(50-54)`, `TOTAL.(55-59)`, 
                             `TOTAL.(60-64)`, `TOTAL.(65-69)`, `TOTAL.(70-74)`,
                             `TOTAL.(75-79)`, `TOTAL.(80-84)`, `TOTAL.(85.y.más)`)))
  ) |> 
  select(DPMP, MPIO, AÑO, edad_15_29, edad_30_59, edad_15_64, hombres, mujeres, total)


poblacion_municipio <- poblacion_agrupada |> 
  group_by(DPMP, MPIO) |> 
  summarise(
    edad_15_29 = mean(edad_15_29, na.rm = TRUE),
    edad_30_59 = mean(edad_30_59, na.rm = TRUE),
    edad_15_64 = mean(edad_15_64, na.rm = TRUE),
    hombres = mean(hombres, na.rm = TRUE),
    mujeres = mean(mujeres, na.rm = TRUE),
    total = mean(total, na.rm = TRUE)
  ) |> 
  ungroup()

## Limpieza de datos de suicidios e intentos de suicidio ----

suicidios_2021_l <- poblacion_municipio |>
  left_join(suicidios_2021, by = c("DPMP" = "Codigo_Municipio"))

suicidios_2022_l <- poblacion_municipio |>
  left_join(suicidios_2022, by = c("DPMP" = "Codigo_Municipio"))

suicidios_2023_l <- poblacion_municipio |> 
  left_join(suicidios_2023, by = c("DPMP" = "Codigo_Municipio"))


### Limpieza intentos de suicidio ----

intento_suicidios_15_29_2021_l <- intento_suicidios_15_29_2021 |>
  mutate(
    Total_15_29 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_29)

intento_suicidios_30_59_2021_l <- intento_suicidios_30_59_2021 |>
  mutate(
    Total_30_59 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_30_59)

intento_suicidios_15_64_2021_l <- intento_suicidios_15_64_2021 |>
  mutate(
    Total_15_64 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_64)

intento_suicidios_hombres_2021_l <- intento_suicidios_hombres_2021 |>
  mutate(
    Hombres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Hombres_Total)

intento_suicidios_mujeres_2021_l <- intento_suicidios_mujeres_2021 |>
  mutate(
    Mujeres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Mujeres_Total)

intento_suicidios_total_2021_l <- intento_suicidios_total_2021 |>
  mutate(
    Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total)

intento_suicidios_15_29_2022_l <- intento_suicidios_15_29_2022 |>
  mutate(
    Total_15_29 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_29)

intento_suicidios_30_59_2022_l <- intento_suicidios_30_59_2022 |>
  mutate(
    Total_30_59 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_30_59)

intento_suicidios_15_64_2022_l <- intento_suicidios_15_64_2022 |>
  mutate(
    Total_15_64 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_64)

intento_suicidios_hombres_2022_l <- intento_suicidios_hombres_2022 |>
  mutate(
    Hombres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Hombres_Total)

intento_suicidios_mujeres_2022_l <- intento_suicidios_mujeres_2022 |>
  mutate(
    Mujeres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Mujeres_Total)

intento_suicidios_total_2022_l <- intento_suicidios_total_2022 |>
  mutate(
    Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total)

intento_suicidios_15_29_2023_l <- intento_suicidios_15_29_2023 |>
  mutate(
    Total_15_29 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_29)

intento_suicidios_30_59_2023_l <- intento_suicidios_30_59_2023 |>
  mutate(
    Total_30_59 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_30_59)

intento_suicidios_15_64_2023_l <- intento_suicidios_15_64_2023 |>
  mutate(
    Total_15_64 = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total_15_64)

intento_suicidios_hombres_2023_l <- intento_suicidios_hombres_2023 |>
  mutate(
    Hombres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Hombres_Total)

intento_suicidios_mujeres_2023_l <- intento_suicidios_mujeres_2023 |>
  mutate(
    Mujeres_Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Mujeres_Total)

intento_suicidios_total_2023_l <- intento_suicidios_total_2023 |>
  mutate(
    Total = casos,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, Total)

intento_suicidios_2021_l2 <- intento_suicidios_15_29_2021_l |> 
  left_join(intento_suicidios_30_59_2021_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_15_64_2021_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_hombres_2021_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_mujeres_2021_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_total_2021_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  mutate(
      CODIGO_MUNICIPIO = paste0("0", CODIGO_MUNICIPIO) 
  )

intento_suicidios_2022_l2 <- intento_suicidios_15_29_2022_l |> 
  left_join(intento_suicidios_30_59_2022_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_15_64_2022_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_hombres_2022_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_mujeres_2022_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_total_2022_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO"))  |> 
  mutate(
    ano = 2022,
    CODIGO_MUNICIPIO = paste0("0", CODIGO_MUNICIPIO) 
  )

intento_suicidios_2023_l2 <- intento_suicidios_15_29_2023_l |>
  left_join(intento_suicidios_30_59_2023_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_15_64_2023_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_hombres_2023_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_mujeres_2023_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_total_2023_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  mutate(
    ano = 2023,
    CODIGO_MUNICIPIO = paste0("0", CODIGO_MUNICIPIO) 
  )

intento_suicidios_2021 <- poblacion_municipio |> 
  left_join(intento_suicidios_2021_l2, by = c("DPMP" = "CODIGO_MUNICIPIO")) |> 
  mutate(
    ano = 2021
  )

intento_suicidios_2022 <- poblacion_municipio |>
  left_join(intento_suicidios_2022_l2, by = c("DPMP" = "CODIGO_MUNICIPIO")) |> 
  mutate(
    ano = 2022
  )

intento_suicidios_2023 <- poblacion_municipio |>
  left_join(intento_suicidios_2023_l2, by = c("DPMP" = "CODIGO_MUNICIPIO")) |> 
  mutate(
    ano = 2023
  )

suicidios_total_2021 <- suicidios_2021_l |> 
  select(MPIO, DPMP, hombres, mujeres, total, edad_15_29, edad_30_59, edad_15_64, 
         Total, Hombres_Total, Mujeres_Total, Hombres_15_19, Mujeres_15_19, Hombres_20_24,
         Mujeres_20_24, Hombres_25_29, Mujeres_25_29, Hombres_30_34, Mujeres_30_34, 
         Hombres_35_39, Mujeres_35_39, Hombres_40_44, Mujeres_40_44, Hombres_45_49,
         Mujeres_45_49, Hombres_50_54, Mujeres_50_54, Hombres_55_59, Mujeres_55_59,
         Hombres_60_64, Mujeres_60_64) |> 
  mutate(
    ano = 2021,
    edad_15_29 = as.numeric(edad_15_29),
    edad_30_59 = as.numeric(edad_30_59),
    edad_15_64 = as.numeric(edad_15_64),
    
    Total_15_29 = Hombres_15_19 + Mujeres_15_19 + Hombres_20_24 + Mujeres_20_24 + Hombres_25_29 + Mujeres_25_29,
    Total_30_59 = Hombres_30_34 + Mujeres_30_34 + Hombres_35_39 + Mujeres_35_39 + Hombres_40_44 + Mujeres_40_44 +
      Hombres_45_49 + Mujeres_45_49 + Hombres_50_54 + Mujeres_50_54 + Hombres_55_59 + Mujeres_55_59,
    Total_15_64 = Total_15_29 + Hombres_60_64 + Mujeres_60_64 + Total_30_59
  )

suicidios_total_2022 <- suicidios_2022_l |>
  select(MPIO, DPMP, hombres, mujeres, total, edad_15_29, edad_30_59, edad_15_64, 
         Total, Hombres_Total, Mujeres_Total, Hombres_15_19, Mujeres_15_19, Hombres_20_24,
         Mujeres_20_24, Hombres_25_29, Mujeres_25_29, Hombres_30_34, Mujeres_30_34, 
         Hombres_35_39, Mujeres_35_39, Hombres_40_44, Mujeres_40_44, Hombres_45_49,
         Mujeres_45_49, Hombres_50_54, Mujeres_50_54, Hombres_55_59, Mujeres_55_59,
         Hombres_60_64, Mujeres_60_64) |> 
  mutate(
    ano = 2022,
    edad_15_29 = as.numeric(edad_15_29),
    edad_30_59 = as.numeric(edad_30_59),
    edad_15_64 = as.numeric(edad_15_64),
    
    Total_15_29 = Hombres_15_19 + Mujeres_15_19 + Hombres_20_24 + Mujeres_20_24 + Hombres_25_29 + Mujeres_25_29,
    Total_30_59 = Hombres_30_34 + Mujeres_30_34 + Hombres_35_39 + Mujeres_35_39 + Hombres_40_44 + Mujeres_40_44 +
      Hombres_45_49 + Mujeres_45_49 + Hombres_50_54 + Mujeres_50_54 + Hombres_55_59 + Mujeres_55_59,
    Total_15_64 = Total_15_29 + Hombres_60_64 + Mujeres_60_64 + Total_30_59
  )

suicidios_total_2023 <- suicidios_2023_l |>
  select(MPIO, DPMP, hombres, mujeres, total, edad_15_29, edad_30_59, edad_15_64, 
         Total, Hombres_Total, Mujeres_Total, Hombres_15_19, Mujeres_15_19, Hombres_20_24,
         Mujeres_20_24, Hombres_25_29, Mujeres_25_29, Hombres_30_34, Mujeres_30_34, 
         Hombres_35_39, Mujeres_35_39, Hombres_40_44, Mujeres_40_44, Hombres_45_49,
         Mujeres_45_49, Hombres_50_54, Mujeres_50_54, Hombres_55_59, Mujeres_55_59,
         Hombres_60_64, Mujeres_60_64) |> 
  mutate(
    ano = 2023,
    edad_15_29 = as.numeric(edad_15_29),
    edad_30_59 = as.numeric(edad_30_59),
    edad_15_64 = as.numeric(edad_15_64),
    
    Total_15_29 = Hombres_15_19 + Mujeres_15_19 + Hombres_20_24 + Mujeres_20_24 + Hombres_25_29 + Mujeres_25_29,
    Total_30_59 = Hombres_30_34 + Mujeres_30_34 + Hombres_35_39 + Mujeres_35_39 + Hombres_40_44 + Mujeres_40_44 +
      Hombres_45_49 + Mujeres_45_49 + Hombres_50_54 + Mujeres_50_54 + Hombres_55_59 + Mujeres_55_59,
    Total_15_64 = Total_15_29 + Hombres_60_64 + Mujeres_60_64 + Total_30_59
  )

## Unir los datos de suicidios e intentos de suicidio de los tres años ----
intento_suicidios_total <- bind_rows(intento_suicidios_2021, intento_suicidios_2022, intento_suicidios_2023)

suicidios_total <- bind_rows(suicidios_total_2021, suicidios_total_2022, suicidios_total_2023)

intento_suicidios_medias <- intento_suicidios_total |>
  select(MPIO, DPMP, ano, hombres, mujeres, total, edad_15_29, edad_30_59, edad_15_64, 
         Hombres_Total, Mujeres_Total, Total, Total_15_29, Total_30_59, Total_15_64) |> 
  group_by(MPIO, DPMP) |> 
  summarise(
    edad_15_29 = mean(edad_15_29, na.rm = TRUE),
    edad_30_59 = mean(edad_30_59, na.rm = TRUE),
    edad_15_64 = mean(edad_15_64, na.rm = TRUE),
    hombres = mean(hombres, na.rm = TRUE),
    mujeres = mean(mujeres, na.rm = TRUE),
    total = mean(total, na.rm = TRUE),
    Hombres_Total = mean(Hombres_Total, na.rm = TRUE),
    Mujeres_Total = mean(Mujeres_Total, na.rm = TRUE),
    Total = mean(Total, na.rm = TRUE),
    Total_15_29 = mean(Total_15_29, na.rm = TRUE),
    Total_30_59 = mean(Total_30_59, na.rm = TRUE),
    Total_15_64 = mean(Total_15_64, na.rm = TRUE)
  ) |>
  ungroup()

suicidios_medias <- suicidios_total |>
  select(MPIO, DPMP, ano, hombres, mujeres, total, edad_15_29, edad_30_59, edad_15_64, 
         Hombres_Total, Mujeres_Total, Total, Total_15_29, Total_30_59, Total_15_64) |> 
  group_by(MPIO, DPMP) |> 
  summarise(
    edad_15_29 = mean(edad_15_29, na.rm = TRUE),
    edad_30_59 = mean(edad_30_59, na.rm = TRUE),
    edad_15_64 = mean(edad_15_64, na.rm = TRUE),
    hombres = mean(hombres, na.rm = TRUE),
    mujeres = mean(mujeres, na.rm = TRUE),
    total = mean(total, na.rm = TRUE),
    Hombres_Total = mean(Hombres_Total, na.rm = TRUE),
    Mujeres_Total = mean(Mujeres_Total, na.rm = TRUE),
    Total = mean(Total, na.rm = TRUE),
    Total_15_29 = mean(Total_15_29, na.rm = TRUE),
    Total_30_59 = mean(Total_30_59, na.rm = TRUE),
    Total_15_64 = mean(Total_15_64, na.rm = TRUE)
  ) |>
  ungroup()

# Tasas ----

intento_suicidios_tasas <- intento_suicidios_medias |> 
  mutate(
    intentos_total = (as.numeric(Total) / as.numeric(total)) * 100000,
    intentos_hombres = (as.numeric(Hombres_Total) / as.numeric(hombres)) * 100000,
    intentos_mujeres = (as.numeric(Mujeres_Total) / as.numeric(mujeres)) * 100000,
    intentos_15_29 = (as.numeric(Total_15_29) / as.numeric(edad_15_29)) * 100000,
    intentos_30_59 = (as.numeric(Total_30_59) / as.numeric(edad_30_59)) * 100000,
    intentos_15_64 = (as.numeric(Total_15_64) / as.numeric(edad_15_64)) * 100000
  ) |> 
  select(MPIO, DPMP, intentos_total, intentos_hombres, intentos_mujeres, intentos_15_29, intentos_30_59, intentos_15_64) |> 
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .)))

suicidios_tasas <- suicidios_medias |> 
  mutate(
    suicidios_total = (as.numeric(Total) / as.numeric(total)) * 100000,
    suicidios_hombres = (as.numeric(Hombres_Total) / as.numeric(hombres)) * 100000,
    suicidios_mujeres = (as.numeric(Mujeres_Total) / as.numeric(mujeres)) * 100000,
    suicidios_15_29 = (as.numeric(Total_15_29) / as.numeric(edad_15_29)) * 100000,
    suicidios_30_59 = (as.numeric(Total_30_59) / as.numeric(edad_30_59)) * 100000,
    suicidios_15_64 = (as.numeric(Total_15_64) / as.numeric(edad_15_64)) * 100000
  ) |> 
  select(MPIO, DPMP, suicidios_total, suicidios_hombres, suicidios_mujeres, suicidios_15_29, suicidios_30_59, suicidios_15_64) |> 
  mutate(across(everything(), ~ ifelse(is.nan(.), NA, .)))

# Base final ----


