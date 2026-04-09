cls
clear all
set more off

** Definir globals y directorios

global input "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS"
global output "C:/Users/aarenas/Proantioquia/Proantioquia Team Site - ACV/PRODUCTOS/EJERCICIO CLUSTERIZACIÓN MUNICIPAL ANTIOQUIA/DATOS/BASES HOMOGENEIZADAS"

** Importar datos

import excel "${input}/DATALAKE EDUCACION.xlsx", sheet("Sheet1") firstrow

** Conservar observaciones a nivel municipal

keep if UnidadGeográfica=="Municipal"

** Conservar indicadores priorizados

g ind_prior=.
	replace ind_prior=1 if Indicador=="Tasa de cobertura bruta en transición"
	replace ind_prior=1 if Indicador=="Tasa de cobertura bruta en primaria"
	replace ind_prior=1 if Indicador=="Tasa de repitencia en transición"
	replace ind_prior=1 if Indicador=="Tasa de repitencia en primaria"
	replace ind_prior=1 if Indicador=="Tasa de deserción intraanual en transición"
	replace ind_prior=1 if Indicador=="Tasa de deserción intraanual en primaria"
	replace ind_prior=1 if Indicador=="Tasa de cobertura bruta en secundaria"
	replace ind_prior=1 if Indicador=="Tasa de cobertura bruta en media"
	replace ind_prior=1 if Indicador=="Tasa de tránsito inmediato a educación superior"
	replace ind_prior=1 if Indicador=="Tasa de repitencia en secundaria"
	replace ind_prior=1 if Indicador=="Tasa de repitencia en media"
	replace ind_prior=1 if Indicador=="Tasa de deserción intraanual en secundaria"
	replace ind_prior=1 if Indicador=="Tasa de deserción intraanual en media"
	replace ind_prior=1 if Indicador=="Proporción de planteles en la clasificación C y D"
	replace ind_prior=1 if Indicador=="Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados"
	replace ind_prior=1 if Indicador=="Tasa de cobertura bruta en educación superior"

keep if ind_prior==1

** Conservar la observación más reciente de cada indicador

egen anno_max=max(Año), by(CódigoUnidadGeográfica Indicador)
g anno_prior=(anno_max==Año)

keep if anno_prior==1

** Conservar variables de interés

keep CódigoUnidadGeográfica NombreUnidadGeográfica Indicador DatoNumérico // UnidadGeográfica Año UnidaddeMedida Fuente CálculosPropios Observaciones

** Ajustar nombre de los indicadores

replace Indicador="clas_cole" if Indicador=="Proporción de planteles en la clasificación C y D"
replace Indicador="tcb_media" if Indicador=="Tasa de cobertura bruta en media"
replace Indicador="tcb_primaria" if Indicador=="Tasa de cobertura bruta en primaria"
replace Indicador="tcb_secundaria" if Indicador=="Tasa de cobertura bruta en secundaria"
replace Indicador="tcb_transicion" if Indicador=="Tasa de cobertura bruta en transición"
replace Indicador="tti_edsup" if Indicador=="Tasa de tránsito inmediato a educación superior"
replace Indicador="tcb_edsup" if Indicador=="Tasa de cobertura bruta en educación superior"
replace Indicador="tdes_media" if Indicador=="Tasa de deserción intraanual en media"
replace Indicador="tdes_primaria" if Indicador=="Tasa de deserción intraanual en primaria"
replace Indicador="tdes_secundaria" if Indicador=="Tasa de deserción intraanual en secundaria"
replace Indicador="tdes_transicion" if Indicador=="Tasa de deserción intraanual en transición"
replace Indicador="trep_media" if Indicador=="Tasa de repitencia en media"
replace Indicador="trep_primaria" if Indicador=="Tasa de repitencia en primaria"
replace Indicador="trep_secundaria" if Indicador=="Tasa de repitencia en secundaria"
replace Indicador="trep_transicion" if Indicador=="Tasa de repitencia en transición"
replace Indicador="ninis" if Indicador=="Jóvenes entre 15 y 28 años que no estudian ni se encuentran ocupados"

** Asignar formato a los valores

format DatoNumérico %4.1f

** Transformar datos en estructura amplia

ren DatoNumérico x_
reshape wide x_, i(CódigoUnidadGeográfica) j(Indicador) string
renvars *, subst(x_ )
order NombreUnidadGeográfica, after(CódigoUnidadGeográfica)

** Homegeneización nombre de variables

ren (CódigoUnidadGeográfica NombreUnidadGeográfica) (ind_mpio nvl_label)

** Guardar base de datos

compress
export excel using "${output}/20250506 EDUCACION.xlsx", firstrow(variables) replace
