* ----------------------------------------------------------------------------
* HOMOGENEIZACION - ECV_oficial_agregados.do
* OBJETIVO: construir el derivado de AGREGADOS OFICIALES de la ECV 2023 para
*           usar los valores oficiales de subregion / departamento / provincia
*           en el flujo (en vez de promediar estimaciones municipales).
* FUENTE:   01_Data/00_Inputs/Indicadores_ECV2023.xlsx (salida oficial ECV,
*           formato largo: Codigo Territorio Clase NomIndicador Valor CV Zona Tipo).
* SALIDA:   01_Data/01_Derived/ECV_oficial_agregados.dta
*           (una fila por nivel x territorio; columnas = indicadores por zona
*            tot/urb/rur, con nombres que calzan con el flujo).
* NIVELES:  SUBREGION (Tipo=Region, 9), PROVINCIA (Tipo=Provincia, solo 6 con
*           dato oficial) y DEPARTAMENTO (Antioquia).
* CLAVE DE CRUCE (`key`):
*   - SUBREGION -> nombre en MAYUSCULAS de codigos_municipios_clean.dta.
*   - PROVINCIA -> id_provincia (1-11) como texto (solo 5,6,7,8,9,10 disponibles).
*   - DEPARTAMENTO -> "ANTIOQUIA".
* ETAPA: Gini + NBI + IPM + laboral (ocupacion, informalidad, desocupacion
*        total y jovenes 15-28, NiNi) + coberturas de servicios publicos
*        (energia, acueducto, alcantarillado, recoleccion, internet, gas natural).
* NOTA: paths locales; correr una vez (etapa de homogenizacion) antes del flujo.
* ----------------------------------------------------------------------------

clear all
set more off

global rawdata "D:\IA Provincias\Proyecto datos y tablas\01_Data\00_Inputs"
global data    "D:\IA Provincias\Proyecto datos y tablas\01_Data\01_Derived"

* --- Importar la salida oficial (encabezados en la fila 14) ---
import excel "$rawdata/Indicadores_ECV2023.xlsx", sheet("Sheet1") cellrange(A14) firstrow clear
keep Territorio NomIndicador Valor Zona Tipo
destring Valor, replace force

* --- Indicadores de interes -> nombre corto (base) que calza con el flujo ---
gen ind = ""
gen pct = 0
* Gini (indice 0-1, NO se divide por 100)
replace ind = "gini_hog" if NomIndicador=="Gini: Ingresos de los hogares"
replace ind = "gini_lab" if NomIndicador=="Gini: Ingresos laborales de las personas ocupadas"
* NBI - personas en pobreza (%)
replace ind = "pob_nbi" if NomIndicador=="Porcentaje de personas en condición de pobreza por NBI"
* IPM - personas y hogares pobres (%)
replace ind = "pob_ipm"         if NomIndicador=="Porcentaje de personas pobres - IPM"
replace ind = "pob_ipm_hogares" if NomIndicador=="Porcentaje de hogares pobres - IPM"
* Laboral (%): ocupacion, informalidad, desocupacion total y jovenes 15-28, NiNi
replace ind = "to"           if NomIndicador=="Tasa de ocupación"
replace ind = "emp_informal" if NomIndicador=="Tasa de empleo informal"
replace ind = "td"           if NomIndicador=="Tasa de desocupados"
replace ind = "td_15_28"     if NomIndicador=="Tasa de desocupados para personas entre 15 y 28 años"
replace ind = "nini"         if NomIndicador=="Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados"
* Coberturas de servicios publicos (% de viviendas con SP) para 03_Ordenamiento
replace ind = "pob_energia"              if NomIndicador=="Porcentaje de viviendas con SP Energía"
replace ind = "pob_acueducto"            if NomIndicador=="Porcentaje de viviendas con SP Acueducto"
replace ind = "pob_alcantarillado"       if NomIndicador=="Porcentaje de viviendas con SP Alcantarillado"
replace ind = "pob_recoleccion_basuras"  if NomIndicador=="Porcentaje de viviendas con SP Recolección Basuras"
replace ind = "pob_internet"             if NomIndicador=="Porcentaje de viviendas con servicio de internet"
replace ind = "pob_gas_natural"          if NomIndicador=="Porcentaje de viviendas con servicio de gas natural por red"
* Los porcentajes se pasan a fraccion 0-1 (para calzar con la escala del flujo)
replace pct = 1 if inlist(ind,"pob_nbi","pob_ipm","pob_ipm_hogares")
replace pct = 1 if inlist(ind,"to","emp_informal","td","td_15_28","nini")
replace pct = 1 if inlist(ind,"pob_energia","pob_acueducto","pob_alcantarillado")
replace pct = 1 if inlist(ind,"pob_recoleccion_basuras","pob_internet","pob_gas_natural")
drop if ind==""
replace Valor = Valor/100 if pct==1

