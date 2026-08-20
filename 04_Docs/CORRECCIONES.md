# Registro de correcciones

**Punto de partida:** commit `a475acf`, rama `Nuevo-pipeline`
**Alcance de esta fase:** los 17 hallazgos que afectan a cifras o documentos ya
entregados. Los de gravedad media y baja quedan para otra fase.
**Para qué sirve este archivo:** que el autor original pueda revisar cada cambio
por separado —qué estaba mal, qué se tocó y dónde— aunque todos viajen en un
mismo commit.

**Regla de esta fase:** la corrección más simple posible y lo más ajustada al
código original. Nada de reescrituras ni de mejoras que nadie pidió.

---

## Índice

| # | Id | Qué corrige | Archivos tocados | Estado |
|---|---|---|---|---|
| 1 | `F-4-004` | Faltan dos municipios en el listado de entrada | `crosswalk_territorial.R` | **aplicado** *(rehecha)* |
| 2 | `F-4-003` | El número de municipios está escrito a mano | `crosswalk_territorial.R` | **aplicado** |
| 3 | `F-1-027` | Internet fijo: la fila provincial promedia en vez de sumar | `03_ordenamiento.R` | **aplicado** |
| 4 | `F-2-027` | Leishmaniasis: ponderador que no es su denominador | `09_salud.R`, `R/01_utils.R` | **aplicado** |
| 5 | `F-2-049` | La prosa promedia en vez de leer el total publicado | `secciones.R`, `panel_provincial.R`, `03_ordenamiento.R` (tablas y figuras) | **aplicado** |
| 6 | `F-2-028` | «Sin registro» se convierte en «cero» | `06_desarrollo_rural.R` | **aplicado** |
| 7 | `F-2-018` | Dos series de población en el mismo libro | `poblacion_municipal.R`, `02_demografia.R` | **aplicado** *(ver 7b)* |
| 8 | `F-2-036` | El titular suma tres tasas no comparables | `04_figuras/09_salud.R` | **aplicado** |
| 9 | `F-3-005` | No se puede leer el archivo del MinTIC | `infraestructura_internet.R`, `00_Inputs/README.md` | **aplicado** |
| 10 | `F-2-035` | El mapa departamental sale incompleto | `00_mapas.R`, `03_tablas/10_seguridad.R`, `run_provincia.R` | **aplicado** |
| 11 | `F-1-006` | ~825 rutas absolutas de otra máquina | `generar_borrador.R` | **aplicado** |
| 12 | `F-2-050` | Informa éxito sin producir el documento | `generar_borrador.R`, `generar_comparativo.R` | **aplicado** |
| 13 | `F-1-010` | Los mapas se degradan sin avisar | `R/03_mapas.R`, `run_provincia.R`, `figuras_comparativas.R` | **aplicado** |
| 14 | `F-2-064` | El anexo se rellena con una corrida parcial | `generar_tablas_anexo.R`, `anexo_metodologico.tex` | **aplicado** |
| 15 | `F-2-054` | El comparativo dice «las once» sin comprobarlo | `panel_provincial.R` | **aplicado** |
| 16 | `F-2-015` | El índice de envejecimiento no tiene fórmula comprobable | `poblacion_municipal.R`, `02_demografia.R` (tablas y figuras) | **aplicado** |
| 17 | `F-4-002` | El rótulo del mapa afirma algo que el dato no dice | `00_mapas.R`, `04_figuras/07_ambiental.R`, `03_tablas/07_ambiental.R` | **aplicado** |
| 7b | `F-2-018` | Los ponderadores salían de la serie descartada | `poblacion_municipal.R`, `03_ordenamiento.R`, `09_salud.R` | **aplicado en parte** |
| 18 | `F-5-001` `F-5-002` | Internet fijo: se suman los cuatro trimestres y se descartan los paquetes | `03_ordenamiento.R` | **aplicado** |
| 19 | `F-5-003` | La revisión estática aborta si git no está en el PATH | `check_pipeline.R` | **aplicado** |
| 20 | `F-5-004` | No se encuentra el pandoc que trae RStudio, y no sale ningún .docx | `generar_borrador.R`, `generar_comparativo.R` | **aplicado** |

`F-5-001` y `F-5-002` no estaban en la lista de 17: aparecieron al preparar el
hallazgo 9 y se corrigieron con él por decisión de Pablo, porque viven en la
misma función que la corrección 3.

---

## Avisos abiertos mientras dure esta fase

**Ninguno.** La inconsistencia que estuvo abierta desde la corrección 3 —la
figura de fibra diciendo una cifra y el párrafo de al lado otra— **quedó cerrada
con la corrección 5 el 20 de agosto**. Las dos dicen ahora 75,8 % en Del Río
Grande.

Quedan dos cosas fuera de nuestro alcance, ninguna bloqueante:

- **Corrección 16 (`F-2-015`)**, esperando al equipo del tablero, que tiene tres
  preguntas: la fórmula del índice de envejecimiento, el umbral de dosel de la
  cobertura arbórea y los cinco municipios cuyo denominador no cierra.
- **La etiqueta de la columna de cobertura arbórea**, que conviene precisar pero
  arrastra a `comparar_referencia.R` —la línea base contra la que comparamos las
  corridas— y por eso no viaja en este commit (ver corrección 17).

---

## Referencia de la corrida previa

Antes de tocar nada se corrió el pipeline sin modificar y se guardó copia de las
salidas de las dos provincias de la muestra en
`tests/referencia/pre_correcciones/` (carpeta ignorada por git). Todo cambio en
las cifras se comprueba contra esa copia.

Provincias de la muestra: **3 · Del Río Grande** (control, no debe cambiar) y
**4 · Turística y Agroecológica** (la afectada por el hallazgo 1).

### Corrida de comprobación · 20-ago-2026

Se corrió `Rscript 02_Code/run_all.R 3 4` con las correcciones 1, 2, 3, 4, 6 y 7
aplicadas. **22 secciones OK en 6,8 minutos.** Resultados clave:

| Comprobación | Resultado |
|---|---|
| Crosswalk territorial | **90 × 6** (era 88) |
| Derivado nuevo `poblacion_edad_2025` | **125 × 31** |
| Turística y Agroecológica | **8 municipios**, 95.213 habitantes |
| Del Río Grande (control) | **5 municipios**, 101.228 habitantes — sin cambio |
| Internet, Río Grande | 68.199 líneas · 40.822 fibra · 59,9 % · 673,7 por mil ⚠️ |
| Internet, Turística | 41.205 líneas · 17.375 fibra · 42,2 % · 432,8 por mil ⚠️ |
| Leishmaniasis provincial | 1,586 y 93,993, rotulada «rurales» |
| Aviso pecuario en el log | *«porcinos: cobertura insuficiente en 2019 (24 de 125 municipios)»* |
| `infraestructura_internet.R` | **FALLO** — es el hallazgo 9, aún sin corregir |

La verificación automática dio **30 de 32 en OK**. Las dos `FALLA` restantes eran
un defecto de la propia prueba, no del pipeline (ver corrección 6).

⚠️ **Las dos filas de internet quedaron obsoletas ese mismo día.** Son correctas
para la corrección 3 sola, pero la corrección 18 volvió a moverlas: los valores
que hay que esperar en la próxima corrida están en la corrección 18.

### Segunda corrida de comprobación · 20-ago-2026, 14:20

`Rscript 02_Code/run_all.R 3 4` con las once correcciones aplicadas.
**22 secciones OK en 9,9 minutos.** Es la primera corrida de toda la revisión en
que las **once** etapas de homogeneización terminan en OK, porque
`infraestructura_internet.R` ya lee la fuente.

Lo que esta corrida verificaba, que era lo nunca ejecutado:

| Corrección | Señal en el log | Resultado |
|---|---|---|
| 9 · lectura del MinTIC | `infraestructura_internet_2025.parquet (124190 x 22)` · `separador «;»` | **OK** |
| 18 · trimestre y paquetes | `[internet] 2025 T4, 4 paquetes con internet fijo` en las dos | **OK** |
| 10 · mapa departamental | `_mapa10_homicidios_dpto (90 filas)` en las dos | **OK** |
| 8 · titular de vectores | `_fig_03` con la posición promedio publicada | **OK** |

La verificación automática dio **46 de 47 en OK**. Lo nuevo:

- **Corrección 9.** El derivado trae 124.190 registros y 22 columnas, nombres en
  minúscula, `cantidad_lineas_accesos` numérica y los cuatro trimestres. Y
  **reproduce la suma de líneas del derivado versionado por el autor: 2.502.506**.
  Esa igualdad es la prueba de que el CSV descargado y la exportación original
  del MinTIC contienen los mismos datos, con otro separador y otra caja.
- **Corrección 18.** Río Grande pasa de 68.199 a **19.217** líneas y de 673,7 a
  **189,8** por 1.000 habitantes; Turística, de 41.205 a **12.165** y de 432,8 a
  **127,8**. Las ocho cifras coinciden con lo recalculado.
- **Corrección 10.** Las dos provincias corridas publican el mapa con **90
  municipios**, pese a haberse corrido solo dos. Antes daban 88 y 89.
- **Corrección 8.** Las posiciones promedio de `_fig_03` coinciden con las tres
  tasas de la propia hoja en las dos provincias.

**Un cambio de titular que produjo la corrección 1.** En Turística, el titular
pasó de lo previsto —«Olaya encabeza el dengue; San Jerónimo, la malaria;
Buriticá, la leishmaniasis»— a:

> «Olaya encabeza el dengue; **Santa Fe de Antioquia**, la malaria y la
> leishmaniasis»

Santa Fe de Antioquia, el municipio que faltaba en el listado de entrada,
encabeza **dos de las tres** enfermedades de su provincia. Es una consecuencia
directa del hallazgo bloqueante: mientras estuvo fuera, el informe de la
Turística atribuía a otros municipios un liderazgo que no era suyo.

**La única `FALLA` fue de la prueba, no del código.** La comprobación se llamaba
«las provincias corridas cubren el universo» pero leía las **once**, no las dos
de la muestra, así que las nueve no corridas la hacían fallar por conservar su
mapa viejo. Corregida en `15_verificar_correcciones.R`: ahora comprueba la
muestra y reporta el resto como información.

Es la **séptima vez en esta fase** que un `FALLA` resulta ser un defecto del
instrumento y no del sistema auditado.

---

## 1 · `F-4-004` — Faltan dos municipios en el listado de entrada

**Estado:** aplicado · 2026-08-18 · **rehecha el 2026-08-18** (ver «Por qué se rehízo»)

### El error

El pipeline decide qué municipios componen cada provincia a partir de la columna
«Esquema asociativo» de `MUNICIPIOS_SUBREG_PROV.xlsx`. Los municipios con esa
celda vacía quedan fuera del sistema provincial.

**Dos municipios estaban vacíos y no debían estarlo:**

- **Santa Fe de Antioquia** (05042) pertenece a la Provincia Turística y
  Agroecológica del Occidente — **Ordenanza 47 del 16 de diciembre de 2024**.
- **Amalfi** (05031) pertenece a la Provincia Minero Agroecológica — **Ordenanza
  7 del 21 de marzo de 2025**.

Un municipio ausente de ese listado no existe para ninguna pieza del sistema: ni
tablas, ni figuras, ni mapas, ni totales provinciales, ni la prosa. Y como todas
las piezas parten del mismo listado, el informe queda mal **de forma coherente
consigo mismo**, sin que ninguna comprobación pueda detectarlo.

### No es un defecto del código

El código hace lo correcto al descartar los municipios sin esquema:

```r
crosswalk <- mpios |>
  dplyr::rename(provincia = `Esquema asociativo`, subregion = `Subregión`) |>
  dplyr::filter(!is.na(provincia), stringr::str_squish(provincia) != "") |>
```

El problema estaba en el dato de entrada. Está comprobado además que el cruce no
pierde ningún municipio por su cuenta.

### Por qué se rehízo esta corrección

**La primera versión editaba dos celdas del Excel, y eso incumple una regla que el
propio proyecto declara dos veces.**

Anexo metodológico, **Regla 2 — «las fuentes no se tocan»**:

> Ningún archivo de `00_Inputs` se edita, se limpia ni se renombra a mano. Toda
> transformación ocurre en un script de `02_Code/01_homogeneizacion`, para que
> quede registrada, revisable y repetible. **Un archivo corregido a mano es una
> corrección que nadie puede auditar y que se pierde en la siguiente entrega de
> la fuente.**

`01_Data/00_Inputs/README.md` dice lo mismo con otras palabras.

El riesgo que la regla anticipa era exactamente el nuestro: **la próxima entrega
del listado habría borrado las dos celdas sin aviso**, y las dos provincias
habrían vuelto a perder sus municipios en silencio.

El Excel quedó **revertido a su estado original**
(MD5 `16f8484583deb535aee63bf252ede552`, 13.400 bytes) y la corrección se movió
al script de homogeneización.

### Qué se cambió y dónde

**Archivo:** `02_Code/01_homogeneizacion/crosswalk_territorial.R`, justo después
de leer el listado. **Entran 21 líneas; no se retira ninguna.**

```r
mpios <- leer_excel(entrada("MUNICIPIOS_SUBREG_PROV.xlsx"))

# Dos municipios que el listado deja sin esquema asociativo y que sí pertenecen
# a una provincia por ordenanza departamental. Se corrige aquí y no en el Excel
# porque la regla 2 del anexo prohíbe editar 00_Inputs a mano: una corrección
# hecha en el archivo se perdería sin aviso en la próxima entrega de la fuente.
# Solo rellena celdas VACÍAS, de modo que en cuanto el listado venga corregido
# de origen estas líneas dejan de tener efecto y se pueden retirar.
mpios <- mpios |>
  dplyr::mutate(
    sin_esquema = is.na(`Esquema asociativo`) |
      stringr::str_squish(`Esquema asociativo`) == "",
    # Santa Fe de Antioquia (05042) — Ordenanza 47 del 16 de diciembre de 2024
    `Esquema asociativo` = ifelse(
      sin_esquema & as.integer(DPMP) == 5042L,
      "PROVINCIA TURISTICA Y AGROECOLOGICA", `Esquema asociativo`),
    # Amalfi (05031) — Ordenanza 7 del 21 de marzo de 2025
    `Esquema asociativo` = ifelse(
      sin_esquema & as.integer(DPMP) == 5031L,
      "PROVINCIA MINERO AGROECOLOGICA", `Esquema asociativo`)
  ) |>
  dplyr::select(-"sin_esquema")
```

**Tres decisiones de diseño, y las tres importan:**

1. **Se cruza por código DANE (`DPMP`), no por nombre.** Es la clave estable, y
   evita el problema que el propio archivo ya sufre con las grafías.
2. **Solo rellena celdas vacías.** En cuanto el equipo corrija el listado de
   origen, estas líneas se vuelven inertes por sí solas. Un override que
   sobrescribiera siempre acabaría tapando la corrección buena.
3. **Se aplica sobre `mpios` nada más leerlo**, no dentro del `crosswalk`. Así
   lo ven por igual el cruce y la comprobación de la corrección 2, que cuenta los
   municipios con esquema sobre esa misma tabla.

Los dos textos de provincia son copia literal de los que ya usan los demás
municipios: el emparejamiento con el catálogo `PROVINCIAS` de `00_config.R` se
hace sobre ese texto.

### Cómo se comprobó antes de entregarlo

El bloque se ejecutó en R sobre el listado **original**, sin editar:

| Prueba | Resultado |
|---|---|
| Punto de partida | 88 municipios con esquema |
| Tras la corrección | **90** |
| Reparto | Turística y Agroecológica **8**, Minero Agroecológica **6**, las otras nueve sin cambios |
| Santa Fe de Antioquia | `PROVINCIA TURISTICA Y AGROECOLOGICA` |
| Amalfi | `PROVINCIA MINERO AGROECOLOGICA` |
| **Si el listado viniera ya corregido de origen** | **el override no cambia nada — no-op** |

Sintaxis validada con `parse()`; CRLF conservados.

### Lo que esto no sustituye

Esta corrección es un puente. **La solución de fondo sigue siendo que el equipo
corrija el listado de origen**, con el anexo de la ordenanza como respaldo. Cuando
eso ocurra, estas líneas se pueden retirar sin que nada cambie — y la prueba de
arriba lo demuestra.

### Efecto esperado en las salidas

Cambia todo lo de las dos provincias afectadas: población, área, cada cifra por
habitante, cada total provincial, los mapas, la prosa y su posición en el
documento comparativo. **Las otras nueve provincias no deben cambiar en nada.**

| Provincia | Municipios | Población total 2025 |
|---|---:|---:|
| Turística y Agroecológica | 8 | 95.213 |
| Minero Agroecológica | 6 | 146.335 |

---

## 2 · `F-4-003` — El número de municipios está escrito a mano

**Estado:** aplicado · 2026-08-18

### El error

Tras armar el crosswalk, el script comprobaba el resultado contra una constante:
`esperado <- 88L`. Eso tiene dos consecuencias.

**Bloquea la corrección 1:** cuántos municipios componen el sistema provincial es
un dato del territorio, no una propiedad del programa. Con el listado ya
corregido a 90, el pipeline se detenía.

**Y hacía inútil la comprobación:** si la fuente asignara 89 municipios y uno se
perdiera al cruzar con los códigos DANE, el resultado sería 88 —exactamente lo
que la comprobación esperaba— y **pasaría sin decir nada**. La comprobación
estaba construida de modo que una pérdida silenciosa parecía un acierto.

Había además un tercer defecto, en el mensaje de error: la lista de municipios
perdidos se calculaba **sin las dos correcciones de nombre** que el propio script
aplica al cruzar, y sin descartar los `NA`.

### La evidencia en el código

`02_Code/01_homogeneizacion/crosswalk_territorial.R`, líneas 107-116:

```r
# --- Verificaciones -----------------------------------------------------------
esperado <- 88L
if (nrow(crosswalk) != esperado) {
  perdidos <- setdiff(
    normalizar_municipio(mpios$MPIO[stringr::str_squish(mpios$`Esquema asociativo`) != ""]),
    crosswalk$nvl_label
  )
  stop(...)
}
```

Veinte líneas antes, el propio script ya contaba los municipios con esquema —es
el filtro con el que arma el crosswalk—, así que la información necesaria estaba
en el archivo y solo faltaba usarla:

```r
dplyr::filter(!is.na(provincia), stringr::str_squish(provincia) != "")
```

### Qué se cambió y dónde

**Archivo:** `02_Code/01_homogeneizacion/crosswalk_territorial.R`
**Líneas:** bloque «Verificaciones». Se retiran 6 líneas y entran 12.

> **Interacción con la corrección 1.** `esperado` se cuenta sobre `mpios`, que es
> la tabla ya corregida por ordenanza. Por eso las dos correcciones tienen que
> viajar juntas: con la 1 sin la 2 el pipeline se detiene, y con la 2 sin la 1 el
> esperado sería 88.

**Antes:**

```r
esperado <- 88L
if (nrow(crosswalk) != esperado) {
  perdidos <- setdiff(
    normalizar_municipio(mpios$MPIO[stringr::str_squish(mpios$`Esquema asociativo`) != ""]),
    crosswalk$nvl_label
  )
  stop("El crosswalk quedó con ", nrow(crosswalk), " municipios y se esperaban ", esperado, ".\n",
       "Municipios sin código DANE: ", paste(perdidos, collapse = ", "), call. = FALSE)
}
```

**Después:**

```r
# El universo lo define la fuente, no una constante escrita a mano: si el listado
# incorpora un municipio, el esperado cambia con él. Y así una pérdida en el cruce
# deja de ser invisible: el conteo de la fuente ya no coincide.
con_esquema <- !is.na(mpios$`Esquema asociativo`) &
  stringr::str_squish(mpios$`Esquema asociativo`) != ""
esperado <- sum(con_esquema)
if (nrow(crosswalk) != esperado) {
  # las mismas dos correcciones de nombre que se aplican arriba al cruzar
  claves <- normalizar_municipio(mpios$MPIO[con_esquema])
  claves <- ifelse(claves == "CAROLINA", "CAROLINA DEL PRINCIPE", claves)
  claves <- ifelse(claves == "SAN VICENTE", "SAN VICENTE FERRER", claves)
  perdidos <- setdiff(claves, crosswalk$nvl_label)
  stop("El crosswalk quedó con ", nrow(crosswalk), " municipios y la fuente asigna ", esperado, ".\n",
       "Municipios sin código DANE: ", paste(perdidos, collapse = ", "), call. = FALSE)
}
```

La condición `con_esquema` es la misma del filtro de la línea 67, calculada una
vez y reutilizada por las dos partes del bloque.

### Cómo se comprobó antes de entregarlo

El bloque nuevo se ejecutó en R contra el listado real ya corregido, en cuatro
escenarios:

| Prueba | Resultado |
|---|---|
| Crosswalk completo (90 municipios) | **Pasa.** `esperado = 90` |
| Se pierde «Santa Fe de Antioquia» en el cruce | **Aborta** y lo nombra: *«quedó con 89 y la fuente asigna 90. Municipios sin código DANE: SANTA FE DE ANTIOQUIA»* |
| Se pierde «Carolina del Príncipe» | **Aborta** y lo nombra correctamente, con su nombre completo |
| El mismo caso con el código anterior | Habría listado *«NA, CAROLINA, SAN VICENTE, SANTA FE DE ANTIOQUIA»*: **tres acusaciones falsas** además del municipio real |

