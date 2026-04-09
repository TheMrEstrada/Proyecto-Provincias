cls
clear all
set more off

** Definir globals y directorios

global input "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS"
global output "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS/BASES HOMOGENEIZADAS"

** Importar datos

tempfile ECV
save `ECV', emptyok

foreach s in "IPM" "NBI" "POBREZA" "INSEGURIDAD ALIMENTARIA" "GINI_HOG" "GINI_LAB" "DEMOGRAFÍA" "EMPLEO" {
	import excel "${input}/INDICADORES ECV 2023 MUNICIPIOS.xlsx", sheet("`s'") firstrow clear
	append using `ECV'
	save `ECV', replace
}

** Conservar indicadores priorizados

g ind_prior=.
	replace ind_prior=1 if NomIndicador=="Porcentaje de hogares con jefe de hogar mujer sin presencia de cónyuge y con hijos menores de 18 años"
	replace ind_prior=1 if NomIndicador=="Porcentaje de personas de 15 años o más que pertenecen a la población campesina"
	replace ind_prior=1 if NomIndicador=="Tasa bruta de participación de las mujeres"
	replace ind_prior=1 if NomIndicador=="Tasa de empleo informal"
	replace ind_prior=1 if NomIndicador=="Tasa de desocupados en los hombres"
	replace ind_prior=1 if NomIndicador=="Tasa de desocupados en las mujeres"
	replace ind_prior=1 if NomIndicador=="Gini: Ingresos de los hogares"
	replace ind_prior=1 if NomIndicador=="Gini: Ingresos laborales de las personas ocupadas"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_moderada"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_moderada para hogares con personas de 5 años o menos"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_moderada para hogares con personas menores de 18 años"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_severa"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_severa para hogares con personas de 5 años o menos"
	replace ind_prior=1 if NomIndicador=="Inseguridad alimentaria_severa para hogares con personas menores de 18 años"
	replace ind_prior=1 if NomIndicador=="Porcentaje de personas pobres - IPM"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hombres pobres - IPM"
	replace ind_prior=1 if NomIndicador=="Porcentaje de mujeres pobres - IPM"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hogares pobres - IPM"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hombres en condición de pobreza por NBI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de mujeres en condición de pobreza por NBI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de personas en condición de pobreza por NBI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hogares en condición de pobreza por NBI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hombres con ingreso per cápita por debajo de la LI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de hombres con ingreso per cápita por debajo de la LP"
	replace ind_prior=1 if NomIndicador=="Porcentaje de mujeres con ingreso per cápita por debajo de la LI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de mujeres con ingreso per cápita por debajo de la LP"
	replace ind_prior=1 if NomIndicador=="Porcentaje de personas con ingreso per cápita por debajo de la LI"
	replace ind_prior=1 if NomIndicador=="Porcentaje de personas con ingreso per cápita por debajo de la LP"

keep if ind_prior==1

** Conservar variables de interés

keep Municipio NomMunicipio NomIndicador Valor_tot // UnidadGeográfica Año UnidaddeMedida Fuente CálculosPropios Observaciones

** Ajustar nombre de los indicadores

replace NomIndicador="hog_mono_fem" if NomIndicador=="Porcentaje de hogares con jefe de hogar mujer sin presencia de cónyuge y con hijos menores de 18 años"
replace NomIndicador="pbl_camp" if NomIndicador=="Porcentaje de personas de 15 años o más que pertenecen a la población campesina"
replace NomIndicador="tgp_mujeres" if NomIndicador=="Tasa bruta de participación de las mujeres"
replace NomIndicador="emp_informal" if NomIndicador=="Tasa de empleo informal"
* replace NomIndicador="td_brecha" if NomIndicador=="Brecha en la tasa de desocupación entre hombres y mujeres"
replace NomIndicador="td_hombres" if NomIndicador=="Tasa de desocupados en los hombres"
replace NomIndicador="td_mujeres" if NomIndicador=="Tasa de desocupados en las mujeres"
replace NomIndicador="gini_hog" if NomIndicador=="Gini: Ingresos de los hogares"
replace NomIndicador="gini_lab" if NomIndicador=="Gini: Ingresos laborales de las personas ocupadas"
* replace NomIndicador="ins_alim" if NomIndicador=="Inseguridad alimentaria"
* replace NomIndicador="ins_alim_5" if NomIndicador=="Inseguridad alimentaria para hogares con personas de 5 años o menos"
* replace NomIndicador="ins_alim_18" if NomIndicador=="Inseguridad alimentaria para hogares con personas menores de 18 años"
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

** Asignar formato a los valores

format Valor_tot %4.1f

** Transformar datos en estructura amplia

ren Valor_tot x_
reshape wide x_, i(Municipio) j(NomIndicador) string
renvars *, subst(x_ )
order NomMunicipio, after(Municipio)

** Calcular indicadores pendientes

g td_brecha=(td_mujeres - td_hombres)
g ins_alim=(ins_alim_mod + ins_alim_sev)
g ins_alim_5=(ins_alim_mod_5 + ins_alim_sev_5)
g ins_alim_18=(ins_alim_mod_18 + ins_alim_sev_18)

** Homegeneización nombre de variables

ren (Municipio NomMunicipio) (ind_mpio nvl_label)

** Guardar base de datos

compress

preserve
	keep ind_mpio nvl_label td_hombres td_mujeres ins_alim_5 ins_alim_18 ins_alim_mod ins_alim_mod_5 ins_alim_mod_18 ins_alim_sev ins_alim_sev_5 ins_alim_sev_18 pob_ipm_hombres pob_ipm_mujeres pob_ipm_hogares pob_nbi_hombres pob_nbi_mujeres pob_nbi_hogares pob_ext_hombres pob_mon_hombres pob_ext_mujeres pob_mon_mujeres
	export excel using "${output}/20250506 ECV ADICIONALES.xlsx", firstrow(variables) replace
restore

keep ind_mpio nvl_label hog_mono_fem pbl_camp tgp_mujeres emp_informal td_brecha gini_hog gini_lab ins_alim pob_ipm pob_nbi pob_ext pob_mon
export excel using "${output}/20250506 ECV.xlsx", firstrow(variables) replace
