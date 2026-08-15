* ----------------------------------------------------------------------------
* PROVINCIAS - 02_Tablas_Gobernanza.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/tablas_gobernanza.xlsx
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"


/********************************************************************
* Gobernanza - IMCA 2022
********************************************************************/

import excel "$data/imca_2022.xlsx", firstrow clear

* Mantener ind_mpio como string
tostring ind_mpio, replace force
replace ind_mpio = strtrim(ind_mpio)

* Identificar niveles
gen es_depto = inlist(ind_mpio, "5", "05")
gen es_subregion_base = regexm(ind_mpio, "^SR")
gen es_mpio = !es_depto & !es_subregion_base

* Código auxiliar numérico solo para municipios
gen ind_mpio_num = real(ind_mpio) if es_mpio

tempfile original municipios_full subreg_base depto_base base promedio
save `original'

*--------------------------------------------------
* Merge con subregiones para municipios
*--------------------------------------------------
use `original', clear
keep if es_mpio

rename ind_mpio ind_mpio_str
rename ind_mpio_num ind_mpio

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

rename ind_mpio ind_mpio_num
rename ind_mpio_str ind_mpio

save `municipios_full'

*--------------------------------------------------
* Filas SR que ya trae la base
*--------------------------------------------------
use `original', clear
keep if es_subregion_base

gen subregion = ""
replace subregion = "VALLE DE ABURRÁ" if ind_mpio == "SR01"
replace subregion = "BAJO CAUCA"      if ind_mpio == "SR02"
replace subregion = "MAGDALENA MEDIO" if ind_mpio == "SR03"
replace subregion = "NORDESTE"        if ind_mpio == "SR04"
replace subregion = "NORTE"           if ind_mpio == "SR05"
replace subregion = "OCCIDENTE"       if ind_mpio == "SR06"
replace subregion = "ORIENTE"         if ind_mpio == "SR07"
replace subregion = "SUROESTE"        if ind_mpio == "SR08"
replace subregion = "URABÁ"           if ind_mpio == "SR09"

gen nvl_label = "TOTAL " + subregion
gen tipo_fila = "Total subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `subreg_base'

*--------------------------------------------------
* Fila departamental que ya viene en la base
*--------------------------------------------------
use `original', clear
keep if es_depto

gen nvl_label = "TOTAL DEPARTAMENTAL"
gen tipo_fila = "Total departamento"
gen subregion = "TOTAL DEPARTAMENTO"
gen provincia = "TOTAL DEPARTAMENTO"
gen id_provincia = .

save `depto_base'

*--------------------------------------------------
* Municipios con provincia
*--------------------------------------------------
use `municipios_full', clear

rename ind_mpio ind_mpio_str
rename ind_mpio_num ind_mpio

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge == 3
drop _merge

rename ind_mpio ind_mpio_num
rename ind_mpio_str ind_mpio

gen tipo_fila = "Municipio"

save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
           imca_infraestructura imca_innovacion imca_instituciones ///
           imca_merc_bienes imca_merc_laboral imca_salud ///
           imca_sist_financiero imca_tam_mercado ///
    (count) n_municipios = ind_mpio_num, ///
    by(id_provincia provincia)

gen ind_mpio = ""
gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen subregion = "TOTAL PROVINCIA"

save `promedio'

*--------------------------------------------------
* Unir todo
*--------------------------------------------------
use `base', clear
append using `promedio'
append using `subreg_base'
append using `depto_base'

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Total subregión"
replace orden_fila = 4 if tipo_fila == "Total departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas
*--------------------------------------------------
label variable ind_mpio       "Código DANE"
label variable nvl_label      "Municipio"
label variable subregion      "Subregión"
label variable provincia      "Provincia"
label variable tipo_fila      "Tipo de fila"

label variable imca_total            "IMCA total"
label variable imca_adop_tic         "IMCA adopción TIC"
label variable imca_capacidades      "IMCA capacidades"
label variable imca_dinam_neg        "IMCA dinamismo de los negocios"
label variable imca_infraestructura  "IMCA infraestructura"
label variable imca_innovacion       "IMCA innovación"
label variable imca_instituciones    "IMCA instituciones"
label variable imca_merc_bienes      "IMCA mercado de bienes"
label variable imca_merc_laboral     "IMCA mercado laboral"
label variable imca_salud            "IMCA salud"
label variable imca_sist_financiero  "IMCA sistema financiero"
label variable imca_tam_mercado      "IMCA tamaño del mercado"

format imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
       imca_infraestructura imca_innovacion imca_instituciones ///
       imca_merc_bienes imca_merc_laboral imca_salud ///
       imca_sist_financiero imca_tam_mercado %12.2f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    imca_total imca_adop_tic imca_capacidades imca_dinam_neg ///
    imca_infraestructura imca_innovacion imca_instituciones ///
    imca_merc_bienes imca_merc_laboral imca_salud ///
    imca_sist_financiero imca_tam_mercado ///
    using "$output/tablas_gobernanza.xlsx", ///
    sheet("imca_2022") firstrow(varlabels) sheetreplace
	
	
/********************************************************************
* Educación
* Tasa de tránsito inmediato a educación superior
********************************************************************/

import excel "$data/20250506 EDUCACION.xlsx", firstrow clear

*--------------------------------------------------
* Merge con subregiones
*--------------------------------------------------

merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

*--------------------------------------------------
* Merge con provincias
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
keep if _merge==3
drop _merge

*--------------------------------------------------
* Base municipal
*--------------------------------------------------
keep ind_mpio nvl_label subregion id_provincia provincia tti_edsup

gen tipo_fila = "Municipio"

tempfile base promedio
save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) tti_edsup ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen ind_mpio = .
gen nvl_label = "PROMEDIO " + upper(provincia)
gen tipo_fila = "Promedio provincia"
gen subregion = "TOTAL PROVINCIA"

save `promedio'

*--------------------------------------------------
* Unir municipios y promedio
*--------------------------------------------------
use `base', clear
append using `promedio'

gen orden_fila = 1 if tipo_fila=="Municipio"
replace orden_fila = 2 if tipo_fila=="Promedio provincia"

sort id_provincia orden_fila nvl_label

*--------------------------------------------------
* Labels
*--------------------------------------------------
label variable ind_mpio   "Código DANE"
label variable nvl_label  "Municipio"
label variable subregion  "Subregión"
label variable provincia  "Provincia"
label variable tipo_fila  "Tipo de fila"

label variable tti_edsup ///
    "Tasa de tránsito inmediato a educación superior"

format tti_edsup %6.1f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    tti_edsup ///
    using "$output/tablas_gobernanza.xlsx", ///
    sheet("tti_edsup") ///
    firstrow(varlabels) sheetreplace


	
* Infraestructura internet
use "${data}/infraestructura_internet_2025.dta", clear	

* Servicios de internet fijo activos
keep if servicio_paquete == "Internet fijo"
keep if estado == "Activo en funcionamiento"

* Agrupar distintas categorías de fibra
gen fibra = strpos(tecnologia, "Fiber to the") > 0 | ///
            tecnologia == "Otras tecnologías de fibra (antes FTTx)"

* Colapsar a municipio x fibra
collapse (sum) cantidad_lineas_accesos, by(ind_mpio municipio fibra)

* Total municipal
bys ind_mpio: egen lineas_totales = total(cantidad_lineas_accesos)

* Dejar solo fibra
keep if fibra == 1

rename cantidad_lineas_accesos lineas_fibra

* Participación de fibra
gen prop_fibra = lineas_fibra / lineas_totales

keep ind_mpio municipio lineas_totales lineas_fibra prop_fibra

**** Tasa de penetración por cada 1000 habitantes
merge 1:m ind_mpio using "$data/poblacion_total_2025.dta"
keep if area_geo =="Total"
rename Total poblacion
drop _merge


***
*Líneas de acceso a internet fijo por cada 1.000 habitantes 
gen internet_1000hab = lineas_totales/poblacion*1000


*--------------------------------------------------
* Merge con subregión y provincia
*--------------------------------------------------
merge m:1 ind_mpio using "$rawdata/Códigos_municipios_clean.dta"
drop esquema_asociativo
drop _merge

merge m:1 ind_mpio using "$rawdata/códigos_provincias.dta"
drop if _merge == 2
drop _merge

gen tipo_fila = "Municipio"

tempfile base prom_prov prom_subreg prom_depto
save `base'

