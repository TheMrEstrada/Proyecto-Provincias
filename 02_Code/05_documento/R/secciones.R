# =============================================================================
# secciones.R — El contenido de cada sección del borrador provincial
#
# Una función por sección del Anexo 1. Cada una devuelve el bloque de Markdown
# de su sección, ya redactado: enunciado factual, detalle municipal, comparación
# con la subregión y el departamento, y la implicación para la formulación del
# Plan.
#
# HASTA DÓNDE LLEGA LA REDACCIÓN
#   Cada afirmación se apoya en una cifra calculada o en una medida derivada de
#   diagnosticos.R. Donde la frase natural exigiría conocimiento de campo —por
#   qué un municipio se comporta como se comporta, qué corredor vial explica un
#   patrón, qué actor está detrás de una economía ilegal— el texto se detiene y
#   deja una nota de verificación. Escribir esa causa sin fuente sería inventar,
#   que es justamente lo que este proyecto no hace.
#
# Los encabezados y su orden son los del Anexo 1, verificados sobre el propio
# documento. No se reordenan ni se añaden.
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

# Formatos de número que usa el informe.
.f0   <- function(x) num_co(x, 0)
.f1   <- function(x) num_co(x, 1)
.f2   <- function(x) num_co(x, 2)
.fpct <- function(x) pct_co(x * 100, dec = 1)
.fkm2 <- function(x) paste0(num_co(x, 0), " km²")
.fhab <- function(x) paste0(num_co(x, 0), " hab.")

#' Une párrafos descartando los que quedaron vacíos porque su hoja no existe.
.p <- function(...) {
  x <- unlist(list(...))
  x <- x[!is.na(x) & nzchar(trimws(x))]
  # Una frase que quedó a medias porque faltaba un agregado no se publica.
  x[!grepl("^\\s*\\.$", x)]
}

# =============================================================================
# 01 Generalidades
# =============================================================================

seccion_generalidades <- function(prov, ctx) {
  d <- hoja_publicada(prov, "01_Generalidades", "distribucion_territorial.xlsx",
                      "distribucion_territorial")
  if (is.null(d)) return(character(0))

  conc <- perfil_concentracion(d, "Área municipal (km²)")
  brecha <- perfil_brecha(d, "Área municipal (km²)")
  bajo <- extremos(d, "Área municipal (km²)", 2, FALSE, .fkm2)
  alto <- extremos(d, "Área municipal (km²)", 2, TRUE, .fkm2)
  pos <- posicion(d, "Área municipal (km²)")

  .p(
    sprintf(paste(
      "La Provincia %s se extiende sobre %s distribuidos entre sus %d",
      "municipios. La superficie está %s: %s reúnen el %s del territorio",
      "provincial, mientras que %s registran las menores extensiones. La razón",
      "entre el municipio más extenso y el más pequeño es de %s a 1, una brecha",
      "%s en términos de la escala a la que cada administración municipal debe",
      "operar."),
      prov$etiqueta, .fkm2(ctx$area_km2), ctx$n,
      conc$clase, conc$nombres_dos, pct_co(conc$pct_dos * 100, dec = 0),
      bajo$texto, .f1(brecha$razon), brecha$clase),

    sprintf(paste(
      "Esa desigualdad de tamaño no es un dato administrativo menor. Un",
      "municipio como %s, con %s, tiene que llevar servicios a un territorio",
      "%s veces mayor que %s con una estructura institucional que la",
      "categorización municipal no diferencia en la misma proporción. La",
      "distancia entre cabeceras, el costo de la red terciaria y el alcance",
      "real de cualquier intervención supramunicipal dependen de esta",
      "geometría, y conviene tenerla presente al dimensionar las apuestas del",
      "Plan."),
      alto$nombres[1], .fkm2(alto$valores[1]), .f0(brecha$razon),
      bajo$nombres[1]),

    if (!is.na(pos$dep) && !is.na(pos$prov)) sprintf(paste(
      "En el contexto departamental, la Provincia representa el %s de la",
      "superficie de Antioquia."),
      pct_co(ctx$area_km2 / pos$dep * 100, dec = 1)) else "",

    verificar(
      "qué articula internamente a esta Provincia más allá de la contigüidad ",
      "—corredores viales, cuencas, relaciones funcionales— y cómo se enuncian ",
      "los Hechos Provinciales en la versión preliminar del Plan. El dato ",
      "territorial describe la forma, no la razón de ser del esquema asociativo.")
  )
}

# =============================================================================
# 02 Demografía
# =============================================================================

seccion_demografia <- function(prov, ctx) {
  out <- character(0)
  pob <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx", "poblacion")

  if (!is.null(pob)) {
    conc <- perfil_concentracion(pob, "Población total")
    bajo <- extremos(pob, "Población total", 3, FALSE, .fhab)
    rur <- grado_ruralidad(ctx)
    dens_alto <- extremos(pob, "Densidad poblacional (hab/km²)", 2, TRUE, .f1)
    dens_bajo <- extremos(pob, "Densidad poblacional (hab/km²)", 2, FALSE, .f1)
    brecha_dens <- perfil_brecha(pob, "Densidad poblacional (hab/km²)")
    n_sobre <- cuantos_superan(pob, "Población total", ctx$poblacion / ctx$n)

    out <- .p(out,
      sprintf(paste(
        "La Provincia %s reúne una población proyectada de %s habitantes para",
        "2025, repartida de forma desigual entre sus %d municipios. La",
        "distribución está %s: %s concentran el %s del total provincial,",
        "mientras que %s registran los menores tamaños. Solo %d de los %d",
        "municipios superan el promedio provincial de %s habitantes, lo que",
        "indica que la media no describe al municipio típico de la Provincia."),
        prov$etiqueta, .f0(ctx$poblacion), ctx$n,
        conc$clase, conc$nombres_dos, pct_co(conc$pct_dos * 100, dec = 0),
        bajo$texto, n_sobre, ctx$n, .f0(ctx$poblacion / ctx$n)),

      sprintf(paste(
        "En su composición, la Provincia es %s: el %s de sus habitantes reside",
        "en centros poblados y rural disperso. Esa proporción condiciona todo",
        "lo que viene después en este diagnóstico —el costo de la cobertura",
        "educativa y de salud, la dependencia de la red terciaria, la",
        "informalidad laboral— y es el rasgo que más distingue a un territorio",
        "como este de la lógica urbana con que suelen diseñarse los",
        "instrumentos de planificación."),
        rur$clase, pct_co(rur$pct * 100, dec = 1)),

      sprintf(paste(
        "La densidad poblacional confirma el patrón de ocupación. %s registran",
        "las densidades más altas y %s las más bajas, todas en habitantes por",
        "km². La razón entre el extremo alto y el bajo es de %s a 1: dentro de",
        "una misma Provincia conviven realidades de poblamiento que exigen",
        "respuestas distintas. La densidad provincial en conjunto es de %s",
        "hab/km². %s"),
        dens_alto$texto, dens_bajo$texto, .f1(brecha_dens$razon),
        .f1(ctx$poblacion / ctx$area_km2),
        frase_contiguidad(prov, pob, "Densidad poblacional (hab/km²)", 3, TRUE))
    )
  }

  est <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx",
                        "estructura_edad")
  if (!is.null(est)) {
    grupos <- c("0 a 9", "10 a 19", "20 a 29", "30 a 39", "40 a 49",
                "50 a 59", "60 a 69", "70 a 79", "80 o más")
    grupos <- grupos[grupos %in% names(est)]
    tot <- vapply(grupos, function(g) valor_agregado(est, g, "provincia"), numeric(1))
    h <- valor_agregado(est, "Población masculina", "provincia")
    m <- valor_agregado(est, "Población femenina", "provincia")
    if (all(!is.na(tot)) && sum(tot) > 0) {
      suma <- sum(tot)
      menores <- sum(tot[grupos %in% c("0 a 9", "10 a 19")])
      mayores <- sum(tot[grupos %in% c("60 a 69", "70 a 79", "80 o más")])
      out <- .p(out, sprintf(paste(
        "La estructura por edad da la medida de esa transición. Los menores de",
        "veinte años representan el %s de la población provincial y los mayores",
        "de sesenta el %s; el grupo más numeroso es el de %s. La razón de",
        "masculinidad es de %s hombres por cada cien mujeres. Una pirámide con",
        "la base estrechándose y la cúspide ensanchándose anticipa, en el",
        "horizonte del Plan, menos demanda escolar y más demanda de servicios",
        "de salud y de cuidado."),
        pct_co(menores / suma * 100, dec = 1),
        pct_co(mayores / suma * 100, dec = 1),
        grupos[which.max(tot)],
        if (!is.na(h) && !is.na(m) && m > 0) .f1(h / m * 100) else "—"))
    }
  }

  dep <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                        "dependencia_economica")
  if (!is.null(dep)) {
    col <- "Índice de Dependencia Económica"
    pos_dep <- posicion(dep, col)
    alto <- extremos(dep, col, 2, TRUE, .f1)
    if (!is.na(pos_dep$prov)) {
      out <- .p(out, sprintf(paste(
        "El Índice de Dependencia Económica resume las dos puntas de la",
        "pirámide: cuántas personas en edades dependientes —menores de quince y",
        "mayores de sesenta y cuatro— hay por cada cien en edad de trabajar. En",
        "la Provincia es de %s, y alcanza sus valores más altos en %s%s. Es la",
        "cifra que traduce la estructura demográfica en carga efectiva sobre la",
        "población productiva."),
        .f1(pos_dep$prov), alto$texto,
        if (nzchar(frase_brecha(pos_dep, "dep", "dependencia", .f1)))
          paste0(", ", frase_brecha(pos_dep, "dep", "dependencia", .f1)) else ""))
    }
  }

  vit <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx",
                        "natalidad_mortalidad")
  if (!is.null(vit)) {
    env <- extremos(vit, "Índice de Envejecimiento", 3, TRUE, .f1)
    pos_env <- posicion(vit, "Índice de Envejecimiento")
    pos_nat <- posicion(vit, "Tasa de Natalidad")
    out <- .p(out,
      sprintf(paste(
        "La dinámica vital muestra una Provincia que envejece. %s presentan",
        "los índices de envejecimiento más altos —adultos mayores por cada cien",
        "menores de quince años—. La Provincia registra un índice de %s, %s%s"),
        env$texto, .f1(pos_env$prov),
        frase_brecha(pos_env, "sub", "envejecimiento", .f1),
        if (nzchar(frase_brecha(pos_env, "dep", "envejecimiento", .f1)))
          paste0(", y ", frase_brecha(pos_env, "dep", "envejecimiento", .f1), ".")
        else "."),

      if (!is.na(pos_nat$prov)) sprintf(paste(
        "La natalidad, de %s nacimientos por cada mil habitantes, se sitúa %s.",
        "Un territorio que envejece y con natalidad contenida tiene una ventana",
        "de planificación distinta: la presión se desplaza de la infraestructura",
        "educativa hacia los servicios de salud y cuidado, y el relevo",
        "generacional de la actividad productiva rural deja de estar",
        "garantizado."),
        .f2(pos_nat$prov),
        frase_brecha(pos_nat, "dep", "natalidad", .f2)) else ""
    )
  }

  mig <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx", "migracion")
  if (!is.null(mig)) {
    col <- "Tasa neta de migración - total"
    signo <- perfil_signo(mig, col)
    rec <- extremos(mig, col, 2, TRUE, .f2)
    baj <- extremos(mig, col, 2, FALSE, .f2)
    # La serie de la ECV no toma valores negativos en ningún municipio, así que
    # no puede leerse como un saldo entre quienes llegan y quienes se van. Se
    # describe lo que el dato sí dice y se deja la definición para verificar.
    out <- .p(out,
      if (isTRUE(signo$hay_negativos)) sprintf(paste(
        "La migración interna completa el cuadro. %s registran los saldos netos",
        "más negativos y %s los más positivos. De los %d municipios de la",
        "Provincia, %d pierden población por traslado, una dinámica que se suma",
        "al envejecimiento porque quien se va suele ser población joven en edad",
        "de trabajar."),
        baj$texto, rec$texto, ctx$n, signo$negativos)
      else sprintf(paste(
        "La tasa neta de migración de la ECV 2023 va de %s a %s entre los",
        "municipios de la Provincia, con los valores más altos en %s. Conviene",
        "notar que en esta fuente el indicador no toma valores negativos en",
        "ningún municipio: no puede leerse, por tanto, como un saldo entre",
        "quienes llegan y quienes se van, y no sostiene por sí solo una",
        "afirmación sobre expulsión de población."),
        .f2(signo$min), .f2(signo$max), rec$texto),

      verificar(
        "la definición exacta de la «tasa neta de migración» en la ECV 2023 ",
        "—si mide inmigración, emigración o saldo— y, con ella, hacia dónde se ",
        "dirige la población que sale de la Provincia.")
    )
  }
  out
}

