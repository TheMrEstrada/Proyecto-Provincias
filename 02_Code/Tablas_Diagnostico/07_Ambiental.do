* ----------------------------------------------------------------------------
* PROVINCIAS - 07_Ambiental.do
* SECCION 7: AMBIENTAL
* FIGURAS: Áreas protegidas, IRCA, Emergencias y desastres, IMRC
* INPUTS: $data/AREAPROTEGIDA_PROVINCIAS.xlsx, IRCA_PROVINCIAS.xlsx,
*         EMERGENCIAS_PROVINCIAS.xlsx, IMRC_PROVINCIAS.xlsx
* OUTPUTS: $out_07 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


* Un solo archivo por seccion: borrar una vez antes de escribir las hojas
capture erase "$out_07/ambiental.xlsx"

/********************************************************************
* 7.1 Áreas protegidas
*     Una sola hoja (detalle): cada área protegida por municipio,
*     total provincial y total departamental, con participación (%).
********************************************************************/

import excel "$data/AREAPROTEGIDA_PROVINCIAS.xlsx", sheet("Hoja1") firstrow clear

destring COD_MPIO, replace force
rename Area_Sobre_Municipio area_km2
destring area_km2, replace force

* Total departamental (todo Antioquia): escalar para participación
quietly summarize area_km2
local tot_dep = r(sum)

*----------------------------------*
* Total departamental (fila)
*----------------------------------*
preserve
    collapse (sum) area_km2
    gen Municipio = "TOTAL DEPARTAMENTO (ANTIOQUIA)"
    gen subreg    = ""
    gen prov      = "DEPARTAMENTO DE ANTIOQUIA"
    gen tipo_fila = "Total departamento"
    tempfile dep
    save `dep'
restore

*----------------------------------*
* Detalle de la provincia
*----------------------------------*
keep if prov == "$provincia_nombre"

* Total provincial: escalar para participación
quietly summarize area_km2
local tot_prov = r(sum)

keep COD_MPIO Municipio subreg prov NombreAreaProtegida categori_1 area_km2
gen tipo_fila = "Municipio"

tempfile base prov_tot
save `base'

*----------------------------------*
* Total provincial (fila)
*----------------------------------*
use `base', clear
collapse (sum) area_km2, by(prov)
gen Municipio = "TOTAL PROVINCIA $provincia_label"
gen subreg    = ""
gen tipo_fila = "Total provincia"
save `prov_tot'

*----------------------------------*
* Unir: detalle + total provincia + total departamento
*----------------------------------*
use `base', clear
append using `prov_tot'
append using `dep'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Total departamento"

sort orden_fila Municipio NombreAreaProtegida

*----------------------------------*
* Participación (%):
*   - detalle: área de la fila sobre el total provincial
*   - total provincia: total provincial sobre el total departamental
*   - total departamento: queda vacío (es la base)
*----------------------------------*
gen participacion_area_prot_pct = .
replace participacion_area_prot_pct = area_km2 / `tot_prov' if tipo_fila == "Municipio"
replace participacion_area_prot_pct = area_km2 / `tot_dep'  if tipo_fila == "Total provincia"

*----------------------------------*
* Labels
*----------------------------------*
label variable COD_MPIO                    "Código DANE"
label variable Municipio                   "Municipio"
label variable subreg                      "Subregión"
label variable prov                        "Provincia"
label variable NombreAreaProtegida         "Nombre Área Protegida"
label variable categori_1                  "Categoría"
label variable area_km2                    "Área sobre municipio (km²)"
label variable participacion_area_prot_pct "Participación del área protegida (%)"

format area_km2 %12.2f
format participacion_area_prot_pct %6.2f


export excel ///
    COD_MPIO Municipio subreg prov ///
    NombreAreaProtegida categori_1 area_km2 participacion_area_prot_pct ///
    using "$out_07/ambiental.xlsx", ///
    sheet("detalle") firstrow(varlabels) sheetreplace


/********************************************************************
* 7.2 IRCA (Índice de Riesgo de la Calidad del Agua)
********************************************************************/

import excel "$data/IRCA_PROVINCIAS.xlsx", sheet("Data") firstrow clear

keep if prov == "$provincia_nombre"
destring MunicipioCodigo, replace force

preserve

    keep MunicipioCodigo Municipio Año subreg prov ///
         IRCA Nivelderiesgo IRCAurbano Nivelderiesgourbano ///
         IRCArural Nivelderiesgorural

    gen tipo_fila = "Municipio"

    * Destring las variables numéricas
    foreach v in IRCA IRCAurbano IRCArural {
        capture destring `v', replace force
    }

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial por año
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) IRCA IRCAurbano IRCArural ///
        (count) n_municipios = MunicipioCodigo, ///
        by(prov Año)

    gen Municipio = "PROMEDIO SIMPLE PROVINCIA $provincia_label"
    gen tipo_fila = "Promedio provincia"
    gen MunicipioCodigo = .
    gen subreg = ""
    gen Nivelderiesgo = ""
    gen Nivelderiesgourbano = ""
    gen Nivelderiesgorural = ""

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort Año orden_fila Municipio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable MunicipioCodigo    "Código DANE"
    label variable Municipio          "Municipio"
    label variable subreg             "Subregión"
    label variable prov               "Provincia"
    label variable Año                "Año"
    label variable IRCA               "IRCA"
    label variable Nivelderiesgo      "Nivel de riesgo"
    label variable IRCAurbano         "IRCA urbano"
    label variable Nivelderiesgourbano  "Nivel riesgo urbano"
    label variable IRCArural          "IRCA rural"
    label variable Nivelderiesgorural   "Nivel riesgo rural"

    format IRCA IRCAurbano IRCArural %6.2f

    export excel ///
        MunicipioCodigo Municipio subreg prov Año ///
        IRCA Nivelderiesgo IRCAurbano Nivelderiesgourbano ///
        IRCArural Nivelderiesgorural ///
        using "$out_07/ambiental.xlsx", ///
        sheet("irca") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 7.3 Emergencias y desastres
