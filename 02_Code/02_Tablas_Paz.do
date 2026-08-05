* ----------------------------------------------------------------------------
* PROVINCIAS - 02_Tablas_Paz.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/tablas_paz.xlsx
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"


*************
* Número de solicitudes de inscripción al SRTDAF recibidas en la Unidad de Restitución de Tierras *

import excel "$rawdata/Estadísticas_Solicitudes_Restitución_Discriminadas_Municipios_20260704.xlsx", firstrow clear
	
keep if DepartamentoDelPredio =="Antioquia"	
rename CodigoDANE ind_mpio

keep ind_mpio MunicipioDelPredio NumeroDeSolicitudes

merge 1:m ind_mpio using "$data/poblacion_total_2025.dta" //no está Sabaneta en la base
keep if area_geo =="Total"
rename Total poblacion
drop _merge

* Solicitudes de restitución de tierras por cada 1.000 habitantes
gen solicitudes_1000hab = NumeroDeSolicitudes / poblacion * 1000
drop if missing(solicitudes_1000hab) 


/********************************************************************
* Paz - Solicitudes de restitución de tierras
********************************************************************/

*--------------------------------------------------
* Merge con subregión
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

*--------------------------------------------------
* Merge con provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
drop if _merge==2
drop _merge

gen tipo_fila = "Municipio"

tempfile base prom_prov prom_subreg prom_depto
save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen ind_mpio = .
gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen subregion = "TOTAL PROVINCIA"

save `prom_prov'

*--------------------------------------------------
* Promedio subregional
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen ind_mpio = .
gen nvl_label = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `prom_subreg'

*--------------------------------------------------
* Promedio departamental
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio

gen ind_mpio = .
gen nvl_label = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `prom_depto'

*--------------------------------------------------
* Unir todo
*--------------------------------------------------
use `base', clear

append using `prom_prov'
append using `prom_subreg'
append using `prom_depto'

gen orden_fila = 1 if tipo_fila=="Municipio"
replace orden_fila = 2 if tipo_fila=="Promedio provincia"
replace orden_fila = 3 if tipo_fila=="Promedio subregión"
replace orden_fila = 4 if tipo_fila=="Promedio departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas
*--------------------------------------------------
label variable ind_mpio               "Código DANE"
label variable nvl_label              "Municipio"
label variable subregion              "Subregión"
label variable provincia              "Provincia"
label variable tipo_fila              "Tipo de fila"
label variable NumeroDeSolicitudes    "Número de solicitudes de restitución"
label variable solicitudes_1000hab    "Solicitudes de restitución por cada 1.000 habitantes"
label variable n_municipios           "Número de municipios"

format NumeroDeSolicitudes %12.0fc
format solicitudes_1000hab %12.2f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    NumeroDeSolicitudes solicitudes_1000hab n_municipios ///
    using "$output/tablas_paz.xlsx", ///
    sheet("restitucion_tierras") ///
    firstrow(varlabels) sheetreplace