# =============================================================================
# 03 Ordenamiento del Territorio
# =============================================================================

seccion_ordenamiento <- function(prov, ctx) {
  list(
    intro = .p(sprintf(paste(
      "El ordenamiento del territorio reúne aquí cuatro asuntos que en la",
      "práctica se condicionan entre sí: los instrumentos con que cada",
      "municipio ordena su suelo, la conectividad que determina qué tan lejos",
      "queda cada cabecera del resto, las capacidades de ciencia y tecnología, y",
      "las condiciones de la vivienda y los servicios domiciliarios. En una",
      "Provincia %s como %s, los cuatro se resuelven sobre el mismo obstáculo:",
      "la dispersión."),
      grado_ruralidad(ctx)$clase, prov$etiqueta)),

    pot = {
      d <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "uso_suelo_rural")
      p <- character(0)
      if (!is.null(d)) {
        col <- "Predios con uso adecuado del suelo rural"
        alto <- extremos(d, col, 2, TRUE, .fpct)
        bajo <- extremos(d, col, 2, FALSE, .fpct)
        m <- solo_municipios(d)
        sin_dato <- sum(is.na(suppressWarnings(as.numeric(m[[col]]))))
        p <- .p(p, sprintf(paste(
          "El uso adecuado del suelo rural, medido por el POTA, alcanza sus",
          "valores más altos en %s y los más bajos en %s. La diferencia mide",
          "cuánta de la actividad que hoy ocurre sobre el suelo corresponde a su",
          "vocación: donde el porcentaje es bajo, el conflicto de uso ya está",
          "instalado y el ordenamiento tiene que corregir, no solo orientar.%s"),
          alto$texto, bajo$texto,
          if (sin_dato > 0) sprintf(paste(
            " La fuente no cubre %d de los %d municipios de la Provincia; esas",
            "celdas quedan vacías y no deben leerse como ceros."),
            sin_dato, ctx$n) else ""))
      }
      cat <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                            "catastro")
      if (!is.null(cat)) {
        m <- solo_municipios(cat)
        est <- table(as.character(m[["Estado del catastro rural"]]))
        est <- sort(est[!is.na(names(est)) & names(est) != ""], decreasing = TRUE)
        sin_dato <- sum(is.na(.num(m[["Avalúo catastral total ($)"]])))
        # Se lee el agregado que ya publica la hoja (fila de provincia), no el
        # promedio simple de los municipios: la media sobrepondera a los
        # municipios pequeños. Hallazgo de Pablo (F-2-049), adoptado también
        # aquí.
        rural_prov <- valor_agregado(
          cat, "Proporción del avalúo catastral rural sobre el total", "provincia")
        p <- .p(p, sprintf(paste(
          "El catastro es la base sobre la que descansan el impuesto predial y",
          "cualquier política de suelo. En la Provincia, el avalúo rural",
          "representa el %s del avalúo catastral total,",
          "lo que confirma por la vía fiscal la ruralidad descrita",
          "en la sección demográfica.%s%s"),
          .fpct(rural_prov),
          if (length(est)) sprintf(
            " El estado más frecuente del catastro rural es «%s», en %d municipios.",
            names(est)[1], as.integer(est[1])) else "",
          if (sin_dato > 0) sprintf(
            " La fuente no cubre %d de los %d municipios de la Provincia.",
            sin_dato, ctx$n) else ""))
      }
      .p(p, verificar(
        "el estado de adopción y vigencia de los POT, PBOT y EOT de cada ",
        "municipio, que no está en las fuentes de este flujo y determina si el ",
        "Plan puede apoyarse en los instrumentos existentes o debe promover su ",
        "actualización. Conviene añadir la vigencia de la formación catastral: ",
        "un avalúo desactualizado subestima el recaudo potencial."))
    },

    vias = {
      d <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx", "vias_area")
      h <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "vias_habitantes")
      p <- character(0)
      if (!is.null(d)) {
        col <- "Km de vía terciaria por km² del municipio"
        alto <- extremos(d, col, 2, TRUE, .f2)
        bajo <- extremos(d, col, 2, FALSE, .f2)
        brecha <- perfil_brecha(d, col)
        p <- .p(p, sprintf(paste(
          "La red terciaria es la que conecta la producción rural con la",
          "cabecera y, por lo tanto, la que decide si la vocación agropecuaria",
          "de un municipio llega o no al mercado. Medida en kilómetros por km²",
          "de territorio, es mayor en %s y menor en %s, con una razón de %s a 1",
          "entre los extremos."),
          alto$texto, bajo$texto, .f1(brecha$razon)))
      }
      if (!is.null(h)) {
        col <- "Km de vía terciaria por cada 1.000 hab."
        alto <- extremos(h, col, 2, TRUE, .f2)
        p <- .p(p, sprintf(paste(
          "Leída por habitante en vez de por área, la misma red cambia de",
          "orden: %s encabezan la Provincia. Las dos lecturas son necesarias.",
          "La primera dice cuánto territorio queda sin cubrir; la segunda,",
          "cuánta vía sostiene cada habitante, que es lo que pesa sobre la",
          "capacidad de mantenimiento del municipio."),
          alto$texto))
      }
      .p(p, verificar(
        "el estado de la red —no solo su extensión— y qué corredores ",
        "primarios y secundarios articulan la Provincia con el resto del ",
        "departamento. Los kilómetros disponibles no dicen nada sobre su ",
        "transitabilidad en invierno, que es lo que determina el aislamiento real."))
    },

    cti = {
      d <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "internet_2025")
      g <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "gobierno_digital")
      t <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx", "tti_edsup")
      p <- character(0)
      if (!is.null(d)) {
        col <- "Líneas de acceso a internet fijo por cada 1.000 habitantes"
        alto <- extremos(d, col, 2, TRUE, .f1)
        bajo <- extremos(d, col, 2, FALSE, .f1)
        # Se lee el agregado que ya publica la hoja, no el promedio simple de
        # los municipios. Hallazgo de Pablo (F-2-049), adoptado también aquí.
        fib_prov <- valor_agregado(d, "Proporción de líneas sobre fibra óptica",
                                   "provincia")
        p <- .p(p, sprintf(paste(
          "El acceso a internet fijo describe la brecha digital interna de la",
          "Provincia. Medido en líneas por cada mil habitantes, es mayor en %s",
          "y menor en %s.%s"),
          alto$texto, bajo$texto,
          if (!is.na(fib_prov)) sprintf(paste(
            " La fibra óptica, que es la tecnología que sostiene un uso",
            "intensivo, representa el %s de las líneas de la",
            "Provincia."),
            .fpct(fib_prov)) else ""))
      }
      if (!is.null(g)) {
        pos_g <- posicion(g, "Índice de Gobierno Digital")
        alto <- extremos(g, "Índice de Gobierno Digital", 2, TRUE, .f1)
        p <- .p(p, sprintf(paste(
          "En capacidad institucional digital, el Índice de Gobierno Digital",
          "sitúa a %s en la parte alta de la Provincia. El promedio provincial",
          "ponderado por población es de %s sobre 100%s. Conectividad y",
          "capacidad institucional se necesitan mutuamente: la primera sin la",
          "segunda deja el trámite en papel, y la segunda sin la primera no",
          "llega al ciudadano rural."),
          alto$texto, .f1(pos_g$prov),
          if (nzchar(frase_brecha(pos_g, "sub", "gobierno digital", .f1)))
            paste0(", ", frase_brecha(pos_g, "sub", "gobierno digital", .f1)) else ""))
      }
      if (!is.null(t)) {
        pos_t <- posicion(t, "Tasa de tránsito inmediato a la educación superior",
                          en_puntos = TRUE)
        if (!is.na(pos_t$prov)) {
          p <- .p(p, sprintf(paste(
            "El tránsito inmediato a la educación superior alcanza el %s en la",
            "Provincia. Es el indicador que cierra el círculo de esta",
            "subsección: sin acceso digital ni oferta cercana, la continuidad",
            "educativa depende de que el joven se desplace, y el desplazamiento",
            "es justamente lo que la dispersión encarece."),
            .fpct(pos_t$prov)))
        }
      }
      im <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx", "imca")
      if (!is.null(im) && "IMCA total" %in% names(im)) {
        pos_im <- posicion(im, "IMCA total")
        alto <- extremos(im, "IMCA total", 2, TRUE, .f1)
        dims <- c(`IMCA innovación` = "innovación",
                  `IMCA adopción TIC` = "adopción de TIC",
                  `IMCA capacidades` = "capacidades",
                  `IMCA infraestructura` = "infraestructura")
        dims <- dims[names(dims) %in% names(im)]
        vals <- vapply(names(dims), function(k) valor_agregado(im, k, "provincia"),
                       numeric(1))
        vals <- vals[!is.na(vals)]
        if (!is.na(pos_im$prov)) {
          p <- .p(p, sprintf(paste(
            "El Índice Municipal de Competitividad de Antioquia sitúa a la",
            "Provincia en %s sobre 100, encabezada por %s.%s"),
            .f1(pos_im$prov), alto$texto,
            if (length(vals) >= 2) {
              # Una dimensión en cero no es «margen de mejora»: en el IMCA la
              # innovación solo toma valor positivo en un puñado de municipios
              # del departamento, y presentarla como brecha del territorio
              # confundiría una propiedad del índice con un rasgo de la
              # Provincia.
              baja <- names(which.min(vals))
              if (min(vals) == 0) {
                sprintf(paste0(
                  " La dimensión de %s es 0 en todos los municipios de la",
                  " Provincia; en el conjunto de Antioquia solo un puñado de",
                  " municipios registra valor positivo, de modo que el cero",
                  " describe la concentración del indicador antes que una",
                  " carencia particular de este territorio."),
                  dims[[baja]])
              } else {
                sprintf(paste0(
                  " Entre sus dimensiones, la más baja es %s (%s), que es donde",
                  " una intervención de CTI encontraría el mayor margen."),
                  dims[[baja]], .f1(min(vals)))
              }
            } else ""))
        }
      }
      .p(p, verificar(
        "qué oferta de educación superior y de formación técnica existe dentro ",
        "de la Provincia o a distancia razonable, y si hay iniciativas de CTI ",
        "en marcha con la Gobernación o con universidades."))
    },

    vivienda = {
      d <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "deficit_vivienda")
      s <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx",
                          "servicios_publicos")
      p <- character(0)
      if (!is.null(d)) {
        pos_cuanti <- posicion(d, "Déficit cuantitativo de vivienda", en_puntos = TRUE)
        pos_cuali <- posicion(d, "Déficit cualitativo de vivienda", en_puntos = TRUE)
        alto_cuanti <- extremos(d, "Déficit cuantitativo de vivienda", 2, TRUE, .fpct)
        alto_cuali <- extremos(d, "Déficit cualitativo de vivienda", 3, TRUE, .fpct)
        p <- .p(p, sprintf(paste(
          "El déficit habitacional se mide en dos dimensiones que piden",
          "políticas distintas. El déficit **cuantitativo** —hogares sin",
          "vivienda o en una irrecuperable— afecta al %s de las viviendas de la",
          "Provincia y se concentra en %s; se resuelve construyendo. El déficit",
          "**cualitativo** —vivienda mejorable en materiales, servicios o",
          "espacio— afecta al %s y es más alto en %s; se resuelve mejorando lo",
          "existente, que es una intervención más barata y de mayor alcance."),
          .fpct(pos_cuanti$prov), alto_cuanti$texto,
          .fpct(pos_cuali$prov), alto_cuali$texto),

          sprintf(paste(
            "Frente a su entorno, la Provincia está %s en déficit cualitativo.",
            "%s"),
            frase_brecha(pos_cuali, "dep", "déficit cualitativo", .fpct),
            frase_contiguidad(prov, d, "Déficit cualitativo de vivienda", 3, TRUE)))
      }
      if (!is.null(s)) {
        # Se lee el agregado que ya publica la hoja («… (agregado)»), no el
        # promedio simple de las columnas municipales: la media sobrepondera
        # a los municipios pequeños, que son los de peor cobertura (medido:
        # +1,5 pp en acueducto, +0,5 pp en alcantarillado, +0,1 pp en energía
        # para Del Río Grande). Hallazgo de Pablo (F-2-049), adoptado también
        # aquí.
        cobs <- c("Cobertura de acueducto (agregado)",
                  "Cobertura de alcantarillado (agregado)",
                  "Cobertura de energía (agregado)")
        cobs <- cobs[cobs %in% names(s)]
        if (length(cobs)) {
          valores <- vapply(cobs, function(cl) valor_agregado(s, cl, "provincia"),
                            numeric(1))
          hay <- !is.na(valores)
          valores <- valores[hay]
          etiqueta <- gsub(" \\(agregado\\)$", "", names(valores))
          etiqueta <- tolower(gsub("^Cobertura de ", "", etiqueta))
          if (length(valores)) {
            p <- .p(p, sprintf(paste(
              "En servicios domiciliarios, la cobertura de la Provincia",
              "es de %s. La distancia entre la cobertura de energía y la de",
              "alcantarillado es el indicador más elocuente de la ruralidad: la",
              "red eléctrica llegó, la de saneamiento no, y esa diferencia",
              "explica buena parte del déficit cualitativo descrito arriba."),
              y_lista(sprintf("%s en %s", .fpct(valores), etiqueta))))
          }
        }
      }
      .p(p, verificar(
        "si existen programas de mejoramiento de vivienda en curso en la ",
        "Provincia y con qué cobertura, para dimensionar la brecha que el Plan ",
        "tendría que cubrir."))
    }
  )
}

