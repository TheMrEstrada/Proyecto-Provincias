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
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

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

    keep subregion provincia area municipio habitantes participacion_pct ind_mpio 
    order municipio ind_mpio subregion provincia area habitantes participacion_pct

    label variable subregion "Subregión"
    *label variable esquema_asociativo "Esquema asociativo"
    label variable provincia "Provincia"
    label variable area "Área"
    label variable municipio "Municipio"
    label variable habitantes "Habitantes"
    label variable participacion_pct "%"
	label variable ind_mpio "Código DANE"

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

    * Totales provinciales por componente
    bysort provincia: egen total_provincia    = total(habitantes_total)
    bysort provincia: egen cabecera_provincia = total(habitantes_cabecera)
    bysort provincia: egen rural_provincia    = total(habitantes_rural)

    * Participación municipal en el total provincial
    gen part_total_prov = (habitantes_total / total_provincia) * 100
    gen part_cab_prov   = (habitantes_cabecera / cabecera_provincia) * 100
    gen part_rural_prov = (habitantes_rural / rural_provincia) * 100

    * Porcentaje urbano/rural dentro del municipio
    gen pct_cabecera = (habitantes_cabecera / habitantes_total) * 100
    gen pct_rural    = (habitantes_rural / habitantes_total) * 100

    format pct_cabecera pct_rural part_total_prov part_cab_prov part_rural_prov %6.1f

    order municipio ind_mpio provincia subregion habitantes_total part_total_prov ///
          habitantes_cabecera pct_cabecera part_cab_prov ///
          habitantes_rural pct_rural part_rural_prov
            

    label variable habitantes_total "Habitantes"
    label variable part_total_prov "Participación en el total provincial"
    label variable habitantes_cabecera "Población urbana"
    label variable pct_cabecera "Porcentaje de población urbana"
    label variable part_cab_prov "Participación en el total provincial"
    label variable habitantes_rural "Población rural"
    label variable pct_rural "Porcentaje de población rural"
    label variable part_rural_prov "Participación en el total provincial"
	label variable ind_mpio "Código DANE"

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

	label variable ind_mpio           "Código DANE"
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
        ind_mpio nvl_label subregion provincia tipo_fila ///
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

    keep ind_mpio subregion id_provincia provincia MPIO ///
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
	
	label variable ind_mpio     "Código DANE"
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
    ind_mpio subregion MPIO provincia tipo_fila ///
    edad_0_9 edad_10_19 edad_20_29 edad_30_39 ///
    edad_40_49 edad_50_59 edad_60_69 edad_70_79 ///
    edad_80_mas ///
    using "$output/tablas_provincias.xlsx", ///
    sheet("prom_estructura_edad") firstrow(varlabels) sheetreplace

restore


/********************************************************************
* GOBERNABILIDAD
********************************************************************/ 	
*--------------------------------------------------
* Tabla Medición Desempeño Municipal MDM
*--------------------------------------------------

*--------------------------------------------------
* 1. Importar población municipal desde Excel
*--------------------------------------------------
import excel "$data/i_datalake_ges_pub_dicc_2024.xlsx", firstrow clear sheet("Data")
*destring ind_mpio, replace

*--------------------------------------------------
* 2. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*--------------------------------------------------
* MDM
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia med_d_mun

    * Base municipal
    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    * Base única de subregión por provincia
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    *----------------------------------*
    * Promedio por provincia
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) med_d_mun ///
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
    label variable ind_mpio      "Código DANE"
    label variable nvl_label     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"
    label variable med_d_mun     "Medición de Desempeño Municipal"

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        med_d_mun ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("mdm") firstrow(varlabels) sheetreplace

restore


*--------------------------------------------------
* IDF
*--------------------------------------------------

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia idf

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) idf ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio      "Código DANE"
    label variable nvl_label     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"
    label variable idf           "Índice de Desempeño Fiscal"

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        idf ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("idf") firstrow(varlabels) sheetreplace

restore





****************************
*EMPLEO, POBREZA
*****
*--------------------------------------------------
* NBI, Línea de pobreza
*--------------------------------------------------

use "$data/ECV_nbi_pobreza.dta", clear

*--------------------------------------------------
* 2. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

