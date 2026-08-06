* ----------------------------------------------------------------------------
* PROVINCIAS - 10_Seguridad.do
* SECCION 10: SEGURIDAD
* FIGURAS: Cultivos ilícitos, EVOA, Delitos alto impacto (hurtos,
*          homicidios, violencia intrafamiliar, delitos sexuales),
*          Hechos victimizantes, SRTDAF, Tierras despojadas (tasa)
* INPUTS: $data/CULTILICITOS_PROVINCIAS.xlsx, EVOA_PROVINCIAS.xlsx,
*         seguridad_policia.xlsx, SRDAFT_PROVINCIAS.xlsx,
*         poblacion_total_2025.dta,
*         $rawdata/cifras_victimas_ruv.xlsx (hechos victimizantes, RUV original)
*         [ya NO usa HECHOSVICTIM_PROVINCIAS.xlsx]
* OUTPUTS: $out_10 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


* Un solo archivo por seccion: borrar una vez antes de escribir las hojas
capture erase "$out_10/seguridad.xlsx"

/********************************************************************
* 10.1 Cultivos ilícitos (coca)
*     El archivo trae solo municipios con coca (+ columnas vacías).
*     Robusto a provincias sin registros (fila total = 0).
*     Proporciones: (A) coca del municipio sobre el área total del
*     municipio; (B) coca del municipio sobre el total de coca del
*     departamento.
********************************************************************/

* --- Área municipal (km²) para la densidad ---
* Fuente: AREA_ORIGINAL.xlsx (00_Inputs); provincia por merge con códigos.
import excel "$rawdata/AREA_ORIGINAL.xlsx", sheet("Area") firstrow clear
rename COD_MPIO ind_mpio
destring ind_mpio AREAKM2, replace force
rename AREAKM2 area_km2
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
quietly summarize area_km2
local tot_area_prov = r(sum)
keep ind_mpio area_km2
rename ind_mpio CODMPIO
tempfile areas
save `areas'

* --- Coca ---
import excel "$data/CULTILICITOS_PROVINCIAS.xlsx", sheet("Coca") firstrow clear

* Eliminar columnas totalmente vacías (el Excel trae columnas basura)
foreach v of varlist * {
    quietly count if missing(`v')
    if r(N) == _N drop `v'
}

* La única columna no-llave es hectáreas de coca (encabezado "2023")
ds CODMPIO MUNICIPIO CODDEPTO DEPARTAMENTO subreg prov, not
rename `r(varlist)' coca_ha
destring CODMPIO coca_ha, replace force

* Total departamental de coca (todas las filas, antes de filtrar)
quietly summarize coca_ha
local tot_dep = r(sum)

