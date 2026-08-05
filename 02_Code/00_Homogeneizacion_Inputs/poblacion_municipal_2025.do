cls
clear all
set more off

* ---- Configuración de directorios ----

	global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
	global rawdata "$path/01_Data/00_Inputs"
	global scripts "$path/02_Code"
	global data "$path/01_Data/01_Derived"
	global output "$path/03_Outputs"
	

*------------------------------------
* Población total
*------------------------------------

import excel "$rawdata/PPED-AreaSexoEdadMun-2018-2042_VP.xlsx", firstrow clear sheet("PobMunicipalxÁreaSexoEdad") cellrange(A9)

rename A cod_dpto
rename B departamento
rename C ind_mpio //2020-2025
rename D nvl_label
rename E año
rename F area_geo

save "$data/poblacion_total.dta", replace




*Solo 2025 TOTALES
use "$data/poblacion_total.dta", clear
keep if año==2025
keep cod_dpto departamento ind_mpio nvl_label año area_geo Total Hombres Mujeres

destring ind_mpio, replace
keep if cod_dpto =="05"

save "$data/poblacion_total_2025.dta", replace




********************************************************************************
* 1. CARGAR Y FILTRAR (AÑO 2025) con tasas e índices
********************************************************************************

use "$data/poblacion_total.dta", clear

keep if año == 2025


********************************************************************************
* 2. GRUPOS ETARIOS
*    "85.y.más" del R = Hombres85años + ... + Hombres100añosymás en este .dta
********************************************************************************

* ── Infancia (0-11) ──────────────────────────────────────────────────────────
egen Inf_H_0_11 = rowtotal(Hombres0años Hombres1año Hombres2años Hombres3años ///
    Hombres4años Hombres5años Hombres6años Hombres7años Hombres8años ///
    Hombres9años Hombres10años Hombres11años)
egen Inf_M_0_11 = rowtotal(Mujeres0años Mujeres1año Mujeres2años Mujeres3años ///
    Mujeres4años Mujeres5años Mujeres6años Mujeres7años Mujeres8años ///
    Mujeres9años Mujeres10años Mujeres11años)
egen Inf_T_0_11 = rowtotal(Total0años Total1año Total2años Total3años ///
    Total4años Total5años Total6años Total7años Total8años ///
    Total9años Total10años Total11años)

* ── Juventud (12-28) ─────────────────────────────────────────────────────────
egen Juv_H_12_28 = rowtotal(Hombres12años Hombres13años Hombres14años ///
    Hombres15años Hombres16años Hombres17años Hombres18años Hombres19años ///
    Hombres20años Hombres21años Hombres22años Hombres23años Hombres24años ///
    Hombres25años Hombres26años Hombres27años Hombres28años)
egen Juv_M_12_28 = rowtotal(Mujeres12años Mujeres13años Mujeres14años ///
    Mujeres15años Mujeres16años Mujeres17años Mujeres18años Mujeres19años ///
    Mujeres20años Mujeres21años Mujeres22años Mujeres23años Mujeres24años ///
    Mujeres25años Mujeres26años Mujeres27años Mujeres28años)
egen Juv_T_12_28 = rowtotal(Total12años Total13años Total14años ///
    Total15años Total16años Total17años Total18años Total19años ///
    Total20años Total21años Total22años Total23años Total24años ///
    Total25años Total26años Total27años Total28años)

* ── Adultez (29-59) ──────────────────────────────────────────────────────────
egen Ad_H_29_59 = rowtotal(Hombres29años Hombres30años Hombres31años ///
    Hombres32años Hombres33años Hombres34años Hombres35años Hombres36años ///
    Hombres37años Hombres38años Hombres39años Hombres40años Hombres41años ///
    Hombres42años Hombres43años Hombres44años Hombres45años Hombres46años ///
    Hombres47años Hombres48años Hombres49años Hombres50años Hombres51años ///
    Hombres52años Hombres53años Hombres54años Hombres55años Hombres56años ///
    Hombres57años Hombres58años Hombres59años)
