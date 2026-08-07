* ----------------------------------------------------------------------------
* PROVINCIAS - 03_Ordenamiento.do
* SECCION 3: ORDENAMIENTO DEL TERRITORIO
* FIGURAS (nivel A integrado):
*   - 3.4 CTI: IMCA (dimensiones y adopcion TIC), Indice de Gobierno Digital
*         + componentes FURAG, tasa de transito inmediato a educacion superior
*   - 3.5 Internet fijo MinTIC: lineas/1.000 hab y % fibra optica
*   - 3.5 Deficit cuantitativo de vivienda (2023)
*   - 3.5 Acceso a servicios publicos (energia, acueducto, alcantarillado,
*         recoleccion de basuras, internet, gas natural)
* INPUTS:
*   $rawdata/deficit cuantitativo por municipio 2023.xlsx
*   $data/ECV_nbi_pobreza.dta
*   $rawdata/POBLACION MUNICIPAL.xlsx   (peso poblacional)
*   $rawdata/codigos_provincias.dta
* OUTPUTS: $out_03/ordenamiento.xlsx (hojas: deficit_vivienda, servicios_publicos,
*   vias_area, vias_habitantes, catastro, imca, gobierno_digital, tti_edsup,
*   internet_2025)
* REQUIERE: 00_master.do (define globals)
* PENDIENTE: "estado del catastro" (decision) y cobertura de CATASTRO.xlsx en
*   prov. 5 y 11 (ver registro de pendientes).
* ----------------------------------------------------------------------------

capture erase "$out_03/ordenamiento.xlsx"


/********************************************************************
* 3.5.1 Deficit cuantitativo de vivienda (2023)
*   Deficit municipal = Sum(viviendas_con_deficit) / Sum(Total viviendas).
*   Agregados provincia, subregión y departamento = ratio agregado
*   (Σ viviendas con déficit / Σ viviendas), no promedio.
********************************************************************/

* Déficit cuantitativo (conteos por municipio)
import excel "$rawdata/deficit cuantitativo por municipio 2023.xlsx", cellrange(A2) firstrow clear
keep if inlist(zona, "Urbana", "Rural")   // descartar filas mal formadas del insumo
rename Cod_mpio ind_mpio
destring ind_mpio Totalviviendas viviendas_con_deficit, replace force
collapse (sum) Totalviviendas viviendas_con_deficit, by(ind_mpio)
rename Totalviviendas        viv_cuanti
rename viviendas_con_deficit vdef_cuanti
tempfile dcuanti
save `dcuanti'

* Déficit cualitativo (conteos por municipio)
import excel "$rawdata/deficit cualitativo por municipio 2023.xlsx", cellrange(A2) firstrow clear
keep if inlist(zona, "Urbana", "Rural")   // el insumo cualitativo trae filas mal formadas
rename Cod_mpio ind_mpio
destring ind_mpio Totaldeviviendas viviendas_con_deficit, replace force
collapse (sum) Totaldeviviendas viviendas_con_deficit, by(ind_mpio)
rename Totaldeviviendas      viv_cuali
rename viviendas_con_deficit vdef_cuali

* Unir ambos déficits + provincia/subregión (TODOS los municipios)
merge 1:1 ind_mpio using "`dcuanti'", nogen
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen

keep ind_mpio nvl_label subregion provincia id_provincia ///
     vdef_cuanti viv_cuanti vdef_cuali viv_cuali
tempfile def_all
save `def_all'

* --- Municipios de la provincia (tasa municipal) ---
use `def_all', clear
keep if id_provincia == $id_provincia
gen deficit_cuanti = vdef_cuanti / viv_cuanti
gen deficit_cuali  = vdef_cuali  / viv_cuali
gen tipo_fila = "Municipio"
tempfile base
save `base'

* --- Provincia = TASA AGREGADA (Σ viviendas con déficit / Σ viviendas) ---
use `def_all', clear
keep if id_provincia == $id_provincia
collapse (sum) vdef_cuanti viv_cuanti vdef_cuali viv_cuali, by(provincia)
gen deficit_cuanti = vdef_cuanti / viv_cuanti
gen deficit_cuali  = vdef_cuali  / viv_cuali
gen nvl_label = "PROVINCIA $provincia_label (tasa agregada: Σ viviendas con déficit / Σ viviendas)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (tasa agregada)"
tempfile agg_prov
save `agg_prov'

* --- Subregión mayoritaria = TASA AGREGADA (todos sus municipios) ---
use `def_all', clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

