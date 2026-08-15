# 02_Code — Guía del código

Cómo está organizado el pipeline y cómo trabajar sobre él.

```
02_Code/
├── run_all.R           pipeline completo (las 11 provincias)
├── run_provincia.R     una provincia; registro de las 10 secciones
├── R/                  infraestructura compartida
│   ├── 00_config.R     rutas, tabla de provincias, dependencias
│   ├── 01_utils.R      crosswalks, agregación, escritura de tablas
│   ├── 02_tema.R       paleta, tema ggplot2, exportación de figuras
│   └── 03_mapas.R      cartografía base y geoms de mapa (sf; opcional)
├── 01_homogeneizacion/ una fuente cruda → un derivado limpio
│   └── externos/       scripts heredados que corrían fuera del repositorio
├── 03_tablas/          una sección temática → su .xlsx
├── 04_figuras/         esas tablas → figuras y mapas PNG y PDF
│   ├── 00_mapas.R      los 10 mapas de cada provincia
│   ├── DISENO.md       manual de diseño (léalo antes de tocar una figura)
│   └── catalogo_figuras.xlsx  catálogo heredado (desactualizado: ver §Huecos
│                              del README raíz)
├── 05_documento/       esqueletos de redacción por provincia
└── 99_checks/          verificación y auditoría
```

## Reglas del proyecto

1. **Las rutas se escriben en un solo lugar.** `R/00_config.R` es el único
   archivo con lógica de rutas. En cualquier otro script se usan `entrada()`,
   `derivado()` y `salida()`. Nunca una ruta absoluta ni un `setwd()`.
2. **`01_Data/00_Inputs` es de solo lectura.** Todo lo que produce el pipeline
   va a `01_Derived` o a `03_Outputs`. Y al revés: si un archivo de `01_Derived`
   no lo genera ningún script, no pertenece ahí sino a `00_Inputs/curados/`.
3. **Los derivados son Parquet, y se leen con `leer_derivado("nombre")`**, nunca
   abriendo el archivo directamente. Así cambiar de formato no obliga a tocar
   todos los scripts.
4. **Los colores y tamaños no se eligen por figura.** Salen de `R/02_tema.R`,
   que implementa `04_figuras/DISENO.md`. Si algo no encaja, se discute el
   manual; no se inventa un color en la figura.
5. **Cada figura deja sus datos en el `.xlsx` de la sección**
   (`escribir_datos_figura()`), para que la cifra publicada sea rastreable.
6. **Nada de rutas nuevas con tildes o espacios** en archivos que cree el
   pipeline. Los insumos históricos las tienen y se respetan; lo nuevo, no.

## Añadir una sección

1. Cree `03_tablas/NN_nombre.R` con una función `tabla_nombre(prov)` que
   devuelva los datos y escriba el `.xlsx` con `escribir_hoja()`.
2. Cree `04_figuras/NN_nombre.R` con `figuras_nombre(prov, tabla)`.
3. Añada la fila correspondiente a `SECCIONES` en `run_provincia.R`.

El orquestador la detecta sola: mientras el archivo no exista, la reporta como
`PENDIENTE` en vez de fallar. Los nombres de archivo y de función siguen el
patrón `NN_nombre.R` / `tabla_nombre` / `figuras_nombre`.

Use `03_tablas/01_generalidades.R` como plantilla: es la sección más corta y
tiene el patrón completo.

## Utilidades que ya existen (no las reescriba)

| Necesidad | Función |
|---|---|
| Ruta de un insumo / salida | `entrada()`, `salida()` |
| Leer o escribir un derivado (Parquet) | `leer_derivado()`, `escribir_derivado()`, `existe_derivado()` |
| Encontrar una columna pese a tildes, espacios o mayúsculas | `col()`, `col_req()` |
| Convertir texto con separadores locales a número | `a_numero()` |
| Añadir provincia y subregión por código DANE | `con_territorio()` |
| Quedarse con los municipios de una provincia | `filtrar_provincia()` |
| Filas de total (provincia, subregión, departamento) | `agregar_totales()` |
| Escribir una hoja con encabezados legibles | `escribir_hoja()` |
| Guardar los datos de una figura | `escribir_datos_figura()` |
| Formato numérico colombiano | `num_co()`, `pct_co()` |
| Barras horizontales ordenadas con resalte | `fig_barras()` |
| Título, subtítulo y fuente de una figura | `textos_fig()` |
| Exportar PNG 300 dpi + PDF vectorial | `guardar_fig()` |
| Mapa de magnitud de una provincia | `mapa_coropletico()` |
| La provincia dentro de Antioquia | `mapa_localizacion()` |
| Los 125 municipios con la provincia delineada | `mapa_departamental()` |
| Las once provincias en un mapa | `mapa_provincias()` |

`agregar_totales()` admite `como = "suma"`, `"promedio"`, `"mediana"` o
`"promedio_ponderado"` (con `pesos =`). **Las tasas y los índices se agregan
ponderados por población, no como promedio simple**: es una decisión
metodológica del proyecto, documentada en los scripts de origen.

## Verificación

```bash
Rscript 02_Code/99_checks/check_pipeline.R        # revisión estática del repo
Rscript 02_Code/99_checks/comparar_referencia.R   # cifras vs. informe publicado
ID_PROVINCIA=2 Rscript 02_Code/99_checks/hoja_contactos.R   # revisión visual

Rscript 02_Code/99_checks/auditoria_end_to_end.R      # trazabilidad de cada cifra
Rscript 02_Code/99_checks/diccionario_indicadores.R   # indicadores vs. fichas
Rscript 02_Code/99_checks/generar_tablas_anexo.R      # tablas del anexo (04_Docs)
```

La auditoría recompone cada fila de total a partir de sus municipios y comprueba
con qué fórmula se reproduce. Deja su evidencia en `04_Docs/auditoria/`, un CSV
por comprobación, comparables entre corridas.

## `01_homogeneizacion/externos/`

Scripts heredados que procesaban insumos que nunca estuvieron en el
repositorio, desde el computador de quien los escribió. No corren aquí y no los
ejecuta el pipeline: se conservan porque documentan cómo se construyeron
algunos derivados que hoy solo existen como archivo. Ver el README de esa
carpeta.
