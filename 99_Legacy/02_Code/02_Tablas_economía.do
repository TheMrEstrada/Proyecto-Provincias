* ----------------------------------------------------------------------------
* PROVINCIAS - 02_Tablas_Economia.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/Tablas_5_economia.xlsx
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"

*------------------------------------
* Índice de independencia económica
* Promedios subregión/departamento antes del merge
*------------------------------------

use "$data/poblacion_municipal_total_2025.dta", clear

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
keep if _merge ==3
drop _merge

keep ind_mpio nvl_label subregion IDE_T

tempfile full subreg depto base promedio

save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) IDE_T ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen nvl_label = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) IDE_T ///
    (count) n_municipios = ind_mpio

gen nvl_label = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) IDE_T ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila nvl_label

label variable ind_mpio      "Código DANE"
label variable nvl_label     "Municipio"
label variable subregion     "Subregión"
label variable provincia     "Provincia"
label variable tipo_fila     "Tipo de fila"
label variable IDE_T         "Índice de independencia económica"

format IDE_T %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila IDE_T ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("IDE_T") ///
    firstrow(varlabels) sheetreplace



*--------------------------------------------------
* NBI, Línea de pobreza
* Promedios subregión/departamento antes del merge
*--------------------------------------------------

use "$data/ECV_nbi_pobreza.dta", clear

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio NomMunicipio subregion ///
     tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
     tot_pob_mon ///
     tot_pob_mon_hombres ///
     tot_pob_mon_mujeres

rename NomMunicipio municipio

tempfile full subreg depto base promedio

save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
        tot_pob_mon ///
        tot_pob_mon_hombres ///
        tot_pob_mon_mujeres ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
        tot_pob_mon ///
        tot_pob_mon_hombres ///
        tot_pob_mon_mujeres ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) ///
        tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
        tot_pob_mon ///
        tot_pob_mon_hombres ///
        tot_pob_mon_mujeres ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio               "Código DANE"
label variable municipio              "Municipio"
label variable subregion              "Subregión"
label variable provincia              "Provincia"
label variable tipo_fila              "Tipo de fila"

label variable tot_pob_nbi            "Pobreza NBI total"
label variable urb_pob_nbi            "Pobreza NBI urbana"
label variable rur_pob_nbi            "Pobreza NBI rural"

label variable tot_pob_mon            "Bajo Línea de Pobreza total"
label variable tot_pob_mon_hombres    "Bajo Línea de Pobreza hombres"
label variable tot_pob_mon_mujeres    "Bajo Línea de Pobreza mujeres"

format tot_* urb_* rur_* %6.1f

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
    tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
    tot_pob_mon ///
    tot_pob_mon_hombres ///
    tot_pob_mon_mujeres ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("ecv_pobreza") firstrow(varlabels) sheetreplace


*----------------------------------*
* Gini laboral - hogares
* Promedios subregión/departamento antes del merge
*----------------------------------*

use "$data/ECV_nbi_pobreza.dta", clear
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge


keep ind_mpio NomMunicipio subregion ///
     tot_gini_hog urb_gini_hog rur_gini_hog ///
     tot_gini_lab urb_gini_lab rur_gini_lab

rename NomMunicipio municipio

tempfile full subreg depto base promedio

save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_gini_hog urb_gini_hog rur_gini_hog ///
        tot_gini_lab urb_gini_lab rur_gini_lab ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_gini_hog urb_gini_hog rur_gini_hog ///
        tot_gini_lab urb_gini_lab rur_gini_lab ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) ///
        tot_gini_hog urb_gini_hog rur_gini_hog ///
        tot_gini_lab urb_gini_lab rur_gini_lab ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio      "Código DANE"
label variable municipio     "Municipio"
label variable subregion     "Subregión"
label variable provincia     "Provincia"
label variable tipo_fila     "Tipo de fila"

label variable tot_gini_hog  "Gini ingresos de los hogares total"
label variable urb_gini_hog  "Gini ingresos de los hogares urbano"
label variable rur_gini_hog  "Gini ingresos de los hogares rural"

label variable tot_gini_lab  "Gini ingresos laborales total"
label variable urb_gini_lab  "Gini ingresos laborales urbano"
label variable rur_gini_lab  "Gini ingresos laborales rural"