use `def_all', clear
keep if subregion == "`dom_subreg'"
collapse (sum) vdef_cuanti viv_cuanti vdef_cuali viv_cuali
gen deficit_cuanti = vdef_cuanti / viv_cuanti
gen deficit_cuali  = vdef_cuali  / viv_cuali
gen nvl_label = "SUBREGIÓN `dom_subreg' (tasa agregada)"
gen subregion = ""
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Total subregión"
tempfile agg_sub
save `agg_sub'

* --- Departamento = TASA AGREGADA (todos los municipios de Antioquia) ---
use `def_all', clear
collapse (sum) vdef_cuanti viv_cuanti vdef_cuali viv_cuali
gen deficit_cuanti = vdef_cuanti / viv_cuanti
gen deficit_cuali  = vdef_cuali  / viv_cuali
gen nvl_label = "DEPARTAMENTO (ANTIOQUIA) (tasa agregada)"
gen subregion = ""
gen provincia = "DEPARTAMENTO DE ANTIOQUIA"
gen ind_mpio  = .
gen tipo_fila = "Total departamento"
tempfile agg_dep
save `agg_dep'

* --- Unir todo ---
use `base', clear
append using `agg_prov'
append using `agg_sub'
append using `agg_dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (tasa agregada)"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"
sort orden_fila nvl_label

label variable ind_mpio       "Código DANE"
label variable nvl_label      "Municipio"
label variable subregion      "Subregión"
label variable provincia      "Provincia"
label variable deficit_cuanti "Déficit cuantitativo de vivienda"
label variable deficit_cuali  "Déficit cualitativo de vivienda"
format deficit_cuanti deficit_cuali %6.4f

export excel ///
    ind_mpio nvl_label subregion provincia deficit_cuanti deficit_cuali ///
    using "$out_03/ordenamiento.xlsx", sheet("deficit_vivienda") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.5.2 Acceso a servicios publicos (coberturas ECV: % de viviendas con SP)
*   Municipios: detalle (mismo valor que la ECV oficial municipal).
*   Agregados: valor OFICIAL ECV en subregion, departamento y las 6 provincias
*   con dato; en las otras 5 provincias, promedio ponderado por poblacion.
*   (Antes: subregion/departamento se promediaban -> aproximacion. Corregido.)
********************************************************************/

* Peso poblacional: poblacion total municipal 2025 (todos los municipios)
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pesos
save `pesos'

* Coberturas ECV (todos los municipios) -> fracción 0-1, con peso y subregión
use "$data/ECV_nbi_pobreza.dta", clear
keep ind_mpio tot_pob_energia tot_pob_acueducto tot_pob_alcantarillado ///
     tot_pob_recoleccion_basuras tot_pob_internet tot_pob_gas_natural
foreach v in tot_pob_energia tot_pob_acueducto tot_pob_alcantarillado tot_pob_recoleccion_basuras tot_pob_internet tot_pob_gas_natural {
    replace `v' = `v' / 100
}
merge 1:1 ind_mpio using "`pesos'", keep(master match) nogen
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión COMPLETA (crosswalk 125) para el agregado de subregión
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen
tempfile serv_all
save `serv_all'

* Coberturas ECV = valores OFICIALES en subregión/departamento/provincia (donde
* exista). Estas coberturas ("% de viviendas con SP") tienen dato oficial de las 6
* provincias; en las otras 5 la provincia se calcula (promedio ponderado por pob.).
* REQUIERE: 00_Homogeneizacion_Inputs/ECV_oficial_agregados.do.
local svars tot_pob_energia tot_pob_acueducto tot_pob_alcantarillado tot_pob_recoleccion_basuras tot_pob_internet tot_pob_gas_natural

* --- Subregión dominante de la provincia (crosswalk 125) ---
use `serv_all', clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Municipios de la provincia (detalle) ---
use `serv_all', clear
keep if id_provincia == $id_provincia
keep ind_mpio nvl_label subregion provincia `svars'
gen tipo_fila  = "Municipio"
gen orden_fila = 1
tempfile base2
save `base2'

* --- Provincia: oficial ECV si es de las 6; si no, promedio ponderado por población ---
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="PROVINCIA" & key=="${id_provincia}"
if _N > 0 {
    keep `svars'
    gen nvl_label = "PROVINCIA $provincia_label (ECV oficial)"
}
else {
    use `serv_all', clear
    keep if id_provincia == $id_provincia
    foreach v of local svars {
        gen _x_`v' = `v' * pob_peso
        gen _w_`v' = pob_peso if !missing(`v')
    }
    collapse (sum) _x_* _w_*
    foreach v of local svars {
        gen `v' = _x_`v' / _w_`v'
    }
    drop _x_* _w_*
    gen nvl_label = "PROVINCIA $provincia_label (promedio ponderado; sin ECV oficial)"
}
gen provincia  = "$provincia_nombre"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Provincia"
gen orden_fila = 2
keep ind_mpio nvl_label subregion provincia `svars' tipo_fila orden_fila
tempfile st_prov
save `st_prov'

