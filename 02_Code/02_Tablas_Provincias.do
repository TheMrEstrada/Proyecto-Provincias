* ----------------------------------------------------------------------------
* PROVINCIAS - 00_Tablas_Provincias.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/Tablas_provincias.xlsx
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	
	
/********************************************************************
* DEMOGRAFÍA
* Tabla de Proyecciones de población 2025
********************************************************************/

use "$data/poblacion_total_2025.dta", clear

* Por si ind_mpio viene como string
capture destring ind_mpio, replace

* Merge con provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*************************************************************
* TABLA: Participación municipal por provincia y área
*************************************************************

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         año area_geo Total Hombres Mujeres

    rename nvl_label municipio
    rename area_geo area
    rename Total habitantes

    bysort id_provincia provincia area: egen total_prov_area = total(habitantes)

    gen participacion_pct = (habitantes / total_prov_area) * 100

    gsort provincia area -habitantes

    keep ind_mpio municipio subregion provincia area habitantes ///
         Hombres Mujeres participacion_pct

    order municipio ind_mpio subregion provincia area ///
          habitantes Hombres Mujeres participacion_pct

    label variable ind_mpio           "Código DANE"
    label variable municipio          "Municipio"
    label variable subregion          "Subregión"
    label variable provincia          "Provincia"
    label variable area               "Área"
    label variable habitantes         "Habitantes"
    label variable Hombres            "Hombres"
    label variable Mujeres            "Mujeres"
    label variable participacion_pct  "%"

    format habitantes Hombres Mujeres %12.0fc
    format participacion_pct %6.1f

    export excel using "$output/tablas_provincias.xlsx", ///
        sheet("poblacion_area") firstrow(varlabels) sheetreplace

restore

*************************************************************
* TABLA: Población total, cabecera y rural por municipio
* Totales/promedios subregión y departamento antes del merge
*************************************************************

use "$data/poblacion_total_2025.dta", clear
keep if departamento =="Antioquia"

capture destring ind_mpio, replace

rename Total habitantes
rename area_geo area
rename nvl_label municipio

gen area_cat = ""
replace area_cat = "total"     if area == "Total"
replace area_cat = "cabecera"  if area == "Cabecera Municipal"
replace area_cat = "rural"     if area == "Centros Poblados y Rural Disperso"

keep ind_mpio municipio area_cat habitantes

reshape wide habitantes, ///
    i(ind_mpio municipio) ///
    j(area_cat) string

rename habitantestotal habitantes_total
rename habitantescabecera habitantes_cabecera
rename habitantesrural habitantes_rural

* Subregión para TODOS los municipios
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio municipio subregion ///
     habitantes_total habitantes_cabecera habitantes_rural

* Porcentaje urbano/rural dentro del municipio
gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
gen pct_rural    = (habitantes_rural / habitantes_total) * 100

tempfile full base prov_total prov_prom subreg_total subreg_prom depto_total depto_prom
save `full'

*--------------------------------------------------*
* Totales subregión - base completa
*--------------------------------------------------*
use `full', clear

collapse ///
    (sum) habitantes_total habitantes_cabecera habitantes_rural ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
gen pct_rural    = (habitantes_rural / habitantes_total) * 100

gen municipio = "TOTAL " + upper(subregion)
gen tipo_fila = "Total subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_total'

*--------------------------------------------------*
* Promedios subregión - base completa
*--------------------------------------------------*
use `full', clear

collapse ///
    (mean) habitantes_total habitantes_cabecera habitantes_rural ///
           pct_cabecera pct_rural ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_prom'

*--------------------------------------------------*
* Total departamental - base completa
*--------------------------------------------------*
use `full', clear

collapse ///
    (sum) habitantes_total habitantes_cabecera habitantes_rural ///
    (count) n_municipios = ind_mpio

gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
gen pct_rural    = (habitantes_rural / habitantes_total) * 100

gen municipio = "TOTAL DEPARTAMENTAL"
gen tipo_fila = "Total departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_total'