keep if prov == "$provincia_nombre"
merge m:1 CODMPIO using `areas', keep(master match) nogen

preserve

    if _N > 0 {
        keep CODMPIO MUNICIPIO subreg prov coca_ha area_km2
        gen tipo_fila = "Municipio"

        tempfile base total
        save `base'

        collapse (sum) coca_ha (count) n_municipios = CODMPIO, by(prov)
        gen MUNICIPIO = "TOTAL PROVINCIA $provincia_label"
        gen tipo_fila = "Total provincia"
        gen CODMPIO   = .
        gen subreg    = ""
        gen area_km2  = `tot_area_prov'
        save `total'

        use `base', clear
        append using `total'

        gen orden_fila = 1 if tipo_fila == "Municipio"
        replace orden_fila = 2 if tipo_fila == "Total provincia"
        sort orden_fila MUNICIPIO
    }
    else {
        * Provincia sin registros de coca: fila única de total = 0
        clear
        set obs 1
        gen CODMPIO    = .
        gen MUNICIPIO  = "TOTAL PROVINCIA $provincia_label"
        gen subreg     = ""
        gen prov       = "$provincia_nombre"
        gen coca_ha    = 0
        gen area_km2   = `tot_area_prov'
        gen tipo_fila  = "Total provincia"
        gen orden_fila = 2
    }

    * (A) coca sobre el área total del municipio; (B) coca sobre el total de coca departamental
    gen pct_coca_area_mun           = coca_ha / (area_km2 * 100)
    gen participacion_coca_dept_pct = coca_ha / `tot_dep'

    label variable CODMPIO                     "Código DANE"
    label variable MUNICIPIO                   "Municipio"
    label variable subreg                      "Subregión"
    label variable prov                        "Provincia"
    label variable coca_ha                     "Hectáreas de coca (2023)"
    label variable pct_coca_area_mun           "Coca sobre área del municipio (%)"
    label variable participacion_coca_dept_pct "Coca sobre el total departamental de coca (%)"

    format coca_ha %12.2f
    format pct_coca_area_mun participacion_coca_dept_pct %6.2f


    export excel ///
        CODMPIO MUNICIPIO subreg prov coca_ha ///
        pct_coca_area_mun participacion_coca_dept_pct ///
        using "$out_10/seguridad.xlsx", ///
        sheet("coca") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 10.2 EVOA - Explotación de Oro de Aluvión
*     Encabezados largos -> renombrar las 4 columnas de hectáreas por posición.
*     Detalle por municipio + totales por año de provincia, subregión
*     dominante y departamento. Robusto a provincias sin EVOA.
********************************************************************/

* --- Subregión dominante de la provincia (la más frecuente) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Importar EVOA y estandarizar ---
import excel "$data/EVOA_PROVINCIAS.xlsx", sheet("EVOA") firstrow clear

capture rename Provincia prov_evoa
capture rename codigomunicipio cod_mun
destring cod_mun, replace force

* Las 4 columnas de hectáreas tienen encabezados largos -> renombrar por posición
ds cod_mun Municipio Subregión prov_evoa Año, not
local c1 : word 1 of `r(varlist)'
local c2 : word 2 of `r(varlist)'
local c3 : word 3 of `r(varlist)'
local c4 : word 4 of `r(varlist)'
rename `c1' ha_permisos
rename `c2' ha_transito
rename `c3' ha_ilicita
rename `c4' total_evoa
destring ha_permisos ha_transito ha_ilicita total_evoa, replace force

* --- Detalle: municipios de la provincia ---
tempfile filas
preserve
    keep if prov_evoa == "$provincia_nombre"
    keep cod_mun Municipio Subregión prov_evoa Año ///
         ha_permisos ha_transito ha_ilicita total_evoa
    gen tipo_fila  = "Municipio"
    gen orden_fila = 1
    save `filas'
restore

* --- Total provincial por año (guard si la provincia no tiene EVOA) ---
preserve
    keep if prov_evoa == "$provincia_nombre"
    if _N > 0 {
        collapse (sum) ha_permisos ha_transito ha_ilicita total_evoa, by(Año)
    }
    else {
        keep Año ha_permisos ha_transito ha_ilicita total_evoa
        set obs 1
        replace Año         = .
        replace ha_permisos = 0
        replace ha_transito = 0
        replace ha_ilicita  = 0
        replace total_evoa  = 0
    }
    gen cod_mun    = .
    gen Municipio  = "TOTAL PROVINCIA $provincia_label"
    gen Subregión  = ""
    gen prov_evoa  = "$provincia_nombre"
    gen tipo_fila  = "Total provincia"
    gen orden_fila = 2
    append using `filas'
    save `filas', replace
restore

* --- Total de la subregión dominante por año ---
preserve
    keep if Subregión == "`dom_subreg'"
    if _N > 0 {
        collapse (sum) ha_permisos ha_transito ha_ilicita total_evoa, by(Año)
    }
    else {
        keep Año ha_permisos ha_transito ha_ilicita total_evoa
        set obs 1
        replace Año         = .
        replace ha_permisos = 0
        replace ha_transito = 0
        replace ha_ilicita  = 0
        replace total_evoa  = 0
    }
    gen cod_mun    = .
    gen Municipio  = "TOTAL SUBREGIÓN `dom_subreg'"
    gen Subregión  = "`dom_subreg'"
    gen prov_evoa  = ""
    gen tipo_fila  = "Total subregión"
    gen orden_fila = 3
    append using `filas'
    save `filas', replace
restore

* --- Total departamental por año ---
preserve
    collapse (sum) ha_permisos ha_transito ha_ilicita total_evoa, by(Año)
    gen cod_mun    = .
    gen Municipio  = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen Subregión  = ""
    gen prov_evoa  = "DEPARTAMENTO DE ANTIOQUIA"
    gen tipo_fila  = "Total departamento"
    gen orden_fila = 4
    append using `filas'
    save `filas', replace
restore

use `filas', clear
sort orden_fila Año Municipio

label variable cod_mun      "Código DANE"
label variable Municipio    "Municipio"
label variable Subregión    "Subregión"
label variable prov_evoa    "Provincia"
label variable Año          "Año"
label variable ha_permisos  "Hectáreas con permisos"
label variable ha_transito  "Hectáreas en tránsito"
label variable ha_ilicita   "Hectáreas ilícita"
label variable total_evoa   "Total EVOA (ha)"

format ha_permisos ha_transito ha_ilicita total_evoa %12.2f


export excel ///
    cod_mun Municipio Subregión prov_evoa Año ///
    ha_permisos ha_transito ha_ilicita total_evoa ///
    using "$out_10/seguridad.xlsx", ///
    sheet("evoa") firstrow(varlabels) sheetreplace


/********************************************************************
* 10.3 Delitos de alto impacto (tasas por 100.000 hab)
*     Una sola hoja con las 4 tasas (hurtos, homicidios, violencia
*     intrafamiliar, delitos sexuales). Filas de agregado con TASA
*     AGREGADA (total de delitos / población x 100.000) para provincia,
*     subregión dominante y departamento.
********************************************************************/

* --- Subregión dominante de la provincia (la más frecuente) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Conteos por municipio (4 fuentes) ---
tempfile seg
import excel "$data/seguridad_policia.xlsx", sheet("hurtos_personas_2025") firstrow clear
keep ind_mpio total_2025
rename total_2025 n_hurtos
save `seg'

import excel "$data/seguridad_policia.xlsx", sheet("homicidios_2025") firstrow clear
keep ind_mpio total_2025
rename total_2025 n_homicidios
merge 1:1 ind_mpio using `seg', nogen
save `seg', replace

import excel "$data/seguridad_policia.xlsx", sheet("violencia_intrafamiliar_2025") firstrow clear
keep ind_mpio total_2025
rename total_2025 n_violencia
merge 1:1 ind_mpio using `seg', nogen
save `seg', replace

import excel "$data/seguridad_policia.xlsx", sheet("delitos_sexuales_2025") firstrow clear
keep ind_mpio total_2025
rename total_2025 n_sexuales
merge 1:1 ind_mpio using `seg', nogen

* --- Población (2025, área Total) ---
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if _merge == 3 & area_geo == "Total"
drop _merge
rename Total pob

* --- Provincia / subregión / municipio (códigos) ---
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión COMPLETA (crosswalk 125) para el agregado de subregión dominante
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen

* --- Detalle: tasas por municipio de la provincia ---
tempfile filas
preserve
    keep if id_provincia == $id_provincia
    gen hurtos           = n_hurtos     / pob * 100000
    gen homicidios       = n_homicidios / pob * 100000
    gen violencia_intrafamiliar  = n_violencia  / pob * 100000
    gen delitos_sexuales = n_sexuales   / pob * 100000
    keep ind_mpio nvl_label subregion ///
         hurtos homicidios violencia_intrafamiliar delitos_sexuales
    gen tipo_fila  = "Municipio"
    gen orden_fila = 1
    save `filas'
restore

* --- Agregados: tasa agregada = (suma delitos / suma población) x 100000 ---
* Provincia
preserve
    keep if id_provincia == $id_provincia
    collapse (sum) n_hurtos n_homicidios n_violencia n_sexuales pob
    gen hurtos           = n_hurtos     / pob * 100000
    gen homicidios       = n_homicidios / pob * 100000
    gen violencia_intrafamiliar  = n_violencia  / pob * 100000
    gen delitos_sexuales = n_sexuales   / pob * 100000
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL PROVINCIA $provincia_label"
    gen subregion  = ""
    gen tipo_fila  = "Total provincia"
    gen orden_fila = 2
    keep ind_mpio nvl_label subregion hurtos homicidios violencia_intrafamiliar delitos_sexuales tipo_fila orden_fila
    append using `filas'
    save `filas', replace
restore

* Subregión dominante
preserve
    keep if subregion == "`dom_subreg'"
    collapse (sum) n_hurtos n_homicidios n_violencia n_sexuales pob
    gen hurtos           = n_hurtos     / pob * 100000
    gen homicidios       = n_homicidios / pob * 100000
    gen violencia_intrafamiliar  = n_violencia  / pob * 100000
    gen delitos_sexuales = n_sexuales   / pob * 100000
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion  = "`dom_subreg'"
    gen tipo_fila  = "Total subregión"
    gen orden_fila = 3
    keep ind_mpio nvl_label subregion hurtos homicidios violencia_intrafamiliar delitos_sexuales tipo_fila orden_fila
    append using `filas'
    save `filas', replace
restore

* Departamento
preserve
    collapse (sum) n_hurtos n_homicidios n_violencia n_sexuales pob
    gen hurtos           = n_hurtos     / pob * 100000
    gen homicidios       = n_homicidios / pob * 100000
    gen violencia_intrafamiliar  = n_violencia  / pob * 100000
    gen delitos_sexuales = n_sexuales   / pob * 100000
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subregion  = ""
    gen tipo_fila  = "Total departamento"
    gen orden_fila = 4
    keep ind_mpio nvl_label subregion hurtos homicidios violencia_intrafamiliar delitos_sexuales tipo_fila orden_fila
    append using `filas'
    save `filas', replace
restore

use `filas', clear
sort orden_fila nvl_label

label variable ind_mpio                   "Código DANE"
label variable nvl_label                  "Municipio"
label variable subregion                  "Subregión"
label variable hurtos           "Hurtos por 100.000 hab."
label variable homicidios       "Homicidios por 100.000 hab."
label variable violencia_intrafamiliar  "Violencia intrafamiliar por 100.000 hab."
label variable delitos_sexuales "Delitos sexuales por 100.000 hab."

format hurtos homicidios violencia_intrafamiliar delitos_sexuales %8.1f


export excel ///
    ind_mpio nvl_label subregion ///
    hurtos homicidios violencia_intrafamiliar delitos_sexuales ///
    using "$out_10/seguridad.xlsx", ///
    sheet("delitos") firstrow(varlabels) sheetreplace


/********************************************************************
* 10.4 Hechos victimizantes (conflicto armado) -> 2 hojas
*     FUENTE ORIGINAL: cifras_victimas_ruv.xlsx (RUV), NO el derivado
*     HECHOSVICTIM_PROVINCIAS (que solo trae 88 munis y suma sobre
*     hechos, doble-contando víctimas). El RUV original trae los 125
*     municipios y totales deduplicados por municipio.
*
*     total_victimas: total deduplicado por municipio (hoja
*        "RUV_totales_municipios") + agregados de provincia, subregión
*        dominante y departamento.
*        - municipios: total deduplicado (REPORTE VICTIMAS).
*        - provincia y subregión: Σ de los totales municipales
*          deduplicados. APROXIMACIÓN: sobrestima levemente el nivel,
*          porque una víctima registrada en >1 municipio se cuenta más
*          de una vez; no existe dedup oficial por provincia/subregión.
*        - departamento: fila OFICIAL deduplicada "TOTAL DEPARTAMENTO".
*        La fuente RUV_totales_municipios NO trae "Eventos"; esta hoja
*        no incluye esa columna.
*     proporcion_hechos: proporción (%) de cada hecho en la provincia
*        sobre el total de "Víctimas por ocurrencia" (hoja
*        "RUV_hechos_municipios", desagregada por hecho).
********************************************************************/

* --- Subregión dominante de la provincia (la más frecuente) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

*==================================================================
* Hoja 1: total_victimas (deduplicado por municipio + agregados)
*==================================================================
import excel "$rawdata/cifras_victimas_ruv.xlsx", sheet("RUV_totales_municipios") firstrow clear
destring COD_MUN VICTIMAS_OCURRENCIA VICTIMAS_DECLARACION VICTIMAS_UBICACION SUJETOS_ATENCION, replace force

* -- Fila oficial de departamento (guardar los 4 totales deduplicados) --
preserve
    keep if NIVEL == "DEPARTAMENTO"
    local dep_ocu = VICTIMAS_OCURRENCIA[1]
    local dep_dec = VICTIMAS_DECLARACION[1]
    local dep_ubi = VICTIMAS_UBICACION[1]
    local dep_suj = SUJETOS_ATENCION[1]
restore

keep if NIVEL == "MUNICIPIO"
rename COD_MUN            ind_mpio
rename VICTIMAS_OCURRENCIA  victimas_ocurrencia
rename VICTIMAS_DECLARACION victimas_declaracion
rename VICTIMAS_UBICACION   victimas_ubicacion
rename SUJETOS_ATENCION     sujetos_atencion

* Nombre de municipio + subregión COMPLETA (crosswalk 125) para el
* agregado de subregión dominante sobre TODA la subregión.
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(nvl_label subregion) keep(master match) nogen
* Provincia / id_provincia (solo los 88 munis PAP) para filtrar la provincia.
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", ///
    keepusing(provincia id_provincia) keep(master match) nogen

tempfile hvfilas

* -- Detalle: municipios de la provincia --
preserve
    keep if id_provincia == $id_provincia
    keep ind_mpio nvl_label subregion ///
         victimas_ocurrencia victimas_declaracion victimas_ubicacion sujetos_atencion
    gen tipo_fila  = "Municipio"
    gen orden_fila = 1
    save `hvfilas'
restore

* -- Provincia: Σ de totales municipales deduplicados --
preserve
    keep if id_provincia == $id_provincia
    collapse (sum) victimas_ocurrencia victimas_declaracion victimas_ubicacion sujetos_atencion
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL PROVINCIA $provincia_label"
    gen subregion  = ""
    gen tipo_fila  = "Total provincia"
    gen orden_fila = 2
    append using `hvfilas'
    save `hvfilas', replace
restore

* -- Subregión dominante (crosswalk 125): Σ de municipales deduplicados --
preserve
    keep if subregion == "`dom_subreg'"
    collapse (sum) victimas_ocurrencia victimas_declaracion victimas_ubicacion sujetos_atencion
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion  = "`dom_subreg'"
    gen tipo_fila  = "Total subregión"
    gen orden_fila = 3
    append using `hvfilas'
    save `hvfilas', replace
restore

* -- Departamento: fila OFICIAL deduplicada (no es la suma municipal) --
preserve
    clear
    set obs 1
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subregion  = ""
    gen victimas_ocurrencia  = `dep_ocu'
    gen victimas_declaracion = `dep_dec'
    gen victimas_ubicacion   = `dep_ubi'
    gen sujetos_atencion     = `dep_suj'
    gen tipo_fila  = "Total departamento"
    gen orden_fila = 4
    append using `hvfilas'
    save `hvfilas', replace
restore

use `hvfilas', clear
sort orden_fila nvl_label

label variable ind_mpio             "Código DANE"
label variable nvl_label            "Municipio"
label variable subregion            "Subregión"
label variable victimas_ocurrencia  "Víctimas por ocurrencia"
label variable victimas_declaracion "Víctimas por declaración"
label variable victimas_ubicacion   "Víctimas por ubicación"
label variable sujetos_atencion     "Sujetos de atención"

format victimas_ocurrencia victimas_declaracion victimas_ubicacion ///
    sujetos_atencion %12.0f

export excel ///
    ind_mpio nvl_label subregion ///
    victimas_ocurrencia victimas_declaracion victimas_ubicacion sujetos_atencion ///
    using "$out_10/seguridad.xlsx", ///
    sheet("total_victimas") firstrow(varlabels) sheetreplace

*==================================================================
* Hoja 2: proporcion_hechos (% por hecho, sobre víctimas por ocurrencia)
*   Fuente: RUV_hechos_municipios (desagregada por hecho). El total
*   por ocurrencia aquí suma sobre hechos (una víctima puede sufrir
*   varios hechos), que es el denominador correcto de la proporción.
*==================================================================
import excel "$rawdata/cifras_victimas_ruv.xlsx", sheet("RUV_hechos_municipios") firstrow clear
rename COD_MUN ind_mpio
destring ind_mpio VICTIMAS_OCURRENCIA, replace force
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", ///
    keepusing(id_provincia) keep(master match) nogen
keep if id_provincia == $id_provincia

rename HECHO hecho_victim
collapse (sum) victimas_ocurrencia = VICTIMAS_OCURRENCIA, by(hecho_victim)

quietly summarize victimas_ocurrencia
local tot_ocu = r(sum)
gen proporcion_pct = victimas_ocurrencia / `tot_ocu'

gsort -victimas_ocurrencia

* Fila de total provincial (100%)
local n = _N + 1
set obs `n'
replace hecho_victim        = "TOTAL PROVINCIA $provincia_label" in `n'
replace victimas_ocurrencia = `tot_ocu' in `n'
replace proporcion_pct      = 1 in `n'

label variable hecho_victim        "Hecho victimizante"
label variable victimas_ocurrencia "Víctimas por ocurrencia"
label variable proporcion_pct      "Proporción sobre el total (%)"

format proporcion_pct %6.2f

export excel ///
    hecho_victim victimas_ocurrencia proporcion_pct ///
    using "$out_10/seguridad.xlsx", ///
    sheet("proporcion_hechos") firstrow(varlabels) sheetreplace


/********************************************************************
* 10.5 SRTDAF - Solicitudes de Restitución de Tierras Despojadas
*              y Abandonadas Forzosamente
*     OJO: prov y subreg del archivo están corruptos (valor único);
*     provincia/subregión se obtienen por merge con códigos_provincias.dta.
*     Detalle por municipio + totales de provincia, subregión dominante
*     y departamento. Robusto a provincias/subregiones sin registros.
********************************************************************/

* --- Subregión dominante de la provincia (la más frecuente) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Importar SRTDAF y traer provincia/subregión por merge ---
import excel "$data/SRDAFT_PROVINCIAS.xlsx", sheet("SRTDAF") firstrow clear
rename CodigoDANE ind_mpio
destring ind_mpio NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares, replace force
capture drop prov subreg
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión COMPLETA (crosswalk 125) para el agregado de subregión dominante
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen

* --- Detalle: municipios de la provincia ---
tempfile filas
preserve
    keep if id_provincia == $id_provincia
    keep ind_mpio nvl_label subregion provincia ///
         NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
    gen tipo_fila  = "Municipio"
    gen orden_fila = 1
    save `filas'
restore

* --- Total provincial ---
preserve
    keep if id_provincia == $id_provincia
    if _N > 0 {
        collapse (sum) NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
    }
    else {
        keep NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
        set obs 1
        replace NumeroDeSolicitudes = 0
        replace NumeroDePredios     = 0
        replace NumeroDeTitulares   = 0
    }
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL PROVINCIA $provincia_label"
    gen subregion  = ""
    gen provincia  = "$provincia_nombre"
    gen tipo_fila  = "Total provincia"
    gen orden_fila = 2
    append using `filas'
    save `filas', replace
restore

* --- Total de la subregión dominante ---
preserve
    keep if subregion == "`dom_subreg'"
    if _N > 0 {
        collapse (sum) NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
    }
    else {
        keep NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
        set obs 1
        replace NumeroDeSolicitudes = 0
        replace NumeroDePredios     = 0
        replace NumeroDeTitulares   = 0
    }
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion  = "`dom_subreg'"
    gen provincia  = ""
    gen tipo_fila  = "Total subregión"
    gen orden_fila = 3
    append using `filas'
    save `filas', replace
restore

* --- Total departamental ---
preserve
    collapse (sum) NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subregion  = ""
    gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
    gen tipo_fila  = "Total departamento"
    gen orden_fila = 4
    append using `filas'
    save `filas', replace
restore

use `filas', clear
sort orden_fila nvl_label

label variable ind_mpio            "Código DANE"
label variable nvl_label           "Municipio"
label variable subregion           "Subregión"
label variable provincia           "Provincia"
label variable NumeroDeSolicitudes "Número de solicitudes"
label variable NumeroDePredios     "Número de predios"
label variable NumeroDeTitulares   "Número de titulares"


export excel ///
    ind_mpio nvl_label subregion provincia ///
    NumeroDeSolicitudes NumeroDePredios NumeroDeTitulares ///
    using "$out_10/seguridad.xlsx", ///
    sheet("srtdaf") firstrow(varlabels) sheetreplace


/********************************************************************
* 10.5.1 Tasa de solicitudes de restitución por 1.000 hab. (fig. 80)
*     Numerador: NumeroDeSolicitudes (conteo acumulado, sin año).
*     Denominador: población municipal 2025, área "Total"
*       (mismo insumo que delitos 10.3).
*     Municipio: tasa = solicitudes / población x 1.000
*     Agregados (provincia, subregión dominante, departamento):
*       TASA AGREGADA = (Σ solicitudes / Σ población) x 1.000
*     Se agrega como hoja "tasas" al mismo seguridad.xlsx, junto con la
*     hoja "srtdaf" de conteos (el archivo se borra una sola vez al inicio).
********************************************************************/

* --- Población municipal 2025 (área Total) ---
use "$data/poblacion_total_2025.dta", clear
keep if area_geo == "Total"
keep ind_mpio Total
rename Total pob
tempfile pob25
save `pob25'

* --- SRTDAF + provincia/subregión (merge) + población ---
import excel "$data/SRDAFT_PROVINCIAS.xlsx", sheet("SRTDAF") firstrow clear
rename CodigoDANE ind_mpio
destring ind_mpio NumeroDeSolicitudes, replace force
capture drop prov subreg
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión COMPLETA (crosswalk 125) para el agregado de subregión dominante
drop subregion
merge m:1 ind_mpio using "$rawdata/códigos_municipios_clean.dta", ///
    keepusing(subregion) keep(master match) nogen
merge m:1 ind_mpio using `pob25', keep(master match) nogen

tempfile tasas

* --- Detalle: municipios de la provincia ---
preserve
    keep if id_provincia == $id_provincia
    keep ind_mpio nvl_label subregion provincia NumeroDeSolicitudes pob
    gen tasa_solicitudes = cond(pob > 0, NumeroDeSolicitudes / pob * 1000, .)
    gen tipo_fila  = "Municipio"
    gen orden_fila = 1
    save `tasas'
restore

* --- Total provincial (tasa agregada) ---
preserve
    keep if id_provincia == $id_provincia
    if _N > 0 {
        collapse (sum) NumeroDeSolicitudes pob
    }
    else {
        keep NumeroDeSolicitudes pob
        set obs 1
        replace NumeroDeSolicitudes = 0
        replace pob = 0
    }
    gen tasa_solicitudes = cond(pob > 0, NumeroDeSolicitudes / pob * 1000, .)
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL PROVINCIA $provincia_label"
    gen subregion  = ""
    gen provincia  = "$provincia_nombre"
    gen tipo_fila  = "Total provincia"
    gen orden_fila = 2
    append using `tasas'
    save `tasas', replace
restore

* --- Total de la subregión dominante (tasa agregada) ---
preserve
    keep if subregion == "`dom_subreg'"
    if _N > 0 {
        collapse (sum) NumeroDeSolicitudes pob
    }
    else {
        keep NumeroDeSolicitudes pob
        set obs 1
        replace NumeroDeSolicitudes = 0
        replace pob = 0
    }
    gen tasa_solicitudes = cond(pob > 0, NumeroDeSolicitudes / pob * 1000, .)
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion  = "`dom_subreg'"
    gen provincia  = ""
    gen tipo_fila  = "Total subregión"
    gen orden_fila = 3
    append using `tasas'
    save `tasas', replace
restore

* --- Total departamental (tasa agregada) ---
preserve
    collapse (sum) NumeroDeSolicitudes pob
    gen tasa_solicitudes = cond(pob > 0, NumeroDeSolicitudes / pob * 1000, .)
    gen ind_mpio   = .
    gen nvl_label  = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subregion  = ""
    gen provincia  = "DEPARTAMENTO DE ANTIOQUIA"
    gen tipo_fila  = "Total departamento"
    gen orden_fila = 4
    append using `tasas'
    save `tasas', replace
restore

use `tasas', clear
sort orden_fila nvl_label

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable NumeroDeSolicitudes "Número de solicitudes"
label variable pob                "Población (2025)"
label variable tasa_solicitudes   "Tasa de solicitudes (por 1.000 hab.)"

format pob %12.0f
format tasa_solicitudes %6.2f

export excel ///
    ind_mpio nvl_label subregion provincia ///
    NumeroDeSolicitudes pob tasa_solicitudes ///
    using "$out_10/seguridad.xlsx", ///
    sheet("tasas") firstrow(varlabels) sheetreplace


/********************************************************************
* 10.6 Percepción de seguridad (encuesta ciudadana)
*     Fuente: $data/percepcion_seguridad.dta (DERIVADO liviano generado por
*       00_Homogeneizacion_Inputs/percepcion_seguridad.do a partir del
*       microdato crudo "Data anonimizada encuesta percepcion 2018-2025.xlsx").
*       El derivado ya trae solo las 8 columnas necesarias, para TODAS las
*       subregiones; el import lento del archivo grande (1363 columnas) ocurre
*       una sola vez en la homogenización, no aquí.
*     Representativa a nivel de SUBREGIÓN -> unidad de análisis = subregión
*     dominante de la provincia del flujo.
*     4 hojas (P1A, P2, P4A, P6): proporción PONDERADA (FACTOR_PONDERACION) de
*     cada categoría por periodo (año; las dos olas de 2019 separadas).
********************************************************************/

* --- Subregión dominante de la provincia -> código B_SUBREGION (1-9) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

local subcode = .
if "`dom_subreg'" == "BAJO CAUCA"      local subcode = 1
if "`dom_subreg'" == "MAGDALENA MEDIO" local subcode = 2
if "`dom_subreg'" == "NORDESTE"        local subcode = 3
if "`dom_subreg'" == "NORTE"           local subcode = 4
if "`dom_subreg'" == "OCCIDENTE"       local subcode = 5
if "`dom_subreg'" == "ORIENTE"         local subcode = 6
if "`dom_subreg'" == "SUROESTE"        local subcode = 7
if "`dom_subreg'" == "URABA"           local subcode = 8
if "`dom_subreg'" == "VALLE DE ABURRA" local subcode = 9

* --- Cargar el derivado liviano (ya reducido a 8 columnas) ---
use "$data/percepcion_seguridad.dta", clear

keep if B_SUBREGION == `subcode'

* --- Periodo = año + orden de ola dentro del año ---
gen fecha = date(FECHAINI, "DMY")
gen anio  = year(fecha)

preserve
    collapse (min) fecha (firstnm) anio, by(ESTUDIO)
    bysort anio (fecha): gen ola   = _n
    bysort anio:         gen n_ola = _N
    gen periodo = string(anio) + cond(n_ola > 1, " (" + string(ola) + ")", "")
    keep ESTUDIO periodo anio fecha
    tempfile per
    save `per'
restore
merge m:1 ESTUDIO using `per', nogen


*------------------------------------
* P1A - En general, en su barrio o vereda usted se siente
*------------------------------------
preserve
    keep if inlist(P1A, 1, 2, 3, 4)
    bysort periodo: egen n_resp = count(P1A)
    collapse (sum) w = FACTOR_PONDERACION (first) anio n_resp, by(periodo P1A)
    bysort periodo: egen tot = total(w)
    gen prop = w / tot
    keep periodo anio n_resp P1A prop
    reshape wide prop, i(periodo anio n_resp) j(P1A)
    foreach c in 1 2 3 4 {
        capture confirm variable prop`c'
        if _rc gen prop`c' = 0
        replace prop`c' = 0 if missing(prop`c')
    }
    rename prop1 muy_seguro
    rename prop2 seguro
    rename prop3 inseguro
    rename prop4 muy_inseguro
    gen subregion = "`dom_subreg'"
    sort anio periodo
    label variable subregion    "Subregión"
    label variable periodo      "Periodo"
    label variable n_resp       "N respuestas"
    label variable muy_seguro   "Muy seguro (%)"
    label variable seguro       "Seguro (%)"
    label variable inseguro     "Inseguro (%)"
    label variable muy_inseguro "Muy inseguro (%)"
    format muy_seguro seguro inseguro muy_inseguro %6.2f
    export excel subregion periodo n_resp muy_seguro seguro inseguro muy_inseguro ///
        using "$out_10/seguridad.xlsx", ///
        sheet("P1A_barrio") firstrow(varlabels) sheetreplace
