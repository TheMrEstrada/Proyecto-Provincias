cls
clear all
set more off

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	

*------------------------------------
* Población total
*------------------------------------

import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear sheet("Total_Municipios")
keep if AÑO==2025
keep DPMP MPIO AÑO ÁREAGEOGRÁFICA TotalGeneral

rename DPMP ind_mpio
destring ind_mpio, replace

save "$data/poblacion_total.dta", replace




