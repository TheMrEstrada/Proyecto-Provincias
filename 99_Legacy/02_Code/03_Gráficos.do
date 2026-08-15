* ----------------------------------------------------------------------------
* PROVINCIAS - 03_gráficos.do
* PRODUCCIÓN DE TABLAS 
* OBJETIVO: Importar indicadores municipales y crear tablas resumen
* OUTPUTS: 03_Outputs/Gráficos/...
* ----------------------------------------------------------------------------

clear all

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	
/********************************************************************
* Pirámide poblacional Antioquia 2025
********************************************************************/

use "$data/poblacion_total_2025.dta", clear

* Solo total departamental / municipal agregado
keep if area_geo == "Total"
keep if departamento =="Antioquia"

* Crear grupos de edad hombres
egen H_0_9   = rowtotal(Hombres0años-Hombres9años)
egen H_10_19 = rowtotal(Hombres10años-Hombres19años)
egen H_20_29 = rowtotal(Hombres20años-Hombres29años)
egen H_30_39 = rowtotal(Hombres30años-Hombres39años)
egen H_40_49 = rowtotal(Hombres40años-Hombres49años)
egen H_50_59 = rowtotal(Hombres50años-Hombres59años)
egen H_60_69 = rowtotal(Hombres60años-Hombres69años)
egen H_70_79 = rowtotal(Hombres70años-Hombres79años)
egen H_80mas = rowtotal(Hombres80años-Hombres99años Hombres100añosymás)

* Crear grupos de edad mujeres
egen M_0_9   = rowtotal(Mujeres0años-Mujeres9años)
egen M_10_19 = rowtotal(Mujeres10años-Mujeres19años)
egen M_20_29 = rowtotal(Mujeres20años-Mujeres29años)
egen M_30_39 = rowtotal(Mujeres30años-Mujeres39años)
egen M_40_49 = rowtotal(Mujeres40años-Mujeres49años)
egen M_50_59 = rowtotal(Mujeres50años-Mujeres59años)
egen M_60_69 = rowtotal(Mujeres60años-Mujeres69años)
egen M_70_79 = rowtotal(Mujeres70años-Mujeres79años)
egen M_80mas = rowtotal(Mujeres80años-Mujeres99años Mujeres100añosymás)

* Agregar Antioquia
collapse ///
    (sum) H_0_9 H_10_19 H_20_29 H_30_39 H_40_49 H_50_59 H_60_69 H_70_79 H_80mas ///
          M_0_9 M_10_19 M_20_29 M_30_39 M_40_49 M_50_59 M_60_69 M_70_79 M_80mas

* Pasar a formato largo
gen id = 1
reshape long H_ M_, i(id) j(grupo) string

rename H_ hombres
rename M_ mujeres

gen edad = .
replace edad = 1 if grupo == "0_9"
replace edad = 2 if grupo == "10_19"
replace edad = 3 if grupo == "20_29"
replace edad = 4 if grupo == "30_39"
replace edad = 5 if grupo == "40_49"
replace edad = 6 if grupo == "50_59"
replace edad = 7 if grupo == "60_69"
replace edad = 8 if grupo == "70_79"
replace edad = 9 if grupo == "80mas"

label define edad_lbl ///
    1 "0-9" ///
    2 "10-19" ///
    3 "20-29" ///
    4 "30-39" ///
    5 "40-49" ///
    6 "50-59" ///
    7 "60-69" ///
    8 "70-79" ///
    9 "80 y más"

label values edad edad_lbl

* Hombres a la izquierda
gen hombres_neg = -hombres

* Variable con etiqueta de edad como texto para Excel
decode edad, gen(grupo_edad)

* Dejar tabla lista para graficar en Excel
keep edad grupo_edad hombres mujeres hombres_neg
order edad grupo_edad hombres hombres_neg mujeres

export excel using "$output/tablas_provincias.xlsx", ///
        sheet("pirámide_género") firstrow(varlabels) sheetreplace

* Gráfico con valores absolutos en eje X
twoway ///
    (bar hombres_neg edad, horizontal barwidth(0.75) ///
        color(navy) lcolor(navy)) ///
    (bar mujeres edad, horizontal barwidth(0.75) ///
        color(eltblue) lcolor(eltblue)), ///
    ylabel(1(1)9, valuelabel labsize(medsmall) angle(0)) ///
    xlabel(-1000000 "1.000" ///
           -500000  "500" ///
            0       "0" ///
            500000  "500" ///
            1000000 "1.000", ///
           labsize(vsmall)) ///
    xscale(range(-1000000 1000000)) ///
    xtitle("Personas (miles)", size(medium)) ///
    ytitle("") ///
    legend(order(1 "Hombres" 2 "Mujeres") ///
           position(6) rows(1) size(medium)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(piramide_antioquia, replace)

graph export "$output/Gráficos/piramide_antioquia.png", replace width(2400)