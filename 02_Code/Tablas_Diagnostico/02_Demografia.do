* ----------------------------------------------------------------------------
* PROVINCIAS - 02_Demografia.do
* SECCION 2: DEMOGRAFIA
* FIGURAS:
*   - Proyecciones de poblacion 2025 (total, cabecera, rural y participaciones)
*   - Composicion urbana-rural (% cabecera / % rural)
*   - Densidad poblacional (hab/km2)
*   - Distribucion por genero y grupos de edad
*   - Tasa de Natalidad y Tasa de Mortalidad
*   - Indice de Envejecimiento
* INPUTS:
*   $rawdata/POBLACION MUNICIPAL.xlsx        (hojas base y Rangos_Quintenios)
*   $rawdata/AREA_ORIGINAL.xlsx              (hoja Area)
*   $rawdata/codigos_provincias.dta
*   $data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA  (tasa_natalidad, tasa_mortalidad)
*   $data/poblacion_municipal_total_2025_dicc       (I_enve_T)
* OUTPUTS: $out_02/demografia.xlsx (hojas: poblacion, estructura_edad, natalidad_mortalidad)
* REQUIERE: 00_master.do (define globals)
* NOTA: el agregado provincial de TASAS/INDICE se calcula PONDERADO por poblacion
*       ( Sum(tasa_i*pob_i)/Sum(pob_i) = tasa agregada ), no como promedio simple.
* ----------------------------------------------------------------------------

capture erase "$out_02/demografia.xlsx"


/********************************************************************
* 0. Tempfile de area municipal (para densidad) - provincia seleccionada
********************************************************************/

import excel "$rawdata/AREA_ORIGINAL.xlsx", sheet("Area") firstrow clear
rename COD_MPIO ind_mpio
destring ind_mpio, replace force
rename AREAKM2 area_km2
destring area_km2, replace force
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
keep ind_mpio area_km2

tempfile area_prov
save `area_prov'


/********************************************************************
* 2.1 Poblacion 2025: total / cabecera / rural, participaciones y densidad
*     Figuras: Proyecciones de poblacion, Composicion urbana-rural, Densidad
********************************************************************/

import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep DPMP ÁREAGEOGRÁFICA TotalGeneral

rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

rename TotalGeneral habitantes

gen area_cat = ""
replace area_cat = "total"    if ÁREAGEOGRÁFICA == "Total"
replace area_cat = "cabecera" if ÁREAGEOGRÁFICA == "Cabecera Municipal"
replace area_cat = "rural"    if ÁREAGEOGRÁFICA == "Centros Poblados y Rural Disperso"
drop if area_cat == ""

keep ind_mpio nvl_label subregion provincia area_cat habitantes
reshape wide habitantes, i(ind_mpio nvl_label subregion provincia) j(area_cat) string

rename habitantestotal    habitantes_total
rename habitantescabecera habitantes_cabecera
rename habitantesrural    habitantes_rural

* --- Densidad (hab/km2) ---
merge 1:1 ind_mpio using "`area_prov'", nogen
gen densidad_pob = habitantes_total / area_km2

* --- Participaciones y porcentajes urbano/rural ---
egen prov_total    = total(habitantes_total)
egen prov_cabecera = total(habitantes_cabecera)
egen prov_rural    = total(habitantes_rural)

gen part_total_prov = habitantes_total    / prov_total   
gen part_cab_prov   = habitantes_cabecera / prov_cabecera
gen part_rural_prov = habitantes_rural    / prov_rural   

gen pct_cabecera = habitantes_cabecera / habitantes_total
gen pct_rural    = habitantes_rural    / habitantes_total

* --- Guardar poblacion municipal para ponderar tasas (bloque 2.3) ---
preserve
    keep ind_mpio habitantes_total
    tempfile pobtot
    save `pobtot'
restore

* --- Fila de total provincial ---
gen tipo_fila = "Municipio"
tempfile base_pob
save `base_pob'

collapse (sum) habitantes_total habitantes_cabecera habitantes_rural area_km2, by(provincia)
gen densidad_pob    = habitantes_total / area_km2
gen pct_cabecera    = habitantes_cabecera / habitantes_total
gen pct_rural       = habitantes_rural    / habitantes_total
gen part_total_prov = 1
gen part_cab_prov   = 1
gen part_rural_prov = 1
gen nvl_label       = "TOTAL PROVINCIA $provincia_label"
gen subregion       = ""
gen ind_mpio        = .
gen tipo_fila       = "Total provincia"

