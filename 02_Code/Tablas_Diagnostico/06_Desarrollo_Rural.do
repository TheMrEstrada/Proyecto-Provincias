* ----------------------------------------------------------------------------
* PROVINCIAS - 06_Desarrollo_Rural.do
* SECCION 6: DESARROLLO RURAL
* FIGURAS: Inventario pecuario, Extensión municipal,
*          Cultivos y producción agrícola (4 figuras)
* INPUTS: $data/PECUARIO_PROVINCIAS.xlsx, $rawdata/AREA_ORIGINAL.xlsx,
*         CULTIVOS_PROVINCIAS.xlsx
* OUTPUTS: $out_06 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


* Un solo archivo por seccion: borrar una vez antes de escribir las hojas
capture erase "$out_06/desarrollo_rural.xlsx"

/********************************************************************
* 6.1 Inventario pecuario
*     PECUARIO_PROVINCIAS.xlsx NO tiene columna prov
*     -> Merge con códigos_provincias.dta
*     Una sola hoja: cada especie en una columna + Total especies.
*     Especies sin registro en un municipio-año quedan en 0.
********************************************************************/

*------------------------------------
* Bovinos -> base municipio-año
*------------------------------------
import excel "$data/PECUARIO_PROVINCIAS.xlsx", sheet("InvBovino") firstrow clear
rename CódigoDanemunicipio ind_mpio
destring ind_mpio, replace force
drop if missing(ind_mpio)
destring Totalbovinos, replace force
rename Totalbovinos bovinos
collapse (sum) bovinos, by(ind_mpio Año)

tempfile pecuario
save `pecuario'

*------------------------------------
* Búfalos
*------------------------------------
import excel "$data/PECUARIO_PROVINCIAS.xlsx", sheet("InvBufalino") firstrow clear
rename CódigoDanemunicipio ind_mpio
destring ind_mpio, replace force
drop if missing(ind_mpio)
destring Totalbúfalos, replace force
rename Totalbúfalos bufalos
collapse (sum) bufalos, by(ind_mpio Año)

merge 1:1 ind_mpio Año using `pecuario', nogen
save `pecuario', replace

*------------------------------------
* Caprinos, Ovinos, Equinos (formato largo -> ancho)
*------------------------------------
import excel "$data/PECUARIO_PROVINCIAS.xlsx", sheet("InvCaprinoOvinoEquino") firstrow clear
rename CódigoDanemunicipio ind_mpio
destring ind_mpio, replace force
drop if missing(ind_mpio)
drop if missing(Especie)
destring Total, replace force
collapse (sum) Total, by(ind_mpio Año Especie)
reshape wide Total, i(ind_mpio Año) j(Especie) string
rename TotalCaprinos caprinos
rename TotalOvinos   ovinos
rename TotalEquinos  equinos

merge 1:1 ind_mpio Año using `pecuario', nogen
save `pecuario', replace

*------------------------------------
* Porcinos
*------------------------------------
import excel "$data/PECUARIO_PROVINCIAS.xlsx", sheet("InvPorcino") firstrow clear
rename CódigoDanemunicipio ind_mpio
destring ind_mpio, replace force
drop if missing(ind_mpio)
destring Totalporcinos, replace force
rename Totalporcinos porcinos
collapse (sum) porcinos, by(ind_mpio Año)

merge 1:1 ind_mpio Año using `pecuario', nogen
save `pecuario', replace

*------------------------------------
* Merge con códigos, filtrar provincia y consolidar
*------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

keep if id_provincia == $id_provincia

* Especies sin registro en un municipio-año -> 0
foreach v in bovinos bufalos caprinos ovinos equinos porcinos {
    replace `v' = 0 if missing(`v')
}

* Total de todas las especies por municipio y año
egen total_especies = rowtotal(bovinos bufalos caprinos ovinos equinos porcinos)

keep ind_mpio nvl_label subregion provincia Año ///
     bovinos bufalos caprinos ovinos equinos porcinos total_especies

sort Año nvl_label

*----------------------------------*
* Participación municipal en el total pecuario provincial (fig. 55)
*----------------------------------*
bysort Año: egen tot_prov_especies = total(total_especies)
gen participacion_pecuario_prov_pct = total_especies / tot_prov_especies
replace participacion_pecuario_prov_pct = . if tot_prov_especies == 0

