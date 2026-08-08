* ----------------------------------------------------------------------------
* PROVINCIAS - 05_Economia.do
* SECCION 5: ECONOMIA
* FIGURAS: Evolución visitantes extranjeros por municipio, Comparativo visitantes
*          PAP vs Antioquia, ECV pobreza/laboral, turismo, IDE, densidad,
*          valor agregado, 5.3 minero-energético XM (2026-08-05).
* INPUTS: $data/EXTRANJEROS_PROVINCIAS.xlsx
* OUTPUTS: $out_05 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


* Un solo archivo por seccion: borrar una vez antes de escribir las hojas
capture erase "$out_05/economia.xlsx"

/********************************************************************
* 5.1 Evolución de visitantes extranjeros no residentes por municipio
********************************************************************/

import excel "$data/EXTRANJEROS_PROVINCIAS.xlsx", sheet("Extranjeros") firstrow clear
destring CODIGO_MUN, replace force

keep CODIGO_MUN Ciudad subreg prov Año CantExtranjerosnoResidentes
rename CantExtranjerosnoResidentes extranjeros
rename CODIGO_MUN cod_mun
tempfile ext_all
save `ext_all'

* --- Municipios de la provincia ---
use `ext_all', clear
keep if prov == "$provincia_nombre"
gen tipo_fila = "Municipio"
tempfile base
save `base'

* --- Total provincial por año ---
use `ext_all', clear
keep if prov == "$provincia_nombre"
collapse (sum) extranjeros (count) n_municipios = cod_mun, by(prov Año)
gen Ciudad = "TOTAL PROVINCIA $provincia_label"
gen tipo_fila = "Total provincia"
gen cod_mun = .
gen subreg = "TOTAL PROVINCIA"
tempfile total_prov
save `total_prov'

* --- Total subregión mayoritaria por año (todos sus municipios) ---
use `ext_all', clear
keep if prov == "$provincia_nombre"
contract subreg
gsort -_freq subreg
local dom_subreg = subreg[1]

use `ext_all', clear
keep if subreg == "`dom_subreg'"
collapse (sum) extranjeros, by(Año)
gen Ciudad = "TOTAL SUBREGIÓN `dom_subreg'"
gen tipo_fila = "Total subregión"
gen cod_mun = .
gen subreg = ""
gen prov = ""
tempfile total_sub
save `total_sub'

* --- Total departamento por año (todos los municipios de Antioquia) ---
use `ext_all', clear
collapse (sum) extranjeros, by(Año)
gen Ciudad = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
gen tipo_fila = "Total departamento"
gen cod_mun = .
gen subreg = ""
gen prov = "DEPARTAMENTO DE ANTIOQUIA"
tempfile total_dep
save `total_dep'

* --- Unir todo ---
use `base', clear
append using `total_prov'
append using `total_sub'
append using `total_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort Año orden_fila Ciudad

*----------------------------------*
* Labels
*----------------------------------*
label variable cod_mun     "Código DANE"
label variable Ciudad      "Municipio"
label variable subreg      "Subregión"
label variable prov        "Provincia"
label variable tipo_fila   "Tipo de fila"
label variable Año         "Año"
label variable extranjeros "Visitantes extranjeros no residentes"

format extranjeros %12.0f

export excel ///
    cod_mun Ciudad subreg prov tipo_fila Año ///
    extranjeros ///
    using "$out_05/economia.xlsx", ///
    sheet("extranjeros_municipio") firstrow(varlabels) sheetreplace


/********************************************************************
* 5.2 Comparativo visitantes PAP vs Antioquia
*     Total provincial (serie temporal) vs total departamental
********************************************************************/

import excel "$data/EXTRANJEROS_PROVINCIAS.xlsx", sheet("Extranjeros") firstrow clear

preserve

    rename CantExtranjerosnoResidentes extranjeros

    * Total departamental por año
    collapse (sum) extranjeros, by(Año)
    rename extranjeros total_antioquia_extranjeros

    tempfile dept
    save `dept'

restore

preserve

    rename CantExtranjerosnoResidentes extranjeros

    * Total provincial por año
    keep if prov == "$provincia_nombre"

    collapse (sum) extranjeros, by(Año prov)
    rename extranjeros total_provincia_extranjeros

    * Merge con total departamental
    merge 1:1 Año using `dept', nogen

    gen participacion_extranjeros_pct = (total_provincia_extranjeros / total_antioquia_extranjeros)
    format participacion_extranjeros_pct %6.2f

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable Año               "Año"
    label variable prov              "Provincia"
    label variable total_provincia_extranjeros   "Visitantes extranjeros provincia"
    label variable total_antioquia_extranjeros   "Visitantes extranjeros Antioquia"
    label variable participacion_extranjeros_pct "Participación de la provincia en el total departamental (%)"

    export excel ///
        Año prov total_provincia_extranjeros total_antioquia_extranjeros participacion_extranjeros_pct ///
        using "$out_05/economia.xlsx", ///
        sheet("comparativo_pap_antioquia") firstrow(varlabels) sheetreplace

restore


* ============================================================================
* SECCION 5.1 (Laura): POBREZA Y MERCADO LABORAL  — Fuente: ECV_nbi_pobreza.dta
* ----------------------------------------------------------------------------
* Provincia y subregion por merge con codigos_provincias (ECV no trae prov).
* Agregado provincial PONDERADO por poblacion municipal:
*     valor_prov = Sum(valor_i * pob_i) / Sum(pob_i | valor_i no faltante)
* NOTA METODOLOGICA: para % de personas (NBI, IPM personas, ocupacion,
*   informalidad, desocupacion) el ponderado es correcto. Para IPM hogares y
*   Gini (indice) y NiNi (base = jovenes) el peso poblacional total es una
*   APROXIMACION (revisar en fase de debugging).
* ============================================================================

* --- Peso poblacional: poblacion total municipal 2025 ---
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pesos
save `pesos'

