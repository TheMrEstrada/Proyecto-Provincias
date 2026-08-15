cls
clear all
set more off

* ============================================================
* Verificación conflictos POTA / suelos de protección
* Procesa todos los municipios en TABLAS MUNICIPALES octubre
* Autor: script generado para verificación ficha vs excel
* ============================================================

* ---- Configuración de directorios ----
global path "D:/LAURA/Trabajo/EAFIT/Proyectos/Provincias/git/Proyecto-Provincias"
global base "$path/01_Data/00_Inputs/TABLAS MUNICIPALES octubre"
global outpath "$path/01_Data/01_Derived"

capture mkdir "$outpath"

tempfile resultados
tempname memhold

postfile `memhold' ///
    str5   codmpio               ///
    str60  municipio             ///
    str10  grupo                 ///
    n_predios_rural               ///
    double pct_uso_adecuado_rural ///
    double pct_sobreutilizacion_rural ///
    double pct_subutilizacion_rural   ///
    double pct_sin_conflicto_rural    ///
    double chk_pct_sum            ///
    n_predios_uso_adec_lt60      ///
    n_predios_uso_adec_60_80     ///
    n_predios_uso_adec_gt80      ///
    n_predios_uso_adec_100       ///
    tiene_urbano                 ///
    n_predios_urbano             ///
    n_predios_favorables_proteccion ///
    n_predios_no_favorables      ///
    using "`resultados'", replace

