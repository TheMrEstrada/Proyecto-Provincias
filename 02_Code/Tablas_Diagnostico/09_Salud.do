* ----------------------------------------------------------------------------
* PROVINCIAS - 09_Salud.do
* SECCION 9: SALUD
* FIGURAS (nivel B integrado):
*   - % de nacidos con bajo peso al nacer
*   - Tasa por 100 mil hab. de dengue, malaria y leishmaniasis
*   - Tasa de intento de suicidio y de suicidio consumado por 100 mil hab.
* INPUTS:
*   $data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA  (bajo_peso, dengue, malaria, leishmaniasis)
*   $data/suicidios_e_intentos_medias_dicc      (TIS_total, TS_total)
*   $rawdata/POBLACION MUNICIPAL.xlsx           (peso poblacional)
*   $rawdata/NATALIDAD.xlsx                     (nacidos vivos por municipio y año)
*   $rawdata/MORTALIDAD_INFANTIL.xlsx           (tasa por municipio y año)
*   $rawdata/codigos_provincias.dta
* OUTPUTS: $out_09/salud.xlsx (hojas: bajo_peso, enfermedades_tropicales, suicidios,
*          aseguramiento_sgsss, mortalidad_infantil)
* REQUIERE: 00_master.do (define globals)
* AGREGADO PROVINCIAL:
*   - tasas por 100 mil (dengue/malaria/leishmaniasis, suicidios): ponderado por
*     poblacion = Sum(tasa*pob)/Sum(pob) = Sum(casos)/Sum(pob)*100mil  (correcto).
*   - bajo_peso (% de NACIMIENTOS) y mortalidad infantil (por 1.000 nacidos):
*     ponderados por NACIMIENTOS = Sum(tasa*nac)/Sum(nac) = Sum(casos)/Sum(nac)
*     (correcto; corregido 2026-08-06, antes se ponderaba por poblacion).
* ----------------------------------------------------------------------------

capture erase "$out_09/salud.xlsx"

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

* --- Nacimientos (nacidos vivos) por municipio y año, 2020-2024 ---
*   Peso correcto para indicadores medidos POR NACIMIENTO (bajo peso, mort. infantil).
*   NATALIDAD.xlsx, hoja "Natalidad total": encabezados en 2 filas (año / Total-Tasa),
*   se lee por posicion desde la fila 4. Col A = codigo; columnas "Total" por año:
*   AE=2020, AG=2021, AI=2022, AK=2023, AM=2024. Se descartan las filas de
*   subregion (codigo tipo "SR0x" -> missing) y de departamento (codigo 05 -> 5 < 1000).
import excel "$rawdata/NATALIDAD.xlsx", sheet("Natalidad total") cellrange(A4) clear
keep A AE AG AI AK AM
rename A  ind_mpio
rename AE nac2020
rename AG nac2021
rename AI nac2022
rename AK nac2023
rename AM nac2024
destring ind_mpio nac2020 nac2021 nac2022 nac2023 nac2024, replace force
drop if missing(ind_mpio) | ind_mpio < 1000
tempfile nac_wide
save `nac_wide'


/********************************************************************
* 9.1 Bajo peso al nacer (%)
********************************************************************/

* Base municipal (TODOS los municipios) con peso = nacimientos y subregión/provincia.
* Peso = NACIMIENTOS 2024 (bajo peso es % de nacimientos, no de población).
use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear
keep ind_mpio bajo_peso
replace bajo_peso = bajo_peso / 100
merge 1:1 ind_mpio using "`nac_wide'", keepusing(nac2024) keep(master match) nogen
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión de TODOS los municipios (crosswalk 125) para el agregado de subregión
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen
tempfile bp_all
save `bp_all'

* Subregión mayoritaria de la provincia (municipios PAP de la provincia)
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Total departamento (ponderado por nacimientos, TODOS los municipios) ---
use `bp_all', clear
gen _x = bajo_peso * nac2024
gen _w = nac2024 if !missing(bajo_peso)
collapse (sum) _x _w
gen bajo_peso = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por nacimientos)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile bp_dep
save `bp_dep'

* --- Total subregión mayoritaria (municipios PAP de la subregión dominante) ---
use `bp_all', clear
keep if subregion == "`dom_subreg'"
gen _x = bajo_peso * nac2024
gen _w = nac2024 if !missing(bajo_peso)
collapse (sum) _x _w
gen bajo_peso = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO SUBREGIÓN `dom_subreg' (por nacimientos)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile bp_sub
save `bp_sub'