* --- Base ECV de la provincia ---
use "$data/ECV_nbi_pobreza.dta", clear
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge 1:1 ind_mpio using "`pesos'", keep(master match) nogen
tempfile ecv_prov
save `ecv_prov'


* --- 5.1.1 Pobreza por NBI — agregados OFICIALES ECV (municipios: referencia) ---
* Subregión y departamento: valor oficial ECV. Provincia: oficial si es de las 6
* con dato; si no, promedio ponderado por población (válido para % de personas).
* REQUIERE: 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.

* Subregión dominante (crosswalk 125)
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* Municipios (fracción 0-1)
use `ecv_prov', clear
keep ind_mpio nvl_label subregion provincia pob_peso tot_pob_nbi urb_pob_nbi rur_pob_nbi
foreach v in tot_pob_nbi urb_pob_nbi rur_pob_nbi {
    replace `v' = `v' / 100
}
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base
save `base'

* Provincia: oficial si existe; si no, promedio ponderado por población
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="PROVINCIA" & key=="${id_provincia}"
if _N > 0 {
    keep tot_pob_nbi urb_pob_nbi rur_pob_nbi
    gen nvl_label = "PROVINCIA $provincia_label (ECV oficial)"
}
else {
    use `base', clear
    foreach v in tot_pob_nbi urb_pob_nbi rur_pob_nbi {
        gen _x_`v' = `v' * pob_peso
        gen _w_`v' = pob_peso if !missing(`v')
    }
    collapse (sum) _x_* _w_*
    foreach v in tot_pob_nbi urb_pob_nbi rur_pob_nbi {
        gen `v' = _x_`v' / _w_`v'
    }
    drop _x_* _w_*
    gen nvl_label = "PROVINCIA $provincia_label (promedio ponderado; sin ECV oficial)"
}
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia tot_pob_nbi urb_pob_nbi rur_pob_nbi tipo_fila orden_fila
tempfile p_nbi
save `p_nbi'

* Subregión dominante (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
keep tot_pob_nbi urb_pob_nbi rur_pob_nbi
gen nvl_label  = "SUBREGIÓN `dom_subreg' (ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión"
gen orden_fila = 3
tempfile s_nbi
save `s_nbi'

* Departamento (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="DEPARTAMENTO" & key=="ANTIOQUIA"
keep tot_pob_nbi urb_pob_nbi rur_pob_nbi
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento"
gen orden_fila = 4
tempfile d_nbi
save `d_nbi'

* Unir: municipios (referencia) + agregados
use `base', clear
append using `p_nbi'
append using `s_nbi'
append using `d_nbi'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_pob_nbi urb_pob_nbi rur_pob_nbi {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio    "Código DANE"
label variable nvl_label   "Municipio"
label variable subregion   "Subregión"
label variable provincia   "Provincia"
label variable tot_pob_nbi_mun "Personas en pobreza por NBI - total (%) (municipal)"
label variable tot_pob_nbi_ofi "Personas en pobreza por NBI - total (%) (agregado)"
label variable urb_pob_nbi_mun "Personas en pobreza por NBI - urbana (%) (municipal)"
label variable urb_pob_nbi_ofi "Personas en pobreza por NBI - urbana (%) (agregado)"
label variable rur_pob_nbi_mun "Personas en pobreza por NBI - rural (%) (municipal)"
label variable rur_pob_nbi_ofi "Personas en pobreza por NBI - rural (%) (agregado)"
format tot_pob_nbi_mun tot_pob_nbi_ofi urb_pob_nbi_mun urb_pob_nbi_ofi rur_pob_nbi_mun rur_pob_nbi_ofi %6.1f
export excel ind_mpio nvl_label subregion provincia ///
    tot_pob_nbi_mun tot_pob_nbi_ofi urb_pob_nbi_mun urb_pob_nbi_ofi rur_pob_nbi_mun rur_pob_nbi_ofi ///
    using "$out_05/economia.xlsx", sheet("ecv_pobreza") firstrow(varlabels) sheetreplace

* --- 5.1.2 Pobreza IPM (personas y hogares, total) — OFICIAL ECV ---
* Subregión y departamento: oficial ECV. Provincia: oficial si es de las 6; si no,
* promedio ponderado por población (IPM personas: válido; IPM hogares: aproximación
* —lo correcto sería ponderar por hogares—, solo aplica a las 5 provincias sin oficial).
* REQUIERE: 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.

* Subregión dominante (crosswalk 125)
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

use `ecv_prov', clear
keep ind_mpio nvl_label subregion provincia pob_peso tot_pob_ipm tot_pob_ipm_hogares
foreach v in tot_pob_ipm tot_pob_ipm_hogares {
    replace `v' = `v' / 100
}
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base
save `base'

* Provincia: oficial si existe; si no, promedio ponderado por población
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="PROVINCIA" & key=="${id_provincia}"
if _N > 0 {
    keep tot_pob_ipm tot_pob_ipm_hogares
    gen nvl_label = "PROVINCIA $provincia_label (ECV oficial)"
}
else {
    use `base', clear
    foreach v in tot_pob_ipm tot_pob_ipm_hogares {
        gen _x_`v' = `v' * pob_peso
        gen _w_`v' = pob_peso if !missing(`v')
    }
    collapse (sum) _x_* _w_*
    foreach v in tot_pob_ipm tot_pob_ipm_hogares {
        gen `v' = _x_`v' / _w_`v'
    }
    drop _x_* _w_*
    gen nvl_label = "PROVINCIA $provincia_label (promedio ponderado; sin ECV oficial)"
}
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia tot_pob_ipm tot_pob_ipm_hogares tipo_fila orden_fila
tempfile p_ipm
save `p_ipm'

* Subregión dominante (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
keep tot_pob_ipm tot_pob_ipm_hogares
gen nvl_label  = "SUBREGIÓN `dom_subreg' (ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión"
gen orden_fila = 3
tempfile s_ipm
save `s_ipm'

* Departamento (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="DEPARTAMENTO" & key=="ANTIOQUIA"
keep tot_pob_ipm tot_pob_ipm_hogares
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento"
gen orden_fila = 4
tempfile d_ipm
save `d_ipm'