*tabla
preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
         tot_pob_mon ///
         tot_pob_mon_hombres ///
         tot_pob_mon_mujeres

    rename NomMunicipio municipio

    *----------------------------------*
    * Base municipal
    *----------------------------------*
    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    * Base única de subregión
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
        tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
        tot_pob_mon ///
        tot_pob_mon_hombres ///
        tot_pob_mon_mujeres ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
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

    sort subregion id_provincia orden_fila municipio

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio               "Código DANE"
    label variable municipio              "Municipio"
    label variable subregion              "Subregión"
    label variable provincia              "Provincia"
    label variable tipo_fila              "Tipo de fila"

    label variable tot_pob_nbi            "Pobreza NBI total"
    label variable urb_pob_nbi            "Pobreza NBI urbana"
    label variable rur_pob_nbi            "Pobreza NBI rural"

    label variable tot_pob_mon            "Bajo Línea de Pobreza total"
    label variable tot_pob_mon_hombres    "Bajo Línea de Pobreza hombres"
    label variable tot_pob_mon_mujeres    "Bajo Línea de Pobreza mujeres"

    format tot_* urb_* rur_* %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_pob_nbi urb_pob_nbi rur_pob_nbi ///
        tot_pob_mon ///
        tot_pob_mon_hombres ///
        tot_pob_mon_mujeres ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_pobreza") firstrow(varlabels) sheetreplace

restore





*----------------------------------*
* Gini laboral - hogares
*----------------------------------*
preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_gini_hog urb_gini_hog rur_gini_hog ///
         tot_gini_lab urb_gini_lab rur_gini_lab

    rename NomMunicipio municipio

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) ///
        tot_gini_hog urb_gini_hog rur_gini_hog ///
        tot_gini_lab urb_gini_lab rur_gini_lab ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila municipio

    label variable ind_mpio      "Código DANE"
    label variable municipio     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"

    label variable tot_gini_hog  "Gini ingresos de los hogares total"
    label variable urb_gini_hog  "Gini ingresos de los hogares urbano"
    label variable rur_gini_hog  "Gini ingresos de los hogares rural"

    label variable tot_gini_lab  "Gini ingresos laborales total"
    label variable urb_gini_lab  "Gini ingresos laborales urbano"
    label variable rur_gini_lab  "Gini ingresos laborales rural"

    format tot_gini_* urb_gini_* rur_gini_* %6.3f

    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_gini_hog urb_gini_hog rur_gini_hog ///
        tot_gini_lab urb_gini_lab rur_gini_lab ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_gini") firstrow(varlabels) sheetreplace

restore


*----------------------------------*
* IPM - hogares/personas
*----------------------------------*

preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
         tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares

    rename NomMunicipio municipio

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
        tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila municipio

    label variable ind_mpio              "Código DANE"
    label variable municipio             "Municipio"
    label variable subregion             "Subregión"
    label variable provincia             "Provincia"
    label variable tipo_fila             "Tipo de fila"

    label variable tot_pob_ipm           "Personas pobres IPM total"
    label variable urb_pob_ipm           "Personas pobres IPM urbana"
    label variable rur_pob_ipm           "Personas pobres IPM rural"

    label variable tot_pob_ipm_hogares   "Hogares pobres IPM total"
    label variable urb_pob_ipm_hogares   "Hogares pobres IPM urbana"
    label variable rur_pob_ipm_hogares   "Hogares pobres IPM rural"

    format tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
           tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares %6.1f

    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_pob_ipm urb_pob_ipm rur_pob_ipm ///
        tot_pob_ipm_hogares urb_pob_ipm_hogares rur_pob_ipm_hogares ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_ipm") firstrow(varlabels) sheetreplace

restore


*-------------------------
* TO e Informalidad
*-------------------------

preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_to urb_to rur_to ///
         tot_emp_informal urb_emp_informal rur_emp_informal

    rename NomMunicipio municipio

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) ///
        tot_to urb_to rur_to ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila municipio

    label variable ind_mpio          "Código DANE"
    label variable municipio         "Municipio"
    label variable subregion         "Subregión"
    label variable provincia         "Provincia"
    label variable tipo_fila         "Tipo de fila"

    label variable tot_to            "Tasa de ocupación total"
    label variable urb_to            "Tasa de ocupación urbana"
    label variable rur_to            "Tasa de ocupación rural"

    label variable tot_emp_informal  "Tasa de empleo informal total"
    label variable urb_emp_informal  "Tasa de empleo informal urbana"
    label variable rur_emp_informal  "Tasa de empleo informal rural"

    format tot_to urb_to rur_to ///
           tot_emp_informal urb_emp_informal rur_emp_informal %6.1f

    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_to urb_to rur_to ///
        tot_emp_informal urb_emp_informal rur_emp_informal ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_ocupacion_informal") firstrow(varlabels) sheetreplace

restore

*-------------------------
* TD en jóvenes, nini
*-------------------------

