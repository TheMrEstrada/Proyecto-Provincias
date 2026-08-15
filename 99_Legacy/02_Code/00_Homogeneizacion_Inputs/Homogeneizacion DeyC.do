cls
clear all
set more off

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"

** Importar datos

import excel "${rawdata}/DATALAKE DEyC.xlsx", sheet("Sheet1") firstrow clear

** Conservar observaciones a nivel municipal

drop if UnidadGeográfica=="Nacional"

** Conservar indicadores priorizados

g ind_prior=.
	replace ind_prior=1 if Indicador=="Valor agregado per capita"
	replace ind_prior=1 if Indicador=="Participacion por actidad economica del Valor agregado - Actividades Primarias"
	replace ind_prior=1 if Indicador=="Número de corresponsalespor cada 1.000 habitantes" // Este puede requerir serie de tiempo
	replace ind_prior=1 if Indicador=="Número de microcréditopor cada 1.000 habitantes" // Este puede requerir serie de tiempo
	replace ind_prior=1 if Indicador=="Tasa de natalidad empresarial neta" 
	replace ind_prior=1 if Indicador=="Densidad empresarial (número de empresas por cada mil habitantes)"
	replace ind_prior=1 if Indicador=="Creación neta de empresas"


keep if ind_prior==1

** Conservar la observación más reciente de cada indicador

egen anno_max=max(Año), by(CódigoUnidadGeográfica Indicador)
g anno_prior=(anno_max==Año)

keep if anno_prior==1

** Conservar variables de interés

keep CódigoUnidadGeográfica /*NombreUnidadGeográfica*/ Indicador DatoNumérico // UnidadGeográfica Año UnidaddeMedida Fuente CálculosPropios Observaciones

** Ajustar nombre de los indicadores

replace Indicador="fin_banc_pc" if Indicador=="Número de corresponsalespor cada 1.000 habitantes"
replace Indicador="fin_microcr_pc" if Indicador=="Número de microcréditopor cada 1.000 habitantes"
replace Indicador="dens_emp" if Indicador=="Densidad empresarial (número de empresas por cada mil habitantes)"
replace Indicador="va_pc" if Indicador=="Valor agregado per capita"
replace Indicador="va_primario" if Indicador=="Participacion por actidad economica del Valor agregado - Actividades Primarias"
replace Indicador="tnat_emp" if Indicador=="Tasa de natalidad empresarial neta"
replace Indicador="creacion_emp" if Indicador=="Creación neta de empresas"

** Asignar formato a los valores

format DatoNumérico %4.1f

** Transformar datos en estructura amplia

rename DatoNumérico valor_

reshape wide valor_, ///
    i(CódigoUnidadGeográfica) ///
    j(Indicador) string

foreach var of varlist valor_* {
    local nuevo = subinstr("`var'", "valor_", "", .)
    rename `var' `nuevo'
}

** Homogeneización nombre de variables

rename CódigoUnidadGeográfica ind_mpio

** Guardar base de datos

compress
export excel using "${data}/estructura_productiva.xlsx", firstrow(variables) replace
save "${data}/estructura_productiva.dta", replace


*base para IMCA*
cls 
clear all
set more off

* ---- Configuración de directorios ----
global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
global rawdata "$path/01_Data/00_Inputs"
global scripts "$path/02_Code"
global data "$path/01_Data/01_Derived"
global output "$path/03_Outputs"

** Importar datos
import excel "${rawdata}/DATALAKE DEyC.xlsx", sheet("Sheet1") firstrow clear

** Conservar observaciones a nivel municipal
drop if UnidadGeográfica=="Nacional"

** Conservar año 2022
keep if Año==2022

** Conservar indicadores IMCA
gen ind_prior = 0

replace ind_prior=1 if Indicador=="IMCA según pilar: adopción TIC"
replace ind_prior=1 if Indicador=="IMCA según pilar: capacidades"
replace ind_prior=1 if Indicador=="IMCA según pilar: dinamismo de los negocios"
replace ind_prior=1 if Indicador=="IMCA según pilar: infraestructura"
replace ind_prior=1 if Indicador=="IMCA según pilar: innovación"
replace ind_prior=1 if Indicador=="IMCA según pilar: instituciones"
replace ind_prior=1 if Indicador=="IMCA según pilar: mercado de bienes"
replace ind_prior=1 if Indicador=="IMCA según pilar: mercado laboral"
replace ind_prior=1 if Indicador=="IMCA según pilar: salud"
replace ind_prior=1 if Indicador=="IMCA según pilar: sistema financiero"
replace ind_prior=1 if Indicador=="IMCA según pilar: tamaño del mercado"
replace ind_prior=1 if Indicador=="Índice Municipal de Competitividad en Antioquia (IMCA)"

keep if ind_prior==1

** Conservar variables de interés
keep CódigoUnidadGeográfica Indicador DatoNumérico Año

** Ajustar nombre de los indicadores
replace Indicador="imca_adop_tic"        if Indicador=="IMCA según pilar: adopción TIC"
replace Indicador="imca_capacidades"    if Indicador=="IMCA según pilar: capacidades"
replace Indicador="imca_dinam_neg"      if Indicador=="IMCA según pilar: dinamismo de los negocios"
replace Indicador="imca_infraestructura" if Indicador=="IMCA según pilar: infraestructura"
replace Indicador="imca_innovacion"     if Indicador=="IMCA según pilar: innovación"
replace Indicador="imca_instituciones"  if Indicador=="IMCA según pilar: instituciones"
replace Indicador="imca_merc_bienes"    if Indicador=="IMCA según pilar: mercado de bienes"
replace Indicador="imca_merc_laboral"   if Indicador=="IMCA según pilar: mercado laboral"
replace Indicador="imca_salud"          if Indicador=="IMCA según pilar: salud"
replace Indicador="imca_sist_financiero" if Indicador=="IMCA según pilar: sistema financiero"
replace Indicador="imca_tam_mercado"    if Indicador=="IMCA según pilar: tamaño del mercado"
replace Indicador="imca_total"          if Indicador=="Índice Municipal de Competitividad en Antioquia (IMCA)"

** Asignar formato a los valores
format DatoNumérico %4.2f

** Revisar duplicados antes del reshape
duplicates report CódigoUnidadGeográfica Indicador

** Transformar datos en estructura amplia
rename DatoNumérico valor_

reshape wide valor_, ///
    i(CódigoUnidadGeográfica) ///
    j(Indicador) string

foreach var of varlist valor_* {
    local nuevo = subinstr("`var'", "valor_", "", .)
    rename `var' `nuevo'
}

** Homogeneización nombre de variables
rename CódigoUnidadGeográfica ind_mpio

** Guardar base de datos
compress
export excel using "${data}/imca_2022.xlsx", firstrow(variables) replace
save "${data}/imca_2022.dta", replace