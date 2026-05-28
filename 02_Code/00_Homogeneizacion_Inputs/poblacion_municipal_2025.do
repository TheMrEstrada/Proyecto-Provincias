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

import excel "$rawdata/PPED-AreaSexoEdadMun-2018-2042_VP.xlsx", firstrow clear sheet("PobMunicipalxÁreaSexoEdad") cellrange(A9)

rename A cod_dpto
rename B departamento
rename C ind_mpio //2020-2025
rename D nlv_label
rename E año
rename F area_geo

save "$data/poblacion_total.dta", replace

*Solo 2025
keep if año==2025
keep cod_dpto departamento ind_mpio nlv_label año area_geo Total Hombres Mujeres

destring ind_mpio, replace

save "$data/poblacion_total_2025.dta", replace