*     EMERGENCIAS_PROVINCIAS.xlsx NO tiene columna prov
*     → Merge con códigos_provincias.dta
********************************************************************/

import excel "$data/EMERGENCIAS_PROVINCIAS.xlsx", sheet("Data") firstrow clear

* Estandarizar nombre de variable de código DIVIPOLA
capture rename CODIFICACIÓNSEGUN ind_mpio
capture rename CODIFICACIÓNSEGUNDIVIPOLADEPART ind_mpio
capture rename CODIFICACIÓNSEGUNDIVIPOLA ind_mpio

capture destring ind_mpio, replace

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

keep if id_provincia == $id_provincia

rename EVENTO emergencia

* Año del evento (FECHA puede importarse como datetime %tc, fecha %td o string)
capture confirm numeric variable FECHA
if _rc == 0 {
    gen Año = year(cond(FECHA > 1e6, dofc(FECHA), FECHA))
}
else {
    gen Año = year(date(FECHA, "YMD"))
}

preserve

    keep ind_mpio MUNICIPIO nvl_label subregion provincia FECHA emergencia

    * Contar eventos por municipio y tipo
    gen n_eventos = 1

    collapse (sum) n_eventos, ///
        by(ind_mpio nvl_label subregion provincia emergencia)

    gen tipo_fila = "Municipio"

    tempfile base total
    save `base'

    *----------------------------------*
    * Total provincial por tipo de evento
    *----------------------------------*
    use `base', clear

    collapse ///
        (sum) n_eventos ///
        (count) n_municipios = ind_mpio, ///
        by(provincia emergencia)

    gen nvl_label = "TOTAL PROVINCIA $provincia_label"
    gen tipo_fila = "Total provincia"
    gen ind_mpio = .
    gen subregion = ""

    save `total'

    use `base', clear
    append using `total'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Total provincia"

    sort emergencia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable emergencia      "Tipo de evento"
    label variable n_eventos   "Número de eventos"

    export excel ///
        ind_mpio nvl_label subregion provincia ///
        emergencia n_eventos ///
        using "$out_07/ambiental.xlsx", ///
        sheet("eventos_tipo") firstrow(varlabels) sheetreplace

restore

* Tabla adicional: eventos por año y municipio
preserve

    keep ind_mpio nvl_label subregion provincia Año

    gen n_eventos = 1

    collapse (sum) n_eventos, ///
        by(ind_mpio nvl_label subregion provincia Año)

    gen tipo_fila = "Municipio"

    tempfile base total
    save `base'

    use `base', clear

    collapse ///
        (sum) n_eventos ///
        (count) n_municipios = ind_mpio, ///
        by(provincia Año)

    gen nvl_label = "TOTAL PROVINCIA $provincia_label"
    gen tipo_fila = "Total provincia"
    gen ind_mpio = .
    gen subregion = ""

    save `total'

    use `base', clear
    append using `total'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Total provincia"

    sort Año orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable Año         "Año"
    label variable n_eventos   "Número de eventos"

    export excel ///
        ind_mpio nvl_label subregion provincia ///
        Año n_eventos ///
        using "$out_07/ambiental.xlsx", ///
        sheet("eventos_año") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 7.4 Desastres selectos por municipio (tabla para figura final)
