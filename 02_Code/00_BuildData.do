* ----------------------------------------------------------------------------
* ANTIOQUIAS - 00_BuildData.do
* PREPARACIÓN Y CONSOLIDACIÓN DE DATOS 
* OBJETIVO: Importar indicadores municipales y consolidarlos
* INPUTS: 01_Data/01_Derived/.xlsx
* OUTPUTS: 01_Data/01_Derived/01_final_data.dta 
* ----------------------------------------------------------------------------

* ---- Configuración de directorios ----
* NOTA: Ajustar según usuario local

*if "`c(username)'" == "user" {
    
	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
*} 

cd "$data"
ls



* ---- Importación de archivos Excel a formato .dta ----
* Cada archivo contiene indicadores a nivel municipal (sheet "Data")

local direccion "20250505_SEGURIDAD_SALUD_DEFICT_VIVIENDA 20250506_DEyC 20250506_ECV 20250506_ECV_ADICIONALES 20250506_EDUCACION i_datalake_ges_pub_dicc infraestructura_municipios_dicc IRCA_decreto_y_resolucion_dicc IRCA_dicc natalidad_dicc poblacion_municipal_total_2023_dicc suicidios_e_intentos_medias_dicc mortalidad_iam_dicc"

foreach x in `direccion' {
    import excel using "`x'.xlsx", sheet("Data") firstrow allstring clear
    save "`x'.dta", replace
}

* ---- Corrección de códigos municipales ----
* Algunos archivos no tienen el cero inicial en el código DIVIPOLA
* Se agrega "0" al inicio para estandarizar a 5 dígitos

use "20250506_ECV.dta", clear
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "20250506_ECV.dta", replace
use "20250506_ECV_ADICIONALES.dta",clear
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "20250506_ECV_ADICIONALES.dta",replace
use "i_datalake_ges_pub_dicc.dta", clear
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "i_datalake_ges_pub_dicc.dta",replace
use "infraestructura_municipios_dicc.dta", clear
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "infraestructura_municipios_dicc.dta",replace
use "IRCA_decreto_y_resolucion_dicc.dta", clear
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "IRCA_decreto_y_resolucion_dicc.dta",replace
use "IRCA_dicc.dta", replace
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "IRCA_dicc.dta",replace
use "natalidad_dicc.dta", replace
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "natalidad_dicc.dta",replace
use "poblacion_municipal_total_2023_dicc.dta", replace
gen codigo_mod = "0" + ind_mpio
drop ind_mpio
rename codigo_mod ind_mpio 
save "poblacion_municipal_total_2023_dicc.dta",replace

* ---- Consolidación de datasets mediante merges sucesivos ----
* Llave primaria: ind_mpio (código DIVIPOLA municipal)
* Algunos archivos incluyen también nvl_label (nivel territorial)

* Base inicial: Seguridad, Salud y Déficit de Vivienda
use "20250505_SEGURIDAD_SALUD_DEFICT_VIVIENDA.dta", replace
merge 1:1 ind_mpio using "20250506_DEyC.dta"
drop _merge

* Merge: Encuesta Calidad de Vida
merge 1:1 ind_mpio using "20250506_ECV.dta"
drop _merge

* Merge: ECV Indicadores Adicionales
merge 1:1 ind_mpio using "20250506_ECV_ADICIONALES.dta"
drop _merge

* Merge: Educación
merge 1:1 ind_mpio using "20250506_EDUCACION.dta"
drop _merge

* Merge: Gestión Pública
merge 1:1 ind_mpio using "i_datalake_ges_pub_dicc.dta"
drop _merge

* Merge: Infraestructura Municipal
merge 1:1 ind_mpio using "infraestructura_municipios_dicc.dta"
drop _merge

* Merge: IRCA (Índice Riesgo Calidad Agua) - Decreto y Resolución
merge 1:1 ind_mpio using "IRCA_decreto_y_resolucion_dicc.dta"
drop _merge

* Merge: IRCA (Índice Riesgo Calidad Agua)
merge 1:1 ind_mpio using "IRCA_dicc.dta"
drop _merge

* Merge: Natalidad
merge 1:1 ind_mpio using "natalidad_dicc.dta"
drop _merge

* Merge: Población Municipal 2023
merge 1:1 ind_mpio using "poblacion_municipal_total_2023_dicc.dta"
drop _merge

* Merge: Suicidios e Intentos (promedios)
merge 1:1 ind_mpio using "suicidios_e_intentos_medias_dicc.dta"
drop _merge

* Merge: Mortalidad por Infarto Agudo de Miocardio (IAM)
merge 1:1 ind_mpio using "mortalidad_iam_dicc.dta"
drop _merge