egen Ad_M_29_59 = rowtotal(Mujeres29años Mujeres30años Mujeres31años ///
    Mujeres32años Mujeres33años Mujeres34años Mujeres35años Mujeres36años ///
    Mujeres37años Mujeres38años Mujeres39años Mujeres40años Mujeres41años ///
    Mujeres42años Mujeres43años Mujeres44años Mujeres45años Mujeres46años ///
    Mujeres47años Mujeres48años Mujeres49años Mujeres50años Mujeres51años ///
    Mujeres52años Mujeres53años Mujeres54años Mujeres55años Mujeres56años ///
    Mujeres57años Mujeres58años Mujeres59años)
egen Ad_T_29_59 = rowtotal(Total29años Total30años Total31años ///
    Total32años Total33años Total34años Total35años Total36años ///
    Total37años Total38años Total39años Total40años Total41años ///
    Total42años Total43años Total44años Total45años Total46años ///
    Total47años Total48años Total49años Total50años Total51años ///
    Total52años Total53años Total54años Total55años Total56años ///
    Total57años Total58años Total59años)

* ── Vejez (60-85+) ───────────────────────────────────────────────────────────
* R: c(paste0("_", 60:84), "_85.y.más")
local v85mas_H Hombres85años Hombres86años Hombres87años Hombres88años    ///
    Hombres89años Hombres90años Hombres91años Hombres92años Hombres93años ///
    Hombres94años Hombres95años Hombres96años Hombres97años Hombres98años ///
    Hombres99años Hombres100añosymás
local v85mas_M Mujeres85años Mujeres86años Mujeres87años Mujeres88años    ///
    Mujeres89años Mujeres90años Mujeres91años Mujeres92años Mujeres93años ///
    Mujeres94años Mujeres95años Mujeres96años Mujeres97años Mujeres98años ///
    Mujeres99años Mujeres100añosymás
local v85mas_T Total85años Total86años Total87años Total88años             ///
    Total89años Total90años Total91años Total92años Total93años            ///
    Total94años Total95años Total96años Total97años Total98años            ///
    Total99años Total100añosymás

