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
* #Número de homicidios 2025
*------------------------------------

import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 2") cellrange(A15) clear

rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename AH total_2025
rename AI arma_fuego_2025
rename AJ arma_blanca_2025
rename AK contundente_2025
rename AL dron_explosivo_2025
rename AM otros_2025

keep if strpos(departamento, "ANTIOQUIA")

gen cod_mpio = substr(municipio, 1, 5)
destring cod_mpio, gen(ind_mpio)
gen nvl_label = strtrim(substr(municipio, 9, .))

order ind_mpio cod_mpio nvl_label departamento
keep ind_mpio cod_mpio nvl_label total_historico total_2025 arma_fuego_2025 arma_blanca_2025 contundente_2025 dron_explosivo_2025 otros_2025

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("homicidios_2025") sheetreplace firstrow(variables)


*------------------------------------
* violencia intrainfamliar 2025
*------------------------------------

import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 6") cellrange(A15) clear

rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename AH total_2025
rename AI sin_armas_2025
rename AJ arma_blanca_2025
rename AK contundente_2025
rename AL arma_fuego_2025
rename AM otros_2025

keep if strpos(departamento, "ANTIOQUIA")

gen cod_mpio = substr(municipio, 1, 5)
destring cod_mpio, gen(ind_mpio)
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2025 sin_armas_2025 arma_blanca_2025 contundente_2025 arma_fuego_2025 otros_2025 cod_mpio ind_mpio nvl_label
order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("violencia_intrafamiliar_2025") sheetreplace firstrow(variables)


*------------------------------------
* delitos sexuales 2025
*------------------------------------

import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 7") cellrange(A15) clear

rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename AH total_2025
rename AI sin_armas_2025
rename AJ arma_blanca_2025
rename AK arma_fuego_2025
rename AL contundente_2025
rename AM otros_2025

keep if strpos(departamento, "ANTIOQUIA")

gen cod_mpio = substr(municipio, 1, 5)
destring cod_mpio, gen(ind_mpio)
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2025 sin_armas_2025 arma_blanca_2025 arma_fuego_2025 contundente_2025 otros_2025 cod_mpio ind_mpio nvl_label
order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("delitos_sexuales_2025") sheetreplace firstrow(variables)


*------------------------------------
* hurtos a personas 2025
*------------------------------------

import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 10") cellrange(A15) clear

rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename IP total_2025
rename IQ sin_armas_2025
rename IR arma_blanca_2025
rename IS contundente_2025
rename IT arma_fuego_2025
rename IU otros_2025

keep if strpos(departamento, "ANTIOQUIA")

gen cod_mpio = substr(municipio, 1, 5)
destring cod_mpio, gen(ind_mpio)
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2025 sin_armas_2025 arma_blanca_2025 contundente_2025 arma_fuego_2025 otros_2025 cod_mpio ind_mpio nvl_label
order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("hurtos_personas_2025") sheetreplace firstrow(variables)	
	

/*------------------------------------
* #Número de homicidios 2023
*------------------------------------

* Importar Déficit cuantitativo desde Excel
import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 2")  cellrange(A15) clear

* Renombrar columnas según posición
rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename V total_2023
rename W arma_fuego_2023
rename X arma_blanca_2023
rename Y contundente_2023
rename Z dron_explosivo_2023
rename AA otros_2023

* Quedarse solo con Antioquia
keep if strpos(departamento, "ANTIOQUIA")

* Sacar código DANE municipal desde "05001 - Medellín"
gen cod_mpio = substr(municipio, 1, 5)

* Opcional: dejar código numérico para merge con ind_mpio
destring cod_mpio, gen(ind_mpio)

* Limpiar nombre municipio
gen nvl_label = strtrim(substr(municipio, 9, .))

order ind_mpio cod_mpio nvl_label departamento
keep ind_mpio cod_mpio nvl_label total_historico total_2023 arma_fuego_2023 arma_blanca_2023 contundente_2023 dron_explosivo_2023 otros_2023

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("homicidios_2023") sheetreplace firstrow(variables) 
	
	
*------------------------------------
* violencia intrainfamliar 2023
*------------------------------------

* Importar Déficit cuantitativo desde Excel
import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 6")  cellrange(A15) clear

* Renombrar columnas según posición
rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename V total_2023
rename W sin_armas_2023
rename X arma_blanca_2023
rename Y contundente_2023
rename Z arma_fuego_2023
rename AA otros_2023

* Quedarse solo con Antioquia
keep if strpos(departamento, "ANTIOQUIA")

* Sacar código DANE municipal desde "05001 - Medellín"
gen cod_mpio = substr(municipio, 1, 5)

* Opcional: dejar código numérico para merge con ind_mpio
destring cod_mpio, gen(ind_mpio)

* Limpiar nombre municipio
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2023 sin_armas_2023 arma_blanca_2023 contundente_2023 arma_fuego_2023 otros_2023 cod_mpio ind_mpio nvl_label

order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("violencia_intrafamiliar_2023") sheetreplace firstrow(variables) 	
	
	
*------------------------------------
* delitos sexuales 2023
*------------------------------------

* Importar Déficit cuantitativo desde Excel
import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 7")  cellrange(A15) clear

* Renombrar columnas según posición
rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename V total_2023
rename W sin_armas_2023
rename X arma_blanca_2023
rename Y arma_fuego_2023
rename Z contundente_2023
rename AA otros_2023

* Quedarse solo con Antioquia
keep if strpos(departamento, "ANTIOQUIA")

* Sacar código DANE municipal desde "05001 - Medellín"
gen cod_mpio = substr(municipio, 1, 5)

* Opcional: dejar código numérico para merge con ind_mpio
destring cod_mpio, gen(ind_mpio)

* Limpiar nombre municipio
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2023 sin_armas_2023 arma_blanca_2023 arma_fuego_2023 contundente_2023 otros_2023 cod_mpio ind_mpio nvl_label

order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("delitos_sexuales_2023") sheetreplace firstrow(variables) 		
	

*------------------------------------
* hurtos a personas 2023
*------------------------------------

* Importar Déficit cuantitativo desde Excel
import excel "$rawdata/CUADRO_DE_SALIDA_DELICTIVO_HISTÓRICO_2020_2025", sheet("Cuadro 10")  cellrange(A15) clear

* Renombrar columnas según posición
rename A departamento
rename B municipio
rename C total_historico //2020-2025
rename EV total_2023
rename EW sin_armas_2023
rename EX arma_blanca_2023
rename EY contundente_2023
rename EZ arma_fuego_2023
rename FA otros_2023

* Quedarse solo con Antioquia
keep if strpos(departamento, "ANTIOQUIA")

* Sacar código DANE municipal desde "05001 - Medellín"
gen cod_mpio = substr(municipio, 1, 5)

* Opcional: dejar código numérico para merge con ind_mpio
destring cod_mpio, gen(ind_mpio)

* Limpiar nombre municipio
gen nvl_label = strtrim(substr(municipio, 9, .))

keep total_historico total_2023 sin_armas_2023 arma_blanca_2023 contundente_2023 arma_fuego_2023 otros_2023 cod_mpio ind_mpio nvl_label

order ind_mpio cod_mpio nvl_label 

export excel using "$data/seguridad_policia.xlsx", ///
    sheet("hurtos_personas_2023") sheetreplace firstrow(variables) 	
*/