*----------------------------------*
* Composición porcentual por especie dentro del municipio (fig. 56)
*----------------------------------*
foreach v in bovinos bufalos caprinos ovinos equinos porcinos {
    gen `v'_pct = `v' / total_especies
    replace `v'_pct = . if total_especies == 0
}

*----------------------------------*
* Labels
*----------------------------------*
label variable ind_mpio          "Código DANE"
label variable nvl_label         "Municipio"
label variable subregion         "Subregión"
label variable provincia         "Provincia"
label variable Año               "Año"
label variable bovinos           "Bovinos"
label variable bufalos           "Búfalos"
label variable caprinos          "Caprinos"
label variable ovinos            "Ovinos"
label variable equinos           "Equinos"
label variable porcinos          "Porcinos"
label variable total_especies    "Total especies pecuarias"
label variable participacion_pecuario_prov_pct "Participación en el total provincial (%)"
label variable bovinos_pct       "Bovinos (%)"
label variable bufalos_pct       "Búfalos (%)"
label variable caprinos_pct      "Caprinos (%)"
label variable ovinos_pct        "Ovinos (%)"
label variable equinos_pct       "Equinos (%)"
label variable porcinos_pct      "Porcinos (%)"

format participacion_pecuario_prov_pct bovinos_pct bufalos_pct caprinos_pct ///
       ovinos_pct equinos_pct porcinos_pct %6.2f


* Hoja 1: conteos por especie (fig. 54)
export excel ///
    ind_mpio nvl_label subregion provincia Año ///
    bovinos bufalos caprinos ovinos equinos porcinos total_especies ///
    using "$out_06/desarrollo_rural.xlsx", ///
    sheet("inventario_pecuario") firstrow(varlabels) sheetreplace

* Hoja 2: participación municipal en el total provincial (fig. 55)
export excel ///
    ind_mpio nvl_label subregion provincia Año ///
    total_especies participacion_pecuario_prov_pct ///
    using "$out_06/desarrollo_rural.xlsx", ///
    sheet("participacion_municipal") firstrow(varlabels) sheetreplace

* Hoja 3: composición porcentual por especie (fig. 56)
export excel ///
    ind_mpio nvl_label subregion provincia Año ///
    bovinos_pct bufalos_pct caprinos_pct ovinos_pct equinos_pct porcinos_pct ///
    using "$out_06/desarrollo_rural.xlsx", ///
    sheet("composicion_especies") firstrow(varlabels) sheetreplace


/********************************************************************
* 6.2 Extensión municipal (km²)
*     Área municipal desde AREA_ORIGINAL.xlsx (00_Inputs); provincia y
*     subregión por merge con códigos_provincias.dta (COD_MPIO -> ind_mpio),
*     evitando la columna prov (con errores) del derivado anterior.
*     NOTA: el suelo rural sigue excluido (pendiente); solo área total en km².
********************************************************************/

import excel "$rawdata/AREA_ORIGINAL.xlsx", sheet("Area") firstrow clear

rename COD_MPIO ind_mpio
destring ind_mpio, replace force
rename AREAKM2 area_km2
destring area_km2, replace force

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", keep(master match) nogen
keep if id_provincia == $id_provincia

preserve

    keep ind_mpio nvl_label subregion provincia area_km2

    gen tipo_fila = "Municipio"

    tempfile base total
    save `base'

    *----------------------------------*
    * Total provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (sum) area_km2 ///
        (count) n_municipios = ind_mpio, ///
        by(provincia)

    gen nvl_label = "TOTAL PROVINCIA $provincia_label"
    gen tipo_fila = "Total provincia"
    gen ind_mpio  = .
    gen subregion = ""

    save `total'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `total'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Total provincia"

    sort orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio   "Código DANE"
    label variable nvl_label  "Municipio"
    label variable subregion  "Subregión"
    label variable provincia  "Provincia"
    label variable area_km2   "Área municipal (km²)"

    format area_km2 %12.2f

    export excel ///
        ind_mpio nvl_label subregion provincia ///
        area_km2 ///
        using "$out_06/desarrollo_rural.xlsx", ///
        sheet("area_km2") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 6.3 Cultivos y producción agrícola
*   Insumo: CULTIVOS_PROVINCIAS.xlsx (UPRA/EVA), filtrando por
*   prov == "$provincia_nombre".
*   Hojas:
*     - permanentes / transitorios : PRINCIPAL cultivo (el de mayor producción)
*       por municipio-año (área sembrada, área cosechada, producción, rendimiento).
*     - composicion_agricola : por MUNICIPIO (participación del municipio en la
*       producción de la provincia [G39] + reparto permanentes/transitorios [G38]).
*     - rendimiento : rendimiento agregado por municipio (Σprod/Σárea) + provincia [G40].
*   NOTA (2026-08-05): se ELIMINÓ del flujo la variable de "área perdida"
*   (decisión de Pablo). El rendimiento se conserva.
********************************************************************/

import excel "$data/CULTIVOS_PROVINCIAS.xlsx", sheet("BasePagina") firstrow clear
keep if prov == "$provincia_nombre"
rename CódigoDanemunicipio cod_mun
destring cod_mun, replace force
rename Áreasembradaha  area_sembrada
rename Áreacosechadaha area_cosechada
rename Producciónt     produccion_cultivo
rename Rendimientotha  rendimiento
destring area_sembrada area_cosechada produccion_cultivo rendimiento, replace force

keep cod_mun Municipio subreg prov Cultivo Ciclodelcultivo Año Periodo ///
     area_sembrada area_cosechada produccion_cultivo rendimiento

label variable cod_mun            "Código DANE"
label variable Municipio          "Municipio"
label variable subreg             "Subregión"
label variable prov               "Provincia"
label variable Cultivo            "Cultivo"
label variable Ciclodelcultivo    "Ciclo del cultivo"
label variable Año                "Año"
label variable Periodo            "Periodo"
label variable area_sembrada      "Área sembrada (ha)"
label variable area_cosechada     "Área cosechada (ha)"
label variable produccion_cultivo "Producción (t)"
label variable rendimiento        "Rendimiento (t/ha)"
format area_sembrada area_cosechada produccion_cultivo %12.1f
format rendimiento %6.2f

tempfile cultivos_base
save `cultivos_base'

*------------------------------------
* 6.3.1 Principal cultivo PERMANENTE por municipio-año (mayor producción)
*   1 fila por municipio-año = el cultivo permanente de MAYOR producción.
*------------------------------------
preserve
    keep if Ciclodelcultivo == "Permanente"
    collapse (sum) area_sembrada area_cosechada produccion_cultivo, ///
        by(cod_mun Municipio subreg prov Ciclodelcultivo Cultivo Año)
    drop if missing(produccion_cultivo)
    gen rendimiento = produccion_cultivo / area_cosechada
    bysort cod_mun Año (produccion_cultivo): keep if _n == _N   // top-1 por producción
    label variable cod_mun            "Código DANE"
    label variable Municipio          "Municipio"
    label variable subreg             "Subregión"
    label variable prov               "Provincia"
    label variable Cultivo            "Principal cultivo permanente"
    label variable Ciclodelcultivo    "Ciclo del cultivo"
    label variable Año                "Año"
    label variable area_sembrada      "Área sembrada (ha)"
    label variable area_cosechada     "Área cosechada (ha)"
    label variable produccion_cultivo "Producción (t)"
    label variable rendimiento        "Rendimiento (t/ha)"
    format area_sembrada area_cosechada produccion_cultivo %12.1f
    format rendimiento %6.2f
    gsort Año -produccion_cultivo
    export excel ///
        cod_mun Municipio subreg prov Cultivo Ciclodelcultivo Año ///
        area_sembrada area_cosechada produccion_cultivo rendimiento ///
        using "$out_06/desarrollo_rural.xlsx", ///
        sheet("permanentes") firstrow(varlabels) sheetreplace
restore

*------------------------------------
* 6.3.2 Principal cultivo TRANSITORIO por municipio-año (mayor producción)
*   Se suma sobre periodos (semestres) antes de elegir el principal.
*------------------------------------
preserve
    keep if Ciclodelcultivo == "Transitorio"
    collapse (sum) area_sembrada area_cosechada produccion_cultivo, ///
        by(cod_mun Municipio subreg prov Ciclodelcultivo Cultivo Año)
    drop if missing(produccion_cultivo)
    gen rendimiento = produccion_cultivo / area_cosechada
    bysort cod_mun Año (produccion_cultivo): keep if _n == _N   // top-1 por producción
    label variable cod_mun            "Código DANE"
    label variable Municipio          "Municipio"
    label variable subreg             "Subregión"
    label variable prov               "Provincia"
    label variable Cultivo            "Principal cultivo transitorio"
    label variable Ciclodelcultivo    "Ciclo del cultivo"
    label variable Año                "Año"
    label variable area_sembrada      "Área sembrada (ha)"
    label variable area_cosechada     "Área cosechada (ha)"
    label variable produccion_cultivo "Producción (t)"
    label variable rendimiento        "Rendimiento (t/ha)"
    format area_sembrada area_cosechada produccion_cultivo %12.1f
    format rendimiento %6.2f
    gsort Año -produccion_cultivo
    export excel ///
        cod_mun Municipio subreg prov Cultivo Ciclodelcultivo Año ///
        area_sembrada area_cosechada produccion_cultivo rendimiento ///
        using "$out_06/desarrollo_rural.xlsx", ///
        sheet("transitorios") firstrow(varlabels) sheetreplace
restore


/********************************************************************
* 6.3.3 Composición agrícola por MUNICIPIO
*   Reproduce:
*     - G39 "Composición porcentual de la producción agrícola - PAP":
*       participación de cada municipio en la producción total de la provincia
*       (pct_prod_prov).
*     - G38 "Proporción de la producción agrícola por municipio y según tipo de
*       cultivo": reparto permanentes/transitorios por municipio
*       (pct_permanente, pct_transitorio).
*   Una fila por municipio-año (2019-2025) + fila TOTAL PROVINCIA.
*   Proporciones en fracción 0-1 (formatear como % en Excel).
********************************************************************/

use `cultivos_base', clear
gen prod_perm = produccion_cultivo if Ciclodelcultivo == "Permanente"
gen prod_tran = produccion_cultivo if Ciclodelcultivo == "Transitorio"
collapse (sum) prod_perm prod_tran, by(cod_mun Municipio subreg prov Año)
gen prod_total = prod_perm + prod_tran
bys Año: egen prod_total_prov = total(prod_total)
gen pct_prod_prov   = prod_total / prod_total_prov
gen pct_permanente  = prod_perm  / prod_total
gen pct_transitorio = prod_tran  / prod_total

* Fila TOTAL PROVINCIA por año
preserve
    collapse (sum) prod_perm prod_tran prod_total, by(prov Año)
    gen prod_total_prov  = prod_total
    gen pct_prod_prov    = 1
    gen pct_permanente   = prod_perm / prod_total
    gen pct_transitorio  = prod_tran / prod_total
    gen cod_mun   = .
    gen Municipio = "TOTAL PROVINCIA $provincia_label"
    gen subreg    = ""
    gen tipo_fila = "Total provincia"
    tempfile totprov
    save `totprov'
restore
gen tipo_fila = "Municipio"
append using `totprov'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Total provincia"
gsort Año orden_fila -prod_total

label variable cod_mun         "Código DANE"
label variable Municipio       "Municipio"
label variable subreg          "Subregión"
label variable prov            "Provincia"
label variable Año             "Año"
label variable prod_perm       "Producción de cultivos permanentes (t)"
label variable prod_tran       "Producción de cultivos transitorios (t)"
label variable prod_total      "Producción agrícola total del municipio (t)"
label variable prod_total_prov "Producción agrícola total de la provincia (t)"
label variable pct_prod_prov   "Participación del municipio en la producción de la provincia"
label variable pct_permanente  "Proporción de cultivos permanentes"
label variable pct_transitorio "Proporción de cultivos transitorios"
format prod_perm prod_tran prod_total prod_total_prov %14.1f
format pct_prod_prov pct_permanente pct_transitorio %6.4f

export excel ///
    cod_mun Municipio subreg prov Año ///
    prod_perm prod_tran prod_total prod_total_prov ///
    pct_prod_prov pct_permanente pct_transitorio ///
    using "$out_06/desarrollo_rural.xlsx", ///
    sheet("composicion_agricola") firstrow(varlabels) sheetreplace


/********************************************************************
* 6.3.4 Rendimiento agrícola por MUNICIPIO (G40, sin área perdida)
*   Rendimiento agregado = Σ producción / Σ área cosechada (t/ha), por año,
*   + fila PROVINCIA (Σ sobre todos los municipios de la provincia).
********************************************************************/

use `cultivos_base', clear
collapse (sum) produccion_cultivo area_cosechada, by(cod_mun Municipio subreg prov Año)
gen rendimiento = produccion_cultivo / area_cosechada

preserve
    collapse (sum) produccion_cultivo area_cosechada, by(prov Año)
    gen rendimiento = produccion_cultivo / area_cosechada
    gen cod_mun   = .
    gen Municipio = "PROVINCIA $provincia_label"
    gen subreg    = ""
    gen tipo_fila = "Provincia"
    tempfile rendprov
    save `rendprov'
restore
gen tipo_fila = "Municipio"
append using `rendprov'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Provincia"
gsort Año orden_fila -rendimiento

label variable cod_mun            "Código DANE"
label variable Municipio          "Municipio"
label variable subreg             "Subregión"
label variable prov               "Provincia"
label variable Año                "Año"
label variable produccion_cultivo "Producción total (t)"
label variable area_cosechada     "Área cosechada total (ha)"
label variable rendimiento        "Rendimiento (t/ha)"
format produccion_cultivo area_cosechada %14.1f
format rendimiento %8.2f

export excel ///
    cod_mun Municipio subreg prov Año produccion_cultivo area_cosechada rendimiento ///
    using "$out_06/desarrollo_rural.xlsx", ///
    sheet("rendimiento") firstrow(varlabels) sheetreplace


di as text "  06_Desarrollo_Rural: tablas exportadas en $out_06/"
