# externos — Scripts heredados que no ejecuta el pipeline

Scripts en R que procesaban insumos desde el computador de quien los escribió,
no desde este repositorio. **El pipeline no los corre** y no hace falta que
corran para generar los informes: los derivados que produjeron están en
`01_Data/01_Derived` y se consumen tal cual.

Se conservan porque son la única documentación de cómo se construyeron esos
derivados. Si hay que actualizarlos, aquí está la lógica, pero habrá que
adaptarla al patrón del pipeline (`entrada()`, `derivado()`, sin `setwd()`).

## Por qué no corren aquí

| Script | Problema |
|---|---|
| `datalake_gestion_publica.R` | rutas `C:/Users/espin/…`; el insumo no está en el repositorio |
| `infraestructura.R` | ídem, y además hace `setwd()` a shapefiles de **otro proyecto** ("Barranquilla_parceros") |
| `irca.R` | ídem; el bloque de normalización de nombres está copiado tres veces dentro del mismo archivo |
| `poblacion_municipal.R` | ídem. **No confundir** con `../poblacion_municipal.R`, que es el script vigente del pipeline |
| `suicidios_e_intentos.R` | ídem, y no escribe nada: su `write.xlsx` está comentado |
| `suicidios_e_intentos_medias.R` | ídem; el archivo termina en `# Base final ----`, sin instrucción de escritura |
| `mortalidad_iam.R` | **este sí usa rutas del repositorio y sí corre**, pero su único consumidor era `00_BuildData.do`, que se retiró a `99_Legacy/` |

## El paso manual que falta

Los derivados de estos scripts llevan el sufijo `_dicc` (`IRCA_dicc`,
`i_datalake_ges_pub_dicc`, `infraestructura_municipios_dicc`,
`mortalidad_iam_dicc`, `poblacion_municipal_total_2023_dicc`,
`suicidios_e_intentos_medias_dicc`). Ese sufijo **no lo pone ningún script**: al
`.csv`/`.xlsx` que producían se le añadió a mano una hoja `Data` en Excel, y esa
versión es la que lee el pipeline. Es un eslabón manual sin documentar; téngalo
en cuenta si va a rehacer alguno.
