# =============================================================================
# resumenes.R — Resumen-viñeta al inicio de cada una de las 10 dimensiones
#
# Pedido de Laura (21/08/2026): un cuadro corto de 2-3 viñetas al principio
# de cada dimensión del informe, a modo de resumen ejecutivo — lo que en la
# conversación se llamó "resumen-viñeta-popup". Pandoc/Word no tiene un
# "popup" de verdad; lo más parecido que da esta cadena (markdown -> pandoc
# -> .docx) sin inventar un estilo de Word nuevo es una tabla de una columna:
# a diferencia de una cita (>), que ya usa verificar() para otra cosa, una
# tabla sale con borde en Word y se distingue a simple vista del resto del
# texto. Si el formato no es el que Laura tenía en mente, es el único punto
# de este archivo que habría que cambiar (.resumen_box()); el resto no.
#
# DELIBERADAMENTE es independiente de seccion_*() (secciones.R): vuelve a
# leer las mismas hojas publicadas en vez de que cada seccion_*() devuelva
# también un resumen. Es un poco de lectura repetida (hojas locales, no red:
# barata), pero mantiene el riesgo contenido a un archivo nuevo en vez de
# tocar la generación de prosa de las 10 secciones que ya funciona.
#
# Cada bloque de bullets usa SOLO columnas que ya se leen en otra parte de
# secciones.R (mismo nombre exacto), para no adivinar encabezados nuevos.
#
# ETAPA DEL PIPELINE: documentación
# =============================================================================

#' Una tabla de una columna: pandoc la vuelve un cuadro con borde en Word.
.resumen_box <- function(titulo, bullets) {
  bullets <- bullets[!is.na(bullets) & nzchar(bullets)]
  if (!length(bullets)) return(character(0))
  c(
    paste0("| **En resumen — ", titulo, "** |"),
    "|:---|",
    paste0("| ", bullets, " |"),
    ""
  )
}