append using `base_pob'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
sort orden_fila nvl_label

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable habitantes_total   "Población total"
label variable part_total_prov    "Participación en el total provincial (%)"
label variable habitantes_cabecera "Población urbana"
label variable pct_cabecera       "Porcentaje de población urbana"
label variable part_cab_prov      "Participación urbana en el total provincial (%)"
label variable habitantes_rural   "Población rural"
label variable pct_rural          "Porcentaje de población rural"
label variable part_rural_prov    "Participación rural en el total provincial (%)"
label variable densidad_pob       "Densidad poblacional (hab/km²)"

format habitantes_* %12.0f
format pct_* part_* %6.1f
format densidad_pob %8.1f

* --- Totales de subregión mayoritaria y departamento (población total/urbana/rural) ---
* Suma sobre los municipios de la subregión y de todo el departamento.
preserve
    import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
    keep if AÑO == 2025
    keep DPMP ÁREAGEOGRÁFICA TotalGeneral
    rename DPMP ind_mpio
    destring ind_mpio, replace
    destring TotalGeneral, replace force
    rename TotalGeneral habitantes
    gen area_cat = ""
    replace area_cat = "total"    if ÁREAGEOGRÁFICA == "Total"
    replace area_cat = "cabecera" if ÁREAGEOGRÁFICA == "Cabecera Municipal"
    replace area_cat = "rural"    if ÁREAGEOGRÁFICA == "Centros Poblados y Rural Disperso"
    drop if area_cat == ""
    keep ind_mpio area_cat habitantes
    reshape wide habitantes, i(ind_mpio) j(area_cat) string
    rename habitantestotal    habitantes_total
    rename habitantescabecera habitantes_cabecera
    rename habitantesrural    habitantes_rural
    tempfile fullpob
    save `fullpob'

    * Total departamento (TODOS los municipios de Antioquia del archivo, no solo los de la PAP)
    collapse (sum) habitantes_total habitantes_cabecera habitantes_rural
    gen pct_cabecera = habitantes_cabecera / habitantes_total
    gen pct_rural    = habitantes_rural    / habitantes_total
    gen nvl_label = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subregion = ""
    gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
    gen ind_mpio  = .
    gen tipo_fila = "Total departamento"
    tempfile tdep
    save `tdep'

    * Traer subregión por merge con códigos (para el total de subregión)
    use `fullpob', clear
    merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
    tempfile fullpob2
    save `fullpob2'

    * Subregión mayoritaria entre los municipios de la provincia
    keep if id_provincia == $id_provincia
    contract subregion
    gsort -_freq subregion
    local dom_subreg = subregion[1]

    * Total subregión mayoritaria (todos sus municipios)
    use `fullpob2', clear
    keep if subregion == "`dom_subreg'"
    collapse (sum) habitantes_total habitantes_cabecera habitantes_rural
    gen pct_cabecera = habitantes_cabecera / habitantes_total
    gen pct_rural    = habitantes_rural    / habitantes_total
    gen nvl_label = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion = ""
    gen provincia = ""
    gen ind_mpio  = .
    gen tipo_fila = "Total subregión"
    tempfile tsub
    save `tsub'
restore

append using `tsub'
append using `tdep'
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

export excel ///
    ind_mpio nvl_label subregion provincia ///
    habitantes_total part_total_prov ///
    habitantes_cabecera pct_cabecera part_cab_prov ///
    habitantes_rural pct_rural part_rural_prov ///
    densidad_pob ///
    using "$out_02/demografia.xlsx", ///
    sheet("poblacion") firstrow(varlabels) sheetreplace


/********************************************************************
* 2.2 Estructura por genero y grupos de edad (2025, area Total)
*     Figura: Distribucion por genero y grupos de edad
********************************************************************/

import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear sheet("Rangos_Quintenios")
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"

rename DPMP ind_mpio
destring ind_mpio, replace

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

* Poblacion por sexo (suma de quinquenios)
egen pob_masc = rowtotal(Hombre04 Hombre59 Hombre1014 Hombre1519 Hombre2024 ///
    Hombre2529 Hombre3034 Hombre3539 Hombre4044 Hombre4549 Hombre5054 ///
    Hombre5559 Hombre6064 Hombre6569 Hombre7074 Hombre7579 Hombre8084 Hombre85ymás)
egen pob_fem = rowtotal(Mujeres04 Mujeres59 Mujeres1014 Mujeres1519 Mujeres2024 ///
    Mujeres2529 Mujeres3034 Mujeres3539 Mujeres4044 Mujeres4549 Mujeres5054 ///
    Mujeres5559 Mujeres6064 Mujeres6569 Mujeres7074 Mujeres7579 Mujeres8084 Mujeres85ymás)

* Grupos de edad de 10 anios (a partir de los quinquenios TOTAL)
gen edad_0_9    = TOTAL04   + TOTAL59
gen edad_10_19  = TOTAL1014 + TOTAL1519
gen edad_20_29  = TOTAL2024 + TOTAL2529
gen edad_30_39  = TOTAL3034 + TOTAL3539
gen edad_40_49  = TOTAL4044 + TOTAL4549
gen edad_50_59  = TOTAL5054 + TOTAL5559
gen edad_60_69  = TOTAL6064 + TOTAL6569
gen edad_70_79  = TOTAL7074 + TOTAL7579
gen edad_80_mas = TOTAL8084 + TOTAL85ymás

* Grupos de edad de 10 anios POR SEXO (para la piramide poblacional: edad x sexo)
* Hombres
gen h_edad_0_9    = Hombre04   + Hombre59
gen h_edad_10_19  = Hombre1014 + Hombre1519
gen h_edad_20_29  = Hombre2024 + Hombre2529
gen h_edad_30_39  = Hombre3034 + Hombre3539
gen h_edad_40_49  = Hombre4044 + Hombre4549
gen h_edad_50_59  = Hombre5054 + Hombre5559
gen h_edad_60_69  = Hombre6064 + Hombre6569
gen h_edad_70_79  = Hombre7074 + Hombre7579
gen h_edad_80_mas = Hombre8084 + Hombre85ymás
* Mujeres
gen m_edad_0_9    = Mujeres04   + Mujeres59
gen m_edad_10_19  = Mujeres1014 + Mujeres1519
gen m_edad_20_29  = Mujeres2024 + Mujeres2529
gen m_edad_30_39  = Mujeres3034 + Mujeres3539
gen m_edad_40_49  = Mujeres4044 + Mujeres4549
gen m_edad_50_59  = Mujeres5054 + Mujeres5559
gen m_edad_60_69  = Mujeres6064 + Mujeres6569
gen m_edad_70_79  = Mujeres7074 + Mujeres7579
gen m_edad_80_mas = Mujeres8084 + Mujeres85ymás

keep ind_mpio nvl_label subregion provincia pob_masc pob_fem ///
     edad_0_9 edad_10_19 edad_20_29 edad_30_39 edad_40_49 ///
     edad_50_59 edad_60_69 edad_70_79 edad_80_mas ///
     h_edad_0_9 h_edad_10_19 h_edad_20_29 h_edad_30_39 h_edad_40_49 ///
     h_edad_50_59 h_edad_60_69 h_edad_70_79 h_edad_80_mas ///
     m_edad_0_9 m_edad_10_19 m_edad_20_29 m_edad_30_39 m_edad_40_49 ///
     m_edad_50_59 m_edad_60_69 m_edad_70_79 m_edad_80_mas

gen tipo_fila = "Municipio"
tempfile base_edad
save `base_edad'

