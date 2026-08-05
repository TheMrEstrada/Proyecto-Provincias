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
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo =="Total"
drop _merge

rename Total total_poblacion

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
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo =="Total"
drop _merge

rename Total total_poblacion

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
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo =="Total"
drop _merge

rename Total total_poblacion

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
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo =="Total"
drop _merge

rename Total total_poblacion

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
* Cifras víctimas del conflicto - tablas por hecho (fecha de corte: 31/05/2026)
* Incluye tasa por 100.000 habitantes (población total 2025)
*------------------------------------------------------------
import excel using "$rawdata/cifras_victimas_ruv.xlsx", clear firstrow sheet("RUV_hechos_municipios")

rename COD_MUN ind_mpio

* Merge con provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

foreach x in Homicidio Confinamiento Amenaza Secuestro ///
             "Sin informacion" Tortura {
    replace HECHO = "`x' (Conflicto)" if HECHO == "`x'"
}

*------------------------------------------------------------
* Población total 2025 (una sola vez, antes del loop de hechos)
*------------------------------------------------------------
preserve
    use "$data/poblacion_total_2025.dta", clear
    keep if area_geo == "Total"
    rename Total poblacion
    keep ind_mpio poblacion
    isid ind_mpio
    tempfile poblacion
    save `poblacion'
restore

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

        *----------------------------------*
        * Merge con población ANTES del collapse
        *----------------------------------*
        merge m:1 ind_mpio using `poblacion'
        * _merge==2: municipio con población pero sin fila reportada en el RUV
        * para este hecho -> se asume 0 víctimas (no ausencia de dato)
        * _merge==1 no debería darse si el merge con provincias ya filtró bien;
        * si aparece, revisar códigos DANE antes de continuar
        tab HECHO if _merge == 2
        foreach v of local vars {
            replace `v' = 0 if _merge == 2
        }
        * Si un municipio de la Provincia no tenía fila para este hecho, sus
        * variables de identificación (nvl_label, subregion, provincia) quedan
        * vacías tras el merge -> hay que traerlas de nuevo antes de seguir
        replace tipo_fila = "Municipio" if _merge == 2
        drop _merge

        gen tasa_ocurrencia_100k = (VICTIMAS_OCURRENCIA / poblacion) * 100000

        tempfile base promedio
        save `base'

        *----------------------------------*
        * Total / tasa provincial
        * Suma de víctimas y de población -> la tasa se recalcula
        * sobre la suma, NO es el promedio de las tasas municipales
        *----------------------------------*
        collapse (sum) `vars' poblacion (count) n_municipios = ind_mpio, ///
            by(id_provincia provincia)

        gen tasa_ocurrencia_100k = (VICTIMAS_OCURRENCIA / poblacion) * 100000

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
        label variable poblacion             "Población total 2025"
        label variable tasa_ocurrencia_100k  "Tasa víctimas ocurrencia x 100.000 hab."

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
            SUJETOS_ATENCION EVENTOS poblacion tasa_ocurrencia_100k ///
            using "$output/tablas_seguridad.xlsx", ///
            sheet("`sheet'") firstrow(varlabels) sheetreplace

    restore
}

*------------------------------------------------------------
* Hoja adicional: total de víctimas por ocurrencia (RUV, deduplicado)
* Fuente: pestaña "RUV_totales_municipios" -> columna REPORTE VICTIMAS
* Ya viene deduplicado por la UARIV, NO es una suma nuestra entre hechos
*------------------------------------------------------------
preserve

    import excel using "$rawdata/cifras_victimas_ruv.xlsx", clear firstrow sheet("RUV_totales_municipios")

    keep if NIVEL == "MUNICIPIO"
    rename COD_MUN ind_mpio

    merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
    keep if _merge == 3
    drop _merge

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION SUJETOS_ATENCION

    gen tipo_fila = "Municipio"

    *----------------------------------*
    * Merge con población (mismo tempfile `poblacion' ya creado arriba)
    *----------------------------------*
    merge m:1 ind_mpio using `poblacion'
    tab nvl_label if _merge != 3   // debería salir vacío para tus 13 municipios
    drop if _merge == 2
    drop _merge

    gen tasa_ocurrencia_100k = (VICTIMAS_OCURRENCIA / poblacion) * 100000

    tempfile base_total promedio_total
    save `base_total'

    *----------------------------------*
    * Total / tasa provincial (suma, no promedio de tasas)
    *----------------------------------*
    collapse (sum) VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION ///
        SUJETOS_ATENCION poblacion (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen tasa_ocurrencia_100k = (VICTIMAS_OCURRENCIA / poblacion) * 100000
    gen nvl_label = "TOTAL " + upper(provincia)
    gen tipo_fila = "Total provincia"
    gen ind_mpio = .
    gen subregion = "TOTAL PROVINCIA"
    save `promedio_total'

    use `base_total', clear
    append using `promedio_total'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Total provincia"
    sort id_provincia orden_fila nvl_label

    label variable ind_mpio               "Código DANE"
    label variable nvl_label              "Municipio"
    label variable subregion              "Subregión"
    label variable provincia              "Provincia"
    label variable tipo_fila              "Tipo de fila"
    label variable VICTIMAS_OCURRENCIA    "Total víctimas ocurrencia (deduplicado, RUV)"
    label variable VICTIMAS_DECLARACION   "Total víctimas declaración (deduplicado, RUV)"
    label variable VICTIMAS_UBICACION     "Total víctimas ubicación (deduplicado, RUV)"
    label variable SUJETOS_ATENCION       "Total sujetos de atención (deduplicado, RUV)"
    label variable poblacion              "Población total 2025"
    label variable tasa_ocurrencia_100k   "Tasa total víctimas ocurrencia x 100.000 hab."

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION SUJETOS_ATENCION ///
        poblacion tasa_ocurrencia_100k ///
        using "$output/tablas_seguridad.xlsx", ///
        sheet("total_victimas_municipio") firstrow(varlabels) sheetreplace

restore





/********************************************************************
* Paz - Solicitudes de restitución de tierras
********************************************************************/
import excel "$rawdata/Estadísticas_Solicitudes_Restitución_Discriminadas_Municipios_20260704.xlsx", firstrow clear
	
keep if DepartamentoDelPredio =="Antioquia"	
rename CodigoDANE ind_mpio

keep ind_mpio MunicipioDelPredio NumeroDeSolicitudes

merge 1:m ind_mpio using "$data/poblacion_total_2025.dta" //no está Sabaneta en la base
keep if area_geo =="Total"
rename Total poblacion
drop _merge

* Solicitudes de restitución de tierras por cada 1.000 habitantes
gen solicitudes_1000hab = NumeroDeSolicitudes / poblacion * 1000
drop if missing(solicitudes_1000hab) 

*--------------------------------------------------
* Merge con subregión
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

*--------------------------------------------------
* Merge con provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
drop if _merge==2
drop _merge

gen tipo_fila = "Municipio"

tempfile base prom_prov prom_subreg prom_depto
save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen ind_mpio = .
gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen subregion = "TOTAL PROVINCIA"

save `prom_prov'

*--------------------------------------------------
* Promedio subregional
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen ind_mpio = .
gen nvl_label = "PROMEDIO " + upper(subregion)
gen tipo_fila = "Promedio subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `prom_subreg'

*--------------------------------------------------
* Promedio departamental
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) NumeroDeSolicitudes solicitudes_1000hab ///
    (count) n_municipios = ind_mpio

