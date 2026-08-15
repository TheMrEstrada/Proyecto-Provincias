# 01_Derived — Datos derivados

Resultados intermedios del pipeline, **todos en Parquet**. Se pueden borrar
enteros y regenerar con:

```bash
Rscript 02_Code/run_all.R
```

No edite estos archivos a mano: el pipeline los sobrescribe. Si un dato hay que
corregirlo a mano, no pertenece aquí sino a `01_Data/00_Inputs/curados/`.

## Por qué Parquet

Antes esta carpeta mezclaba `.dta` y `.xlsx`, y 17 archivos existían en los dos
formatos a la vez. Un solo formato, columnar y comprimido, resolvió tres cosas:

| | antes | ahora |
|---|---|---|
| Peso | 115 MB | **20 MB** |
| Formatos | `.dta` + `.xlsx` mezclados y duplicados | solo `.parquet` |
| Tipos de dato | se perdían al pasar por Excel | se conservan |

Parquet además se lee igual desde R, Python y Stata 18+, así que el formato no
ata el proyecto a una herramienta.

## Cómo se leen y se escriben

En el código **no se abren estos archivos directamente**: hay dos funciones que
esconden el formato, de modo que cambiarlo mañana no obligue a tocar 30 scripts.

```r
d <- leer_derivado("codigos_provincias")      # sin extensión
escribir_derivado(d, "codigos_provincias")    # escribe .parquet
existe_derivado("percepcion_seguridad")       # TRUE / FALSE
```

`leer_derivado()` lee el parquet; si solo encontrara un `.dta` o `.xlsx`
heredado, lo lee igualmente y avisa, para que una conversión a medias no rompa
el pipeline.

Desde fuera de R:

```python
import pandas as pd
pd.read_parquet("01_Data/01_Derived/codigos_provincias.parquet")
```

## Qué hay aquí

| Archivo | Lo produce |
|---|---|
| `codigos_provincias`, `subreg_completo` | `crosswalk_territorial.R` |
| `ECV_nbi_pobreza`, `ECV_raw` | `ecv.R` |
| `ECV_oficial_agregados` | `ecv_oficial_agregados.R` |
| `estructura_productiva`, `imca_2022` | `deyc.R` |
| `20250506 EDUCACION` | `educacion.R` |
| `20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA` | `salud_seguridad.R` |
| `infraestructura_internet_2025` | `infraestructura_internet.R` |
| `seguridad_policia` | `seguridad_policia.R` |
| `poblacion_total_2025`, `poblacion_municipal_total_2025` | `poblacion_municipal.R` |
| `percepcion_seguridad` | `percepcion_seguridad.R` |
| `uso_del_suelo_pota` | `uso_suelo.R` |

Todos tienen productor: **si un archivo aparece aquí sin script que lo genere,
está en el lugar equivocado.** Lo que se arma a mano va a
[`01_Data/00_Inputs/curados/`](../00_Inputs/curados/).

`maps/` guarda la cartografía derivada (shapefiles), que no es tabular y por eso
no va en parquet.

## Un cambio de estructura que conviene conocer

`seguridad_policia` era un Excel de **ocho hojas**, una por delito y año. Como
todas tenían la misma estructura, ahora es **una sola tabla larga** con las
columnas `delito` y `anio`. Es el mismo dato, filtrable y sin repetir el esquema
ocho veces:

```r
policia <- leer_derivado("seguridad_policia")
subset(policia, delito == "homicidios" & anio == 2025)
```

## Nombres heredados

Dos archivos conservan un nombre que induce a error, porque cambiarlo obligaría
a tocar a todos sus lectores:

- **`20250506 EDUCACION`** — la fecha es de la entrega original de mayo de 2025;
  el contenido se ha actualizado desde entonces. Lleva un espacio en el nombre.
- **`20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA`** — dice "DEFICT" por "DÉFICIT".