restore

*------------------------------------
* P2 - Con relación a hace un año (barrio o vereda)
*------------------------------------
preserve
    keep if inlist(P2, 1, 2, 3, 999)
    bysort periodo: egen n_resp = count(P2)
    collapse (sum) w = FACTOR_PONDERACION (first) anio n_resp, by(periodo P2)
    bysort periodo: egen tot = total(w)
    gen prop = w / tot
    keep periodo anio n_resp P2 prop
    reshape wide prop, i(periodo anio n_resp) j(P2)
    foreach c in 1 2 3 999 {
        capture confirm variable prop`c'
        if _rc gen prop`c' = 0
        replace prop`c' = 0 if missing(prop`c')
    }
    rename prop1   mas_seguro
    rename prop2   menos_seguro
    rename prop3   igual
    rename prop999 ns_nr
    gen subregion = "`dom_subreg'"
    sort anio periodo
    label variable subregion    "Subregión"
    label variable periodo      "Periodo"
    label variable n_resp       "N respuestas"
    label variable mas_seguro   "Más seguro (%)"
    label variable menos_seguro "Menos seguro (%)"
    label variable igual        "Igual (%)"
    label variable ns_nr        "No sabe/No responde (%)"
    format mas_seguro menos_seguro igual ns_nr %6.2f
    export excel subregion periodo n_resp mas_seguro menos_seguro igual ns_nr ///
        using "$out_10/seguridad.xlsx", ///
        sheet("P2_cambio_barrio") firstrow(varlabels) sheetreplace