* --- Subregión dominante (oficial) ---
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="SUBREGION" & key=="`dom_subreg'"
keep `svars'
gen nvl_label  = "SUBREGIÓN `dom_subreg' (ECV oficial)"
gen provincia  = ""
gen subregion  = "`dom_subreg'"
gen ind_mpio   = .
gen tipo_fila  = "Subregión"
gen orden_fila = 3
tempfile stsub
save `stsub'

* --- Departamento (oficial) ---
use "$data/ECV_oficial_agregados.dta", clear
keep if nivel=="DEPARTAMENTO" & key=="ANTIOQUIA"
keep `svars'
gen nvl_label  = "DEPARTAMENTO (ANTIOQUIA) (ECV oficial)"
gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
gen subregion  = ""
gen ind_mpio   = .
gen tipo_fila  = "Departamento"
gen orden_fila = 4
tempfile stdep
save `stdep'

* --- Unir: municipios + agregados ---
use `base2', clear
append using `st_prov'
append using `stsub'
append using `stdep'
sort orden_fila nvl_label

* Split _mun (detalle municipal, ECV_nbi_pobreza) / _ofi (agregado, ECV_oficial_agregados)
foreach v in tot_pob_energia tot_pob_acueducto tot_pob_alcantarillado tot_pob_recoleccion_basuras tot_pob_internet tot_pob_gas_natural {
    gen `v'_mun = `v' if tipo_fila == "Municipio"
    gen `v'_ofi = `v' if tipo_fila != "Municipio"
    drop `v'
}
label variable ind_mpio                    "Código DANE"
label variable nvl_label                   "Municipio"
label variable subregion                   "Subregión"
label variable provincia                   "Provincia"
label variable tot_pob_energia_mun             "Cobertura de energía (%) (municipal)"
label variable tot_pob_energia_ofi             "Cobertura de energía (%) (agregado)"
label variable tot_pob_acueducto_mun           "Cobertura de acueducto (%) (municipal)"
label variable tot_pob_acueducto_ofi           "Cobertura de acueducto (%) (agregado)"
label variable tot_pob_alcantarillado_mun      "Cobertura de alcantarillado (%) (municipal)"
label variable tot_pob_alcantarillado_ofi      "Cobertura de alcantarillado (%) (agregado)"
label variable tot_pob_recoleccion_basuras_mun "Cobertura de recolección de basuras (%) (municipal)"
label variable tot_pob_recoleccion_basuras_ofi "Cobertura de recolección de basuras (%) (agregado)"
label variable tot_pob_internet_mun            "Cobertura de internet (%) (municipal)"
label variable tot_pob_internet_ofi            "Cobertura de internet (%) (agregado)"
label variable tot_pob_gas_natural_mun         "Cobertura de gas natural (%) (municipal)"
label variable tot_pob_gas_natural_ofi         "Cobertura de gas natural (%) (agregado)"
format *_mun *_ofi %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    tot_pob_energia_mun tot_pob_energia_ofi tot_pob_acueducto_mun tot_pob_acueducto_ofi ///
    tot_pob_alcantarillado_mun tot_pob_alcantarillado_ofi tot_pob_recoleccion_basuras_mun tot_pob_recoleccion_basuras_ofi ///
    tot_pob_internet_mun tot_pob_internet_ofi tot_pob_gas_natural_mun tot_pob_gas_natural_ofi ///
    using "$out_03/ordenamiento.xlsx", sheet("servicios_publicos") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.3 Kilometros de via (segun area y por cada mil habitantes)
*   Fuente: infraestructura_municipios_dicc  (IDV_* = km/area ; VPC_* = km/1000 hab)
*   Agregado provincial:
*     - IDV (km/area): ponderado por AREA   = Sum(km)/Sum(area)
*     - VPC (km/1000h): ponderado por POBLACION = Sum(km)/Sum(pob)*1000
********************************************************************/

* Area municipal (provincia)
import excel "$rawdata/AREA_ORIGINAL.xlsx", sheet("Area") firstrow clear
rename COD_MPIO ind_mpio
destring ind_mpio, replace force
rename AREAKM2 area_km2
destring area_km2, replace force
keep ind_mpio area_km2
tempfile area_v
save `area_v'