preserve

    keep ind_mpio NomMunicipio subregion id_provincia provincia ///
         tot_td urb_td rur_td ///
         tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
         tot_nini urb_nini rur_nini

    rename NomMunicipio municipio

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) ///
        tot_td urb_td rur_td ///
        tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
        tot_nini urb_nini rur_nini ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen municipio = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila municipio

    label variable ind_mpio      "Código DANE"
    label variable municipio     "Municipio"
    label variable subregion     "Subregión"
    label variable provincia     "Provincia"
    label variable tipo_fila     "Tipo de fila"

    label variable tot_td        "Tasa de desocupación total"
    label variable urb_td        "Tasa de desocupación urbana"
    label variable rur_td        "Tasa de desocupación rural"

    label variable tot_td_15_28  "Tasa de desocupación 15-28 total"
    label variable urb_td_15_28  "Tasa de desocupación 15-28 urbana"
    label variable rur_td_15_28  "Tasa de desocupación 15-28 rural"

    label variable tot_nini      "Ninis total"
    label variable urb_nini      "Ninis urbano"
    label variable rur_nini      "Ninis rural"

    format tot_* urb_* rur_* %6.1f

    export excel ///
        ind_mpio municipio subregion provincia tipo_fila ///
        tot_td urb_td rur_td ///
        tot_td_15_28 urb_td_15_28 rur_td_15_28 ///
        tot_nini urb_nini rur_nini ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("ecv_desocupacion_nini") ///
        firstrow(varlabels) sheetreplace

restore


********************
** CLIMA **
**********************************


*-----------------
* IRCA
*-----------------
import excel "$rawdata/Indice de riesgo de calidad del agua (IRCA) 2024.xlsx", firstrow clear

drop if Municipio =="#TODOS"
rename MunicipioCodigo ind_mpio
destring ind_mpio, replace

keep ind_mpio IRCA IRCAurbano IRCArural

foreach v in IRCAurbano IRCArural {
    replace `v' = "" if `v' == "ND"
    destring `v', replace
}

*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         IRCA IRCAurbano IRCArural

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) IRCA IRCAurbano IRCArural ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"
    label variable IRCA        "IRCA total"
    label variable IRCAurbano  "IRCA urbano"
    label variable IRCArural   "IRCA rural"

    format IRCA IRCAurbano IRCArural %6.2f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IRCA IRCAurbano IRCArural ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("irca") firstrow(varlabels) sheetreplace

restore


*-----------------
* Índice de riesgo ajustado por capacidades (DEFICIT DE LLUVIAS)
*-----------------

import excel "$rawdata/Indice gestion capacidades 2024.xlsx", cellrange(A2) firstrow clear sheet("Deficit de Lluvias")

keep if Departamento =="ANTIOQUIA"
count

rename DIVIPOLA ind_mpio
destring ind_mpio, replace

rename Indicederiesgodedesastresaj IMRC_D
keep ind_mpio IMRC_D
label variable IMRC_D    "INDICE DE RIESGO DE DESASTRE AJUSTADO POR CAPACIDADES - DEFICIT DE LLUVIAS"


*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia IMRC_D

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
        (mean) IMRC_D ///
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

    label variable IMRC_D ///
        "Índice de Riesgo de Desastre Ajustado por Capacidades - Déficit de lluvias"

    format IMRC_D %6.2f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IMRC_D ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("imrc_deficit_lluvias") ///
        firstrow(varlabels) sheetreplace

restore




*-----------------
* Índice de riesgo ajustado por capacidades (EXCESO DE LLUVIAS)
*-----------------

import excel "$rawdata/Indice gestion capacidades 2024.xlsx", cellrange(A2) firstrow clear sheet("Exceso de Lluvias")

keep if Departamento =="ANTIOQUIA"
count

rename DIVIPOLA ind_mpio
destring ind_mpio, replace

rename Indicederiesgodedesastresaj IMRC_E
keep ind_mpio IMRC_E
label variable IMRC_E    "INDICE DE RIESGO DE DESASTRE AJUSTADO POR CAPACIDADES - EXCESO DE LLUVIAS"


*--------------------------------------------------
* 3. Merge con códigos/provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"

keep if _merge == 3
drop _merge

preserve

    keep ind_mpio nvl_label subregion id_provincia provincia IMRC_E

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'

    use `base', clear

    collapse ///
        (mean) IMRC_E ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    label variable ind_mpio    "Código DANE"
    label variable nvl_label   "Municipio"
    label variable subregion   "Subregión"
    label variable provincia   "Provincia"
    label variable tipo_fila   "Tipo de fila"

    label variable IMRC_E ///
        "Índice de Riesgo de Desastre Ajustado por Capacidades - Exceso de lluvias"

    format IMRC_E %6.2f

    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        IMRC_E ///
        using "$output/tablas_provincias.xlsx", ///
        sheet("imrc_exceso_lluvias") ///
        firstrow(varlabels) sheetreplace

restore