# =============================================================================
# 04 Gobernabilidad y capacidades territoriales
# =============================================================================

seccion_gobernabilidad <- function(prov, ctx) {
  list(
    gob = {
      d <- ultimo_anio(hoja_publicada(prov, "04_Gobernabilidad",
                                      "gobernabilidad.xlsx", "mdm"))
      p <- character(0)
      if (!is.null(d) && nrow(d)) {
        anio <- suppressWarnings(max(.num(d[["Año"]]), na.rm = TRUE))
        alto <- extremos(d, "MDM", 2, TRUE, .f1)
        bajo <- extremos(d, "MDM", 2, FALSE, .f1)
        brecha <- perfil_brecha(d, "MDM")
        p <- .p(p, sprintf(paste(
          "La capacidad de gestión de los municipios determina si una apuesta",
          "provincial se ejecuta o se queda en el papel. En la Medición de",
          "Desempeño Municipal de %d, %s obtienen los puntajes más altos de la",
          "Provincia y %s los más bajos, con una diferencia de %s puntos entre",
          "los extremos."),
          as.integer(anio), alto$texto, bajo$texto,
          .f1(brecha$max - brecha$min)),

          paste(
            "El MDM no se promedia entre municipios y este informe no publica",
            "un valor provincial: el DNP compara a cada municipio dentro de su",
            "grupo de capacidades iniciales, de modo que un promedio entre",
            "grupos distintos no tendría lectura. Lo que sí es legítimo leer es",
            "la dispersión: una Provincia con municipios en extremos opuestos",
            "necesita que el esquema asociativo compense, no solo que coordine."))
      }
      .p(p, verificar(
        "qué explica el desempeño de los municipios en los extremos —rotación ",
        "de personal, tamaño de la planta, acompañamiento departamental— y si ",
        "el esquema asociativo tiene hoy capacidad técnica propia."))
    },

    finanzas = {
      d <- ultimo_anio(hoja_publicada(prov, "04_Gobernabilidad",
                                      "gobernabilidad.xlsx", "idf"))
      l <- ultimo_anio(hoja_publicada(prov, "04_Gobernabilidad",
                                      "gobernabilidad.xlsx", "ley617"))
      p <- character(0)
      if (!is.null(d) && nrow(d)) {
        anio <- suppressWarnings(max(.num(d[["Año"]]), na.rm = TRUE))
        alto <- extremos(d, "IDF", 2, TRUE, .f1)
        bajo <- extremos(d, "IDF", 2, FALSE, .f1)
        p <- .p(p, sprintf(paste(
          "El Índice de Desempeño Fiscal de %d ubica a %s en la parte alta de",
          "la Provincia y a %s en la baja. Como el MDM, tampoco admite promedio",
          "provincial. El indicador resume la capacidad de generar recursos",
          "propios y de sostener el gasto: es el techo real de cualquier",
          "compromiso de cofinanciación que el Plan les pida asumir."),
          as.integer(anio), alto$texto, bajo$texto))
      }
      if (!is.null(l) && nrow(l)) {
        m <- solo_municipios(l)
        ind <- .num(m[["Indicador Ley 617"]])
        p <- .p(p, sprintf(paste(
          "El indicador de la Ley 617 —gastos de funcionamiento sobre ingresos",
          "corrientes de libre destinación— se publica por municipio y no se",
          "agrega: es un cociente institucional medido contra el techo legal de",
          "cada categoría, y no existe un 617 provincial. En la Provincia va de",
          "%s a %s."),
          .fpct(min(ind, na.rm = TRUE)), .fpct(max(ind, na.rm = TRUE))))
      }
      .p(p, verificar(
        "el margen real de inversión de cada municipio una vez descontado el ",
        "funcionamiento y el servicio de la deuda, y qué fuentes de ",
        "cofinanciación —regalías, SGP, cooperación— están disponibles para la ",
        "Provincia."))
    },

    icm = {
      d <- ultimo_anio(hoja_publicada(prov, "04_Gobernabilidad",
                                      "gobernabilidad.xlsx", "icm"))
      p <- character(0)
      if (!is.null(d) && nrow(d)) {
        anio <- suppressWarnings(max(.num(d[["Año"]]), na.rm = TRUE))
        alto <- extremos(d, "ICM", 2, TRUE, .f1)
        pos_icm <- posicion(d, "ICM")
        dims <- c(PCC = "condiciones de vida", GPI = "gestión pública",
                  EIS = "equidad e inclusión social", CTI = "ciencia y tecnología",
                  SEG = "seguridad", SOS = "sostenibilidad")
        dims <- dims[names(dims) %in% names(d)]
        vals <- vapply(names(dims), function(k) valor_agregado(d, k, "provincia"),
                       numeric(1))
        peor <- names(which.min(vals)); mejor <- names(which.max(vals))
        p <- .p(p, sprintf(paste(
          "El Índice de Ciudades Modernas resume en un solo número seis",
          "dimensiones del desarrollo territorial. En %d, %s encabezan la",
          "Provincia, cuyo promedio ponderado por población es de %s%s."),
          as.integer(anio), alto$texto, .f1(pos_icm$prov),
          if (nzchar(frase_brecha(pos_icm, "dep", "ICM", .f1)))
            paste0(", ", frase_brecha(pos_icm, "dep", "ICM", .f1)) else ""),

          if (length(vals) >= 2) sprintf(paste(
            "Desagregado por dimensiones, el punto más fuerte de la Provincia",
            "es %s (%s) y el más débil %s (%s). Esa asimetría es más útil para",
            "el Plan que el índice agregado: señala dónde una intervención",
            "encuentra base sobre la cual construir y dónde tendría que",
            "empezar de cero."),
            dims[[mejor]], .f1(vals[[mejor]]),
            dims[[peor]], .f1(vals[[peor]])) else "")
      }
      .p(p, verificar(
        "la evolución del ICM en la serie disponible: si la Provincia converge ",
        "o diverge respecto del departamento, que es una lectura de tendencia ",
        "y no de nivel."))
    }
  )
}