* Poblacion municipal (provincia) - peso
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2025
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pob_v
save `pob_v'

use "$data/infraestructura_municipios_dicc", clear
keep ind_mpio IDV_pri IDV_sec IDV_ter VPC_pri VPC_sec VPC_ter
rename IDV_pri idv_pri
rename IDV_sec idv_sec
rename IDV_ter idv_ter
rename VPC_pri vpc_pri
rename VPC_sec vpc_sec
rename VPC_ter vpc_ter
destring ind_mpio idv_pri idv_sec idv_ter vpc_pri vpc_sec vpc_ter, replace force   // el derivado trae todo como texto
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge 1:1 ind_mpio using "`area_v'", keep(master match) nogen
merge 1:1 ind_mpio using "`pob_v'", keep(master match) nogen
tempfile via_prov
save `via_prov'

* --- 3.3.1 Km de via segun el area (IDV, ponderado por area) ---
use `via_prov', clear
keep ind_mpio nvl_label subregion provincia area_km2 idv_pri idv_sec idv_ter
gen tipo_fila = "Municipio"
tempfile base
save `base'
foreach v in idv_pri idv_sec idv_ter {
    gen _x_`v' = `v' * area_km2
    gen _w_`v' = area_km2 if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in idv_pri idv_sec idv_ter {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por área del municipio)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"
append using `base'
gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
sort orden_fila nvl_label
label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable idv_pri   "Km de vía primaria por km² del municipio"
label variable idv_sec   "Km de vía secundaria por km² del municipio"
label variable idv_ter   "Km de vía terciaria por km² del municipio"
format idv_* %8.3f
export excel ind_mpio nvl_label subregion provincia idv_pri idv_sec idv_ter ///
    using "$out_03/ordenamiento.xlsx", sheet("vias_area") firstrow(varlabels) sheetreplace

