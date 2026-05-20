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

* Importar población municipal desde Excel
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

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio provincial
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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable deficit_cuantitativo_total ///
        "Déficit cuantitativo total"

    label variable deficit_cuantitativo_urbana ///
        "Déficit cuantitativo urbano"

    label variable deficit_cuantitativo_rural ///
        "Déficit cuantitativo rural"

    format deficit_cuantitativo_* %6.2f

    *----------------------------------*
    * Exportar
    *----------------------------------*
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
********************************************************************/

use "$data/ECV_nbi_pobreza.dta", clear

*Merge con códigos/provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*--------------------------------------------------
* 2. Cobertura Energía (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_energia ///
         urb_pob_energia ///
         rur_pob_energia

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_energia ///
        urb_pob_energia ///
        rur_pob_energia ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio        "Código DANE"
    label variable nvl_label       "Municipio"
    label variable subregion       "Subregión"
    label variable provincia       "Provincia"
    label variable tipo_fila       "Tipo de fila"

    label variable tot_pob_energia ///
        "Cobertura energía total"

    label variable urb_pob_energia ///
        "Cobertura energía urbana"

    label variable rur_pob_energia ///
        "Cobertura energía rural"

    format tot_pob_energia urb_pob_energia rur_pob_energia %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_energia ///
        urb_pob_energia ///
        rur_pob_energia ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("energia") ///
        firstrow(varlabels) sheetreplace

restore

*--------------------------------------------------
* 3. Cobertura Alcantarillado (ECV)
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_alcantarillado ///
         urb_pob_alcantarillado ///
         rur_pob_alcantarillado

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio                 "Código DANE"
    label variable nvl_label                "Municipio"
    label variable subregion                "Subregión"
    label variable provincia                "Provincia"
    label variable tipo_fila                "Tipo de fila"

    label variable tot_pob_alcantarillado ///
        "Cobertura alcantarillado total"

    label variable urb_pob_alcantarillado ///
        "Cobertura alcantarillado urbana"

    label variable rur_pob_alcantarillado ///
        "Cobertura alcantarillado rural"

    format tot_pob_alcantarillado ///
           urb_pob_alcantarillado ///
           rur_pob_alcantarillado %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
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

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio             "Código DANE"
    label variable nvl_label            "Municipio"
    label variable subregion            "Subregión"
    label variable provincia            "Provincia"
    label variable tipo_fila            "Tipo de fila"

    label variable tot_pob_acueducto ///
        "Cobertura acueducto total"

    label variable urb_pob_acueducto ///
        "Cobertura acueducto urbana"

    label variable rur_pob_acueducto ///
        "Cobertura acueducto rural"

    format tot_pob_acueducto ///
           urb_pob_acueducto ///
           rur_pob_acueducto %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
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

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_recoleccion_basuras ///
        "Cobertura recolección de basuras total"

    label variable urb_pob_recoleccion_basuras ///
        "Cobertura recolección de basuras urbana"

    label variable rur_pob_recoleccion_basuras ///
        "Cobertura recolección de basuras rural"

    format tot_pob_recoleccion_basuras ///
           urb_pob_recoleccion_basuras ///
           rur_pob_recoleccion_basuras %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
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

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_internet ///
        "Cobertura internet total"

    label variable urb_pob_internet ///
        "Cobertura internet urbana"

    label variable rur_pob_internet ///
        "Cobertura internet rural"

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

    tempfile base promedio subregiones
    save `base'

    *----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
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

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable tot_pob_gas_natural ///
        "Cobertura gas natural total"

    label variable urb_pob_gas_natural ///
        "Cobertura gas natural urbana"

    label variable rur_pob_gas_natural ///
        "Cobertura gas natural rural"

    format tot_pob_gas_natural ///
           urb_pob_gas_natural ///
           rur_pob_gas_natural %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_gas_natural ///
        urb_pob_gas_natural ///
        rur_pob_gas_natural ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("gas_natural") ///
        firstrow(varlabels) sheetreplace

restore






/********************************************************************
* 5.4 Turismo
********************************************************************/