gen ind_mpio = .
gen nvl_label = "PROMEDIO DEPARTAMENTAL"
gen tipo_fila = "Promedio departamento"
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `prom_depto'

*--------------------------------------------------
* Unir todo
*--------------------------------------------------
use `base', clear

append using `prom_prov'
append using `prom_subreg'
append using `prom_depto'

gen orden_fila = 1 if tipo_fila=="Municipio"
replace orden_fila = 2 if tipo_fila=="Promedio provincia"
replace orden_fila = 3 if tipo_fila=="Promedio subregión"
replace orden_fila = 4 if tipo_fila=="Promedio departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas
*--------------------------------------------------
label variable ind_mpio               "Código DANE"
label variable nvl_label              "Municipio"
label variable subregion              "Subregión"
label variable provincia              "Provincia"
label variable tipo_fila              "Tipo de fila"
label variable NumeroDeSolicitudes    "Número de solicitudes de restitución"
label variable solicitudes_1000hab    "Solicitudes de restitución por cada 1.000 habitantes"
label variable n_municipios           "Número de municipios"

format NumeroDeSolicitudes %12.0fc
format solicitudes_1000hab %12.2f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    NumeroDeSolicitudes solicitudes_1000hab n_municipios ///
    using "$output/tablas_seguridad.xlsx", ///
    sheet("restitucion_tierras") ///
    firstrow(varlabels) sheetreplace

	

/********************************************************************
* Desaparecidos
********************************************************************/

import excel "$rawdata/UBPD_desaparecidos_Antioquia.xlsx", ///
    firstrow clear sheet("Por Municipio") cellrange(A2)

drop A
rename CódDANE ind_mpio
rename Municipio nvl_label
destring ind_mpio, replace

drop if missing(PersonasDesaparecidas)

tempfile original
save `original'

*--------------------------------------------------
* Base municipal con subregión y provincia
*--------------------------------------------------
use `original', clear

* Conservar solo municipios
keep if !inlist(nvl_label, "TOTAL DEPARTAMENTO", "SIN INFORMACIÓN", "NO DETERMINADO")

* Merge con subregión
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

* Merge con provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
drop if _merge == 2
drop _merge

gen tipo_fila = "Municipio"

tempfile base total_prov total_subreg total_depto
save `base'

*--------------------------------------------------
* Total provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (sum) PersonasDesaparecidas ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen ind_mpio = .
gen Municipio = ""
gen nvl_label = "TOTAL " + upper(provincia)
gen tipo_fila = "Total provincia"
gen subregion = "TOTAL PROVINCIA"

save `total_prov'

*--------------------------------------------------
* Total subregional
*--------------------------------------------------
use `base', clear

collapse ///
    (sum) PersonasDesaparecidas ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen ind_mpio = .
gen Municipio = ""
gen nvl_label = "TOTAL " + upper(subregion)
gen tipo_fila = "Total subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `total_subreg'

*--------------------------------------------------
* Total departamento oficial
*--------------------------------------------------
use `original', clear

keep if nvl_label == "TOTAL DEPARTAMENTO"

gen tipo_fila = "Total departamento"
gen n_municipios = 125
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `total_depto'

*--------------------------------------------------
* Unir
*--------------------------------------------------
use `base', clear

append using `total_prov'
append using `total_subreg'
append using `total_depto'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas
*--------------------------------------------------
label variable ind_mpio              "Código DANE"
label variable nvl_label             "Municipio"
label variable subregion             "Subregión"
label variable provincia             "Provincia"
label variable tipo_fila             "Tipo de fila"
label variable PersonasDesaparecidas "Personas desaparecidas"
label variable n_municipios          "Número de municipios"

format PersonasDesaparecidas %12.0fc

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    PersonasDesaparecidas n_municipios ///
    using "$output/tablas_seguridad.xlsx", ///
    sheet("desaparecidos") firstrow(varlabels) sheetreplace