*--------------------------------------------------*
* Promedio departamental - base completa
*--------------------------------------------------*
use `full', clear

collapse ///
    (mean) habitantes_total habitantes_cabecera habitantes_rural ///
           pct_cabecera pct_rural ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_prom'

*--------------------------------------------------*
* Municipios con provincia
*--------------------------------------------------*
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

* Participación municipal en el total provincial
bysort provincia: egen total_provincia    = total(habitantes_total)
bysort provincia: egen cabecera_provincia = total(habitantes_cabecera)
bysort provincia: egen rural_provincia    = total(habitantes_rural)

gen part_total_prov = (habitantes_total / total_provincia) * 100
gen part_cab_prov   = (habitantes_cabecera / cabecera_provincia) * 100
gen part_rural_prov = (habitantes_rural / rural_provincia) * 100

drop total_provincia cabecera_provincia rural_provincia

save `base'

*--------------------------------------------------*
* Total provincia
*--------------------------------------------------*
use `base', clear

collapse ///
    (sum) habitantes_total habitantes_cabecera habitantes_rural ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
gen pct_rural    = (habitantes_rural / habitantes_total) * 100

gen part_total_prov = 100
gen part_cab_prov   = 100
gen part_rural_prov = 100

gen municipio = "TOTAL " + upper(provincia)
gen tipo_fila = "Total provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `prov_total'

*--------------------------------------------------*
* Promedio provincia
*--------------------------------------------------*
use `base', clear

collapse ///
    (mean) habitantes_total habitantes_cabecera habitantes_rural ///
           pct_cabecera pct_rural ///
           part_total_prov part_cab_prov part_rural_prov ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `prov_prom'