* --- Provincia (ponderado) + municipios de la provincia ---
use `bp_all', clear
keep if id_provincia == $id_provincia
gen tipo_fila = "Municipio"
tempfile base
save `base'

gen _x = bajo_peso * nac2024
gen _w = nac2024 if !missing(bajo_peso)
collapse (sum) _x _w, by(provincia)
gen bajo_peso = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por nacimientos)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"

append using `base'
append using `bp_sub'
append using `bp_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable bajo_peso "Nacidos con bajo peso al nacer (%)"
format bajo_peso %6.1f

export excel ind_mpio nvl_label subregion provincia bajo_peso ///
    using "$out_09/salud.xlsx", sheet("bajo_peso") firstrow(varlabels) sheetreplace


/********************************************************************
* 9.2 Enfermedades tropicales: tasa por 100 mil hab.
********************************************************************/

use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear
keep ind_mpio dengue malaria leishmaniasis
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge 1:1 ind_mpio using "`pesos'", keep(master match) nogen

gen tipo_fila = "Municipio"
tempfile base
save `base'

foreach v in dengue malaria leishmaniasis {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in dengue malaria leishmaniasis {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"
append using `base'
gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
sort orden_fila nvl_label

label variable ind_mpio      "Código DANE"
label variable nvl_label     "Municipio"
label variable subregion     "Subregión"
label variable provincia     "Provincia"
label variable dengue        "Tasa de dengue por 100 mil hab."
label variable malaria       "Tasa de malaria por 100 mil hab."
label variable leishmaniasis "Tasa de leishmaniasis por 100 mil hab."
format dengue malaria leishmaniasis %8.2f

export excel ind_mpio nvl_label subregion provincia dengue malaria leishmaniasis ///
    using "$out_09/salud.xlsx", sheet("enfermedades_tropicales") firstrow(varlabels) sheetreplace


/********************************************************************
* 9.3 Intento de suicidio y suicidio consumado (tasa por 100 mil hab.)
********************************************************************/