* Total provincia (suma)
collapse (sum) pob_masc pob_fem edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
    edad_40_49 edad_50_59 edad_60_69 edad_70_79 edad_80_mas ///
    h_edad_0_9 h_edad_10_19 h_edad_20_29 h_edad_30_39 h_edad_40_49 ///
    h_edad_50_59 h_edad_60_69 h_edad_70_79 h_edad_80_mas ///
    m_edad_0_9 m_edad_10_19 m_edad_20_29 m_edad_30_39 m_edad_40_49 ///
    m_edad_50_59 m_edad_60_69 m_edad_70_79 m_edad_80_mas, by(provincia)
gen nvl_label = "TOTAL PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total provincia"
tempfile total_edad
save `total_edad'

use `base_edad', clear
append using `total_edad'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
sort orden_fila nvl_label

label variable ind_mpio    "Código DANE"
label variable nvl_label   "Municipio"
label variable subregion   "Subregión"
label variable provincia   "Provincia"
label variable pob_masc    "Población masculina"
label variable pob_fem     "Población femenina"
label variable edad_0_9    "0 a 9"
label variable edad_10_19  "10 a 19"
label variable edad_20_29  "20 a 29"
label variable edad_30_39  "30 a 39"
label variable edad_40_49  "40 a 49"
label variable edad_50_59  "50 a 59"
label variable edad_60_69  "60 a 69"
label variable edad_70_79  "70 a 79"
label variable edad_80_mas "80 o más"
label variable h_edad_0_9    "Hombres 0 a 9"
label variable h_edad_10_19  "Hombres 10 a 19"
label variable h_edad_20_29  "Hombres 20 a 29"
label variable h_edad_30_39  "Hombres 30 a 39"
label variable h_edad_40_49  "Hombres 40 a 49"
label variable h_edad_50_59  "Hombres 50 a 59"
label variable h_edad_60_69  "Hombres 60 a 69"
label variable h_edad_70_79  "Hombres 70 a 79"
label variable h_edad_80_mas "Hombres 80 o más"
label variable m_edad_0_9    "Mujeres 0 a 9"
label variable m_edad_10_19  "Mujeres 10 a 19"
label variable m_edad_20_29  "Mujeres 20 a 29"
label variable m_edad_30_39  "Mujeres 30 a 39"
label variable m_edad_40_49  "Mujeres 40 a 49"
label variable m_edad_50_59  "Mujeres 50 a 59"
label variable m_edad_60_69  "Mujeres 60 a 69"
label variable m_edad_70_79  "Mujeres 70 a 79"
label variable m_edad_80_mas "Mujeres 80 o más"

format pob_masc pob_fem edad_* h_edad_* m_edad_* %12.0f

export excel ///
    ind_mpio nvl_label subregion provincia pob_masc pob_fem ///
    edad_0_9 edad_10_19 edad_20_29 edad_30_39 edad_40_49 ///
    edad_50_59 edad_60_69 edad_70_79 edad_80_mas ///
    h_edad_0_9 h_edad_10_19 h_edad_20_29 h_edad_30_39 h_edad_40_49 ///
    h_edad_50_59 h_edad_60_69 h_edad_70_79 h_edad_80_mas ///
    m_edad_0_9 m_edad_10_19 m_edad_20_29 m_edad_30_39 m_edad_40_49 ///
    m_edad_50_59 m_edad_60_69 m_edad_70_79 m_edad_80_mas ///
    using "$out_02/demografia.xlsx", ///
    sheet("estructura_edad") firstrow(varlabels) sheetreplace


/********************************************************************
* 2.3 Natalidad, Mortalidad e Indice de Envejecimiento
*     Figuras: Tasa de Natalidad y Mortalidad, Indice de Envejecimiento
*     Agregado provincial PONDERADO por poblacion.
********************************************************************/

use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear
keep ind_mpio tasa_natalidad tasa_mortalidad

merge 1:1 ind_mpio using "$data/poblacion_municipal_total_2025_dicc", ///
    keepusing(I_enve_T) keep(master match) nogen

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

* Peso poblacional (poblacion total municipal 2025)
merge 1:1 ind_mpio using "`pobtot'", keep(master match) nogen