La sintaxis del archivo completo se validó con `parse()`. El archivo conserva sus
finales de línea originales (CRLF), de modo que el `git diff` muestra solo este
bloque y no el archivo entero.

### Efecto esperado en las salidas

**Ninguno por sí solo.** Este cambio no calcula nada: solo permite que el
pipeline arranque con el listado corregido. Lo que mueve cifras es la corrección 1.

### Cómo comprobar que quedó bien

Al correr, `crosswalk_territorial.R` debe escribir:

```
[derivado] codigos_provincias.parquet  (90 x 6, ...)
codigos_provincias.dta: 90 municipios en 11 provincias
```

Si dice 88, el archivo de entrada corregido no se guardó. Si se detiene, el
mensaje dirá qué municipio no encuentra su código DANE.

---

## 3 · `F-1-027` — Internet fijo: la fila provincial promedia en vez de sumar

**Estado:** aplicado · 2026-08-18

### El error

La hoja `internet_2025` publica cuatro columnas por municipio y una fila de total
provincial. Esa fila se calculaba haciendo el **promedio simple** de las cuatro
columnas sobre los municipios, incluidas las dos que son **conteos**.

El resultado es que la provincia declaraba la suma de sus líneas **dividida entre
el número de municipios**. Comprobado en las once: la razón entre lo publicado y
la suma real es exactamente 1/n. La única señal de que algo iba mal era el
decimal —«13.639,8 líneas»—, que desaparece al redondear.

Incumple la regla 6 del anexo del propio proyecto: *un conteo se suma; una razón
entre dos conteos se recalcula sobre las sumas, no se promedia*.

### La evidencia en el código

`02_Code/03_tablas/03_ordenamiento.R`, líneas 660-663: un solo `como = "promedio"`
para cuatro columnas de naturalezas distintas.

```r
tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
                         columnas = columnas, como = "promedio") |>
  .etiquetar_agregados(stats::setNames(
    paste0("PROMEDIO SIMPLE PROVINCIA ", toupper(prov$etiqueta)), "Total provincia")) |>
```

**No fue un descuido: está documentado** en el comentario que abre la función
(líneas 622-623), que lo atribuye al código Stata original —*«así lo define el
.do y así se publicó el informe»*—. Es una decisión heredada, no un olvido.

### Cómo se decidió la corrección

Se contrastaron las tres agregaciones posibles sobre los datos reales:

| Del Río Grande | Líneas totales | Prop. fibra | Líneas/1.000 hab. |
|---|---:|---:|---:|
| Promedio simple *(anterior)* | 13.639,8 | 56,1 % | 727,3 |
| Ponderado por población | 15.344,8 | 62,7 % | **673,7** |
| **Suma / recálculo sobre sumas** | **68.199** | **59,9 %** | **673,7** |

Dos conclusiones que decidieron el criterio:

1. **En las dos tasas no hay discusión.** El promedio ponderado con su peso
   correcto —población para la tasa por mil, líneas para la proporción de fibra—
   es algebraicamente idéntico a recalcular sobre las sumas.
2. **Ponderar los dos conteos por población da un tercer número** que no es el
   total ni el promedio, que el lector no puede reconstruir desde la tabla —haría
   falta una columna de población que la hoja no publica— y que rompe con el resto
   del informe: en las diez secciones, los 41 usos de la función de agregación
   suman todos los conteos y ponderan todas las tasas.

### Qué se cambió y dónde

**Archivo:** `02_Code/03_tablas/03_ordenamiento.R`. Dos tramos, 22 líneas de diff.

**a) Comentario de cabecera, líneas 622-623.** Decía lo contrario de lo que el
código hace ahora.

| | |
|---|---|
| Antes | *«El agregado provincial es promedio SIMPLE de los valores municipales, también para los conteos: así lo define el .do y así se publicó el informe.»* |
| Después | *«Los conteos se suman y las razones se recalculan sobre las sumas (regla 6 del anexo). El .do original promediaba las cuatro columnas, también los conteos: la fila provincial publicaba la suma dividida por el número de municipios.»* |

**b) Bloque de agregación, líneas 649-665.**

```diff
   columnas <- c("lineas_totales", "lineas_fibra", "prop_fibra", "internet_1000hab")
+  sumables <- c("lineas_totales", "lineas_fibra", "poblacion")
 
   municipios <- lineas |>
     dplyr::inner_join(poblacion, by = "ind_mpio") |>
-    dplyr::mutate(internet_1000hab = .data$lineas_totales / .data$poblacion * 1000) |>
     con_territorio() |>
     filtrar_provincia(prov) |>
     dplyr::arrange(.data$nvl_label) |>
     dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
-                  dplyr::all_of(columnas))
+                  dplyr::all_of(sumables))
 
+  # Se suman los conteos y las razones se recalculan al final: así la fila de
+  # municipio y la de agregado salen de la misma fórmula.
   tabla <- agregar_totales(municipios, universo = NULL, prov = prov,
-                           columnas = columnas, como = "promedio") |>
+                           columnas = sumables, como = "suma") |>
+    dplyr::mutate(
+      prop_fibra       = .data$lineas_fibra / .data$lineas_totales,
+      internet_1000hab = .data$lineas_totales / .data$poblacion * 1000
+    ) |>
     .etiquetar_agregados(stats::setNames(
-      paste0("PROMEDIO SIMPLE PROVINCIA ", toupper(prov$etiqueta)), "Total provincia")) |>
+      paste0("PROVINCIA ", toupper(prov$etiqueta),
+             " (suma de líneas; razones recalculadas sobre las sumas)"), "Total provincia")) |>
     dplyr::select("ind_mpio", "municipio", "subregion", "provincia",
                   dplyr::all_of(columnas), "tipo_fila")
```

Tres cambios y nada más: se lleva `poblacion` hasta la agregación —antes se
descartaba—, se suma en vez de promediar, y las dos razones se recalculan después
para todas las filas. **Las columnas publicadas, sus encabezados y sus formatos
son exactamente los mismos.**

Es el patrón que el propio archivo ya usa 500 líneas más arriba, en
`.hoja_deficit_vivienda()`, con su comentario incluido.

### Cómo se comprobó antes de entregarlo

- Sintaxis del archivo completo validada con `parse()`.
- Finales de línea originales (CRLF) conservados: el `git diff` muestra 22 líneas,
  no el archivo entero.
- Los valores esperados se calcularon por fuera, en Python, desde el derivado.

### Efecto esperado en las salidas

**Las filas municipales no cambian.** Ya eran correctas: las 352 celdas
municipales de las once provincias se verificaron una a una contra el archivo de
origen. Cambia **solo la fila de total provincial**, en las once.

| | Del Río Grande | Turística y Agroecológica |
|---|---:|---:|
| Líneas totales | 13.639,8 → **68.199** | 3.646,0 → **41.205** |
| Líneas de fibra | 8.164,4 → **40.822** | — → **17.375** |
| Proporción de fibra | 56,1 % → **59,9 %** | 24,1 % → **42,2 %** |
| Líneas por 1.000 hab. | 727,3 → **673,7** | 381,3 → **432,8** |

*(Turística y Agroecológica incluye ya el municipio añadido en la corrección 1.)*

**Cambian también dos figuras y el comparativo:**

- `fig_13_internet_1000hab` y `fig_14_internet_fibra`: la **línea de referencia
  provincial** se mueve. Las barras municipales no.
- **El documento comparativo ordena a las once provincias con esta cifra.** Con
  la corrección, **ocho de las once cambian de puesto**: De la Paz sube tres
  posiciones, Agroindustrial del Occidente dos, y el primer puesto pasa de Del
  Río Grande a Agua, Bosques y Turismo. El promedio simple comparaba «el
  municipio promedio» de cada provincia en vez de las provincias.

### Lo que se dejó pendiente a propósito

La prosa calcula la proporción de fibra con `mean()` sobre los municipios en vez
de leer la fila provincial. **No se corrigió aquí**: forma parte de la corrección
5 (`F-2-049`) y se agrupa con el resto de los cambios de prosa. Mientras tanto,
la figura y el párrafo darán cifras distintas — ver «Avisos abiertos» arriba.

---

## 4 · `F-2-027` — Leishmaniasis: se pondera por población total y su denominador es rural

**Estado:** aplicado · 2026-08-18

### El error

La hoja `enfermedades_tropicales` agrega sus tres tasas —dengue, malaria y
leishmaniasis— con un promedio ponderado **por población total**. Para las dos
primeras es correcto: son tasas por 100 mil habitantes. **La leishmaniasis se
mide sobre población rural**, así que al ponderarla por población total el peso
se lo llevan municipios con mucha gente y poca población rural.

El error no es constante ni pequeño, y **su signo depende de lo urbana que sea la
provincia** — que es justamente la variable con la que el lector interpreta la
cifra:

| Provincia | Publicado | Correcto | Error | % rural |
|---|---:|---:|---:|---:|
| Área Metropolitana | 15,880 | 7,675 | **+106,9 %** | 4,4 % |
| Minero Agroecológica | 354,943 | 258,374 | +37,4 % | 39,2 % |
| Turística y Agroecológica | 113,618 | 93,993 | +20,9 % | 53,5 % |
| Bioenergética del Norte | 257,119 | 300,170 | **−14,3 %** | 50,8 % |
| Del Río Grande | 1,613 | 1,586 | +1,7 % | 40,3 % |

### La evidencia en el código

`02_Code/03_tablas/09_salud.R`, líneas 227-231:

```r
  # Ponderador = POBLACIÓN (son tasas por 100 mil habitantes).
  tabla <- agregar_totales(
    municipios, universo = NULL, prov = prov, columnas = columnas,
    como = stats::setNames(as.list(rep("promedio_ponderado", length(columnas))), columnas),
    pesos = "pob_peso"
  ) |>
```

**El propio archivo reconoce el denominador correcto treinta líneas más abajo**,
al rotular la hoja:

```r
    # El .do rotulaba la leishmaniasis "por 100 mil hab.", pero el diccionario
    # del insumo (y el Anexo 1) la miden sobre POBLACIÓN RURAL: se explicita.
    leishmaniasis = "Tasa de leishmaniasis por 100 mil hab. rurales"
```

Es decir: se corrigió el rótulo y no llegó a corregirse el ponderador. La hoja
publica una tasa rotulada «por 100 mil hab. rurales» agregada como si fuera por
habitantes.

### El obstáculo, y por qué se resolvió así

`agregar_totales()` aceptaba **un método por columna** pero **un solo ponderador
para todas**, de modo que no había forma de ponderar la leishmaniasis distinto
sin salirse del ayudante. La alternativa —calcular ese agregado aparte y
sobrescribir la celda— habría **duplicado la lógica de tratamiento de ausentes**
que el ayudante ya tiene, que es exactamente el defecto corregido en la
corrección 2.

Se optó por **extender el ayudante de forma simétrica con su propio diseño**: si
`como` admite una lista columna → método, `pesos` admite una lista columna → peso.

### Qué se cambió y dónde

**a) `02_Code/R/01_utils.R`** — función `agregar_totales()`, rama
`promedio_ponderado` (línea 194). **Una línea sustituida, cuatro añadidas.**

```diff
         promedio_ponderado = {
-          w <- suppressWarnings(as.numeric(d[[pesos]]))
+          # `pesos` admite un nombre de columna, o una lista columna -> peso,
+          # igual que `como` admite un método o una lista columna -> método.
+          col_peso <- if (is.list(pesos)) pesos[[cl]] else pesos
+          w <- suppressWarnings(as.numeric(d[[col_peso]]))
           ok <- !is.na(x) & !is.na(w)
           if (any(ok)) stats::weighted.mean(x[ok], w[ok]) else NA_real_
         },
```

> **Este es el único cambio de esta fase sobre infraestructura compartida.**
> `agregar_totales()` la usan las diez secciones. Por eso el cambio se hizo
> compatible hacia atrás y se comprobó como tal (ver pruebas abajo): cuando
> `pesos` es un texto —los otros diez usos del proyecto— el comportamiento es
> literalmente el de antes.

**b) `02_Code/03_tablas/09_salud.R`** — `.pesos_poblacion()` (líneas 109-125).
Antes devolvía solo la población total; ahora devuelve también la rural, de la
**misma fuente y el mismo año**, para no mezclar series. La columna `pob_peso`
conserva su nombre, así que las demás hojas que la usan no se enteran.

```r
  por_area <- function(area, nombre) {
    x <- d |>
      dplyr::filter(a_numero(.data[[c_ano]]) == 2025, .data[[c_area]] == area) |>
      dplyr::transmute(ind_mpio = as.integer(a_numero(.data[[c_cod]])),
                       peso     = a_numero(.data[[c_pob]])) |>
      dplyr::filter(!is.na(.data$ind_mpio))
    stats::setNames(x, c("ind_mpio", nombre))
  }

  dplyr::left_join(por_area("Total", "pob_peso"),
                   por_area("Centros Poblados y Rural Disperso", "pob_rural"),
                   by = "ind_mpio")
```

**c) `02_Code/03_tablas/09_salud.R`** — `.hoja_enfermedades_tropicales()`
(líneas 233-246): se lleva `pob_rural` hasta la agregación, se pasa el ponderador
por columna, y la etiqueta de la fila agregada deja constancia de los dos pesos.

```diff
-    pesos = "pob_peso"
+    pesos = list(dengue = "pob_peso", malaria = "pob_peso",
+                 leishmaniasis = "pob_rural")
   ) |>
-    .marcar_ponderado("por población") |>
+    .marcar_ponderado("por población; leishmaniasis por población rural") |>
```

### Cómo se comprobó antes de entregarlo

El núcleo modificado de `agregar_totales()` se ejecutó en R en cuatro escenarios:

| Prueba | Resultado |
|---|---|
| `pesos` como texto (los otros diez usos del proyecto) | **Idéntico al comportamiento anterior** |
| `pesos` como lista por columna | Dengue y malaria **exactamente iguales**; leishmaniasis pasa a ponderarse por rural |
| Un municipio sin dato y otro sin peso rural | Se conserva el tratamiento de ausentes del ayudante |
| Métodos mezclados (suma + ponderado) con pesos por columna | Correcto |

Sintaxis de los dos archivos validada con `parse()`. Finales de línea CRLF
conservados: el `git diff` de `01_utils.R` son 5 líneas y el de `09_salud.R`, 45.

### Efecto esperado en las salidas

**Las filas municipales no cambian.** Cambia solo la fila provincial, y solo en
la columna de leishmaniasis: dengue y malaria quedan idénticos.

| | Del Río Grande | Turística y Agroecológica |
|---|---:|---:|
| Dengue | 0,33 *(sin cambio)* | 23,07 *(sin cambio)* |
| Malaria | 0,00 *(sin cambio)* | 24,39 *(sin cambio)* |
| **Leishmaniasis** | 1,613 → **1,586** | 113,618 → **93,993** |

Cambia también la línea de referencia provincial de la figura de enfermedades por
vectores. **Las otras nueve secciones no deben cambiar en nada** — y esa es la
comprobación que hay que hacer en la corrida, porque es el único cambio que toca
código compartido.

---

## 6 · `F-2-028` — El inventario pecuario convierte «sin registro» en «cero»

**Estado:** aplicado · 2026-08-18

### El error

Las cuatro hojas del archivo pecuario se unen por municipio y año, y toda ausencia
resultante se convertía en **cero**. Para el porcino de 2019 eso es falso: esa
hoja solo cubre **24 de los 125 municipios**, y los 101 restantes se publicaban
con cero cerdos. No son municipios sin cerdos — en 2020 declaran hasta 118.604
cabezas.

El resultado es un salto entre 2019 y 2020 que se lee como crecimiento del hato y
es puro cambio de cobertura de la fuente: **+478 % en Del Río Grande y +196 % en
Turística y Agroecológica**. Y como `total_especies` sumaba esos ceros, el error
se propagaba al total pecuario y a las participaciones calculadas sobre él.

Incumple la regla 5 del anexo —*«cero ≠ vacío»*— en el único sitio del pipeline
donde el vacío se convertía en cero de forma masiva.

### La evidencia en el código

`02_Code/03_tablas/06_desarrollo_rural.R`, `.universo_pecuario()`, líneas 122-130:

```r
#' Una especie sin registro en un municipio-año queda en 0, como en el .do.
...
  faltantes <- setdiff(names(ESPECIES_PECUARIAS), names(d))
  for (v in faltantes) d[[v]] <- 0

  d |>
    dplyr::mutate(dplyr::across(dplyr::all_of(names(ESPECIES_PECUARIAS)),
                                \(x) dplyr::coalesce(x, 0))) |>
```

El comentario *«como en el .do»* explica el origen, no que sea correcto: el `.do`
heredó el mismo problema.

### Por qué la corrección no podía ser «dejar todos los vacíos en blanco»

Se midió la cobertura de las cuatro hojas, año por año:

| Especie | Cobertura 2019-2025 | Mínimo respecto de su propio máximo |
|---|---|---:|
| Bovinos | 125 · 125 · 125 · 125 · 125 · 125 · 125 | 100 % |
| Búfalos | 61 · 65 · 74 · 66 · 82 · 75 · 76 | 74 % |
| Caprinos / ovinos / equinos | 125 · 125 · 125 · 124 · 124 · 124 · 124 | 99 % |
| **Porcinos** | **24** · 125 · 125 · 123 · 123 · 123 · 123 | **19 %** |

**Los búfalos cubren entre 61 y 82 municipios todos los años, y ahí el cero es
correcto**: esa hoja solo lista los municipios que tienen búfalos. Blanquear toda
ausencia habría vaciado casi toda esa columna y, con ella, el total pecuario de
casi todos los municipios.

Lo que distingue al porcino de 2019 no es que le falten municipios, sino que **le
faltan respecto de sí mismo**.

### Qué se cambió y dónde

**Archivo:** `02_Code/03_tablas/06_desarrollo_rural.R`, `.universo_pecuario()`.
Se retiran 2 líneas (el `coalesce` global) y entran 19.

```diff
+  # El porcino de 2019 trae 24 municipios de 125, y los 101 restantes no son
+  # municipios sin cerdos: en 2020 declaran hasta 118.604 cabezas. El búfalo, en
+  # cambio, cubre entre 61 y 82 todos los años, y ahí el cero sí es correcto: la
+  # hoja solo lista los municipios que tienen. El umbral separa los dos casos.
+  COBERTURA_MIN <- 0.5
+  for (v in names(ESPECIES_PECUARIAS)) {
+    cob   <- tapply(!is.na(d[[v]]), d$anio, sum)
+    malos <- names(cob)[cob < COBERTURA_MIN * max(cob)]
+    ok    <- !(as.character(d$anio) %in% malos)
+    d[[v]][ok] <- dplyr::coalesce(d[[v]][ok], 0)
+    if (length(malos)) {
+      message("  [pecuario] ", v, ": cobertura insuficiente en ", ...)
+    }
+  }
+
   d |>
-    dplyr::mutate(dplyr::across(dplyr::all_of(names(ESPECIES_PECUARIAS)),
-                                \(x) dplyr::coalesce(x, 0))) |>
     dplyr::mutate(
       total_especies = rowSums(dplyr::pick(dplyr::all_of(names(ESPECIES_PECUARIAS))))
```

`total_especies` ya usaba `rowSums()` sin `na.rm`, así que **el total de 2019
queda vacío por sí solo**, sin tocar esa línea. Y la corrida deja constancia en
el log de qué especie y qué año se blanquearon, en vez de hacerlo en silencio.

### Cómo se comprobó antes de entregarlo

El bloque nuevo se ejecutó en R sobre las coberturas reales medidas en el insumo:

| Prueba | Resultado |
|---|---|
| ¿Qué especie-año se marca? | **Solo porcinos 2019**, y el log lo dice: *«24 de 125 municipios»* |
| ¿Cuántos valores se vacían? | **101** — exactamente los municipios sin registro |
| ¿Se tocan los búfalos? | **No**: siguen en cero en 376 filas pese a cubrir 61-82 municipios |
| ¿Se tocan los años 2020-2025? | **No**, ningún vacío nuevo |
| Total pecuario | Vacío solo en esas 101 filas de 2019 |

Sintaxis validada con `parse()`; CRLF conservados. El `git diff` son 26 líneas.

### Alcance: qué NO cambia, comprobado antes de aplicar

Se rastrearon los cinco consumidores del inventario pecuario y **los cinco se
quedan solo con el último año de la serie**, que es 2025 y tiene cobertura normal:

| Consumidor | Cómo lee | ¿Toca 2019? |
|---|---|:--:|
| `fig_01_participacion_pecuaria` | `anio_pec <- max(anio)` | No |
| `fig_02_composicion_especies` | `filter(anio == anio_pec)` | No |
| Prosa, sección 06 | `ultimo_anio(...)` | No |
| Comparativo, ranking pecuario | `d <- ultimo_anio(d)` | No |
| `comparar_referencia.R` | año del título, o `max(anios)` | No |

