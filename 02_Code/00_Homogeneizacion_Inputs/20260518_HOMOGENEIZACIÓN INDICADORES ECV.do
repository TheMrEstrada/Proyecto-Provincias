cls
clear all
set more off

** Definir globals y directorios

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"

** Importar datos

tempfile ECV
save `ECV', emptyok

foreach s in "IPM" "NBI" "POBREZA" "INSEGURIDAD ALIMENTARIA" "GINI_HOG" "GINI_LAB" "DEMOGRAFÍA" "EMPLEO" "EDUCACIÓN" "VIVIENDA" {
	import excel "$rawdata/INDICADORES ECV 2023 MUNICIPIOS.xlsx", sheet("`s'") firstrow clear
	append using `ECV'
	save `ECV', replace
}

*Guardar datos crudos
save "$rawdata/ECV_raw.dta", replace


********************************
use "$rawdata/ECV_raw.dta", clear

keep Municipio NomMunicipio NomIndicador Valor_tot Valor_urb Valor_rur

*----------------------------------
* 1. Renombrar indicadores
*----------------------------------
replace NomIndicador="hog_mono_fem" if NomIndicador=="Porcentaje de hogares con jefe de hogar mujer sin presencia de cónyuge y con hijos menores de 18 años"
replace NomIndicador="pbl_camp" if NomIndicador=="Porcentaje de personas de 15 años o más que pertenecen a la población campesina"
replace NomIndicador="tgp_mujeres" if NomIndicador=="Tasa bruta de participación de las mujeres"
replace NomIndicador="emp_informal" if NomIndicador=="Tasa de empleo informal"
replace NomIndicador="td_hombres" if NomIndicador=="Tasa de desocupados en los hombres"
replace NomIndicador="td_mujeres" if NomIndicador=="Tasa de desocupados en las mujeres"
replace NomIndicador="gini_hog" if NomIndicador=="Gini: Ingresos de los hogares"
replace NomIndicador="gini_lab" if NomIndicador=="Gini: Ingresos laborales de las personas ocupadas"
replace NomIndicador="ins_alim_mod" if NomIndicador=="Inseguridad alimentaria_moderada"
replace NomIndicador="ins_alim_mod_5" if NomIndicador=="Inseguridad alimentaria_moderada para hogares con personas de 5 años o menos"
replace NomIndicador="ins_alim_mod_18" if NomIndicador=="Inseguridad alimentaria_moderada para hogares con personas menores de 18 años"
replace NomIndicador="ins_alim_sev" if NomIndicador=="Inseguridad alimentaria_severa"
replace NomIndicador="ins_alim_sev_5" if NomIndicador=="Inseguridad alimentaria_severa para hogares con personas de 5 años o menos"
replace NomIndicador="ins_alim_sev_18" if NomIndicador=="Inseguridad alimentaria_severa para hogares con personas menores de 18 años"
replace NomIndicador="pob_ipm" if NomIndicador=="Porcentaje de personas pobres - IPM"
replace NomIndicador="pob_ipm_hombres" if NomIndicador=="Porcentaje de hombres pobres - IPM"
replace NomIndicador="pob_ipm_mujeres" if NomIndicador=="Porcentaje de mujeres pobres - IPM"
replace NomIndicador="pob_ipm_hogares" if NomIndicador=="Porcentaje de hogares pobres - IPM"
replace NomIndicador="pob_nbi_hombres" if NomIndicador=="Porcentaje de hombres en condición de pobreza por NBI"
replace NomIndicador="pob_nbi_mujeres" if NomIndicador=="Porcentaje de mujeres en condición de pobreza por NBI"
replace NomIndicador="pob_nbi" if NomIndicador=="Porcentaje de personas en condición de pobreza por NBI"
replace NomIndicador="pob_nbi_hogares" if NomIndicador=="Porcentaje de hogares en condición de pobreza por NBI"
replace NomIndicador="pob_ext_hombres" if NomIndicador=="Porcentaje de hombres con ingreso per cápita por debajo de la LI"
replace NomIndicador="pob_mon_hombres" if NomIndicador=="Porcentaje de hombres con ingreso per cápita por debajo de la LP"
replace NomIndicador="pob_ext_mujeres" if NomIndicador=="Porcentaje de mujeres con ingreso per cápita por debajo de la LI"
replace NomIndicador="pob_mon_mujeres" if NomIndicador=="Porcentaje de mujeres con ingreso per cápita por debajo de la LP"
replace NomIndicador="pob_ext" if NomIndicador=="Porcentaje de personas con ingreso per cápita por debajo de la LI"
replace NomIndicador="pob_mon" if NomIndicador=="Porcentaje de personas con ingreso per cápita por debajo de la LP"


*Nuevas variables agregadas
replace NomIndicador="to" if NomIndicador=="Tasa de ocupación"
replace NomIndicador="to_hombres" if NomIndicador=="Tasa de ocupación de los hombres"
replace NomIndicador="to_mujeres" if NomIndicador=="Tasa de ocupación de las mujeres"
replace NomIndicador="emp_informal_hombres" if NomIndicador=="Tasa de empleo informal en hombres"
replace NomIndicador="emp_informal_mujeres" if NomIndicador=="Tasa de empleo informal en mujeres"
replace NomIndicador="td" if NomIndicador=="Tasa de desocupados"
replace NomIndicador="td_15_28" if NomIndicador=="Tasa de desocupados para personas entre 15 y 28 años"
replace NomIndicador="nini" if NomIndicador=="Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados"
replace NomIndicador="pob_alcantarillado" if NomIndicador=="Porcentaje de viviendas con SP Alcantarillado"
replace NomIndicador="pob_energia" if NomIndicador=="Porcentaje de viviendas con SP Energía"
replace NomIndicador="pob_acueducto" if NomIndicador=="Porcentaje de viviendas con SP Acueducto"
replace NomIndicador="pob_recoleccion_basuras" if NomIndicador=="Porcentaje de viviendas con SP Recolección Basuras"
replace NomIndicador="pob_internet" if NomIndicador=="Porcentaje de viviendas con servicio de internet"
replace NomIndicador="pob_gas_natural" if NomIndicador=="Porcentaje de viviendas con servicio de gas natural por red"
replace NomIndicador="pob_gas_pipeta" if NomIndicador=="Porcentaje de viviendas con servicio de gas licuado en pipeta"


* Quedarse solo con indicadores ya renombrados
keep if regexm(NomIndicador, "^[A-Za-z0-9_]+$")

*----------------------------------
* 2. Revisar duplicados antes del reshape
*----------------------------------
duplicates report Municipio NomMunicipio NomIndicador

/* Si hay duplicados, colapsar
collapse ///
    (mean) Valor_tot Valor_urb Valor_rur, ///
    by(Municipio NomMunicipio NomIndicador)
*/
*----------------------------------
* 3. Reshape wide
*----------------------------------
rename Valor_tot tot_
rename Valor_urb urb_
rename Valor_rur rur_

reshape wide tot_ urb_ rur_, ///
    i(Municipio NomMunicipio) ///
    j(NomIndicador) string

format tot_* urb_* rur_* %9.1f
rename Municipio ind_mpio

save "$data/ECV_nbi_pobreza.dta", replace



