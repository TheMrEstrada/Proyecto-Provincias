# Manual de diseño de figuras — Proyecto Provincias

Sistema visual de las figuras y tablas del diagnóstico provincial. **Toda figura del
proyecto se rige por este documento.** No hay decisiones de color, tipografía o
tamaño que se tomen figura por figura: se toman aquí una vez y se aplican mediante
`02_Code/R/02_tema.R`.

Identidad: **base EAFIT + capa propia del proyecto**. Los colores provienen del
Manual de Marca Universidad EAFIT 2025 v4.0 (paleta oficial de 31 tonos Pantone);
la tipografía y la retícula siguen el manual; no se usan logotipos ni el arquetipo
institucional dentro de las figuras (la marca la pone el documento que las
contiene, no cada gráfico).

> Cada color de este documento fue **verificado con un validador**, no elegido a
> ojo. El procedimiento y los resultados están en la sección
> [Verificación del color](#verificación-del-color). Si cambia un color, hay que
> volver a correr el validador.

---

## 1. Principios

1. **Una figura responde una pregunta.** Si necesita dos, son dos figuras.
2. **El dato manda, la tinta acompaña.** Sin fondos de color, sin sombras, sin 3D,
   sin degradados decorativos, sin bordes de marco.
3. **Etiquetar directamente.** El valor va sobre la marca, no en un eje que obliga
   a estimar. Esto además es el requisito de accesibilidad de los tonos claros
   (ver §2.4).
4. **El color codifica una sola cosa a la vez**: identidad (categórica), magnitud
   (secuencial) o polaridad (divergente). Nunca las tres.
5. **Nunca color solo.** Si hay dos o más series, hay leyenda; si son ≤ 4, además
   van etiquetadas directamente.
6. **Todo gráfico dice de dónde viene.** Nota de fuente obligatoria, con año.

---

## 2. Color

### 2.1 Categórica — identidad de series

Orden **fijo**. Se asignan en secuencia (serie 1 → slot 1); nunca se ciclan ni se
reordenan por valor.

| Slot | Nombre EAFIT | Hex | Pantone | Contraste vs fondo |
|:---:|---|:---:|---|---:|
| 1 | Azul marino | `#4458A6` | 7455 C | 6,41:1 |
| 2 | Naranja | `#FF8F1B` | 151 C | 2,22:1 ▲ |
| 3 | Verde selva | `#159449` | 7482 C | 3,81:1 |
| 4 | Mora | `#BA3A93` | 240 C | 4,97:1 |
| 5 | Turquesa menta | `#46C69F` | 3395 C | 2,08:1 ▲ |
| 6 | Baya | `#C24A49` | 7418 C | 4,68:1 |

▲ Bajo 3:1 — **obliga** a etiqueta de valor visible sobre la marca (que este
proyecto usa siempre, así que la condición se cumple por diseño).

- **Serie única:** slot 1 (Azul marino). Sin leyenda: el título nombra la serie.
- **Más de 6 series:** no se inventa un color 7. Se agrupa en «Otros», se pasa a
  múltiplos pequeños, o se cambia de forma. El límite es real, no una sugerencia.
- **En dispersión, burbujas, mapas y múltiplos pequeños** (donde cualquier par de
  marcas puede quedar contiguo) el máximo son **3 series**: slots 1–3.

### 2.2 Secuencial — magnitud

Rampa monocroma derivada del **hue del Azul Zafre EAFIT** (264°), que termina
prácticamente en el Zafre institucional (`#000066`):

```
#A1B4DB  #7391D0  #456DC5  #1E47B1  #02228F  #00015E
 menor  ───────────────────────────────────────►  mayor
```

Uso: mapas coropléticos, heatmaps, cualquier codificación de «cuánto». Nunca un
arcoíris; nunca una rampa de dos hues.

### 2.3 Divergente — polaridad respecto de una referencia

Para «por encima / por debajo» de un promedio (provincial, subregional o
departamental). Gris neutro en el centro:

```
#BB4343  #CD7671  #D5A39F  │ #E8E8E6 │  #A3B0D5  #7B8FD0  #546AC0
  por debajo de la referencia   neutro   por encima de la referencia
```

Brazo cálido derivado del hue de Baya (24°), brazo frío del hue de Azul marino
(270°), pasos de lightness simétricos.

### 2.4 Resalte y contexto

El patrón más frecuente del proyecto: **un municipio (o la provincia) destacado
sobre sus pares**.

| Rol | Hex | Contraste | Uso |
|---|:---:|---:|---|
| Resalte | `#4458A6` | 6,41:1 | el municipio/provincia del que trata la figura |
| Contexto | `#888C94` | 3,29:1 | los demás municipios |
| Referencia | `#C24A49` | 4,68:1 | línea de promedio provincial / departamental |

### 2.5 Tinta y superficie

| Rol | Hex | Contraste | Uso |
|---|:---:|---:|---|
| Superficie | `#FFFFFF` | — | fondo del gráfico (blanco EAFIT) |
| Tinta primaria | `#292E38` | 13,3:1 | título, etiquetas de valor, nombres de categoría |
| Tinta secundaria | `#595E66` | 6,4:1 | subtítulo, títulos de eje, leyenda |
| Tinta terciaria | `#888C94` | 3,3:1 | nota de fuente |
| Grilla | `#DCDEE1` | 1,3:1 | líneas de referencia (deliberadamente tenues) |

**El texto nunca lleva el color de la serie.** Un valor etiquetado va en tinta
primaria; la identidad la carga la marca de color junto a él.

> **Brecha declarada frente al Manual EAFIT.** El Manual no incluye grises
> intermedios neutros: solo Gris ceniza `#CFD1D2` (1,49:1, insuficiente para
> texto y para marcas de datos) y Negro. Los cuatro grises de esta sección se
> derivaron desaturando el hue del Azul Zafre (264°) y fijando su lightness por
> requisito de contraste WCAG. Es una extensión **funcional**, no estética, y se
> documenta aquí para eventual revisión con Comunicaciones Institucionales.

---

## 3. Tipografía

**Inter** (principal EAFIT, SIL OFL) en todo el sistema. Si no está instalada, la
cadena de reemplazo es Roboto Serif → Arial → la sans por defecto del sistema:
una figura nunca falla por falta de tipografía, pero el resultado canónico es Inter.

| Elemento | Familia | Tamaño | Peso | Color |
|---|---|---:|---|---|
| Título | Inter | 12 pt | Semibold (600) | tinta primaria |
| Subtítulo | Inter | 10 pt | Regular | tinta secundaria |
| Etiqueta de valor | Inter | 8,5 pt | Medium (500) | tinta primaria |
| Categoría (eje Y) | Inter | 9 pt | Regular | tinta primaria |
| Escala (eje X) | Inter | 8,5 pt | Regular | tinta secundaria |
| Título de eje | Inter | 9 pt | Regular | tinta secundaria |
| Leyenda | Inter | 9 pt | Regular | tinta secundaria |
| Nota de fuente | Inter | 7,5 pt | Regular | tinta terciaria |

Tracking −15 (−0,015 em) en títulos, según Manual EAFIT p. 51. Nunca versalitas
sostenidas en nombres de municipio: van en capitalización normal
(`Santa Fe de Antioquia`, no `SANTA FE DE ANTIOQUIA`).

---

## 4. Dimensiones y retícula

Ancho de caja del informe (A4 con márgenes de 2,5 cm): **16 cm**. Toda figura se
genera al ancho final de impresión — nunca se reescala en Word, porque eso
deforma la tipografía.

| Tipo | Ancho | Alto | Nota |
|---|---:|---:|---|
| Barras horizontales (n municipios) | 16 cm | 4 + 0,55·n cm | crece con el número de barras |
| Barras verticales / columnas | 16 cm | 9 cm | |
| Líneas (series de tiempo) | 16 cm | 8 cm | |
| Dumbbell (dos momentos) | 16 cm | 4 + 0,55·n cm | |
| Pirámide poblacional | 16 cm | 11 cm | |
| Dispersión | 12 cm | 12 cm | cuadrada: las distancias deben ser comparables |
| Media caja (dos figuras lado a lado) | 7,7 cm | 7 cm | |

Márgenes internos: 2 mm arriba y derecha, 0 abajo e izquierda (el texto de ejes ya
aporta su propio espacio).

---

## 5. Reglas por tipo de gráfico

### Barras horizontales — el caballo de batalla del proyecto
- Ordenadas por valor **descendente** (la mayor arriba), nunca alfabéticas: el
  orden es información.
- Etiqueta de valor al final de la barra, por fuera, en tinta primaria.
- **Sin eje X** (ni línea, ni marcas, ni grilla vertical): las etiquetas ya dan el
  valor y el eje sería tinta redundante.
- Barra: altura relativa 0,68 (deja aire entre barras), esquinas rectas.
- Con resalte: municipio destacado en color de resalte, resto en contexto.
- Línea de promedio: discontinua, 0,6 pt, color de referencia, con su valor rotulado.

### Barras apiladas
- Máximo 4 segmentos; el resto se agrupa en «Otros» (siempre el último, en gris de
  contexto).
- Separación de 0,5 pt del color de superficie entre segmentos.
- Etiquetas solo en segmentos que superen el 8 % del total (debajo no caben y
  producen colisiones).

### Líneas
- Grosor 0,8 pt; marcador solo en el primer y último punto de cada serie.
- Etiqueta directa al final de la línea (no leyenda) cuando hay ≤ 4 series.
- Eje Y empieza en cero salvo que se indique lo contrario en el subtítulo.
- Grilla horizontal tenue; **nunca** grilla vertical.

### Dumbbell (cambio entre dos momentos)
- Segmento conector en gris de contexto, 0,8 pt; puntos de 2,2 mm.
- Momento inicial en contexto, momento final en resalte.
- Etiqueta el valor de ambos extremos y ordena por el valor final.

### Pirámide poblacional
- Hombres a la izquierda (valores negativos, etiquetados en positivo), mujeres a
  la derecha. Slots 1 y 2 de la categórica.
- Eje X simétrico y con marcas en múltiplos redondos.
- Sin grilla vertical; línea central en gris de contexto.

### Dispersión
- Puntos de 2,5 mm, 80 % de opacidad, anillo blanco de 0,3 pt para que los
  solapamientos se lean.
- Máximo 3 series de color (§2.1).

### Tortas
- **No se usan.** Cualquier composición va en barra apilada al 100 % o en barras
  ordenadas. Excepción única: composición binaria (dos categorías) donde la
  proporción es el mensaje. Si el catálogo pide torta, se sustituye y se anota.

### Mapas

Implementados en [`02_Code/R/03_mapas.R`](../R/03_mapas.R) y generados por
[`00_mapas.R`](00_mapas.R).

**Cuándo un mapa gana a una barra.** La barra ordena, el mapa localiza. Solo se
usa mapa cuando la pregunta es **dónde**: contigüidad (los municipios con déficit
alto, ¿son vecinos?), frontera (¿el patrón se corta en el límite provincial?),
accesibilidad (¿los peores están lejos del corredor vial?). Si la lectura es
«quién tiene más», la barra es mejor y el mapa es decoración cara.

- **Magnitud:** rampa secuencial del Azul Zafre (§2.2). Nunca categórica.
- **Sin dato:** gris `#E8E8E6`, y la leyenda lo declara. No es un cero (§7).
- **Sin ejes ni retícula.** `coord_sf(datum = NA)`: en un mapa temático el lector
  no localiza por coordenada, y los números del eje compiten con el dato.
- **Etiquetas** de municipio separadas con `ggrepel` y halo del color de la
  superficie, para que el nombre se lea sobre cualquier tono de la rampa.
- **Máximo 3 series categóricas** (§2.1). Once provincias no se distinguen por
  color: se distinguen por su límite.
- **Cartografía base:** DANE, Marco Geoestadístico Nacional
  (`01_Data/00_Inputs/maps/MGN_MPIO_POLITICO.shp`), cruzada por código DIVIPOLA.
- **Tamaño:** 16 × 11 cm. El texto se ajusta a 12,5 cm porque la leyenda
  vertical ocupa unos 3 cm a la derecha.
- **Los datos vienen de la tabla ya exportada**, no de los derivados. Un mapa que
  recalculara podría discrepar de la tabla de su propia sección.

`sf` y `ggrepel` son dependencias **opcionales**: sin ellas el pipeline genera
todo lo demás y omite los mapas con un aviso.

---

## 6. Anatomía de la figura

De arriba hacia abajo, siempre en este orden:

```
Título: la conclusión, no la variable
Subtítulo: unidad, año, ámbito geográfico
[ área de trazado ]
Fuente: <entidad>, <año>. Cálculos propios.
```

- **El título es una afirmación**, no una etiqueta.
  `Ituango concentra el 38 % del área de la provincia`, no `Área por municipio`.
- El subtítulo carga lo que el título no debe: unidades, año, universo.
- La nota de fuente nombra la entidad y el año, y aclara si hay cálculo propio.
- Notas metodológicas (exclusiones, tratamiento de faltantes) van tras la fuente,
  en la misma línea, separadas por `·`.

---

## 7. Formato de números (Colombia)

- Separador de miles: **punto**. Decimal: **coma**. `1.234,5`
- Porcentajes: un decimal, con espacio antes del signo → `24,3 %`.
- Miles y millones se abrevian en ejes, nunca en etiquetas de valor: `1.200 k`
  en el eje, `1.234.567` en la etiqueta.
- Tasas: se explicita el denominador en el subtítulo
  (`por cada 100.000 habitantes`), nunca solo en el título.
- Cero real (`0`) y dato faltante (`—`, sin dato) **no** se representan igual.

---

## 8. Exportación

Cada figura se guarda en dos formatos, con el mismo nombre base:

| Formato | Para qué | Especificación |
|---|---|---|
| `.png` | Word, PowerPoint, revisión | 300 dpi, fondo blanco, dispositivo `ragg` |
| `.pdf` | impresión, LaTeX | vectorial, dispositivo `cairo_pdf`, fuentes embebidas |

Nomenclatura: `fig_<NN>_<slug>.{png,pdf}`, donde `NN` es el número de figura dentro
de la sección y `slug` es descriptivo en minúsculas sin tildes
(`fig_03_area_por_municipio.png`).

Ubicación: `03_Outputs/<Provincia>/<NN_Seccion>/figuras/`.

Los datos exactos de cada figura se escriben además como hoja del `.xlsx` de la
sección, para que la cifra publicada sea siempre trazable.

---

## 9. Verificación del color

Los colores de este manual pasaron el validador del método de visualización
(`validate_palette.js`), que mide en OKLab: banda de lightness, piso de chroma,
separación bajo daltonismo (protanopia y deuteranopia simuladas con
Machado-Oliveira-Fernandes 2009), piso de visión normal y contraste contra la
superficie.

| Conjunto | Resultado |
|---|---|
| Categórica (6 slots, pares adyacentes) | **PASA** — peor par CVD ΔE 8,8 (Verde selva ↔ Naranja); visión normal ΔE 29,1 |
| Categórica (3 slots, todos los pares) | **PASA** — peor par CVD ΔE 8,8; visión normal ΔE 26,2 |
| Secuencial Zafre (6 pasos) | **PASA** — lightness monótona, ΔL ≥ 0,06, hue único (1° de dispersión), extremo claro 2,03:1 |
| Divergente (3 + neutro + 3) | **PASA** en ambos brazos — monótona, hue único por brazo, extremos claros ≥ 2:1 |
| Advertencia registrada | Naranja (2,22:1) y Turquesa menta (2,08:1) quedan bajo 3:1 → exigen etiqueta de valor visible, que el sistema aplica siempre |

**Si se cambia cualquier color, se vuelve a correr el validador y se actualiza esta
tabla.** No se acepta un color «que se ve bien».

---

## 10. Equivalente CSS

Para piezas HTML (dashboards, informes web) que deban verse como las figuras:

```css
:root {
  /* Categórica — orden fijo */
  --serie-1: #4458A6;  /* Azul marino · Pantone 7455 C */
  --serie-2: #FF8F1B;  /* Naranja · Pantone 151 C */
  --serie-3: #159449;  /* Verde selva · Pantone 7482 C */
  --serie-4: #BA3A93;  /* Mora · Pantone 240 C */
  --serie-5: #46C69F;  /* Turquesa menta · Pantone 3395 C */
  --serie-6: #C24A49;  /* Baya · Pantone 7418 C */

  /* Roles de dato */
  --resalte:    #4458A6;
  --contexto:   #888C94;
  --referencia: #C24A49;

  /* Secuencial (hue del Azul Zafre) */
  --seq-1: #A1B4DB; --seq-2: #7391D0; --seq-3: #456DC5;
  --seq-4: #1E47B1; --seq-5: #02228F; --seq-6: #00015E;

  /* Divergente */
  --div-neg-3: #BB4343; --div-neg-2: #CD7671; --div-neg-1: #D5A39F;
  --div-neutro: #E8E8E6;
  --div-pos-1: #A3B0D5; --div-pos-2: #7B8FD0; --div-pos-3: #546AC0;

  /* Tinta y superficie */
  --superficie:      #FFFFFF;
  --tinta-primaria:  #292E38;
  --tinta-secundaria:#595E66;
  --tinta-terciaria: #888C94;
  --grilla:          #DCDEE1;

  --fuente: "Inter", "Roboto Serif", Arial, sans-serif;
  --tracking-titulo: -0.015em;
}
```

---

## 11. Lista de verificación antes de dar una figura por terminada

- [ ] ¿El título es una afirmación y no una etiqueta de variable?
- [ ] ¿Subtítulo con unidad, año y ámbito?
- [ ] ¿Nota de fuente con entidad y año?
- [ ] ¿Las barras están ordenadas por valor, no alfabéticamente?
- [ ] ¿Cada valor está etiquetado directamente (o hay eje legible que lo sustituya)?
- [ ] ¿Los colores salen de este manual? ¿Ninguno inventado?
- [ ] ¿Dos o más series → hay leyenda? ¿≤ 4 series → además etiquetadas?
- [ ] ¿Números en formato colombiano (`1.234,5`)?
- [ ] ¿Se generaron PNG y PDF al tamaño final, sin reescalar?
- [ ] ¿Los datos de la figura quedaron en una hoja del `.xlsx` de la sección?
- [ ] ¿Se ve bien impresa en blanco y negro o con daltonismo? (el orden de slots lo
      garantiza, pero verifíquelo si cambió de color)

---

## Fuentes

- Manual de Marca Universidad EAFIT 2025, v4.0 (noviembre 2024) — paleta oficial de
  31 tonos Pantone (pp. 31–32), tipografía Inter (pp. 38–42), Roboto Serif
  (pp. 43–46), Arial (p. 50), jerarquía tipográfica (pp. 51–52), retícula (pp. 68–76).
- Método de visualización de datos: forma según la tarea del dato, color según su
  función, verificación computable de la paleta (validador OKLab + simulación CVD
  Machado-Oliveira-Fernandes 2009).
- Referencia de contenido: `catalogo_figuras.xlsx` (83 figuras) y Anexo 1 del
  informe, en `00_Documentos/`.
