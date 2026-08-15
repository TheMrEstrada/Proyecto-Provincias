cls
clear all
set more off

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	

	
	
import delimited "$rawdata/EMPAQUETAMIENTO_FIJO_3"	
gen period = yq(anno, trimestre)
format period %tq

keep if id_departamento==5
rename id_municipio ind_mpio 

*Quedarse con 2025
keep if anno == 2025

*Guardar base
save "${data}/infraestructura_internet_2025.dta", replace