#' Bullets de las 10 dimensiones. Devuelve una lista nombrada; cualquier
#' elemento puede quedar en character(0) si a la provincia le falta esa
#' hoja (mismo criterio que el resto del documento: se calla, no se rompe).
resumen_dimensiones <- function(prov, ctx) {
  b <- list()

  # --- 1. Generalidades (no necesita hoja: ya está en ctx) -------------------
  b$generalidades <- c(
    sprintf("%d municipios · %s", ctx$n, .fkm2(ctx$area_km2)),
    sprintf("Población 2025: %s (%s rural)", .fhab(ctx$poblacion),
            .fpct(ctx$rural / ctx$poblacion))
  )

  # --- 2. Demografía ----------------------------------------------------------
  pob <- hoja_publicada(prov, "02_Demografia", "demografia.xlsx", "poblacion")
  if (!is.null(pob)) {
    tot <- valor_agregado(pob, "Población total", "provincia")
    dens_alto <- extremos(pob, "Densidad poblacional (hab/km²)", 1, TRUE, .f1)
    b$demografia <- c(
      if (!is.na(tot)) sprintf("Población total de la provincia: %s", .fhab(tot)),
      if (!is.null(dens_alto)) sprintf("Mayor densidad poblacional: %s", dens_alto$texto)
    )
  }

  # --- 3. Ordenamiento del Territorio -----------------------------------------
  viv <- hoja_publicada(prov, "03_Ordenamiento", "ordenamiento.xlsx", "deficit_vivienda")
  if (!is.null(viv)) {
    cuanti <- extremos(viv, "Déficit cuantitativo de vivienda", 1, TRUE, .fpct)
    cuali <- extremos(viv, "Déficit cualitativo de vivienda", 1, TRUE, .fpct)
    b$ordenamiento <- c(
      if (!is.null(cuanti)) sprintf("Mayor déficit cuantitativo de vivienda: %s", cuanti$texto),
      if (!is.null(cuali)) sprintf("Mayor déficit cualitativo de vivienda: %s", cuali$texto)
    )
  }

  # --- 4. Gobernabilidad y capacidades territoriales --------------------------
  icm <- ultimo_anio(hoja_publicada(prov, "04_Gobernabilidad", "gobernabilidad.xlsx", "icm"))
  ing <- hoja_publicada(prov, "04_Gobernabilidad", "gobernabilidad.xlsx", "ingresos_inversion")
  b$gobernabilidad <- c(
    { alto_icm <- extremos(icm, "ICM", 1, TRUE, .f1)
      if (!is.null(alto_icm)) sprintf("Mayor ICM: %s", alto_icm$texto) },
    { tot_ing <- valor_agregado(ing, "Total ingresos de inversión", "provincia")
      if (!is.na(tot_ing)) sprintf("Ingresos de inversión 2026 (PGN+SGP+SGR+propios+otros): %s",
                                   .f0(tot_ing)) }
  )

  # --- 5. Economía y desarrollo ------------------------------------------------
  va <- ultimo_anio(hoja_publicada(prov, "05_Economia", "economia.xlsx", "valor_agregado"))
  if (!is.null(va)) {
    pc_alto <- extremos(va, "Valor agregado per cápita (pesos constantes de 2015)", 1, TRUE, .f0)
    pc_prov <- valor_agregado(va, "Valor agregado per cápita (pesos constantes de 2015)", "provincia")
    b$economia <- c(
      if (!is.null(pc_alto)) sprintf("Mayor valor agregado per cápita: %s", pc_alto$texto),
      if (!is.na(pc_prov)) sprintf("Valor agregado per cápita provincial: %s", .f0(pc_prov))
    )
  }

  # --- 6. Desarrollo Rural ------------------------------------------------------
  inv <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural", "desarrollo_rural.xlsx",
                                    "inventario_pecuario"))
  com <- ultimo_anio(hoja_publicada(prov, "06_Desarrollo_Rural", "desarrollo_rural.xlsx",
                                    "composicion_agricola"))
  b$desarrollo_rural <- c(
    { tot_pec <- valor_agregado(inv, "Total especies pecuarias", "provincia")
      if (!is.na(tot_pec)) sprintf("Total especies pecuarias: %s", .f0(tot_pec)) },
    { perm <- valor_agregado(com, "Proporción de cultivos permanentes", "provincia")
      if (!is.na(perm)) sprintf("Cultivos permanentes: %s del área agrícola", .fpct(perm)) }
  )

  # --- 7. Ambiental --------------------------------------------------------------
  irca <- ultimo_anio(hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx", "irca"))
  imrc <- hoja_publicada(prov, "07_Ambiental", "ambiental.xlsx", "imrc")
  b$ambiental <- c(
    { peor_irca <- extremos(irca, "IRCA", 1, TRUE, .f2)
      if (!is.null(peor_irca)) sprintf("Peor calidad de agua (IRCA más alto): %s", peor_irca$texto) },
    { alto_lluv <- extremos(imrc, "IMRC Exceso de lluvias", 1, TRUE, .f2)
      if (!is.null(alto_lluv)) sprintf("Mayor riesgo por exceso de lluvias: %s", alto_lluv$texto) }
  )

  # --- 8. Educación ----------------------------------------------------------------
  edu <- ultimo_anio(hoja_publicada(prov, "08_Educacion", "educacion.xlsx", "educacion"))
  if (!is.null(edu)) {
    cob_alto <- extremos(edu, "Cobertura neta", 1, TRUE, .fpct)
    des_alto <- extremos(edu, "Tasa de deserción", 1, TRUE, .fpct)
    b$educacion <- c(
      if (!is.null(cob_alto)) sprintf("Mayor cobertura neta: %s", cob_alto$texto),
      if (!is.null(des_alto)) sprintf("Mayor tasa de deserción: %s", des_alto$texto)
    )
  }

  # --- 9. Salud ---------------------------------------------------------------------
  bp <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "bajo_peso_2024")
  ase <- hoja_publicada(prov, "09_Salud", "salud.xlsx", "aseguramiento_sgsss")
  b$salud <- c(
    { alto_bp <- extremos(bp, "Nacidos con bajo peso al nacer, 2024 (%)", 1, TRUE, .fpct)
      if (!is.null(alto_bp)) sprintf("Mayor proporción de bajo peso al nacer: %s", alto_bp$texto) },
    { sub_pct <- valor_agregado(ase, "% afiliados régimen subsidiado", "provincia")
      if (!is.na(sub_pct)) sprintf("Afiliados al régimen subsidiado (provincial): %s",
                                   .fpct(sub_pct)) }
  )

  # --- 10. Seguridad, Paz y Derechos Humanos -----------------------------------------
  del <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "delitos")
  vic <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "total_victimas")
  rc  <- hoja_publicada(prov, "10_Seguridad", "seguridad.xlsx", "reparacion_colectiva")
  b$seguridad <- c(
    { alto_hom <- extremos(del, "Homicidios por 100.000 hab.", 1, TRUE, .f1)
      if (!is.null(alto_hom)) sprintf("Mayor tasa de homicidios: %s", alto_hom$texto) },
    { tot_vic <- valor_agregado(vic, "Víctimas por ocurrencia", "provincia")
      if (!is.na(tot_vic)) sprintf("Victimizaciones del conflicto armado: %s", .f0(tot_vic)) },
    { tot_rc <- valor_agregado(rc, "Sujetos de reparación colectiva reconocidos", "provincia")
      if (!is.na(tot_rc) && tot_rc > 0) sprintf("Sujetos de reparación colectiva reconocidos: %s",
                                                .f0(tot_rc)) }
  )

  b
}
