* ----------------------------------------------------------------------------
* PROVINCIAS - 08_Educacion.do
* SECCION 8: EDUCACION
* FIGURAS: Cobertura neta, Deserción, Repitencia
* INPUTS: $data/EDUCACION_PROVINCIAS.xlsx
* OUTPUTS: $out_08 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


/********************************************************************
* 8.1 Indicadores educativos: Cobertura neta, Deserción, Repitencia
*     Una sola hoja. Promedios PONDERADOS por POBLACION_5_16_EDU (población
*     en edad escolar) para provincia, subregión dominante y departamento.
*     Subregión dominante = la más frecuente entre los municipios de la
*     provincia seleccionada.
********************************************************************/

import excel "$data/EDUCACION_PROVINCIAS.xlsx", sheet("Data") firstrow clear

rename AÑO Año
rename POBLACIÓN_5_16 POBLACION_5_16_EDU
destring CÓDIGO_MUNICIPIO POBLACION_5_16_EDU COBERTURA_NETA DESERCIÓN REPITENCIA, replace force
foreach v in COBERTURA_NETA DESERCIÓN REPITENCIA {
    replace `v' = `v' / 100
}

* Subregión desde el crosswalk oficial de 125 municipios (fuente única del flujo,
* consistente con el resto de secciones). Reemplaza el `subreg` del derivado.
drop subreg
gen ind_mpio = CÓDIGO_MUNICIPIO
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen
rename subregion subreg
drop ind_mpio

* --- Subregión dominante de la provincia (la más frecuente) ---
preserve
    keep if prov == "$provincia_nombre"
    bysort CÓDIGO_MUNICIPIO: keep if _n == 1
    contract subreg
    gsort -_freq subreg
    local dom_subreg = subreg[1]
restore

* --- Promedio ponderado provincia (por año) ---
preserve
    keep if prov == "$provincia_nombre"
    collapse (mean) COBERTURA_NETA DESERCIÓN REPITENCIA [aweight=POBLACION_5_16_EDU], by(Año)
    gen MUNICIPIO        = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población escolar)"
    gen subreg           = ""
    gen prov             = "$provincia_nombre"
    gen CÓDIGO_MUNICIPIO = .
    gen tipo_fila        = "Promedio provincia"
    tempfile tprov
    save `tprov'
restore

* --- Promedio ponderado subregión dominante (por año) ---
preserve
    keep if subreg == "`dom_subreg'"
    collapse (mean) COBERTURA_NETA DESERCIÓN REPITENCIA [aweight=POBLACION_5_16_EDU], by(Año)
    gen MUNICIPIO        = "PROMEDIO PONDERADO SUBREGIÓN `dom_subreg' (por población escolar)"
    gen subreg           = "`dom_subreg'"
    gen prov             = ""
    gen CÓDIGO_MUNICIPIO = .
    gen tipo_fila        = "Promedio subregión"
    tempfile tsub
    save `tsub'
restore

* --- Promedio ponderado departamento (por año) ---
preserve
    collapse (mean) COBERTURA_NETA DESERCIÓN REPITENCIA [aweight=POBLACION_5_16_EDU], by(Año)
    gen MUNICIPIO        = "PROMEDIO PONDERADO DEPARTAMENTO (ANTIOQUIA) (por población escolar)"
    gen subreg           = ""
    gen prov             = "DEPARTAMENTO DE ANTIOQUIA"
    gen CÓDIGO_MUNICIPIO = .
    gen tipo_fila        = "Promedio departamento"
    tempfile tdep
    save `tdep'
restore

* --- Detalle de la provincia + filas de promedios ---
keep if prov == "$provincia_nombre"
keep CÓDIGO_MUNICIPIO MUNICIPIO subreg prov Año COBERTURA_NETA DESERCIÓN REPITENCIA
gen tipo_fila = "Municipio"

append using `tprov'
append using `tsub'
append using `tdep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort Año orden_fila MUNICIPIO

*----------------------------------*
* Labels
*----------------------------------*
label variable CÓDIGO_MUNICIPIO "Código DANE"
label variable MUNICIPIO        "Municipio"
label variable subreg           "Subregión"
label variable prov             "Provincia"
label variable Año              "Año"
label variable COBERTURA_NETA   "Cobertura neta"
label variable DESERCIÓN        "Tasa de deserción"
label variable REPITENCIA       "Tasa de repitencia"

format COBERTURA_NETA DESERCIÓN REPITENCIA %6.2f

* Borrar archivo previo para no dejar las hojas obsoletas (antes: 3 hojas)
capture erase "$out_08/educacion.xlsx"

export excel ///
    CÓDIGO_MUNICIPIO MUNICIPIO subreg prov Año ///
    COBERTURA_NETA DESERCIÓN REPITENCIA ///
    using "$out_08/educacion.xlsx", ///
    sheet("educacion") firstrow(varlabels) sheetreplace


di as text "  08_Educacion: tabla exportada en $out_08/"
