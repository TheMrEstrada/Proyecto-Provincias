# Proyecto Provincias

Datos, código y salidas del diagnóstico territorial para la formulación de los
**Planes Estratégicos Provinciales** de Antioquia: 11 provincias, 90 municipios,
10 secciones temáticas por provincia.

El pipeline produce, para cada provincia, un juego de tablas en Excel y de
figuras listas para el informe.

---

## Cómo correr el pipeline

Requiere **R ≥ 4.3**. La primera vez, instale las dependencias:

```r
install.packages("renv"); renv::restore()
```

Después, desde la raíz del repositorio:

```bash
# Una provincia (2 = Bioenergética del Norte)
ID_PROVINCIA=2 Rscript 02_Code/run_provincia.R

# Solo algunas secciones de una provincia
ID_PROVINCIA=2 SECCIONES=01,02 Rscript 02_Code/run_provincia.R

# Todas las provincias, de principio a fin
Rscript 02_Code/run_all.R
```

Desde RStudio, abra el proyecto en la raíz y:

```r
Sys.setenv(ID_PROVINCIA = "2")
source("02_Code/run_provincia.R")
```

No hay rutas que editar. El pipeline encuentra la raíz solo; si necesita
fijarla (por ejemplo en un servidor), defina la variable de entorno
`PROVINCIAS_ROOT`.

### Las 11 provincias

| id | Provincia | id | Provincia |
|---:|---|---:|---|
| 1 | Agroindustrial del Occidente | 7 | De la Paz |
| 2 | Bioenergética del Norte de Antioquia | 8 | San Juan |
| 3 | Del Río Grande | 9 | Minero Agroecológica |
| 4 | Turística y Agroecológica | 10 | Penderisco y Sinifana |
| 5 | Agua, Bosques y Turismo | 11 | Área Metropolitana |
| 6 | Cartama | | |

Definidas en un solo lugar: la tabla `PROVINCIAS` de
[02_Code/R/00_config.R](02_Code/R/00_config.R).

---

## Cómo está organizado

```
00_Documentos/     informes, fichas técnicas, documentos metodológicos
01_Data/
  00_Inputs/       fuentes crudas — solo lectura, nadie escribe aquí
    curados/       tableros que el equipo arma a mano en Excel
  01_Derived/      datos que produce el pipeline (todos en Parquet)
02_Code/
  run_all.R        pipeline completo
  run_provincia.R  una provincia
  R/               configuración, utilidades, sistema visual y cartografía
  01_homogeneizacion/  cada fuente cruda → un derivado limpio
  03_tablas/           una sección temática → su .xlsx
  04_figuras/          esas tablas → figuras y mapas PNG y PDF
  05_documento/        diagnósticos provinciales en Word
  06_comparativo/      panel y documento comparativo de las once provincias
  99_checks/           verificación y auditoría del pipeline
03_Outputs/        salidas por provincia (se generan; no se versionan)
04_Docs/           anexo metodológico, auditoría y plan de escritura
99_Legacy/         pipeline anterior en Stata y material retirado
tests/             referencia de validación
```

### El flujo

```
01_Data/00_Inputs         fuentes crudas (DANE, Gobernación, Policía, MinSalud…)
        │
        │  02_Code/01_homogeneizacion/     una fuente → un derivado limpio
        ▼
01_Data/01_Derived        datos homogeneizados a nivel municipal
        │
        │  02_Code/03_tablas/              filtro por provincia, agregados,
        │                                  totales de provincia/subregión/depto.
        ▼
03_Outputs/<Provincia>/<NN_Seccion>/seccion.xlsx
        │
        │  02_Code/04_figuras/             ggplot2 y sf según DISENO.md
        ▼
03_Outputs/<Provincia>/<NN_Seccion>/figuras/fig_NN_*.png · mapa_NN_*.png (+ .pdf)
```

Cada figura y cada mapa dejan sus datos exactos en una hoja del `.xlsx` de la
sección, para que cualquier cifra publicada se pueda rastrear hasta su origen.

Los mapas corren **después** de las diez secciones y leen la tabla que la sección
acaba de escribir: si recalcularan desde los derivados podrían discrepar de ella,
y el informe tendría dos cifras para el mismo hecho.

Los datos intermedios (`01_Derived`) están todos en **Parquet**: un solo formato,
comprimido y tipado, legible desde R, Python y Stata 18+. En el código se leen
con `leer_derivado("nombre")`, sin extensión.

### Las 10 secciones

`01_Generalidades` · `02_Demografia` · `03_Ordenamiento` · `04_Gobernabilidad` ·
`05_Economia` · `06_Desarrollo_Rural` · `07_Ambiental` · `08_Educacion` ·
`09_Salud` · `10_Seguridad`

---

## Figuras y mapas

