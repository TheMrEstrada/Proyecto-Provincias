library(haven)
library(dplyr)
library(openxlsx)
library(readxl)
library(stringr)

# 0. Datos ----

## Datos de población 
poblacion_total_edad <- read_dta("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/poblacion_total_edad.dta")

poblacion_hombres_edad <- read_dta("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/poblacion_total_edad_hombres.dta")

poblacion_mujeres_edad <- read_dta("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/poblacion_total_edad_mujeres.dta")

poblacion_total_genero <- read_dta("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/poblacion_total_genero.dta")

## Datos de intentos de suicidios
intento_suicidios_15_29 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_porcentaje_1529.csv")

intento_suicidios_30_59 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_porcentaje_3059.csv")

intento_suicidios_15_64 <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_porcentaje_1564.csv")

intento_suicidios_hombres <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_porcentaje_hombres.csv")

intento_suicidios_mujeres <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_porcentaje_mujeres.csv")

intento_suicidios_total <- read.csv("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/intento_suicidio_2023_porcentaje_total.csv")

## Datos de suicidios
suicidios <- read_excel("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/00_input/Procesamiento DATOS SALUD.xlsx")

# 1. Limpieza de datos ----

intento_suicidios_15_29_l <- intento_suicidios_15_29 |> 
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_1529) |> 
  mutate(
    porcentaje_suicidio_1529 = porcentaje_suicidio_1529 * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_1529 = ifelse(porcentaje_suicidio_1529 == 0, NA, porcentaje_suicidio_1529))

intento_suicidios_30_59_l <- intento_suicidios_30_59 |>
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_3059) |> 
  mutate(
    porcentaje_suicidio_3059 = porcentaje_suicidio_3059 * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_3059 = ifelse(porcentaje_suicidio_3059 == 0, NA, porcentaje_suicidio_3059))

intento_suicidios_15_64_l <- intento_suicidios_15_64 |>
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_15_64) |> 
  mutate(
    porcentaje_suicidio_1564 = porcentaje_suicidio_15_64 * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_1564 = ifelse(porcentaje_suicidio_1564 == 0, NA, porcentaje_suicidio_1564)) |> 
  select(-porcentaje_suicidio_15_64)

intento_suicidios_hombres_l <- intento_suicidios_hombres |>
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_hombres) |> 
  mutate(
    porcentaje_suicidio_hombres = porcentaje_suicidio_hombres * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_hombres = ifelse(porcentaje_suicidio_hombres == 0, NA, porcentaje_suicidio_hombres))

intento_suicidios_mujeres_l <- intento_suicidios_mujeres |>
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_mujeres) |> 
  mutate(
    porcentaje_suicidio_mujeres = porcentaje_suicidio_mujeres * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_mujeres = ifelse(porcentaje_suicidio_mujeres == 0, NA, porcentaje_suicidio_mujeres))

intento_suicidios_total_l <- intento_suicidios_total |>
  select(CODIGO_MUNICIPIO, NOMBRE_MPIO, porcentaje_suicidio_total) |> 
  mutate(
    porcentaje_suicidio_total = porcentaje_suicidio_total * 1000,
    CODIGO_MUNICIPIO = as.character(CODIGO_MUNICIPIO)
  ) |> 
  mutate(porcentaje_suicidio_total = ifelse(porcentaje_suicidio_total == 0, NA, porcentaje_suicidio_total))