# =============================================================================
# 05 Economía y desarrollo
# =============================================================================

seccion_economia <- function(prov, ctx) {
  list(
    intro = .p(sprintf(paste(
      "Esta sección describe de qué vive la Provincia %s y en qué condiciones",
      "lo hace. Ordena cuatro asuntos: las condiciones de vida y el mercado",
      "laboral, la productividad medida por el valor agregado, la actividad",
      "minero-energética y el turismo. El hilo que los une es la pregunta de",
      "cuánta de la riqueza que se genera en el territorio se queda en él."),
      prov$etiqueta)),

    pobreza = {
      p <- character(0)
      d <- hoja_publicada(prov, "05_Economia", "economia.xlsx", "ecv_pobreza")
      i <- hoja_publicada(prov, "05_Economia", "economia.xlsx", "ecv_ipm")
      o <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                          "ecv_ocupacion_informal")
      dn <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                           "ecv_desocupacion_nini")

      if (!is.null(d)) {
        col_m <- "Personas en pobreza por NBI - total (municipal)"
        col_a <- "Personas en pobreza por NBI - total (agregado)"
        alto <- extremos(d, col_m, 3, TRUE, .fpct)
        bajo <- extremos(d, col_m, 2, FALSE, .fpct)
        pos_nbi <- posicion(d, col_a, en_puntos = TRUE)
        rur <- extremos(d, "Personas en pobreza por NBI - rural (municipal)",
                        1, TRUE, .fpct)
        p <- .p(p, sprintf(paste(
          "La pobreza medida por Necesidades Básicas Insatisfechas alcanza sus",
          "valores más altos en %s y los más bajos en %s. En el conjunto de la",
          "Provincia afecta al %s de las personas, %s. %s"),
          alto$texto, bajo$texto, .fpct(pos_nbi$prov),
          frase_brecha(pos_nbi, "dep", "NBI", .fpct),
          frase_contiguidad(prov, d, col_m, 3, TRUE)),

          if (!is.null(rur)) sprintf(paste(
            "La lectura urbano-rural es más severa que la agregada: en %s, el",
            "NBI rural llega al %s. La pobreza de esta Provincia es",
            "fundamentalmente rural, y eso significa que se resuelve con",
            "bienes públicos —agua, saneamiento, vía, escuela— antes que con",
            "transferencias."),
            rur$nombres[1], .fpct(rur$valores[1])) else "")
      }
      if (!is.null(i)) {
        col <- "Personas en pobreza IPM - total (agregado)"
        pos_ipm <- posicion(i, col, en_puntos = TRUE)
        if (!is.na(pos_ipm$prov)) {
          p <- .p(p, sprintf(paste(
            "El Índice de Pobreza Multidimensional, que mide privaciones en",
            "educación, salud, trabajo y condiciones de la vivienda, sitúa a la",
            "Provincia en %s. Las dos medidas —NBI e IPM— coinciden en el",
            "diagnóstico y difieren en el detalle: la primera señala carencias",
            "estructurales de la vivienda y la segunda añade las del acceso a",
            "servicios y al empleo."),
            .fpct(pos_ipm$prov)))
        }
      }
      if (!is.null(o)) {
        col_inf <- "Tasa de informalidad laboral - total (municipal)"
        col_to <- "Tasa de ocupación - total (municipal)"
        inf <- extremos(o, col_inf, 2, TRUE, .fpct)
        m <- solo_municipios(o)
        media_inf <- mean(.num(m[[col_inf]]), na.rm = TRUE)
        media_to <- mean(.num(m[[col_to]]), na.rm = TRUE)
        p <- .p(p, sprintf(paste(
          "En el mercado laboral, la informalidad promedio de los municipios de",
          "la Provincia es del %s y alcanza sus máximos en %s, con una tasa de",
          "ocupación promedio del %s. La informalidad no es solo un problema",
          "de ingresos: define la base tributaria del municipio, el acceso a la",
          "seguridad social y la composición del aseguramiento en salud que se",
          "describe más adelante."),
          .fpct(media_inf), inf$texto, .fpct(media_to)))
      }
      if (!is.null(dn)) {
        col <- "Jóvenes que no estudian ni trabajan (NiNi) (municipal)"
        if (col %in% names(dn)) {
          nini <- extremos(dn, col, 2, TRUE, .fpct)
          p <- .p(p, sprintf(paste(
            "Entre la población joven, la proporción que no estudia ni trabaja",
            "es más alta en %s. Es el indicador que conecta esta sección con la",
            "de educación y con la de seguridad: un joven fuera del sistema",
            "educativo y del mercado laboral formal es, en términos de política",
            "pública, una oportunidad perdida y un riesgo."),
            nini$texto))
        }
      }
      .p(p, verificar(
        "qué actividades absorben el empleo informal en la Provincia y si ",
        "existen procesos de formalización en marcha. La ECV mide la ",
        "condición, no el sector que la genera."))
    },

    productividad = {
      p <- character(0)
      va <- ultimo_anio(hoja_publicada(prov, "05_Economia", "economia.xlsx",
                                       "valor_agregado"))
      de <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                           "densidad_empresarial")
      if (!is.null(va) && nrow(va)) {
        anio <- suppressWarnings(max(.num(va[["Año"]]), na.rm = TRUE))
        col_va <- "Valor agregado total (miles de millones $ constantes de 2015)"
        conc <- perfil_concentracion(va, col_va)
        pc <- extremos(va, "Valor agregado per cápita (pesos constantes de 2015)",
                       2, TRUE, .f0)
        pc_bajo <- extremos(va, "Valor agregado per cápita (pesos constantes de 2015)",
                            2, FALSE, .f0)
        prim <- valor_agregado(va, "Participación del VA - primarias", "provincia")
        sec <- valor_agregado(va, "Participación del VA - secundarias", "provincia")
        ter <- valor_agregado(va, "Participación del VA - terciarias", "provincia")
        p <- .p(p, sprintf(paste(
          "En %d, la generación de valor agregado de la Provincia está %s: %s",
          "reúnen el %s del total. El valor agregado por habitante es mayor en",
          "%s y menor en %s, una brecha que describe territorios con",
          "capacidades productivas muy distintas dentro del mismo esquema",
          "asociativo."),
          as.integer(anio), conc$clase, conc$nombres_dos,
          pct_co(conc$pct_dos * 100, dec = 0), pc$texto, pc_bajo$texto),

          if (!is.na(prim)) sprintf(paste(
            "Por composición sectorial, las actividades primarias aportan el",
            "%s del valor agregado provincial, las secundarias el %s y las",
            "terciarias el %s. Los tres agregados no suman el total: la serie a",
            "precios constantes deja un remanente sin distribuir, de modo que",
            "las participaciones se calculan siempre sobre el valor agregado",
            "total y no sobre la suma de los tres."),
            .fpct(prim), .fpct(sec), .fpct(ter)) else "",

          paste(
            "Las cifras van a precios constantes de 2015. El Anexo 1 publicó",
            "esta misma tabla a precios corrientes, de modo que los dos valores",
            "son correctos y no son comparables entre sí: la diferencia es el",
            "deflactor, no un cambio en la economía de la Provincia."))
      }
      if (!is.null(de)) {
        col <- "Densidad empresarial (empresas por cada 1.000 hab.)"
        alto <- extremos(de, col, 2, TRUE, .f2)
        pos_de <- posicion(de, col)
        p <- .p(p, sprintf(paste(
          "La densidad empresarial —empresas registradas por cada mil",
          "habitantes— es mayor en %s, con un promedio provincial ponderado de",
          "%s. Es una medida de formalización tanto como de actividad: donde la",
          "densidad es baja, buena parte de la economía existe pero no está",
          "registrada, lo que la deja fuera del crédito, de la contratación",
          "pública y de los programas de apoyo empresarial."),
          alto$texto, .f2(pos_de$prov)))
      }
      .p(p, verificar(
        "qué cadenas productivas concretas explican el valor agregado de los ",
        "municipios que lo concentran, y si existen encadenamientos entre ",
        "municipios de la Provincia o cada uno se articula por separado hacia ",
        "afuera."))
    },

    minero = {
      p <- character(0)
      cen <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                            "energia_centrales")
      par <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                            "energia_participacion")
      tit <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                            "titulos_mineros")
      if (!is.null(cen) && nrow(cen)) {
        m <- cen[!is.na(cen[["Central / Planta"]]), , drop = FALSE]
        cap <- .num(m[["Capacidad efectiva neta (MW)"]])
        if (length(cap) && any(!is.na(cap))) {
          i <- order(cap, decreasing = TRUE)[1]
          p <- .p(p, sprintf(paste(
            "La Provincia alberga %d central%s de generación con una capacidad",
            "efectiva neta de %s MW, encabezada%s por %s (%s MW). La generación",
            "eléctrica es la actividad que mejor ilustra la pregunta de esta",
            "sección: produce valor en el territorio sin que ese valor se",
            "traduzca necesariamente en empleo local ni en ingresos",
            "municipales más allá de las transferencias del sector."),
            nrow(m), if (nrow(m) == 1) "" else "es", .f2(sum(cap, na.rm = TRUE)),
            if (nrow(m) == 1) "" else "s",
            m[["Central / Planta"]][i], .f2(cap[i])))
        }
      } else {
        p <- .p(p, paste(
          "La Provincia no registra centrales de generación eléctrica en el",
          "inventario del Sistema Interconectado Nacional."))
      }
      if (!is.null(par)) {
        fila <- par[grepl("^PROVINCIA", par[["Ámbito"]]), , drop = FALSE]
        if (nrow(fila)) {
          p <- .p(p, sprintf(paste(
            "Esa capacidad representa el %s de la de Antioquia y el %s del",
            "Sistema Interconectado Nacional."),
            .fpct(.num(fila[["Participación en Antioquia"]])[1]),
            .fpct(.num(fila[["Participación en el SIN"]])[1])))
        }
      }
      if (!is.null(tit) && nrow(tit)) {
        if (grepl("SIN T", tit[["Tipo de mineral"]][1])) {
          p <- .p(p, "No hay títulos mineros vigentes en la Provincia.")
        } else {
          n <- .num(tit[["Número de títulos mineros"]])
          i <- order(n, decreasing = TRUE)
          top <- utils::head(i, 3)
          p <- .p(p, sprintf(paste(
            "En minería, la Provincia registra títulos vigentes sobre %d tipos",
            "de mineral. Los más frecuentes son %s. Se cuentan títulos activos",
            "distintos: uno que ampara varios minerales cuenta en cada uno, y",
            "uno que cubre varios municipios cuenta una sola vez."),
            nrow(tit),
            y_lista(sprintf("%s (%d títulos)",
                            tolower(tit[["Tipo de mineral"]][top]),
                            as.integer(n[top])))))
        }
      }
      .p(p, verificar(
        "qué parte de la actividad minera es formal y qué parte no, y cómo se ",
        "distribuyen las regalías y las transferencias del sector eléctrico ",
        "entre los municipios de la Provincia."))
    },

    turismo = {
      p <- character(0)
      ext <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                            "comparativo_pap_antioquia")
      ins <- hoja_publicada(prov, "05_Economia", "economia.xlsx",
                            "turismo_instrumentos")
      if (!is.null(ext) && nrow(ext)) {
        a <- .num(ext[["Año"]]); i <- which.max(a)
        p <- .p(p, sprintf(paste(
          "En %d, la Provincia recibió %s visitantes extranjeros no residentes,",
          "el %s del total departamental. La cifra cuenta visitantes",
          "extranjeros, no turistas totales: el turismo interno, que en",
          "territorios como este suele ser el grueso, no está en esta fuente."),
          as.integer(a[i]),
          .f0(.num(ext[["Visitantes extranjeros provincia"]])[i]),
          .fpct(.num(ext[["Participación de la provincia en el total departamental"]])[i])))
      }
      if (!is.null(ins) && nrow(ins)) {
        con_plan <- sum(!is.na(ins[["Plan Local de Turismo"]]) &
                          grepl("^S", toupper(as.character(ins[["Plan Local de Turismo"]]))))
        con_mesa <- sum(!is.na(ins[["Mesa Local de Turismo"]]) &
                          grepl("^S", toupper(as.character(ins[["Mesa Local de Turismo"]]))))
        p <- .p(p, sprintf(paste(
          "En instrumentos de planificación turística, %d de los %d municipios",
          "cuentan con Plan Local de Turismo y %d con Mesa Local. La capacidad",
          "de gestión del turismo antecede a la llegada de visitantes: sin",
          "instrumento local, la actividad crece sin ordenamiento y sus",
          "beneficios se capturan fuera del municipio."),
          con_plan, nrow(ins), con_mesa))
      }
      .p(p, verificar(
        "qué atractivos concretos tiene la Provincia y en qué estado están sus ",
        "inventarios turísticos, y si el turismo aparece como Hecho Provincial ",
        "en la versión preliminar del Plan."))
    }
  )
}