format tot_gini_* urb_gini_* rur_gini_* %6.3f

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
    tot_gini_hog urb_gini_hog rur_gini_hog ///
    tot_gini_lab urb_gini_lab rur_gini_lab ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("ecv_gini") firstrow(varlabels) sheetreplace
	
	
*----------------------------------*
* IPM - hogares/personas
* Promedios subregión/departamento antes del merge
*----------------------------------*

use "$data/ECV_nbi_pobreza.dta", clear

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio NomMunicipio subregion ///
     tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
     tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
     tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares

rename NomMunicipio municipio

tempfile full subreg depto base promedio

save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
        tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
        tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
        tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
        tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) ///
        tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
        tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
        tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio              "Código DANE"
label variable municipio             "Municipio"
label variable subregion             "Subregión"
label variable provincia             "Provincia"
label variable tipo_fila             "Tipo de fila"

label variable tot_pob_ipm           "Personas IPM total"
label variable urb_pob_ipm           "Personas IPM urbana"
label variable rur_pob_ipm           "Personas IPM rural"
label variable tot_pob_ipm_hombres   "Personas IPM hombres"
label variable tot_pob_ipm_mujeres   "Personas IPM mujeres"

label variable tot_pob_ipm_hogares   "Hogares IPM total"
label variable urb_pob_ipm_hogares   "Hogares IPM urbana"
label variable rur_pob_ipm_hogares   "Hogares IPM rural"

format ///
    tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
    tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
    tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares %6.1f

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
	tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
    tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
    tot_pob_ipm_hombres tot_pob_ipm_mujeres ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("ecv_ipm") firstrow(varlabels) sheetreplace	
	
	
*-------------------------
* TD e Informalidad
*-------------------------

use "$data/ECV_nbi_pobreza.dta", clear

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio NomMunicipio subregion ///
     tot_td urb_td rur_td ///
     tot_emp_informal urb_emp_informal rur_emp_informal

rename NomMunicipio municipio

tempfile full subreg depto base promedio
save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_td urb_td rur_td ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_td urb_td rur_td ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) ///
        tot_td urb_td rur_td ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio          "Código DANE"
label variable municipio         "Municipio"
label variable subregion         "Subregión"
label variable provincia         "Provincia"
label variable tipo_fila         "Tipo de fila"

label variable tot_td            "Tasa de desocupación total"
label variable urb_td            "Tasa de desocupación urbana"
label variable rur_td            "Tasa de desocupación rural"

label variable tot_emp_informal  "Tasa de empleo informal total"
label variable urb_emp_informal  "Tasa de empleo informal urbana"
label variable rur_emp_informal  "Tasa de empleo informal rural"

format tot_td urb_td rur_td ///
       tot_emp_informal urb_emp_informal rur_emp_informal %6.1f

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
    tot_td urb_td rur_td ///
    tot_emp_informal urb_emp_informal rur_emp_informal ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("ecv_desocupacion_informal") firstrow(varlabels) sheetreplace	
	

	*-------------------------
* TO e Informalidad
*-------------------------

use "$data/ECV_nbi_pobreza.dta", clear

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio NomMunicipio subregion ///
     tot_to urb_to rur_to ///
     tot_emp_informal urb_emp_informal rur_emp_informal

rename NomMunicipio municipio

tempfile full subreg depto base promedio
save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_to urb_to rur_to ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) ///
        tot_to urb_to rur_to ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) ///
        tot_to urb_to rur_to ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio          "Código DANE"
label variable municipio         "Municipio"
label variable subregion         "Subregión"
label variable provincia         "Provincia"
label variable tipo_fila         "Tipo de fila"

label variable tot_to            "Tasa de ocupación total"
label variable urb_to            "Tasa de ocupación urbana"
label variable rur_to            "Tasa de ocupación rural"

label variable tot_emp_informal  "Tasa de empleo informal total"
label variable urb_emp_informal  "Tasa de empleo informal urbana"
label variable rur_emp_informal  "Tasa de empleo informal rural"

format tot_to urb_to rur_to ///
       tot_emp_informal urb_emp_informal rur_emp_informal %6.1f

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
    tot_to urb_to rur_to ///
    tot_emp_informal urb_emp_informal rur_emp_informal ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("ecv_ocupacion_informal") firstrow(varlabels) sheetreplace
	
	
	
