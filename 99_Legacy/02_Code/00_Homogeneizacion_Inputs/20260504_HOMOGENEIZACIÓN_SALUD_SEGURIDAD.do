* ----------------------------------------------------------------------------
* PROVINCIAS - 20260504_HOMOGENEIZACIÓN_SALUD_SEGURIDAD.do
* HOMOGENEIZACIÓN DE INPUTS
* OBJETIVO : Importar indicadores municipales y crear tablas resumen
* INPUTS   : $data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx
*            $rawdata/NATALIDAD.xlsx
*            $rawdata/DATOS SALUD.xlsx
* OUTPUTS  : $data/20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx (.dta)
* AUTORA   : Laura
* CREADO   : 2026-05-04
* ----------------------------------------------------------------------------

clear all
set more off

* ============================================================================
* 0. CONFIGURACIÓN DE DIRECTORIOS
* ============================================================================

global path     "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
global rawdata  "$path/01_Data/00_Inputs"
global scripts  "$path/02_Code"
global data     "$path/01_Data/01_Derived"
global output   "$path/03_Outputs"

* Archivo principal de trabajo
* (actualización del archivo 20250505 con datos 2026)
local master "20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA"

* Orden canónico de variables (definido una sola vez para reusar)
* Se usa en cada bloque con:  order `varorder'
local varorder ind_mpio nvl_label                                   ///
    tasa_natalidad tasa_mortalidad crec_vegetativo                  ///
    percepción_seguridad tasa_delitos IRV                           ///
    VBG VBG_jovenes VBG_adolescentes homicidios                     ///
    vinculacion_nna mortalidad_desnutrición                         ///
    bajo_peso desnutrición_aguda controles_prenatales               ///
    fecundidad_niñas fecundidad_adolescentes camas                  ///
    IRA dengue malaria leishmaniasis                                ///
    acueducto_rural alcantarillado_rural                            ///
    acueducto_urbano alcantarillado_urbano                          ///
    deficit_cuali deficit_cuanti                                    ///
    hacinamiento_rural hacinamiento_urbano                          ///
    Población_2023 IRCC afectados_dn perdida_ca

* ============================================================================
* 1. CARGAR ARCHIVO MAESTRO Y GUARDAR COMO .DTA
* ============================================================================

import excel "$data/`master'", sheet("Data") firstrow clear
save "$data/`master'", replace

* ============================================================================
* 2. CARGAR POBLACIÓN MUNICIPAL
* ============================================================================

import excel "$data/poblacion_municipal_total_2025_dicc", sheet("Data") firstrow clear
save "$data/poblacion_municipal_total_2025_dicc", replace

* ============================================================================
* 3. INCORPORAR TASA DE NATALIDAD
* ============================================================================

import excel "$rawdata/NATALIDAD.xlsx", sheet("Natalidad total") clear

* Conservar solo columnas relevantes y eliminar filas de encabezado
keep A AL AM
drop in 1/3
rename A  ind_mpio
rename AL tasa_natalidad

* Filtrar solo municipios (código DIVIPOLA de 5 dígitos)
keep if length(ind_mpio) == 5
destring tasa_natalidad, replace
keep ind_mpio tasa_natalidad

merge 1:1 ind_mpio using "$data/`master'"
drop if _merge == 1   // municipios sin match en maestro
drop _merge

* Reordenar (tasa_mortalidad y crec_vegetativo aún no existen; Stata los ignora)
order `varorder'
save "$data/`master'", replace

export excel using "$data/`master'.xlsx",                 ///
    sheet("Data") cell(A1) firstrow(varlabels) sheetreplace

* ============================================================================
* 4. INCORPORAR TASA DE MORTALIDAD Y CALCULAR CRECIMIENTO VEGETATIVO
* ============================================================================

import excel "$rawdata/DATOS SALUD.xlsx", sheet("tasa mortalidad general") clear

* Conservar solo columnas relevantes y eliminar filas de encabezado
keep B AQ
drop in 1/4
rename B  ind_mpio
rename AQ tasa_mortalidad

* Filtrar solo municipios (código DIVIPOLA de 5 dígitos)
keep if length(ind_mpio) == 5
destring tasa_mortalidad, replace
keep ind_mpio tasa_mortalidad

merge 1:1 ind_mpio using "$data/`master'"
drop if _merge == 1   // municipios sin match en maestro
drop _merge

* Crecimiento vegetativo = natalidad - mortalidad
generate crec_vegetativo = tasa_natalidad - tasa_mortalidad
label variable crec_vegetativo "Crecimiento vegetativo (por mil)"

* Convertir código municipal a numérico para compatibilidad
destring ind_mpio, replace

order `varorder'
save "$data/`master'", replace

export excel using "$data/`master'.xlsx",                 ///
    sheet("Data") cell(A1) firstrow(varlabels) sheetreplace