**Ninguna figura, ninguna prosa y ningún ranking cambian.** El efecto se limita a
la hoja `inventario_pecuario` del Excel, que es la única pieza que publica la
serie completa de siete años.

### Un efecto de rebote que conviene anticipar

Al blanquear 2019 quedará visible una incoherencia **dentro de la propia hoja**:
la fila `TOTAL SUBREGIÓN NORTE` de 2019 seguirá publicando 99.695 porcinos
—porque la subregión incluye municipios de fuera de la provincia que sí tienen
registro— junto a filas municipales en blanco. Esa incoherencia ya existe hoy,
disfrazada de ceros; ahora será evidente. Es preferible: una discrepancia visible
se investiga, una disfrazada de cero se publica.

### Lo que dijo la corrida de muestra (20-ago-2026)

La verificación marcó dos `FALLA` en esta corrección. **El defecto estaba en la
prueba, no en el código.** La prueba exigía que *todos* los porcinos de 2019
quedaran vacíos; la fuente sí trae 24 municipios del país con registro en 2019:

| Provincia | Municipios | Con registro 2019 | Vacíos esperados | Vacíos obtenidos |
|---|:--:|---|:--:|:--:|
| Del Río Grande | 5 | Donmatías (5237), Santa Rosa de Osos (5686) | 3 | 3 |
| Turística y Agroecológica | 8 | Santa Fe de Antioquia (5042) | 7 | 7 |

Comprobado leyendo `01_Data/00_Inputs/curados/PECUARIO_PROVINCIAS.xlsx`, hoja
`InvPorcino`. El código hizo exactamente lo que debía: vació los municipios sin
registro y respetó los que sí lo tienen. La aserción de
`15_verificar_correcciones.R` se corrigió para comprobar lo correcto —el número
de vacíos y que **no quede ningún 0** en 2019, que era el síntoma original.

### Un límite conocido de la corrección

Si una especie faltara **por completo** del archivo, el código sigue rellenándola
con ceros, como antes. Ese caso no se da hoy —las seis especies están— y
corregirlo habría exigido decidir qué hacer con un total pecuario enteramente
vacío, que es una discusión aparte.

---

## 7 · `F-2-018` — Dos series de población en el mismo libro

**Estado:** aplicado **en parte** · 2026-08-18 · **sin probar en ejecución** (ver más abajo)

### El error

El proyecto tiene dos fuentes de población municipal y usa las dos a la vez:

- **PPED** (proyecciones DANE 2018-2042), derivado `poblacion_total_2025` — **es
  la serie con la que se publicó el informe**.
- **`POBLACION MUNICIPAL.xlsx`**, heredada del código Stata.

La hoja `poblacion` usa la primera y la hoja `estructura_edad` **del mismo libro**
usa la segunda. **Yarumal aparece con 41.884 habitantes en una y 44.770 en la
otra.** Medido en los 125 municipios, las dos series difieren entre **−15,4 % y
+14,2 %**, con mediana −0,7 %; a nivel departamental casi coinciden (+0,34 %), lo
que hace la discrepancia invisible en los totales y muy visible en los municipios.

### La evidencia en el código

El autor **conoce la discrepancia, la documentó con estas mismas cifras y tomó
una decisión razonada**. Cabecera de `02_demografia.R`:

```r
# FUENTE DE POBLACIÓN — desviación deliberada respecto del .do:
# El .do lee POBLACION MUNICIPAL.xlsx, pero esa serie NO es la que se publicó.
# El informe salió de la serie PPED 2018-2042 [...]
# Comprobado municipio a municipio: con la serie PPED se reproduce el Anexo 1
# [...] con POBLACION MUNICIPAL.xlsx las cifras difieren entre −3 % y +10 %
# por municipio (Yarumal 44.770 vs 41.884 publicados).
# Se usa la serie publicada, porque el pipeline debe poder rehacer el informe.
```

**La decisión es correcta; lo que no ocurrió es que se aplicara fuera de esa
hoja.** Hay nueve puntos en cinco archivos que siguen leyendo la serie descartada.

### Por qué esta corrección no pudo ser mínima

El derivado PPED con edades que ya existe —`poblacion_municipal_total_2025`—
**no sirve**: trae cuatro tramos de ciclo de vida (0-11, 12-28, 29-59, 60-85) y la
hoja publica **nueve grupos decenales**. Había que construir un derivado nuevo.

Lo que sí facilitó las cosas: **el PPED trae 101 columnas de edad simple por
sexo** («Hombres 0 años» … «Hombres 100 años y más»), y `poblacion_municipal.R`
ya tiene la maquinaria para leerlas —`.matriz_edades()` y `.total_grupo()`—. Los
grupos decenales son sumas exactas de edades simples: no hay aproximación.

### Qué se cambió y dónde

**Archivo 1 — `02_Code/01_homogeneizacion/poblacion_municipal.R`.** Entran 41
líneas; no se retira ninguna. Se añade un derivado, reutilizando `.total_grupo()`:

```r
DECENIOS <- list(
  edad_0_9    = list(edades =  0:9,  cien = FALSE),
  ...
  edad_80_mas = list(edades = 80:99, cien = TRUE)
)

poblacion_edad_2025 <- pob_2025 |>
  dplyr::transmute(ind_mpio, nvl_label, cod_dpto, area_geo, pob_masc, pob_fem)

for (g in names(DECENIOS)) {
  poblacion_edad_2025[[g]] <- .total_grupo("T", edades, cien)
  poblacion_edad_2025[[sub("^edad", "h_edad", g)]] <- .total_grupo("H", edades, cien)
  poblacion_edad_2025[[sub("^edad", "m_edad", g)]] <- .total_grupo("M", edades, cien)
}

poblacion_edad_2025 <- poblacion_edad_2025 |>
  dplyr::filter(cod_dpto == "05", area_geo == AREA_TOTAL) |>
  dplyr::select(-"cod_dpto", -"area_geo")

escribir_derivado(poblacion_edad_2025, "poblacion_edad_2025")
```

Se colocó **junto a los otros dos `escribir_derivado`, sin renumerar ninguna
sección** del archivo, y se documentó en la cabecera `OUTPUTS`.

**Archivo 2 — `02_Code/03_tablas/02_demografia.R`.** Se retiran 22 líneas y
entran 12. La hoja pasa a leer el derivado:

```r
  base <- leer_derivado("poblacion_edad_2025") |>
    dplyr::mutate(ind_mpio = as.integer(.data$ind_mpio)) |>
    dplyr::select(-dplyr::any_of("nvl_label"))
```

Con eso quedan **sin uso** `.suma_tramos()` y `.TRAMOS`, que existían solo para
leer la hoja de quinquenios: se retiran. Y `.GRUPOS` pasa de ser una lista de
índices sobre `.TRAMOS` a un vector de nombres, porque solo se usaban sus nombres
y los índices habrían quedado apuntando a una constante borrada.

**Las columnas publicadas, sus nombres, su orden y sus etiquetas no cambian.**

### Lo que NO se corrigió, y por qué

Los **ponderadores** de las secciones 03, 04, 05 y 09 siguen usando la serie
descartada. Se midió su efecto antes de decidir:

| Indicador | Diferencia entre ponderadores, 11 provincias |
|---|---|
| Dengue | −3,4 % a +5,0 % |
| Malaria | −6,2 % a +3,7 % |
| Leishmaniasis | −3,9 % a +2,0 % |
| Natalidad | −0,5 % a +0,8 % |
| Mortalidad | −0,1 % a +1,1 % |

Es un efecto de segundo orden: un ponderador solo mueve pesos relativos. Y la
sección 03 usa además ponderadores de **2022 y 2024**, años que el derivado PPED
no cubre — cerrarlos exige extender `poblacion_municipal.R` a otros años.

Se dejan abiertos en la ficha `F-2-018`, con la medición hecha.

### ⚠️ Esta corrección no se pudo probar antes de entregarla

Es la primera del bloque en la que **no hay verificación previa**. Dos razones:

1. **El insumo PPED pesa 131 MB y no está versionado.** Se intentó traerlo por el
   puente y no pasó.
2. En el entorno de revisión **no está instalado `dplyr`**, así que el bloque no
   se puede ejecutar aunque hubiera datos.

Lo único validado es la **sintaxis** de los dos archivos (`parse()`, con locale
UTF-8 porque el script usa `año` como nombre de variable) y que **los grupos
decenales son sumas exactas de las edades simples que la fuente trae**, leído del
propio código que ya las procesa.

**Hay que comprobarlo en la corrida**, con la prueba de la sección siguiente.

### Cómo comprobar que quedó bien

La comprobación es directa y es exactamente lo que el hallazgo dice que está roto:
**la estructura por edad tiene que sumar la población de la hoja anterior del
mismo libro.**

```r
library(openxlsx2)
f <- "03_Outputs/Rio_Grande/02_Demografia/demografia.xlsx"
pob <- wb_to_df(wb_load(f), sheet = "poblacion")
edad <- wb_to_df(wb_load(f), sheet = "estructura_edad")

a <- as.numeric(pob[["Habitantes (total)"]])
b <- as.numeric(edad[["Población masculina"]]) + as.numeric(edad[["Población femenina"]])
data.frame(municipio = pob[["Municipio"]], poblacion = a, suma_por_sexo = b,
           dif = round(b - a, 1))
```

**Debe salir `dif = 0` en todas las filas.** Antes de la corrección no salía: en
Bioenergética del Norte, Yarumal daba 41.884 frente a 44.770.

Y en la corrida, `poblacion_municipal.R` debe escribir una línea más:

```
[derivado] poblacion_edad_2025.parquet  (125 x 30, ...)
```

### Efecto en las salidas

Cambian **todas las cifras de la hoja `estructura_edad` de los once informes**, y
con ellas la pirámide poblacional (`fig_04_piramide_poblacional`), que se
construye desde esa hoja. La hoja `poblacion` no cambia. El resto del informe
tampoco.

### Consecuencias fuera del código

1. **El anexo metodológico cambia** al añadirse un derivado: `\cifraDerivados` y
   los dos grafos —script→derivado y sección→recurso— se regeneran solos con
   `generar_tablas_anexo.R`. **Pero solo si el anexo se regenera con una corrida
   completa**, que es la corrección 14 (`F-2-064`). Hay dependencia entre las dos.
2. **El anexo no declara hoy qué serie de población sostiene el informe.** Se
   buscó en las 52.000 palabras del documento: la única mención de
   `POBLACION MUNICIPAL.xlsx` está en la Regla 3, como ejemplo de nombre de
   archivo que no se renombra. Convendría escribirlo, con cambio o sin él.
3. **Toca el terreno de `F-2-015`** (corrección 16, bloqueada esperando respuesta
   externa): el derivado PPED publica su propio índice de envejecimiento, que
   difiere del que hoy se publica desde un curado. Esta corrección **no lo toca**
   —solo añade grupos decenales—, pero deja las dos versiones a la vista.

---

## 8 · `F-2-036` — El titular de vectores suma tres tasas no comparables

**Estado:** aplicado · 2026-08-20
**Archivo:** `02_Code/04_figuras/09_salud.R`

### El error

La figura `fig_03_enfermedades_vectores` dibuja tres paneles con escalas
independientes —dengue, malaria y leishmaniasis— porque las tres tasas tienen
denominadores distintos. Para elegir el municipio del **titular** y para ordenar
las barras, sin embargo, el código **sumaba las tres tasas**.

Dengue y malaria se miden sobre población total; la leishmaniasis, sobre
población **rural**. La suma no es una magnitud: es un número en el que la
leishmaniasis pesa de más solo por tener el denominador más pequeño.

### La evidencia en el código

El propio proyecto declara la regla dos veces y la figura la incumple las dos.
Tres líneas antes de la suma, en el mismo archivo:

```r
# Múltiplos pequeños en vez de barras agrupadas: las tres enfermedades tienen
# denominadores distintos (la leishmaniasis se mide sobre población rural) y
# órdenes de magnitud distintos, así que una escala común sería ilegible y
# además compararía cosas que no son comparables (DISENO.md §2.1).
vec <- solo_municipios(tabla$enfermedades_tropicales)
enfermedades <- c(dengue = "Dengue", malaria = "Malaria",
                  leishmaniasis = "Leishmaniasis")
carga <- rowSums(vec[, names(enfermedades)], na.rm = TRUE)
```

Y la prosa de esa misma sección, en `02_Code/05_documento/R/secciones.R:1228`:

```r
# Dengue y malaria se miden sobre población total; la leishmaniasis, sobre
# población RURAL. Ordenarlas juntas para decir cuál «incide más» compararía
# tasas con denominadores distintos, que es una forma silenciosa de mentir.
# Cada una se reporta con su denominador y no se rankean entre sí.
```

La prosa cumple la regla; la figura de al lado la rompe. El informe se
contradice a sí mismo en la misma página.

### Lo que producía

Medido sobre las once salidas publicadas: en **5 de 11 provincias** el titular
nombraba a un municipio distinto del que resulta con cualquier criterio
adimensional.

| Provincia | Titular publicado | Con criterio adimensional |
|---|---|---|
| Bioenergética del Norte | Anorí | Valdivia |
| Agroindustrial de Occidente | Frontino | Dabeiba |
| De la Paz | Nariño | Sonsón |
| Penderisco y Sinifaná | Urrao | Anzá |
| Turística y Agroecológica | Buriticá | San Jerónimo |

En Bioenergética, Valdivia encabeza **dos de las tres** enfermedades (dengue 39,1
y leishmaniasis 1.167,9) y Anorí solo una (malaria 827,0). El titular publicaba
Anorí porque 25,7 + 827,0 + 914,4 = 1.767 supera a 39,1 + 195,4 + 1.167,9 = 1.402.

Dos defectos añadidos:

1. **En provincias sin transmisión el titular fabricaba un hallazgo.** En Del Río
   Grande cuatro municipios están en cero y Santa Rosa de Osos tiene 0,86 de
   dengue y 4,19 de leishmaniasis. El titular publicado decía: *«Santa Rosa de
   Osos soporta la mayor carga de enfermedades transmitidas por vectores de la
   provincia»*.
2. **La magnitud que decidía el titular no se publicaba.** La hoja `_fig_03`
   guardaba solo las tres tasas, nunca `carga`. Contra la regla 11.

### Qué se cambió y dónde

**Se aplica a la figura la regla que ya está escrita en la prosa: no se suman.**
El titular nombra al municipio que encabeza **cada** enfermedad; el orden
vertical usa la posición promedio dentro de cada enfermedad, que es adimensional,
y esa posición se publica como columna.

**a) `02_Code/04_figuras/09_salud.R`, después de la línea 35** (tras las
constantes `FUENTE_*`, antes de `figuras_salud()`) — bloque nuevo, 34 líneas:

```r
# El titular de la figura de vectores. Las tres enfermedades no comparten
# denominador, así que no se suman ni se rankean entre sí: se nombra al
# municipio que encabeza cada una. Si el mismo los encabeza todos la frase se
# colapsa, y si la provincia no registra casos no se nombra a nadie.
VECTORES_CON_ARTICULO <- c(dengue = "el dengue", malaria = "la malaria",
                           leishmaniasis = "la leishmaniasis")

.unir_y <- function(x) {
  if (length(x) < 2L) return(paste(x, collapse = ""))
  paste(paste(x[-length(x)], collapse = ", "), "y", x[length(x)])
}

.titular_vectores <- function(lideres, provincia) {
  n_total <- length(lideres)
  lideres <- lideres[!is.na(lideres)]
  if (length(lideres) == 0L) {
    return(sprintf(
      "La provincia %s no registra casos de enfermedades transmitidas por vectores",
      provincia))
  }
  nombres <- VECTORES_CON_ARTICULO[names(lideres)]
  ms <- unique(unname(lideres))
  if (length(ms) == 1L) {
    if (length(lideres) == n_total) {
      return(sprintf(
        "%s encabeza las tres enfermedades transmitidas por vectores de la provincia",
        ms))
    }
    return(sprintf("%s encabeza %s en la provincia", ms, .unir_y(nombres)))
  }
  partes <- vapply(ms, function(m) .unir_y(nombres[lideres == m]), character(1))
  paste(c(sprintf("%s encabeza %s", ms[1], partes[1]),
          sprintf("%s, %s", ms[-1], partes[-1])), collapse = "; ")
}
```

**b) Antes — línea 165 (una línea):**

```r
  carga <- rowSums(vec[, names(enfermedades)], na.rm = TRUE)
```

**Después — 21 líneas:**

```r
  # Las tres tasas NO se suman: el dengue y la malaria se miden sobre población
  # total y la leishmaniasis sobre población RURAL, de modo que el total sería un
  # número sin significado en el que la leishmaniasis pesa de más por tener el
  # denominador más pequeño. Es la misma regla que ya aplica la prosa de esta
  # sección (05_documento/R/secciones.R): cada enfermedad se reporta con su
  # denominador y no se rankean entre sí. En consecuencia:
  #   - el titular nombra al municipio que encabeza CADA enfermedad;
  #   - el orden vertical usa la posición promedio dentro de cada enfermedad,
  #     que es adimensional, y se publica como columna (regla 11).
  tasas  <- vec[, names(enfermedades), drop = FALSE]
  rangos <- sapply(tasas, rank, na.last = "keep")
  dim(rangos) <- c(nrow(vec), ncol(tasas))
  orden  <- rowMeans(rangos, na.rm = TRUE)
  orden[is.na(orden)] <- 0
  vec$posicion_promedio <- round(orden, 2)

  lideres <- vapply(names(enfermedades), function(v) {
    x <- tasas[[v]]
    if (all(is.na(x)) || max(x, na.rm = TRUE) <= 0) NA_character_
    else vec$municipio[which.max(x)]
  }, character(1))
```

**c) Orden de las barras — antes (línea 173) / después:**

```r
      municipio  = factor(.data$municipio, levels = vec$municipio[order(carga)])
      municipio  = factor(.data$municipio, levels = vec$municipio[order(orden)])
```

**d) Se elimina la línea 176:**

```r
  peor_vec <- vec[which.max(carga), ]
```

**e) Titular — antes (líneas 195-198) / después (una línea):**

```r
      titulo = sprintf(
        "%s soporta la mayor carga de enfermedades transmitidas por vectores de la provincia",
        peor_vec$municipio
      ),
```
```r
      titulo = .titular_vectores(lideres, prov$etiqueta),
```

**f) Subtítulo — se declara el criterio de orden (línea 202):**

```r
              "Cada panel tiene su propia escala."),
```
```r
              "Cada panel tiene su propia escala; los municipios se ordenan por",
              "su posición promedio en las tres enfermedades."),
```

**g) Hoja de datos — se publica la magnitud que decide el orden (línea 211):**

```r
    vec[, c("municipio", names(enfermedades))], archivo, "fig_03"
    vec[, c("municipio", names(enfermedades), "posicion_promedio")], archivo, "fig_03"
```

### Cómo se comprobó antes de entregarlo

Sintaxis validada con `parse()`; CRLF conservados. El bloque nuevo se ejecutó en
R sobre los datos publicados de las once provincias (hoja `_fig_03` de cada
`salud.xlsx`). Los once titulares resultantes:

| Provincia | Titular nuevo |
|---|---|
| Agroindustrial de Occidente | Uramita encabeza el dengue; Frontino, la malaria; Dabeiba, la leishmaniasis |
| Agua, Bosques y Turismo | San Francisco encabeza el dengue; San Carlos, la malaria; San Luis, la leishmaniasis |
| Área Metropolitana | Medellín encabeza las tres enfermedades transmitidas por vectores de la provincia |
| Bioenergética del Norte | Valdivia encabeza el dengue y la leishmaniasis; Anorí, la malaria |
| Cartama | La Pintada encabeza las tres enfermedades transmitidas por vectores de la provincia |
| De la Paz | Sonsón encabeza el dengue; Nariño, la leishmaniasis |
| Minero Agroecológica | Segovia encabeza las tres enfermedades transmitidas por vectores de la provincia |
| Penderisco y Sinifaná | Anzá encabeza el dengue y la leishmaniasis; Urrao, la malaria |
| Del Río Grande | Santa Rosa de Osos encabeza el dengue y la leishmaniasis en la provincia |
| San Juan | Salgar encabeza el dengue; Ciudad Bolívar, la malaria y la leishmaniasis |
| Turística y Agroecológica | Olaya encabeza el dengue; San Jerónimo, la malaria; Buriticá, la leishmaniasis |

Las cuatro ramas del titular quedan ejercidas por datos reales: un municipio que
encabeza las tres (Medellín, Segovia, La Pintada), tres municipios distintos
(Turística), dos y uno (Bioenergética), y una enfermedad sin casos que se omite
sola (De la Paz, donde la malaria es cero en los cinco municipios).

### Efecto esperado en las salidas

Cambia el **titular** de la figura 3 de la sección 9 en las once provincias, y el
**orden vertical** de las barras. No cambia ninguna cifra: las tasas de los tres
paneles son las mismas. La hoja `_fig_03` gana una columna,
`posicion_promedio`.