* --- Zona -> sufijo tot/urb/rur ---
gen z = ""
replace z = "tot" if Zona=="Total"
replace z = "urb" if Zona=="Urbano"
replace z = "rur" if Zona=="Rural"
drop if z==""

* --- Nivel ---
gen nivel = ""
replace nivel = "SUBREGION"    if Tipo=="Region"
replace nivel = "PROVINCIA"    if Tipo=="Provincia"
replace nivel = "DEPARTAMENTO" if strpos(Tipo,"Departamento")>0
drop if nivel==""

* --- Clave de cruce ---
gen key = ""
replace key = "BAJO CAUCA"      if nivel=="SUBREGION" & Territorio=="Bajo Cauca"
replace key = "MAGDALENA MEDIO" if nivel=="SUBREGION" & Territorio=="Magdalena Medio"
replace key = "NORDESTE"        if nivel=="SUBREGION" & Territorio=="Nordeste"
replace key = "NORTE"           if nivel=="SUBREGION" & Territorio=="Norte"
replace key = "OCCIDENTE"       if nivel=="SUBREGION" & Territorio=="Occidente"
replace key = "ORIENTE"         if nivel=="SUBREGION" & Territorio=="Oriente"
replace key = "SUROESTE"        if nivel=="SUBREGION" & Territorio=="Suroeste"
replace key = "URABA"           if nivel=="SUBREGION" & Territorio=="Urabá"
replace key = "VALLE DE ABURRA" if nivel=="SUBREGION" & Territorio=="Área Metropolitana"
replace key = "6"  if nivel=="PROVINCIA" & Territorio=="Provincia Cartama"
replace key = "9"  if nivel=="PROVINCIA" & Territorio=="Provincia Minero Agroecológica en el departamento de Antioquia"
replace key = "7"  if nivel=="PROVINCIA" & Territorio=="Provincia de La Paz"
replace key = "10" if nivel=="PROVINCIA" & Territorio=="Provincia de Penderisco y Sinifaná"
replace key = "8"  if nivel=="PROVINCIA" & Territorio=="Provincia de San Juan"
replace key = "5"  if nivel=="PROVINCIA" & Territorio=="Provincia del Agua, Bosques y Turismo"
replace key = "ANTIOQUIA" if nivel=="DEPARTAMENTO"
drop if key==""

* --- Etiqueta legible del territorio + columna ancha ---
gen terr_label = Territorio
gen col = z + "_" + ind
keep nivel key terr_label col Valor

* colapsar por si hay duplicados y pasar a ancho
collapse (mean) Valor, by(nivel key terr_label col)
reshape wide Valor, i(nivel key terr_label) j(col) string
foreach v of varlist Valor* {
    local nn = subinstr("`v'","Valor","",1)
    rename `v' `nn'
}

order nivel key terr_label
save "$data/ECV_oficial_agregados.dta", replace
di as text "  ECV_oficial_agregados.dta guardado (etapa Gini)."
