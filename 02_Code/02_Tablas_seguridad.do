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
* SEGURIDAD
********************************************************************/

*------------------------------------
* #Número de hurtos 2025
*------------------------------------

import excel "$data/seguridad_policia.xlsx", sheet("hurtos_personas_2025") clear firstrow

*merge población total
merge 1:m ind_mpio using "$data/poblacion_total.dta"
keep if ÁREAGEOGRÁFICA =="Total"
drop _merge

rename TotalGeneral total_poblacion

*Tasa por cada 100 mil habitantes
gen tasa_hurtos_100k = (total_2025 / total_poblacion) * 100000
label var tasa_hurtos_100k "Hurtos por cada 100.000 habitantes"

keep ind_mpio tasa_hurtos_100k

*merge códigos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*TABLA 
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tasa_hurtos_100k

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) tasa_hurtos_100k ///
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
    label variable ind_mpio          "Código DANE"
    label variable nvl_label         "Municipio"
    label variable subregion         "Subregión"
    label variable provincia         "Provincia"
    label variable tipo_fila         "Tipo de fila"
    label variable tasa_hurtos_100k  "Hurtos por cada 100.000 habitantes"

    format tasa_hurtos_100k %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tasa_hurtos_100k ///
        using "$output/tablas_seguridad.xlsx", ///
        sheet("hurtos_100k") ///
        firstrow(varlabels) sheetreplace

restore



*------------------------------------
* #Número de homicidios 2025
*------------------------------------

import excel "$data/seguridad_policia.xlsx", sheet("homicidios_2025") clear firstrow

*merge población total
merge 1:m ind_mpio using "$data/poblacion_total.dta"
keep if ÁREAGEOGRÁFICA == "Total"
drop _merge

rename TotalGeneral total_poblacion

*Tasa por cada 100 mil habitantes
gen tasa_homicidios_100k = (total_2025 / total_poblacion) * 100000
label var tasa_homicidios_100k "Homicidios por cada 100.000 habitantes"

keep ind_mpio tasa_homicidios_100k

*merge códigos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*TABLA 
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tasa_homicidios_100k

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) tasa_homicidios_100k ///
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
    label variable ind_mpio               "Código DANE"
    label variable nvl_label              "Municipio"
    label variable subregion              "Subregión"
    label variable provincia              "Provincia"
    label variable tipo_fila              "Tipo de fila"
    label variable tasa_homicidios_100k   "Homicidios por cada 100.000 habitantes"

    format tasa_homicidios_100k %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tasa_homicidios_100k ///
        using "$output/tablas_seguridad.xlsx", ///
        sheet("homicidios_100k") ///
        firstrow(varlabels) sheetreplace

restore



*------------------------------------
* #Violencia intrafamiliar 2025
*------------------------------------

import excel "$data/seguridad_policia.xlsx", sheet("violencia_intrafamiliar_2025") clear firstrow

*merge población total
merge 1:m ind_mpio using "$data/poblacion_total.dta"
keep if ÁREAGEOGRÁFICA == "Total"
drop _merge

rename TotalGeneral total_poblacion

*Tasa por cada 100 mil habitantes
gen tasa_violencia_intra_100k = (total_2025 / total_poblacion) * 100000
label var tasa_violencia_intra_100k "Violencia intrafamiliar por cada 100.000 habitantes"

keep ind_mpio tasa_violencia_intra_100k

*merge códigos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*TABLA 
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tasa_violencia_intra_100k

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) tasa_violencia_intra_100k ///
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
    label variable ind_mpio                         "Código DANE"
    label variable nvl_label                        "Municipio"
    label variable subregion                        "Subregión"
    label variable provincia                        "Provincia"
    label variable tipo_fila                        "Tipo de fila"
    label variable tasa_violencia_intra_100k "Violencia intrafamiliar por cada 100.000 habitantes"

    format tasa_violencia_intra_100k %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tasa_violencia_intra_100k ///
        using "$output/tablas_seguridad.xlsx", ///
        sheet("violencia_intrafamiliar_100k") ///
        firstrow(varlabels) sheetreplace

restore



*------------------------------------
* #Delitos sexuales 2025
*------------------------------------

import excel "$data/seguridad_policia.xlsx", sheet("delitos_sexuales_2025") clear firstrow

