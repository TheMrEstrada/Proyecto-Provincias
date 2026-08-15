* ----------------------------------------------------------------------------
* tests/golden_run.do — Generación de outputs de REFERENCIA con el pipeline Stata
*
* OBJETIVO: producir, con el código Stata original y sin modificarlo, las tablas
*           de las 10 secciones para una provincia, en tests/golden/<Provincia>/.
*           Esas salidas son el patrón contra el que se valida la migración a R
*           (02_Code/99_checks/comparar_golden.R).
*
* USO:  stata-mp -b do tests/golden_run.do <id_provincia>
*       (o definir el global id_provincia antes de hacer `do`)
*
* NOTA: replica la lógica de 02_Code/Tablas_Diagnostico/00_master.do salvo la
*       raíz de rutas (aquí se deriva del repositorio, no de "D:\IA Provincias")
*       y la carpeta de salida (tests/golden en vez de 03_Outputs).
* ----------------------------------------------------------------------------

clear all
set more off

* --- 1. Provincia: del argumento de línea de comandos o del global ya definido
if "`1'" != "" global id_provincia `1'
if "$id_provincia" == "" global id_provincia 4

* --- 2. Rutas derivadas del repositorio (cwd = raíz del repo) ---------------
global path    "`c(pwd)'"
global rawdata "$path/01_Data/00_Inputs"
global data    "$path/01_Data/01_Derived"
global scripts "$path/02_Code/Tablas_Diagnostico"
global output  "$path/tests/golden"

capture confirm file "$scripts/00_master.do"
if _rc {
    di as error "No se encuentra $scripts/00_master.do"
    di as error "Ejecute este do-file con el directorio de trabajo en la raíz del repositorio."
    exit 601
}

capture mkdir "$path/tests"
capture mkdir "$output"

* --- 3. Nombres de provincia (idénticos a 00_master.do) ---------------------
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
di as text "  GOLDEN RUN — provincia $id_provincia: $provincia_label"
di as text "  Salida: $output/$provincia_carpeta"
di as text "=========================================="

* --- 4. Estructura de carpetas ---------------------------------------------
capture mkdir "$output/$provincia_carpeta"
local secciones "01_Generalidades 02_Demografia 03_Ordenamiento 04_Gobernabilidad 05_Economia 06_Desarrollo_Rural 07_Ambiental 08_Educacion 09_Salud 10_Seguridad"
foreach s of local secciones {
    capture mkdir "$output/$provincia_carpeta/`s'"
}
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

* --- 5. Ejecutar los 10 sectoriales -----------------------------------------
*     capture noisily: una sección que falle (p. ej. por insumo ausente del clon)
*     no debe impedir generar las demás. El resumen final dice cuáles fallaron.
local fallos ""
foreach s of local secciones {
    di as text _n ">>> `s'.do"
    capture noisily do "$scripts/`s'.do"
    if _rc {
        di as error "    [FALLO rc=`=_rc'] `s'.do"
        local fallos "`fallos' `s'(rc=`=_rc')"
    }
    else {
        di as result "    [OK] `s'.do"
    }
}

di as text _n "=========================================="
di as text "  GOLDEN RUN terminado — provincia $id_provincia"
if "`fallos'" == "" {
    di as result "  Todas las secciones OK"
}
else {
    di as error "  Secciones con fallo:`fallos'"
}
di as text "=========================================="
