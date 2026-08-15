* ----------------------------------------------------------------------------
* PROVINCIAS - 00_master.do
* PRODUCCION DE TABLAS PARA DIAGNOSTICO TERRITORIAL
* OBJETIVO: Orquestar la produccion de todas las tablas base para las figuras
*           del diagnostico de contexto territorial de una provincia especifica
* OUTPUTS: 03_Outputs/<provincia>/  (carpeta con subcarpetas por seccion)
* ----------------------------------------------------------------------------

clear all
set more off

* ============================================================================
* 1. CONFIGURACION DE DIRECTORIOS
*    NOTA: Ajustar la ruta base segun usuario local
* ============================================================================

	global path "D:\IA Provincias\Proyecto datos y tablas" // Hay que cambiar este path para poder ejecutar todo
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code/Tablas_Diagnostico"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"

* ============================================================================
* 2. SELECCION DE PROVINCIA
*    Cambiar id_provincia para generar tablas de otra provincia.
*    IDs disponibles:
*        1 = Agroindustrial del Occidente
*        2 = Bioenergetica del Norte de Antioquia
*        3 = Del Rio Grande
*        4 = Turistica y Agroecologica
*        5 = Agua, Bosques y Turismo
*        6 = Cartama
*        7 = De la Paz
*        8 = San Juan
*        9 = Minero Agroecologica
*       10 = Penderisco y Sinifana
*       11 = Area Metropolitana
* ============================================================================

	global id_provincia 4


* ============================================================================
* 3. DERIVAR NOMBRES DE PROVINCIA (no modificar)
* ============================================================================

* Nombre tal como aparece en los archivos de datos (columna prov)
if $id_provincia == 1  global provincia_nombre "PROVINCIA AGROINDUSTRIAL DEL OCCIDENTE"
if $id_provincia == 2  global provincia_nombre "PROVINCIA BIOENERGETICA DEL NORTE DE ANTIOQUIA"
if $id_provincia == 3  global provincia_nombre "PROVINCIA DEL RIO GRANDE"
if $id_provincia == 4  global provincia_nombre "PROVINCIA TURISTICA Y AGROECOLOGICA"
if $id_provincia == 5  global provincia_nombre "POVINCIA DEL AGUA, BOSQUES Y TURISMO"
if $id_provincia == 6  global provincia_nombre "PROVINCIA CARTAMA"
if $id_provincia == 7  global provincia_nombre "PROVINCIA DE LA PAZ"
if $id_provincia == 8  global provincia_nombre "PROVINCIA DE SAN JUAN"
if $id_provincia == 9  global provincia_nombre "PROVINCIA MINERO AGROECOLOGICA"
if $id_provincia == 10 global provincia_nombre "PROVINCIA PENDERISCO Y SINIFANA"
if $id_provincia == 11 global provincia_nombre "AREA METROPOLITANA"

* Nombre corto para carpetas de salida
if $id_provincia == 1  global provincia_carpeta "Agroindustrial_Occidente"
if $id_provincia == 2  global provincia_carpeta "Bioenergetica_Norte"
if $id_provincia == 3  global provincia_carpeta "Rio_Grande"
if $id_provincia == 4  global provincia_carpeta "Turistica_Agroecologica"
if $id_provincia == 5  global provincia_carpeta "Agua_Bosques_Turismo"
if $id_provincia == 6  global provincia_carpeta "Cartama"
if $id_provincia == 7  global provincia_carpeta "De_la_Paz"
if $id_provincia == 8  global provincia_carpeta "San_Juan"
if $id_provincia == 9  global provincia_carpeta "Minero_Agroecologica"
if $id_provincia == 10 global provincia_carpeta "Penderisco_Sinifana"
if $id_provincia == 11 global provincia_carpeta "Area_Metropolitana"