**No hay efecto fuera de la figura.** La prosa de la sección 9 nunca leyó
`carga` —construye su párrafo enfermedad por enfermedad— y el comparativo no
usa estas tasas.

### Dos límites conocidos

1. **La posición promedio da igual peso a las tres enfermedades.** Es una
   decisión editorial, no un hecho: en Turística, San Jerónimo queda arriba de
   Buriticá pese a que Buriticá tiene 201 de leishmaniasis contra 27,6. El
   criterio está declarado en el subtítulo y publicado en la hoja, que es lo que
   la suma anterior no hacía.
2. **En provincias con transmisión mínima el titular sigue nombrando a alguien.**
   En Del Río Grande dirá que Santa Rosa de Osos encabeza el dengue (0,86) y la
   leishmaniasis (4,19). El umbral se puso en cero —solo se calla cuando no hay
   ningún caso— para no inventar un mínimo que nadie declaró. Es menos grave que
   antes: la frase ya no afirma que el municipio «soporta la mayor carga», solo
   que encabeza cada indicador, que es literalmente cierto.

---

## 9 · `F-3-005` — El pipeline no puede leer el archivo del MinTIC

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/01_homogeneizacion/infraestructura_internet.R`,
`01_Data/00_Inputs/README.md`

### El error

El script lee `EMPAQUETAMIENTO_FIJO_3.csv` suponiendo que las columnas van
separadas por **comas**. El archivo que publica hoy el MinTIC va separado por
**punto y coma**, y trae los encabezados en MAYÚSCULAS.

`readr::read_csv()` no falla con el separador equivocado: devuelve una tabla de
**una sola columna** cuyo nombre es la línea de cabecera entera.

### La evidencia en la corrida

`04_Docs/revision/evidencia/16_run_all.txt`, línea 26:

```
== infraestructura de internet ==
  [FALLO] infraestructura_internet.R: No encuentro ninguna de estas columnas: id_departamento
  Columnas disponibles: ANNO;TRIMESTRE;ID_EMPRESA;EMPRESA;ID_MUNICIPIO;MUNICIPIO;ID_DEPARTAMENTO;...
```

Esa lista de «columnas disponibles» **es una sola columna**. El código, línea 25:

```r
datos <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE) |>
  as.data.frame()
```

Hay que decir lo que funcionó: `col_req()` abortó de inmediato y su mensaje
nombra las columnas reales. Sin ese guarda el script habría seguido con una tabla
de una columna y habría escrito un derivado inservible.

### Las MAYÚSCULAS son la mitad del problema, y no estaban en el hallazgo

Arreglar el separador no basta. `escribir_derivado()` no toca los nombres de
columna (`01_utils.R:346`), y `03_tablas/03_ordenamiento.R` los pide en duro:
`.data$servicio_paquete`, `.data$estado`, `.data$tecnologia`. Con el separador
arreglado y los nombres en mayúscula, el derivado se escribiría bien y la sección
03 fallaría después. Por eso la corrección normaliza los nombres.

### Qué se cambió y dónde

**a) `infraestructura_internet.R`, líneas 25-36 — se retiran 12 líneas y entran 50.**

Antes:

```r
datos <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE) |>
  as.data.frame()

c_depto <- col_req(datos, "id_departamento")
c_mpio  <- col_req(datos, "id_municipio")
c_anno  <- col_req(datos, "anno", "año", "anio")

antioquia <- datos |>
  dplyr::filter(as.integer(.data[[c_depto]]) == 5L,
                as.integer(.data[[c_anno]]) == 2025L) |>
  dplyr::rename(ind_mpio = dplyr::all_of(c_mpio)) |>
  dplyr::mutate(ind_mpio = as.integer(ind_mpio))
```

Después, en cuatro pasos:

```r
# 1. El separador se detecta, no se supone
cabecera <- readLines(ruta, n = 1L, warn = FALSE)
sep <- if (stringr::str_count(cabecera, ";") > stringr::str_count(cabecera, ",")) ";" else ","

# 2. Los nombres se resuelven sobre una muestra de 100 filas, no sobre los 718 MB.
#    col_req() sigue siendo el guarda.
muestra <- readr::read_delim(ruta, delim = sep, n_max = 100,
                             col_types = readr::cols(.default = readr::col_character()),
                             show_col_types = FALSE, progress = FALSE)
names(muestra) <- tolower(names(muestra))
c_depto <- col_req(muestra, "id_departamento")
c_mpio  <- col_req(muestra, "id_municipio")
c_anno  <- col_req(muestra, "anno", "año", "anio")

# 3. Lectura por trozos, descartando lo que no es Antioquia 2025 sobre la marcha
recorte <- function(x, pos) {
  names(x) <- tolower(names(x))
  d <- suppressWarnings(as.integer(x[[c_depto]]))
  a <- suppressWarnings(as.integer(x[[c_anno]]))
  x[!is.na(d) & d == 5L & !is.na(a) & a == 2025L, , drop = FALSE]
}
antioquia <- readr::read_delim_chunked(
  ruta, delim = sep,
  callback = readr::DataFrameCallback$new(recorte),
  chunk_size = 200000,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE, progress = FALSE) |>
  as.data.frame() |>
  dplyr::rename(ind_mpio = dplyr::all_of(c_mpio))

# 4. Vuelven a número las columnas que lo son, con el conversor del pipeline
NUMERICAS <- c("anno", "trimestre", "id_empresa", "ind_mpio", "id_departamento",
               "id_segmento", "id_servicio_paquete", "id_tecnologia", "id_estado",
               "cantidad_lineas_accesos", "valor_facturado_o_cobrado",
               "otros_valores_facturados", "valor_total_plan_tarifario")
for (v in intersect(NUMERICAS, names(antioquia))) {
  antioquia[[v]] <- a_numero(antioquia[[v]])
}
antioquia$ind_mpio <- as.integer(antioquia$ind_mpio)
```

**Por qué todos los trozos se leen como texto:** si cada trozo adivinara sus
tipos por su cuenta, dos trozos podrían adivinar distinto y no se podrían unir.
Se leen como texto y se convierten al final, sobre 124.190 filas en vez de sobre
3,6 millones. `a_numero()` es la función que ya usa todo el pipeline y resuelve
los separadores locales, así que si una entrega futura trae decimales con coma,
no hay que tocar nada.

**b) El mensaje final declara el separador usado** (línea 45):

```r
message("  infraestructura_internet_2025.dta: ", nrow(antioquia), " registros")
```
```r
message("  infraestructura_internet_2025: ", nrow(antioquia), " registros",
        "  (separador «", sep, "»)")
```

**c) `01_Data/00_Inputs/README.md`** — se añade una tabla de procedencia del
archivo bajo «Fuentes ausentes del clon»: tamaño, MD5, separador, caja de los
encabezados, filas, columnas y periodos, más la constancia de que la entrega
anterior venía con comas, en minúscula y con una columna `period` de más. **La
fecha de descarga y la URL quedan en blanco: hay que anotarlas.**

### Cómo se comprobó

Sintaxis validada con `parse()`; CRLF conservados. La lectura ya se había probado
de punta a punta en la máquina de Pablo el 18 de agosto
(`evidencia/12_internet_lectura.txt`):

```
Separador detectado: «;»
Filas leídas en total (todo el país): 3.572.367
Filas de Antioquia 2025:              124.190
Tiempo:                               23.3 s
Pico de memoria de R:                 2010 MB
```

Y los tres agregados coincidieron **exactamente** con el derivado versionado:
50.450 registros de «Internet fijo / Activo», 125 municipios y 2.502.506 líneas.

### Efecto en las salidas

**Ninguno por sí solo.** El derivado que regenera es el mismo que ya estaba. Lo
que cambia es que el pipeline vuelve a poder correr de cero desde la fuente.

Una diferencia menor: el derivado regenerado tendrá **22 columnas en vez de 23**.
La que falta es `period`, que el `.do` de Stata generaba con `yq(anno, trimestre)`
y que no existe en el archivo de hoy. No la lee nadie.

---

## 18 · `F-5-001` y `F-5-002` — Internet fijo: cuatro trimestres sumados y los paquetes descartados

**Estado:** aplicado · 2026-08-20
**Archivo:** `02_Code/03_tablas/03_ordenamiento.R`, `.hoja_internet()`

*Estos dos hallazgos no estaban en la lista de 17. Aparecieron al abrir el
derivado para preparar la corrección 9.*

### Error 1 — se suman los cuatro trimestres del año

El derivado trae los **cuatro trimestres** de 2025. `.hoja_internet()` filtra por
servicio y por estado, pero **no por trimestre**, y luego suma agrupando solo por
municipio:

```r
crudo <- leer_derivado("infraestructura_internet_2025") |>
  dplyr::filter(.data$servicio_paquete == "Internet fijo",
                .data$estado == "Activo en funcionamiento") |>
  ...
lineas <- crudo |>
  dplyr::group_by(ind_mpio = as.integer(.data$ind_mpio)) |>
  dplyr::summarise(lineas_totales = sum(.data$lineas, na.rm = TRUE), ...)
```

`cantidad_lineas_accesos` es un **stock** —los accesos activos al cierre del
trimestre—, no un flujo. Sumar los cuatro cuenta cuatro veces el mismo acceso.

Comprobado sobre el derivado publicado, Provincia del Río Grande, internet fijo
activo: T1 = 16.431, T2 = 17.109, T3 = 17.154, T4 = 17.505. **Suma = 68.199, que
es exactamente la cifra publicada en la hoja `internet_2025`.**

El factor de inflación no es constante: depende de cuánto creció el parque
durante el año.

### Error 2 — se descartan los accesos empaquetados

`servicio_paquete` tiene siete valores en la fuente, y **cuatro** contienen
internet fijo:

```
Internet fijo
Triple Play (Telefonía fija + Internet fijo + TV por suscripción)
Duo Play 1 (Telefonía fija + Internet fijo)
Duo Play 2 (Internet fijo y TV por suscripción)
```

El código se queda con el primero. La metodología del propio MinTIC cuenta los
empaquetados: *«En caso de proveer servicios empaquetados mediante el uso de dos
o más tecnologías de acceso de última milla, estos accesos serán contabilizados
como uno solo»* (Boletín Trimestral de las TIC, julio de 2025).

Y el filtro **no sesga parejo**. Porcentaje de los accesos que se venden como
«Internet fijo» suelto, cuarto trimestre de 2025:

| Turística | Agroindustrial | Minero | Río Grande | Penderisco | Área Metropolitana |
|---|---|---|---|---|---|
| 95,8 % | 95,4 % | 94,9 % | 91,1 % | 75,9 % | **30,8 %** |

Descarta el 4 % de los accesos de una provincia rural y el **69 %** de los del
Área Metropolitana.

### Los dos vienen heredados del `.do` original

`99_Legacy/codigo/stata_pipeline/tablas_diagnostico/03_Ordenamiento.do`:

```stata
use "$data/infraestructura_internet_2025.dta", clear
keep if servicio_paquete == "Internet fijo"
keep if estado == "Activo en funcionamiento"
...
collapse (sum) cantidad_lineas_accesos, by(ind_mpio fibra)
```

No hay `keep if trimestre`, y el filtro de paquete es idéntico. El migrador a R
reprodujo el `.do` con fidelidad; el defecto es anterior. El propio `.do` deja
además una advertencia sin atender en su cabecera: *«VERIFICAR EN LA 1a CORRIDA
los nombres de columnas del insumo (servicio_paquete, estado, tecnologia,
cantidad_lineas_accesos, area_geo)»*.

### Por qué es grave: la cifra publicada es imposible

| | publicado | corregido |
|---|---|---|
| Antioquia, accesos por 100 habitantes | **36,1** | **25,2** |
| Agua, Bosques y Turismo, por 1.000 hab. | 721,1 | 202,1 |
| Del Río Grande, por 1.000 hab. | 673,7 | 189,8 |
| El Peñol, por 1.000 hab. | **1.046** | 297 |

El MinTIC sitúa a Antioquia en **24 accesos por cada 100 habitantes** en el primer
trimestre de 2025, segunda del país después de Bogotá (29). El informe publica
una cifra que implica 36 —por encima de Bogotá— y municipios como El Peñol con
más líneas de internet que habitantes.

Los dos errores tienen signo contrario y su cociente varía entre **1,07** (Área
Metropolitana) y **3,55** (Río Grande) según la provincia. Esa dispersión es lo
que destruye el ranking.

### Qué se cambió y dónde

**a) Antes de `.hoja_internet()` — lista nueva, 6 líneas más el comentario:**

```r
PAQUETES_CON_INTERNET_FIJO <- c(
  "Internet fijo",
  "Triple Play (Telefonía fija + Internet fijo + TV por suscripción)",
  "Duo Play 1 (Telefonía fija + Internet fijo)",
  "Duo Play 2 (Internet fijo y TV por suscripción)"
)
```

Se escribe la lista completa, y no una búsqueda de texto, para que se vea qué se
está contando.

**b) Al entrar en la función — guarda y elección del trimestre, 16 líneas nuevas:**

```r
fuente <- leer_derivado("infraestructura_internet_2025")

nuevos <- setdiff(
  grep("Internet fijo", unique(fuente$servicio_paquete), value = TRUE),
  PAQUETES_CON_INTERNET_FIJO)
if (length(nuevos)) {
  stop("La fuente trae paquetes con internet fijo que no están en la lista:\n  ",
       paste(nuevos, collapse = "\n  "),
       "\nAgréguelos a PAQUETES_CON_INTERNET_FIJO o el conteo saldrá corto.",
       call. = FALSE)
}

ultimo <- max(a_numero(fuente$trimestre), na.rm = TRUE)
anio   <- max(a_numero(fuente$anno), na.rm = TRUE)
message("  [internet] ", anio, " T", ultimo, ", ",
        length(PAQUETES_CON_INTERNET_FIJO), " paquetes con internet fijo")
```

La guarda es barata y hace que la lista se mantenga sola: si el MinTIC publica un
«Quad Play» con internet fijo, el pipeline se detiene en vez de contar de menos
en silencio.

**c) El filtro — antes / después:**

```r
  crudo <- leer_derivado("infraestructura_internet_2025") |>
    dplyr::filter(.data$servicio_paquete == "Internet fijo",
                  .data$estado == "Activo en funcionamiento") |>
```
```r
  crudo <- fuente |>
    dplyr::filter(a_numero(.data$trimestre) == ultimo,
                  .data$servicio_paquete %in% PAQUETES_CON_INTERNET_FIJO,
                  .data$estado == "Activo en funcionamiento") |>
```

El resto de la función —la suma condicional de fibra, el cruce con población, la
agregación de la corrección 3— **no se toca**.

### Lo que hay que esperar en la próxima corrida

| | antes | después |
|---|---|---|
| **Río Grande**, líneas | 68.199 | **19.217** |
| líneas de fibra | 40.822 | **14.563** |
| proporción de fibra | 59,9 % | **75,8 %** |
| por 1.000 habitantes | 673,7 | **189,8** |
| **Turística**, líneas | 41.205 | **12.165** |
| líneas de fibra | 17.375 | **4.711** |
| proporción de fibra | 42,2 % | **38,7 %** |
| por 1.000 habitantes | 432,8 | **127,8** |

Y en el log, una línea nueva:

```
  [internet] 2025 T4, 4 paquetes con internet fijo
```

*(Las cifras de Turística incluyen ya a Santa Fe de Antioquia, que entra por la
corrección 1.)*

### Efecto en las salidas

Cambia **todo lo que sale de la hoja `internet_2025`**, en las once provincias:

1. Las cuatro columnas de la hoja, municipio por municipio y en la fila provincial.
2. `fig_13_internet_1000hab` — todas las barras. **El municipio del titular cambia
   en 4 de 11 provincias**: Cartama (Venecia → Fredonia), Agua Bosques y Turismo
   (Peñol → Marinilla), Minero (Vegachí → Segovia), Turística (Heliconia → Ebéjico).
3. `fig_14_internet_fibra` — **el titular cambia en 9 de 11**. En el Área
   Metropolitana pasa de «en 8 de 10 municipios la fibra ya es mayoría» a 3 de 10;
   en Turística, de «en ningún municipio» a 1 de 7.
4. La prosa de la sección 03 (bloque `cti` de `secciones.R`): el municipio con más
   y con menos acceso, y la frase de la fibra, que se mueve entre −15,5 pp (Área
   Metropolitana) y +9,9 pp (Río Grande).
5. El comparativo: **nueve de las once provincias cambian de puesto**. El Área
   Metropolitana pasa del noveno lugar al **primero**.

**Lo que NO cambia,** y conviene decirlo: la correlación entre internet fijo y el
IMCA del comparativo pasa de **+0,93 a +0,91**. Esa frase se sostiene sin tocarla.
Y la figura de servicios públicos usa `tot_pob_internet`, que viene de la **ECV**:
es otra fuente y no se toca.

### Una advertencia sobre el método de esta auditoría

`V-4-004` había verificado que las 352 celdas municipales de internet de las once
provincias reproducen exactamente lo que hace el código. Y lo reproducen. Pero
esa verificación reimplementó **el mismo filtro equivocado**, así que confirmó la
aritmética sin tocar la definición. Es la cuarta extensión de la regla de
procedencia —«convergencia no es independencia»— aplicada a la propia auditoría:
comprobar que el código hace lo que dice no comprueba que lo que dice sea correcto.

---

## 10 · `F-2-035` — El mapa departamental de homicidios sale incompleto en diez de los once informes

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/04_figuras/00_mapas.R`, `02_Code/run_all.R`,
`02_Code/run_provincia.R`

### El error

`mapa_10_homicidios_dpto` pinta los homicidios de todo el departamento para que
el lector vea si su provincia es un caso aparte o parte de un patrón regional.
Lo arma leyendo la hoja `delitos` del `.xlsx` de las **once** provincias:

```r
todos <- do.call(rbind, lapply(PROVINCIAS$id, function(i) {
  x <- .hoja_de(provincia(i), "10_Seguridad", "seguridad.xlsx", "delitos")
  if (is.null(x)) NULL else
    x[, c("Código DANE", "Municipio", "Homicidios por 100.000 hab.")]
}))
```

Pero lee de **archivos en disco**, y esos archivos los escribe el propio
pipeline. `run_provincia.R:109-112` llama a `mapas_provincia()` al final de
**cada** provincia:

```r
if (identical(lista, SECCIONES)) {
  source(file.path(RUTAS$codigo, "04_figuras", "00_mapas.R"), encoding = "UTF-8")
  r_mapas <- tryCatch(mapas_provincia(prov), error = function(e) e)
```

Cuando corre la provincia *k*, en disco solo existen las hojas de las provincias
1..*k*. Solo la última obtiene el mapa completo.

### Por qué es grave: la nota afirma lo contrario

```r
nota = paste("Solo se colorean los municipios que pertenecen a alguna",
             "de las once provincias; el resto queda en gris.")
```

Ese texto era fijo. En Bioenergética del Norte el mapa carga 19 municipios, así
que **69 municipios que sí pertenecen a una provincia salen en gris** bajo un
rótulo que le dice al lector que no pertenecen a ninguna. No es un dato ausente:
es una afirmación falsa sobre el territorio.

### La evidencia

Corridas las once desde cero, filas de la hoja `_mapa10_homicidios_dpto`:

**6 · 19 · 24 · 31 · 43 · 54 · 59 · 65 · 70 · 78 · 88**

Cada incremento es exactamente el número de municipios de la provincia que
acababa de correr —6, 13, 5, 7, 12, 11, 5, 6, 5, 8, 10—, los once sin excepción.

Medido sobre las salidas en disco, provincia por provincia:

| Provincia | Municipios en su mapa |
|---|---|
| Agroindustrial de Occidente | **6** de 88 |
| Bioenergética del Norte | 19 |
| Del Río Grande | 24 |
| Turística y Agroecológica | 31 |
| Agua, Bosques y Turismo | 43 |
| Cartama | 54 |
| De la Paz | 59 |
| San Juan | 65 |
| Minero Agroecológica | 70 |
| Penderisco y Sinifaná | 78 |
| Área Metropolitana | **88** |

**Dónde se publica:** `generar_borrador.R:192` recoge todos los PNG de
`03_Outputs/<Provincia>/10_Seguridad/figuras/` por barrido de directorio, así
que el mapa entra en el documento de cada provincia como **figura 68**. Está en
los dos borradores existentes (`Area_Metropolitana` línea 598, `Bioenergetica_Norte`
línea 616). El comparativo **no** lo usa: construye sus propios mapas.

### Y mezcla vigencias sin avisar

En la corrida de muestra del 20 de agosto (`evidencia/16_run_all.txt`):

```
línea 308  Del Río Grande              _mapa10_homicidios_dpto  (88 filas)
línea 569  Turística y Agroecológica   _mapa10_homicidios_dpto  (89 filas)
```

Ninguna es correcta: el universo tras la corrección 1 es **90**. Río Grande sacó
88 leyendo las hojas viejas de las otras nueve —incluida una Turística de 7
municipios y una Minero sin Amalfi—; Turística sacó 89 porque para entonces su
propia hoja ya estaba reescrita.

### Por qué la primera versión no bastaba