* ---- Tratamiento de valores faltantes ----
* Variables de salud mental: reemplazar blancos por "NA" explícito

replace TS_total = "NA" if TS_total == ""
replace TS_15_29 = "NA" if TS_15_29 == ""
replace TS_30_59 = "NA" if TS_30_59 == ""
replace TS_15_64 = "NA" if TS_15_64 == ""
replace TS_hombres = "NA" if TS_hombres == ""
replace TS_mujeres = "NA" if TS_mujeres == ""
replace TIS_total = "NA" if TIS_total == ""
replace TIS_15_29 = "NA" if TIS_15_29 == ""
replace TIS_30_59 = "NA" if TIS_30_59 == ""
replace TIS_15_64 = "NA" if TIS_15_64 == ""
replace TIS_hombres = "NA" if TIS_hombres == ""	
replace TIS_mujeres = "NA" if TIS_mujeres == ""

* ---- Guardado del dataset consolidado ----
* OUTPUT: 01_final_data.dta
* Contiene todos los indicadores municipales listos para análisis PCA

save "$data/01_final_data.dta", replace





/********************************************************************
* Consolidación con provincias
********************************************************************/

cd "$rawdata"

*--------------------------------------------------
* 1. Importar listado de municipios por provincia
*--------------------------------------------------
import excel "MUNICIPIOS_SUBREG_PROV.xlsx", ///
    firstrow clear

* Quitar los municipios que no tienen provicias
drop if Esquemaasociativo  ==""
rename Esquemaasociativo provincia
tab provincia 

*--------------------------------------------------*
* 2. Crear identificador de provincia
*--------------------------------------------------*

gen id_provincia = .

replace id_provincia = 1 if provincia == "PROVINCIA AGROINDUSTRIAL DEL OCCIDENTE"

replace id_provincia = 2 if provincia == ///
    "PROVINCIA BIOENERGETICA DEL NORTE DE ANTIOQUIA"

replace id_provincia = 3 if provincia == ///
    "PROVINCIA DEL RIO GRANDE"

replace id_provincia = 4 if provincia == ///
    "PROVINCIA TURISTICA Y AGROECOLOGICA"

replace id_provincia = 5 if provincia == ///
    "POVINCIA DEL AGUA, BOSQUES Y TURISMO"

replace id_provincia = 6 if provincia == ///
    "PROVINCIA CARTAMA"

replace id_provincia = 7 if provincia == ///
    "PROVINCIA DE LA PAZ"

replace id_provincia = 8 if provincia == ///
    "PROVINCIA DE SAN JUAN"

replace id_provincia = 9 if provincia == ///
    "PROVINCIA MINERO AGROECOLOGICA"

replace id_provincia = 10 if provincia == ///
    "PROVINCIA PENDERISCO Y SINIFANA"

replace id_provincia = 11 if provincia == ///
    "AREA METROPOLITANA"

label define provincia_lbl ///
    1 "Agroindustrial del Occidente" ///
    2 "Bioenergética del Norte de Antioquia" ///
    3 "Del Río Grande" ///
    4 "Turística y Agroecológica" ///
    5 "Agua, Bosques y Turismo" ///
    6 "Cartama" ///
    7 "De la Paz" ///
    8 "San Juan" ///
    9 "Minero Agroecológica" ///
    10 "Penderisco y Sinifaná" ///
    11 "Área Metropolitana"

label values id_provincia provincia_lbl

*--------------------------------------------------
* 3. Limpiar nombres de municipios para merge
*--------------------------------------------------
gen nvl_label = MPIO

replace nvl_label = ustrnormalize(nvl_label, "nfd")
replace nvl_label = ustrregexra(nvl_label, "\p{Mark}", "")
replace nvl_label = upper(nvl_label)
replace nvl_label = strtrim(nvl_label)

* Ajustes manuales
replace nvl_label = "CAROLINA DEL PRINCIPE" if nvl_label == "CAROLINA"
replace nvl_label = "SAN VICENTE FERRER" if nvl_label == "SAN VICENTE"


drop MPIO

*--------------------------------------------------
* 4. Pegar códigos municipales
*--------------------------------------------------
merge 1:1 nvl_label using "Códigos_municipios_clean.dta"

keep if _merge == 3 //match == 88
drop _merge
destring ind_mpio, replace

save "códigos_provincias.dta", replace

/********************************************************************
* Merge con datos originales de Antioquias
********************************************************************/

merge 1:1 ind_mpio using "$data/01_final_data.dta"

keep if _merge == 3
drop _merge

save "$data/01_final_data_provincias.dta", replace