egen V_H_60_85 = rowtotal(Hombres60años Hombres61años Hombres62años       ///
    Hombres63años Hombres64años Hombres65años Hombres66años Hombres67años ///
    Hombres68años Hombres69años Hombres70años Hombres71años Hombres72años ///
    Hombres73años Hombres74años Hombres75años Hombres76años Hombres77años ///
    Hombres78años Hombres79años Hombres80años Hombres81años Hombres82años ///
    Hombres83años Hombres84años `v85mas_H')
egen V_M_60_85 = rowtotal(Mujeres60años Mujeres61años Mujeres62años       ///
    Mujeres63años Mujeres64años Mujeres65años Mujeres66años Mujeres67años ///
    Mujeres68años Mujeres69años Mujeres70años Mujeres71años Mujeres72años ///
    Mujeres73años Mujeres74años Mujeres75años Mujeres76años Mujeres77años ///
    Mujeres78años Mujeres79años Mujeres80años Mujeres81años Mujeres82años ///
    Mujeres83años Mujeres84años `v85mas_M')
egen V_T_60_85 = rowtotal(Total60años Total61años Total62años              ///
    Total63años Total64años Total65años Total66años Total67años            ///
    Total68años Total69años Total70años Total71años Total72años            ///
    Total73años Total74años Total75años Total76años Total77años            ///
    Total78años Total79años Total80años Total81años Total82años            ///
    Total83años Total84años `v85mas_T')

* ── Dependientes (0-14 + 60-85+) ────────────────────────────────────────────
* R: c(paste0("_", 0:14), paste0("_", 60:84), "_85.y.más")
egen Dep_H_0_14_60_85 = rowtotal(                                         ///
    Hombres0años Hombres1año Hombres2años Hombres3años Hombres4años        ///
    Hombres5años Hombres6años Hombres7años Hombres8años Hombres9años       ///
    Hombres10años Hombres11años Hombres12años Hombres13años Hombres14años  ///
    Hombres60años Hombres61años Hombres62años Hombres63años Hombres64años  ///
    Hombres65años Hombres66años Hombres67años Hombres68años Hombres69años  ///
    Hombres70años Hombres71años Hombres72años Hombres73años Hombres74años  ///
    Hombres75años Hombres76años Hombres77años Hombres78años Hombres79años  ///
    Hombres80años Hombres81años Hombres82años Hombres83años Hombres84años  ///
    `v85mas_H')
egen Dep_M_0_14_60_85 = rowtotal(                                          ///
    Mujeres0años Mujeres1año Mujeres2años Mujeres3años Mujeres4años        ///
    Mujeres5años Mujeres6años Mujeres7años Mujeres8años Mujeres9años       ///
    Mujeres10años Mujeres11años Mujeres12años Mujeres13años Mujeres14años  ///
    Mujeres60años Mujeres61años Mujeres62años Mujeres63años Mujeres64años  ///
    Mujeres65años Mujeres66años Mujeres67años Mujeres68años Mujeres69años  ///
    Mujeres70años Mujeres71años Mujeres72años Mujeres73años Mujeres74años  ///
    Mujeres75años Mujeres76años Mujeres77años Mujeres78años Mujeres79años  ///
    Mujeres80años Mujeres81años Mujeres82años Mujeres83años Mujeres84años  ///
    `v85mas_M')
egen Dep_T_0_14_60_85 = rowtotal(                                          ///
    Total0años Total1año Total2años Total3años Total4años                   ///
    Total5años Total6años Total7años Total8años Total9años                  ///
    Total10años Total11años Total12años Total13años Total14años             ///
    Total60años Total61años Total62años Total63años Total64años             ///
    Total65años Total66años Total67años Total68años Total69años             ///
    Total70años Total71años Total72años Total73años Total74años             ///
    Total75años Total76años Total77años Total78años Total79años             ///
    Total80años Total81años Total82años Total83años Total84años             ///
    `v85mas_T')

* ── Activos (15-59) ──────────────────────────────────────────────────────────
* R: paste0("_", 15:59)
egen Act_H_15_59 = rowtotal(Hombres15años Hombres16años Hombres17años      ///
    Hombres18años Hombres19años Hombres20años Hombres21años Hombres22años  ///
    Hombres23años Hombres24años Hombres25años Hombres26años Hombres27años  ///
    Hombres28años Hombres29años Hombres30años Hombres31años Hombres32años  ///
    Hombres33años Hombres34años Hombres35años Hombres36años Hombres37años  ///
    Hombres38años Hombres39años Hombres40años Hombres41años Hombres42años  ///
    Hombres43años Hombres44años Hombres45años Hombres46años Hombres47años  ///
    Hombres48años Hombres49años Hombres50años Hombres51años Hombres52años  ///
    Hombres53años Hombres54años Hombres55años Hombres56años Hombres57años  ///
    Hombres58años Hombres59años)
egen Act_M_15_59 = rowtotal(Mujeres15años Mujeres16años Mujeres17años      ///
    Mujeres18años Mujeres19años Mujeres20años Mujeres21años Mujeres22años  ///
    Mujeres23años Mujeres24años Mujeres25años Mujeres26años Mujeres27años  ///
    Mujeres28años Mujeres29años Mujeres30años Mujeres31años Mujeres32años  ///
    Mujeres33años Mujeres34años Mujeres35años Mujeres36años Mujeres37años  ///
    Mujeres38años Mujeres39años Mujeres40años Mujeres41años Mujeres42años  ///
    Mujeres43años Mujeres44años Mujeres45años Mujeres46años Mujeres47años  ///
    Mujeres48años Mujeres49años Mujeres50años Mujeres51años Mujeres52años  ///
    Mujeres53años Mujeres54años Mujeres55años Mujeres56años Mujeres57años  ///
    Mujeres58años Mujeres59años)
egen Act_T_15_59 = rowtotal(Total15años Total16años Total17años             ///
    Total18años Total19años Total20años Total21años Total22años             ///
    Total23años Total24años Total25años Total26años Total27años             ///
    Total28años Total29años Total30años Total31años Total32años             ///
    Total33años Total34años Total35años Total36años Total37años             ///
    Total38años Total39años Total40años Total41años Total42años             ///
    Total43años Total44años Total45años Total46años Total47años             ///
    Total48años Total49años Total50años Total51años Total52años             ///
    Total53años Total54años Total55años Total56años Total57años             ///
    Total58años Total59años)

* ── Envejecimiento (65-85+) ──────────────────────────────────────────────────
* R: c(paste0("_", 65:84), "_85.y.más")
egen Enve_H_65_85 = rowtotal(Hombres65años Hombres66años Hombres67años    ///
    Hombres68años Hombres69años Hombres70años Hombres71años Hombres72años  ///
    Hombres73años Hombres74años Hombres75años Hombres76años Hombres77años  ///
    Hombres78años Hombres79años Hombres80años Hombres81años Hombres82años  ///
    Hombres83años Hombres84años `v85mas_H')
egen Enve_M_65_85 = rowtotal(Mujeres65años Mujeres66años Mujeres67años    ///
    Mujeres68años Mujeres69años Mujeres70años Mujeres71años Mujeres72años  ///
    Mujeres73años Mujeres74años Mujeres75años Mujeres76años Mujeres77años  ///
    Mujeres78años Mujeres79años Mujeres80años Mujeres81años Mujeres82años  ///
    Mujeres83años Mujeres84años `v85mas_M')
egen Enve_T_65_85 = rowtotal(Total65años Total66años Total67años           ///
    Total68años Total69años Total70años Total71años Total72años             ///
    Total73años Total74años Total75años Total76años Total77años             ///
    Total78años Total79años Total80años Total81años Total82años             ///
    Total83años Total84años `v85mas_T')

* ── Jov_0_14 (base índice envejecimiento) ────────────────────────────────────
* R: Jov_T_0_14 = rowSums(c(0:14, 60:84, 85+)) — mismo cálculo que Dep
gen Jov_H_0_14 = Dep_H_0_14_60_85
gen Jov_M_0_14 = Dep_M_0_14_60_85
gen Jov_T_0_14 = Dep_T_0_14_60_85

********************************************************************************
* 3. CONSERVAR VARIABLES CLAVE Y RENOMBRAR TOTALES
********************************************************************************

keep ind_mpio nvl_label area_geo                                             ///
     Total Hombres Mujeres                                                   ///
     Inf_T_0_11  Juv_T_12_28  Ad_T_29_59  V_T_60_85                         ///
     Inf_H_0_11  Juv_H_12_28  Ad_H_29_59  V_H_60_85                         ///
     Inf_M_0_11  Juv_M_12_28  Ad_M_29_59  V_M_60_85                         ///
     Dep_T_0_14_60_85 Dep_H_0_14_60_85 Dep_M_0_14_60_85                     ///
     Act_T_15_59 Act_H_15_59 Act_M_15_59                                     ///
     Enve_T_65_85 Enve_H_65_85 Enve_M_65_85                                 ///
     Jov_T_0_14 Jov_H_0_14 Jov_M_0_14

rename (Total Hombres Mujeres) (T_T H_T M_T)

********************************************************************************
* 4. DATASET TOTAL  [datos_general en R]
********************************************************************************

preserve
    keep if area_geo == "Total"

    * Proporciones por ciclo vital sobre total municipal
    gen P_T          = (T_T / T_T) * 100
    gen P_H          = (H_T / T_T) * 100
    gen P_M          = (M_T / T_T) * 100
    gen P_inf_T_0_11 = (Inf_T_0_11  / T_T) * 100
    gen P_j_T_12_28  = (Juv_T_12_28 / T_T) * 100
    gen P_ad_T_29_59 = (Ad_T_29_59  / T_T) * 100
    gen P_v_T_60_85  = (V_T_60_85   / T_T) * 100
    gen P_inf_H_0_11 = (Inf_H_0_11  / T_T) * 100
    gen P_j_H_12_28  = (Juv_H_12_28 / T_T) * 100
    gen P_ad_H_29_59 = (Ad_H_29_59  / T_T) * 100
    gen P_v_H_60_85  = (V_H_60_85   / T_T) * 100
    gen P_inf_M_0_11 = (Inf_M_0_11  / T_T) * 100
    gen P_j_M_12_28  = (Juv_M_12_28 / T_T) * 100
    gen P_ad_M_29_59 = (Ad_M_29_59  / T_T) * 100
    gen P_v_M_60_85  = (V_M_60_85   / T_T) * 100
    * IDE
    gen IDE_T = (Dep_T_0_14_60_85 / Act_T_15_59) * 100
    gen IDE_H = (Dep_H_0_14_60_85 / Act_H_15_59) * 100
    gen IDE_M = (Dep_M_0_14_60_85 / Act_M_15_59) * 100
    * Índice de envejecimiento
    gen I_enve_T = (Enve_T_65_85 / Jov_T_0_14) * 100
    gen I_enve_H = (Enve_H_65_85 / Jov_H_0_14) * 100
    gen I_enve_M = (Enve_M_65_85 / Jov_M_0_14) * 100

    keep ind_mpio nvl_label                                                  ///
         P_T P_H P_M                                                         ///
         P_inf_T_0_11 P_j_T_12_28 P_ad_T_29_59 P_v_T_60_85                 ///
         P_inf_H_0_11 P_j_H_12_28 P_ad_H_29_59 P_v_H_60_85                 ///
         P_inf_M_0_11 P_j_M_12_28 P_ad_M_29_59 P_v_M_60_85                 ///
         IDE_T IDE_H IDE_M                                                   ///
         I_enve_T I_enve_H I_enve_M

    save "_tmp_general.dta", replace
restore

********************************************************************************
* 5. DATASET RURAL  [datos_rural en R]
********************************************************************************

preserve
    keep if area_geo == "Centros Poblados y Rural Disperso"

    gen P_T_r          = (T_T / T_T) * 100
    gen P_H_r          = (H_T / T_T) * 100
    gen P_M_r          = (M_T / T_T) * 100
    gen P_inf_T_0_11_r = (Inf_T_0_11  / T_T) * 100
    gen P_j_T_12_28_r  = (Juv_T_12_28 / T_T) * 100
    gen P_ad_T_29_59_r = (Ad_T_29_59  / T_T) * 100
    gen P_v_T_60_85_r  = (V_T_60_85   / T_T) * 100
    gen P_inf_H_0_11_r = (Inf_H_0_11  / T_T) * 100
    gen P_j_H_12_28_r  = (Juv_H_12_28 / T_T) * 100
    gen P_ad_H_29_59_r = (Ad_H_29_59  / T_T) * 100
    gen P_v_H_60_85_r  = (V_H_60_85   / T_T) * 100
    gen P_inf_M_0_11_r = (Inf_M_0_11  / T_T) * 100
    gen P_j_M_12_28_r  = (Juv_M_12_28 / T_T) * 100
    gen P_ad_M_29_59_r = (Ad_M_29_59  / T_T) * 100
    gen P_v_M_60_85_r  = (V_M_60_85   / T_T) * 100
    gen IDE_T_r        = (Dep_T_0_14_60_85 / Act_T_15_59) * 100
    gen IDE_H_r        = (Dep_H_0_14_60_85 / Act_H_15_59) * 100
    gen IDE_M_r        = (Dep_M_0_14_60_85 / Act_M_15_59) * 100
    gen I_enve_T_r     = (Enve_T_65_85 / Jov_T_0_14) * 100
    gen I_enve_H_r     = (Enve_H_65_85 / Jov_H_0_14) * 100
    gen I_enve_M_r     = (Enve_M_65_85 / Jov_M_0_14) * 100

    keep ind_mpio nvl_label                                                  ///
         P_T_r P_H_r P_M_r                                                   ///
         P_inf_T_0_11_r P_j_T_12_28_r P_ad_T_29_59_r P_v_T_60_85_r         ///
         P_inf_H_0_11_r P_j_H_12_28_r P_ad_H_29_59_r P_v_H_60_85_r         ///
         P_inf_M_0_11_r P_j_M_12_28_r P_ad_M_29_59_r P_v_M_60_85_r         ///
         IDE_T_r IDE_H_r IDE_M_r                                             ///
         I_enve_T_r I_enve_H_r I_enve_M_r

    save "_tmp_rural.dta", replace
restore

********************************************************************************
* 6. DATASET CABECERA  [datos_cabecera en R]
********************************************************************************

preserve
    keep if area_geo == "Cabecera Municipal"

    gen P_T_c          = (T_T / T_T) * 100
    gen P_H_c          = (H_T / T_T) * 100
    gen P_M_c          = (M_T / T_T) * 100
    gen P_inf_T_0_11_c = (Inf_T_0_11  / T_T) * 100
    gen P_j_T_12_28_c  = (Juv_T_12_28 / T_T) * 100
    gen P_ad_T_29_59_c = (Ad_T_29_59  / T_T) * 100
    gen P_v_T_60_85_c  = (V_T_60_85   / T_T) * 100
    gen P_inf_H_0_11_c = (Inf_H_0_11  / T_T) * 100
    gen P_j_H_12_28_c  = (Juv_H_12_28 / T_T) * 100
    gen P_ad_H_29_59_c = (Ad_H_29_59  / T_T) * 100
    gen P_v_H_60_85_c  = (V_H_60_85   / T_T) * 100
    gen P_inf_M_0_11_c = (Inf_M_0_11  / T_T) * 100
    gen P_j_M_12_28_c  = (Juv_M_12_28 / T_T) * 100
    gen P_ad_M_29_59_c = (Ad_M_29_59  / T_T) * 100
    gen P_v_M_60_85_c  = (V_M_60_85   / T_T) * 100
    gen IDE_T_c        = (Dep_T_0_14_60_85 / Act_T_15_59) * 100
    gen IDE_H_c        = (Dep_H_0_14_60_85 / Act_H_15_59) * 100
    gen IDE_M_c        = (Dep_M_0_14_60_85 / Act_M_15_59) * 100
    gen I_enve_c_T     = (Enve_T_65_85 / Jov_T_0_14) * 100
    gen I_enve_H_c     = (Enve_H_65_85 / Jov_H_0_14) * 100
    gen I_enve_M_c     = (Enve_M_65_85 / Jov_M_0_14) * 100

    keep ind_mpio nvl_label                                                  ///
         P_T_c P_H_c P_M_c                                                   ///
         P_inf_T_0_11_c P_j_T_12_28_c P_ad_T_29_59_c P_v_T_60_85_c         ///
         P_inf_H_0_11_c P_j_H_12_28_c P_ad_H_29_59_c P_v_H_60_85_c         ///
         P_inf_M_0_11_c P_j_M_12_28_c P_ad_M_29_59_c P_v_M_60_85_c         ///
         IDE_T_c IDE_H_c IDE_M_c                                             ///
         I_enve_c_T I_enve_H_c I_enve_M_c

    save "_tmp_cabecera.dta", replace
restore

********************************************************************************
* 7. PROPORCIONES RURALES SOBRE EL TOTAL  [datos_p_rural en R]
********************************************************************************

* -- Base total --
preserve
    keep if area_geo == "Total"
    keep ind_mpio T_T H_T M_T                                               ///
         Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                        ///
         Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                        ///
         Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85
    rename (T_T H_T M_T                                                      ///
            Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                     ///
            Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                     ///
            Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85)                    ///
           (T_t H_t M_t                                                      ///
            InfT_t JuvT_t AdT_t VT_t                                         ///
            InfH_t JuvH_t AdH_t VH_t                                         ///
            InfM_t JuvM_t AdM_t VM_t)
    save "_tmp_base_total.dta", replace
restore

* -- Merge con rural y calcular PR_ --
preserve
    keep if area_geo == "Centros Poblados y Rural Disperso"
    keep ind_mpio T_T H_T M_T                                               ///
         Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                        ///
         Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                        ///
         Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85
    rename (T_T H_T M_T                                                      ///
            Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                     ///
            Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                     ///
            Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85)                    ///
           (T_r H_r M_r                                                      ///
            InfT_r JuvT_r AdT_r VT_r                                         ///
            InfH_r JuvH_r AdH_r VH_r                                         ///
            InfM_r JuvM_r AdM_r VM_r)
    merge 1:1 ind_mpio using "_tmp_base_total.dta", nogenerate

    gen PR_T          = (T_r    / T_t)    * 100
    gen PR_H          = (H_r    / H_t)    * 100
    gen PR_M          = (M_r    / M_t)    * 100
    gen PR_inf_T_0_11 = (InfT_r / InfT_t) * 100
    gen PR_j_T_12_28  = (JuvT_r / JuvT_t) * 100
    gen PR_ad_T_29_59 = (AdT_r  / AdT_t)  * 100
    gen PR_v_T_60_85  = (VT_r   / VT_t)   * 100
    gen PR_inf_H_0_11 = (InfH_r / InfH_t) * 100
    gen PR_j_H_12_28  = (JuvH_r / JuvH_t) * 100
    gen PR_ad_H_29_59 = (AdH_r  / AdH_t)  * 100
    gen PR_v_H_60_85  = (VH_r   / VH_t)   * 100
    gen PR_inf_M_0_11 = (InfM_r / InfM_t) * 100
    gen PR_j_M_12_28  = (JuvM_r / JuvM_t) * 100
    gen PR_ad_M_29_59 = (AdM_r  / AdM_t)  * 100
    gen PR_v_M_60_85  = (VM_r   / VM_t)   * 100

    keep ind_mpio PR_T PR_H PR_M                                             ///
         PR_inf_T_0_11 PR_j_T_12_28 PR_ad_T_29_59 PR_v_T_60_85              ///
         PR_inf_H_0_11 PR_j_H_12_28 PR_ad_H_29_59 PR_v_H_60_85              ///
         PR_inf_M_0_11 PR_j_M_12_28 PR_ad_M_29_59 PR_v_M_60_85
    save "_tmp_p_rural.dta", replace
restore

********************************************************************************
* 8. PROPORCIONES URBANAS SOBRE EL TOTAL  [datos_p_urbano en R]
********************************************************************************

preserve
    keep if area_geo == "Cabecera Municipal"
    keep ind_mpio T_T H_T M_T                                               ///
         Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                        ///
         Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                        ///
         Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85
    rename (T_T H_T M_T                                                      ///
            Inf_T_0_11 Juv_T_12_28 Ad_T_29_59 V_T_60_85                     ///
            Inf_H_0_11 Juv_H_12_28 Ad_H_29_59 V_H_60_85                     ///
            Inf_M_0_11 Juv_M_12_28 Ad_M_29_59 V_M_60_85)                    ///
           (T_u H_u M_u                                                      ///
            InfT_u JuvT_u AdT_u VT_u                                         ///
            InfH_u JuvH_u AdH_u VH_u                                         ///
            InfM_u JuvM_u AdM_u VM_u)
    merge 1:1 ind_mpio using "_tmp_base_total.dta", nogenerate

    gen PU_T          = (T_u    / T_t)    * 100
    gen PU_H          = (H_u    / H_t)    * 100
    gen PU_M          = (M_u    / M_t)    * 100
    gen PU_inf_T_0_11 = (InfT_u / InfT_t) * 100
    gen PU_j_T_12_28  = (JuvT_u / JuvT_t) * 100
    gen PU_ad_T_29_59 = (AdT_u  / AdT_t)  * 100
    gen PU_v_T_60_85  = (VT_u   / VT_t)   * 100
    gen PU_inf_H_0_11 = (InfH_u / InfH_t) * 100
    gen PU_j_H_12_28  = (JuvH_u / JuvH_t) * 100
    gen PU_ad_H_29_59 = (AdH_u  / AdH_t)  * 100
    gen PU_v_H_60_85  = (VH_u   / VH_t)   * 100
    gen PU_inf_M_0_11 = (InfM_u / InfM_t) * 100
    gen PU_j_M_12_28  = (JuvM_u / JuvM_t) * 100
    gen PU_ad_M_29_59 = (AdM_u  / AdM_t)  * 100
    gen PU_v_M_60_85  = (VM_u   / VM_t)   * 100

    keep ind_mpio PU_T PU_H PU_M                                             ///
         PU_inf_T_0_11 PU_j_T_12_28 PU_ad_T_29_59 PU_v_T_60_85              ///
         PU_inf_H_0_11 PU_j_H_12_28 PU_ad_H_29_59 PU_v_H_60_85              ///
         PU_inf_M_0_11 PU_j_M_12_28 PU_ad_M_29_59 PU_v_M_60_85
    save "_tmp_p_urbano.dta", replace
restore

********************************************************************************
* 9. UNIR TODOS Y EXPORTAR  [datos_total en R]
* R: datos_general |> left_join(rural) |> left_join(cabecera)
*                  |> left_join(p_rural) |> left_join(p_urbano)
********************************************************************************

use "_tmp_general.dta", clear

merge 1:1 ind_mpio using "_tmp_rural.dta",    nogenerate
merge 1:1 ind_mpio using "_tmp_cabecera.dta", nogenerate
merge 1:1 ind_mpio using "_tmp_p_rural.dta",  nogenerate
merge 1:1 ind_mpio using "_tmp_p_urbano.dta", nogenerate

destring ind_mpio, replace

* Guardar .dta final
keep if departamento == "Antioquia"
save "$data/poblacion_municipal_total_2025.dta", replace


* Limpiar archivos temporales
erase "_tmp_general.dta"
erase "_tmp_rural.dta"
erase "_tmp_cabecera.dta"
erase "_tmp_base_total.dta"
erase "_tmp_p_rural.dta"
erase "_tmp_p_urbano.dta"