La primera corrección movía el mapa a una segunda pasada de `run_all.R`, cuando
ya estuvieran escritas las once hojas. Pablo señaló el agujero: **en una corrida
de muestra el mapa seguiría mal**, porque la segunda pasada leería las hojas
viejas de las provincias que no se corrieron. Regenerar los once no arregla
nada si nueve se arman con datos de otra corrida.

Mientras el mapa lea de `03_Outputs`, su contenido depende de qué hubo en disco.
La única forma de que siempre esté bien es que **no lea de disco**.

### La tensión con la regla 1, y cómo se resuelve

La cabecera de `00_mapas.R` lo prohíbe explícitamente:

> **DE DÓNDE SALEN LAS CIFRAS.** De las hojas .xlsx que ya generó la sección —
> nunca de los derivados ni de los crudos. El mapa pinta EXACTAMENTE lo que dice
> la tabla publicada: **si recalculara, podría discrepar de ella** y el informe
> tendría dos cifras para el mismo hecho.

El riesgo que nombra la regla es real: dos implementaciones de la misma cuenta
terminan separándose. **Pero se puede cumplir el espíritu sin leer de disco:**
en vez de que el mapa reescriba la fórmula, se extrae la fórmula a un solo sitio
y la usan los dos. El mapa no recalcula: **reutiliza**.

En `.hoja_delitos()` ya existía la costura exacta — la variable local `universo`,
que es la tabla de todos los municipios del departamento antes de filtrar por
provincia.

### Qué se cambió y dónde

**a) `02_Code/03_tablas/10_seguridad.R` — dos funciones extraídas, sin cambiar
ninguna cuenta.**

`universo_delitos()` es literalmente el bloque que antes abría `.hoja_delitos()`
y terminaba en la variable local `universo`. `tasas_delitos()` es el `mutate()`
de las cuatro tasas, que antes iba en línea:

```r
COLUMNAS_DELITOS <- c(names(DELITOS), "pob")

universo_delitos <- function() { ...lo que antes era el principio de .hoja_delitos()... }

#' La fórmula vive AQUÍ y en ningún otro sitio. La regla 1 del anexo dice que la
#' figura no recalcula, y su razón es que dos implementaciones de la misma
#' cuenta terminan discrepando. El mapa departamental usa esta misma función, de
#' modo que no puede publicar una cifra distinta de la de la hoja.
tasas_delitos <- function(d) {
  dplyr::mutate(
    d,
    hurtos                  = .data$n_hurtos     / .data$pob * 1e5,
    homicidios              = .data$n_homicidios / .data$pob * 1e5,
    violencia_intrafamiliar = .data$n_violencia  / .data$pob * 1e5,
    delitos_sexuales        = .data$n_sexuales   / .data$pob * 1e5
  )
}
```

Y `.hoja_delitos()` queda así, con el `mutate` en línea sustituido por la
llamada:

```r
.hoja_delitos <- function(prov, archivo) {
  universo <- universo_delitos()

  detalle <- universo |> filtrar_provincia(prov) |> ...

  tabla <- agregar_totales(detalle, universo = universo, prov = prov,
                           columnas = COLUMNAS_DELITOS, como = "suma") |>
    .rotular_agregados(prov, subreg_dom) |>
    tasas_delitos() |>
    .ordenar_filas(.data$municipio) |>
    ...
```

**b) `02_Code/04_figuras/00_mapas.R` — el mapa deja de leer las once hojas.**

Antes:

```r
todos <- do.call(rbind, lapply(PROVINCIAS$id, function(i) {
  x <- .hoja_de(provincia(i), "10_Seguridad", "seguridad.xlsx", "delitos")
  if (is.null(x)) NULL else
    x[, c("Código DANE", "Municipio", "Homicidios por 100.000 hab.")]
}))
```

Después:

```r
  # Se colorean los municipios que pertenecen a algún esquema asociativo; el
  # resto del departamento queda en gris, que es el criterio con el que se
  # publicó. id_provincia viene de con_territorio(), o sea del crosswalk: el
  # universo no está escrito a mano en ningún lado.
  todos <- universo_delitos() |>
    dplyr::filter(!is.na(.data$id_provincia)) |>
    tasas_delitos() |>
    dplyr::transmute(
      `Código DANE`                 = .data$ind_mpio,
      Municipio                     = .data$municipio,
      `Homicidios por 100.000 hab.` = .data$homicidios
    )
```

El bloque se sacó de `mapas_provincia()` a una función propia,
`mapa_departamental_homicidios()`, para poder documentar por qué es la excepción;
`mapas_provincia()` la llama en el mismo punto donde estaba el bloque.

**c) La nota deja de ser un texto fijo y escribe la cobertura real:**

```r
      nota = paste("Solo se colorean los municipios que pertenecen a alguna",
                   "de las once provincias; el resto queda en gris.")
```
```r
      nota = sprintf(paste("Se colorean los %s municipios que pertenecen a alguna",
                           "de las once provincias; el resto queda en gris."),
                     num_co(cargados, 0))
```

**d) La cabecera de `00_mapas.R` declara la excepción** en el bloque «DE DÓNDE
SALEN LAS CIFRAS», para que nadie la lea como una violación silenciosa de la
regla 1. **e)** Cuatro líneas de comentario equivalentes en `run_provincia.R`.

**`run_all.R` no se toca.** La segunda pasada que se había añadido en la primera
versión se retiró: una vez quitada la dependencia del disco, ya no hace falta.

### Cómo se comprobó que la cifra no cambia

Se recalculó `total_2025 / población × 100.000` desde `seguridad_policia.parquet`
y `poblacion_total_2025.parquet` —los dos derivados de la máquina de Pablo— y se
comparó contra las **88 celdas municipales** de la columna «Homicidios por
100.000 hab.» de las once hojas `delitos` publicadas:

```
municipios con homicidios 2025 en el derivado:  125
celdas municipales comparadas:                   88
diferencia máxima:                                0.000000000
```

Exacto en las 88. El mapa dibuja lo mismo que la tabla, por construcción y ahora
también medido.

### Lo que hay que esperar en la próxima corrida

Los mapas de las provincias corridas pasan a tener **90 filas** —el universo del
crosswalk— en vez de las 88, 89 o menos que tenían. En el log no aparece ninguna
línea nueva salvo que el derivado de policía no cubra el universo, en cuyo caso
avisa.

Las provincias que **no** se corran conservan su mapa viejo en disco, con menos
filas. Solo se arreglan al correrlas.

### Efecto en las salidas

Cambia la **figura 68** de los informes de las provincias que se corran, y la
hoja `_mapa10_homicidios_dpto`. Ninguna cifra de ninguna tabla cambia: las
funciones extraídas son las mismas líneas de antes, y la comparación contra las
88 celdas publicadas da diferencia cero.

### El problema de las vigencias, resuelto de paso

La versión anterior del mapa podía mezclar datos de corridas distintas sin
avisar, y eso pasó en la corrida del 20 de agosto. Al calcular desde el derivado
ya no puede: el mapa siempre refleja el estado actual de los datos, no el de los
archivos que hubiera en `03_Outputs`.

Queda una decisión editorial anotada, no un defecto: se colorean los **90**
municipios del sistema provincial y los 35 restantes van en gris, que es el
criterio con el que se publicó. El derivado trae los 125, así que colorear el
departamento entero es posible si algún día se quiere.

---

## 11 y 12 · `F-1-006` y `F-2-050` — Rutas de otra máquina, y éxito anunciado sin entregable

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/05_documento/generar_borrador.R`,
`02_Code/06_comparativo/generar_comparativo.R`

Van juntas porque **corregir la 11 sola volvería silencioso un fallo que hoy es
ruidoso.** Está medido más abajo.

### 11 · El error

Cada figura del Markdown se escribe con la ruta **absoluta** del disco donde se
generó el documento:

```markdown
![68. Homicidios departamento](/Users/jcmunoz/github_repositories/Proyecto-Provincias/03_Outputs/Bioenergetica_Norte/10_Seguridad/figuras/mapa_10_homicidios_dpto.png)
```

En cualquier otra máquina esa ruta no existe.

**La evidencia en el código** — `generar_borrador.R:176-183`:

```r
.figura <- function(ruta, titulo, fuente_txt = NULL) {
  if (!file.exists(ruta)) return(character(0))
  .contador$fig <- (.contador$fig %||% 0) + 1
  c(sprintf("![%s. %s](%s)", .contador$fig, titulo, ruta),
```

`ruta` llega desde `RUTAS$outputs`, que es absoluta. **El código está limpio**:
la ruta no está escrita a mano, sale de `PROJ_ROOT` autodetectado. Lo que está
contaminado es el entregable versionado. Y `generar_comparativo.R:31` hace
`source()` de este archivo y usa la misma `.figura()`, así que el defecto es uno
solo con doce víctimas.

**Magnitud, contada sobre los archivos del repositorio:**

```
74  04_Docs/borradores/Area_Metropolitana/Area_Metropolitana_diagnostico.md
74  04_Docs/borradores/Bioenergetica_Norte/Bioenergetica_Norte_diagnostico.md
11  04_Docs/comparativo/Comparativo_provincias.md
```

74 × 11 + 11 = **825 referencias**.

**El autor ya intentó protegerse**, y ahí está la parte instructiva. Los dos
generadores pasan:

```r
# Las rutas de las imágenes son absolutas, pero se declara la raíz
# por si el borrador se regenera desde otro directorio.
"--resource-path", shQuote(RUTAS$raiz))
```

**`--resource-path` es inerte con rutas absolutas.** Pandoc solo lo aplica a
rutas relativas. El comentario describe una protección que no protege.

### Una corrección a la ficha de auditoría

`F-1-006` afirmaba que *«pandoc no encuentra ninguna imagen, emite warnings y
produce el .docx igual»*. **Medido, es falso** en pandoc 3.1.3:

| Caso | estado | ¿.docx? | imágenes |
|---|---|---|---|
| Ruta absoluta inexistente | **1** | **no se crea** | — |
| Ruta absoluta existente (la máquina del autor) | 0 | sí | 1 |
| Ruta relativa + `--resource-path` correcto | 0 | sí | 1 |
| **Ruta relativa no encontrable** | **0** | sí | **0** |

```
pandoc: /Users/jcmunoz/.../fig.png: withBinaryFile: does not exist
```

Con rutas absolutas pandoc **aborta**; no avisa. El efecto real no era «doce
documentos sin figuras» sino **doce documentos que no se pueden producir** en
ninguna máquina ajena — salvo que hubiera un `.docx` viejo en disco, que es
exactamente el hallazgo 12.

La última fila es la que ordena las dos correcciones: con rutas **relativas** no
encontrables, pandoc sale con estado **0** y entrega un `.docx` sin figuras.

### 11 · Qué se cambió y dónde

`generar_borrador.R`, antes de `.figura()` — **función nueva, 10 líneas**:

```r
#' La ruta de la imagen, relativa a la raíz del proyecto.
#'
#' Escrita en absoluto, la referencia solo funciona en la máquina que generó el
#' documento: eran ~825 rutas /Users/... en los doce entregables. Y el
#' --resource-path que ya se pasa no lo arreglaba, porque pandoc solo lo aplica
#' a rutas RELATIVAS; con absolutas es inerte y pandoc aborta sin escribir nada.
#' Emitiéndolas relativas, ese --resource-path empieza a hacer su trabajo.
.ruta_relativa <- function(ruta) {
  sub(paste0(RUTAS$raiz, "/"), "", ruta, fixed = TRUE)
}
```

Y la línea que emite la referencia — **antes / después**:

```r
  c(sprintf("![%s. %s](%s)", .contador$fig, titulo, ruta),
```
```r
  # Entre <> por si la ruta trae espacios: es la forma que CommonMark define
  # para destinos de enlace y pandoc la entiende.
  c(sprintf("![%s. %s](<%s>)", .contador$fig, titulo, .ruta_relativa(ruta)),
```

Más el comentario del `--resource-path` en los **dos** generadores, que ahora
describe lo que de verdad hace:

```r
            # Las rutas de las imágenes son relativas a la raíz, así que este
            # --resource-path es lo que permite resolverlas desde donde sea.
```

**Una sola función tocada arregla los 825 casos**, porque el comparativo la
hereda por el `source()` que ya hacía.

### 12 · El error

Tres mecanismos encadenados.

**(a) Sin pandoc, termina en éxito** (`generar_borrador.R:520`):

```r
if (!.hay_pandoc()) {
  message("  [borrador] ", prov$etiqueta, " — solo Markdown (falta pandoc)")
  return(invisible(md))
}
```

`message()`, no `warning()` ni `stop()`. `Rscript` sale con código 0 habiendo
producido once `.md` y cero `.docx`. Es el estado real del repositorio hoy.

**(b) Publica el `.docx` viejo como recién hecho** (líneas 537-546):

```r
salida <- suppressWarnings(system2("pandoc", args, stdout = TRUE, stderr = TRUE))
if (!file.exists(docx)) { ... FALLÓ ... }
message("  [borrador] ", prov$etiqueta, " -> ", basename(docx), "  (",
        format(structure(file.size(docx), ...)))
```

No se borra el `.docx` anterior y el éxito se comprueba solo con
`file.exists()`. Si pandoc falla, el archivo viejo sigue ahí y **el script
imprime la línea de éxito con el tamaño del archivo viejo**. Es una inversión de
la regla 0 del anexo, «el dato manda sobre el informe».

El patrón correcto ya está en este mismo archivo, línea 150:
`if (file.exists(PLANTILLA)) unlink(PLANTILLA)`.

**(c) No se mira el estado ni el tamaño.** `attr(salida, "status")` nunca se
consulta. Y el estado tampoco basta: en el caso de la figura no encontrada
pandoc sale con 0.

### 12 · Qué se cambió y dónde

**a) `generar_borrador.R`, tras `.hay_pandoc()` — función nueva, 22 líneas:**

```r
#' Por qué NO sirve el .docx que pandoc acaba de intentar producir.
#'
#' Devuelve character(0) si está bien, o el motivo. Son tres cosas que
#' file.exists() no ve:
#'   - pandoc devolvió error;
#'   - el archivo quedó vacío;
#'   - pandoc terminó BIEN pero no encontró alguna imagen y la sustituyó por su
#'     descripción. Ese caso sale con estado 0 y produce un .docx sin ninguna
#'     figura; es el único modo de fallo que queda vivo al emitir las rutas en
#'     relativo, y el estado de salida no lo delata.
#'
#' La usan este generador y el del comparativo, que comparten el bloque.
.falla_pandoc <- function(salida, docx) {
  estado <- attr(salida, "status") %||% 0L
  if (estado != 0L)         return(sprintf("pandoc devolvió %d", estado))
  if (!file.exists(docx))   return("no se creó el archivo")
  if (file.size(docx) == 0) return("el archivo quedó vacío")
  perdidas <- grep("Could not fetch resource", salida, value = TRUE)
  if (length(perdidas))
    return(sprintf("%d imagen(es) no se encontraron: el .docx saldría sin ellas",
                   length(perdidas)))
  character(0)
}
```

**b) El bloque de conversión, en los dos generadores — antes:**

```r
  salida <- suppressWarnings(system2("pandoc", args, stdout = TRUE, stderr = TRUE))
  if (!file.exists(docx)) {
    message("  [borrador] ", prov$etiqueta, " — FALLÓ pandoc:\n    ",
            paste(utils::head(salida, 5), collapse = "\n    "))
    return(invisible(md))
  }
```

**Después:**

```r
  # pandoc no escribe nada si falla: sin este unlink, el .docx de una corrida
  # anterior pasaría la comprobación y se anunciaría como recién hecho.
  unlink(docx)
  salida <- suppressWarnings(system2("pandoc", args, stdout = TRUE, stderr = TRUE))
  mal <- .falla_pandoc(salida, docx)
  if (length(mal)) {
    unlink(docx)   # que el disco no contradiga al log
    message("  [borrador] ", prov$etiqueta, " — FALLÓ pandoc: ", mal, "\n    ",
            paste(utils::head(salida, 5), collapse = "\n    "))
    return(invisible(md))
  }
```

**c) Tres avisos que hoy se pierden entre el log pasan a `warning()`:**

| Archivo | Antes | Después |
|---|---|---|
| `generar_borrador.R` | `message("  pandoc no está instalado…")` | `warning("pandoc no está instalado: … ningún .docx.")` |
| `generar_borrador.R` | `message("  [plantilla] No está el Anexo 1…")` | `warning("No está el Anexo 1: los .docx saldrán sin el estilo Table…")` |
| `generar_comparativo.R` | `message("  [comparativo] solo Markdown…")` | `warning("pandoc no está instalado: el comparativo queda solo en Markdown.")` |

**Lo que NO se hizo:** `generar_borradores()` sigue devolviendo lo mismo y la
invocación por CLI sigue saliendo con 0. Se descartó porque hoy es legítimo
correr el script sin pandoc para regenerar solo los Markdown, y hacerlo fallar
convertiría un uso válido en un error aparente. El `quit(status = 1)` es una
línea el día que haya integración continua.

### Cómo se comprobó antes de entregarlo

Sintaxis validada con `parse()` en los dos archivos; CRLF conservados.

Y una prueba de extremo a extremo con **las funciones reales del pipeline**
—cargadas del propio `generar_borrador.R`— sobre un árbol de proyecto de
mentira, con pandoc de verdad y **desde un directorio de trabajo distinto**
(`/`), que es la condición que hacía fallar el original:

```
1) ruta emitida:
    03_Outputs/Rio_Grande/09_Salud/figuras/fig_03.png
2) línea Markdown:
    ![1. Enfermedades por vectores](<03_Outputs/Rio_Grande/09_Salud/figuras/fig_03.png>)
3) conversión (cwd = / ):
   resource-path = raiz (lo que hace)  -> OK                       imagenes=1
   resource-path mal puesto            -> FALLA: 1 imagen(es) no    imagenes=0
                                          se encontraron
4) el .docx viejo ya no puede colarse:
   tras unlink + fallo de figura: FALLA detectada
```

La segunda línea del punto 3 es la importante: **ese es el caso que antes salía
con estado 0 y nadie miraba.**

### Efecto en las salidas

Los doce documentos dejan de llevar rutas de otra máquina. El `.md`, que es el
artefacto **versionado**, pasa a ser idéntico byte a byte entre máquinas: hoy
dos corridas del mismo commit sobre los mismos datos producen `.md` distintos.

Y el `.docx` deja de poder anunciarse sin existir.

**No cambia ninguna cifra.** Solo las referencias de imagen y el control de
errores.

### Dos límites conocidos

1. **El `.md` sigue sin mostrar figuras en GitHub.** Las rutas son relativas a
   la raíz del proyecto, no al archivo, y GitHub las resuelve desde la ubicación
   del `.md`. Emitirlas relativas al propio documento lo arreglaría, pero exige
   calcular el salto (`../../../`) y cambiar el `--resource-path` de los dos
   generadores. Se eligió la opción mínima, que es la que el autor dejó a medias.
2. **La versión de pandoc importa.** Todo lo medido aquí es con **pandoc 3.1.3**.
   Versiones 2.x pueden avisar en vez de abortar ante una ruta absoluta
   inexistente. Las cuatro guardas cubren los dos comportamientos, pero conviene
   anotar con qué versión se generan los entregables.

---

## 13 · `F-1-010` — Los mapas se degradan en silencio sin `ggrepel`

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/R/03_mapas.R`, `02_Code/run_provincia.R`,
`02_Code/06_comparativo/figuras_comparativas.R`

### El error

`ggrepel` separa las etiquetas de municipio y les pone un halo del color del
fondo. Era dependencia opcional: sin ella el código caía a `geom_text()` en el
centroide, sin halo ni separación, **y no avisaba**.

### La evidencia en el código

`R/03_mapas.R:121-143`:

```r
HAY_REPEL <- requireNamespace("ggrepel", quietly = TRUE)

.capa_etiquetas <- function(et, color = COLOR$tinta_1, halo = TRUE) {
  if (HAY_REPEL) {
    ggrepel::geom_text_repel(..., bg.color = if (halo) COLOR$superficie else NA, ...)
  } else {
    ggplot2::geom_text(data = et, mapping = aes_txt,
      size = PT$fuente / .pt, family = FUENTE, color = color)   # sin aviso
  }
}
```

Treinta líneas antes, `sf` sí avisa al cargar y se reporta como
`OMITIDO — falta el paquete sf` en el resumen de la corrida. Dos dependencias
del mismo módulo, dos comportamientos distintos ante la misma ausencia.

### El proyecto ya había decidido esto, y lo escribió dos veces

`04_figuras/DISENO.md`, línea 237:

> `sf` y `ggrepel` son dependencias **opcionales**: sin ellas el pipeline genera
> todo lo demás **y omite los mapas con un aviso**.

`R/00_config.R`, línea 162:

> Los mapas no son obligatorios: **sin estos dos paquetes** el pipeline genera
> todas las tablas y todas las figuras no cartográficas, **y omite los mapas con
> un aviso**.
> ```r
> PAQUETES_MAPAS <- c("sf", "ggrepel")
> ```

Los dos textos dicen lo mismo. `03_mapas.R` aplicaba esa regla solo a `sf`.

