# Indicadores Poblacion Municipal ----
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
datos <- read.xlsx("C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/poblacion_municipal/00_input/POBLACION MUNICIPAL.xlsx")

# Limpieza de datos ----

datos  <- datos |> 
  filter(AÑO == 2025)


# Infancia (0-11)
datos$Inf_H_0_11 <- rowSums(datos[paste0("Hombres_", 0:11)])
datos$Inf_M_0_11 <- rowSums(datos[paste0("Mujeres_", 0:11)])
datos$Inf_T_0_11 <- rowSums(datos[paste0("Total_", 0:11)])

# Juventud (12-28)
datos$Juv_H_12_28 <- rowSums(datos[paste0("Hombres_", 12:28)])
datos$Juv_M_12_28 <- rowSums(datos[paste0("Mujeres_", 12:28)])
datos$Juv_T_12_28 <- rowSums(datos[paste0("Total_", 12:28)])

# Adultez (29-59)
datos$Ad_H_29_59 <- rowSums(datos[paste0("Hombres_", 29:59)])
datos$Ad_M_29_59 <- rowSums(datos[paste0("Mujeres_", 29:59)])
datos$Ad_T_29_59 <- rowSums(datos[paste0("Total_", 29:59)])

# Vejez (60-85) — asumiendo que "85.y.más" se cuenta como 85
datos$V_H_60_85 <- rowSums(datos[c(paste0("Hombres_", 60:84), "Hombres_85.y.más")])
datos$V_M_60_85 <- rowSums(datos[c(paste0("Mujeres_", 60:84), "Mujeres_85.y.más")])
datos$V_T_60_85 <- rowSums(datos[c(paste0("Total_", 60:84), "Total_85.y.más")])

# Dependientes (0-14 y 60-85 y mas)
datos$Dep_H_0_14_60_85 <- rowSums(datos[c(paste0("Hombres_", 0:14), paste0("Hombres_", 60:84), "Hombres_85.y.más")])
datos$Dep_M_0_14_60_85 <- rowSums(datos[c(paste0("Mujeres_", 0:14), paste0("Mujeres_", 60:84), "Mujeres_85.y.más")])
datos$Dep_T_0_14_60_85 <- rowSums(datos[c(paste0("Total_", 0:14), paste0("Total_", 60:84), "Total_85.y.más")])

# Población en edad activa (15-59)
datos$Act_H_15_59 <- rowSums(datos[paste0("Hombres_", 15:59)])
datos$Act_M_15_59 <- rowSums(datos[paste0("Mujeres_", 15:59)])
datos$Act_T_15_59 <- rowSums(datos[paste0("Total_", 15:59)])

# Viejos 2 (65-85 y más)
datos$Enve_H_65_85 <- rowSums(datos[c(paste0("Hombres_", 65:84), "Hombres_85.y.más")])
datos$Enve_M_65_85 <- rowSums(datos[c(paste0("Mujeres_", 65:84), "Mujeres_85.y.más")])
datos$Enve_T_65_85 <- rowSums(datos[c(paste0("Total_", 65:84), "Total_85.y.más")])

# Jovenes 2 (0-14)
datos$Jov_H_0_14 <- rowSums(datos[c(paste0("Hombres_", 0:14), paste0("Hombres_", 60:84), "Hombres_85.y.más")])
datos$Jov_M_0_14 <- rowSums(datos[c(paste0("Mujeres_", 0:14), paste0("Mujeres_", 60:84), "Mujeres_85.y.más")])
datos$Jov_T_0_14 <- rowSums(datos[c(paste0("Total_", 0:14), paste0("Total_", 60:84), "Total_85.y.más")])


# 2. Crear columnas sumadas por grupo y sexo
datos_resumen <- datos |>
  select(
    ÁREA.GEOGRÁFICA,
    DPMP,
    MPIO,
    Total.General, Total.Hombres, Total.Mujeres,
    Inf_T_0_11, Juv_T_12_28, Ad_T_29_59, V_T_60_85,
    Inf_H_0_11, Juv_H_12_28, Ad_H_29_59, V_H_60_85, 
    Inf_M_0_11, Juv_M_12_28, Ad_M_29_59, V_M_60_85,
    Dep_T_0_14_60_85, Dep_H_0_14_60_85, Dep_M_0_14_60_85,
    Act_T_15_59, Act_H_15_59, Act_M_15_59,
    Enve_T_65_85, Enve_H_65_85, Enve_M_65_85,
    Jov_T_0_14, Jov_H_0_14, Jov_M_0_14
    )