restore

*------------------------------------
* P4A - En general, en este municipio usted se siente
*------------------------------------
preserve
    keep if inlist(P4A, 1, 2, 3, 4)
    bysort periodo: egen n_resp = count(P4A)
    collapse (sum) w = FACTOR_PONDERACION (first) anio n_resp, by(periodo P4A)
    bysort periodo: egen tot = total(w)
    gen prop = w / tot
    keep periodo anio n_resp P4A prop
    reshape wide prop, i(periodo anio n_resp) j(P4A)
    foreach c in 1 2 3 4 {
        capture confirm variable prop`c'
        if _rc gen prop`c' = 0
        replace prop`c' = 0 if missing(prop`c')
    }
    rename prop1 muy_seguro
    rename prop2 seguro
    rename prop3 inseguro
    rename prop4 muy_inseguro
    gen subregion = "`dom_subreg'"
    sort anio periodo
    label variable subregion    "Subregión"
    label variable periodo      "Periodo"
    label variable n_resp       "N respuestas"
    label variable muy_seguro   "Muy seguro (%)"
    label variable seguro       "Seguro (%)"
    label variable inseguro     "Inseguro (%)"
    label variable muy_inseguro "Muy inseguro (%)"
    format muy_seguro seguro inseguro muy_inseguro %6.2f
    export excel subregion periodo n_resp muy_seguro seguro inseguro muy_inseguro ///
        using "$out_10/seguridad.xlsx", ///
        sheet("P4A_municipio") firstrow(varlabels) sheetreplace