Y el propio comentario de `00_config.R` justifica la opcionalidad por una razón
que **no aplica a `ggrepel`**:

> Se declaran aparte para que un clon sin `sf` —**que necesita GDAL, GEOS y PROJ
> en el sistema**— no quede bloqueado.

`ggrepel` es R puro, sin dependencias de sistema.

### Lo que estaba produciendo

Inspección directa de
`03_Outputs/Bioenergetica_Norte/02_Demografia/figuras/mapa_02_densidad.png`
(corrida del 2026-08-15):

- **«Angostura» y «Guadalupe» encabalgadas**, una sobre otra.
- **«Yarumal» y «Campamento»** en tinta casi negra sobre el azul más oscuro de
  la rampa, apenas legibles.
- **«San Andrés de Cuerquía», «San José de la Montaña» y «Valdivia»** desbordan
  su polígono sobre el vecino.
- **Ninguna etiqueta lleva halo.**

Son **110 mapas** —diez por provincia— y el resumen de cada corrida dice
`Mapas  OK`.

### Qué se cambió y dónde

**a) `R/03_mapas.R`, líneas 25-32 — el guarda.** La lista de paquetes deja de
estar escrita aquí y pasa a ser la que `00_config.R` ya declaraba:

```r
# `sf` es la única dependencia que añade este módulo. Se carga solo si está: un
# clon sin sf debe seguir generando tablas y figuras no cartográficas.
HAY_CARTOGRAFIA <- requireNamespace("sf", quietly = TRUE)

if (!HAY_CARTOGRAFIA) {
  message("[mapas] El paquete 'sf' no está instalado: los mapas se omitirán. ",
          "Instálelo con  install.packages(\"sf\")  para generarlos.")
}
```

```r
# Los dos paquetes que añade este módulo. Se cargan solo si están: un clon sin
# ellos debe seguir generando tablas y figuras no cartográficas.
#
# La lista NO se escribe aquí: es PAQUETES_MAPAS, que 00_config.R ya declara
# como «sin estos dos paquetes el pipeline (...) omite los mapas con un aviso».
# Antes solo se comprobaba `sf`, y sin `ggrepel` el mapa se generaba igual, sin
# separar las etiquetas ni ponerles halo, y sin decir nada: en Bioenergética del
# Norte «Angostura» y «Guadalupe» salían una encima de otra. DISENO.md §5 exige
# las dos cosas y declara esta misma condición de omisión.
FALTAN_MAPAS <- PAQUETES_MAPAS[
  !vapply(PAQUETES_MAPAS, requireNamespace, logical(1), quietly = TRUE)]
HAY_CARTOGRAFIA <- length(FALTAN_MAPAS) == 0L

if (!HAY_CARTOGRAFIA) {
  message("[mapas] Falta ", paste(FALTAN_MAPAS, collapse = " y "),
          ": los mapas se omitirán. Instálelo(s) con\n",
          "        install.packages(c(\"", paste(FALTAN_MAPAS, collapse = "\", \""),
          "\"))")
}
```

**b) `.capa_etiquetas()` pierde la rama alternativa.** Con el guarda de arriba,
`ggrepel` está garantizado cuando se dibuja un mapa: la rama `geom_text()` era
inalcanzable y era justamente el camino silencioso. **Se elimina el `if/else`**;
la función queda con la llamada a `ggrepel::geom_text_repel()` y nada más. La
degradación desaparece por construcción, no por un guarda que alguien pueda
saltarse.

**c) `run_provincia.R:121` — el resumen nombra lo que falta:**

```r
                else if (is.null(r_mapas)) "falta el paquete sf"
```
```r
                else if (is.null(r_mapas))
                  paste("falta", paste(FALTAN_MAPAS, collapse = " y "))
```

**d) Un segundo sitio con el mismo defecto, que la ficha no registraba.**
`06_comparativo/figuras_comparativas.R:225` usa el mismo patrón para los
diagramas de dispersión del comparativo. **No son mapas**, así que omitirlos no
estaba sobre la mesa; se les quita el silencio:

```r
  } else {
+   # Sin ggrepel las once etiquetas se montan unas sobre otras. Aquí no se
+   # omite la figura —no es un mapa—, pero tampoco se degrada en silencio.
+   warning("Falta ggrepel: las etiquetas de '", titulo,
+           "' van en el punto y pueden superponerse.", call. = FALSE)
    ggplot2::geom_text(ggplot2::aes(label = provincia), ...)
  }
```

Y `HAY_REPEL` sobrevive **solo** para ese caso, derivado del mismo cálculo:

```r
HAY_REPEL <- !("ggrepel" %in% FALTAN_MAPAS)
```

### Cómo se comprobó antes de entregarlo

Sintaxis validada con `parse()` en los tres archivos; CRLF conservados. El
guarda se ejecutó en R, en un entorno sin ninguno de los dos paquetes:

```
[mapas] Falta sf y ggrepel: los mapas se omitirán. Instálelo(s) con
        install.packages(c("sf", "ggrepel"))
HAY_CARTOGRAFIA: FALSE | HAY_REPEL: FALSE
detalle del resumen: falta sf y ggrepel
```

**Lo que NO se pudo comprobar aquí:** el resultado gráfico. Este contenedor no
tiene `ggplot2` ni `ggrepel`, así que no se renderizó ningún mapa. Que las
etiquetas queden separadas y con halo solo se confirma abriendo el PNG.

### ⚠️ Antes de la próxima corrida

**Hay que instalar `ggrepel`, o no habrá ningún mapa.**

```r
install.packages("ggrepel")
```

No tiene dependencias de sistema; es cuestión de segundos. Si se corre sin él,
el log dirá `[mapas] Falta ggrepel: los mapas se omitirán` y el resumen de cada
provincia dirá `Mapas  OMITIDO  falta ggrepel` — que es el comportamiento
correcto, pero deja los once informes sin cartografía.

Con `ggrepel` instalado, **los 110 mapas se regeneran con las etiquetas
separadas y con halo**, que es el efecto real de esta corrección: no solo dejar
de callar, sino arreglar las figuras.

### Un defecto vecino que esta corrección NO resuelve

El color del texto de las etiquetas es fijo —`COLOR$tinta_1`, casi negro— para
toda la rampa, y el halo declarado tiene radio `bg.r = 0.12`. DISENO.md promete
que el nombre «se lea sobre cualquier tono de la rampa». Sobre el azul más
oscuro puede no bastar ni con halo.

El propio proyecto tiene la solución escrita en
`04_figuras/06_desarrollo_rural.R` (`.luminancia()` / `.color_legible()`), que
elige blanco o tinta según el fondo, y no se usa en los mapas. **No se tocó**
porque es un cambio visual que aquí no se puede renderizar ni comprobar. Queda
como pendiente, y se decide mirando los mapas ya regenerados con `ggrepel`.

---

## 14 · `F-2-064` — El anexo se rellena con la última corrida, sea cual sea

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/99_checks/generar_tablas_anexo.R`,
`04_Docs/anexo_metodologico.tex`

### El error

`generar_tablas_anexo.R` produce las macros que el anexo cita **contando filas**
de los CSV que dejó la auditoría:

```r
macros$cifraAgregados <- .n(nrow(prov_rows))
macros$cifraFiguras   <- .n(nrow(fig))
macros$cifraMapas     <- .n(sum(fig$tipo == "Mapa"))
```

Esos CSV cubren las provincias que hayan corrido. En ninguna parte del script se
contaba cuántas son.

### Por qué no es teórico

`auditoria_end_to_end.R:786` acepta ids, igual que `run_all.R`:

```r
auditar_todo(if (length(.cli)) as.integer(.cli) else PROVINCIAS$id)
```

La auditoría parcial **es un modo de uso previsto**, y el generador del anexo no
tenía forma de saber que lo fue.

### La evidencia está dentro del propio archivo

Línea 560, tabla T8 — el autor **sí** dividió por las provincias presentes:

```r
figuras = sum(g$tipo == "Figura") / length(unique(g$provincia)),
mapas   = sum(g$tipo == "Mapa")   / length(unique(g$provincia)),
```

Línea 573, doce líneas después — la macro **no**:

```r
macros$cifraFiguras <- .n(nrow(fig))
```

Identificó la necesidad en la tabla y se le pasó en la macro, en el mismo bloque
y sobre la misma variable.

Y la nota de la tabla T4, línea 494, llevaba una afirmación fija junto a un
número que no lo era:

> «Verificación sobre las filas de total PROVINCIAL de todas las hojas de **las
> once provincias**.»

### Por qué importa

El anexo es el documento que describe el flujo ante terceros, y la promesa está
escrita en la cabecera del propio script:

> El anexo de 04_Docs **no lleva ninguna cifra escrita a mano**. (…) Si el
> pipeline cambia, se vuelve a correr esto y el anexo queda al día.

Es la tercera aparición del mismo patrón —`F-2-035` en el mapa departamental,
`F-2-054` en el comparativo— y la más grave, porque aquí el número se convierte
en una afirmación del documento metodológico.

### Qué se cambió y dónde

**Decisión tomada:** no abortar. Se emite la cobertura real como macro y el
anexo la cita donde antes decía «las once».

**a) `generar_tablas_anexo.R`, junto a `.csv()` — helper de 6 líneas:**

```r
#' Las provincias que aparecen en un CSV de la auditoría.
.provincias_en <- function(d) {
  if (!"provincia" %in% names(d)) return(character(0))
  p <- d$provincia
  unique(p[!is.na(p) & nzchar(p)])
}
```

**b) Al principio de `generar()` — 28 líneas nuevas.** Tres CSV llevan columna
`provincia`: `C1_cobertura_municipal`, `D1_agregados` y `F1_figuras`.

```r
  agr <- .csv("D1_agregados.csv")
  cob <- .csv("C1_cobertura_municipal.csv")
  fig <- .csv("F1_figuras.csv")
  provincias_auditadas <- sort(unique(unlist(
    lapply(list(agr, cob, fig), .provincias_en))))
  n_auditadas <- length(provincias_auditadas)
  macros$cifraProvinciasCorridas <- .n(n_auditadas)
  if (n_auditadas < nrow(PROVINCIAS)) {
    warning("El anexo se está generando con ", n_auditadas, " de las ",
            nrow(PROVINCIAS), " provincias. Faltan: ",
            paste(setdiff(PROVINCIAS$etiqueta, provincias_auditadas),
                  collapse = ", "),
            ". Sus cifras son de esas ", n_auditadas,
            " provincias, no del sistema completo.", call. = FALSE)
  } else {
    message("  cobertura: las ", n_auditadas, " provincias")
  }
```

El contraste es contra `PROVINCIAS`, no contra un «11» escrito a mano: mismo
principio que la corrección 2.

**Se leen al principio y no en cada tabla** por dos razones: para que la macro
exista antes de escribir el primer fragmento, y porque el script va escribiendo
los `.tex` sobre la marcha —conocer la cobertura a mitad no serviría de nada.

**c) Las tres lecturas duplicadas se retiran** de las líneas 473, 535 y 556: los
mismos CSV ya no se leen dos veces.

**d) La nota de T4 deja de decir «once» — antes / después:**

```r
    nota = paste("Verificación sobre las filas de total PROVINCIAL de todas las",
                 "hojas de las once provincias. «Otro ponderador» reúne los casos",
```
```r
    nota = paste(
      sprintf(paste("Verificación sobre las filas de total PROVINCIAL de todas",
                    "las hojas de las %d provincias auditadas."), n_auditadas),
      "«Otro ponderador» reúne los casos en que el pipeline pondera por",
```

**e) `04_Docs/anexo_metodologico.tex`, dos líneas.** Es la primera corrección de
esta fase que toca el documento, y va porque la opción elegida lo exige.

Línea 695, que es una afirmación de **cobertura**:

```latex
La auditoría recomputa cada fila de total provincial —\cifraAgregados{} celdas
en las once provincias— y comprueba con qué fórmula se reproduce.
```
```latex
La auditoría recomputa cada fila de total provincial —\cifraAgregados{} celdas
en las \cifraProvinciasCorridas{} provincias auditadas— y comprueba con qué
fórmula se reproduce.
```

Línea 79, que es un hecho **estructural** —la tabla T1 se arma de `PROVINCIAS` y
siempre está completa—, así que ahí la macro correcta es la otra:

```latex
\caption{Las once provincias y su composición municipal}
```
```latex
\caption{Las \cifraProvincias{} provincias y su composición municipal}
```

### Una precisión sobre la decisión

Se preguntó si la nota de T4 debía derivar de `PROVINCIAS`. **Deriva del número
auditado, no de `PROVINCIAS`**, y la razón es la otra decisión: si el anexo puede
generarse desde una auditoría parcial, una nota que dijera «las 11 provincias»
mientras `\cifraAgregados` trae las cifras de dos volvería a mentir, solo que con
una interpolación en vez de un literal. Las dos decisiones juntas obligan a que
toda afirmación de cobertura salga del recuento real.

Donde el número **sí** es estructural —la tabla T1— se usa `\cifraProvincias`,
que viene de `nrow(PROVINCIAS)`.

### Las otras cinco menciones de «once» en el anexo, que NO se tocaron

| Línea | Texto | Por qué se deja |
|---|---|---|
| 765 | «el flujo produce los textos: once» | Estructural: once borradores, uno por provincia |
| 779 | «Comparativo de las once… Lee las once» | Es el territorio de `F-2-054`, corrección 15 |
| 821 | «prosa de los once documentos» | `auditoria_redaccion.R` recorre `PROVINCIAS$id` sin ids de CLI: su cobertura no la gobierna esta macro |
| 848 | comentario en un bloque de código | Estructural |
| 976 | título de un hallazgo | Narrativo |

### Cómo se comprobó antes de entregarlo

`parse()` sobre el script y CRLF conservados en los dos archivos. Y **el LaTeX se
compiló**: se añadió `\cifraProvinciasCorridas` a `cifras.tex` y se compiló un
documento mínimo con las dos frases editadas.

```
exit=0    errores de LaTeX: 0

  Las 11 provincias y su composición municipal
  La auditoría recomputa cada fila de total provincial —7.730 celdas en las 11
  provincias auditadas— y comprueba con qué fórmula se reproduce.
```

**Lo que no se pudo compilar es el anexo entero**: requiere los fragmentos
`tablas/T1…T11.tex`, que no están en esta copia porque los produce el propio
script. La compilación completa hay que hacerla tras regenerarlos.

### Lo que NO se tocó, a propósito

T5, T7, la redacción y el panel están envueltos en `if (file.exists(...))`, así
que si el CSV no está la macro no se define. **Es un fallo ruidoso**: LaTeX no
compila con una macro sin definir. Se deja como está.

### ⚠️ Un aviso sobre `cifras.tex`

El archivo actual está desactualizado respecto de las correcciones ya aplicadas:

```latex
\newcommand{\cifraMunicipios}{88}     % son 90 desde la corrección 1
\newcommand{\cifraFiguras}{814}
```

Se pone al día solo, pero **solo tras una corrida completa** seguida de
`auditoria_end_to_end.R` y de este script. Hasta entonces el anexo publica 88
municipios.

---

## 15 · `F-2-054` — El comparativo se construye con lo que haya y se publica como «las once»

**Estado:** aplicado · 2026-08-20
**Archivo:** `02_Code/06_comparativo/panel_provincial.R`

### El error

`construir_panel()` recorre el **catálogo** de provincias, no lo que hay en disco:

```r
filas <- lapply(PROVINCIAS$id, function(id) {
  prov <- provincia(id)
  vals <- vapply(INDICADORES, function(ind) .valor_provincial(prov, ind), numeric(1))
```

Y `.valor_provincial()` devuelve `NA_real_` en silencio cuando la hoja no está:

```r
d <- hoja_publicada(prov, ind$seccion, ind$archivo, ind$hoja)
if (is.null(d) || !ind$columna %in% names(d)) return(NA_real_)
```

**El único conteo del proceso mide el catálogo, no los datos:**

```r
message("  ", nrow(panel), " provincias x ", length(INDICADORES), " indicadores")
```

`nrow(panel)` es siempre 11, porque `panel` se arma de `PROVINCIAS`. Con una sola
provincia en disco, el proceso sigue anunciando «11 provincias x 34 indicadores».

**Y los rótulos declaran un universo que puede no existir**
(`figuras_comparativas.R:184` y `:197`):

```r
breaks = c(1, 6, 11), labels = c("1.º (mejor)", "6.º", "11.º (peor)")) +
```
```r
subtitulo = paste("Puesto de cada provincia entre las once, indicador por", ...)
```

Con cuatro provincias presentes, los puestos van de 1 a 4 **bajo una leyenda que
anuncia un puesto 11 que no existe**. Es el mismo defecto que `F-2-035` en el
mapa departamental.

Y nada garantiza que las once hayan corrido: `run_all.R` **no incluye la etapa
comparativa**, y declara el estado parcial como normal — *«Una etapa que falle
por un insumo ausente no detiene el resto»*.

### Por qué se aborta aquí y en el anexo no

El anexo es un documento **metodológico**: describe el flujo, y un estado parcial
es describible, así que la corrección 14 emite la cobertura real y sigue. El
comparativo **es** la comparación de las once: uno parcial no es una versión
reducida, es otro documento que dice lo que no es.

Tres razones más, todas prácticas:

1. **Los rótulos se vuelven ciertos sin tocar una sola frase.** Misma mecánica
   que la corrección 10 con la nota del mapa. Propagar el número exigiría
   reescribir unas treinta frases en los tres archivos del comparativo, que es
   territorio de la corrección 5.
2. **Ya fallaba, solo que tarde y sucio.** Con pocas provincias
   `cor(use = "complete.obs")` revienta a mitad, cuando el panel `.csv` y `.xlsx`
   ya se reescribieron con provincias vacías, junto a un
   `Comparativo_provincias.md` de la corrida anterior que ya no los respalda.
3. **Por dónde va el guarda, ese escenario desaparece.** `construir_panel()` es
   lo primero que corre:
   ```r
   panel <- construir_panel()      # <- el guarda va aquí
   guardar_panel(panel)
   generar_figuras_comparativas(panel)
   writeLines(markdown_comparativo(panel), md, useBytes = TRUE)
   ```
   Abortando ahí **no se sobrescribe nada**. La propuesta registrada incluía
   escribir el `.md` a un temporal con `file.rename()`; con el guarda en este
   punto esa parte deja de hacer falta y no se hizo.

### Qué se cambió y dónde

**a) Guarda al cerrar `construir_panel()` — 26 líneas nuevas** justo antes del
`message()` final:

```r
  cols_ind <- vapply(INDICADORES, function(i) i$id, character(1))
  medidos <- rowSums(!is.na(panel[, cols_ind, drop = FALSE]))
  vacias <- panel$provincia[medidos == 0]
  if (length(vacias)) {
    stop("El comparativo necesita las ", nrow(PROVINCIAS), " provincias y ",
         length(vacias), " no tienen salidas en 03_Outputs: ",
         paste(vacias, collapse = ", "), ".\n",
         "  Corra antes:  Rscript 02_Code/run_all.R", call. = FALSE)
  }

  huecos <- panel$provincia[medidos < length(cols_ind)]
  if (length(huecos)) {
    warning("Faltan indicadores en: ", paste(huecos, collapse = ", "),
            ". El ranking las ordena con los que sí tienen.", call. = FALSE)
  }
```

El universo se compara contra `PROVINCIAS`, no contra un «11» escrito a mano.
Y el guarda distingue dos cosas: la provincia **ausente** —ningún indicador—
aborta; la provincia con **huecos** solo avisa, porque un indicador sin dato es
un caso legítimo que el ranking ya sabe manejar.

**b) `cobertura_sistema()` deja de mirar solo a `provincia(1)` — antes:**

```r
  area_dep <- NA_real_
  pob_dep <- NA_real_
  d <- hoja_publicada(provincia(1), "01_Generalidades",
                      "distribucion_territorial.xlsx", "distribucion_territorial")
  if (!is.null(d)) area_dep <- valor_agregado(d, "Área municipal (km²)", "departamento")
  p <- hoja_publicada(provincia(1), "02_Demografia", "demografia.xlsx", "poblacion")
  if (!is.null(p)) pob_dep <- valor_agregado(p, "Población total", "departamento")
```

**Después:**

```r
  # El valor departamental es el mismo se entre por la provincia que se entre,
  # pero solo lo publica la hoja de una provincia que exista. Buscarlo únicamente
  # en provincia(1) hacía que un fallo en esa sola carpeta vaciara la cobertura
  # del sistema entera. .valor_departamental(), sesenta líneas más arriba, ya
  # resuelve esto recorriendo las once hasta encontrar la hoja.
  area_dep <- .valor_departamental(list(
    seccion = "01_Generalidades", archivo = "distribucion_territorial.xlsx",
    hoja = "distribucion_territorial", columna = "Área municipal (km²)"))
  pob_dep <- .valor_departamental(list(
    seccion = "02_Demografia", archivo = "demografia.xlsx",
    hoja = "poblacion", columna = "Población total"))
```

No se escribe una función nueva: se llama a la que el propio archivo ya tenía
para este mismo problema. Se comprobó que es seguro: `.valor_departamental()`
pasa por `ultimo_anio()`, que devuelve la tabla intacta cuando no hay columna
`Año` —que es el caso de las dos hojas— así que el valor no cambia.

**Ni `figuras_comparativas.R` ni `generar_comparativo.R` se tocan.**

### Cómo se comprobó antes de entregarlo

`parse()` y CRLF conservados. La lógica del guarda se ejecutó en R sobre tres
paneles sintéticos:

```
--- A) las once completas ---
  11 provincias x 5 indicadores          -> pasa, sin aviso

--- B) dos provincias sin ninguna salida ---
ERROR: El comparativo necesita las 11 provincias y 2 no tienen salidas en
       03_Outputs: P 3, P 7.
         Corra antes:  Rscript 02_Code/run_all.R

--- C) una provincia con un hueco ---
WARN: Faltan indicadores en: P 5. El ranking las ordena con los que sí tienen.
```

Y se comprobó que el aviso de huecos **no va a sonar en una corrida normal**:
el panel real publicado (`04_Docs/comparativo/panel_provincial.csv`) tiene
**38 de 38 columnas con dato en las once provincias**, sin un solo hueco.

### Efecto en las salidas

Ninguno mientras se corra completo: el panel actual pasa los dos guardas sin
inmutarse. Lo que cambia es que un comparativo parcial **deja de poder
generarse**, y con él desaparece la posibilidad de publicar un ranking de cuatro
provincias rotulado como de once.

`cobertura_sistema()` puede cambiar de valor solo en un caso: si la carpeta de
Agroindustrial de Occidente —la provincia 1— faltara. Con el guarda nuevo ese
caso ya no llega hasta aquí, así que en la práctica la corrección b) es
redundancia defensiva sobre la a).

---

## 17 · `F-4-002` — El rótulo del mapa de cobertura arbórea afirma algo que el dato no dice

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/04_figuras/00_mapas.R`,
`02_Code/04_figuras/07_ambiental.R`, `02_Code/03_tablas/07_ambiental.R`