/********************************************************************
* Estructura productiva
********************************************************************/

import excel "$data/estructura_productiva.xlsx", firstrow clear

* Mantener ind_mpio como string
tostring ind_mpio, replace force
replace ind_mpio = strtrim(ind_mpio)

* Identificar niveles
gen es_depto = inlist(ind_mpio, "5", "05")
gen es_subregion_base = regexm(ind_mpio, "^SR")
gen es_mpio = !es_depto & !es_subregion_base

* Código auxiliar numérico solo para municipios
gen ind_mpio_num = real(ind_mpio) if es_mpio

tempfile original municipios_full subreg_base depto_base base promedio
save `original'

*--------------------------------------------------
* Merge con subregiones para municipios
*--------------------------------------------------
use `original', clear
keep if es_mpio

rename ind_mpio ind_mpio_str
rename ind_mpio_num ind_mpio

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

rename ind_mpio ind_mpio_num
rename ind_mpio_str ind_mpio

save `municipios_full'

*--------------------------------------------------
* Filas SR que ya trae la base
*--------------------------------------------------
use `original', clear
keep if es_subregion_base

gen subregion = ""
replace subregion = "VALLE DE ABURRÁ" if ind_mpio == "SR01"
replace subregion = "BAJO CAUCA"      if ind_mpio == "SR02"
replace subregion = "MAGDALENA MEDIO" if ind_mpio == "SR03"
replace subregion = "NORDESTE"        if ind_mpio == "SR04"
replace subregion = "NORTE"           if ind_mpio == "SR05"
replace subregion = "OCCIDENTE"       if ind_mpio == "SR06"
replace subregion = "ORIENTE"         if ind_mpio == "SR07"
replace subregion = "SUROESTE"        if ind_mpio == "SR08"
replace subregion = "URABÁ"           if ind_mpio == "SR09"

gen nvl_label = "TOTAL " + subregion
gen tipo_fila = "Total subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_base'

*--------------------------------------------------
* Fila departamental que ya viene en la base
*--------------------------------------------------
use `original', clear
keep if es_depto

gen nvl_label = "TOTAL DEPARTAMENTAL"
gen tipo_fila = "Total departamento"
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_base'

*--------------------------------------------------
* Municipios con provincia
*--------------------------------------------------
use `municipios_full', clear

rename ind_mpio ind_mpio_str
rename ind_mpio_num ind_mpio

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

rename ind_mpio ind_mpio_num
rename ind_mpio_str ind_mpio

gen tipo_fila = "Municipio"

save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) creacion_emp dens_emp fin_banc_pc fin_microcr_pc ///
           tnat_emp va_pc va_primario ///
    (count) n_municipios = ind_mpio_num, ///
    by(id_provincia provincia)

gen ind_mpio = ""
gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen subregion = "TOTAL PROVINCIA"

save `promedio'

*--------------------------------------------------
* Unir todo
*--------------------------------------------------
use `base', clear
append using `promedio'
append using `subreg_base'
append using `depto_base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"

sort subregion id_provincia orden_fila nvl_label

label variable ind_mpio       "Código DANE"
label variable nvl_label      "Municipio"
label variable subregion      "Subregión"
label variable provincia      "Provincia"
label variable tipo_fila      "Tipo de fila"

label variable creacion_emp   "Creación de empresas"
label variable dens_emp       "Densidad empresarial"
label variable fin_banc_pc    "Corresponsales bancarios per cápita"
label variable fin_microcr_pc "Microcréditos per cápita"
label variable tnat_emp       "Tasa neta de creación empresarial"
label variable va_pc          "Valor agregado per cápita"
label variable va_primario    "Participación actividades primarias"

format creacion_emp dens_emp fin_banc_pc fin_microcr_pc ///
       tnat_emp va_pc va_primario %12.2f

export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    creacion_emp dens_emp fin_banc_pc fin_microcr_pc ///
    tnat_emp va_pc va_primario ///
    using "$output/Tablas_5_economia.xlsx", ///
    sheet("estructura_productiva") firstrow(varlabels) sheetreplace
	
	
	