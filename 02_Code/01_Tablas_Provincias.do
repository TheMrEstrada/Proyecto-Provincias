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
* DEMOGRAFÍA
* Tabla de Proyecciones de población 2025
********************************************************************/

*--------------------------------------------------
* 1. Importar población municipal desde Excel
*--------------------------------------------------
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear
keep if AÑO==2025
keep DPMP MPIO AÑO ÁREAGEOGRÁFICA TotalGeneral

rename DPMP ind_mpio
destring ind_mpio, replace

*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "códigos_provincias.dta"

keep if _merge == 3
drop _merge

*************************************************************
* TABLA: Participación municipal por provincia y área
*************************************************************

preserve

    rename TotalGeneral habitantes
    rename ÁREAGEOGRÁFICA area
    rename MPIO municipio

    bysort provincia area: egen total_prov_area = total(habitantes)

    gen participacion_pct = (habitantes / total_prov_area) * 100
    format participacion_pct %6.1f

    gsort provincia area -habitantes

    keep subregion provincia area municipio habitantes participacion_pct
    order municipio subregion provincia area habitantes participacion_pct

    label variable subregion "Subregión"
    *label variable esquema_asociativo "Esquema asociativo"
    label variable provincia "Provincia"
    label variable area "Área"
    label variable municipio "Municipio"
    label variable habitantes "Habitantes"
    label variable participacion_pct "%"

    export excel using "$output/tablas_provincias.xlsx", ///
        sheet("población_area") firstrow(varlabels) sheetreplace

restore


*************************************************************
* TABLA: Población total, cabecera y rural por municipio
*************************************************************

preserve

    rename TotalGeneral habitantes
    rename ÁREAGEOGRÁFICA area
    rename MPIO municipio

    gen area_cat = ""
    replace area_cat = "total"     if area == "Total"
    replace area_cat = "cabecera"  if area == "Cabecera Municipal"
    replace area_cat = "rural"     if area == "Centros Poblados y Rural Disperso"

    keep subregion provincia municipio ind_mpio area_cat habitantes

    reshape wide habitantes, ///
        i(subregion provincia municipio ind_mpio) ///
        j(area_cat) string

    rename habitantestotal habitantes_total
    rename habitantescabecera habitantes_cabecera
    rename habitantesrural habitantes_rural

    gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
    gen pct_rural    = (habitantes_rural / habitantes_total) * 100

    format pct_cabecera pct_rural %6.1f

    order municipio subregion provincia ind_mpio ///
          habitantes_total habitantes_cabecera habitantes_rural ///
          pct_cabecera pct_rural

    label variable subregion "Subregión"
    label variable provincia "Provincia"
    label variable municipio "Municipio"
    label variable ind_mpio "Código DANE"
    label variable habitantes_total "Habitantes total"
    label variable habitantes_cabecera "Habitantes cabecera"
    label variable habitantes_rural "Habitantes rural"
    label variable pct_cabecera "% cabecera"
    label variable pct_rural "% rural"

    export excel using "$output/tablas_provincias.xlsx", ///
        sheet("población_wide") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* DEMOGRAFÍA
* Tabla de Natalidad, Mortalidad, Envejecimiento...
********************************************************************/
*Merge datos salud con población 
use "$data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA", clear

merge 1:1 ind_mpio using "$data/poblacion_municipal_total_2025_dicc"
drop _merge	

*variables relevantes para la tabla
keep ind_mpio nvl_label tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T

*merge datos provincias
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

//********************************************************************
* Tabla demográfica municipal + promedio por provincia en una sola hoja
********************************************************************/

preserve

    keep ind_mpio subregion id_provincia provincia nvl_label ///
     tasa_natalidad tasa_mortalidad crec_vegetativo ///
     I_enve_T

    gen tipo_fila = "Municipio"

    tempfile base subregiones promedios
    save `base'

    * Base única de subregión por provincia
    frame put id_provincia subregion, into(fr_subregiones)
    frame fr_subregiones {
        duplicates drop id_provincia, force
        save `subregiones'
    }
    frame drop fr_subregiones

    * Promedios por provincia
    collapse ///
        (mean) tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedios'

    use `base', clear
    append using `promedios'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable subregion          "Subregión"
    label variable nvl_label          "Municipios"
    label variable provincia          "Provincia"
    label variable tipo_fila          "Tipo de fila"
    *label variable n_municipios       "Número de municipios"
    label variable tasa_natalidad     "Tasa de Natalidad"
    label variable tasa_mortalidad    "Tasa de Mortalidad"
    label variable crec_vegetativo    "Crecimiento Vegetativo"
    label variable I_enve_T           "Índice de Envejecimiento"

    export excel ///
        nvl_label subregion provincia tipo_fila ///
        tasa_natalidad tasa_mortalidad crec_vegetativo I_enve_T ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("prom_natalidad_mortalidad") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* DEMOGRAFÍA
* Población por edades
********************************************************************/

