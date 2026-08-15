# 00_Inputs — Datos crudos

Fuentes originales, **tal como llegaron**. Esta carpeta es de solo lectura para
el pipeline:

- Ningún script debe **escribir** aquí. Los resultados intermedios van a
  `01_Derived/`. (El pipeline anterior sí dejaba dos derivados en esta carpeta,
  `códigos_provincias.dta` y `ECV_raw.dta`; ya no.)
- Ningún archivo se edita ni se limpia a mano. Toda transformación se hace en
  `02_Code/01_homogeneizacion/`, para que quede registrada.
- Al actualizar una fuente, se reemplaza el archivo conservando el nombre y se
  anota en el historial del README de la raíz. Si el nombre cambia, hay que
  actualizar el script que lo lee.

El inventario de variables con su definición y fuente está en
`INVENTARIO_VARIABLES_v_2.xlsx` (la versión sin `_v_2` es anterior; el
pipeline de consolidación todavía lee esa).

---

## Fuentes ausentes del clon ⚠️

Cuatro archivos no están versionados (pesan demasiado para GitHub) y hay que
pedírselos al equipo. Sin ellos, las partes del pipeline que los usan no corren:

| Archivo | Lo necesita |
|---|---|
| `PPED-AreaSexoEdadMun-2018-2042_VP.xlsx` | homogeneización de población |
| `EMPAQUETAMIENTO_FIJO_3.csv` | homogeneización de infraestructura de internet |
| `Data anonimizada encuesta percepcion 2018-2025.xlsx` | percepción de seguridad (sección 10) |
| `Indicadores_ECV2023.xlsx` | agregados oficiales de la ECV |
| `MICRODATOS ECV 2023.dta` | procesamiento de microdatos ECV |

Están listados en `.gitignore` para que nadie los suba por accidente.

---

## Estructura

- **Raíz** — la mayoría de fuentes municipales y departamentales.
- **`Actualización/Fuentes/`** — fuentes nuevas o actualizadas (2026). El
  pipeline vigente ya consume algunas desde aquí, así que la carpeta no es un
  borrador: es parte del flujo.
- **`TABLAS MUNICIPALES octubre/`** — insumos POTA por municipio, agrupados en
  ocho carpetas. Los lee la homogeneización de uso del suelo. (Existía una copia
  byte a byte llamada `POTA/`; se eliminó.)
- **`Fichas territoriales`** (en `00_Documentos/Fichas Tecnicas/POTA/`) —
  documentos de contexto, no los lee ningún script.
- **`maps/`** — cartografía base (shapefiles MGN y municipios de Antioquia).
  Falta el `.cpg` en los shapefiles, lo que puede romper los acentos al leerlos
  con `sf`; si pasa, indique el encoding explícitamente al leer.

## Nombres con espacios y tildes

Muchos archivos tienen espacios, tildes o mayúsculas inconsistentes
(`POBLACION MUNICIPAL.xlsx`, `códigos_municipios_clean.dta`,
`Pérdida de cobertura árborea.xlsx`). **No los renombre** sin actualizar los
scripts: son el contrato con el código y con las entregas del equipo. El
pipeline en R los maneja bien; al escribir código nuevo, use `entrada()` y
`col_req()`, que toleran las variantes de escritura de los encabezados.