# =============================================================================
# 06 Desarrollo Rural
# =============================================================================

seccion_desarrollo_rural <- function(prov, ctx) {
  out <- character(0)
  inv <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural",
                                    "desarrollo_rural.xlsx", "inventario_pecuario"))
  com <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural",
                                    "desarrollo_rural.xlsx", "composicion_agricola"))
  ren <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural",
                                    "desarrollo_rural.xlsx", "rendimiento"))
  pri <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural",
                                    "desarrollo_rural.xlsx", "principales_cultivos"))

  out <- .p(out, sprintf(paste(
    "En una Provincia donde el %s de la población vive en zona rural, el",
    "desarrollo rural no es una sección sectorial más: es la descripción de la",
    "base económica de la mayoría de sus habitantes."),
    pct_co(ctx$rural / ctx$poblacion * 100, dec = 1)))

  if (!is.null(inv) && nrow(inv)) {
    anio <- suppressWarnings(max(.num(inv[["Año"]]), na.rm = TRUE))
    conc <- perfil_concentracion(inv, "Total especies pecuarias")
    especies <- c("Bovinos", "Porcinos", "Equinos", "Búfalos", "Caprinos", "Ovinos")
    especies <- especies[especies %in% names(inv)]
    tot <- vapply(especies, function(cl) valor_agregado(inv, cl, "provincia"),
                  numeric(1))
    tot <- tot[!is.na(tot) & tot > 0]
    out <- .p(out, sprintf(paste(
      "El inventario pecuario de %d suma %s cabezas en la Provincia, %s: %s",
      "reúnen el %s del total. La composición está dominada por %s.%s"),
      as.integer(anio), .f0(valor_agregado(inv, "Total especies pecuarias", "provincia")),
      conc$clase, conc$nombres_dos, pct_co(conc$pct_dos * 100, dec = 0),
      y_lista(sprintf("%s (%s)", tolower(names(sort(tot, decreasing = TRUE))[1:min(2, length(tot))]),
                      .f0(sort(tot, decreasing = TRUE)[1:min(2, length(tot))]))),
      " El inventario no incluye aves: la fuente de este flujo no las reporta."))
  }

  if (!is.null(com) && nrow(com)) {
    anio <- suppressWarnings(max(.num(com[["Año"]]), na.rm = TRUE))
    conc <- perfil_concentracion(com, "Producción agrícola total del municipio (t)")
    perm <- valor_agregado(com, "Proporción de cultivos permanentes", "provincia")
    out <- .p(out, sprintf(paste(
      "En producción agrícola, %d muestra una actividad %s: %s concentran el",
      "%s de las toneladas producidas en la Provincia.%s"),
      as.integer(anio), conc$clase, conc$nombres_dos,
      pct_co(conc$pct_dos * 100, dec = 0),
      if (!is.na(perm)) sprintf(paste(
        " Los cultivos permanentes representan el %s de la producción, frente",
        "al %s de los transitorios. El predominio de permanentes indica una",
        "estructura productiva más estable pero también menos flexible ante un",
        "cambio de precios, porque la reconversión toma años."),
        .fpct(perm), .fpct(1 - perm)) else ""))
  }

  if (!is.null(pri) && nrow(pri)) {
    cultivos <- table(as.character(pri[["Principal cultivo permanente"]]))
    cultivos <- sort(cultivos[!is.na(names(cultivos)) & names(cultivos) != ""],
                     decreasing = TRUE)
    if (length(cultivos)) {
      out <- .p(out, sprintf(paste(
        "El cultivo permanente principal es %s en %d de los %d municipios de la",
        "Provincia. Que un mismo producto domine en tantos municipios define",
        "una vocación compartida, y con ella una oportunidad de acción",
        "conjunta —asistencia técnica, acopio, comercialización— que es",
        "exactamente el tipo de intervención que justifica un esquema",
        "asociativo."),
        tolower(names(cultivos)[1]), as.integer(cultivos[1]), nrow(pri)))
    }
  }

  if (!is.null(ren) && nrow(ren)) {
    alto <- extremos(ren, "Rendimiento (t/ha)", 2, TRUE, .f2)
    bajo <- extremos(ren, "Rendimiento (t/ha)", 2, FALSE, .f2)
    prov_r <- valor_agregado(ren, "Rendimiento (t/ha)", "provincia")
    out <- .p(out, sprintf(paste(
      "El rendimiento agregado —producción total sobre área cosechada— es",
      "mayor en %s y menor en %s, con un valor provincial de %s toneladas por",
      "hectárea. El rendimiento provincial se recalcula sobre las sumas y no",
      "promedia los rendimientos municipales, que darían un número distinto y",
      "sobrerrepresentarían a los municipios de menor producción."),
      alto$texto, bajo$texto, .f2(prov_r)))
  }

  .p(out, verificar(
    "el régimen de tenencia de la tierra, el acceso a asistencia técnica y ",
    "los canales de comercialización de los principales productos. El ",
    "inventario dice qué se produce y cuánto; no dice quién lo produce ni en ",
    "qué condiciones lo vende."))
}