*--------------------------------------------------*
* Unir todo
*--------------------------------------------------*
use `base', clear
append using `prov_total'
append using `prov_prom'
append using `subreg_total'
append using `subreg_prom'
append using `depto_total'
append using `depto_prom'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Promedio provincia"
replace orden_fila = 4 if tipo_fila == "Total subregión"
replace orden_fila = 5 if tipo_fila == "Promedio subregión"
replace orden_fila = 6 if tipo_fila == "Total departamento"
replace orden_fila = 7 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

format habitantes_total habitantes_cabecera habitantes_rural %12.0fc
format pct_cabecera pct_rural part_total_prov part_cab_prov part_rural_prov %6.1f

label variable municipio             "Municipio"
label variable ind_mpio              "Código DANE"
label variable provincia             "Provincia"
label variable subregion             "Subregión"
label variable tipo_fila             "Tipo de fila"

label variable habitantes_total      "Habitantes"
label variable part_total_prov       "Participación en el total provincial"
label variable habitantes_cabecera   "Población urbana"
label variable pct_cabecera          "Porcentaje de población urbana"
label variable part_cab_prov         "Participación urbana en el total provincial"
label variable habitantes_rural      "Población rural"
label variable pct_rural             "Porcentaje de población rural"
label variable part_rural_prov       "Participación rural en el total provincial"

export excel ///
    ind_mpio municipio subregion provincia tipo_fila ///
    habitantes_total part_total_prov ///
    habitantes_cabecera pct_cabecera part_cab_prov ///
    habitantes_rural pct_rural part_rural_prov ///
    using "$output/tablas_provincias.xlsx", ///
    sheet("poblacion_wide") firstrow(varlabels) sheetreplace

/********************************************************************
* DEMOGRAFÍA
* Tabla de Natalidad, Mortalidad, Envejecimiento...
********************************************************************/
*Merge datos salud con población 
use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear

merge 1:1 ind_mpio using "$data/poblacion_municipal_total_2025_dicc"
drop _merge	

*variables relevantes para la tabla
keep ind_mpio nvl_label tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T

*merge datos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

//********************************************************************
* Tabla demográfica municipal + promedio por provincia en una sola hoja
********************************************************************/

preserve

    keep ind_mpio subregion id_provincia provincia nvl_label ///
     tasa_natalidad tasa_mortalidad crec_vegetativo ///
     I_enve_T

    gen tipo_fila = "Municipio"

    tempfile base subregiones promedios
    save `base'

    * Base única de subregión por provincia
    frame put id_provincia subregion, into(fr_subregiones)
    frame fr_subregiones {
        duplicates drop id_provincia, force
        save `subregiones'
    }
    frame drop fr_subregiones

    * Promedios por provincia
    collapse ///
        (mean) tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedios'

    use `base', clear
    append using `promedios'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

	label variable ind_mpio           "Código DANE"
    label variable subregion          "Subregión"
    label variable nvl_label          "Municipios"
    label variable provincia          "Provincia"
    label variable tipo_fila          "Tipo de fila"
    *label variable n_municipios       "Número de municipios"
    label variable tasa_natalidad     "Tasa de Natalidad"
    label variable tasa_mortalidad    "Tasa de Mortalidad"
    label variable crec_vegetativo    "Crecimiento Vegetativo"
    label variable I_enve_T           "Índice de Envejecimiento"

       export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("prom_natalidad_mortalidad") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* DEMOGRAFÍA
* Tabla población por grupos de edad
********************************************************************/

use "$data/poblacion_total_2025.dta", clear

* Quedarse solo con población total municipal
keep if area_geo == "Total"
keep if departamento =="Antioquia"

capture destring ind_mpio, replace

* Crear grupos de edad
egen P_0_9 = rowtotal(Total0años Total1año Total2años Total3años Total4años ///
                      Total5años Total6años Total7años Total8años Total9años)

egen P_10_19 = rowtotal(Total10años Total11años Total12años Total13años Total14años ///
                        Total15años Total16años Total17años Total18años Total19años)

egen P_20_29 = rowtotal(Total20años Total21años Total22años Total23años Total24años ///
                        Total25años Total26años Total27años Total28años Total29años)

egen P_30_39 = rowtotal(Total30años Total31años Total32años Total33años Total34años ///
                        Total35años Total36años Total37años Total38años Total39años)

egen P_40_49 = rowtotal(Total40años Total41años Total42años Total43años Total44años ///
                        Total45años Total46años Total47años Total48años Total49años)

egen P_50_59 = rowtotal(Total50años Total51años Total52años Total53años Total54años ///
                        Total55años Total56años Total57años Total58años Total59años)

egen P_60_69 = rowtotal(Total60años Total61años Total62años Total63años Total64años ///
                        Total65años Total66años Total67años Total68años Total69años)

egen P_70_79 = rowtotal(Total70años Total71años Total72años Total73años Total74años ///
                        Total75años Total76años Total77años Total78años Total79años)

egen P_80_mas = rowtotal(Total80años Total81años Total82años Total83años Total84años ///
                         Total85años Total86años Total87años Total88años Total89años ///
                         Total90años Total91años Total92años Total93años Total94años ///
                         Total95años Total96años Total97años Total98años Total99años ///
                         Total100añosymás)

* Subregión para TODOS los municipios
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio nvl_label subregion ///
     P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
     P_50_59 P_60_69 P_70_79 P_80_mas

rename nvl_label municipio

tempfile full subreg_total subreg_prom depto_total depto_prom base prov_total prov_prom

save `full'

* Totales subregión - base completa
use `full', clear

collapse ///
    (sum) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
          P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "TOTAL " + upper(subregion)
gen tipo_fila = "Total subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_total'

* Promedios subregión - base completa
use `full', clear

collapse ///
    (mean) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
           P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen municipio = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_prom'

* Total departamental - base completa
use `full', clear

collapse ///
    (sum) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
          P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio

gen municipio = "TOTAL DEPARTAMENTAL"
gen tipo_fila = "Total departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_total'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
           P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio

gen municipio = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_prom'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Total provincia
use `base', clear

collapse ///
    (sum) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
          P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "TOTAL " + upper(provincia)
gen tipo_fila = "Total provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `prov_total'

* Promedio provincia
use `base', clear

collapse ///
    (mean) P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
           P_50_59 P_60_69 P_70_79 P_80_mas ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen municipio = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `prov_prom'

* Unir todo
use `base', clear
append using `prov_total'
append using `prov_prom'
append using `subreg_total'
append using `subreg_prom'
append using `depto_total'
append using `depto_prom'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Promedio provincia"
replace orden_fila = 4 if tipo_fila == "Total subregión"
replace orden_fila = 5 if tipo_fila == "Promedio subregión"
replace orden_fila = 6 if tipo_fila == "Total departamento"
replace orden_fila = 7 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila municipio

label variable ind_mpio    "Código DANE"
label variable subregion   "Subregión"
label variable municipio   "Municipio"
label variable provincia   "Provincia"
label variable tipo_fila   "Tipo de fila"

label variable P_0_9       "0 a 9"
label variable P_10_19     "10 a 19"
label variable P_20_29     "20 a 29"
label variable P_30_39     "30 a 39"
label variable P_40_49     "40 a 49"
label variable P_50_59     "50 a 59"
label variable P_60_69     "60 a 69"
label variable P_70_79     "70 a 79"
label variable P_80_mas    "80 o más"

format P_* %12.0fc

export excel ///
    ind_mpio subregion municipio provincia tipo_fila ///
    P_0_9 P_10_19 P_20_29 P_30_39 P_40_49 ///
    P_50_59 P_60_69 P_70_79 P_80_mas ///
    using "$output/tablas_provincias.xlsx", ///
    sheet("prom_estructura_edad") firstrow(varlabels) sheetreplace


/********************************************************************
* DEMOGRAFÍA
* Tabla de Natalidad, Mortalidad, Envejecimiento
********************************************************************/

* Base salud
use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear

keep ind_mpio tasa_natalidad tasa_mortalidad crec_vegetativo

* Merge con población municipal total 2025 para traer I_enve_T
merge 1:1 ind_mpio using "$data/poblacion_municipal_total_2025.dta", ///
    keepusing(nvl_label I_enve_T)
drop _merge

* Merge con códigos municipales limpios para subregión completa
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio nvl_label subregion ///
     tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T

tempfile full subreg depto base promedio

save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
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
    (mean) tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
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
    (mean) tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
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

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable tipo_fila          "Tipo de fila"
label variable tasa_natalidad     "Tasa de Natalidad"
label variable tasa_mortalidad    "Tasa de Mortalidad"
label variable crec_vegetativo    "Crecimiento Vegetativo"
label variable I_enve_T           "Índice de Envejecimiento"

format tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
    using "$output/tablas_provincias.xlsx", ///
    sheet("prom_natalidad_mortalidad") firstrow(varlabels) sheetreplace


/********************************************************************
* GOBERNABILIDAD
********************************************************************/ 	
*--------------------------------------------------
* Tabla Medición Desempeño Municipal MDM
*--------------------------------------------------

*--------------------------------------------------
* 1. Importar población municipal desde Excel
*--------------------------------------------------
import excel "$data/i_datalake_ges_pub_dicc_2024.xlsx", firstrow clear sheet("Data")
*destring ind_mpio, replace

*--------------------------------------------------
* 2. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*--------------------------------------------------
* MDM
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia med_d_mun

    * Base municipal
    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    * Base única de subregión por provincia
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio por provincia
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) med_d_mun ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio      "Código DANE"
    label variable nvl_label     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"
    label variable med_d_mun     "Medición de Desempeño Municipal"

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        med_d_mun ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("mdm") firstrow(varlabels) sheetreplace

restore


*--------------------------------------------------
* IDF
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia idf

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) idf ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio      "Código DANE"
    label variable nvl_label     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"
    label variable idf           "Índice de Desempeño Fiscal"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        idf ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("idf") firstrow(varlabels) sheetreplace

restore

*-------------------------
* TD en jóvenes, nini
*-------------------------

preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_td urb_td rur_td ///
         tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
         tot_nini urb_nini rur_nini

    rename NomMunicipio municipio

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) ///
        tot_td urb_td rur_td ///
        tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
        tot_nini urb_nini rur_nini ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila municipio

    label variable ind_mpio      "Código DANE"
    label variable municipio     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"

    label variable tot_td        "Tasa de desocupación total"
    label variable urb_td        "Tasa de desocupación urbana"
    label variable rur_td        "Tasa de desocupación rural"

    label variable tot_td_15_28  "Tasa de desocupación 15-28 total"
    label variable urb_td_15_28  "Tasa de desocupación 15-28 urbana"
    label variable rur_td_15_28  "Tasa de desocupación 15-28 rural"

    label variable tot_nini      "Ninis total"
    label variable urb_nini      "Ninis urbano"
    label variable rur_nini      "Ninis rural"

    format tot_* urb_* rur_* %6.1f

    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_td urb_td rur_td ///
        tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
        tot_nini urb_nini rur_nini ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_desocupacion_nini") ///
        firstrow(varlabels) sheetreplace

restore


********************
** CLIMA **
**********************************


*-----------------
* IRCA
*-----------------
import excel "$rawdata/Indice de riesgo de calidad del agua (IRCA) 2024.xlsx", firstrow clear

drop if Municipio =="#TODOS"
rename MunicipioCodigo ind_mpio
destring ind_mpio, replace

keep ind_mpio IRCA IRCAurbano IRCArural

foreach v in IRCAurbano IRCArural {
    replace `v' = "" if `v' == "ND"
    destring `v', replace
}

*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         IRCA IRCAurbano IRCArural

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) IRCA IRCAurbano IRCArural ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"
    label variable IRCA        "IRCA total"
    label variable IRCAurbano  "IRCA urbano"
    label variable IRCArural   "IRCA rural"

    format IRCA IRCAurbano IRCArural %6.2f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IRCA IRCAurbano IRCArural ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("irca") firstrow(varlabels) sheetreplace

restore


*-----------------
* Índice de riesgo ajustado por capacidades (DEFICIT DE LLUVIAS)
*-----------------

import excel "$rawdata/Indice gestion capacidades 2024.xlsx", cellrange(A2) firstrow clear sheet("Deficit de Lluvias")

keep if Departamento =="ANTIOQUIA"
count

rename DIVIPOLA ind_mpio
destring ind_mpio, replace

rename Indicederiesgodedesastresaj IMRC_D
keep ind_mpio IMRC_D
label variable IMRC_D    "INDICE DE RIESGO DE DESASTRE AJUSTADO POR CAPACIDADES - DEFICIT DE LLUVIAS"


*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia IMRC_D

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) IMRC_D ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable IMRC_D ///
        "Índice de Riesgo de Desastre Ajustado por Capacidades - Déficit de lluvias"

    format IMRC_D %6.2f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IMRC_D ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("imrc_deficit_lluvias") ///
        firstrow(varlabels) sheetreplace

restore




*-----------------
* Índice de riesgo ajustado por capacidades (EXCESO DE LLUVIAS)
*-----------------

import excel "$rawdata/Indice gestion capacidades 2024.xlsx", cellrange(A2) firstrow clear sheet("Exceso de Lluvias")

keep if Departamento =="ANTIOQUIA"
count

rename DIVIPOLA ind_mpio
destring ind_mpio, replace

rename Indicederiesgodedesastresaj IMRC_E
keep ind_mpio IMRC_E
label variable IMRC_E    "INDICE DE RIESGO DE DESASTRE AJUSTADO POR CAPACIDADES - EXCESO DE LLUVIAS"


*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia IMRC_E

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) IMRC_E ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable IMRC_E ///
        "Índice de Riesgo de Desastre Ajustado por Capacidades - Exceso de lluvias"

    format IMRC_E %6.2f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IMRC_E ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("imrc_exceso_lluvias") ///
        firstrow(varlabels) sheetreplace

restore
