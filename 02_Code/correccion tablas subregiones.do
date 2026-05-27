preserve

    keep ind_mpio nvl_label subregion id_provincia provincia ///
         tot_pob_alcantarillado ///
         urb_pob_alcantarillado ///
         rur_pob_alcantarillado

    gen tipo_fila = "Municipio"

    tempfile base promedio subregiones
    save `base'

    /*----------------------------------*
    * Base única de subregión
    *----------------------------------*
    use `base', clear
    keep id_provincia subregion
    duplicates drop id_provincia, force
    save `subregiones'
*/
    *----------------------------------*
    * Promedio provincial
    *----------------------------------*
    use `base', clear

    collapse ///
        (mean) ///
        tot_pob_alcantarillado ///
        urb_pob_alcantarillado ///
        rur_pob_alcantarillado ///
        (count) n_municipios = ind_mpio, ///
        by(id_provincia provincia)

    gen nvl_label = "PROMEDIO " + upper(provincia)
    gen tipo_fila = "Promedio provincia"

    merge 1:1 id_provincia using `subregiones', nogen

    save `promedio'

    *----------------------------------*
    * Unir todo
    *----------------------------------*
    use `base', clear
    append using `promedio'

    gen orden_fila = 1 if tipo_fila == "Municipio"
    replace orden_fila = 2 if tipo_fila == "Promedio provincia"

    sort subregion id_provincia orden_fila nvl_label

    *----------------------------------*
    * Labels
    *----------------------------------*
    label variable ind_mpio                 "Código DANE"
    label variable nvl_label                "Municipio"
    label variable subregion                "Subregión"
    label variable provincia                "Provincia"
    label variable tipo_fila                "Tipo de fila"

    label variable tot_pob_alcantarillado ///
        "Cobertura alcantarillado total"

    label variable urb_pob_alcantarillado ///
        "Cobertura alcantarillado urbana"

    label variable rur_pob_alcantarillado ///
        "Cobertura alcantarillado rural"

    format tot_pob_alcantarillado ///
           urb_pob_alcantarillado ///
           rur_pob_alcantarillado %6.1f

    *----------------------------------*
    * Exportar
    *----------------------------------*
    export excel ///
        ind_mpio nvl_label subregion provincia tipo_fila ///
        tot_pob_alcantarillado ///
        urb_pob_alcantarillado ///
        rur_pob_alcantarillado ///
        using "$output/tablas_3.3_5.4.xlsx", ///
        sheet("alcantarillado") ///
        firstrow(varlabels) sheetreplace

restore