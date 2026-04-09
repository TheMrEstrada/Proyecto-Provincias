cls
clear all
set more off

** Definir globals y directorios

global input "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS"
global output "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS/BASES HOMOGENEIZADAS"

** Importar datos

import excel "${input}/DATALAKE DEyC.xlsx", sheet("Sheet1") firstrow

** Conservar observaciones a nivel municipal

keep if UnidadGeográfica=="Municipal"

** Conservar indicadores priorizados

g ind_prior=.
	replace ind_prior=1 if Indicador=="Valor agregado per capita"
	replace ind_prior=1 if Indicador=="Participacion por actidad economica del Valor agregado - Actividades Primarias"
	replace ind_prior=1 if Indicador=="Número de corresponsalespor cada 1.000 habitantes" // Este puede requerir serie de tiempo
	replace ind_prior=1 if Indicador=="Número de microcréditopor cada 1.000 habitantes" // Este puede requerir serie de tiempo
	replace ind_prior=1 if Indicador=="Porcentaje de viviendas con servicio de conexión a internet"
	replace ind_prior=1 if Indicador=="Tasa de natalidad empresarial neta" 
	replace ind_prior=1 if Indicador=="Densidad empresarial (número de empresas por cada mil habitantes)"
	replace ind_prior=1 if Indicador=="Porcentaje de personas afiliadas al sistema de seguridad social en salud: Mujer"
	replace ind_prior=1 if Indicador=="Porcentaje de personas afiliadas al sistema de seguridad social en salud: Hombre"
	replace ind_prior=1 if Indicador=="Porcentaje de personas ocupadas que tienen afiliación al sistema de pensiones como cotizantes: Hombre"
	replace ind_prior=1 if Indicador=="Porcentaje de personas ocupadas que tienen afiliación al sistema de pensiones como cotizantes: Mujer"

keep if ind_prior==1

** Conservar la observación más reciente de cada indicador

egen anno_max=max(Año), by(CódigoUnidadGeográfica Indicador)
g anno_prior=(anno_max==Año)

keep if anno_prior==1

** Conservar variables de interés

keep CódigoUnidadGeográfica /*NombreUnidadGeográfica*/ Indicador DatoNumérico // UnidadGeográfica Año UnidaddeMedida Fuente CálculosPropios Observaciones

** Ajustar nombre de los indicadores

replace Indicador="fin_banc_pc" if Indicador=="Número de corresponsalespor cada 1.000 habitantes"
replace Indicador="fin_microcr_pc" if Indicador=="Número de microcréditopor cada 1.000 habitantes"
replace Indicador="internet" if Indicador=="Porcentaje de viviendas con servicio de conexión a internet"
replace Indicador="dens_emp" if Indicador=="Densidad empresarial (número de empresas por cada mil habitantes)"
replace Indicador="ss_salud_hombres" if Indicador=="Porcentaje de personas afiliadas al sistema de seguridad social en salud: Hombre"
replace Indicador="ss_salud_mujeres" if Indicador=="Porcentaje de personas afiliadas al sistema de seguridad social en salud: Mujer"
replace Indicador="ss_pension_hombres" if Indicador=="Porcentaje de personas ocupadas que tienen afiliación al sistema de pensiones como cotizantes: Hombre"
replace Indicador="ss_pension_mujeres" if Indicador=="Porcentaje de personas ocupadas que tienen afiliación al sistema de pensiones como cotizantes: Mujer"
replace Indicador="va_pc" if Indicador=="Valor agregado per capita"
replace Indicador="va_primario" if Indicador=="Participacion por actidad economica del Valor agregado - Actividades Primarias"
replace Indicador="tnat_emp" if Indicador=="Tasa de natalidad empresarial neta"

** Asignar formato a los valores

format DatoNumérico %4.1f

** Transformar datos en estructura amplia

ren DatoNumérico x_
reshape wide x_, i(CódigoUnidadGeográfica) j(Indicador) string
renvars *, subst(x_ )
* order NombreUnidadGeográfica, after(CódigoUnidadGeográfica)

** Homegeneización nombre de variables

ren (CódigoUnidadGeográfica /*NombreUnidadGeográfica*/) (ind_mpio /*nvl_label*/)

** Guardar base de datos

compress
export excel using "${output}/20250506 DEyC.xlsx", firstrow(variables) replace