forvalues g = 1/8 {

    local folder "$base/GRUPO `g'"
    local files : dir "`folder'" files "*.xlsx"

    foreach f of local files {

        local fullpath "`folder'/`f'"
        local fname = subinstr("`f'", ".xlsx", "", .)

        local codmpio = "NA"
        local nombre  = "`fname'"
        if regexm("`fname'", "^([0-9]+)_conflictos_(.+)$") {
            local codmpio = regexs(1)
            local nombre  = regexs(2)
        }

        di as text "----------------------------------------"
        di as text "GRUPO `g' -> `codmpio' - `nombre'"

        local n_rural   = .
        local pct_adec  = .
        local pct_sobre = .
        local pct_sub   = .
        local pct_sin   = .
        local chk_sum   = .
        local n_lt60    = .
        local n_60_80   = .
        local n_gt80    = .
        local n_100     = .
        local tiene_urbano   = 0
        local n_urbano       = .
        local n_favorable    = .
        local n_no_favorable = .

        * ===================== HOJA RURAL =====================
capture import excel using "`fullpath'", sheet("RURAL") cellrange(A1) clear

if _rc {
    di as error "  No se pudo leer hoja RURAL en `f'"
}
else {
    qui ds
    local vlist `r(varlist)'
    foreach v of local vlist {
        capture local hdr = `v'[1]
        if _rc local hdr ""
        local hdr = lower("`hdr'")

             if strpos("`hdr'","cartograf")                          capture rename `v' area_cartografia
        else if strpos("`hdr'","adecuado") & strpos("`hdr'","%")     capture rename `v' pct_adecuado
        else if strpos("`hdr'","adecuado")                          capture rename `v' area_adecuado
        else if strpos("`hdr'","sobreutiliz") & strpos("`hdr'","%")  capture rename `v' pct_sobre
        else if strpos("`hdr'","sobreutiliz")                      capture rename `v' area_sobre
        else if strpos("`hdr'","subutiliz") & strpos("`hdr'","%")   capture rename `v' pct_sub
        else if strpos("`hdr'","subutiliz")                        capture rename `v' area_sub
        else if strpos("`hdr'","sin conflicto") & strpos("`hdr'","%") capture rename `v' pct_sin
        else if strpos("`hdr'","sin conflicto")                     capture rename `v' area_sin
        else if strpos("`hdr'","verific")                          capture rename `v' pct_verif
        else if strpos("`hdr'","total") & !strpos("`hdr'","%")      capture rename `v' area_total
        else if strpos("`hdr'","npn")                              capture rename `v' npn
        else if strpos("`hdr'","pk")                                capture rename `v' pk_predio
    }

    drop in 1

    capture confirm variable area_total
    local rc_area = _rc
    capture confirm variable pct_adecuado
    local rc_pct  = _rc

    if `rc_area' | `rc_pct' {
        di as error "  No se reconocieron todas las columnas esperadas en RURAL de `f', revisar encabezados"
    }
    else {
        destring area_adecuado area_sobre area_sub area_sin area_total pct_adecuado, replace force

        count
        local n_rural = r(N)

        count if pct_adecuado < 0.60
        local n_lt60 = r(N)
        count if pct_adecuado >= 0.60 & pct_adecuado < 0.80
        local n_60_80 = r(N)
        count if pct_adecuado >= 0.80
        local n_gt80 = r(N)
        count if pct_adecuado >= 0.999999
        local n_100 = r(N)

        quietly summarize area_adecuado
        local tot_adec = r(sum)
        quietly summarize area_sobre
        local tot_sobre = r(sum)
        quietly summarize area_sub
        local tot_sub = r(sum)
        quietly summarize area_sin
        local tot_sin = r(sum)
        quietly summarize area_total
        local tot_area = r(sum)

        if `tot_area' > 0 {
            local pct_adec  = `tot_adec'/`tot_area'*100
            local pct_sobre = `tot_sobre'/`tot_area'*100
            local pct_sub   = `tot_sub'/`tot_area'*100
            local pct_sin   = `tot_sin'/`tot_area'*100
            local chk_sum   = `pct_adec' + `pct_sobre' + `pct_sub' + `pct_sin'
        }
    }
}

 * ===================== HOJA URBANO (puede no existir) =====================
capture import excel using "`fullpath'", sheet("URBANO") cellrange(A1) clear

if _rc == 0 {
    qui ds
    local vlist `r(varlist)'
    foreach v of local vlist {
        capture local hdr = `v'[1]
        if _rc local hdr ""
        local hdr = lower("`hdr'")

             if strpos("`hdr'","calific") capture rename `v' conflicto_urbano
        else if strpos("`hdr'","npn")     capture rename `v' npn
        else if strpos("`hdr'","pk")      capture rename `v' pk_predio
    }

    drop in 1

    capture confirm variable conflicto_urbano
    if _rc == 0 {
        destring conflicto_urbano, replace force
        count
        local n_urbano = r(N)
        count if conflicto_urbano == 1
        local n_favorable = r(N)
        count if conflicto_urbano == 0
        local n_no_favorable = r(N)
        local tiene_urbano = 1
    }
    else {
        di as error "  Hoja URBANO existe pero no se reconoció columna de calificación en `f'"
    }
	
else {
    di as text "  (sin hoja URBANO, municipio solo rural)"
}

        post `memhold' ("`codmpio'") ("`nombre'") ("GRUPO `g'") ///
            (`n_rural') (`pct_adec') (`pct_sobre') (`pct_sub') (`pct_sin') (`chk_sum') ///
            (`n_lt60') (`n_60_80') (`n_gt80') (`n_100') ///
            (`tiene_urbano') (`n_urbano') (`n_favorable') (`n_no_favorable')
    }
}
}

postclose `memhold'

use "`resultados'", clear
sort codmpio

label variable codmpio                        "Código DIVIPOLA municipio"
label variable municipio                      "Nombre municipio"
label variable grupo                          "Carpeta GRUPO de origen"
label variable n_predios_rural                "N predios rurales (excel)"
label variable pct_uso_adecuado_rural         "% área uso adecuado rural"
label variable pct_sobreutilizacion_rural     "% área sobreutilización rural"
label variable pct_subutilizacion_rural       "% área subutilización rural"
label variable pct_sin_conflicto_rural        "% área sin conflicto rural"
label variable chk_pct_sum                    "Control: suma de los 4 % (debe ser ~100)"
label variable n_predios_uso_adec_lt60        "N predios uso adecuado <60%"
label variable n_predios_uso_adec_60_80       "N predios uso adecuado 60-80%"
label variable n_predios_uso_adec_gt80        "N predios uso adecuado >80%"
label variable n_predios_uso_adec_100         "N predios uso adecuado =100%"
label variable tiene_urbano                   "1 = municipio tiene hoja URBANO"
label variable n_predios_urbano               "N predios urbanos (excel)"
label variable n_predios_favorables_proteccion "N predios urbanos favorables a protección (calificación=1)"
label variable n_predios_no_favorables        "N predios urbanos calificación=0"

export excel using "$outpath/uso_del_suelo_pota.xlsx", ///
    firstrow(variables) replace

di as result "----------------------------------------"
di as result "Listo. Municipios procesados: " _N
count if tiene_urbano == 1
di as result "Municipios con hoja URBANO: " r(N)
count if tiene_urbano == 0
di as result "Municipios solo RURAL: " r(N)
count if abs(chk_pct_sum - 100) > 1 & !missing(chk_pct_sum)
di as result "Municipios con chk_pct_sum fuera de rango [99,101]: " r(N)

di as result "Archivo exportado a: $outpath/uso_del_suelo_pota.xlsx"