Todas las figuras siguen un único sistema visual, documentado en
[02_Code/04_figuras/DISENO.md](02_Code/04_figuras/DISENO.md): paleta oficial
EAFIT verificada para daltonismo y contraste, tipografía Inter, tamaños al ancho
de caja del informe, formato numérico colombiano y nota de fuente obligatoria.

Salen en dos formatos: **PNG a 300 dpi** (Word, PowerPoint) y **PDF vectorial**
(imprenta, LaTeX), ambos al tamaño final — no hay que reescalarlas.

Los **mapas** siguen las mismas reglas (rampa secuencial para magnitud, gris para
el dato ausente, sin ejes ni retícula) y están en
[02_Code/R/03_mapas.R](02_Code/R/03_mapas.R). Requieren `sf` y `ggrepel`, que son
dependencias **opcionales**: sin ellas el pipeline genera todo lo demás y omite
los mapas con un aviso.

```r
install.packages(c("sf", "ggrepel"))
```

Si va a crear o modificar una figura, lea ese manual antes: los colores y
tamaños no se eligen figura por figura.

---

## Verificación

```bash
# Revisión estática del repositorio (rutas, insumos, nombres, secciones)
Rscript 02_Code/99_checks/check_pipeline.R

# Compara las tablas generadas contra las cifras del informe publicado
Rscript 02_Code/99_checks/comparar_referencia.R

# Junta las figuras de una provincia en una imagen, para revisarlas de un vistazo
ID_PROVINCIA=2 Rscript 02_Code/99_checks/hoja_contactos.R

# Auditoría de trazabilidad: procedencia, huella de las fuentes, cobertura
# municipal, recomputación de cada agregado, rangos y trazabilidad de figuras
Rscript 02_Code/99_checks/auditoria_end_to_end.R

# Qué indicadores publica el pipeline y cuáles tienen ficha técnica
Rscript 02_Code/99_checks/diccionario_indicadores.R

# Verifica que ninguna cifra del texto de los informes carezca de procedencia,
# y mide su propio poder de detección inyectando cifras falsas
Rscript 02_Code/99_checks/auditoria_redaccion.R
```

Estado actual de la validación: **43 de 43 columnas reproducen el informe**.

La auditoría escribe su evidencia en [04_Docs/auditoria/](04_Docs/) — un CSV por
comprobación, comparables entre corridas — y su lectura de un vistazo en
`04_Docs/auditoria/RESUMEN.md`. El anexo metodológico
([04_Docs/anexo_metodologico.pdf](04_Docs/)) documenta fuentes, protocolos de
uso, reglas de limpieza y agregación, y la estrategia de actualización.

El Anexo 1 (`00_Documentos/`) es el informe entregado para la provincia
Bioenergética del Norte: 52 tablas ya curadas. Sirve de patrón para validar que
la migración a R reproduce las cifras. La referencia se extrae con:

```bash
python3 tests/extraer_referencia_anexo1.py
```

---

## Huecos conocidos

Cosas que hay que saber antes de confiar en un resultado.

**Fuentes que no están en el repositorio.** Cinco archivos pesan demasiado para
GitHub y hay que pedírselos al equipo; los scripts que los usan se detienen con
un mensaje que dice cuál falta. Ver
[01_Data/00_Inputs/README.md](01_Data/00_Inputs/README.md).

**Veinticinco insumos se arman a mano en Excel** y ningún script los regenera
(la familia `*_PROVINCIAS.xlsx` y algunos tableros más). Es el mayor hueco de
reproducibilidad que queda: si uno se pierde, hay que rehacerlo a mano. Están
separados del resto en
[01_Data/00_Inputs/curados/](01_Data/00_Inputs/curados/), precisamente para que
no se confundan con lo que sí se regenera.

**Algunos insumos son más nuevos que el informe.** Las cifras de salud
(bajo peso, vectores, suicidios, aseguramiento) usan cortes de 2023 y de
diciembre de 2025, frente al 2024 publicado; el valor agregado está a precios
constantes de 2015 y el Anexo se publicó a corrientes; el uso del suelo rural y
las víctimas del conflicto vienen de versiones posteriores de la fuente. El
pipeline da la cifra actual, que no siempre es la del informe de 2026.

**Dos decisiones metodológicas cambian resultados frente al informe.** Donde el
Anexo promedió tasas municipales, el pipeline calcula la tasa agregada
(ponderada por población o por nacimientos, según el indicador), que es lo
correcto y lo que pide el código original. Y `agregar_totales()` define la
subregión como los municipios que el DANE le asigna, mientras el informe a veces
suma solo los de la provincia que están en esa subregión.

**Erratas del informe ya verificadas** (registradas en el comparador, no hay que
volver a perseguirlas): la Tabla 50 intercambia las filas de Angostura y Anorí
en mortalidad infantil, y la tabla de valor agregado hace lo mismo con esos dos
municipios; Toledo aparece con 122 km² donde la fuente da 122,578.