intento_suicidios <- intento_suicidios_15_29_l |> 
  left_join(intento_suicidios_30_59_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_15_64_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_hombres_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_mujeres_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios_total_l, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO"))


suicidios_l <- poblacion_total_edad |>
  left_join(suicidios, by = c("CODIGO_MUNICIPIO" = "Codigo_Municipio"))

  
suicidios_total <- suicidios_l |> 
    select(NOMBRE_MPIO, CODIGO_MUNICIPIO, Total.x, edad_15_19, edad_20_24, edad_25_29,
           edad_30_34, edad_35_39, edad_40_44, edad_45_49, edad_50_54, edad_55_59, edad_60_64, 
           Total.y, Hombres_Total, Mujeres_Total, Hombres_15_19, Mujeres_15_19, Hombres_20_24,
           Mujeres_20_24, Hombres_25_29, Mujeres_25_29, Hombres_30_34, Mujeres_30_34, 
           Hombres_35_39, Mujeres_35_39, Hombres_40_44, Mujeres_40_44, Hombres_45_49,
           Mujeres_45_49, Hombres_50_54, Mujeres_50_54, Hombres_55_59, Mujeres_55_59,
           Hombres_60_64, Mujeres_60_64) |> 
    mutate(
      edad_15_19 = as.numeric(edad_15_19),
      edad_20_24 = as.numeric(edad_20_24),
      edad_25_29 = as.numeric(edad_25_29),
      edad_30_34 = as.numeric(edad_30_34),
      edad_35_39 = as.numeric(edad_35_39),
      edad_40_44 = as.numeric(edad_40_44),
      edad_45_49 = as.numeric(edad_45_49),
      edad_50_54 = as.numeric(edad_50_54),
      edad_55_59 = as.numeric(edad_55_59),
      edad_60_64 = as.numeric(edad_60_64),
      
      Total_15_29 = Hombres_15_19 + Mujeres_15_19 + Hombres_20_24 + Mujeres_20_24 + Hombres_25_29 + Mujeres_25_29,
      Total_30_59 = Hombres_30_34 + Mujeres_30_34 + Hombres_35_39 + Mujeres_35_39 + Hombres_40_44 + Mujeres_40_44 +
        Hombres_45_49 + Mujeres_45_49 + Hombres_50_54 + Mujeres_50_54 + Hombres_55_59 + Mujeres_55_59,
      Total_15_64 = Total_15_29 + Hombres_60_64 + Mujeres_60_64 + Total_30_59,
      
      edad_15_29 = edad_15_19 + edad_20_24 + edad_25_29,
      edad_30_59 = edad_30_34 + edad_35_39 + edad_40_44 + edad_45_49 + edad_50_54 + edad_55_59,
      edad_15_64 = edad_15_29 + edad_30_59 + edad_60_64
    )

suicidios_edad <- suicidios_total |>
  mutate(
    suicidios_total = (Total.y / as.numeric(Total.x)) * 100000,
    suicidios_15_29 = (Total_15_29 / edad_15_29) * 100000,
    suicidios_30_59 = (Total_30_59 / edad_30_59) * 100000,
    suicidios_15_64 = (Total_15_64 / edad_15_64) * 100000
  ) |> 
  select(NOMBRE_MPIO, CODIGO_MUNICIPIO, 
         suicidios_total, suicidios_15_29, 
         suicidios_30_59, suicidios_15_64) |> 
  mutate(CODIGO_MUNICIPIO = str_remove(CODIGO_MUNICIPIO, "^0")) |> 
  mutate(
    suicidios_total = ifelse(suicidios_total == 0, NA, suicidios_total),
    suicidios_15_29 = ifelse(suicidios_15_29 == 0, NA, suicidios_15_29),
    suicidios_30_59 = ifelse(suicidios_30_59 == 0, NA, suicidios_30_59),
    suicidios_15_64 = ifelse(suicidios_15_64 == 0, NA, suicidios_15_64)
  )

suicidios_genero_l <- poblacion_total_genero |>
  left_join(suicidios, by = c("CODIGO_MUNICIPIO" = "Codigo_Municipio"))

suicidios_genero <- suicidios_genero_l |>
  mutate(
    suicidios_hombres = (Hombres_Total / as.numeric(Total_Hombres)) * 100000,
    suicidios_mujeres = (Mujeres_Total / as.numeric(Total_Mujeres)) * 100000
  ) |> 
  select(NOMBRE_MPIO, CODIGO_MUNICIPIO, 
         suicidios_hombres, suicidios_mujeres) |> 
  mutate(CODIGO_MUNICIPIO = str_remove(CODIGO_MUNICIPIO, "^0")) |> 
  mutate(
    suicidios_hombres = ifelse(suicidios_hombres == 0, NA, suicidios_hombres),
    suicidios_mujeres = ifelse(suicidios_mujeres == 0, NA, suicidios_mujeres)
  )

## Asegurarme que los códigos de municipios  sean caracteres
suicidios_edad$CODIGO_MUNICIPIO <- as.character(suicidios_edad$CODIGO_MUNICIPIO)
suicidios_genero$CODIGO_MUNICIPIO <- as.character(suicidios_genero$CODIGO_MUNICIPIO)
intento_suicidios$CODIGO_MUNICIPIO <- as.character(intento_suicidios$CODIGO_MUNICIPIO)



suicidios_final <- suicidios_edad |>
  left_join(suicidios_genero, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO")) |> 
  left_join(intento_suicidios, by = c("CODIGO_MUNICIPIO", "NOMBRE_MPIO"))

base_final <- suicidios_final |> 
  rename(
    ind_mpio = CODIGO_MUNICIPIO,
    nvl_label = NOMBRE_MPIO,
    TS_total = suicidios_total,
    TS_15_29 = suicidios_15_29,
    TS_30_59 = suicidios_30_59,
    TS_15_64 = suicidios_15_64,
    TS_hombres = suicidios_hombres,
    TS_mujeres = suicidios_mujeres,
    TIS_15_29 = porcentaje_suicidio_1529,
    TIS_30_59 = porcentaje_suicidio_3059,
    TIS_15_64 = porcentaje_suicidio_1564,
    TIS_hombres = porcentaje_suicidio_hombres,
    TIS_mujeres = porcentaje_suicidio_mujeres,
    TIS_total = porcentaje_suicidio_total
  )

# 2. Exportar base final ----
#write.xlsx(base_final, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/suicidios/02_output/suicidios_e_intentos.xlsx", 
#            rowNames = FALSE)