*     Municipio x 6 tipos + emergencia más prevalente, con total de
*     provincia y total de la subregión dominante.
*     Subregión dominante = la más frecuente entre los municipios de
*     la provincia seleccionada. Fuente de subregión: códigos_provincias.dta
********************************************************************/

* --- Subregión dominante de la provincia (la más frecuente) ---
use "$rawdata/códigos_provincias.dta", clear
keep if id_provincia == $id_provincia
contract subregion
gsort -_freq subregion
local dom_subreg = subregion[1]

* --- Conteo de desastres selectos por municipio ---
import excel "$data/EMERGENCIAS_PROVINCIAS.xlsx", sheet("Data") firstrow clear

capture rename CODIFICACIÓNSEGUN ind_mpio
capture rename CODIFICACIÓNSEGUNDIVIPOLADEPART ind_mpio
capture rename CODIFICACIÓNSEGUNDIVIPOLA ind_mpio
capture destring ind_mpio, replace

gen _ev = strtrim(upper(EVENTO))
gen av  = _ev == "AVENIDA TORRENCIAL"
gen mm  = _ev == "MOVIMIENTO EN MASA"
gen icv = _ev == "INCENDIO DE COBERTURA VEGETAL"
gen inu = _ev == "INUNDACION"
gen seq = _ev == "SEQUIA"
gen sis = _ev == "SISMO"

collapse (sum) av mm icv inu seq sis, by(ind_mpio)

* Traer subregión, provincia y nombre del municipio
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
* Subregión DANE completa (125 municipios) para el agregado de subregión
merge m:1 ind_mpio using "$rawdata/subreg_completo.dta", keep(master match) nogen

* --- Detalle: municipios de la provincia ---
preserve
    keep if id_provincia == $id_provincia
    keep ind_mpio nvl_label subregion av mm icv inu seq sis
    gen tipo_fila = "Municipio"
    tempfile detalle
    save `detalle'
restore

* --- Total provincia ---
preserve
    keep if id_provincia == $id_provincia
    collapse (sum) av mm icv inu seq sis
    gen nvl_label = "TOTAL PROVINCIA $provincia_label"
    gen subregion = ""
    gen ind_mpio  = .
    gen tipo_fila = "Total provincia"
    tempfile tprov
    save `tprov'
restore

* --- Total de la subregión dominante ---
preserve
    keep if subregion_full == "`dom_subreg'"
    collapse (sum) av mm icv inu seq sis
    gen nvl_label = "TOTAL SUBREGIÓN `dom_subreg'"
    gen subregion = "`dom_subreg'"
    gen ind_mpio  = .
    gen tipo_fila = "Total subregión"
    tempfile tsub
    save `tsub'
restore

* --- Unir: detalle + total provincia + total subregión ---
use `detalle', clear
append using `tprov'
append using `tsub'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
sort orden_fila nvl_label

* --- Emergencia más prevalente (entre los 6 selectos; empate: la primera en orden) ---
egen _max = rowmax(av mm icv inu seq sis)
gen prevalente = ""
replace prevalente = "Sismo"                         if sis == _max
replace prevalente = "Sequía"                        if seq == _max
replace prevalente = "Inundación"                    if inu == _max
replace prevalente = "Incendio de cobertura vegetal" if icv == _max
replace prevalente = "Movimiento en masa"            if mm  == _max
replace prevalente = "Avenida torrencial"            if av  == _max
replace prevalente = "" if _max == 0
drop _max

* --- Labels ---
label variable ind_mpio    "Código DANE"
label variable nvl_label   "Municipio"
label variable subregion   "Subregión"
label variable av          "Avenida torrencial"
label variable mm          "Movimiento en masa"
label variable icv         "Incendio de cobertura vegetal"
label variable inu         "Inundación"
label variable seq         "Sequía"
label variable sis         "Sismo"
label variable prevalente  "Emergencia más prevalente"