restore

*------------------------------------
* P6 - Con relación a hace un año (municipio)
*------------------------------------
preserve
    keep if inlist(P6, 1, 2, 3, 999)
    bysort periodo: egen n_resp = count(P6)
    collapse (sum) w = FACTOR_PONDERACION (first) anio n_resp, by(periodo P6)
    bysort periodo: egen tot = total(w)
    gen prop = w / tot
    keep periodo anio n_resp P6 prop
    reshape wide prop, i(periodo anio n_resp) j(P6)
    foreach c in 1 2 3 999 {
        capture confirm variable prop`c'
        if _rc gen prop`c' = 0
        replace prop`c' = 0 if missing(prop`c')
    }
    rename prop1   mas_seguro
    rename prop2   menos_seguro
    rename prop3   igual
    rename prop999 ns_nr
    gen subregion = "`dom_subreg'"
    sort anio periodo
    label variable subregion    "Subregión"
    label variable periodo      "Periodo"
    label variable n_resp       "N respuestas"
    label variable mas_seguro   "Más seguro (%)"
    label variable menos_seguro "Menos seguro (%)"
    label variable igual        "Igual (%)"
    label variable ns_nr        "No sabe/No responde (%)"
    format mas_seguro menos_seguro igual ns_nr %6.2f
    export excel subregion periodo n_resp mas_seguro menos_seguro igual ns_nr ///
        using "$out_10/seguridad.xlsx", ///
        sheet("P6_cambio_municipio") firstrow(varlabels) sheetreplace