### El error

El mismo número se publica con **tres etiquetas distintas** en la misma sección,
y dos de ellas afirman denominadores incompatibles.

| Pieza | Qué afirma | Denominador |
|---|---|---|
| Figura 4 (`04_figuras/07_ambiental.R:294,298`) | «perdió el 9 % de **su cobertura arbórea**», «como porcentaje de la **cobertura inicial**» | el bosque del municipio |
| Mapa 7 (`04_figuras/00_mapas.R:201,205`) | leyenda «**% del área**», «Porcentaje **del área** con pérdida» | el territorio del municipio |
| Comentario (`03_tablas/07_ambiental.R:172`) | «fracción **del área con cobertura**» | una tercera cosa |

En Del Río Grande, Santa Rosa de Osos sale con **9,0 % en las dos piezas**, a dos
páginas de distancia. El municipio tiene 813 km²: el 9 % del territorio son
73 km²; el 9 % de su cobertura de 2000, unos 55 km².

### Qué dice la fuente

Global Forest Watch mide la pérdida contra una **línea base**: la cobertura
arbórea del año 2000, contando solo donde el dosel superaba el 30 %.

> «Unless otherwise specified, the Global Forest Review uses tree cover with
> greater than 30 percent canopy density **in the year 2000 as its baseline for
> measurement**.» — [Global Forest Review, WRI](https://gfr.wri.org/annual-tree-cover-loss-data-explained)

Y la frase que publica el tablero es «perdió X kha de cobertura arbórea,
equivalente a una **disminución del Y % en la cobertura arbórea desde 2000**».

### Y los datos lo confirman

El mismo Excel trae la hoja cruda con las hectáreas perdidas cada año.
Despejando qué cobertura de 2000 implica cada cifra publicada:

```
cobertura arbórea de 2000 implícita, como fracción del área del municipio
  mínimo 0,40 | p25 0,68 | MEDIANA 0,76 | p75 0,86
```

Municipios con entre el 40 % y el 86 % del territorio arbolado en 2000: es
exactamente lo que cabe esperar de Antioquia. La lectura del mapa, en cambio,
**no cuadra**: pérdida acumulada ÷ área difiere del valor publicado en **119 de
124 municipios** —Medellín daría 6,59 % y se publica 10,00 %; Amalfi 11,07 %
frente a 13,00 %—.

### Corrección a la ficha de auditoría

`F-4-002` concluía: *«con los archivos del repositorio no se puede decir qué mide
exactamente la columna»*. **Era demasiado pesimista.** Sí se puede: es la
convención de GFW, la figura ya la rotulaba bien y el que estaba mal era el mapa.

Dos precisiones más sobre la propia ficha:

- Decía «siempre por debajo». Son **115 de 124**, no todos.
- Decía «nueve municipios imposibles». Son **cinco**: Hispania 3,08×, Jardín
  1,26×, Venecia 1,19×, La Unión 1,13× y Sabaneta 1,09×. Los otros cuatro
  —Frontino, Belmira, Granada y San Jerónimo— dan exactamente 1,00 y se explican
  por el redondeo a 0,1 pp: son municipios prácticamente cubiertos en 2000.

Los cinco restantes **siguen sin explicación** y quedan como pregunta abierta
para el equipo, junto con la del índice de envejecimiento (`F-2-015`). Pueden ser
diferencias de frontera —GFW usa límites GADM, no los del DANE— o un umbral de
dosel distinto en esas filas del tablero.

### Qué se cambió y dónde

**a) `04_figuras/00_mapas.R` — la leyenda y el subtítulo del mapa. Antes:**

```r
      titulo_leyenda = "% del área",
      formato = function(x) pct_co(x * 100, dec = 0)) +
      .textos_mapa(
        titulo = "La pérdida de cobertura arbórea se concentra en unos pocos municipios",
        subtitulo = "Porcentaje del área con pérdida de cobertura arbórea, 2001-2023",
        fuente = "Global Forest Watch. Cálculos propios."
      )
```

**Después:**

```r
      # NO es un porcentaje del área del municipio. Global Forest Watch mide la
      # pérdida contra una línea base: la cobertura arbórea del año 2000. Este
      # mapa rotulaba «% del área», y recalcularlo así difiere del valor
      # publicado en 119 de los 124 municipios —Medellín daría 6,6 % y se
      # publica 10,0 %— mientras que la figura 4 de esta misma sección ya lo
      # rotulaba bien (F-4-002).
      titulo_leyenda = "% de la cobertura\narbórea de 2000",
      formato = function(x) pct_co(x * 100, dec = 0)) +
      .textos_mapa(
        titulo = "La pérdida de cobertura arbórea se concentra en unos pocos municipios",
        subtitulo = paste("Pérdida acumulada 2001-2023, como porcentaje de la",
                          "cobertura arbórea que el municipio tenía en 2000"),
        fuente = "Global Forest Watch. Cálculos propios.",
        nota = paste("Cobertura arbórea: superficie con más del 30 % de dosel en",
                     "el año 2000, según Global Forest Watch. Incluye",
                     "plantaciones y cultivos arbóreos.")
      )
```

**b) `04_figuras/07_ambiental.R` — el subtítulo de la figura precisa el año, y
gana la misma nota:**

```r
        "Pérdida de cobertura arbórea acumulada 2001-2023, como porcentaje de la cobertura inicial. Provincia %s",
```
```r
        paste("Pérdida acumulada 2001-2023, como porcentaje de la cobertura",
              "arbórea que el municipio tenía en 2000. Provincia %s"),
```

«Cobertura inicial» no decía inicial **de qué**. El título de la figura no se
toca: ya era correcto.

**c) `03_tablas/07_ambiental.R` — el comentario del código. Antes:**

```r
#' Pérdida de cobertura arbórea 2001-2023 (fracción del área con cobertura).
```

**Después:**

```r
#' Pérdida de cobertura arbórea 2001-2023, como fracción de la cobertura que el
#' municipio tenía en 2000 (Global Forest Watch, dosel > 30 %). NO es una
#' fracción del área del municipio: recalcularla así difiere del valor publicado
#' en 119 de los 124 municipios (F-4-002).
```

**d) Las tres cabeceras de archivo** que describían la pieza como
«pérdida de cobertura arbórea 2001-2023 (%)» ahora dicen «como porcentaje de la
cobertura de 2000».

### Lo que se intentó y se revirtió: renombrar la columna del .xlsx

Se aplicó primero el séptimo cambio previsto —precisar la etiqueta de la columna
a `«… (% de la cobertura de 2000)»`— y **se revirtió al comprobar sus lectores**:

```
./99_checks/comparar_referencia.R:308
./05_documento/R/secciones.R:1043
./06_comparativo/panel_provincial.R:135
```

Los tres buscan la columna **por su nombre exacto**. Y el del comparativo es el
peligroso: `.valor_provincial()` hace
`if (is.null(d) || !ind$columna %in% names(d)) return(NA_real_)` — devuelve
**NA sin avisar**. El indicador ambiental habría desaparecido del panel de las
once provincias en silencio.

La etiqueta actual, `«… (%)»`, **no afirma nada falso**: dice «porcentaje», no
«porcentaje del área». Precisarla es una mejora real, pero toca la prosa
(`secciones.R`), que está aparcada para la corrección 5, y la línea base de
`comparar_referencia.R`. Queda anotado para hacerse allí, de una vez.

Se dejó constancia en el propio código, junto a la etiqueta:

```r
      # El rótulo de la columna se deja como está. No afirma nada falso —dice
      # «%», no «% del área»— y renombrarla rompería en SILENCIO a sus tres
      # lectores, que la buscan por el nombre exacto: la prosa de la sección
      # (05_documento/R/secciones.R:1043), el panel comparativo
      # (06_comparativo/panel_provincial.R:135, que devuelve NA sin avisar si no
      # la encuentra) y comparar_referencia.R:308. Precisarla es una mejora que
      # va con el ajuste de la prosa, no aquí.
```

### Cómo se comprobó antes de entregarlo

`parse()` en los tres archivos y CRLF conservados. Y se comprobó que el nombre de
la columna vuelve a ser idéntico en los **seis** sitios que lo usan, incluidos
los tres lectores externos.

El recálculo desde la fuente se hizo dos veces por caminos distintos: primero
acumulando la hoja cruda contra el área (lectura del mapa, falla en 119 de 124) y
después despejando la cobertura implícita (lectura de la figura, coherente en
119 de 124).

### Efecto en las salidas

Cambia el **subtítulo y la leyenda del mapa 7** y el **subtítulo de la figura 4**
en los once informes, más una nota nueva en las dos piezas. **Ninguna cifra
cambia.**

### Lo que sigue abierto

1. **Los cinco municipios que no cierran** — pregunta para el equipo.
2. **El umbral exacto de dosel** que usó quien armó el tablero. Se documenta el
   30 % porque es el valor por defecto de GFW; si el tablero usó otro, la nota
   habría que ajustarla.
3. **Calcular el indicador en el pipeline** desde la hoja cruda, con el
   denominador declarado en código. Se descartó en esta fase: cambiaría la cifra
   de los once informes —Medellín pasaría de 10,0 % a 6,6 %— sustituyendo un
   número sin documentar por otro distinto. Debe esperar a la misma respuesta que
   bloquea la corrección 16.

---

## 5 · `F-2-049` — La prosa promedia los municipios en vez de leer el total que la tabla ya publicó

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/05_documento/R/secciones.R`,
`02_Code/06_comparativo/panel_provincial.R`,
`02_Code/04_figuras/03_ordenamiento.R`, `02_Code/03_tablas/03_ordenamiento.R`

Es la corrección que se dejó para el final porque agrupa **todos** los cambios de
texto, y la que cierra el aviso abierto desde la corrección 3.

### El error

Las hojas publican cada cobertura **dos veces**: `«… (municipal)»` por municipio
y `«… (agregado)»` con el agregado ponderado en la fila de provincia. La prosa
tomaba la columna municipal y la promediaba:

```r
medias <- vapply(cobs, function(cl) mean(.num(m[[cl]]), na.rm = TRUE), numeric(1))
```

El panel comparativo hacía lo mismo con `via = "promedio"`. Y el bloque de
catastro y el de fibra repetían el patrón sobre sus propias columnas.

### Lo que producía

Medido sobre `ordenamiento.xlsx` y `economia.xlsx` de **Del Río Grande**, corrida
del 20 de agosto:

| | Decía la prosa | Dice su propia hoja | |
|---|---:|---:|---:|
| Acueducto | 87,3 % | **88,8 %** | +1,5 pp |
| Alcantarillado | 74,3 % | **74,8 %** | +0,5 pp |
| Energía | 99,8 % | **99,9 %** | +0,1 pp |
| Avalúo catastral rural | 56,0 % | **53,2 %** | −2,7 pp |
| Fibra óptica | 66,0 % | **75,8 %** | +9,8 pp |
| Informalidad laboral | 52,1 % | **48,9 %** | −3,3 pp |

El sesgo tiene dirección conocida: **la media simple sobrepondera a los
municipios pequeños**, que son los de peor cobertura.

Y contradecía tres declaraciones del propio proyecto: la regla 6 del anexo, la
cabecera de `panel_provincial.R` —«nunca se inventa un agregado»— y la caja de
lectura del comparativo: «si una provincia dice un número en su informe, aquí
dice exactamente el mismo».

### Qué se cambió y dónde

**a) `secciones.R` · servicios domiciliarios.** Se leen las columnas
`«(agregado)»` en vez de promediar las `«(municipal)»`:

```r
        cobs <- c("Cobertura de acueducto (municipal)", ...)
          m <- solo_municipios(s)
          medias <- vapply(cobs, function(cl) mean(.num(m[[cl]]), na.rm = TRUE),
                           numeric(1))
```
```r
        cobs <- c("Cobertura de acueducto (agregado)", ...)
          valores <- vapply(cobs, function(cl) valor_agregado(s, cl, "provincia"),
                            numeric(1))
          hay <- !is.na(valores)
```

Y la frase:

> ~~En servicios domiciliarios, **el promedio municipal** de la Provincia es de
> **87,3 %** en acueducto, **74,3 %** en alcantarillado y **99,8 %** en energía.~~
> En servicios domiciliarios, **la cobertura** de la Provincia es de **88,8 %** en
> acueducto, **74,8 %** en alcantarillado y **99,9 %** en energía.

**b) `secciones.R` · catastro.**

```r
        rural <- .num(m[["Proporción del avalúo catastral rural sobre el total"]])
          pct_co(mean(rural, na.rm = TRUE) * 100, dec = 1),
```
```r
        rural_prov <- valor_agregado(
          cat, "Proporción del avalúo catastral rural sobre el total", "provincia")
          .fpct(rural_prov),
```

> ~~el avalúo rural representa **en promedio** el **56,0 %** del avalúo catastral
> total **de cada municipio**~~
> el avalúo rural representa el **53,2 %** del avalúo catastral total

**c) `secciones.R` · fibra óptica.**

```r
        fib <- .num(m[["Proporción de líneas sobre fibra óptica"]])
            pct_co(mean(fib, na.rm = TRUE) * 100, dec = 1)) else ""))
```
```r
        fib_prov <- valor_agregado(d, "Proporción de líneas sobre fibra óptica",
                                   "provincia")
            .fpct(fib_prov)) else ""))
```

> ~~La fibra óptica […] representa **en promedio** el **66,0 %** de las líneas~~
> La fibra óptica […] representa el **75,8 %** de las líneas de la Provincia.

**En los tres casos desaparece «en promedio»**, que es lo que hacía falsa la
frase: el número ya no es un promedio de municipios sino el valor de la
provincia.

**d) `panel_provincial.R` · tres indicadores** pasan de `"promedio"` sobre
`(municipal)` a `"fila"` sobre `(agregado)`: `acueducto`, `alcantarillado` e
`informalidad`. Es la regla que declara la cabecera del propio archivo:
*«promedio: solo donde la hoja no publica agregado»*. Las tres lo publican.

**e) `03_tablas/03_ordenamiento.R` · el periodo viaja con la tabla.** Dos líneas:

```r
  periodo <- sprintf("último trimestre de %d", anio)
  ...
  attr(tabla, "periodo") <- periodo
```

**f) `04_figuras/03_ordenamiento.R` · los subtítulos dejan de decir «2025».**

```r
  periodo <- attr(tabla, "periodo") %||% "2025"
```

> ~~…por cada 1.000 habitantes, **2025** · municipios de la provincia…~~
> …por cada 1.000 habitantes, **último trimestre de 2025** · municipios…

**g) La nota de `fig_14`, que desde la corrección 3 afirmaba lo contrario de lo
que hace:**

```r
      nota = "El valor provincial es el promedio simple de las proporciones municipales"
```
```r
      nota = paste("El valor provincial es el total de líneas de fibra sobre el",
                   "total de líneas de la provincia, no el promedio de los",
                   "municipios. Se cuentan los accesos activos del último",
                   "trimestre, en los cuatro paquetes de servicio que incluyen",
                   "internet fijo.")
```

**h) `fig_13` gana una nota** con la segunda mitad de ese texto, porque la
corrección 18 también cambió qué se cuenta en ella.

### Cómo se comprobó antes de entregarlo

`parse()` en los cuatro archivos y CRLF conservados. Y las tres frases nuevas se
ejecutaron en R **con las funciones reales del proyecto** —`valor_agregado()` e
`y_lista()`, cargadas de `frases.R`— contra la hoja publicada de Del Río Grande:

```
SERVICIOS
  «En servicios domiciliarios, la cobertura de la Provincia es de 88,8 % en
   acueducto, 74,8 % en alcantarillado y 99,9 % en energía.»
CATASTRO
  «...el avalúo rural representa el 53,2 % del avalúo catastral total...»
FIBRA
  «La fibra óptica ... representa el 75,8 % de las líneas de la Provincia.»
```

Las tres coinciden **exactamente** con la fila que publica su propia hoja. Y el
75,8 % de la fibra es el mismo número que la línea de referencia de la figura 14:
**el aviso abierto queda cerrado**.

El `attr(tabla, "periodo")` se probó por separado, incluido el respaldo cuando el
atributo no está.

### Efecto en las salidas

- **Los once borradores** cambian seis cifras cada uno y la redacción de tres
  frases.
- **El panel comparativo** cambia tres columnas, y con ellas **el ranking del
  mosaico**: acueducto, alcantarillado e informalidad entran en él.
- **Las figuras 13 y 14** cambian subtítulo y nota. Sus cifras no.

**Ninguna hoja `.xlsx` cambia.** Esta corrección no toca ningún cálculo: hace que
el texto lea lo que la tabla ya decía.

### Lo que NO se hizo

La etiqueta de la columna de cobertura arbórea (`F-4-002`). Precisarla obliga a
tocar `comparar_referencia.R`, que es la línea base contra la que se comparan las
corridas, y mover esa referencia en el mismo commit que todo lo demás impediría
distinguir un cambio esperado de una regresión. Queda para después de validar
esta corrida.

---

## 16 · `F-2-015` — El índice de envejecimiento no tenía fórmula comprobable

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/01_homogeneizacion/poblacion_municipal.R`,
`02_Code/03_tablas/02_demografia.R`, `02_Code/04_figuras/02_demografia.R`

Estaba bloqueada esperando al equipo del tablero. **Se desbloqueó al medir**: la
pregunta no era cuál es la fórmula correcta, porque el informe ya la declaraba.

### El error

Había **dos** índices de envejecimiento en el proyecto y no coincidían en ningún
municipio:

- **El que se publicaba**, leído de `curados/poblacion_municipal_total_2025_dicc.dta`,
  un archivo armado a mano cuya fórmula no está en ninguna parte del repositorio.
- **El que el pipeline calcula** en `poblacion_municipal.R`, que la propia
  auditoría registra con **cero consumidores**.

```
125 municipios comparados · coincidencias exactas: 0
el curado es ~6,6 % más alto (mediana)
Angostura: publica 27,96   el pipeline calcula 25,20
```

### Lo que se descubrió al corregir

**a) La diferencia no es de fórmula, es de estructura de edad.** Comparadas
todas las columnas de los dos archivos, no solo el índice:

```
P_T            (población total)      125 de 125 exactas
P_inf_T_0_11   (0 a 11 años)            0 de 125
P_j_T_12_28    (12 a 28)                0 de 125
P_ad_T_29_59   (29 a 59)                0 de 125
P_v_T_60_85    (60 y más)               1 de 125
```

La población total coincide exactamente y las columnas son porcentajes que suman
100 en los dos archivos. **Reparten la misma población en edades distintas**, y
el curado describe una población sistemáticamente más envejecida —en Angostura,
16,4 % de mayores de 60 frente a 14,8 %—. La explicación más probable es que se
armó con otra vigencia de la proyección del DANE.

**b) Los dos usan el mismo denominador NO estándar.** Estimados desde
`poblacion_edad_2025`, mediana de los 125 municipios:

| Versión | Fórmula | Mediana |
|---|---|---:|
| Lo que se publicaba | desconocida (curado) | 30,5 |
| Lo que calcula el pipeline | 65+ / (0-14 + 60+) | ~28,6 |
| **El estándar** | **65+ / 0-14** | **49,9** |