**Nombres que no se deben "arreglar".** El nombre de la provincia 5 tenía una
errata (`POVINCIA`) que el código Stata daba por buena; el Excel ya se corrigió,
así que ese código dejaría hoy a la provincia 5 sin municipios. El pipeline en R
empareja de forma tolerante y no depende de la grafía. Y
`20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA` conserva el error "DEFICT" porque es
el archivo vigente.

**Cuatro derivados no se pueden rehacer desde la fuente.** Los scripts de
[02_Code/01_homogeneizacion/externos/](02_Code/01_homogeneizacion/externos/)
documentan cómo se construyeron los kilómetros de vía (IDV y VPC), las tasas de
suicidio e intento, el índice de envejecimiento y el IRCA, pero leen rutas del
computador de quien los escribió y no corren aquí. Dos de ellos, además, no
contienen ninguna instrucción de escritura. Esos indicadores se publican sin que
exista en el repositorio código capaz de reproducirlos.

**La cobertura neta educativa supera el 100 %** en 284 de los 1.750 registros
municipio-año de la fuente, con un máximo de 186,97 %. Una cobertura *neta* no
puede exceder el 100 % por definición: o la serie es de cobertura bruta, o
matrícula y proyección de población no son consistentes. El pipeline publica el
dato sin corregirlo —corregirlo sería inventar— y las figuras y mapas de esa
sección llevan una nota que lo advierte. Falta verificarlo con el MEN.

**Solo una de las once provincias tiene validación externa.** El comparador
contrasta 43 columnas contra el Anexo 1 de la provincia 2 y las 43 reproducen el
informe. Para las otras diez no hay informe publicado contra el cual contrastar:
su corrección descansa en que el código es el mismo y en la auditoría interna.

**330 indicadores publicados, 12 con ficha técnica.** Las 65 fichas del
repositorio describen la familia de indicadores de la ECV y del Anuario, no lo
que el diagnóstico reporta. Ver
[04_Docs/anexo_metodologico.pdf](04_Docs/) §7.

**Documentación desactualizada.** `02_Code/04_figuras/CATALOGO_NOTAS.md` describe
una decisión ya superada (gráficos nativos de Excel, sin ggplot2) y
`catalogo_figuras.xlsx` marca 78 figuras como «hecho» cuando el código genera 56
más 10 mapas por provincia. Varias cabeceras de scripts de tablas declaran rutas
en `01_Data/01_Derived` para insumos que hoy viven en `01_Data/00_Inputs/curados`.

---

## Pipeline anterior en Stata

El diagnóstico se producía antes con Stata. Ese código se conserva en
[99_Legacy/](99_Legacy/) con la explicación de qué hacía cada pieza y por qué se
retiró. No lo ejecuta nada; está para poder auditar la migración.

---

## Historial de cambios

**2026-08-08** Reestructuración completa del repositorio y migración del
pipeline a R de punta a punta:

- Un solo comando produce las 11 provincias: 110 juegos de tablas y 704 figuras
  en unos 6 minutos. Antes había que correr Stata y luego R, en ese orden, y
  editar rutas a mano en cada `.do`.
- Rutas portables: se acabaron las cuatro raíces `D:\` y `C:\Users\…` de cuatro
  máquinas distintas.
- Sistema de diseño de figuras documentado y verificado
  ([DISENO.md](02_Code/04_figuras/DISENO.md)): paleta EAFIT validada para
  daltonismo y contraste, salida en PNG 300 dpi y PDF vectorial.
- Validación automática contra el informe publicado: **43 de 43 columnas**
  reproducen el Anexo 1.
- Limpieza: ~117 MB de duplicados exactos eliminados, 14 archivos de basura
  retirados del control de versiones, y el código y los datos obsoletos movidos
  a [99_Legacy/](99_Legacy/).
- Errores del pipeline anterior corregidos: la provincia 5 habría desaparecido
  al actualizarse su Excel, se perdían 47 de 102 títulos mineros, y los
  ponderadores de salud estaban corrompidos por un desplazamiento de columnas.
  Detalle en [99_Legacy/codigo/stata_pipeline/README.md](99_Legacy/codigo/stata_pipeline/README.md).

**2026-04-28** Nueva rama "actualización": primeros archivos actualizados de las
bases de datos. Main se mantiene con los datos "de base".

**2026-04-23** Actualización de "Categorias_datos_y_nuevas_fuentes.xlsx": fuentes
identificadas para datos de seguridad.

**2026-04-14** Actualización de "Categorias_datos_y_nuevas_fuentes.xlsx"
finalizando la adición de nuevas fuentes recomendadas.

**2026-04-13** Nueva carpeta "Informes y avances" con la categorización propuesta
de los datos y el informe de estado de datos.

**2026-04-10** `Inventario_Variables_v_2`: diccionario e inventario de datos
original más las intervenciones del equipo.

**2026-04-09** Se suben los archivos originales de las Antioquias.
