* ----------------------------------------------------------------------------
* PROVINCIAS - 00_Tablas_Provincias.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/Tablas_provincias.xlsx
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	
	
/********************************************************************
* 3.3. Vivienda y servicios
********************************************************************/

*------------------------------------
* 1. Déficit cuantitativo de Vivienda 
*------------------------------------

* Importar Déficit cuantitativo desde Excel
import excel "$rawdata/deficit cuantitativo por municipio 2023.xlsx", cellrange(A2) firstrow clear

rename Cod_mpio ind_mpio
destring ind_mpio, replace
drop in 251/l

*crear variable total viviendas con déficit y proporción
destring Totalviviendas, replace
destring viviendas_con_deficit, replace

bysort ind_mpio: egen Total = total(Totalviviendas)
bysort ind_mpio: egen Total_viviendas_deficit = total(viviendas_con_deficit)
bysort ind_mpio: gen Total_deficit = Total_viviendas_deficit / Total

* Crear una fila adicional por municipio con zona = "Total"
expand 2 if zona == "Urbana", gen(nueva)

replace zona = "Total" if nueva == 1
replace deficit_cuantitativo = Total_deficit if zona == "Total"

drop nueva

keep ind_mpio zona deficit_cuantitativo Total_deficit

reshape wide deficit_cuantitativo, ///
    i(ind_mpio) ///
    j(zona) string

rename deficit_cuantitativoRural deficit_cuantitativo_rural
rename deficit_cuantitativoUrbana deficit_cuantitativo_urbana
rename deficit_cuantitativoTotal deficit_cuantitativo_total

drop Total_deficit

* Merge con códigos/provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge


preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         deficit_cuantitativo_total ///
         deficit_cuantitativo_urbana ///
         deficit_cuantitativo_rural

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    * OJO: no incluir subregion en el by()
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        deficit_cuantitativo_total ///
        deficit_cuantitativo_urbana ///
        deficit_cuantitativo_rural ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    * Orden explícito
    gen orden_fila = .
    replace orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    * Ordenar por provincia, no por subregión
    sort provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable deficit_cuantitativo_total  "Déficit cuantitativo total"
    label variable deficit_cuantitativo_urbana "Déficit cuantitativo urbano"
    label variable deficit_cuantitativo_rural  "Déficit cuantitativo rural"

    format deficit_cuantitativo_* %6.2f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        deficit_cuantitativo_total ///
        deficit_cuantitativo_urbana ///
        deficit_cuantitativo_rural ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("deficit_cuantitativo") ///
        firstrow(varlabels) sheetreplace

restore


/********************************************************************
* Servicios Públicos
* Cobertura Energía
********************************************************************/

use "$data/ECV_nbi_pobreza.dta", clear

* Subregión para TODOS los municipios
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

keep ind_mpio nvl_label subregion ///
     tot_pob_energia urb_pob_energia rur_pob_energia

tempfile full subreg depto base promedio
save `full'

* Promedio subregión - base completa
use `full', clear

collapse ///
    (mean) tot_pob_energia urb_pob_energia rur_pob_energia ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen nvl_label = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen ind_mpio = .
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg'

* Promedio departamental - base completa
use `full', clear

collapse ///
    (mean) tot_pob_energia urb_pob_energia rur_pob_energia ///
    (count) n_municipios = ind_mpio

gen nvl_label = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen ind_mpio = .
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto'

* Municipios con provincia
use `full', clear

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

gen tipo_fila = "Municipio"

save `base'

* Promedio provincial - solo municipios de provincia
use `base', clear

collapse ///
    (mean) tot_pob_energia urb_pob_energia rur_pob_energia ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen ind_mpio = .
gen subregion = "TOTAL PROVINCIA"