*--------------------------------------------------
* Resumen provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) lineas_totales lineas_fibra internet_1000hab ///
    (sum) lineas_fibra_sum = lineas_fibra ///
          lineas_totales_sum = lineas_totales ///
    (count) n_municipios = ind_mpio, ///
    by(id_provincia provincia)

gen prop_fibra = lineas_fibra_sum / lineas_totales_sum

drop lineas_fibra_sum lineas_totales_sum

gen ind_mpio = .
gen municipio = ""
gen nvl_label = "RESUMEN " + upper(provincia)
gen tipo_fila = "Resumen provincia"
gen subregion = "TOTAL PROVINCIA"

save `prom_prov'

*--------------------------------------------------
* Resumen subregional
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) lineas_totales lineas_fibra internet_1000hab ///
    (sum) lineas_fibra_sum = lineas_fibra ///
          lineas_totales_sum = lineas_totales ///
    (count) n_municipios = ind_mpio, ///
    by(subregion)

gen prop_fibra = lineas_fibra_sum / lineas_totales_sum

drop lineas_fibra_sum lineas_totales_sum

gen ind_mpio = .
gen municipio = ""
gen nvl_label = "RESUMEN " + upper(subregion)
gen tipo_fila = "Resumen subregión"
gen provincia = "SIN PROVINCIA"
gen id_provincia = .

save `prom_subreg'

*--------------------------------------------------
* Resumen departamental
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) lineas_totales lineas_fibra internet_1000hab ///
    (sum) lineas_fibra_sum = lineas_fibra ///
          lineas_totales_sum = lineas_totales ///
    (count) n_municipios = ind_mpio

gen prop_fibra = lineas_fibra_sum / lineas_totales_sum

drop lineas_fibra_sum lineas_totales_sum

gen ind_mpio = .
gen municipio = ""
gen nvl_label = "RESUMEN DEPARTAMENTAL"
gen tipo_fila = "Resumen departamento"
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

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Resumen provincia"
replace orden_fila = 3 if tipo_fila == "Resumen subregión"
replace orden_fila = 4 if tipo_fila == "Resumen departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas y formato
*--------------------------------------------------
label variable ind_mpio         "Código DANE"
label variable nvl_label        "Municipio"
label variable subregion        "Subregión"
label variable provincia        "Provincia"
label variable tipo_fila        "Tipo de fila"

label variable lineas_totales   "Líneas de acceso a internet fijo"
label variable lineas_fibra     "Líneas de acceso a internet fijo por fibra"
label variable prop_fibra       "Proporción de líneas sobre fibra óptica"
label variable internet_1000hab "Líneas de acceso a internet fijo por cada 1.000 habitantes"
label variable n_municipios     "Número de municipios"

format lineas_totales lineas_fibra %12.0fc
format prop_fibra %12.3f
format internet_1000hab %12.2f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    lineas_totales lineas_fibra prop_fibra internet_1000hab n_municipios ///
    using "$output/tablas_gobernanza.xlsx", ///
    sheet("internet_2025") firstrow(varlabels) sheetreplace
	
	
	
*******************
* ÍNDICE DE GOBIERNO DIGITAL
**************************

/********************************************************************
* Gobierno digital - FURAG 2024
********************************************************************/

import excel "$rawdata/Indice_gobierno_digital_2024.xlsx", ///
    sheet("Medición_desempeño") cellrange(A5) firstrow clear

* Renombrar variables clave
rename IdMunicipio ind_mpio
rename Municipio municipio

* Quedarse solo con Antioquia
keep if IdDepartamento == 5

* Limpiar nombres
replace municipio = strtrim(municipio)

keep if NaturalezaJurídica == "ALCALDÍA"

* Mantener variables relevantes
keep ind_mpio municipio ///
ÍndicedeGobiernoDigital Gobernanza InnovaciónPúblicaDigital Arquitectura SeguridadyPrivacidaddelainf ServiciosCiudadanosDigitales Culturayapropiación ServiciosyProcesosInteligente Estadoabierto Decisionesbasadasendatos ProyectosdeTransformaciónDigi EstrategiasdeCiudadesyTerrit

