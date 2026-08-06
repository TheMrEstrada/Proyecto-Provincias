* ----------------------------------------------------------------------------
* PROVINCIAS - 04_Gobernabilidad.do
* SECCION 4: GOBERNABILIDAD
* FIGURAS: MDM, IDF, Indicador Ley 617, ICM
* INPUTS: $data/MDM_PROVINCIAS.xlsx, IDF_PROVINCIAS.xlsx,
*         617_PROVINCIAS.xlsx, ICM_PROVINCIAS.xlsx
* OUTPUTS: $out_04 (archivos .xlsx)
* REQUIERE: 00_master.do (define globals)
* ----------------------------------------------------------------------------


* Un solo archivo por seccion: borrar una vez antes de escribir las hojas
capture erase "$out_04/gobernabilidad.xlsx"

/********************************************************************
* 4.1 Medición de Desempeño Municipal (MDM)
********************************************************************/

import excel "$data/MDM_PROVINCIAS.xlsx", sheet("Base") firstrow clear

keep if prov == "$provincia_nombre"
destring cmpio, replace force
rename año Año
rename mdm med_d_mun

preserve

    keep cmpio nmpio subreg prov Año gestion resultados med_d_mun

    gen tipo_fila = "Municipio"

    * Sin fila de promedio provincial (decisión de Pablo: MDM no se promedia).
    sort Año nmpio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable cmpio       "Código DANE"
    label variable nmpio       "Municipio"
    label variable subreg      "Subregión"
    label variable prov        "Provincia"
    label variable Año         "Año"
    label variable gestion     "Gestión"
    label variable resultados  "Resultados"
    label variable med_d_mun   "MDM"

    format gestion resultados med_d_mun %6.2f

    export excel ///
        cmpio nmpio subreg prov Año ///
        gestion resultados med_d_mun ///
        using "$out_04/gobernabilidad.xlsx", ///
        sheet("mdm") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 4.2 Índice de Desempeño Fiscal (IDF)
********************************************************************/

import excel "$data/IDF_PROVINCIAS.xlsx", sheet("IDF") firstrow clear
destring Codigo, replace force
rename año Año
rename IDF idf

* La provincia ("Esquema asociativo") y la subregión del archivo están CORRUPTAS
* (desalineadas: municipios asignados a la provincia equivocada). Se descartan y se
* traen provincia/subregión por merge con códigos_provincias (fuente confiable),
* igual que en SRTDAF (10_Seguridad). [Corregir el archivo fuente en el repo.]
capture drop Esquemaasociativo
capture drop Subregión
rename Codigo ind_mpio
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta", ///
    keepusing(provincia subregion id_provincia) keep(master match) nogen
keep if id_provincia == $id_provincia
rename ind_mpio Codigo
rename provincia prov_idf
rename subregion Subregión

preserve

    keep Codigo Municipio Subregión prov_idf Año Resultados Gestion idf Rango

    gen tipo_fila = "Municipio"

    * Sin fila de promedio provincial (decisión de Pablo: IDF no se promedia).
    sort Año Municipio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable Codigo       "Código DANE"
    label variable Municipio    "Municipio"
    label variable Subregión    "Subregión"
    label variable prov_idf     "Provincia"
    label variable Año          "Año"
    label variable Resultados   "Resultados"
    label variable Gestion      "Gestión"
    label variable idf          "IDF"
    label variable Rango        "Rango"

    format Resultados Gestion idf %6.2f

    export excel ///
        Codigo Municipio Subregión prov_idf Año ///
        Resultados Gestion idf Rango ///
        using "$out_04/gobernabilidad.xlsx", ///
        sheet("idf") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 4.3 Indicador Ley 617
********************************************************************/

import excel "$data/617_PROVINCIAS.xlsx", sheet("617") firstrow clear

keep if prov == "$provincia_nombre"
destring Código, replace force