* Nombre legible para labels en tablas
if $id_provincia == 1  global provincia_label "Agroindustrial del Occidente"
if $id_provincia == 2  global provincia_label "Bioenergetica del Norte de Antioquia"
if $id_provincia == 3  global provincia_label "Del Rio Grande"
if $id_provincia == 4  global provincia_label "Turistica y Agroecologica"
if $id_provincia == 5  global provincia_label "Agua, Bosques y Turismo"
if $id_provincia == 6  global provincia_label "Cartama"
if $id_provincia == 7  global provincia_label "De la Paz"
if $id_provincia == 8  global provincia_label "San Juan"
if $id_provincia == 9  global provincia_label "Minero Agroecologica"
if $id_provincia == 10 global provincia_label "Penderisco y Sinifana"
if $id_provincia == 11 global provincia_label "Area Metropolitana"

di as text "=========================================="
di as text "  Provincia seleccionada: $provincia_label"
di as text "  ID: $id_provincia"
di as text "  Carpeta de salida: $provincia_carpeta"
di as text "=========================================="


* ============================================================================
* 4. CREAR ESTRUCTURA DE CARPETAS DE SALIDA
* ============================================================================

capture mkdir "$output/$provincia_carpeta"
capture mkdir "$output/$provincia_carpeta/01_Generalidades"
capture mkdir "$output/$provincia_carpeta/02_Demografia"
capture mkdir "$output/$provincia_carpeta/03_Ordenamiento"
capture mkdir "$output/$provincia_carpeta/04_Gobernabilidad"
capture mkdir "$output/$provincia_carpeta/05_Economia"
capture mkdir "$output/$provincia_carpeta/06_Desarrollo_Rural"
capture mkdir "$output/$provincia_carpeta/07_Ambiental"
capture mkdir "$output/$provincia_carpeta/08_Educacion"
capture mkdir "$output/$provincia_carpeta/09_Salud"
capture mkdir "$output/$provincia_carpeta/10_Seguridad"

* Ruta de salida por seccion (usada en cada .do seccional)
global out_01 "$output/$provincia_carpeta/01_Generalidades"
global out_02 "$output/$provincia_carpeta/02_Demografia"
global out_03 "$output/$provincia_carpeta/03_Ordenamiento"
global out_04 "$output/$provincia_carpeta/04_Gobernabilidad"
global out_05 "$output/$provincia_carpeta/05_Economia"
global out_06 "$output/$provincia_carpeta/06_Desarrollo_Rural"
global out_07 "$output/$provincia_carpeta/07_Ambiental"
global out_08 "$output/$provincia_carpeta/08_Educacion"
global out_09 "$output/$provincia_carpeta/09_Salud"
global out_10 "$output/$provincia_carpeta/10_Seguridad"


* ============================================================================
* 5. EJECUTAR DO-FILES SECCIONALES
*    Comentar/descomentar lineas para ejecutar secciones individuales
* ============================================================================

di as text _n ">>> Ejecutando 01_Generalidades.do ..."
do "$scripts/01_Generalidades.do"

di as text _n ">>> Ejecutando 02_Demografia.do ..."
do "$scripts/02_Demografia.do"

di as text _n ">>> Ejecutando 03_Ordenamiento.do ..."
do "$scripts/03_Ordenamiento.do"

di as text _n ">>> Ejecutando 04_Gobernabilidad.do ..."
do "$scripts/04_Gobernabilidad.do"

di as text _n ">>> Ejecutando 05_Economia.do ..."
do "$scripts/05_Economia.do"

di as text _n ">>> Ejecutando 06_Desarrollo_Rural.do ..."
do "$scripts/06_Desarrollo_Rural.do"

di as text _n ">>> Ejecutando 07_Ambiental.do ..."
do "$scripts/07_Ambiental.do"

di as text _n ">>> Ejecutando 08_Educacion.do ..."
do "$scripts/08_Educacion.do"

di as text _n ">>> Ejecutando 09_Salud.do ..."
do "$scripts/09_Salud.do"

di as text _n ">>> Ejecutando 10_Seguridad.do ..."
do "$scripts/10_Seguridad.do"


di as text _n "=========================================="
di as text "  PROCESO COMPLETADO"
di as text "  Tablas exportadas en: $output/$provincia_carpeta/"
di as text "=========================================="