* Renombrar variables
rename ÍndicedeGobiernoDigital         gobierno_digital
rename Gobernanza                      gobernanza
rename InnovaciónPúblicaDigital        innovacion_digital
rename Arquitectura                    arquitectura
rename SeguridadyPrivacidaddelainf     seguridad_privacidad
rename ServiciosCiudadanosDigitales    servicios_ciudadanos
rename Culturayapropiación             cultura_apropiacion
rename ServiciosyProcesosInteligente   servicios_inteligentes
rename Estadoabierto                   estado_abierto
rename Decisionesbasadasendatos        decisiones_datos
rename ProyectosdeTransformaciónDigi   proyectos_transformacion
rename EstrategiasdeCiudadesyTerrit    ciudades_territorios

* Guardar
save "${data}/indice_gobierno_digital_2024.dta", replace	



/********************************************************************
* Gobernanza - Índice de Gobierno Digital 2024
********************************************************************/

use "${data}/indice_gobierno_digital_2024.dta", clear

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
drop if _merge == 2
drop _merge

gen tipo_fila = "Municipio"

tempfile base prom_prov prom_subreg prom_depto
save `base'

*--------------------------------------------------
* Promedio provincial
*--------------------------------------------------
use `base', clear

collapse ///
    (mean) gobierno_digital gobernanza innovacion_digital ///
           arquitectura seguridad_privacidad ///
           servicios_ciudadanos cultura_apropiacion ///
           servicios_inteligentes estado_abierto ///
           decisiones_datos proyectos_transformacion ///
           ciudades_territorios ///
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
    (mean) gobierno_digital gobernanza innovacion_digital ///
           arquitectura seguridad_privacidad ///
           servicios_ciudadanos cultura_apropiacion ///
           servicios_inteligentes estado_abierto ///
           decisiones_datos proyectos_transformacion ///
           ciudades_territorios ///
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
    (mean) gobierno_digital gobernanza innovacion_digital ///
           arquitectura seguridad_privacidad ///
           servicios_ciudadanos cultura_apropiacion ///
           servicios_inteligentes estado_abierto ///
           decisiones_datos proyectos_transformacion ///
           ciudades_territorios ///
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

gen orden_fila = 1 if tipo_fila == "Municipio"
replace orden_fila = 2 if tipo_fila == "Promedio provincia"
replace orden_fila = 3 if tipo_fila == "Promedio subregión"
replace orden_fila = 4 if tipo_fila == "Promedio departamento"

sort subregion id_provincia orden_fila nvl_label

*--------------------------------------------------
* Etiquetas
*--------------------------------------------------
label variable ind_mpio        "Código DANE"
label variable nvl_label       "Municipio"
label variable subregion       "Subregión"
label variable provincia       "Provincia"
label variable tipo_fila       "Tipo de fila"
label variable n_municipios    "Número de municipios"

label variable gobierno_digital          "Índice de Gobierno Digital"
label variable gobernanza                "Gobernanza"
label variable innovacion_digital        "Innovación Pública Digital"
label variable arquitectura              "Arquitectura"
label variable seguridad_privacidad      "Seguridad y Privacidad de la información"
label variable servicios_ciudadanos      "Servicios Ciudadanos Digitales"
label variable cultura_apropiacion       "Cultura y apropiación"
label variable servicios_inteligentes    "Servicios y Procesos Inteligentes"
label variable estado_abierto            "Estado abierto"
label variable decisiones_datos          "Decisiones basadas en datos"
label variable proyectos_transformacion  "Proyectos de Transformación Digital"
label variable ciudades_territorios      "Estrategias de Ciudades y Territorios Inteligentes"

format gobierno_digital gobernanza innovacion_digital ///
       arquitectura seguridad_privacidad servicios_ciudadanos ///
       cultura_apropiacion servicios_inteligentes estado_abierto ///
       decisiones_datos proyectos_transformacion ciudades_territorios %12.2f

*--------------------------------------------------
* Exportar
*--------------------------------------------------
export excel ///
    ind_mpio nvl_label subregion provincia tipo_fila ///
    gobierno_digital gobernanza innovacion_digital ///
    arquitectura seguridad_privacidad servicios_ciudadanos ///
    cultura_apropiacion servicios_inteligentes estado_abierto ///
    decisiones_datos proyectos_transformacion ciudades_territorios ///
    n_municipios ///
    using "$output/tablas_gobernanza.xlsx", ///
    sheet("gobierno_digital_2024") firstrow(varlabels) sheetreplace