keep ind_mpio nvl_label subregion provincia habitantes_total ///
     tasa_natalidad tasa_mortalidad I_enve_T

gen tipo_fila = "Municipio"
tempfile base_nat
save `base_nat'

* --- Agregado provincial ponderado por poblacion ---
gen xn = tasa_natalidad  * habitantes_total
gen xm = tasa_mortalidad * habitantes_total
gen xe = I_enve_T        * habitantes_total
gen wn = habitantes_total if !missing(tasa_natalidad)
gen wm = habitantes_total if !missing(tasa_mortalidad)
gen we = habitantes_total if !missing(I_enve_T)

collapse (sum) xn xm xe wn wm we, by(provincia)
gen tasa_natalidad  = xn / wn
gen tasa_mortalidad = xm / wm
gen I_enve_T        = xe / we
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"
keep ind_mpio nvl_label subregion provincia tasa_natalidad tasa_mortalidad I_enve_T tipo_fila

append using `base_nat'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
sort orden_fila nvl_label

label variable ind_mpio        "Código DANE"
label variable nvl_label       "Municipio"
label variable subregion       "Subregión"
label variable provincia       "Provincia"
label variable tasa_natalidad  "Tasa de Natalidad"
label variable tasa_mortalidad "Tasa de Mortalidad"
label variable I_enve_T        "Índice de Envejecimiento"