# =============================================================================
# 07 Ambiental
# =============================================================================

seccion_ambiental <- function(prov, ctx) {
  list(
    intro = .p(sprintf(paste(
      "La dimensión ambiental de la Provincia %s se lee en dos registros: los",
      "activos naturales que conserva —áreas protegidas, cobertura arbórea,",
      "agua— y las presiones que los amenazan, desde la deforestación hasta el",
      "riesgo de desastres. Ambos son, además, condicionantes del ordenamiento",
      "y de la actividad productiva descrita en las secciones anteriores."),
      prov$etiqueta)),

    recursos = {
      p <- character(0)
      ap <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx", "detalle")
      irca <- ultimo_anio(hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx",
                                         "irca"))
      if (!is.null(ap)) {
        m <- solo_municipios(ap)
        total <- sum(.num(m[["Área sobre municipio (km²)"]]), na.rm = TRUE)
        cats <- table(as.character(m[["Categoría"]]))
        cats <- sort(cats[!is.na(names(cats)) & names(cats) != ""], decreasing = TRUE)
        por_mpio <- tapply(.num(m[["Área sobre municipio (km²)"]]),
                           as.character(m[["Municipio"]]), sum, na.rm = TRUE)
        por_mpio <- sort(por_mpio, decreasing = TRUE)
        p <- .p(p, sprintf(paste(
          "Las áreas protegidas cubren %s del territorio de la Provincia, el %s",
          "de su superficie, repartidas en %d registros. La mayor extensión",
          "protegida corresponde a %s (%s).%s"),
          .fkm2(total), pct_co(total / ctx$area_km2 * 100, dec = 1), nrow(m),
          names(por_mpio)[1], .fkm2(por_mpio[1]),
          if (length(cats)) sprintf(
            " La figura de protección más frecuente es «%s».", names(cats)[1]) else ""))
      }
      if (!is.null(irca) && nrow(irca)) {
        anio <- suppressWarnings(max(.num(irca[["Año"]]), na.rm = TRUE))
        peor <- extremos(irca, "IRCA", 2, TRUE, .f2)
        mejor <- extremos(irca, "IRCA", 2, FALSE, .f2)
        pos_irca <- posicion(irca, "IRCA")
        p <- .p(p, sprintf(paste(
          "En calidad del agua para consumo humano, el IRCA de %d registra los",
          "niveles de riesgo más altos en %s y los más bajos en %s; en este",
          "índice un valor mayor significa peor calidad. El promedio provincial",
          "es de %s. El agua potable es el eslabón donde convergen la",
          "dispersión rural, la capacidad institucional del municipio y el",
          "déficit cualitativo de vivienda: los tres se manifiestan en el mismo",
          "indicador."),
          as.integer(anio), peor$texto, mejor$texto, .f2(pos_irca$prov)))
      }
      .p(p, verificar(
        "qué autoridad ambiental tiene jurisdicción sobre cada municipio y qué ",
        "instrumentos de manejo —POMCA, planes de manejo de áreas protegidas— ",
        "están vigentes, para saber sobre qué marco puede apoyarse el Plan."))
    },

    sostenibilidad = {
      p <- character(0)
      pc <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx",
                           "perdida_cobertura")
      im <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx", "imrc")
      ea <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx", "eventos_año")
      ds <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx",
                           "desastres_selectos")
      if (!is.null(pc)) {
        col <- "Pérdida de cobertura arbórea 2001-2023 (%)"
        alto <- extremos(pc, col, 3, TRUE, .fpct)
        pos_pc <- posicion(pc, col, en_puntos = TRUE)
        p <- .p(p, sprintf(paste(
          "La pérdida de cobertura arbórea entre 2001 y 2023 se concentra en",
          "%s. El promedio provincial es del %s, %s. %s"),
          alto$texto, .fpct(pos_pc$prov),
          frase_brecha(pos_pc, "dep", "pérdida de cobertura", .fpct),
          frase_contiguidad(prov, pc, col, 3, TRUE)))
      }
      if (!is.null(im)) {
        pe <- extremos(im, "IMRC Exceso de lluvias", 2, TRUE, .f2)
        pd <- extremos(im, "IMRC Déficit de lluvias", 2, TRUE, .f2)
        p <- .p(p, sprintf(paste(
          "El Índice Municipal de Riesgo ajustado por capacidades distingue dos",
          "amenazas climáticas opuestas. Por exceso de lluvias, los municipios",
          "más expuestos son %s; por déficit, %s. Que un mismo territorio",
          "aparezca en ambos extremos no es contradictorio: la variabilidad",
          "climática se manifiesta en las dos direcciones y exige medidas de",
          "adaptación distintas."),
          pe$texto, pd$texto))
      }
      if (!is.null(ds)) {
        m <- solo_municipios(ds)
        prev <- table(as.character(m[["Emergencia más prevalente"]]))
        prev <- sort(prev[!is.na(names(prev)) & names(prev) != ""], decreasing = TRUE)
        if (length(prev)) {
          p <- .p(p, sprintf(paste(
            "En materia de desastres, la emergencia más prevalente es %s en %d",
            "de los %d municipios de la Provincia. Conocer cuál predomina",
            "importa porque orienta la inversión en gestión del riesgo hacia un",
            "tipo de obra y de sistema de alerta y no hacia otro."),
            tolower(names(prev)[1]), as.integer(prev[1]), nrow(m)))
        }
      }
      if (!is.null(ea)) {
        m <- solo_municipios(ea)
        por_anio <- tapply(.num(m[["Número de eventos"]]),
                           as.character(m[["Año"]]), sum, na.rm = TRUE)
        por_anio <- por_anio[!is.na(names(por_anio))]
        if (length(por_anio) >= 2) {
          anios <- names(por_anio)
          p <- .p(p, sprintf(paste(
            "El registro de emergencias muestra la exposición efectiva, no solo",
            "la potencial. Entre %s y %s la Provincia acumuló %s eventos, con el",
            "máximo en %s (%s eventos) y el mínimo en %s (%s). La serie es",
            "corta y depende de la capacidad de reporte de cada municipio, de",
            "modo que un año con pocos registros no significa necesariamente un",
            "año tranquilo."),
            min(anios), max(anios), .f0(sum(por_anio)),
            anios[which.max(por_anio)], .f0(max(por_anio)),
            anios[which.min(por_anio)], .f0(min(por_anio))))
        }
      }
      .p(p, verificar(
        "qué explica la pérdida de cobertura en los municipios donde se ",
        "concentra —frontera agropecuaria, minería, cultivos de uso ilícito, ",
        "infraestructura— y si existen procesos de restauración en curso."))
    }
  )
}

# =============================================================================
# 08 Educación
# =============================================================================

seccion_educacion <- function(prov, ctx) {
  d <- ultimo_anio(hoja_publicada(prov, "08_Educacion", "educacion.xlsx",
                                  "educacion"))
  if (is.null(d) || !nrow(d)) return(character(0))
  anio <- suppressWarnings(max(.num(d[["Año"]]), na.rm = TRUE))

  pos_cob <- posicion(d, "Cobertura neta", en_puntos = TRUE)
  alto <- extremos(d, "Cobertura neta", 2, TRUE, .fpct)
  bajo <- extremos(d, "Cobertura neta", 3, FALSE, .fpct)
  des <- extremos(d, "Tasa de deserción", 2, TRUE, .fpct)
  rep <- extremos(d, "Tasa de repitencia", 2, TRUE, .fpct)
  pos_des <- posicion(d, "Tasa de deserción", en_puntos = TRUE)
  v <- .num(solo_municipios(d)[["Cobertura neta"]])

  out <- .p(
    sprintf(paste(
      "La dimensión educativa permite comprender algunas de las condiciones más",
      "significativas de desarrollo humano, equidad territorial y",
      "competitividad de la Provincia %s. En un territorio con alta ruralidad y",
      "dispersión poblacional, el acceso, la permanencia y el tránsito efectivo",
      "entre niveles son determinantes de las oportunidades de su población, y",
      "cada uno se enfrenta a un obstáculo distinto: llegar a la escuela,",
      "quedarse en ella y continuar después."),
      prov$etiqueta),

    sprintf(paste(
      "De acuerdo con la información del Ministerio de Educación Nacional para",
      "%d, la Provincia presenta una cobertura neta del %s, %s. A escala",
      "municipal las diferencias internas son significativas: %s presentan las",
      "coberturas más altas, mientras que %s registran los niveles más bajos."),
      as.integer(anio), .fpct(pos_cob$prov),
      frase_brecha(pos_cob, "dep", "cobertura neta", .fpct),
      alto$texto, bajo$texto),

    sprintf(paste(
      "La permanencia cuenta una historia complementaria. La deserción escolar",
      "es mayor en %s y la repitencia en %s, con una deserción provincial del",
      "%s. Cobertura y permanencia no se mueven necesariamente juntas: un",
      "municipio puede matricular bien y perder alumnos durante el año, y ese",
      "patrón exige una respuesta distinta —transporte, alimentación,",
      "acompañamiento— que la de ampliar cupos."),
      des$texto, rep$texto, .fpct(pos_des$prov)),

    frase_contiguidad(prov, d, "Cobertura neta", 3, FALSE),

    if (any(v > 1, na.rm = TRUE)) sprintf(paste(
      "**Advertencia sobre el dato.** En %d de los %d municipios la cobertura",
      "neta supera el 100 %%. El valor viene así de la fuente: una cobertura",
      "*neta* no puede exceder el 100 %% por definición, de modo que o la serie",
      "corresponde a cobertura bruta, o la matrícula y la proyección de",
      "población no son consistentes. Se publica sin corregir —corregirla sería",
      "inventar— y debe declararse al citarla."),
      sum(v > 1, na.rm = TRUE), ctx$n) else "",

    verificar(
      "la distribución de sedes educativas rurales y la oferta de media ",
      "técnica en la Provincia. La cobertura dice cuántos están matriculados; ",
      "no dice a qué distancia queda la sede ni qué se enseña en ella.")
  )
  out
}