use `base', clear
append using `p_ipm'
append using `s_ipm'
append using `d_ipm'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_pob_ipm tot_pob_ipm_hogares {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio            "Código DANE"
label variable nvl_label           "Municipio"
label variable subregion           "Subregión"
label variable provincia           "Provincia"
label variable tot_pob_ipm_mun         "Personas en pobreza IPM - total (%) (municipal)"
label variable tot_pob_ipm_ofi         "Personas en pobreza IPM - total (%) (agregado)"
label variable tot_pob_ipm_hogares_mun "Hogares en pobreza IPM - total (%) (municipal)"
label variable tot_pob_ipm_hogares_ofi "Hogares en pobreza IPM - total (%) (agregado)"
format tot_pob_ipm_mun tot_pob_ipm_ofi tot_pob_ipm_hogares_mun tot_pob_ipm_hogares_ofi %6.1f
export excel ind_mpio nvl_label subregion provincia ///
    tot_pob_ipm_hogares_mun tot_pob_ipm_hogares_ofi tot_pob_ipm_mun tot_pob_ipm_ofi ///
    using "$out_05/economia.xlsx", sheet("ecv_ipm") firstrow(varlabels) sheetreplace

* --- 5.1.3 Gini (hogar y laboral) — AGREGADOS OFICIALES ECV ---
* El Gini NO es promediable entre municipios (un promedio ignora la desigualdad
* ENTRE municipios y subestima el Gini real). Por eso los agregados se toman de
* la ECV OFICIAL ($data/ECV_oficial_agregados.dta):
*   - Subregión: valor oficial de la subregión dominante (existe para las 9).
*   - Provincia: valor oficial (solo 6/11 provincias lo tienen; si no -> "no disponible").
*   - Departamento: la ECV no publica Gini departamental -> "no disponible".
* Los municipios muestran su Gini municipal (referencia), sin agregarse.
* REQUIERE: correr antes 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.

* Subregión dominante (crosswalk completo de 125)
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* Detalle municipal (Gini municipal, referencia)
use `ecv_prov', clear
keep ind_mpio nvl_label subregion provincia ///
     tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base
save `base'

