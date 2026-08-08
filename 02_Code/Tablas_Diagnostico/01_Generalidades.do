* ----------------------------------------------------------------------------
* PROVINCIAS - 01_Generalidades.do
* SECCION 1: GENERALIDADES
* FIGURAS: Distribución territorial de la PAP por municipio
*          (% de la superficie provincial)
* INPUTS: $rawdata/AREA_ORIGINAL.xlsx, $rawdata/códigos_provincias.dta
* OUTPUTS: $out_01 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


/********************************************************************
* 1.1 Distribución territorial (área municipal y participación provincial)
*     Área municipal desde AREA_ORIGINAL.xlsx (00_Inputs); provincia y
*     subregión por merge con códigos_provincias.dta (COD_MPIO -> ind_mpio).
*     Exporta: área de cada municipio, la participación % del área municipal
*     en el total provincial, y las áreas totales de la provincia, de la
*     subregión mayoritaria (todos sus municipios) y del departamento (Antioquia).
********************************************************************/

import excel "$rawdata/AREA_ORIGINAL.xlsx", sheet("Area") firstrow clear

rename COD_MPIO ind_mpio
destring ind_mpio, replace force
rename AREAKM2 area_km2
destring area_km2, replace force

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión DANE completa (125 municipios) para el agregado de subregión
merge m:1 ind_mpio using "$rawdata/subreg_completo.dta", keep(master match) nogen

* --- Base con TODOS los municipios (para totales de subregión y departamento) ---
tempfile area_all
save `area_all'

* --- Municipios de la provincia seleccionada ---
keep if id_provincia == $id_provincia

* --- Participación del área municipal en el total provincial ---
egen area_total_prov = total(area_km2)
gen participacion_area_prov_pct = area_km2 / area_total_prov

keep ind_mpio nvl_label subregion provincia area_km2 participacion_area_prov_pct
gen tipo_fila = "Municipio"

tempfile base
save `base'

*----------------------------------*
* Total provincial (suma de los municipios de la provincia)
*----------------------------------*
collapse (sum) area_km2 (count) n_municipios = ind_mpio, by(provincia)
gen nvl_label                   = "TOTAL PROVINCIA $provincia_label"
gen tipo_fila                   = "Total provincia"
gen ind_mpio                    = .
gen subregion                   = ""
gen participacion_area_prov_pct = 1
tempfile total_prov
save `total_prov'

*----------------------------------*
* Total subregión mayoritaria (suma de TODOS sus municipios)
*----------------------------------*
use `area_all', clear
keep if id_provincia == $id_provincia
contract subregion_full
gsort -_freq subregion_full
local dom_subreg = subregion_full[1]

use `area_all', clear
keep if subregion_full == "`dom_subreg'"
collapse (sum) area_km2
gen nvl_label = "TOTAL SUBREGIÓN `dom_subreg'"
gen provincia = ""
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile total_sub
save `total_sub'

*----------------------------------*
* Total departamento (suma de TODOS los municipios de Antioquia)
*----------------------------------*
use `area_all', clear
collapse (sum) area_km2
gen nvl_label = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile total_dep
save `total_dep'

*----------------------------------*
* Unir todo
*----------------------------------*
use `base', clear
append using `total_prov'
append using `total_sub'
append using `total_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"

sort orden_fila nvl_label

*----------------------------------*
* Labels
*----------------------------------*
label variable ind_mpio                    "Código DANE"
label variable nvl_label                   "Municipio"
label variable subregion                   "Subregión"
label variable provincia                   "Provincia"
label variable area_km2                    "Área municipal (km²)"
label variable participacion_area_prov_pct "Proporción del territorio municipal sobre total provincial"

format area_km2 %12.2f
format participacion_area_prov_pct %6.4f

capture erase "$out_01/distribucion_territorial.xlsx"

export excel ///
    ind_mpio nvl_label subregion provincia ///
    area_km2 participacion_area_prov_pct ///
    using "$out_01/distribucion_territorial.xlsx", ///
    sheet("distribucion_territorial") firstrow(varlabels) sheetreplace


di as text "  01_Generalidades: tabla exportada en $out_01/"