El curado y el derivado están cerca entre sí y los dos muy lejos del estándar: el
curado usa el mismo denominador de **población dependiente** que el pipeline.

**c) Y el informe ya declaraba la fórmula estándar. En tres sitios.**

`04_figuras/02_demografia.R`, título de la figura 5:

> «%s es el municipio más envejecido de la provincia, con %s adultos mayores
> **por cada 100 menores de 15 años**»

Subtítulo de la misma figura:

> «Índice de envejecimiento (**población de 65 años o más por cada 100 menores de
> 15**), 2025»

`05_documento/R/secciones.R`, la prosa:

> «los índices de envejecimiento más altos —adultos mayores **por cada cien
> menores de quince años**—»

**Los tres textos describen 65+/0-14. El número publicado no era eso.** No era
una ambigüedad metodológica: era un rótulo demostrablemente falso, igual que el
del mapa de cobertura arbórea (`F-4-002`).

Eso convierte la decisión en trivial: no se cambia la definición, **se hace que
el número obedezca a la definición que el informe ya declaraba.**

### Qué se cambió y dónde

**a) `poblacion_municipal.R` — el derivado gana los dos grupos.** Entra una lista
nueva junto a `DECENIOS`:

```r
# Los dos grupos del índice de envejecimiento estándar: 65 y más sobre 0 a 14.
# No son decenales, así que van aparte, pero salen del mismo PPED y del mismo
# .total_grupo() que los de arriba.
GRUPOS_ENVEJECIMIENTO <- list(
  edad_0_14   = list(edades =  0:14, cien = FALSE),
  edad_65_mas = list(edades = 65:99, cien = TRUE)
)
```

y seis líneas que las añaden a `poblacion_edad_2025`, el derivado que ya creamos
en la corrección 7. **Solo en total**: la sección no abre el índice por sexo.

Los dos grupos ya se calculaban dentro del script para otra cosa —`"Dep"` y
`"Enve"` de la lista `grupos`—; lo que faltaba era publicarlos.

**b) `03_tablas/02_demografia.R` — deja de leer el curado. Antes:**

```r
  envejecimiento <- haven::read_dta(entrada("curados", "poblacion_municipal_total_2025_dicc.dta")) |>
    dplyr::transmute(ind_mpio = as.integer(.data$ind_mpio),
                     I_enve_T = as.numeric(.data$I_enve_T))
```

**Después:**

```r
  edades <- leer_derivado("poblacion_edad_2025") |>
    dplyr::transmute(
      ind_mpio    = as.integer(.data$ind_mpio),
      edad_65_mas = as.numeric(.data$edad_65_mas),
      edad_0_14   = as.numeric(.data$edad_0_14)
    )
```

**c) Y el agregado provincial deja de ser un promedio ponderado.** El índice es
una razón entre dos conteos: se suman las dos puntas y se recalcula sobre las
sumas, como manda la regla 6. Ponderar por población total —que no es el
denominador de ninguna de las dos puntas— habría repetido el error que la
corrección 4 quitó de la leishmaniasis.

```r
  columnas <- c("tasa_natalidad", "tasa_mortalidad", "edad_65_mas", "edad_0_14")
  tabla <- agregar_totales(
    municipios, universo = universo, prov = prov, columnas = columnas,
    como = list(tasa_natalidad = "promedio_ponderado",
                tasa_mortalidad = "promedio_ponderado",
                edad_65_mas = "suma", edad_0_14 = "suma"),
    pesos = "habitantes_total"
  ) |>
    dplyr::mutate(I_enve_T = .data$edad_65_mas / .data$edad_0_14 * 100) |>
```

Las dos tasas vitales siguen ponderadas por población, que sí es su denominador.

**d) El rótulo de la fila agregada** deja de decir solo «(por población)»:

```r
           " (por población)")
```
```r
           " (tasas por población; índice sobre las sumas)")
```

**e) El subtítulo de la figura 5** decía «(promedio ponderado por población: X)»,
que desde este cambio es falso:

```r
              "menores de 15), 2025 · Provincia %s (sobre las sumas de la",
              "provincia: %s)"),
```

**El título de la figura y la prosa NO se tocan: ya eran correctos.** Lo que
cambia es que ahora el número los respeta.

### Sobre la regla que Pablo fijó

El ajuste **no lee el original**: `02_demografia.R` lee un derivado, y el
derivado lo produce un script de homogeneización desde el PPED. Se eligió
**ampliar `poblacion_edad_2025`** en vez de crear otro derivado, porque ya salía
del mismo insumo y ya lo lee esta misma sección.

### Efecto en las salidas

**El índice sube en los 125 municipios: alrededor de un 67 % (mediana de 30,5 a
49,9 estimada).** Cambian la columna «Índice de Envejecimiento» de la hoja
`natalidad_mortalidad`, la figura 5 y la frase de la sección 02 en los once
informes.

Es el cambio de cifra más grande de toda la fase, y hay que declararlo al autor:
**la cifra entregada no era comparable con la que publica el DANE.**

### Lo que NO se pudo comprobar aquí

El valor exacto. `poblacion_edad_2025` solo publica decenios, así que las cifras
de arriba son una estimación por interpolación dentro del decenio. El número
definitivo sale de la corrida, que es la que calcula 0-14 y 65+ de verdad.

**Qué esperar en el log:**

```
[derivado] poblacion_edad_2025.parquet  (125 x 33, ...)
```

Dos columnas más que antes (31 → 33).

### Un archivo curado que se queda sin lector

`curados/poblacion_municipal_total_2025_dicc.dta` ya no lo lee nadie. **No se
borra**: es una fuente y las fuentes no se tocan (regla 2). Pero conviene que el
`README` de `curados/` lo anote, y que el equipo confirme de qué vigencia de la
proyección salió, porque esa pregunta sigue sin respuesta aunque ya no bloquee
nada.

---

## 7b · `F-2-018` — Los ponderadores salían de la serie que el proyecto declaró descartada

**Estado:** aplicado en parte · 2026-08-20
**Archivos:** `02_Code/01_homogeneizacion/poblacion_municipal.R`,
`02_Code/03_tablas/03_ordenamiento.R`, `02_Code/03_tablas/09_salud.R`

La corrección 7 cerró la contradicción **visible** —la pirámide y la tabla de
población del mismo libro—. Esta cierra los **ponderadores**.

### El error

Cuatro secciones ponderaban sus agregados con `POBLACION MUNICIPAL.xlsx`, la
serie que la cabecera de `02_demografia.R` declara descartada con estas palabras:

> El .do lee POBLACION MUNICIPAL.xlsx, pero esa serie **NO es la que se
> publicó**. (…) las cifras difieren entre −3 % y +10 % por municipio (Yarumal
> 44.770 vs 41.884 publicados). Se usa la serie publicada, porque el pipeline
> debe poder rehacer el informe.

La decisión está bien razonada; lo que no ocurría es que se aplicara fuera de esa
hoja. El caso más claro: **la sección 09 ponderaba con Yarumal a 44.770
habitantes mientras la sección 10 del mismo informe imprimía 41.884.**

### Qué se cambió y dónde

**a) `poblacion_municipal.R` — derivado nuevo `poblacion_anual`.** Es
`poblacion_total_2025` sin filtrar el año: Antioquia, todos los años del PPED,
por área geográfica. Existe porque los ponderadores no son todos de 2025 —la
sección 03 pondera con 2022 y 2024—.

```r
poblacion_anual <- pped |>
  dplyr::filter(.data$cod_dpto == "05") |>
  dplyr::transmute(
    ind_mpio  = a_numero(.data$ind_mpio), nvl_label = .data$nvl_label,
    anio      = as.integer(.data$año),    area_geo  = .data$area_geo,
    Total     = a_numero(.data[[c_total]]),
    Hombres   = a_numero(.data[[c_hombres]]),
    Mujeres   = a_numero(.data[[c_mujeres]])
  )
```

**`poblacion_total_2025` no se toca**: su cabecera advierte que es la serie con
la que se publicó el informe y que tiene tres lectores.

**b) `03_ordenamiento.R` · `.poblacion_peso()`** deja de leer el Excel y lee el
derivado. Y **gana un guarda**: un año fuera del rango del PPED devolvía cero
filas, y el `left_join` dejaba todos los pesos en `NA` sin que nada fallara.

```r
  if (nrow(d) == 0) {
    anios <- sort(unique(.cache_ordenamiento$pob$anio))
    stop("No hay población de ", anio_pedido, " en el derivado poblacion_anual; ",
         "el PPED cubre ", min(anios), "-", max(anios), ".", call. = FALSE)
  }
```

**c) `09_salud.R` · `.pesos_poblacion()`** lee `poblacion_total_2025`, que ya
publica las tres áreas de 2025 —total, cabecera y rural—, que es exactamente lo
que esta sección necesita. No hizo falta derivado nuevo.

### Efecto medido

**Sección 09.** Recalculado con los pesos del PPED sobre las salidas del 20 de
agosto:

| | Publicada | Con PPED |
|---|---:|---:|
| Leishmaniasis, Del Río Grande | 1,586 | **1,641** |
| Leishmaniasis, Turística | 93,993 | **95,728** |

**Sección 03.** El efecto es mínimo, porque un ponderador solo mueve pesos
relativos:

| Del Río Grande | Publicada | Con PPED |
|---|---:|---:|
| Acueducto | 88,81 % | 88,87 % (+0,06 pp) |
| Alcantarillado | 74,79 % | 74,81 % (+0,02 pp) |
| Energía | 99,90 % | 99,90 % (=) |

**Las cifras de la corrección 5 no se mueven a un decimal**: la prosa seguirá
diciendo 88,8 %, 74,8 % y 99,9 %.

### Declarado en el código · decisión del 2026-08-20

Se deja **sin corregir y declarado**. Pablo: «esto solo afecta las tablas, en los
documentos de borrador no se usan esos años anteriores como parte del análisis».

 de  y  de
 llevan ahora un bloque de doce líneas que dice qué serie usan,
por qué, y qué haría falta para cambiarla, para que quien reciba el código no lo
lea como un olvido. **Ninguna cifra cambia.**

### Lo que queda abierto, y por qué

**Las secciones 04 y 05 no se tocaron: el PPED no cubre sus años.**

| Sección | Años que necesita | ¿PPED (2018-2042)? |
|---|---|---|
| 09 · Salud | 2025 | **sí** — cerrada |
| 03 · Ordenamiento | 2022, 2024, 2025 | **sí** — cerrada |
| 05 · Economía | 2015-2024 | **no**: faltan 2015, 2016 y 2017 |
| 04 · Gobernabilidad | 2010-2024 (ICM) | **no**: faltan 2010 a 2017 |

El valor agregado per cápita se publica desde 2015 y el ICM desde 2010.
Repuntarlos al PPED dejaría esos años **sin población y sin indicador**, que es
peor que la incoherencia que se quiere quitar.

Hay tres salidas posibles y ninguna es de código:

1. Comprobar si existe la **retroproyección** del DANE (1985-2017) y añadirla
   como segundo insumo de `poblacion_municipal.R`. Es la solución limpia.
2. Aceptar la mezcla **declarada**: PPED desde 2018 y la serie vieja antes,
   dicho en la hoja. Resuelve el presente y deja el pasado marcado.
3. Recortar las series a 2018 en adelante.

**Y un quinto sitio que no es un ponderador:** `.hoja_dependencia_economica()`
de `05_economia.R` lee la hoja `Rangos_Quintenios` de `POBLACION MUNICIPAL.xlsx`
para el índice de dependencia. No es un peso sino el indicador mismo, y necesita
grupos quinquenales que el derivado no publica. Queda fuera de `F-2-018`.

### Cómo se comprobó antes de entregarlo

`parse()` en los tres archivos, CRLF conservados, y se verificó que los nombres
de área que pide `09_salud.R` —`"Total"` y `"Centros Poblados y Rural
Disperso"`— son exactamente los que trae `poblacion_total_2025`.

Los dos valores nuevos de leishmaniasis se recalcularon desde las salidas reales
y **ya están en `15_verificar_correcciones.R`**, junto con comprobaciones nuevas:
que `poblacion_anual` exista y traiga los 125 municipios en 2022, 2024 y 2025;
que los dos scripts ya no nombren `POBLACION MUNICIPAL.xlsx`; y que Yarumal pese
41.884 y no 44.770.

---

## 19 · `F-5-003` — La revisión estática aborta entera si git no está en el PATH

**Estado:** aplicado · 2026-08-20
**Archivo:** `02_Code/99_checks/check_pipeline.R`

Hallazgo nuevo, encontrado al preparar la corrida limpia.

### El error

`check_pipeline.R` llama a git sin comprobar antes que exista:

```r
rastreados <- system2("git", c("-C", shQuote(RUTAS$raiz), "ls-files"),
                      stdout = TRUE, stderr = FALSE)
```

En Windows es normal tener git instalado pero **fuera del PATH que ve R**.
Entonces `system2()` lanza un error no capturado y R aborta el script entero.

### La evidencia, en ejecución

Salida real en la máquina de Pablo:

```
1. Rutas absolutas en código vigente
  OK — ninguna
2. Insumos referenciados por el código
  25 insumos citados; 25 presentes
3. Nombres de archivo (unicode y mayúsculas)
Error in system2("git", c("-C", shQuote(RUTAS$raiz), "ls-files"), stdout = TRUE, :
  '"git"' not found
Execution halted
                                                        status 1
```

Las comprobaciones **4 en adelante nunca corrieron**. Y el script sale con
`status 1`, así que se lee como «el repositorio tiene errores» cuando lo que
falta es una herramienta que solo necesita una de las comprobaciones.

El propio proyecto ya tiene el patrón correcto para una dependencia opcional:
`HAY_CARTOGRAFIA` en `R/03_mapas.R` comprueba y avisa en vez de abortar.

### Qué se cambió y dónde

**`rastreados` lo usan DOS comprobaciones**, la 3 y la 4, así que la variable
queda definida siempre y las dos ramas se guardan por separado:

```r
GIT <- Sys.which("git")
HAY_GIT <- nzchar(GIT)
# `rastreados` queda definido siempre: la comprobación 4 también lo usa.
rastreados <- if (HAY_GIT) {
  system2(GIT, c("-C", shQuote(RUTAS$raiz), "ls-files"),
          stdout = TRUE, stderr = FALSE)
} else character(0)

if (!HAY_GIT) {
  cat("  omitida: git no está en el PATH que ve R\n")
  avi("git no está en el PATH que ve R: se omiten las comprobaciones 3 y 4, ",
      "que preguntan por los archivos rastreados. Las demás sí corren. (...)")
} else {
  ...
}
```

Y la comprobación 4:

```r
if (!HAY_GIT) {
  # Sin la lista de archivos rastreados esta comprobación no puede concluir
  # nada. Se omite en vez de imprimir un «OK» que no ha comprobado nada.
  cat("  omitida: necesita la lista de archivos rastreados por git\n")
} else {
  for (d in RETIRADAS) { ... }
  cat("  OK — ninguna reapareció\n")
}
```

El `cat()` inline importa: `avi()` no imprime en el momento —acumula los avisos
y los vuelca al final—, así que sin esa línea el usuario ve un título de
comprobación seguido de nada.

### El primer intento estaba mal, y así se vio

La primera versión de esta corrección solo protegió la **creación** de
`rastreados`, dentro del `else`. La comprobación 4 la usa treinta líneas más
abajo, fuera de ese `else`, así que el script pasó de morir en el punto 3 a morir
en el punto 4:

```
3. Nombres de archivo (unicode y mayúsculas)
4. Carpetas retiradas en la reestructuración
Error: object 'rastreados' not found
Execution halted
```

**Un `parse()` correcto no lo detecta**: la sintaxis era válida y el error solo
aparece al ejecutar la rama sin git. Fue Pablo quien lo encontró al correrlo.

### Cómo se comprobó, esta vez ejecutando

Se extrajo del archivo el bloque **real** de las comprobaciones 3 y 4 —líneas
89 a 138— y se ejecutó en R con las dos ramas, simulando solo el entorno de
alrededor:

```
--- git PRESENTE ---
3. Nombres de archivo (unicode y mayúsculas)
  0 archivos rastreados; 0 en NFD; 0 colisiones
4. Carpetas retiradas en la reestructuración
  OK — ninguna reapareció
resultado: sin error

--- git AUSENTE ---
3. Nombres de archivo (unicode y mayúsculas)
  omitida: git no está en el PATH que ve R
4. Carpetas retiradas en la reestructuración
  omitida: necesita la lista de archivos rastreados por git
resultado: sin error
```

### Por qué importa más de lo que parece

Es el primer control del README y el que se corre antes de una corrida larga.
En cualquier máquina que reciba el repositorio sin git en el PATH —que es
justamente el caso de uso previsto: pasarle el proyecto a otra persona— no
revisaba nada más allá del punto 2.

---

## 20 · `F-5-004` — No se encuentra el pandoc que trae RStudio, y no sale ningún `.docx`

**Estado:** aplicado · 2026-08-20
**Archivos:** `02_Code/05_documento/generar_borrador.R`,
`02_Code/06_comparativo/generar_comparativo.R`

Hallazgo nuevo, encontrado en la corrida limpia del 20 de agosto.

### El error

```r
.hay_pandoc <- function() nzchar(Sys.which("pandoc"))
```

`Sys.which()` solo mira el PATH. **RStudio trae su propia copia de pandoc y no la
publica en el PATH**: la deja en la carpeta que anuncia por la variable de
entorno `RSTUDIO_PANDOC`. En una máquina con RStudio y sin pandoc instalado
aparte —el caso normal de este proyecto, y el de la máquina de Pablo— el
pipeline concluye que no hay pandoc **cuando sí lo hay**.

### La evidencia, en ejecución

Salida real de `generar_borrador.R 3 4`:

```
== Borradores provinciales ==
== Panel provincial ==
  11 provincias x 34 indicadores
  [borrador] Del Río Grande — solo Markdown (falta pandoc)
  [borrador] Turística y Agroecológica — solo Markdown (falta pandoc)
Warning message:
pandoc no está instalado: se generará solo el Markdown y ningún .docx.
Instálelo con  brew install pandoc
```

**Cero `.docx`.** Y el consejo era inservible: `brew install pandoc` es macOS.

Es la contrapartida exacta de `F-2-050`, que corregimos en la corrección 12:
aquel hallazgo decía que la ausencia de pandoc se avisaba con `message()` y el
proceso salía con código 0. El `warning()` que pusimos **funcionó** —por eso se
vio— pero el diagnóstico de fondo era otro: pandoc estaba ahí.

### Qué se cambió y dónde

**a) `generar_borrador.R` — función nueva que resuelve la ruta:**

```r
#' Ruta al ejecutable de pandoc, o "" si no aparece por ningún lado.
#'
#' Se busca primero en el PATH y después en RSTUDIO_PANDOC. RStudio trae su
#' propia copia de pandoc y NO la publica en el PATH, así que en una máquina con
#' RStudio —el caso normal de este proyecto— Sys.which("pandoc") decía que no
#' había pandoc cuando sí lo había, y los once informes salían solo en Markdown
#' (F-5-004). Verificado en Windows el 2026-08-20.
.ruta_pandoc <- function() {
  p <- unname(Sys.which("pandoc"))
  if (nzchar(p)) return(p)
  dir <- Sys.getenv("RSTUDIO_PANDOC", unset = "")
  if (nzchar(dir)) {
    exe <- file.path(dir, if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc")
    if (file.exists(exe)) return(exe)
  }
  ""
}

.hay_pandoc <- function() nzchar(.ruta_pandoc())
```

**b) Las tres llamadas** dejan de invocar el literal `"pandoc"` y usan la ruta
resuelta: `.completar_estilos()` (línea 69), `generar_borrador()` (578) y
`generar_comparativo()` (380).

**c) El aviso deja de ser de macOS:**

```r
    warning("pandoc no está instalado: se generará solo el Markdown y ningún ",
            ".docx. Instálelo con  brew install pandoc", call. = FALSE)
```
```r
    warning("no se encuentra pandoc: se generará solo el Markdown y ningún ",
            ".docx. Instálelo desde https://pandoc.org/installing.html, o corra ",
            "esto desde RStudio, que trae su propia copia (RSTUDIO_PANDOC).",
            call. = FALSE)
```

**d) `generar_comparativo.R`** tenía su propia copia de la comprobación
(`nzchar(Sys.which("pandoc"))`). Pasa a usar `.hay_pandoc()`, que hereda por el
`source()` que ya hace de `generar_borrador.R`.

### Cómo se comprobó

Se cargaron las dos funciones del archivo real y se ejecutaron las tres
situaciones:

```
1) pandoc en el PATH        -> /usr/bin/pandoc                     | hay: TRUE
2) solo en RSTUDIO_PANDOC   -> /tmp/.../pandoc                     | hay: TRUE
3) en ninguna parte         -> «»                                  | hay: FALSE
```

### Por qué importa

Sin esto, **el entregable del proyecto no se produce** en la máquina más común
para correrlo. Y como los `.md` sí salen, el fallo es fácil de pasar por alto:
hay archivos nuevos en `04_Docs/borradores/`, solo que no son los que se
entregan.

---