save `promedio'

* Unir todo
use `base', clear
append using `promedio'
append using `subreg'
append using `depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila nvl_label

label variable ind_mpio        "Código DANE"
label variable nvl_label       "Municipio"
label variable subregion       "Subregión"
label variable provincia       "Provincia"
label variable tipo_fila       "Tipo de fila"

label variable tot_pob_energia "Cobertura energía total"
label variable urb_pob_energia "Cobertura energía urbana"
label variable rur_pob_energia "Cobertura energía rural"

format tot_pob_energia urb_pob_energia rur_pob_energia %6.1f

export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    tot_pob_energia urb_pob_energia rur_pob_energia ///
    using "$output/tablas_3.3_5.4.xlsx", ///
    sheet("energia") ///
    firstrow(varlabels) sheetreplace

*--------------------------------------------------
* 3. Cobertura Alcantarillado (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_alcantarillado ///
         urb_pob_alcantarillado ///
         rur_pob_alcantarillado

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_alcantarillado ///
        urb_pob_alcantarillado ///
        rur_pob_alcantarillado ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio                 "Código DANE"
    label variable nvl_label                "Municipio"
    label variable subregion                "Subregión"
    label variable provincia                "Provincia"
    label variable tipo_fila                "Tipo de fila"

    label variable tot_pob_alcantarillado   "Cobertura alcantarillado total"
    label variable urb_pob_alcantarillado   "Cobertura alcantarillado urbana"
    label variable rur_pob_alcantarillado   "Cobertura alcantarillado rural"

    format tot_pob_alcantarillado ///
           urb_pob_alcantarillado ///
           rur_pob_alcantarillado %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_alcantarillado ///
        urb_pob_alcantarillado ///
        rur_pob_alcantarillado ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("alcantarillado") ///
        firstrow(varlabels) sheetreplace

restore

*--------------------------------------------------
* 4. Cobertura Acueducto (ECV)
*--------------------------------------------------


preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_acueducto ///
         urb_pob_acueducto ///
         rur_pob_acueducto

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_acueducto ///
        urb_pob_acueducto ///
        rur_pob_acueducto ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio             "Código DANE"
    label variable nvl_label            "Municipio"
    label variable subregion            "Subregión"
    label variable provincia            "Provincia"
    label variable tipo_fila            "Tipo de fila"

    label variable tot_pob_acueducto    "Cobertura acueducto total"
    label variable urb_pob_acueducto    "Cobertura acueducto urbana"
    label variable rur_pob_acueducto    "Cobertura acueducto rural"

    format tot_pob_acueducto ///
           urb_pob_acueducto ///
           rur_pob_acueducto %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_acueducto ///
        urb_pob_acueducto ///
        rur_pob_acueducto ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("acueducto") ///
        firstrow(varlabels) sheetreplace

restore

*--------------------------------------------------
* 5. Cobertura Recolección de basuras (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_recoleccion_basuras ///
         urb_pob_recoleccion_basuras ///
         rur_pob_recoleccion_basuras

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_recoleccion_basuras ///
        urb_pob_recoleccion_basuras ///
        rur_pob_recoleccion_basuras ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_recoleccion_basuras "Cobertura recolección de basuras total"
    label variable urb_pob_recoleccion_basuras "Cobertura recolección de basuras urbana"
    label variable rur_pob_recoleccion_basuras "Cobertura recolección de basuras rural"

    format tot_pob_recoleccion_basuras ///
           urb_pob_recoleccion_basuras ///
           rur_pob_recoleccion_basuras %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_recoleccion_basuras ///
        urb_pob_recoleccion_basuras ///
        rur_pob_recoleccion_basuras ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("recoleccion_basuras") ///
        firstrow(varlabels) sheetreplace

restore


*--------------------------------------------------
* 6. Cobertura Internet (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_internet ///
         urb_pob_internet ///
         rur_pob_internet

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_internet ///
        urb_pob_internet ///
        rur_pob_internet ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_internet "Cobertura internet total"
    label variable urb_pob_internet "Cobertura internet urbana"
    label variable rur_pob_internet "Cobertura internet rural"

    format tot_pob_internet ///
           urb_pob_internet ///
           rur_pob_internet %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_internet ///
        urb_pob_internet ///
        rur_pob_internet ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("internet") ///
        firstrow(varlabels) sheetreplace

restore


*--------------------------------------------------
* 6. Cobertura Gas natural (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_gas_natural ///
         urb_pob_gas_natural ///
         rur_pob_gas_natural

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_gas_natural ///
        urb_pob_gas_natural ///
        rur_pob_gas_natural ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_gas_natural "Cobertura gas natural total"
    label variable urb_pob_gas_natural "Cobertura gas natural urbana"
    label variable rur_pob_gas_natural "Cobertura gas natural rural"

    format tot_pob_gas_natural ///
           urb_pob_gas_natural ///
           rur_pob_gas_natural %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_gas_natural ///
        urb_pob_gas_natural ///
        rur_pob_gas_natural ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("gas_natural") ///
        firstrow(varlabels) sheetreplace

restore






/***********************************************************************
* 5.4 Turismo
***********************************************************************/

/*--------------------------------------------------------------------
  6. Conteo de Extranjeros 2019–2023
--------------------------------------------------------------------*/

*--- 6.1 Importar y preparar datos -----------------------------------

import excel "$rawdata/Turismo.xlsx", ///
    firstrow clear                    ///
    sheet("Conteo Extranjeros")

gen    periodo = ym(Año, Mes)
format periodo %tm

keep if inrange(periodo, ym(2019,1), ym(2023,5))   // Enero 2019 – Mayo 2023

save "$data/turismo_extranjeros.dta", replace


*--- 6.2 Revisión: cobertura municipal --------------------------------

use "$data/turismo_extranjeros.dta", clear

destring CODIGO_MUN, replace
rename   CODIGO_MUN ind_mpio

collapse (mean) CantExtranjerosnoResidentes, by(Año ind_mpio)

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
tab ind_mpio if _merge == 2

/* Municipios sin cobertura en el período analizado:
       05541  El Peñol              (datos solo desde 2025/2026)
       05647  San Andrés de Cuerquía
       05873  Vigía del Fuerte                                        */


*--- 6.3 Agregación por subregión exportación -------------

use "$data/turismo_extranjeros.dta", clear

destring CODIGO_MUN, replace
rename CODIGO_MUN ind_mpio

* Total anual por subregión
collapse (sum) CantExtranjerosnoResidentes, by(Año SUBREGION ind_mpio)
collapse (sum) CantExtranjerosnoResidentes, by(Año SUBREGION)
rename SUBREGION subregion

* Total anual del departamento
bysort Año: egen total_anual = total(CantExtranjerosnoResidentes)

* Participación porcentual
gen pct_anual = ///
    100 * CantExtranjerosnoResidentes / total_anual

* Formato
format pct_anual %6.2f

sort subregion Año CantExtranjerosnoResidentes pct_anual

label variable Año                         "Año"
label variable subregion                   "Subregión"
label variable CantExtranjerosnoResidentes "Extranjeros no residentes"
label variable pct_anual ///
    "Participación porcentual anual"

export excel ///
    Año subregion CantExtranjerosnoResidentes pct_anual ///
    using "$output/tablas_3.3_5.4.xlsx", ///
    sheet("turismo_extranjeros") firstrow(varlabels) sheetreplace
	
	
/*--------------------------------------------------------------------
  7. Motivos de viaje (nivel departamento, encuesta EMA DANE)
--------------------------------------------------------------------*/	

* Importar desde Excel
*******************************************************
* Importar base
*******************************************************
import excel "$rawdata/Turismo.xlsx", ///
    sheet("m_residentes_dpto") cellrange(A3) clear

*******************************************************
* Renombrar columnas
*******************************************************
rename A anio
rename B mes

rename C nac_vacaciones
rename D nac_trabajo
rename E nac_salud
rename F nac_convenciones
rename G nac_americas
rename H nac_otros

rename I ant_vacaciones
rename J ant_trabajo
rename K ant_salud
rename L ant_convenciones
rename M ant_americas
rename N ant_otros

*******************************************************
* Limpiar año: llenar hacia abajo
*******************************************************
replace anio = ustrregexra(anio, "[^0-9]", "")
destring anio, replace

replace anio = anio[_n-1] if missing(anio)

*******************************************************
* Crear mes numérico
*******************************************************
gen mes_num = .
replace mes_num = 1  if mes == "Enero"
replace mes_num = 2  if mes == "Febrero"
replace mes_num = 3  if mes == "Marzo"
replace mes_num = 4  if mes == "Abril"
replace mes_num = 5  if mes == "Mayo"
replace mes_num = 6  if mes == "Junio"
replace mes_num = 7  if mes == "Julio"
replace mes_num = 8  if mes == "Agosto"
replace mes_num = 9  if mes == "Septiembre"
replace mes_num = 10 if mes == "Octubre"
replace mes_num = 11 if mes == "Noviembre"
replace mes_num = 12 if mes == "Diciembre"

*******************************************************
* Crear periodo mensual
*******************************************************
gen periodo = ym(anio, mes_num)
format periodo %tm

*******************************************************
* Convertir variables numéricas
*******************************************************
destring nac_* ant_*, replace

*******************************************************
* Quedarse con años de interés (2019 a mayo de 2023)
*******************************************************
keep if period >=ym(2019,1)
keep if period <=ym(2023,5)
tab period

*******************************************************
* Pasar a formato largo
*******************************************************
reshape long nac_ ant_, i(periodo) j(motivo) string

rename nac_ total_nacional
rename ant_ antioquia

order anio mes_num mes periodo motivo total_nacional antioquia


*Promedio por año
collapse (mean) total_nacional antioquia, ///
    by(anio motivo)
	
*******************************************************
* Tabla Antioquia - Motivos de viaje
*******************************************************

preserve

keep anio motivo antioquia

*******************************************************
* Redondear
*******************************************************
replace antioquia = round(antioquia, 0.1)

*******************************************************
* Nombres bonitos de categorías
*******************************************************
replace motivo = "Vacaciones, ocio y recreo" if motivo=="vacaciones"
replace motivo = "Trabajo y negocios"        if motivo=="trabajo"
replace motivo = "Salud y atención médica"   if motivo=="salud"
replace motivo = "Convenciones (MICE)"       if motivo=="convenciones"
replace motivo = "Américas"                  if motivo=="americas"
replace motivo = "Otros"                     if motivo=="otros"

*******************************************************
* Pasar a formato ancho
*******************************************************
reshape wide antioquia, i(motivo) j(anio)

*******************************************************
* Labels para exportar bonito
*******************************************************
label variable motivo          "Motivo de viaje"
label variable antioquia2019   "2019"
label variable antioquia2020   "2020"
label variable antioquia2021   "2021"
label variable antioquia2022   "2022"
label variable antioquia2023   "2023"

*******************************************************
* Formato
*******************************************************
format antioquia* %9.1f

*******************************************************
* Exportar a Excel
*******************************************************
export excel                                            ///
    motivo                                               ///
    antioquia2019 antioquia2020 antioquia2021           ///
    antioquia2022 antioquia2023                         ///
    using "$output/tablas_3.3_5.4.xlsx",                ///
    sheet("motivos_antioquia_ema") firstrow(varlabels)      ///
    sheetreplace

restore


/*--------------------------------------------------------------------
  7. Inventario turístico
--------------------------------------------------------------------*/

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Inventario Turístico") firstrow clear	

destring CódMunicipio, replace
rename CódMunicipio ind_mpio

*----------------------------------*
* Chequeo ANTES del merge
*----------------------------------*
tab InventarioTurístico, missing

count if inlist(lower(strtrim(InventarioTurístico)), "sí", "si")
di "Total inventarios turísticos con Sí antes del merge = " r(N)

count if strpos(lower(strtrim(InventarioTurístico)), "proceso")
di "Total inventarios turísticos en proceso antes del merge = " r(N)

*----------------------------------*
* Merge con códigos/provincias
*----------------------------------*
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge	

rename InventarioTurístico InventarioTuristico

*----------------------------------*
* Limpiar categorías
*----------------------------------*
gen inventario_clean = lower(strtrim(InventarioTuristico))

gen inventario_si = inlist(inventario_clean, "sí", "si")
gen inventario_en_proceso = strpos(inventario_clean, "proceso") > 0
gen inventario_no = inventario_clean == "no"

* Conteos por provincia
bysort id_provincia provincia: egen n_inv_si_provincia = total(inventario_si)
bysort id_provincia provincia: egen n_inv_proceso_provincia = total(inventario_en_proceso)
bysort id_provincia provincia: egen n_inv_no_provincia = total(inventario_no)

* Conteos por subregión
bysort subregion: egen n_inv_si_subregion = total(inventario_si)
bysort subregion: egen n_inv_proceso_subregion = total(inventario_en_proceso)
bysort subregion: egen n_inv_no_subregion = total(inventario_no)

*----------------------------------*
* Tabla municipal
*----------------------------------*
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         InventarioTuristico ///
         n_inv_si_provincia n_inv_proceso_provincia n_inv_no_provincia ///
         n_inv_si_subregion n_inv_proceso_subregion n_inv_no_subregion

    gen tipo_fila = "Municipio"

    sort id_provincia nvl_label

    label variable ind_mpio                  "Código DANE"
    label variable nvl_label                 "Municipio"
    label variable subregion                 "Subregión"
    label variable provincia                 "Provincia"
    label variable tipo_fila                 "Tipo de fila"
    label variable InventarioTuristico       "Inventario turístico"

    label variable n_inv_si_provincia        "Inventarios turísticos Sí por provincia"
    label variable n_inv_proceso_provincia   "Inventarios turísticos en proceso por provincia"
    label variable n_inv_no_provincia        "Inventarios turísticos No por provincia"

    label variable n_inv_si_subregion        "Inventarios turísticos Sí por subregión"
    label variable n_inv_proceso_subregion   "Inventarios turísticos en proceso por subregión"
    label variable n_inv_no_subregion        "Inventarios turísticos No por subregión"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        InventarioTuristico ///
        n_inv_si_provincia n_inv_proceso_provincia n_inv_no_provincia ///
        n_inv_si_subregion n_inv_proceso_subregion n_inv_no_subregion ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("inventario_turistico") ///
        firstrow(varlabels) sheetreplace

restore



*--------------------------------------------------------------------
* 8. Plan local de turismo
*--------------------------------------------------------------------

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Plan Local de Turismo") firstrow clear	

destring CódMunicipio, replace
rename CódMunicipio ind_mpio

* Chequeo antes del merge
tab PlanLocaldeTurismo, missing

* Merge con códigos/provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge	

replace ActoAdministrativo = "Sin Información" if ActoAdministrativo == ""

* Indicador: tiene Plan Local de Turismo
gen plan_clean = lower(strtrim(PlanLocaldeTurismo))
gen plan_si = inlist(plan_clean, "sí", "si")

* Conteos por provincia y subregión
bysort id_provincia provincia: egen n_plan_si_provincia = total(plan_si)
bysort subregion: egen n_plan_si_subregion = total(plan_si)

* Tabla
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         PlanLocaldeTurismo ActoAdministrativo ///
         n_plan_si_provincia n_plan_si_subregion

    gen tipo_fila = "Municipio"

    sort id_provincia nvl_label

    label variable ind_mpio              "Código DANE"
    label variable nvl_label             "Municipio"
    label variable subregion             "Subregión"
    label variable provincia             "Provincia"
    label variable tipo_fila             "Tipo de fila"
    label variable PlanLocaldeTurismo    "Plan Local de Turismo"
    label variable ActoAdministrativo    "¿Se encuentra bajo acto administrativo?"
    label variable n_plan_si_provincia   "Planes locales de turismo por provincia"
    label variable n_plan_si_subregion   "Planes locales de turismo por subregión"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        PlanLocaldeTurismo ActoAdministrativo ///
        n_plan_si_provincia n_plan_si_subregion ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("plan_local_turismo") ///
        firstrow(varlabels) sheetreplace

restore


/*--------------------------------------------------------------------
  9. IOT
--------------------------------------------------------------------*/

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("IOT por Municipio") firstrow clear	

destring CódMunicipio, replace
rename CódMunicipio ind_mpio

* Chequeo antes del merge
tab EstadoIOT, missing

* Merge con códigos/provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge	

* Indicador: IOT actualizado
gen iot_clean = lower(strtrim(EstadoIOT))
gen iot_actualizado = iot_clean == "actualizado"

* Conteo por provincia y subregión
bysort id_provincia provincia: egen n_iot_actualizado_provincia = total(iot_actualizado)
bysort subregion: egen n_iot_actualizado_subregion = total(iot_actualizado)

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         EstadoIOT n_iot_actualizado_provincia n_iot_actualizado_subregion

    gen tipo_fila = "Municipio"

    sort id_provincia nvl_label

    label variable ind_mpio                    "Código DANE"
    label variable nvl_label                   "Municipio"
    label variable subregion                   "Subregión"
    label variable provincia                   "Provincia"
    label variable tipo_fila                   "Tipo de fila"
    label variable EstadoIOT                   "¿En qué estado se encuentra el IOT?"
    label variable n_iot_actualizado_provincia "IOT actualizados por provincia"
    label variable n_iot_actualizado_subregion "IOT actualizados por subregión"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        EstadoIOT n_iot_actualizado_provincia n_iot_actualizado_subregion ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("iot") ///
        firstrow(varlabels) sheetreplace

restore


/*--------------------------------------------------------------------
  10. Mesa local de Turismo 
--------------------------------------------------------------------*/

import excel "$rawdata/instrumentos_planificacion_turistica_antioquia.xlsx", ///
    sheet("Mesa Local de Turismo") firstrow clear	

	destring CódMunicipio, replace
	rename CódMunicipio ind_mpio
	

	*----------------------------------*
* Chequeo ANTES del merge
*----------------------------------*
tab MesaLocaldeTurismo, missing

count if inlist(lower(strtrim(MesaLocaldeTurismo)), "sí", "si")
di "Total de mesas conformadas antes del merge = " r(N)
	
	
*Merge con códigos/provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge	

* Indicador numérico: 1 si tiene mesa, 0 si no
gen mesa_si = .
replace mesa_si = 1 if lower(strtrim(MesaLocaldeTurismo)) == "sí" | lower(strtrim(MesaLocaldeTurismo)) == "si"
replace mesa_si = 0 if lower(strtrim(MesaLocaldeTurismo)) == "no"

* Conteo por provincia
bysort id_provincia provincia: egen n_mesas_provincia = total(mesa_si)

* Conteo por subregión
bysort subregion: egen n_mesas_subregion = total(mesa_si)

*Tabla

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         MesaLocaldeTurismo n_mesas_provincia n_mesas_subregion

    gen tipo_fila = "Municipio"

    sort id_provincia nvl_label

    label variable ind_mpio              "Código DANE"
    label variable nvl_label             "Municipio"
    label variable subregion             "Subregión"
    label variable provincia             "Provincia"
    label variable tipo_fila             "Tipo de fila"
    label variable MesaLocaldeTurismo    "¿Tiene Mesa Local de Turismo?"
    label variable n_mesas_provincia     "Número de mesas conformadas por provincia"
    label variable n_mesas_subregion     "Número de mesas conformadas por subregión"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        MesaLocaldeTurismo n_mesas_provincia n_mesas_subregion ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("mesa_local_turismo") ///
        firstrow(varlabels) sheetreplace

restore