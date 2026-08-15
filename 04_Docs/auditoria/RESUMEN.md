# Auditoría de trazabilidad — Proyecto Provincias

Generado por `02_Code/99_checks/auditoria_end_to_end.R` el 2026-08-10 18:31.
Cada afirmación de este resumen tiene su CSV de respaldo en esta misma carpeta.

## A. Procedencia

- Derivados en `01_Derived`: **15**
- Derivados sin script que los produzca: **0**
- Insumos curados (armados a mano, sin productor): **26**
- Curados que ningún script lee: **4** — 20260504_SEGURIDAD_SALUD_DEFICT_VIVIENDA.xlsx, infraestructura_municipios_dicc.xlsx, poblacion_municipal_total_2025_dicc.xlsx, suicidios_e_intentos_medias_dicc.xlsx
- Scripts en `externos/` con rutas de otra máquina: **6 de 7**
- Scripts en `externos/` que no escriben ninguna salida: **3** — mortalidad_iam.R, suicidios_e_intentos_medias.R, suicidios_e_intentos.R

## B. Inventario

- Insumos citados por el código: **45**
- Presentes en el clon: **43**; ausentes: **2**
- Huella y fecha de cada uno: `B1_inventario_insumos.csv`

## C. Cobertura municipal

- Hojas municipales auditadas: **726**
- Hojas con municipios AJENOS a la provincia: **0**
- Hojas con municipios FALTANTES: **46**

Un municipio ajeno sería una cifra atribuida a un territorio que no es el suyo;
uno faltante es un silencio que el lector puede confundir con un cero.
El detalle por hoja está en `C1_cobertura_municipal.csv`.

## D. Agregados

- Celdas agregadas auditadas: **13592**, de las cuales **7730** son de ámbito provincial (las únicas verificables
  con la propia hoja: subregión y departamento se calculan sobre los 125
  municipios de Antioquia, que no aparecen en la tabla provincial).

Fórmula que reproduce cada celda provincial:

  - `suma`: 4153 (53.7 %)
  - `OTRA`: 2834 (36.7 %)
  - `promedio`: 579 (7.5 %)
  - `ponderado_poblacion`: 144 (1.9 %)
  - `mediana`: 20 (0.3 %)
- **Bandera roja** (ni fórmula conocida ni dentro del rango municipal): **4**
  - coca / Coca sobre área del municipio (%) (2 celdas)
  - detalle / Participación del área protegida (%) (2 celdas)

`OTRA` no significa error: significa que la fórmula no es ninguna de las
cuatro estándar (suma, promedio simple, mediana, ponderado por población).
El pipeline usa a propósito otros ponderadores —nacimientos, población
escolar, área, matrícula— y esos casos caen aquí. Lo que **sí** exige
explicación una por una es la bandera roja.

## E. Rangos

- Columnas con valores implausibles: **14**
  - Agroindustrial del Occidente / educacion / Cobertura neta: proporción fuera de [0,1]
  - Bioenergética del Norte de Antioquia / educacion / Cobertura neta: proporción fuera de [0,1]
  - Del Río Grande / educacion / Cobertura neta: proporción fuera de [0,1]
  - Del Río Grande / _mapa08_cobertura_neta / Cobertura neta: proporción fuera de [0,1]
  - Turística y Agroecológica / educacion / Cobertura neta: proporción fuera de [0,1]
  - Agua, Bosques y Turismo / educacion / Cobertura neta: proporción fuera de [0,1]
  - Agua, Bosques y Turismo / _mapa08_cobertura_neta / Cobertura neta: proporción fuera de [0,1]
  - Cartama / educacion / Cobertura neta: proporción fuera de [0,1]
  - San Juan / educacion / Cobertura neta: proporción fuera de [0,1]
  - Minero Agroecológica / educacion / Cobertura neta: proporción fuera de [0,1]
  - Minero Agroecológica / _mapa08_cobertura_neta / Cobertura neta: proporción fuera de [0,1]
  - Penderisco y Sinifana / educacion / Cobertura neta: proporción fuera de [0,1]
  - Área Metropolitana / educacion / Cobertura neta: proporción fuera de [0,1]
  - Área Metropolitana / _mapa08_cobertura_neta / Cobertura neta: proporción fuera de [0,1]

## F. Figuras

- Figuras exportadas: **814**
- Sin PDF vectorial: **0**
- Sin hoja de datos trazable en el `.xlsx`: **0**
- Llamadas a `guardar_fig()` en el código: **66**
- Sin nota de fuente: **0**
- Sin subtítulo: **0**
- Sin `escribir_datos_figura()` cerca: **0**

## G. Catálogo

- Filas del catálogo: **83**
- Marcadas «hecho»: **78**
- Marcadas «fuera de alcance»: **5**
- Figuras que el código R genera: **66**