# =============================================================================
# 09 Salud
# =============================================================================

seccion_salud <- function(prov, ctx) {
  out <- character(0)
  ase <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "aseguramiento_sgsss")
  mi <- ultimo_anio(hoja_publicada(prov, "09_Salud", "salud.xlsx",
                                   "mortalidad_infantil"))
  bp <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "bajo_peso_2024")
  ev <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "enfermedades_tropicales")
  su <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "suicidios")

  if (!is.null(ase)) {
    sub_pct <- valor_agregado(ase, "% afiliados régimen subsidiado", "provincia")
    con_pct <- valor_agregado(ase, "% afiliados régimen contributivo", "provincia")
    if (!is.na(sub_pct)) {
      out <- .p(out, sprintf(paste(
        "El aseguramiento en salud de la Provincia se apoya mayoritariamente en",
        "el régimen subsidiado, que concentra el %s de los afiliados frente al",
        "%s del contributivo. Esa composición no es un dato del sector salud",
        "sino un reflejo directo de la estructura del empleo descrita en la",
        "sección de economía: donde la informalidad es alta, el aseguramiento",
        "es subsidiado, y el sistema de salud local depende de transferencias",
        "antes que de cotizaciones. Corte: diciembre de 2025."),
        .fpct(sub_pct), .fpct(con_pct)))
    }
  }

  if (!is.null(mi) && nrow(mi)) {
    anio <- suppressWarnings(max(.num(mi[["Año"]]), na.rm = TRUE))
    col <- "Tasa de mortalidad infantil (x 1.000 nacidos vivos)"
    alto <- extremos(mi, col, 2, TRUE, .f2)
    pos_mi <- posicion(mi, col)
    out <- .p(out, sprintf(paste(
      "En %d, la mortalidad infantil registra sus valores más altos en %s, con",
      "una tasa provincial de %s por cada mil nacidos vivos, %s. Conviene leer",
      "esta cifra con cuidado: en municipios con pocos nacimientos la tasa se",
      "mueve mucho con un solo caso, de modo que un valor alto en un año no",
      "constituye una tendencia."),
      as.integer(anio), alto$texto, .f2(pos_mi$prov),
      frase_brecha(pos_mi, "dep", "mortalidad infantil", .f2)))
  }

  if (!is.null(bp)) {
    alto <- extremos(bp, "Nacidos con bajo peso al nacer, 2024 (%)", 2, TRUE, .fpct)
    pos_bp <- posicion(bp, "Nacidos con bajo peso al nacer, 2024 (%)", en_puntos = TRUE)
    out <- .p(out, sprintf(paste(
      "El bajo peso al nacer, que anticipa buena parte de la trayectoria de",
      "salud posterior, afecta al %s de los nacimientos de la Provincia y",
      "alcanza sus valores más altos en %s. Es un indicador de nutrición y de",
      "control prenatal, de modo que conecta la salud con las condiciones",
      "materiales descritas en la sección de economía."),
      .fpct(pos_bp$prov), alto$texto))
  }

  if (!is.null(ev)) {
    # Dengue y malaria se miden sobre población total; la leishmaniasis, sobre
    # población RURAL. Ordenarlas juntas para decir cuál «incide más» compararía
    # tasas con denominadores distintos, que es una forma silenciosa de mentir.
    # Cada una se reporta con su denominador y no se rankean entre sí.
    c_den <- "Tasa de dengue por 100 mil hab."
    c_mal <- "Tasa de malaria por 100 mil hab."
    c_lei <- "Tasa de leishmaniasis por 100 mil hab. rurales"
    partes <- character(0)

    if (c_den %in% names(ev)) {
      v <- valor_agregado(ev, c_den, "provincia")
      if (!is.na(v)) partes <- c(partes, sprintf(
        "el dengue registra una tasa provincial de %s por cada cien mil habitantes, con sus valores más altos en %s",
        .f2(v), extremos(ev, c_den, 2, TRUE, .f2)$texto))
    }
    if (c_mal %in% names(ev)) {
      v <- valor_agregado(ev, c_mal, "provincia")
      if (!is.na(v)) partes <- c(partes, sprintf(
        "la malaria, de %s sobre la misma base, encabezada por %s",
        .f2(v), extremos(ev, c_mal, 2, TRUE, .f2)$texto))
    }
    if (length(partes)) {
      out <- .p(out, sprintf(paste(
        "Entre las enfermedades transmitidas por vectores, %s. Son sensibles al",
        "clima y a las condiciones de la vivienda y el saneamiento, lo que las",
        "convierte en un indicador cruzado entre la sección ambiental y la de",
        "ordenamiento."),
        y_lista(partes)))
    }
    if (c_lei %in% names(ev)) {
      v <- valor_agregado(ev, c_lei, "provincia")
      if (!is.na(v)) out <- .p(out, sprintf(paste(
        "La leishmaniasis se mide sobre población **rural** y no sobre la",
        "total, de modo que su tasa no es comparable con las dos anteriores. En",
        "la Provincia alcanza %s por cada cien mil habitantes rurales, con los",
        "valores más altos en %s."),
        .f2(v), extremos(ev, c_lei, 2, TRUE, .f2)$texto))
    }
  }

  if (!is.null(su)) {
    col <- "Tasa de intento de suicidio por 100 mil hab."
    if (col %in% names(su)) {
      pos_su <- posicion(su, col)
      alto <- extremos(su, col, 2, TRUE, .f2)
      out <- .p(out, sprintf(paste(
        "En salud mental, la tasa de intento de suicidio de la Provincia es de",
        "%s por cada cien mil habitantes, con los valores más altos en %s. Es",
        "el indicador con mayor subregistro de esta sección y conviene",
        "presentarlo como una cota inferior."),
        .f2(pos_su$prov), alto$texto))
    }
  }

  .p(out, verificar(
    "la red de prestación de servicios disponible en la Provincia —nivel de ",
    "complejidad de las IPS, tiempos de traslado al hospital de referencia— ",
    "y el estado financiero de las ESE municipales. Los indicadores de ",
    "resultado no dicen con qué capacidad instalada se obtuvieron."))
}

# =============================================================================
# 10 Seguridad, Paz y Derechos Humanos
# =============================================================================