format tasa_natalidad tasa_mortalidad I_enve_T %8.2f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    tasa_natalidad tasa_mortalidad I_enve_T ///
    using "$out_02/demografia.xlsx", ///
    sheet("natalidad_mortalidad") firstrow(varlabels) sheetreplace


/********************************************************************
* 2.4 Tasa Neta de Migración (ECV 2023)
*   Fuente: INDICADORES ECV 2023 MUNICIPIOS.xlsx (hoja DEMOGRAFÍA, indicador TNM).
*   Valor_tot = total ; Valor_urb = cabecera ; Valor_rur = centros poblados/rural.
*   Se lee el crudo directamente (misma estrategia ECV, sin regenerar derivados).
*   Agregado provincial ponderado por población (TNM es una tasa).
********************************************************************/

* TNM municipal (todos los municipios de la ECV)
import excel "$rawdata/INDICADORES ECV 2023 MUNICIPIOS.xlsx", sheet("DEMOGRAFÍA") firstrow clear
keep if Indicador == "TNM"
rename Municipio ind_mpio
destring ind_mpio, replace force
rename Valor_tot tot_tnm
rename Valor_urb urb_tnm
rename Valor_rur rur_tnm
destring tot_tnm urb_tnm rur_tnm, replace force
keep ind_mpio tot_tnm urb_tnm rur_tnm
tempfile tnm_all
save `tnm_all'

* Poblacion total municipal 2025 (todos) para ponderar
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob
tempfile pob_all
save `pob_all'

* Base municipal: TNM + poblacion + subregión/provincia
use `tnm_all', clear
merge 1:1 ind_mpio using "`pob_all'", keep(match) nogen
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
tempfile mig_all
save `mig_all'

* --- Total departamento (ponderado por población, TODOS los municipios) ---
foreach v in tot_tnm urb_tnm rur_tnm {
    gen _x_`v' = `v' * pob
    gen _w_`v' = pob if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tot_tnm urb_tnm rur_tnm {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por población)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile mtdep
save `mtdep'

* --- Subregión mayoritaria (ponderado por población) ---
use `mig_all', clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

use `mig_all', clear
keep if subregion == "`dom_subreg'"
foreach v in tot_tnm urb_tnm rur_tnm {
    gen _x_`v' = `v' * pob
    gen _w_`v' = pob if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tot_tnm urb_tnm rur_tnm {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO SUBREGIÓN `dom_subreg' (por población)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile mtsub
save `mtsub'

* --- Provincia (ponderado) + municipios ---
use `mig_all', clear
keep if id_provincia == $id_provincia
gen tipo_fila = "Municipio"
tempfile base_mig
save `base_mig'

foreach v in tot_tnm urb_tnm rur_tnm {
    gen _x_`v' = `v' * pob
    gen _w_`v' = pob if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in tot_tnm urb_tnm rur_tnm {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"

append using `base_mig'
append using `mtsub'
append using `mtdep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable tot_tnm   "Tasa neta de migración - total"
label variable urb_tnm   "Tasa neta de migración - cabecera municipal"
label variable rur_tnm   "Tasa neta de migración - centros poblados y rural"
format tot_tnm urb_tnm rur_tnm %8.2f

export excel ind_mpio nvl_label subregion provincia tot_tnm urb_tnm rur_tnm ///
    using "$out_02/demografia.xlsx", sheet("migracion") firstrow(varlabels) sheetreplace


di as text "  02_Demografia: 4 hojas exportadas en $out_02/demografia.xlsx"