preserve

    keep Código Municipio subreg prov Año ICDL ///
         Gastosfuncionamiento Indicador617 Observación

    rename Gastosfuncionamiento gastos_func
    rename Indicador617 ind_617

    *----------------------------------*
    * SIN agregado: Ley 617 NO se agrega.
    * Es un cociente institucional (gastos func. / ICLD) de CADA entidad, medido
    * contra el techo legal de la categoría de cada municipio. No existe un 617
    * provincial/subregional, y el 617 departamental corresponde a la Gobernación
    * (otra entidad), no a la suma de los municipios. Por eso se exportan SOLO los
    * municipios de la provincia seleccionada, sin filas de provincia/subregión/depto.
    *----------------------------------*
    sort Año Municipio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable Código       "Código DANE"
    label variable Municipio    "Municipio"
    label variable subreg       "Subregión"
    label variable prov         "Provincia"
    label variable Año          "Año"
    label variable ICDL         "ICDL"
    label variable gastos_func  "Gastos de funcionamiento"
    label variable ind_617      "Indicador Ley 617"
    label variable Observación  "Observación"

    format ICDL gastos_func ind_617 %12.2f

    export excel ///
        Código Municipio subreg prov Año ///
        ICDL gastos_func ind_617 Observación ///
        using "$out_04/gobernabilidad.xlsx", ///
        sheet("ley617") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* 4.4 Índice de Capacidad Municipal (ICM)
********************************************************************/

import excel "$data/ICM_PROVINCIAS.xlsx", sheet("BD_ICM_Municipal") firstrow clear

keep if prov == "$provincia_nombre"

* Renombrar variables (Stata importa ICM-00-0 como ICM000, etc.)
rename ICM000 ICM_total
rename PCC000 PCC_total
rename GPI000 GPI_total
rename EIS000 EIS_total
rename CTI000 CTI_total
rename SEG000 SEG_total
rename SOS000 SOS_total
rename AÑO Año
destring Divipola, replace force

keep Divipola Municipio subreg prov Año ///
     ICM_total PCC_total GPI_total EIS_total ///
     CTI_total SEG_total SOS_total
gen tipo_fila = "Municipio"
tempfile base_icm
save `base_icm'

* Poblacion por año (peso) - todos los municipios, todas las áreas Total
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if ÁREAGEOGRÁFICA == "Total"
keep DPMP AÑO TotalGeneral
rename DPMP Divipola
rename AÑO  Año
rename TotalGeneral pob
destring Divipola Año pob, replace force
tempfile pobyr
save `pobyr'

*----------------------------------*
* Promedio provincial PONDERADO por población del año
*----------------------------------*
use `base_icm', clear
merge m:1 Divipola Año using `pobyr', keep(master match) nogen
foreach v in ICM_total PCC_total GPI_total EIS_total CTI_total SEG_total SOS_total {
    gen _x_`v' = `v' * pob
    gen _w_`v' = pob if !missing(`v')
}
collapse (sum) _x_* _w_* (count) n_municipios = Divipola, by(prov Año)
foreach v in ICM_total PCC_total GPI_total EIS_total CTI_total SEG_total SOS_total {
    gen `v' = _x_`v' / _w_`v'
}
drop _x_* _w_*
gen Municipio = "PROMEDIO PONDERADO PROVINCIA $provincia_label (por población del año)"
gen tipo_fila = "Promedio provincia"
gen Divipola = .
gen subreg = ""
tempfile promedio
save `promedio'

use `base_icm', clear
append using `promedio'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
sort Año orden_fila Municipio

*----------------------------------*
* Labels
*----------------------------------*
label variable Divipola     "Código DANE"
label variable Municipio    "Municipio"
label variable subreg       "Subregión"
label variable prov         "Provincia"
label variable Año          "Año"
label variable ICM_total    "ICM"
label variable PCC_total    "PCC"
label variable GPI_total    "GPI"
label variable EIS_total    "EIS"
label variable CTI_total    "CTI"
label variable SEG_total    "SEG"
label variable SOS_total    "SOS"

format ICM_total PCC_total GPI_total EIS_total ///
       CTI_total SEG_total SOS_total %6.2f

export excel ///
    Divipola Municipio subreg prov Año ///
    ICM_total PCC_total GPI_total EIS_total ///
    CTI_total SEG_total SOS_total ///
    using "$out_04/gobernabilidad.xlsx", ///
    sheet("icm") firstrow(varlabels) sheetreplace


di as text "  04_Gobernabilidad: tablas exportadas en $out_04/"