seccion_seguridad <- function(prov, ctx) {
  list(
    intro = .p(sprintf(paste(
      "Esta sección reúne tres registros que en la Provincia %s se solapan: la",
      "seguridad y convivencia del presente, la huella del conflicto armado y",
      "la situación de derechos humanos. Se presentan por separado porque",
      "responden a políticas distintas, pero se leen mejor juntos."),
      prov$etiqueta)),

    convivencia = {
      p <- character(0)
      d <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "delitos")
      irv <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "irv")
      if (!is.null(d)) {
        hom <- extremos(d, "Homicidios por 100.000 hab.", 2, TRUE, .f1)
        pos_hom <- posicion(d, "Homicidios por 100.000 hab.")
        hur <- extremos(d, "Hurtos por 100.000 hab.", 2, TRUE, .f1)
        vif <- extremos(d, "Violencia intrafamiliar por 100.000 hab.", 2, TRUE, .f1)
        p <- .p(p, sprintf(paste(
          "Las tasas de homicidio más altas de la Provincia corresponden a %s,",
          "con una tasa provincial de %s por cada cien mil habitantes, %s. %s"),
          hom$texto, .f1(pos_hom$prov),
          frase_brecha(pos_hom, "dep", "homicidios", .f1),
          frase_contiguidad(prov, d, "Homicidios por 100.000 hab.", 3, TRUE)),

          sprintf(paste(
            "Los delitos contra el patrimonio y la violencia intrafamiliar",
            "dibujan un mapa distinto: el hurto se concentra en %s y la",
            "violencia intrafamiliar en %s. Que no coincidan con la geografía",
            "del homicidio es esperable —responden a dinámicas diferentes— y es",
            "una razón para no reducir la política de seguridad a un solo",
            "indicador."),
            hur$texto, vif$texto))
      }
      if (!is.null(irv)) {
        m <- solo_municipios(irv)
        cat_riesgo <- table(as.character(m[["Categoría de riesgo"]]))
        cat_riesgo <- sort(cat_riesgo[!is.na(names(cat_riesgo))], decreasing = TRUE)
        alto <- extremos(irv, "Índice de Riesgo de Victimización", 2, TRUE,
                         function(x) num_co(x, 4))
        if (length(cat_riesgo)) {
          p <- .p(p, sprintf(paste(
            "El Índice de Riesgo de Victimización clasifica a los municipios",
            "según su exposición prospectiva. En la Provincia, la categoría más",
            "frecuente es «%s», con %d municipios, y los valores más altos",
            "corresponden a %s. A diferencia de las tasas de delito, que",
            "describen lo ocurrido, el IRV anticipa: es la medida más útil para",
            "priorizar prevención."),
            names(cat_riesgo)[1], as.integer(cat_riesgo[1]), alto$texto))
        }
      }
      .p(p, verificar(
        "qué actores y economías ilegales operan en la Provincia y cómo se ",
        "relacionan con los corredores de movilidad. Las tasas describen el ",
        "resultado; la explicación exige información de contexto que no está ",
        "en estas fuentes."))
    },

    paz = {
      p <- character(0)
      v <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "total_victimas")
      ph <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx",
                           "proporcion_hechos")
      s <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "tasas")
      coca <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "coca")
      if (!is.null(v)) {
        conc <- perfil_concentracion(v, "Víctimas por ocurrencia")
        total <- valor_agregado(v, "Víctimas por ocurrencia", "provincia")
        p <- .p(p, sprintf(paste(
          "La Provincia registra %s victimizaciones por ocurrencia del",
          "conflicto armado, %s: %s reúnen el %s del total. Son",
          "victimizaciones y no personas —una misma persona puede aparecer en",
          "más de un hecho—, de modo que la cifra mide la intensidad del daño y",
          "no el número de víctimas."),
          .f0(total), conc$clase, conc$nombres_dos,
          pct_co(conc$pct_dos * 100, dec = 0)))
      }
      if (!is.null(ph) && nrow(ph)) {
        h <- ph[ph[["Hecho victimizante"]] != "" &
                  !grepl("^TOTAL", ph[["Hecho victimizante"]]), , drop = FALSE]
        if (nrow(h)) {
          p <- .p(p, sprintf(paste(
            "Por tipo de hecho, %s concentra el %s de las victimizaciones de la",
            "Provincia. La composición del daño importa para la reparación: no",
            "se repara igual un desplazamiento que una desaparición o un",
            "despojo."),
            tolower(h[["Hecho victimizante"]][1]),
            .fpct(.num(h[["Proporción sobre el total (%)"]])[1])))
        }
      }
      if (!is.null(s)) {
        alto <- extremos(s, "Tasa de solicitudes (por 1.000 hab.)", 2, TRUE, .f2)
        p <- .p(p, sprintf(paste(
          "Las solicitudes de restitución de tierras por cada mil habitantes",
          "son más altas en %s. La restitución es el indicador que enlaza el",
          "conflicto con el ordenamiento: donde hubo despojo, la formalización",
          "de la propiedad rural sigue pendiente."),
          alto$texto))
      }
      if (!is.null(coca)) {
        m <- solo_municipios(coca)
        ha <- sum(.num(m[["Hectáreas de coca (2023)"]]), na.rm = TRUE)
        if (nrow(m) == 0 || ha == 0) {
          p <- .p(p, paste(
            "La Provincia no registra hectáreas de cultivos de coca en la",
            "fuente disponible."))
        } else {
          alto <- extremos(coca, "Hectáreas de coca (2023)", 2, TRUE, .f2)
          p <- .p(p, sprintf(paste(
            "En economías ilegales, la Provincia registra %s hectáreas de coca,",
            "concentradas en %s. Solo aparecen los municipios donde la fuente",
            "detectó cultivo: la ausencia de un municipio significa cero, no",
            "falta de dato."),
            .f2(ha), alto$texto))
        }
      }
      evoa <- ultimo_anio(hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx",
                                         "evoa"))
      if (!is.null(evoa) && nrow(evoa)) {
        anio <- suppressWarnings(max(.num(evoa[["Año"]]), na.rm = TRUE))
        tot <- valor_agregado(evoa, "Total EVOA (ha)", "provincia")
        ili <- valor_agregado(evoa, "Hectáreas ilícita", "provincia")
        if (!is.na(tot) && tot > 0) {
          p <- .p(p, sprintf(paste(
            "La explotación de oro de aluvión ocupaba en %d unas %s hectáreas",
            "en la Provincia%s. A diferencia de la coca, esta actividad deja una",
            "huella física duradera sobre el cauce y el suelo, de modo que su",
            "efecto sobrevive al fin de la explotación."),
            as.integer(anio), .f2(tot),
            if (!is.na(ili) && tot > 0) sprintf(
              ", de las cuales el %s corresponde a explotación sin título",
              pct_co(ili / tot * 100, dec = 1)) else ""))
        }
      }
      rc <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "reparacion_colectiva")
      if (!is.null(rc)) {
        total_suj <- valor_agregado(rc, "Sujetos de reparación colectiva reconocidos", "provincia")
        if (!is.na(total_suj) && total_suj > 0) {
          # perfil_concentracion() exige al menos 2 municipios con valor
          # positivo y devuelve NULL si no los hay; con conteos tan chicos
          # como estos (Área Metropolitana: los 3 sujetos, todos en Medellín)
          # es un caso real, no la excepción, así que hace falta un texto de
          # respaldo para un solo municipio en vez de asumir que siempre hay
          # al menos dos.
          conc_rc <- perfil_concentracion(rc, "Sujetos de reparación colectiva reconocidos")
          concentracion_txt <- if (!is.null(conc_rc)) {
            sprintf("%s: %s reúnen el %s del total", conc_rc$clase,
                    conc_rc$nombres_dos, pct_co(conc_rc$pct_dos * 100, dec = 0))
          } else {
            m_rc <- solo_municipios(rc)
            v_rc <- .num(m_rc[["Sujetos de reparación colectiva reconocidos"]])
            sprintf("%s por completo en %s",
                    if (total_suj == 1) "concentrado" else "concentrados",
                    m_rc[["Municipio"]][which.max(v_rc)])
          }
          total_impl <- valor_agregado(
            rc, "Sujetos con Plan Integral de Reparación Colectiva implementado", "provincia")
          p <- .p(p, sprintf(paste(
            "La UARIV reconoce %s %s de reparación colectiva en la Provincia,",
            "%s. De ellos, %s %s la",
            "implementación de su Plan Integral de Reparación Colectiva (PIRC); el",
            "resto sigue en alguna de las fases previas —identificación,",
            "caracterización del daño, diagnóstico, diseño y formulación o",
            "alistamiento—, que es justamente el estado de avance que pedía",
            "verificar la revisión de este documento."),
            .f0(total_suj), if (total_suj == 1) "sujeto" else "sujetos",
            concentracion_txt, .f0(total_impl),
            if (total_impl == 1) "ya completó" else "ya completaron"))
        } else {
          p <- .p(p, paste(
            "La UARIV no reconoce sujetos de reparación colectiva en ningún",
            "municipio de la Provincia."))
        }
      }
      # Zona PDET: subproducto del mismo insumo de reparación colectiva (cada
      # sujeto trae la zona PDET de su municipio). Cubre solo los municipios
      # que tienen algún sujeto reconocido —40 de los 90 con provincia en
      # Antioquia—, así que "sin PDET reconocido" NO equivale a "confirmado
      # que no es zona PDET" para el resto: se nombra a los que sí se sabe
      # que lo son y no se afirma nada de los demás.
      rs <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx",
                           "reparacion_colectiva_sujetos")
      if (!is.null(rs) && "Zona PDET" %in% names(rs)) {
        pdet_mpios <- unique(rs[["Municipio"]][rs[["Zona PDET"]] != "No PDET" &
                                                 !is.na(rs[["Zona PDET"]])])
        pdet_zonas <- unique(rs[["Zona PDET"]][rs[["Zona PDET"]] != "No PDET" &
                                                 !is.na(rs[["Zona PDET"]])])
        if (length(pdet_mpios)) {
          p <- .p(p, sprintf(paste(
            "Al menos %s %s territorio PDET (%s), según la zona que trae",
            "la misma fuente de reparación colectiva; esto solo cubre los",
            "municipios con algún sujeto reconocido, así que no descarta que",
            "otros municipios de la Provincia también lo sean."),
            y_lista(pdet_mpios), if (length(pdet_mpios) == 1) "es" else "son",
            y_lista(pdet_zonas)))
        }
      }
      .p(p, verificar(
        "el estado de implementación de PNIS en la Provincia, y la cobertura ",
        "PDET completa de todos sus municipios —lo que hay hoy sobre PDET es ",
        "un subproducto del insumo de reparación colectiva y solo cubre los ",
        "municipios con algún sujeto reconocido."))
    },

    ddhh = {
      p <- character(0)
      d <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "desaparecidos")
      if (!is.null(d)) {
        conc <- perfil_concentracion(d, "Personas dadas por desaparecidas")
        total <- valor_agregado(d, "Personas dadas por desaparecidas", "provincia")
        p <- .p(p, sprintf(paste(
          "La Unidad de Búsqueda de Personas dadas por Desaparecidas registra",
          "%s casos en la Provincia, %s: %s reúnen el %s del total. La",
          "desaparición forzada es el hecho victimizante con mayor subregistro",
          "histórico, de modo que la cifra debe leerse como una cota inferior."),
          .f0(total), conc$clase, conc$nombres_dos,
          pct_co(conc$pct_dos * 100, dec = 0)))
      }
      p <- .p(p, paste(
        "La encuesta de percepción de seguridad complementa este panorama con",
        "la mirada de la ciudadanía. Sus resultados son representativos a nivel",
        "de **subregión**, no de provincia ni de municipio, y así se rotulan en",
        "las tablas y figuras de esta sección: presentarlos como cifras",
        "provinciales atribuiría a este territorio una medición que no lo",
        "representa."))
      .p(p, verificar(
        "qué organizaciones sociales y de víctimas operan en la Provincia y ",
        "qué mecanismos de protección existen para líderes sociales, que es ",
        "información de campo y no estadística."))
    }
  )
}