* --- 3.3.2 Km de via por cada mil habitantes (VPC, ponderado por poblacion) ---
use `via_prov', clear
keep ind_mpio nvl_label subregion provincia pob_peso vpc_pri vpc_sec vpc_ter
gen tipo_fila = "Municipio"
tempfile base
save `base'
foreach v in vpc_pri vpc_sec vpc_ter {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in vpc_pri vpc_sec vpc_ter {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (ponderado)"
append using `base'
gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (ponderado)"
sort orden_fila nvl_label
label variable ind_mpio  "Código DANE"
label variable nvl_label "Municipio"
label variable subregion "Subregión"
label variable provincia "Provincia"
label variable vpc_pri   "Km de vía primaria por cada 1.000 hab."
label variable vpc_sec   "Km de vía secundaria por cada 1.000 hab."
label variable vpc_ter   "Km de vía terciaria por cada 1.000 hab."
format vpc_* %8.3f
export excel ind_mpio nvl_label subregion provincia vpc_pri vpc_sec vpc_ter ///
    using "$out_03/ordenamiento.xlsx", sheet("vias_habitantes") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.1 Caracterizacion del catastro municipal
*   Fuentes: CATASTRO.xlsx (hoja "Consolidado Urb + Rural") = avaluos;
*     ESTADO_CATASTRO.xlsx (hoja "Catastro_Full") = estado del catastro
*     categorico rural/urbano (integrado 2026-08-05).
*   Columnas avaluo (por posicion): C=COD DANE, M=avaluo urbano, V=avaluo rural,
*     W=avaluo total. Proporciones urbano/rural sobre el total (derivadas).
*   "Estado del catastro" = categorico (Actualizado / Ajuste pendiente /
*     Rezagado / No actualizado); solo por municipio (sin agregado provincial).
*   Agregado provincial = suma de avaluos y proporciones recomputadas.
*   COBERTURA: ni avaluo ni estado cubren 10 municipios de la PAP (prov. 5:
*     Marinilla, San Vicente Ferrer; prov. 11 Area Metropolitana) -> pendiente.
********************************************************************/

* Estado del catastro (categorico rural/urbano) -> tempfile para merge
import excel "$data/ESTADO_CATASTRO.xlsx", sheet("Catastro_Full") cellrange(A2) clear
keep B D F
rename B ind_mpio
rename D estado_catastro_rural
rename F estado_catastro_urbano
destring ind_mpio, replace force
drop if missing(ind_mpio)
tempfile estado_cat
save `estado_cat'

import excel "$rawdata/CATASTRO.xlsx", sheet("Consolidado Urb + Rural") cellrange(A2) clear
keep C M V W
rename C ind_mpio
rename M avaluo_urbano
rename V avaluo_rural
rename W avaluo_total
destring ind_mpio avaluo_urbano avaluo_rural avaluo_total, replace force
drop if missing(ind_mpio)

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

* Estado del catastro (categorico) por municipio
merge m:1 ind_mpio using "`estado_cat'", keep(master match) nogen

gen prop_avaluo_urbano = avaluo_urbano / avaluo_total
gen prop_avaluo_rural  = avaluo_rural  / avaluo_total

gen tipo_fila = "Municipio"
tempfile base
save `base'

* Agregado provincial: solo avaluos (el estado es categorico -> sin agregado)
collapse (sum) avaluo_urbano avaluo_rural avaluo_total, by(provincia)
gen prop_avaluo_urbano = avaluo_urbano / avaluo_total
gen prop_avaluo_rural  = avaluo_rural  / avaluo_total
gen nvl_label = "TOTAL PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total provincia"
append using `base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
sort orden_fila nvl_label

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable avaluo_total       "Avalúo catastral total ($)"
label variable avaluo_urbano      "Avalúo catastral urbano ($)"
label variable avaluo_rural       "Avalúo catastral rural ($)"
label variable prop_avaluo_urbano "Proporción del avalúo catastral urbano sobre el total (%)"
label variable prop_avaluo_rural  "Proporción del avalúo catastral rural sobre el total (%)"
label variable estado_catastro_rural  "Estado del catastro rural"
label variable estado_catastro_urbano "Estado del catastro urbano"
format avaluo_* %15.0f
format prop_avaluo_* %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    avaluo_total avaluo_urbano avaluo_rural prop_avaluo_urbano prop_avaluo_rural ///
    estado_catastro_rural estado_catastro_urbano ///
    using "$out_03/ordenamiento.xlsx", sheet("catastro") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.4 CTI - Índice Municipal de Competitividad (IMCA) 2022
*   Figuras: "IMCA por dimensiones (Provincia vs municipios)" y
*            "IMCA: Adopción de TIC por municipio".
*   Fuente: $data/imca_2022.dta (derivado; municipios con ind_mpio "05001";
*     el insumo TRAE filas oficiales de subregión "SR01".."SR09").
*   IMCA es un ÍNDICE (0-100): NO se convierte a fracción.
*   Agregados:
*     - Provincia: PROMEDIO PONDERADO por población 2022 (Σ imca·pob / Σ pob).
*     - Subregión: valor OFICIAL de subregión del propio insumo (filas SR..).
*   Reutiliza/adapta 02_Code/02_Tablas_Gobernanza.do (bloque IMCA).
********************************************************************/

* --- Peso poblacional 2022 (para ponderar el agregado provincial) ---
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2022
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pob22
save `pob22'

* --- IMCA oficial de subregión (filas SR.. del insumo) ---
use "$data/imca_2022.dta", clear
keep if regexm(ind_mpio, "^SR")
gen subregion = ""
replace subregion = "VALLE DE ABURRA" if ind_mpio=="SR01"
replace subregion = "BAJO CAUCA"      if ind_mpio=="SR02"
replace subregion = "MAGDALENA MEDIO" if ind_mpio=="SR03"
replace subregion = "NORDESTE"        if ind_mpio=="SR04"
replace subregion = "NORTE"           if ind_mpio=="SR05"
replace subregion = "OCCIDENTE"       if ind_mpio=="SR06"
replace subregion = "ORIENTE"         if ind_mpio=="SR07"
replace subregion = "SUROESTE"        if ind_mpio=="SR08"
replace subregion = "URABA"           if ind_mpio=="SR09"
keep subregion imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
     imca_infraestructura imca_innovacion imca_instituciones ///
     imca_merc_bienes imca_merc_laboral imca_salud imca_sist_financiero imca_tam_mercado
tempfile imca_sr
save `imca_sr'

* --- Municipios de la provincia ---
use "$data/imca_2022.dta", clear
destring ind_mpio, replace force            // "05001" -> 5001 ; "SR.." -> missing
drop if missing(ind_mpio)
keep ind_mpio imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
     imca_infraestructura imca_innovacion imca_instituciones ///
     imca_merc_bienes imca_merc_laboral imca_salud imca_sist_financiero imca_tam_mercado
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge m:1 ind_mpio using "`pob22'", keep(master match) nogen
gen tipo_fila = "Municipio"
tempfile base
save `base'

* --- Fila(s) de subregión de la provincia (IMCA oficial de subregión) ---
use `base', clear
contract subregion
keep subregion
merge 1:1 subregion using "`imca_sr'", keep(match) nogen
gen subregion_name = subregion
gen nvl_label = "SUBREGIÓN " + subregion_name + " (IMCA oficial de subregión)"
replace subregion = subregion_name
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Subregión (IMCA oficial)"
drop subregion_name
tempfile sr_prov
save `sr_prov'

* --- Provincia: PROMEDIO PONDERADO por población 2022 ---
use `base', clear
foreach v in imca_total imca_adop_tic imca_capacidades imca_dinam_neg imca_infraestructura imca_innovacion imca_instituciones imca_merc_bienes imca_merc_laboral imca_salud imca_sist_financiero imca_tam_mercado {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v in imca_total imca_adop_tic imca_capacidades imca_dinam_neg imca_infraestructura imca_innovacion imca_instituciones imca_merc_bienes imca_merc_laboral imca_salud imca_sist_financiero imca_tam_mercado {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población 2022)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (promedio ponderado)"

append using `base'
append using `sr_prov'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (promedio ponderado)"
replace orden_fila = 3 if tipo_fila == "Subregión (IMCA oficial)"
sort orden_fila nvl_label

label variable ind_mpio             "Código DANE"
label variable nvl_label            "Municipio"
label variable subregion            "Subregión"
label variable provincia            "Provincia"
label variable imca_total           "IMCA total"
label variable imca_adop_tic        "IMCA adopción TIC"
label variable imca_capacidades     "IMCA capacidades"
label variable imca_dinam_neg       "IMCA dinamismo de los negocios"
label variable imca_infraestructura "IMCA infraestructura"
label variable imca_innovacion      "IMCA innovación"
label variable imca_instituciones   "IMCA instituciones"
label variable imca_merc_bienes     "IMCA mercado de bienes"
label variable imca_merc_laboral    "IMCA mercado laboral"
label variable imca_salud           "IMCA salud"
label variable imca_sist_financiero "IMCA sistema financiero"
label variable imca_tam_mercado     "IMCA tamaño del mercado"
format imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
       imca_infraestructura imca_innovacion imca_instituciones ///
       imca_merc_bienes imca_merc_laboral imca_salud ///
       imca_sist_financiero imca_tam_mercado %12.2f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
    imca_infraestructura imca_innovacion imca_instituciones ///
    imca_merc_bienes imca_merc_laboral imca_salud ///
    imca_sist_financiero imca_tam_mercado ///
    using "$out_03/ordenamiento.xlsx", sheet("imca") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.4 CTI - Índice de Gobierno Digital 2024 (FURAG)
*   Figuras: "Índice de Gobierno Digital 2024" y
*            "Índice de Gobierno Digital por componente FURAG 2024".
*   Fuente: $data/indice_gobierno_digital_2024.dta (derivado de
*     $rawdata/Indice_gobierno_digital_2024.xlsx vía datalake gestión pública).
*   Índice 0-100: NO se convierte a fracción.
*   Agregados (ambos PROMEDIO PONDERADO por población 2024):
*     - Provincia: sobre los municipios de la provincia.
*     - Subregión: sobre TODOS los municipios de la subregión (insumo no trae
*       fila oficial de subregión, por eso se calcula ponderado).
*   Reutiliza/adapta 02_Code/02_Tablas_Gobernanza.do (bloque Gob. Digital).
********************************************************************/

local gdvars gobierno_digital gobernanza innovacion_digital arquitectura seguridad_privacidad servicios_ciudadanos cultura_apropiacion servicios_inteligentes estado_abierto decisiones_datos proyectos_transformacion ciudades_territorios

* --- Peso poblacional 2024 ---
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO == 2024
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP TotalGeneral
rename DPMP ind_mpio
destring ind_mpio, replace
destring TotalGeneral, replace force
rename TotalGeneral pob_peso
tempfile pob24
save `pob24'

* --- Subregión: promedio ponderado por población 2024 (todos los municipios) ---
use "$data/indice_gobierno_digital_2024.dta", clear
capture drop municipio
keep ind_mpio `gdvars'
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", keep(master match) nogen
merge m:1 ind_mpio using "`pob24'", keep(master match) nogen
foreach v of local gdvars {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(subregion)
foreach v of local gdvars {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
tempfile gd_sr
save `gd_sr'

* --- Municipios de la provincia ---
use "$data/indice_gobierno_digital_2024.dta", clear
capture drop municipio
keep ind_mpio `gdvars'
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
merge m:1 ind_mpio using "`pob24'", keep(master match) nogen
gen tipo_fila = "Municipio"
tempfile base
save `base'

* --- Fila(s) de subregión de la provincia (promedio ponderado) ---
use `base', clear
contract subregion
keep subregion
merge 1:1 subregion using "`gd_sr'", keep(match) nogen
gen subregion_name = subregion
gen nvl_label = "PROMEDIO PONDERADO SUBREGIÓN " + subregion_name + " (por población 2024)"
replace subregion = subregion_name
gen provincia = ""
gen ind_mpio  = .
gen tipo_fila = "Subregión (promedio ponderado)"
drop subregion_name
tempfile gd_sr_prov
save `gd_sr_prov'

* --- Provincia: PROMEDIO PONDERADO por población 2024 ---
use `base', clear
foreach v of local gdvars {
    gen _x_`v' = `v' * pob_peso
    gen _w_`v' = pob_peso if !missing(`v')
}
collapse (sum) _x_* _w_*, by(provincia)
foreach v of local gdvars {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen nvl_label = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población 2024)"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (promedio ponderado)"

append using `base'
append using `gd_sr_prov'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (promedio ponderado)"
replace orden_fila = 3 if tipo_fila == "Subregión (promedio ponderado)"
sort orden_fila nvl_label

label variable ind_mpio                 "Código DANE"
label variable nvl_label                "Municipio"
label variable subregion                "Subregión"
label variable provincia                "Provincia"
label variable gobierno_digital         "Índice de Gobierno Digital"
label variable gobernanza               "Gobernanza"
label variable innovacion_digital       "Innovación Pública Digital"
label variable arquitectura             "Arquitectura"
label variable seguridad_privacidad     "Seguridad y Privacidad de la Información"
label variable servicios_ciudadanos     "Servicios Ciudadanos Digitales"
label variable cultura_apropiacion      "Cultura y Apropiación"
label variable servicios_inteligentes   "Servicios y Procesos Inteligentes"
label variable estado_abierto           "Estado Abierto"
label variable decisiones_datos         "Decisiones basadas en datos"
label variable proyectos_transformacion "Proyectos de Transformación Digital"
label variable ciudades_territorios     "Estrategias de Ciudades y Territorios Inteligentes"
format gobierno_digital gobernanza innovacion_digital arquitectura ///
       seguridad_privacidad servicios_ciudadanos cultura_apropiacion ///
       servicios_inteligentes estado_abierto decisiones_datos ///
       proyectos_transformacion ciudades_territorios %12.2f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    gobierno_digital gobernanza innovacion_digital arquitectura ///
    seguridad_privacidad servicios_ciudadanos cultura_apropiacion ///
    servicios_inteligentes estado_abierto decisiones_datos ///
    proyectos_transformacion ciudades_territorios ///
    using "$out_03/ordenamiento.xlsx", sheet("gobierno_digital") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.4 CTI - Tasa de tránsito inmediato a la educación superior
*   Fuente: $data/20250506 EDUCACION.xlsx (variable tti_edsup, escala 0-100).
*   Convención decimal: llega en 0-100 -> se divide /100 (fracción; % en Excel).
*   Agregado provincial: PROMEDIO SIMPLE.
*   Reutiliza la lógica de 02_Code/02_Tablas_Gobernanza.do (bloque TTI).
********************************************************************/

import excel "$data/20250506 EDUCACION.xlsx", firstrow clear
keep ind_mpio tti_edsup
destring ind_mpio tti_edsup, replace force
replace tti_edsup = tti_edsup / 100          // 0-100 -> fracción 0-1

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

gen tipo_fila = "Municipio"
tempfile base
save `base'

collapse (mean) tti_edsup, by(provincia)
gen nvl_label = "PROMEDIO SIMPLE PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (promedio simple)"
append using `base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (promedio simple)"
sort orden_fila nvl_label

label variable ind_mpio   "Código DANE"
label variable nvl_label  "Municipio"
label variable subregion  "Subregión"
label variable provincia  "Provincia"
label variable tti_edsup  "Tasa de tránsito inmediato a la educación superior"
format tti_edsup %6.4f

export excel ///
    ind_mpio nvl_label subregion provincia tti_edsup ///
    using "$out_03/ordenamiento.xlsx", sheet("tti_edsup") firstrow(varlabels) sheetreplace


/********************************************************************
* 3.5 Vivienda y servicios - Internet fijo (MinTIC 2025)
*   Figuras: "Líneas de acceso a internet fijo por cada 1.000 habitantes" y
*            "Proporción de líneas sobre fibra óptica (%)".
*   Fuente: $data/infraestructura_internet_2025.dta (MinTIC, líneas fijas 2025)
*     + $data/poblacion_total_2025.dta (denominador poblacional).
*   internet_1000hab = tasa (x1.000): NO se convierte. prop_fibra: fracción 0-1.
*   Agregado provincial: PROMEDIO SIMPLE de las tasas municipales (decisión de
*     Pablo; el método queda declarado en la etiqueta del agregado).
*   Reutiliza la lógica de 02_Code/02_Tablas_Gobernanza.do (bloque internet),
*     con una mejora: se calcula lineas_fibra por suma condicional en vez de
*     "keep if fibra==1", para NO perder municipios con 0 líneas de fibra.
*   VERIFICAR EN LA 1a CORRIDA los nombres de columnas del insumo
*     (servicio_paquete, estado, tecnologia, cantidad_lineas_accesos, area_geo).
********************************************************************/

use "$data/infraestructura_internet_2025.dta", clear
keep if servicio_paquete == "Internet fijo"
keep if estado == "Activo en funcionamiento"

* Marca de fibra óptica (agrupa categorías FTTx)
gen fibra = strpos(tecnologia, "Fiber to the") > 0 | ///
            tecnologia == "Otras tecnologías de fibra (antes FTTx)"

* Colapsar a municipio x fibra y reconstruir totales sin perder municipios
collapse (sum) cantidad_lineas_accesos, by(ind_mpio fibra)
gen _lin_fibra = cantidad_lineas_accesos * (fibra == 1)
bys ind_mpio: egen lineas_totales = total(cantidad_lineas_accesos)
bys ind_mpio: egen lineas_fibra   = total(_lin_fibra)
bys ind_mpio: keep if _n == 1
keep ind_mpio lineas_totales lineas_fibra
gen prop_fibra = lineas_fibra / lineas_totales

* Denominador poblacional (población total municipal 2025)
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo == "Total"
rename Total poblacion
keep ind_mpio lineas_totales lineas_fibra prop_fibra poblacion
gen internet_1000hab = lineas_totales / poblacion * 1000

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

gen tipo_fila = "Municipio"
tempfile base
save `base'

* Agregado provincial = PROMEDIO SIMPLE de las tasas municipales
collapse (mean) lineas_totales lineas_fibra prop_fibra internet_1000hab, by(provincia)
gen nvl_label = "PROMEDIO SIMPLE PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Provincia (promedio simple)"
append using `base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia (promedio simple)"
sort orden_fila nvl_label

label variable ind_mpio         "Código DANE"
label variable nvl_label        "Municipio"
label variable subregion        "Subregión"
label variable provincia        "Provincia"
label variable lineas_totales   "Líneas de acceso a internet fijo"
label variable lineas_fibra     "Líneas de acceso a internet fijo por fibra óptica"
label variable prop_fibra       "Proporción de líneas sobre fibra óptica"
label variable internet_1000hab "Líneas de acceso a internet fijo por cada 1.000 habitantes"
format lineas_totales lineas_fibra %12.0fc
format prop_fibra %6.4f
format internet_1000hab %8.2f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    lineas_totales lineas_fibra prop_fibra internet_1000hab ///
    using "$out_03/ordenamiento.xlsx", sheet("internet_2025") firstrow(varlabels) sheetreplace




/********************************************************************
* 3.1 Uso adecuado del suelo rural (POTA)
*   Figura: "Uso adecuado del suelo rural PAP – 2025".
*   Fuente: $data/uso_del_suelo_pota.xlsx (POTA). Se exporta ÚNICAMENTE el
*     % de predios rurales con USO ADECUADO (decisión de Pablo; las demás
*     categorías no se necesitan). Trae codmpio (código DANE).
*   Convención decimal: llega 0-100 -> /100 (fracción).
*   SIN AGREGADOS (decisión 2026-08-06): solo municipios, sin promedio de
*     provincia/subregión/departamento. La fuente POTA cubre solo 88 de los
*     125 municipios de Antioquia (58 de la PAP; p. ej. 5 de 7 en la prov. 4),
*     y la ausencia no es aleatoria: cualquier agregado se calcularía sobre el
*     subconjunto con dato y se leería como el valor real del territorio. Por
*     eso el indicador se deja a nivel municipal.
*   Los municipios de la provincia SIN dato aparecen igual, con la celda en
*     blanco (cobertura del insumo).
********************************************************************/

* --- Datos POTA (tempfile) ---
import excel "$data/uso_del_suelo_pota.xlsx", sheet("Sheet1") firstrow clear
rename codmpio ind_mpio
destring ind_mpio pct_uso_adecuado_rural, replace force
keep ind_mpio pct_uso_adecuado_rural
replace pct_uso_adecuado_rural = pct_uso_adecuado_rural / 100
tempfile pota
save `pota'

* --- Base: TODOS los municipios de la provincia (desde códigos) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
keep ind_mpio nvl_label subregion provincia id_provincia
merge 1:1 ind_mpio using "`pota'", keep(master match) nogen
gen tipo_fila = "Municipio"

sort nvl_label

label variable ind_mpio               "Código DANE"
label variable nvl_label              "Municipio"
label variable subregion              "Subregión"
label variable provincia              "Provincia"
label variable pct_uso_adecuado_rural "Predios con uso adecuado del suelo rural"
format pct_uso_adecuado_rural %6.4f

export excel ///
    ind_mpio nvl_label subregion provincia pct_uso_adecuado_rural ///
    using "$out_03/ordenamiento.xlsx", sheet("uso_suelo_rural") firstrow(varlabels) sheetreplace


di as text "  03_Ordenamiento: hojas exportadas en $out_03/ordenamiento.xlsx"
