* ----------------------------------------------------------------------------
* HOMOGENEIZACION - percepcion_seguridad.do
* OBJETIVO: reducir el microdato crudo de la encuesta de percepcion ciudadana
*           2018-2025 (1363 columnas, ~105 MB) a las 8 columnas que usa el
*           flujo, y guardarlo como derivado liviano. Asi el import lento del
*           archivo grande ocurre UNA sola vez (etapa de homogenizacion) y el
*           sectorial 10_Seguridad lee el derivado (rapido).
* FUENTE:   01_Data/00_Inputs/Data anonimizada encuesta percepcion 2018-2025.xlsx
*           (hoja "Data_033200250000 Perc2018-2025"; doble encabezado, nombres
*            cortos en la fila 2 -> cellrange(A2)).
* SALIDA:   01_Data/01_Derived/percepcion_seguridad.dta  (+ .xlsx de respaldo)
*           Microdato por entrevista, TODAS las subregiones (para que el flujo
*           funcione con cualquier $id_provincia). NO se preagrega: el "periodo"
*           y las proporciones ponderadas se calculan en el flujo, tras filtrar
*           la subregion, para no alterar resultados.
* COLUMNAS: ESTUDIO FECHAINI B_SUBREGION P1A P2 P4A P6 FACTOR_PONDERACION
* NOTA: paths locales; correr una vez (etapa de homogenizacion) antes del flujo.
* ----------------------------------------------------------------------------

clear all
set more off

global rawdata "D:\IA Provincias\Proyecto datos y tablas\01_Data\00_Inputs"
global data    "D:\IA Provincias\Proyecto datos y tablas\01_Data\01_Derived"

* --- Importar el microdato crudo (nombres cortos en la fila 2). Lento: 1363
*     columnas / ~105 MB. Por eso se hace aqui una sola vez. ---
import excel "$rawdata/Data anonimizada encuesta percepcion 2018-2025.xlsx", ///
    sheet("Data_033200250000 Perc2018-2025") cellrange(A2) firstrow clear

* --- Quedarse solo con lo que usa el flujo ---
keep ESTUDIO FECHAINI B_SUBREGION P1A P2 P4A P6 FACTOR_PONDERACION
destring B_SUBREGION FACTOR_PONDERACION P1A P2 P4A P6, replace force

* FECHAINI se deja como string (DMY): el flujo hace date(FECHAINI,"DMY").

label variable ESTUDIO            "Codigo del estudio"
label variable FECHAINI           "Fecha inicio entrevista (DMY)"
label variable B_SUBREGION        "Subregion (1-9)"
label variable P1A                "P1A percepcion barrio/vereda"
label variable P2                 "P2 cambio barrio/vereda"
label variable P4A                "P4A percepcion municipio"
label variable P6                 "P6 cambio municipio"
label variable FACTOR_PONDERACION "Factor de ponderacion"

order ESTUDIO FECHAINI B_SUBREGION P1A P2 P4A P6 FACTOR_PONDERACION

save "$data/percepcion_seguridad.dta", replace
export excel using "$data/percepcion_seguridad.xlsx", firstrow(variables) replace

di as text "  percepcion_seguridad: derivado guardado en $data/ (" _N " filas)"
