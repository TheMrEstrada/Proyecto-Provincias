# curados — Insumos preparados a mano

Archivos que **el equipo arma y mantiene en Excel**, no los produce ningún
script. Están aquí, entre los insumos, porque eso es lo que son: entradas del
pipeline. Antes vivían en `01_Derived`, la carpeta de resultados, y eso hacía
creer que se podían borrar y regenerar — no se puede: **si se pierden, hay que
rehacerlos a mano**.

Siguen en Excel a propósito: es el formato en que se editan. Los derivados que
sí calcula el pipeline están en `01_Data/01_Derived/` y son parquet.

## Qué hay

**Agregados provinciales** (familia `*_PROVINCIAS.xlsx`) — una tabla por tema,
con los municipios de las once provincias:

`617` · `AREAPROTEGIDA` · `CULTILICITOS` · `CULTIVOS` · `EDUCACION` ·
`EMERGENCIAS` · `EVOA` · `EXTRANJEROS` · `HECHOSVICTIM` · `ICM` · `IDF` ·
`IMRC` · `IRCA` · `MDM` · `PECUARIO` · `SRDAFT`

**Otros tableros:**

| Archivo | Qué es |
|---|---|
| `ESTADO_CATASTRO.xlsx` | estado del catastro urbano y rural por municipio |
| `VALOR_AGREGADO_20152024_MUNICIPIOS.xlsx` | valor agregado municipal, serie a precios constantes de 2015 |
| `indice_gobierno_digital_2024.dta` | índice de gobierno digital y sus componentes |
| `20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx` | tablero de 33 indicadores de seguridad, salud y vivienda |
| `*_dicc.{dta,xlsx}` | salidas de scripts que corrieron fuera del repositorio, con una hoja `Data` añadida a mano |

## Cómo se leen

```r
leer_excel(entrada("curados", "MDM_PROVINCIAS.xlsx"))
```

## Al actualizarlos

1. Edite el Excel conservando **el nombre del archivo y los encabezados**: el
   código busca las columnas por nombre (tolera tildes y mayúsculas, pero no que
   una columna desaparezca).
2. Vuelva a correr el pipeline: `Rscript 02_Code/run_all.R`.
3. Compare contra el informe: `Rscript 02_Code/99_checks/comparar_referencia.R`.

## Por qué conviene ir migrándolos

Cada uno de estos archivos es un punto donde el dato depende de que alguien haga
bien un paso manual, sin registro de qué se hizo. Convertir uno en script es
sustituir ese paso por código auditable. `02_Code/01_homogeneizacion/` tiene
nueve ejemplos del patrón, y el comparador permite comprobar que la conversión
no movió ninguna cifra.

Caso especial: **`20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx`** es mitad y
mitad. De sus 36 columnas, `salud_seguridad.R` calcula tres desde fuentes crudas
y las otras 33 vienen de este archivo. El script lee de aquí y escribe el
resultado en `01_Derived`, así que ya no puede reescribirse encima como hacía el
código en Stata.