* Base municipal (TODOS los municipios) con peso poblacional y subregión/provincia
use "$data/suicidios_e_intentos_medias_dicc", clear
keep ind_mpio TIS_total TS_total
rename TIS_total tis_total
rename TS_total  ts_total
destring ind_mpio tis_total ts_total, replace force   // el derivado trae todo como texto
merge 1:1 ind_mpio using "`pesos'", keep(master match) nogen
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión de TODOS los municipios (crosswalk 125) para el agregado de subregión
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen
tempfile su_all
save `su_all'

* Subregión mayoritaria de la provincia
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Total departamento (ponderado por población, TODOS los municipios) ---
use `su_all', clear
foreach v in tis_total ts_total {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tis_total ts_total {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por población)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile su_dep
save `su_dep'

* --- Total subregión mayoritaria (municipios PAP de la subregión dominante) ---
use `su_all', clear
keep if subregion == "`dom_subreg'"
foreach v in tis_total ts_total {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*
foreach v in tis_total ts_total {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO SUBREGIÓN `dom_subreg' (por población)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile su_sub
save `su_sub'

* --- Provincia (ponderado) + municipios de la provincia ---
use `su_all', clear
keep if id_provincia == $id_provincia
gen tipo_fila = "Municipio"
tempfile base
save `base'

foreach v in tis_total ts_total {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in tis_total ts_total {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"

append using `base'
append using `su_sub'
append using `su_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

label variable ind_mpio   "Código DANE"
label variable nvl_label  "Municipio"
label variable subregion  "Subregión"
label variable provincia  "Provincia"
label variable tis_total  "Tasa de intento de suicidio por 100 mil hab."
label variable ts_total   "Tasa de suicidio consumado por 100 mil hab."
format tis_total ts_total %8.2f

export excel ind_mpio nvl_label subregion provincia tis_total ts_total ///
    using "$out_09/salud.xlsx", sheet("suicidios") firstrow(varlabels) sheetreplace


/********************************************************************
* 9.4 Composicion de afiliados al SGSSS por regimen
*   Fuente: ASEGURAMIENTO_MUNICIPIOS.xlsx (hoja "1. Población_Afiliada_Regimen").
*   CORTE: DICIEMBRE 2025 (no es total anual).
*   Codigo municipal = 3 digitos -> ind_mpio = 5000 + cod.
*   Regimen especial y de excepcion = Excepcion + Fuerza Publica + INPEC.
*   Columnas (por posicion): A=cod, D=subsidiado, F=contributivo,
*     H=excepcion, J=fuerza publica, L=INPEC (cada regimen: Total, %).
*   Proporciones = composicion (regimen / total afiliados). Agregado provincial
*   = suma de afiliados y proporciones recomputadas (exacto).
********************************************************************/

import excel "$rawdata/ASEGURAMIENTO_MUNICIPIOS.xlsx", ///
    sheet("1. Población_Afiliada_Regimen") cellrange(A6) clear
rename A cod
rename D afil_subsidiado
rename F afil_contributivo
rename H afil_exc
rename J afil_fp
rename L afil_inpec
keep cod afil_subsidiado afil_contributivo afil_exc afil_fp afil_inpec
destring cod afil_subsidiado afil_contributivo afil_exc afil_fp afil_inpec, replace force
drop if missing(cod)
gen ind_mpio = 5000 + cod
gen afil_especial = afil_exc + afil_fp + afil_inpec
keep ind_mpio afil_subsidiado afil_contributivo afil_especial

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

keep ind_mpio nvl_label subregion provincia afil_contributivo afil_subsidiado afil_especial
gen tipo_fila = "Municipio"
tempfile base
save `base'

collapse (sum) afil_contributivo afil_subsidiado afil_especial, by(provincia)
gen nvl_label = "TOTAL PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total provincia"
append using `base'

* Proporciones de composicion (para municipios y total)
gen total_sgsss = afil_contributivo + afil_subsidiado + afil_especial
gen prop_contributivo = afil_contributivo / total_sgsss
gen prop_subsidiado   = afil_subsidiado   / total_sgsss
gen prop_especial     = afil_especial     / total_sgsss
drop total_sgsss

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
sort orden_fila nvl_label

label variable ind_mpio          "Código DANE"
label variable nvl_label         "Municipio"
label variable subregion         "Subregión"
label variable provincia         "Provincia"
label variable afil_contributivo "Afiliados al régimen contributivo"
label variable afil_subsidiado   "Afiliados al régimen subsidiado"
label variable afil_especial     "Afiliados al régimen especial y de excepción"
label variable prop_contributivo "% afiliados régimen contributivo"
label variable prop_subsidiado   "% afiliados régimen subsidiado"
label variable prop_especial     "% afiliados régimen especial y de excepción"
format afil_* %12.0f
format prop_* %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    afil_contributivo afil_subsidiado afil_especial ///
    prop_contributivo prop_subsidiado prop_especial ///
    using "$out_09/salud.xlsx", sheet("aseguramiento_sgsss") firstrow(varlabels) sheetreplace


/********************************************************************
* 9.5 Mortalidad infantil por municipio, serie 2020-2024
*   Fuente: MORTALIDAD_INFANTIL.xlsx (hoja "INFANTIL"), matriz ancha:
*     col B = código (05xxx); por año: casos y "Tasa x mil Nacidos vivos".
*     Tasa 2020..2024 en columnas Excel AI, AK, AM, AO, AQ.
*   Se exporta en formato largo (municipio x Año) CON fila de agregado
*   provincial por año, ponderado por nacidos vivos (NATALIDAD.xlsx):
*     tasa_prov = Σ(tasa_i*nac_i)/Σnac_i = Σcasos/Σnacidos * 1.000.
*   La tasa=0 se maneja bien (casos_i=0 aporta 0 al numerador y nac_i al denom.).
********************************************************************/

* La columna A del archivo está vacía; el área de datos empieza en la columna B.
import excel "$rawdata/MORTALIDAD_INFANTIL.xlsx", sheet("INFANTIL") cellrange(B6) clear
keep B AI AK AM AO AQ
rename B  codigo
rename AI tasa_mort_infantil2020
rename AK tasa_mort_infantil2021
rename AM tasa_mort_infantil2022
rename AO tasa_mort_infantil2023
rename AQ tasa_mort_infantil2024
destring codigo tasa_mort_infantil2020 tasa_mort_infantil2021 ///
    tasa_mort_infantil2022 tasa_mort_infantil2023 tasa_mort_infantil2024, replace force
drop if missing(codigo)
rename codigo ind_mpio

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión de TODOS los municipios (crosswalk 125) para el agregado de subregión
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen

keep ind_mpio nvl_label subregion provincia id_provincia ///
    tasa_mort_infantil2020 tasa_mort_infantil2021 tasa_mort_infantil2022 ///
    tasa_mort_infantil2023 tasa_mort_infantil2024
reshape long tasa_mort_infantil, i(ind_mpio nvl_label subregion provincia id_provincia) j(Año)

* --- Nacidos vivos por municipio y año (nac_wide ancho -> largo) ---
preserve
    use "`nac_wide'", clear
    reshape long nac, i(ind_mpio) j(Año)
    tempfile nac_long
    save `nac_long'
restore

merge 1:1 ind_mpio Año using "`nac_long'", keep(master match) nogen
tempfile mi_all
save `mi_all'

* Subregión mayoritaria de la provincia
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Departamento por año (ponderado por nacidos vivos, TODOS los municipios) ---
use `mi_all', clear
gen _x = tasa_mort_infantil * nac
gen _w = nac if !missing(tasa_mort_infantil)
collapse (sum) _x _w, by(Año)
gen tasa_mort_infantil = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por nacidos vivos)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile mi_dep
save `mi_dep'

* --- Subregión dominante por año (municipios PAP de la subregión) ---
use `mi_all', clear
keep if subregion == "`dom_subreg'"
gen _x = tasa_mort_infantil * nac
gen _w = nac if !missing(tasa_mort_infantil)
collapse (sum) _x _w, by(Año)
gen tasa_mort_infantil = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO SUBREGIÓN `dom_subreg' (por nacidos vivos)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile mi_sub
save `mi_sub'

* --- Provincia por año + municipios de la provincia ---
use `mi_all', clear
keep if id_provincia == $id_provincia
gen tipo_fila = "Municipio"
tempfile base_mi
save `base_mi'

gen _x = tasa_mort_infantil * nac
gen _w = nac if !missing(tasa_mort_infantil)
collapse (sum) _x _w, by(provincia Año)
gen tasa_mort_infantil = _x / _w
drop _x _w
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por nacidos vivos)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"

append using `base_mi'
append using `mi_sub'
append using `mi_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort Año orden_fila nvl_label

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable Año                "Año"
label variable tasa_mort_infantil "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"
format tasa_mort_infantil %8.2f

export excel ///
    ind_mpio nvl_label subregion provincia Año tasa_mort_infantil ///
    using "$out_09/salud.xlsx", sheet("mortalidad_infantil") firstrow(varlabels) sheetreplace


di as text "  09_Salud: 5 hojas exportadas en $out_09/salud.xlsx"