*merge población total
merge 1:m ind_mpio using "$data/poblacion_total.dta"
keep if ÁREAGEOGRÁFICA == "Total"
drop _merge

rename TotalGeneral total_poblacion

*Tasa por cada 100 mil habitantes
gen tasa_delitos_sexuales_100k = (total_2025 / total_poblacion) * 100000
label var tasa_delitos_sexuales_100k "Delitos sexuales por cada 100.000 habitantes"

keep ind_mpio tasa_delitos_sexuales_100k

*merge códigos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*TABLA 
preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tasa_delitos_sexuales_100k

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    use `base', clear

    collapse ///
        (mean) tasa_delitos_sexuales_100k ///
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

    label variable ind_mpio                    "Código DANE"
    label variable nvl_label                   "Municipio"
    label variable subregion                   "Subregión"
    label variable provincia                   "Provincia"
    label variable tipo_fila                   "Tipo de fila"
    label variable tasa_delitos_sexuales_100k  "Delitos sexuales por cada 100.000 habitantes"

    format tasa_delitos_sexuales_100k %6.1f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tasa_delitos_sexuales_100k ///
        using "$output/tablas_seguridad.xlsx", ///
        sheet("delitos_sexuales_100k") ///
        firstrow(varlabels) sheetreplace

restore



*------------------------------------------------------------
* Cifras víctimas del conflicto - tablas por hecho (fecha de corte: 30/04/2026)
*------------------------------------------------------------
import excel using "$rawdata/cifras_victimas.xlsx", clear firstrow

rename COD_MUN ind_mpio

* Merge con provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

foreach x in Homicidio Confinamiento Amenaza Secuestro ///
             "Sin informacion" Tortura {

    replace HECHO = "`x' (Conflicto)" if HECHO == "`x'"
}

* Variables de interés
local vars VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION ///
           SUJETOS_ATENCION EVENTOS

* Lista de hechos
levelsof HECHO, local(hechos)

foreach h of local hechos {

    preserve

        keep if HECHO == "`h'"

        keep ind_mpio nvl_label subregion id_provincia provincia HECHO `vars'

        gen tipo_fila = "Municipio"

        tempfile base promedio
        save `base'

        *----------------------------------*
        * Total / promedio provincial
        * En este caso uso SUMA porque son conteos de víctimas/eventos
        *----------------------------------*
        collapse ///
            (sum) `vars' ///
            (count) n_municipios = ind_mpio, ///
            by(id_provincia provincia)

        gen nvl_label = "TOTAL " + upper(provincia)
        gen tipo_fila = "Total provincia"
        gen ind_mpio = .
        gen subregion = "TOTAL PROVINCIA"
        gen HECHO = "`h'"

        save `promedio'

        *----------------------------------*
        * Unir municipios + total provincia
        *----------------------------------*
        use `base', clear
        append using `promedio'

        gen orden_fila = 1 if tipo_fila == "Municipio"
        replace orden_fila = 2 if tipo_fila == "Total provincia"

        sort id_provincia orden_fila nvl_label

        * Labels
        label variable ind_mpio              "Código DANE"
        label variable nvl_label             "Municipio"
        label variable subregion             "Subregión"
        label variable provincia             "Provincia"
        label variable HECHO                 "Hecho victimizante"
        label variable tipo_fila             "Tipo de fila"
        label variable VICTIMAS_OCURRENCIA   "Víctimas ocurrencia"
        label variable VICTIMAS_DECLARACION  "Víctimas declaración"
        label variable VICTIMAS_UBICACION    "Víctimas ubicación"
        label variable SUJETOS_ATENCION      "Sujetos de atención"
        label variable EVENTOS               "Eventos"

        * Nombre corto y limpio para la hoja
        local sheet = lower("`h'")
        local sheet = subinstr("`sheet'", " ", "_", .)
        local sheet = subinstr("`sheet'", "/", "_", .)
        local sheet = subinstr("`sheet'", ",", "", .)
        local sheet = subinstr("`sheet'", ".", "", .)
        local sheet = substr("`sheet'", 1, 31)

        export excel ///
            ind_mpio nvl_label subregion provincia tipo_fila HECHO ///
            VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION ///
            SUJETOS_ATENCION EVENTOS ///
            using "$output/tablas_seguridad.xlsx", ///
            sheet("`sheet'") firstrow(varlabels) sheetreplace

    restore
}