restore


/********************************************************************
* 10.7 Índice de Riesgo de Victimización (IRV) - 2025 (fig. 85)
*     Fuente: IRV-2025.xlsx (00_Inputs, UARIV).
*     Dos variables: irv (Estimado, índice 0-1) y categoria_riesgo (Cluster).
*     Detalle por municipio de la provincia. Sin fila de agregado: el índice
*     no se promedia de forma estándar y la categoría es cualitativa.
********************************************************************/

import excel "$rawdata/IRV-2025.xlsx", sheet("Datos") firstrow clear

* 'Código Municipio' es la col. 7 -> se renombra por posición (evita el acento)
ds
local codmun : word 7 of `r(varlist)'
rename `codmun' ind_mpio
destring ind_mpio, replace force

rename Estimado irv
destring irv, replace force
rename Cluster categoria_riesgo

* Provincia / subregión por merge con códigos
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

keep ind_mpio nvl_label subregion provincia irv categoria_riesgo
sort nvl_label

label variable ind_mpio         "Código DANE"
label variable nvl_label        "Municipio"
label variable subregion        "Subregión"
label variable provincia        "Provincia"
label variable irv              "Índice de Riesgo de Victimización"
label variable categoria_riesgo "Categoría de riesgo"

format irv %6.4f


export excel ///
    ind_mpio nvl_label subregion provincia irv categoria_riesgo ///
    using "$out_10/seguridad.xlsx", ///
    sheet("irv") firstrow(varlabels) sheetreplace