*--------------------------------------------------
* 1. Importar población municipal desde Excel
*--------------------------------------------------
import excel "$rawdata/POBLACION MUNICIPAL.xlsx", firstrow clear sheet("Rangos_Quintenios")
keep if AÑO==2025
keep if ÁREAGEOGRÁFICA =="Total"
keep DPMP MPIO AÑO ÁREAGEOGRÁFICA TOTAL04 TOTAL59 TOTAL1014 TOTAL1519 TOTAL2024 TOTAL2529 TOTAL3034 TOTAL3539 TOTAL4044 TOTAL4549 TOTAL5054 TOTAL5559 TOTAL6064 TOTAL6569 TOTAL7074 TOTAL7579 TOTAL8084 TOTAL85ymás

rename DPMP ind_mpio
destring ind_mpio, replace

*--------------------------------------------------
* 2. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge


*--------------------------------------------------
* 3. Comprobar población total calculada
*--------------------------------------------------
egen pob_total_calc = rowtotal( ///
    TOTAL04 TOTAL59 TOTAL1014 TOTAL1519 TOTAL2024 TOTAL2529 ///
    TOTAL3034 TOTAL3539 TOTAL4044 TOTAL4549 TOTAL5054 TOTAL5559 ///
    TOTAL6064 TOTAL6569 TOTAL7074 TOTAL7579 TOTAL8084 TOTAL85ymás )

summ pob_total_calc

*--------------------------------------------------
* 4. Construir rangos de edad
*--------------------------------------------------
gen edad_0_9    = TOTAL04   + TOTAL59
gen edad_10_19  = TOTAL1014 + TOTAL1519
gen edad_20_29  = TOTAL2024 + TOTAL2529
gen edad_30_39  = TOTAL3034 + TOTAL3539
gen edad_40_49  = TOTAL4044 + TOTAL4549
gen edad_50_59  = TOTAL5054 + TOTAL5559
gen edad_60_69  = TOTAL6064 + TOTAL6569
gen edad_70_79  = TOTAL7074 + TOTAL7579
gen edad_80_mas = TOTAL8084 + TOTAL85ymás

foreach v in edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
             edad_40_49 edad_50_59 edad_60_69 edad_70_79 edad_80_mas {
    
    gen p_`v' = (`v' / pob_total_calc) * 100
}

*--------------------------------------------------
* 5. Labels
*--------------------------------------------------
label variable MPIO            "Municipios"
label variable provincia       "Provincia"
label variable p_edad_0_9      "0 a 9"
label variable p_edad_10_19    "10 a 19"
label variable p_edad_20_29    "20 a 29"
label variable p_edad_30_39    "30 a 39"
label variable p_edad_40_49    "40 a 49"
label variable p_edad_50_59    "50 a 59"
label variable p_edad_60_69    "60 a 69"
label variable p_edad_70_79    "70 a 79"
label variable p_edad_80_mas   "80 o más"

*--------------------------------------------------
* 8. Tabla estructura de edad: municipios + resumen provincia
*--------------------------------------------------
preserve

    keep subregion id_provincia provincia MPIO ///
         edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
         edad_40_49 edad_50_59 edad_60_69 edad_70_79 ///
         edad_80_mas

    * Base municipal
    gen tipo_fila = "Municipio"

    tempfile base total promedio subregiones
    save `base'

    * Base única de subregión por provincia
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *------------------------------
    * Total por provincia
    *------------------------------
    use `base', clear

    collapse ///
        (sum) edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
              edad_40_49 edad_50_59 edad_60_69 edad_70_79 ///
              edad_80_mas, ///
        by(id_provincia provincia)

    gen MPIO = "TOTAL " + upper(provincia)
    gen tipo_fila = "Total provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `total'

    *------------------------------
    * Promedio municipal por provincia
    *------------------------------
    use `base', clear

    collapse ///
        (mean) edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
               edad_40_49 edad_50_59 edad_60_69 edad_70_79 ///
               edad_80_mas, ///
        by(id_provincia provincia)

    gen MPIO = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio municipal"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *------------------------------
    * Unir todo
    *------------------------------
    use `base', clear
    append using `total'
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Total provincia"
    replace orden_fila = 3 if tipo_fila == "Promedio municipal"

    sort subregion id_provincia orden_fila MPIO

    *------------------------------
    * Labels
    *------------------------------
    label variable subregion     "Subregión"
    label variable MPIO          "Municipios"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"
    label variable edad_0_9      "0 a 9"
    label variable edad_10_19    "10 a 19"
    label variable edad_20_29    "20 a 29"
    label variable edad_30_39    "30 a 39"
    label variable edad_40_49    "40 a 49"
    label variable edad_50_59    "50 a 59"
    label variable edad_60_69    "60 a 69"
    label variable edad_70_79    "70 a 79"
    label variable edad_80_mas   "80 o más"

    export excel ///
        subregion MPIO provincia tipo_fila ///
        edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
        edad_40_49 edad_50_59 edad_60_69 edad_70_79 ///
        edad_80_mas ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("prom_estructura_edad") firstrow(varlabels) sheetreplace

restore


 	