datos_base_original <- datos_resumen |> 
  rename(
    ind_mpio = "DPMP",
    nvl_label = "MPIO",
    H_T = "Total.Hombres",
    M_T = "Total.Mujeres",
    T_T = "Total.General"
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

# Datos total ----
datos_general <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Total") |> 
  select(-ÁREA.GEOGRÁFICA) |> 
  mutate(
    P_T = (T_T / T_T) * 100,
    P_H = (H_T / T_T) * 100,
    P_M = (M_T / T_T) * 100,
    P_inf_T_0_11 = (Inf_T_0_11 / T_T) * 100,
    P_j_T_12_28 = (Juv_T_12_28 / T_T) * 100,
    P_ad_T_29_59 = (Ad_T_29_59 / T_T) * 100,
    P_v_T_60_85 = (V_T_60_85 / T_T) * 100,
    P_inf_H_0_11 = (Inf_H_0_11 / T_T) * 100,
    P_j_H_12_28 = (Juv_H_12_28 / T_T) * 100,
    P_ad_H_29_59 = (Ad_H_29_59 / T_T) * 100,
    P_v_H_60_85 = (V_H_60_85 / T_T) * 100,
    P_inf_M_0_11 = (Inf_M_0_11 / T_T) * 100,
    P_j_M_12_28 = (Juv_M_12_28 / T_T) * 100,
    P_ad_M_29_59 = (Ad_M_29_59 / T_T) * 100,
    P_v_M_60_85 = (V_M_60_85 / T_T) * 100,
    IDE_T = (Dep_T_0_14_60_85 / Act_T_15_59) * 100,
    IDE_H = (Dep_H_0_14_60_85 / Act_H_15_59) * 100,
    IDE_M = (Dep_M_0_14_60_85 / Act_M_15_59) * 100,
    I_enve_T = (Enve_T_65_85 / Jov_T_0_14) * 100,
    I_enve_H = (Enve_H_65_85 / Jov_H_0_14) * 100,
    I_enve_M = (Enve_M_65_85 / Jov_M_0_14) * 100
  ) |> 
  select(
    ind_mpio,
    nvl_label,
    P_T,
    P_H,
    P_M,
    P_inf_T_0_11,
    P_j_T_12_28,
    P_ad_T_29_59,
    P_v_T_60_85,
    P_inf_H_0_11,
    P_j_H_12_28,
    P_ad_H_29_59,
    P_v_H_60_85,
    P_inf_M_0_11,
    P_j_M_12_28,
    P_ad_M_29_59,
    P_v_M_60_85,
    IDE_T,
    IDE_H,
    IDE_M,
    I_enve_T,
    I_enve_H,
    I_enve_M
  )

# Datos rural ----
datos_rural <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Centros Poblados y Rural Disperso") |> 
  select(-ÁREA.GEOGRÁFICA) |> 
  mutate(
    P_T_r = (T_T / T_T) * 100,
    P_H_r = (H_T / T_T) * 100,
    P_M_r = (M_T / T_T) * 100,
    P_inf_T_0_11_r = (Inf_T_0_11 / T_T) * 100,
    P_j_T_12_28_r = (Juv_T_12_28 / T_T) * 100,
    P_ad_T_29_59_r = (Ad_T_29_59 / T_T) * 100,
    P_v_T_60_85_r = (V_T_60_85 / T_T) * 100,
    P_inf_H_0_11_r = (Inf_H_0_11 / T_T) * 100,
    P_j_H_12_28_r = (Juv_H_12_28 / T_T) * 100,
    P_ad_H_29_59_r = (Ad_H_29_59 / T_T) * 100,
    P_v_H_60_85_r = (V_H_60_85 / T_T) * 100,
    P_inf_M_0_11_r = (Inf_M_0_11 / T_T) * 100,
    P_j_M_12_28_r = (Juv_M_12_28 / T_T) * 100,
    P_ad_M_29_59_r = (Ad_M_29_59 / T_T) * 100,
    P_v_M_60_85_r = (V_M_60_85 / T_T) * 100,
    IDE_T_r = (Dep_T_0_14_60_85 / Act_T_15_59) * 100,
    IDE_H_r = (Dep_H_0_14_60_85 / Act_H_15_59) * 100,
    IDE_M_r = (Dep_M_0_14_60_85 / Act_M_15_59) * 100,
    I_enve_T_r = (Enve_T_65_85 / Jov_T_0_14) * 100,
    I_enve_H_r = (Enve_H_65_85 / Jov_H_0_14) * 100,
    I_enve_M_r = (Enve_M_65_85 / Jov_M_0_14) * 100
  ) |>
  select(
    ind_mpio,
    nvl_label,
    P_T_r,
    P_H_r,
    P_M_r,
    P_inf_T_0_11_r,
    P_j_T_12_28_r,
    P_ad_T_29_59_r,
    P_v_T_60_85_r,
    P_inf_H_0_11_r,
    P_j_H_12_28_r,
    P_ad_H_29_59_r,
    P_v_H_60_85_r,
    P_inf_M_0_11_r,
    P_j_M_12_28_r,
    P_ad_M_29_59_r,
    P_v_M_60_85_r,
    IDE_T_r,
    IDE_H_r,
    IDE_M_r,
    I_enve_T_r,
    I_enve_H_r,
    I_enve_M_r
  )

# Datos cabecera ----
datos_cabecera <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Cabecera Municipal") |> 
  select(-ÁREA.GEOGRÁFICA) |> 
  mutate(
    P_T_c = (T_T / T_T) * 100,
    P_H_c = (H_T / T_T) * 100,
    P_M_c = (M_T / T_T) * 100,
    P_inf_T_0_11_c = (Inf_T_0_11 / T_T) * 100,
    P_j_T_12_28_c = (Juv_T_12_28 / T_T) * 100,
    P_ad_T_29_59_c = (Ad_T_29_59 / T_T) * 100,
    P_v_T_60_85_c = (V_T_60_85 / T_T) * 100,
    P_inf_H_0_11_c = (Inf_H_0_11 / T_T) * 100,
    P_j_H_12_28_c = (Juv_H_12_28 / T_T) * 100,
    P_ad_H_29_59_c = (Ad_H_29_59 / T_T) * 100,
    P_v_H_60_85_c = (V_H_60_85 / T_T) * 100,
    P_inf_M_0_11_c = (Inf_M_0_11 / T_T) * 100,
    P_j_M_12_28_c = (Juv_M_12_28 / T_T) * 100,
    P_ad_M_29_59_c = (Ad_M_29_59 / T_T) * 100,
    P_v_M_60_85_c = (V_M_60_85 / T_T) * 100,
    IDE_T_c = (Dep_T_0_14_60_85 / Act_T_15_59) * 100,
    IDE_H_c = (Dep_H_0_14_60_85 / Act_H_15_59) * 100,
    IDE_M_c = (Dep_M_0_14_60_85 / Act_M_15_59) * 100,
    I_enve_c_T = (Enve_T_65_85 / Jov_T_0_14) * 100,
    I_enve_H_c = (Enve_H_65_85 / Jov_H_0_14) * 100,
    I_enve_M_c = (Enve_M_65_85 / Jov_M_0_14) * 100
  ) |> 
  select(
    ind_mpio,
    nvl_label,
    P_T_c,
    P_H_c,
    P_M_c,
    P_inf_T_0_11_c,
    P_j_T_12_28_c,
    P_ad_T_29_59_c,
    P_v_T_60_85_c,
    P_inf_H_0_11_c,
    P_j_H_12_28_c,
    P_ad_H_29_59_c,
    P_v_H_60_85_c,
    P_inf_M_0_11_c,
    P_j_M_12_28_c,
    P_ad_M_29_59_c,
    P_v_M_60_85_c,
    IDE_T_c,
    IDE_H_c,
    IDE_M_c,
    I_enve_c_T,
    I_enve_H_c,
    I_enve_M_c
  )

# Datos con el porcentaje rural del total ----
datos_rural_base <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Centros Poblados y Rural Disperso") |> 
  select(-ÁREA.GEOGRÁFICA)

datos_total_base <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Total") |> 
  select(-ÁREA.GEOGRÁFICA)

datos_combinados <- left_join(
  datos_total_base,
  datos_rural_base,
  by = c("ind_mpio", "nvl_label"),
  suffix = c("_t", "_r")
)

# Calculamos proporciones rurales respecto al total para cada grupo
datos_p_rural <- datos_combinados |> 
  mutate(
    PR_T = (T_T_r / T_T_t) * 100,
    PR_H = (H_T_r / H_T_t) * 100,
    PR_M = (M_T_r / M_T_t) * 100,
    PR_inf_T_0_11 = (Inf_T_0_11_r / Inf_T_0_11_t) * 100,
    PR_j_T_12_28 = (Juv_T_12_28_r / Juv_T_12_28_t) * 100,
    PR_ad_T_29_59 = (Ad_T_29_59_r / Ad_T_29_59_t) * 100,
    PR_v_T_60_85 = (V_T_60_85_r / V_T_60_85_t) * 100,
    PR_inf_H_0_11 = (Inf_H_0_11_r / Inf_H_0_11_t) * 100,
    PR_j_H_12_28 = (Juv_H_12_28_r / Juv_H_12_28_t) * 100,
    PR_ad_H_29_59 = (Ad_H_29_59_r / Ad_H_29_59_t) * 100,
    PR_v_H_60_85 = (V_H_60_85_r / V_H_60_85_t) * 100,
    PR_inf_M_0_11 = (Inf_M_0_11_r / Inf_M_0_11_t) * 100,
    PR_j_M_12_28 = (Juv_M_12_28_r / Juv_M_12_28_t) * 100,
    PR_ad_M_29_59 = (Ad_M_29_59_r / Ad_M_29_59_t) * 100,
    PR_v_M_60_85 = (V_M_60_85_r / V_M_60_85_t) * 100
  ) |> 
  select(
    ind_mpio,
    nvl_label,
    starts_with("PR_")
  )

# Datos con el porcentaje urbano del total ----
datos_urbano_base <- datos_base_original |> 
  filter(ÁREA.GEOGRÁFICA == "Cabecera Municipal") |> 
  select(-ÁREA.GEOGRÁFICA)

datos_combinados_urbano <- left_join(
  datos_total_base,
  datos_urbano_base,
  by = c("ind_mpio", "nvl_label"),
  suffix = c("_t", "_u")
)

# Calculamos proporciones urbanas respecto al total para cada grupo
datos_p_urbano <- datos_combinados_urbano |> 
  mutate(
    PU_T = (T_T_u / T_T_t) * 100,
    PU_H = (H_T_u / H_T_t) * 100,
    PU_M = (M_T_u / M_T_t) * 100,
    PU_inf_T_0_11 = (Inf_T_0_11_u / Inf_T_0_11_t) * 100,
    PU_j_T_12_28 = (Juv_T_12_28_u / Juv_T_12_28_t) * 100,
    PU_ad_T_29_59 = (Ad_T_29_59_u / Ad_T_29_59_t) * 100,
    PU_v_T_60_85 = (V_T_60_85_u / V_T_60_85_t) * 100,
    PU_inf_H_0_11 = (Inf_H_0_11_u / Inf_H_0_11_t) * 100,
    PU_j_H_12_28 = (Juv_H_12_28_u / Juv_H_12_28_t) * 100,
    PU_ad_H_29_59 = (Ad_H_29_59_u / Ad_H_29_59_t) * 100,
    PU_v_H_60_85 = (V_H_60_85_u / V_H_60_85_t) * 100,
    PU_inf_M_0_11 = (Inf_M_0_11_u / Inf_M_0_11_t) * 100,
    PU_j_M_12_28 = (Juv_M_12_28_u / Juv_M_12_28_t) * 100,
    PU_ad_M_29_59 = (Ad_M_29_59_u / Ad_M_29_59_t) * 100,
    PU_v_M_60_85 = (V_M_60_85_u / V_M_60_85_t) * 100
  ) |> 
  select(
    ind_mpio,
    nvl_label,
    starts_with("PU_")
  )






# Unir todos los datos ----
datos_total <- datos_general|> 
  left_join(datos_rural, by = c("ind_mpio", "nvl_label")) |>
  left_join(datos_cabecera, by = c("ind_mpio", "nvl_label")) |>
  left_join(datos_p_rural, by = c("ind_mpio", "nvl_label")) |>
  left_join(datos_p_urbano, by = c("ind_mpio", "nvl_label"))


# Guardar datos total ----  
write.csv(datos_total, "C:/Users/espin/Desktop/Asistencia_Investigacion/Antioquias/poblacion_municipal/02_output/poblacion_municipal_total_2025.csv",row.names = FALSE)