/********************************************************************
* 10.2 Paz — Personas dadas por desaparecidas (UBPD)
*   Figura: "Proporción de personas dadas por desaparecidas dentro de la
*     Provincia por municipio."
*   Fuente: $rawdata/UBPD_desaparecidos_Antioquia.xlsx (hoja "Por Municipio").
*   Reutiliza la lógica de 02_Code/02_Tablas_seguridad.do (bloque Desaparecidos).
*   Se exporta el conteo por municipio + la PROPORCIÓN dentro de la provincia
*     (personas del municipio / total provincial, fracción 0-1) + fila TOTAL
*     PROVINCIA. Cobertura: 88 municipios de la PAP (completa).
********************************************************************/

import excel "$rawdata/UBPD_desaparecidos_Antioquia.xlsx", ///
    sheet("Por Municipio") cellrange(A2) firstrow clear
rename CódDANE ind_mpio
rename PersonasDesaparecidas desaparecidos
destring ind_mpio desaparecidos, replace force
drop if missing(ind_mpio)   // descarta filas SIN INFORMACIÓN / TOTAL DEPARTAMENTO
keep ind_mpio desaparecidos

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

* proporción de cada municipio dentro del total provincial
egen _tot_prov = total(desaparecidos)
gen prop_desaparecidos = desaparecidos / _tot_prov
drop _tot_prov
gen tipo_fila = "Municipio"
tempfile base
save `base'

* Total provincial (suma)
collapse (sum) desaparecidos, by(provincia)
gen prop_desaparecidos = 1
gen nvl_label = "TOTAL PROVINCIA $provincia_label"
gen subregion = ""
gen ind_mpio  = .
gen tipo_fila = "Total provincia"
append using `base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
gsort orden_fila -desaparecidos

label variable ind_mpio           "Código DANE"
label variable nvl_label          "Municipio"
label variable subregion          "Subregión"
label variable provincia          "Provincia"
label variable desaparecidos      "Personas dadas por desaparecidas"
label variable prop_desaparecidos "Proporción dentro de la provincia"
format desaparecidos %12.0fc
format prop_desaparecidos %6.4f

export excel ///
    ind_mpio nvl_label subregion provincia desaparecidos prop_desaparecidos ///
    using "$out_10/seguridad.xlsx", sheet("desaparecidos") firstrow(varlabels) sheetreplace


di as text "  10_Seguridad: tablas exportadas en $out_10/"