export excel ///
    ind_mpio nvl_label subregion av mm icv inu seq sis prevalente ///
    using "$out_07/ambiental.xlsx", ///
    sheet("desastres_selectos") firstrow(varlabels) sheetreplace


/********************************************************************
* 7.5 IMRC - Índice Municipal de Riesgo de Desastres
*     Exceso y Déficit de lluvias
********************************************************************/

import excel "$data/IMRC_PROVINCIAS.xlsx", sheet("IMRC") firstrow clear

* Los encabezados de IMRC son largos y casi idénticos, así que Stata no los
* importa como IMRC_E/IMRC_D. Se renombran por posición (col 5 = Exceso, col 6 = Déficit)
ds DIVIPOLA Municipio subreg prov, not
local imrc_e : word 1 of `r(varlist)'
local imrc_d : word 2 of `r(varlist)'
rename `imrc_e' IMRC_E
rename `imrc_d' IMRC_D

destring DIVIPOLA IMRC_E IMRC_D, replace force

*----------------------------------*
* Promedio departamental (todos los municipios, antes de filtrar)
*----------------------------------*
preserve
    collapse (mean) IMRC_E IMRC_D (count) n_municipios = DIVIPOLA
    gen Municipio = "PROMEDIO SIMPLE DEPARTAMENTO (ANTIOQUIA)"
    gen subreg    = ""
    gen prov      = "DEPARTAMENTO DE ANTIOQUIA"
    gen DIVIPOLA  = .
    gen tipo_fila = "Promedio departamento"
    tempfile depprom
    save `depprom'
restore

keep if prov == "$provincia_nombre"

preserve

    keep DIVIPOLA Municipio subreg prov IMRC_E IMRC_D

    gen tipo_fila = "Municipio"

    tempfile base promedio
    save `base'

    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) IMRC_E IMRC_D ///
        (count) n_municipios = DIVIPOLA, ///
        by(prov)

    gen Municipio = "PROMEDIO SIMPLE PROVINCIA $provincia_label"
    gen tipo_fila = "Promedio provincia"
    gen DIVIPOLA = .
    gen subreg = ""

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'
    append using `depprom'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"
    replace orden_fila = 3 if tipo_fila == "Promedio departamento"

    sort orden_fila Municipio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable DIVIPOLA    "Código DANE"
    label variable Municipio   "Municipio"
    label variable subreg      "Subregión"
    label variable prov        "Provincia"
    label variable IMRC_E      "IMRC Exceso de lluvias"
    label variable IMRC_D      "IMRC Déficit de lluvias"

    format IMRC_E IMRC_D %6.4f

    export excel ///
        DIVIPOLA Municipio subreg prov ///
        IMRC_E IMRC_D ///
        using "$out_07/ambiental.xlsx", ///
        sheet("imrc") firstrow(varlabels) sheetreplace

restore


* ============================================================================
* 7.2 (Laura) Porcentaje de perdida de cobertura arborea 2001-2023
* ----------------------------------------------------------------------------
* Fuente: Pérdida de cobertura árborea.xlsx (hoja "Pérdida cobertura árborea").
* El encabezado del % es largo/con acentos: se importa sin firstrow y se
* renombra por posicion (A=Cod_mpio, C=% perdida).
* NOTA: verificar unidad (fraccion 0-1 vs %) en debugging. Figura municipal;
*       sin fila de agregado provincial (requeriria area base de cobertura).
* ============================================================================

import excel "$rawdata/Pérdida de cobertura árborea.xlsx", ///
    sheet("Pérdida cobertura árborea") cellrange(A1) clear
drop in 1
rename A ind_mpio
rename C perdida_ca
keep ind_mpio perdida_ca
destring ind_mpio, replace force
destring perdida_ca, replace force
drop if missing(ind_mpio)

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia
sort nvl_label

label variable ind_mpio   "Código DANE"
label variable nvl_label  "Municipio"
label variable subregion  "Subregión"
label variable provincia  "Provincia"
label variable perdida_ca "Pérdida de cobertura arbórea 2001-2023 (fracción; formatear como % en Excel)"
format perdida_ca %8.3f

export excel ind_mpio nvl_label subregion provincia perdida_ca ///
    using "$out_07/ambiental.xlsx", ///
    sheet("perdida_cobertura") firstrow(varlabels) sheetreplace


di as text "  07_Ambiental: tablas exportadas en $out_07/"