* --- Provincia (oficial si está entre las 6 con dato) ---
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="PROVINCIA" & key=="${id_provincia}"
if _N==0 {
    set obs 1
    foreach v in tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab {
        capture confirm variable `v'
        if _rc gen `v' = .
        replace `v' = .
    }
    gen nvl_label = "PROVINCIA $provincia_label (Gini ECV oficial: no disponible)"
}
else {
    gen nvl_label = "PROVINCIA $provincia_label (Gini ECV oficial)"
}
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia (ECV oficial)"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia ///
     tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab tipo_fila orden_fila
tempfile g_prov
save `g_prov'

* --- Subregión dominante (oficial) ---
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
if _N==0 {
    set obs 1
    foreach v in tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab {
        capture confirm variable `v'
        if _rc gen `v' = .
        replace `v' = .
    }
}
gen nvl_label  = "SUBREGIÓN `dom_subreg' (Gini ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión (ECV oficial)"
gen orden_fila = 3
keep ind_mpio nvl_label subregion provincia ///
     tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab tipo_fila orden_fila
tempfile g_sub
save `g_sub'

* --- Departamento (la ECV no publica Gini departamental) ---
clear
set obs 1
foreach v in tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab {
    gen `v' = .
}
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (Gini ECV oficial: no disponible)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento (ECV oficial)"
gen orden_fila = 4
tempfile g_dep
save `g_dep'

* --- Unir: municipios (referencia) + agregados oficiales ---
use `base', clear
append using `g_prov'
append using `g_sub'
append using `g_dep'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_gini_hog urb_gini_hog rur_gini_hog tot_gini_lab urb_gini_lab rur_gini_lab {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio     "Código DANE"
label variable nvl_label    "Municipio"
label variable subregion    "Subregión"
label variable provincia    "Provincia"
label variable tot_gini_hog_mun "Gini ingresos del hogar - total (municipal)"
label variable tot_gini_hog_ofi "Gini ingresos del hogar - total (agregado)"
label variable urb_gini_hog_mun "Gini ingresos del hogar - urbano (municipal)"
label variable urb_gini_hog_ofi "Gini ingresos del hogar - urbano (agregado)"
label variable rur_gini_hog_mun "Gini ingresos del hogar - rural (municipal)"
label variable rur_gini_hog_ofi "Gini ingresos del hogar - rural (agregado)"
label variable tot_gini_lab_mun "Gini laboral - total (municipal)"
label variable tot_gini_lab_ofi "Gini laboral - total (agregado)"
label variable urb_gini_lab_mun "Gini laboral - urbano (municipal)"
label variable urb_gini_lab_ofi "Gini laboral - urbano (agregado)"
label variable rur_gini_lab_mun "Gini laboral - rural (municipal)"
label variable rur_gini_lab_ofi "Gini laboral - rural (agregado)"
format *_gini_*_mun *_gini_*_ofi %6.3f
export excel ind_mpio nvl_label subregion provincia ///
    tot_gini_hog_mun tot_gini_hog_ofi urb_gini_hog_mun urb_gini_hog_ofi rur_gini_hog_mun rur_gini_hog_ofi ///
    tot_gini_lab_mun tot_gini_lab_ofi urb_gini_lab_mun urb_gini_lab_ofi rur_gini_lab_mun rur_gini_lab_ofi ///
    using "$out_05/economia.xlsx", sheet("ecv_gini") firstrow(varlabels) sheetreplace

* --- 5.1.4 Ocupación e informalidad — OFICIAL ECV (subregión/departamento) ---
* Subregión y departamento: oficial ECV. No hay dato oficial de provincia para
* laboral, así que la provincia se calcula como promedio ponderado por población.
* REQUIERE: 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.

* Subregión dominante (crosswalk 125)
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

use `ecv_prov', clear
keep ind_mpio nvl_label subregion provincia pob_peso ///
     tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal
foreach v in tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal {
    replace `v' = `v' / 100
}
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base
save `base'

* Provincia: promedio ponderado por población (no hay oficial de provincia laboral)
foreach v in tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label  = "PROVINCIA $provincia_label (promedio ponderado; sin ECV oficial de provincia)"
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia ///
     tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal tipo_fila orden_fila
tempfile p_oi
save `p_oi'

* Subregión dominante (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
keep tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal
gen nvl_label  = "SUBREGIÓN `dom_subreg' (ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión"
gen orden_fila = 3
tempfile s_oi
save `s_oi'

* Departamento (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="DEPARTAMENTO" & key=="ANTIOQUIA"
keep tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento"
gen orden_fila = 4
tempfile d_oi
save `d_oi'

use `base', clear
append using `p_oi'
append using `s_oi'
append using `d_oi'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_to urb_to rur_to tot_emp_informal urb_emp_informal rur_emp_informal {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio          "Código DANE"
label variable nvl_label         "Municipio"
label variable subregion         "Subregión"
label variable provincia         "Provincia"
label variable tot_to_mun            "Tasa de ocupación - total (municipal)"
label variable tot_to_ofi            "Tasa de ocupación - total (agregado)"
label variable urb_to_mun            "Tasa de ocupación - urbano (municipal)"
label variable urb_to_ofi            "Tasa de ocupación - urbano (agregado)"
label variable rur_to_mun            "Tasa de ocupación - rural (municipal)"
label variable rur_to_ofi            "Tasa de ocupación - rural (agregado)"
label variable tot_emp_informal_mun  "Tasa de informalidad laboral - total (municipal)"
label variable tot_emp_informal_ofi  "Tasa de informalidad laboral - total (agregado)"
label variable urb_emp_informal_mun  "Tasa de informalidad laboral - urbano (municipal)"
label variable urb_emp_informal_ofi  "Tasa de informalidad laboral - urbano (agregado)"
label variable rur_emp_informal_mun  "Tasa de informalidad laboral - rural (municipal)"
label variable rur_emp_informal_ofi  "Tasa de informalidad laboral - rural (agregado)"
format *_to_mun *_to_ofi *_emp_informal_mun *_emp_informal_ofi %6.1f
export excel ind_mpio nvl_label subregion provincia ///
    tot_to_mun tot_to_ofi urb_to_mun urb_to_ofi rur_to_mun rur_to_ofi ///
    tot_emp_informal_mun tot_emp_informal_ofi urb_emp_informal_mun urb_emp_informal_ofi rur_emp_informal_mun rur_emp_informal_ofi ///
    using "$out_05/economia.xlsx", sheet("ecv_ocupacion_informal") firstrow(varlabels) sheetreplace

* --- 5.1.5 Desocupación y NiNi (totales) — OFICIAL ECV ---
* Subregión y departamento: oficial ECV para las tres. Provincia: desocupación
* (total y jóvenes) se calcula (no hay oficial de provincia); NiNi usa oficial si
* la provincia es de las 6 (NiNi sí tiene provincia oficial), si no, se calcula.
* REQUIERE: 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.

* Subregión dominante (crosswalk 125)
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

use `ecv_prov', clear
keep ind_mpio nvl_label subregion provincia pob_peso tot_td tot_td_15_28 tot_nini
foreach v in tot_td tot_td_15_28 tot_nini {
    replace `v' = `v' / 100
}
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base
save `base'

* NiNi oficial de la provincia (si existe entre las 6)
local nini_ofi = .
preserve
    use "$data/ECV_oficial_agregados.dta", clear
    keep if nivel=="PROVINCIA" & key=="${id_provincia}"
    if _N > 0 local nini_ofi = tot_nini[1]
restore

* Provincia: td y td_15_28 ponderados; NiNi oficial si hay, si no ponderado
use `base', clear
foreach v in tot_td tot_td_15_28 tot_nini {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tot_td tot_td_15_28 tot_nini {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
if !missing(`nini_ofi') {
    replace tot_nini = `nini_ofi'
    gen nvl_label = "PROVINCIA $provincia_label (desoc.: ponderado; NiNi: ECV oficial)"
}
else {
    gen nvl_label = "PROVINCIA $provincia_label (promedio ponderado; sin ECV oficial de provincia)"
}
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia tot_td tot_td_15_28 tot_nini tipo_fila orden_fila
tempfile p_dn
save `p_dn'

* Subregión dominante (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
keep tot_td tot_td_15_28 tot_nini
gen nvl_label  = "SUBREGIÓN `dom_subreg' (ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión"
gen orden_fila = 3
tempfile s_dn
save `s_dn'

* Departamento (oficial)
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="DEPARTAMENTO" & key=="ANTIOQUIA"
keep tot_td tot_td_15_28 tot_nini
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento"
gen orden_fila = 4
tempfile d_dn
save `d_dn'

use `base', clear
append using `p_dn'
append using `s_dn'
append using `d_dn'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_td tot_td_15_28 tot_nini {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio      "Código DANE"
label variable nvl_label     "Municipio"
label variable subregion     "Subregión"
label variable provincia     "Provincia"
label variable tot_td_mun        "Tasa de desocupación - total (municipal)"
label variable tot_td_ofi        "Tasa de desocupación - total (agregado)"
label variable tot_td_15_28_mun  "Tasa de desocupación jóvenes (15-28) (municipal)"
label variable tot_td_15_28_ofi  "Tasa de desocupación jóvenes (15-28) (agregado)"
label variable tot_nini_mun      "Jóvenes que no estudian ni trabajan (NiNi) (%) (municipal)"
label variable tot_nini_ofi      "Jóvenes que no estudian ni trabajan (NiNi) (%) (agregado)"
format tot_td_mun tot_td_ofi tot_td_15_28_mun tot_td_15_28_ofi tot_nini_mun tot_nini_ofi %6.1f
export excel ind_mpio nvl_label subregion provincia ///
    tot_td_mun tot_td_ofi tot_td_15_28_mun tot_td_15_28_ofi tot_nini_mun tot_nini_ofi ///
    using "$out_05/economia.xlsx", sheet("ecv_desocupacion_nini") firstrow(varlabels) sheetreplace


* ============================================================================
* SECCION 5.4 (Laura): TURISMO — Instrumentos de planificacion turistica
* ----------------------------------------------------------------------------
* Fuente: instrumentos_planificacion_turistica_antioquia.xlsx (hojas por instrumento)
* Tabla categorica por municipio: Inventario, Plan Local, Mesa Local y su
* formalizacion (constituida y reglamentada). Sin agregado provincial (categorica).
* ============================================================================


* Se lee por posición de columna (A=Cód. Municipio, C=indicador, D=formalización)
* para no depender de la sanitización de encabezados con acentos/puntos.
import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Inventario Turístico") cellrange(A2) clear
keep A C
rename A ind_mpio
rename C InventarioTuristico
destring ind_mpio, replace force
drop if missing(ind_mpio)
tempfile inv
save `inv'

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Plan Local de Turismo") cellrange(A2) clear
keep A C
rename A ind_mpio
rename C PlanLocaldeTurismo
destring ind_mpio, replace force
drop if missing(ind_mpio)
tempfile plan
save `plan'

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Mesa Local de Turismo") cellrange(A2) clear
keep A C D
rename A ind_mpio
rename C MesaLocaldeTurismo
rename D ConstituidaYReglamentada
destring ind_mpio, replace force
drop if missing(ind_mpio)
tempfile mesa
save `mesa'

use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
keep ind_mpio nvl_label subregion provincia
merge 1:1 ind_mpio using `inv',  keep(master match) nogen
merge 1:1 ind_mpio using `plan', keep(master match) nogen
merge 1:1 ind_mpio using `mesa', keep(master match) nogen
sort nvl_label

label variable ind_mpio                 "Código DANE"
label variable nvl_label                "Municipio"
label variable subregion                "Subregión"
label variable provincia                "Provincia"
label variable InventarioTuristico      "Inventario turístico"
label variable PlanLocaldeTurismo       "Plan Local de Turismo"
label variable MesaLocaldeTurismo       "Mesa Local de Turismo"
label variable ConstituidaYReglamentada "Mesa Local de Turismo formalizada (constituida y reglamentada)"

export excel ///
    ind_mpio nvl_label subregion provincia ///
    InventarioTuristico PlanLocaldeTurismo MesaLocaldeTurismo ConstituidaYReglamentada ///
    using "$out_05/economia.xlsx", sheet("turismo_instrumentos") firstrow(varlabels) sheetreplace


* ============================================================================
* SECCION 5.1 (Laura): INDICE DE DEPENDENCIA ECONOMICA (IDE)
* ----------------------------------------------------------------------------
* IDE = (poblacion <15 + poblacion 65+) / poblacion 15-64 * 100
* Fuente: POBLACION MUNICIPAL.xlsx (Rangos_Quintenios, 2025, area Total).
* Agregados provincia, subregión y departamento: recomputados desde sumas de grupos (exacto).
* ============================================================================

import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear sheet("Rangos_Quintenios")
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
rename DPMP ind_mpio
destring ind_mpio, replace
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión DANE completa (125 municipios) para el agregado de subregión
merge m:1 ind_mpio using "$rawdata/subreg_completo.dta", keep(master match) nogen

egen pob_men15 = rowtotal(TOTAL04 TOTAL59 TOTAL1014)
egen pob_1564  = rowtotal(TOTAL1519 TOTAL2024 TOTAL2529 TOTAL3034 TOTAL3539 ///
                          TOTAL4044 TOTAL4549 TOTAL5054 TOTAL5559 TOTAL6064)
egen pob_65mas = rowtotal(TOTAL6569 TOTAL7074 TOTAL7579 TOTAL8084 TOTAL85ymás)

keep ind_mpio nvl_label subregion subregion_full provincia id_provincia pob_men15 pob_1564 pob_65mas
tempfile ide_all
save `ide_all'

* --- Municipios de la provincia ---
use `ide_all', clear
keep if id_provincia == $id_provincia
gen ide = (pob_men15 + pob_65mas) / pob_1564 * 100
gen tipo_fila = "Municipio"
tempfile base
save `base'

* --- Provincia (agregado exacto desde sumas de grupos) ---
use `ide_all', clear
keep if id_provincia == $id_provincia
collapse (sum) pob_men15 pob_1564 pob_65mas, by(provincia)
gen ide = (pob_men15 + pob_65mas) / pob_1564 * 100
gen nvl_label = "PROVINCIA $provincia_label (agregado)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (agregado)"
tempfile agg_prov
save `agg_prov'

* --- Subregión mayoritaria (agregado exacto) ---
use `ide_all', clear
keep if id_provincia == $id_provincia
contract subregion_full
gsort -_freq subregion_full
local dom_subreg = subregion_full[1]

use `ide_all', clear
keep if subregion_full == "`dom_subreg'"
collapse (sum) pob_men15 pob_1564 pob_65mas
gen ide = (pob_men15 + pob_65mas) / pob_1564 * 100
gen nvl_label = "SUBREGIÓN `dom_subreg' (agregado)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile agg_sub
save `agg_sub'

* --- Departamento (agregado exacto, todos los municipios de Antioquia) ---
use `ide_all', clear
collapse (sum) pob_men15 pob_1564 pob_65mas
gen ide = (pob_men15 + pob_65mas) / pob_1564 * 100
gen nvl_label = "DEPARTAMENTO (ANTIOQUIA) (agregado)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile agg_dep
save `agg_dep'

* --- Unir todo ---
use `base', clear
append using `agg_prov'
append using `agg_sub'
append using `agg_dep'
gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (agregado)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable ide       "Índice de Dependencia Económica"
format ide %6.1f

export excel ind_mpio nvl_label subregion provincia ide ///
    using "$out_05/economia.xlsx", sheet("dependencia_economica") firstrow(varlabels) sheetreplace


* ============================================================================
* SECCION 5.2 (Laura): DENSIDAD EMPRESARIAL — Fuente: DATALAKE DEyC.xlsx
* ----------------------------------------------------------------------------
* Indicador "Densidad empresarial (número de empresas por cada mil habitantes)",
* nivel Municipal, año 2023. Agregado provincial ponderado por poblacion.
* (Valor Agregado 5.2 queda DIFERIDO: la fuente va a cambiar — ver pendientes.)
* ============================================================================

* Peso poblacional
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pesos_de
save `pesos_de'

* Lectura por posición (A=Unidad geográfica, B=código, F=indicador, G=año, H=dato)
* para no depender de encabezados con acentos/puntos.
import excel "$rawdata/DATALAKE DEyC.xlsx", sheet("Sheet1") cellrange(A2) clear
keep if A == "Municipal"
keep if F == "Densidad empresarial (número de empresas por cada mil habitantes)"
destring G, replace force
keep if G == 2023
rename B ind_mpio
rename H dens_emp
destring ind_mpio dens_emp, replace force
keep ind_mpio dens_emp

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge 1:1 ind_mpio using "`pesos_de'", keep(master match) nogen

gen tipo_fila = "Municipio"
tempfile base
save `base'
gen _x = dens_emp * pob_peso
gen _w = pob_peso if !missing(dens_emp)
collapse (sum) _x _w, by(provincia)
gen dens_emp = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"
append using `base'
gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
sort orden_fila nvl_label

label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable dens_emp  "Densidad empresarial (empresas por cada 1.000 hab.)"
format dens_emp %8.2f

export excel ind_mpio nvl_label subregion provincia dens_emp ///
    using "$out_05/economia.xlsx", sheet("densidad_empresarial") firstrow(varlabels) sheetreplace


* ============================================================================
* SECCION 5.2 (Laura): VALOR AGREGADO — Fuente: VALOR_AGREGADO_20152024_MUNICIPIOS.xlsx
* ----------------------------------------------------------------------------
* Serie 2015-2024 (las figuras usan 2024, pero se exportan todos los años).
* Precios constantes 2015, miles de millones de pesos.
* Columnas (por posicion, cellrange desde fila 4): A=Año, E=cod municipio,
*   J=Primarias, M=Secundarias, V=Terciarias, W=VA Total; ramas: H=Agricultura,
*   I=Minas, K=Manufactura, L=Construccion, N=Electricidad, O=Comercio,
*   P=Informacion, Q=Financieras, R=Inmobiliarias, S=Profesionales,
*   T=Administracion, U=Artisticas.
* Per capita con poblacion del AÑO respectivo. Peso relativo = VA total
*   municipal / VA total provincial. prop_va_dpto = / VA total departamental.
* NOTA: los 3 sectores no suman VA Total en municipios mineros (gap, ver
*   pendientes); las distribuciones % se calculan sobre VA Total.
* ============================================================================


* --- Poblacion por año (2015-2024), area Total ---
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if ÁREAGEOGRÁFICA == "Total"
keep if AÑO >= 2015 & AÑO <= 2024
keep DPMP AÑO TotalGeneral
rename DPMP ind_mpio
rename AÑO  Año
rename TotalGeneral pob
destring ind_mpio Año pob, replace force
tempfile pobyear
save `pobyear'

* --- Importar Valor Agregado ---
import excel "$data/VALOR_AGREGADO_20152024_MUNICIPIOS.xlsx", ///
    sheet("PIB Mpal 2015-2024 Cons") cellrange(A4) clear
keep A E J M V W H I K L N O P Q R S T U
rename A Año
rename E ind_mpio
rename J va_primario
rename M va_secundario
rename V va_terciario
rename W va_total
rename H va_agricultura
rename I va_minas
rename K va_manufactura
rename L va_construccion
rename N va_electricidad
rename O va_comercio
rename P va_informacion
rename Q va_financieras
rename R va_inmobiliarias
rename S va_profesionales
rename T va_administracion
rename U va_artisticas
destring Año ind_mpio va_*, replace force
drop if missing(ind_mpio) | missing(Año)
keep if Año >= 2015 & Año <= 2024

* Total departamental por año (sobre TODOS los municipios del archivo VA, no solo la PAP)
bysort Año: egen dpto_va_total = total(va_total)

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(match) nogen
keep if id_provincia == $id_provincia

* Total provincial por año
bysort Año: egen prov_va_total = total(va_total)

* Poblacion del año respectivo
merge 1:1 ind_mpio Año using "`pobyear'", keep(master match) nogen

* Metricas municipales
gen prop_va_prov      = va_total / prov_va_total
gen prop_va_dpto      = va_total / dpto_va_total
gen va_pc             = va_total * 1e9 / pob
gen prop_va_primario  = va_primario  / va_total
gen prop_va_secundario= va_secundario/ va_total
gen prop_va_terciario = va_terciario / va_total

gen tipo_fila = "Municipio"
tempfile base_va
save `base_va'

* --- Fila provincial por año (suma; proporciones y per capita recomputadas) ---
collapse (sum) va_total va_primario va_secundario va_terciario ///
    va_agricultura va_minas va_manufactura va_construccion va_electricidad ///
    va_comercio va_informacion va_financieras va_inmobiliarias va_profesionales ///
    va_administracion va_artisticas pob ///
    (mean) dpto_va_total, by(Año provincia)
gen prop_va_prov       = 100
gen prop_va_dpto       = va_total / dpto_va_total
gen va_pc              = va_total * 1e9 / pob
gen prop_va_primario   = va_primario  / va_total
gen prop_va_secundario = va_secundario/ va_total
gen prop_va_terciario  = va_terciario / va_total
gen nvl_label = "TOTAL PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total provincia"
append using `base_va'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
sort Año orden_fila nvl_label

* --- Etiquetas ---
label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable Año                "Año"
label variable va_total           "Valor agregado total (miles de millones $)"
label variable va_primario        "VA actividades primarias (miles de millones $)"
label variable va_secundario      "VA actividades secundarias (miles de millones $)"
label variable va_terciario       "VA actividades terciarias (miles de millones $)"
label variable prop_va_primario   "Participación % del VA - primarias"
label variable prop_va_secundario "Participación % del VA - secundarias"
label variable prop_va_terciario  "Participación % del VA - terciarias"
label variable prop_va_prov       "Proporción del VA municipal sobre total provincial (%)"
label variable prop_va_dpto       "Proporción del VA municipal sobre total departamental (%)"
label variable va_pc              "Valor agregado per cápita (pesos, constantes 2015)"
format va_total va_primario va_secundario va_terciario %12.1f
format prop_va_* %6.1f
format va_pc %14.0f

export excel ///
    ind_mpio nvl_label subregion provincia Año ///
    va_total va_primario va_secundario va_terciario ///
    prop_va_primario prop_va_secundario prop_va_terciario ///
    prop_va_prov prop_va_dpto va_pc ///
    using "$out_05/economia.xlsx", sheet("valor_agregado") firstrow(varlabels) sheetreplace

* --- Hoja de actividades economicas (ramas detalladas) ---
label variable va_agricultura    "VA Agricultura, ganadería, caza, silvicultura y pesca"
label variable va_minas          "VA Explotación de minas y canteras"
label variable va_manufactura    "VA Industrias manufactureras"
label variable va_construccion   "VA Construcción"
label variable va_electricidad   "VA Suministro de electricidad, gas y agua"
label variable va_comercio       "VA Comercio, transporte y alojamiento"
label variable va_informacion    "VA Información y comunicaciones"
label variable va_financieras    "VA Actividades financieras y de seguros"
label variable va_inmobiliarias  "VA Actividades inmobiliarias"
label variable va_profesionales  "VA Actividades profesionales, científicas y técnicas"
label variable va_administracion "VA Administración pública, educación y salud"
label variable va_artisticas     "VA Actividades artísticas y de entretenimiento"

export excel ///
    ind_mpio nvl_label subregion provincia Año ///
    va_agricultura va_minas va_manufactura va_construccion va_electricidad ///
    va_comercio va_informacion va_financieras va_inmobiliarias va_profesionales ///
    va_administracion va_artisticas ///
    using "$out_05/economia.xlsx", sheet("va_actividades") firstrow(varlabels) sheetreplace




/********************************************************************
* 5.3 Minero-energético (XM) — capacidad instalada de generación
*   Fuente: $rawdata/Energia_NorteAntioquia.xlsx (XM S.A. E.S.P., PARATEC /
*     Intégrame; corte 2024-2025). El insumo NO trae código DANE: el cruce
*     con la provincia se hace por NOMBRE de municipio normalizado (sin tildes)
*     contra códigos_provincias (fuente de verdad del flujo).
*   Hojas:
*     - energia_tecnologia   : capacidad del SIN por tecnología (NACIONAL).
*     - energia_centrales    : centrales de la provincia + participación.
*     - energia_participacion: participación de la provincia en SIN/Antioquia.
*   NOTA: la participación usa la definición de provincia de códigos_provincias,
*     que puede diferir de listas precalculadas del insumo (p. ej. prov. 2
*     incluye San Andrés de Cuerquia: 2428.3 MW vs 2393.4 del archivo). Ver
*     pendientes. Nivel NACIONAL/no-municipio (no sigue el patrón ind_mpio).
*   VALIDAR en una provincia CON plantas (p. ej. prov. 2); la prov. 4 no tiene.
********************************************************************/

* --- Fig 1: capacidad del SIN por tecnología (nacional) ---
import excel "$rawdata/Energia_NorteAntioquia.xlsx", sheet("SIN por Tecnología") cellrange(A3) clear
keep A B C
rename A tecnologia
rename B cap_mw
rename C participacion
drop if missing(tecnologia)
drop if strpos(tecnologia, "Fuente") > 0
destring cap_mw participacion, replace force

* Denominador nacional (Total SIN)
quietly summarize cap_mw if tecnologia == "Total SIN"
scalar sin_total = r(sum)

label variable tecnologia    "Tecnología"
label variable cap_mw        "Capacidad instalada (MW)"
label variable participacion "Participación en el SIN"
format cap_mw %12.2f
format participacion %6.4f
export excel tecnologia cap_mw participacion ///
    using "$out_05/economia.xlsx", sheet("energia_tecnologia") firstrow(varlabels) sheetreplace

* --- Crosswalk NOMBRE de municipio -> provincia (para el cruce sin DANE) ---
use "$rawdata/códigos_provincias.dta", clear
keep ind_mpio id_provincia provincia subregion nvl_label
rename nvl_label mun_norm
tempfile codname
save `codname'

* --- Plantas de Antioquia (hoja 2) ---
import excel "$rawdata/Energia_NorteAntioquia.xlsx", sheet("Antioquia – Todas las plantas") cellrange(A3) clear
keep A B C D F G
rename A municipio
rename B central
rename C tecnologia
rename D estado
rename F empresa
rename G cap_mw
drop if missing(municipio)
drop if strpos(municipio,"Total")>0 | strpos(municipio,"Resumen")>0 | ///
        strpos(municipio,"Fuente")>0 | strpos(municipio,"Nota")>0
destring cap_mw, replace force
drop if missing(cap_mw)

* Denominador departamental (suma de todas las plantas de Antioquia)
quietly summarize cap_mw
scalar ant_total = r(sum)

* Normalizar nombre (quitar tildes) para cruzar con nvl_label de códigos
gen mun_norm = upper(strtrim(municipio))
replace mun_norm = subinstr(mun_norm,"Á","A",.)
replace mun_norm = subinstr(mun_norm,"É","E",.)
replace mun_norm = subinstr(mun_norm,"Í","I",.)
replace mun_norm = subinstr(mun_norm,"Ó","O",.)
replace mun_norm = subinstr(mun_norm,"Ú","U",.)
replace mun_norm = subinstr(mun_norm,"Ñ","N",.)
replace mun_norm = subinstr(mun_norm,"Ü","U",.)

merge m:1 mun_norm using "`codname'", keep(master match) nogen
keep if id_provincia == $id_provincia

gen part_sin = cap_mw / sin_total
gen part_ant = cap_mw / ant_total
gen tipo_fila = "Central"
tempfile centrales
save `centrales'

* Total de la provincia: SIEMPRE 1 fila (si no hay plantas, total = 0 MW).
* Se construye sin collapse para no fallar cuando la provincia no tiene
* centrales (export excel exige >= 1 observación).
use `centrales', clear
quietly summarize cap_mw
scalar prov_total = cond(r(N) > 0, r(sum), 0)

clear
set obs 1
gen provincia  = "$provincia_nombre"
gen municipio  = "TOTAL PROVINCIA $provincia_label"
gen double cap_mw   = prov_total
gen double part_sin = prov_total / sin_total
gen double part_ant = prov_total / ant_total
gen central    = ""
gen tecnologia = ""
gen estado     = ""
gen empresa    = ""
gen ind_mpio   = .
gen subregion  = ""
gen tipo_fila  = "Total provincia"
append using `centrales'

gen orden_fila = 1 if tipo_fila=="Central"
replace orden_fila = 2 if tipo_fila=="Total provincia"
gsort orden_fila -cap_mw

label variable ind_mpio   "Código DANE"
label variable municipio  "Municipio"
label variable subregion  "Subregión"
label variable provincia  "Provincia"
label variable central    "Central / Planta"
label variable tecnologia "Tecnología"
label variable estado     "Estado"
label variable empresa    "Empresa operadora"
label variable cap_mw     "Capacidad efectiva neta (MW)"
label variable part_sin   "Participación en el SIN"
label variable part_ant   "Participación en Antioquia"
format cap_mw %12.2f
format part_sin part_ant %8.5f
export excel ///
    ind_mpio municipio subregion provincia central tecnologia estado empresa ///
    cap_mw part_sin part_ant ///
    using "$out_05/economia.xlsx", sheet("energia_centrales") firstrow(varlabels) sheetreplace

* --- Fig 3: participación de la provincia (resumen SIN / Antioquia) ---
use `centrales', clear
quietly summarize cap_mw
scalar prov_total = cond(r(N) > 0, r(sum), 0)

clear
set obs 3
gen str60 ambito = ""
gen double cap_mw = .
gen double part_sin = .
replace ambito = "PROVINCIA $provincia_label"                 in 1
replace cap_mw = prov_total                                   in 1
replace part_sin = prov_total/sin_total                       in 1
replace ambito = "Departamento de Antioquia"                  in 2
replace cap_mw = ant_total                                    in 2
replace part_sin = ant_total/sin_total                        in 2
replace ambito = "Sistema Interconectado Nacional (SIN)"      in 3
replace cap_mw = sin_total                                    in 3
replace part_sin = 1                                          in 3
gen double part_ant = cap_mw/ant_total
replace part_ant = . in 3          // el SIN no tiene "% de Antioquia"

label variable ambito   "Ámbito"
label variable cap_mw   "Capacidad instalada (MW)"
label variable part_sin "Participación en el SIN"
label variable part_ant "Participación en Antioquia"
format cap_mw %12.2f
format part_sin part_ant %8.5f
export excel ambito cap_mw part_sin part_ant ///
    using "$out_05/economia.xlsx", sheet("energia_participacion") firstrow(varlabels) sheetreplace




/********************************************************************
* 5.3 Minero-energético — Títulos mineros por tipo de mineral
*   Figura (Pablo): "Títulos mineros por tipo de mineral en la PAP".
*   Fuente: $rawdata/Actualización/Fuentes/TITULOSMINAS_ORIGINAL.xlsx (ANM,
*     catastro minero), hoja "Título Vigente (1)". NO trae CODIGO_DANE: cruce
*     por NOMBRE de municipio normalizado (sin tildes). Se filtran los ACTIVOS
*     (vigentes). Los minerales vienen en una LISTA separada por comas dentro de
*     una celda: se quitan los paréntesis (comas internas) y se separan en filas.
*   Método: conteo de TÍTULOS distintos por mineral en la provincia; un título
*     con varios minerales cuenta en cada uno; uno en varios municipios cuenta
*     una sola vez. Se exportan TODOS los minerales (sin agrupar en "Otros");
*     el usuario decide caso por caso qué agrupar.
********************************************************************/

* Crosswalk nombre de municipio -> provincia (nvl_label ya viene sin tildes)
use "$rawdata/códigos_provincias.dta", clear
keep ind_mpio id_provincia provincia nvl_label
rename nvl_label mun_norm
tempfile codname_lic
save `codname_lic'

import excel "$rawdata/Actualización/Fuentes/TITULOSMINAS_ORIGINAL.xlsx", ///
    sheet("Título Vigente (1)") firstrow clear
keep CODIGO_EXPEDIENTE Estado Minerales Municipios
keep if Estado == "Activo"

* nombre de municipio normalizado (quitar tildes) para el cruce
gen mun_norm = upper(strtrim(Municipios))
replace mun_norm = subinstr(mun_norm,"Á","A",.)
replace mun_norm = subinstr(mun_norm,"É","E",.)
replace mun_norm = subinstr(mun_norm,"Í","I",.)
replace mun_norm = subinstr(mun_norm,"Ó","O",.)
replace mun_norm = subinstr(mun_norm,"Ú","U",.)
replace mun_norm = subinstr(mun_norm,"Ñ","N",.)
replace mun_norm = subinstr(mun_norm,"Ü","U",.)

merge m:1 mun_norm using "`codname_lic'", keep(master match) nogen
keep if id_provincia == $id_provincia

count
if r(N) == 0 {
    * Provincia sin títulos: fila indicativa (no abortar)
    clear
    set obs 1
    gen str40 grupo_mineral = "SIN TÍTULOS EN LA PROVINCIA"
    gen n_titulos = 0
}
else {
    * limpiar minerales: quitar paréntesis (tienen comas internas) y separar por coma
    replace Minerales = ustrregexra(Minerales, "\([^)]*\)", "")
    gen _id = _n
    split Minerales, parse(",") generate(min_)
    reshape long min_, i(_id) j(_k)
    replace min_ = strtrim(stritrim(upper(min_)))   // stritrim colapsa los espacios dobles que dejan los paréntesis
    drop if min_ == ""
    * un registro por (título, mineral) dentro de la provincia
    keep CODIGO_EXPEDIENTE min_
    rename min_ mineral
    duplicates drop CODIGO_EXPEDIENTE mineral, force
    contract mineral, freq(n_titulos)
    rename mineral grupo_mineral
    gsort -n_titulos
}

gen provincia = "$provincia_nombre"
label variable grupo_mineral "Tipo de mineral"
label variable n_titulos     "Número de títulos mineros"
label variable provincia     "Provincia"
format n_titulos %6.0f
export excel grupo_mineral n_titulos provincia ///
    using "$out_05/economia.xlsx", sheet("titulos_mineros") firstrow(varlabels) sheetreplace


di as text "  05_Economia: tablas exportadas en $out_05/"
