# Plan de trabajo — Pipeline de figuras en R (estado actualizado)

**Proyecto:** Diagnóstico territorial PEMP "Provincias de Antioquia"
**Fase:** Automatización de figuras (no-mapa) con R, parametrizada por `id_provincia` (1–11).
**Provincia de validación:** 4 (Turística y Agroecológica), también 3 (Río Grande).
**Estado global:** pipeline construido y corriendo de punta a punta. 78/83 figuras hechas.

---

## 1. Contexto

- El flujo Stata (`02_Code/Tablas_Diagnostico/00_master.do` + 10 sectoriales) está completo y
  exporta, por provincia, un `.xlsx` por sección en `03_Outputs/<provincia>/<NN_Sección>/`, con una
  hoja por figura/tabla (incluye filas de agregado: TOTAL/PROMEDIO PONDERADO provincia/subregión/
  departamento).
- Referencia de figuras: **Anexo 1** (imágenes de alta calidad, con el título dentro de la imagen;
  tablas con formato Word). Registro: hoja *Figuras* de la sistematización. Mapeo consolidado:
  `catalogo_figuras.xlsx`.

## 2. Decisiones (finales)

1. **Salida:** gráficos **nativos de Excel**, editables, dentro del mismo `.xlsx` del flujo
   (datos de cada gráfico en hojas auxiliares ocultas `_fig_*`/`_f_*`).
2. **Todo nativo, sin ggplot2/imágenes.** Pirámide = barras divergentes (hombres en negativo);
   dumbbell = aproximación nativa (2 series de puntos + líneas de conexión). Fallback a imagen solo
   como decisión puntual futura, si hiciera falta.
3. **Editabilidad primero** + estilo homogéneo con plantilla común (`R/01_tema.R`).
4. **Orden Stata → R** (obligatorio; el sectorial hace `capture erase`). Mismo `.xlsx` (validado).
5. **Parametrizado por `id_provincia`**; raíz del proyecto **autodetectada**.
6. **5 figuras fuera de alcance** (sin fuente en el export): fig11 (POT), fig14 (POMCA/PORH),
   fig56/57 (suelo rural), fig62 (clima).

## 3. Arquitectura (implementada)

`02_Code/R_Figuras/`:
- `run_provincia.R` — orquestador; elige provincia (`id_provincia <- N` o `ID_PROVINCIA`), recorre
  las 10 secciones.
- `R/00_setup.R` — instala/carga `openxlsx2` (≥1.28) + `encharter` (≥0.10) en R fresco.
- `R/00_config.R` — valida provincia; autodetecta raíz (sube hasta `03_Outputs`; escape
  `PROVINCIAS_ROOT`).
- `R/01_tema.R` — paleta (navy `#1F3864`, azul `#4472C4`, claro `#9DC3E6`), tipografía, paleta de series.
- `R/02_utils.R` — helpers de figura + utilidades de lectura/robustez.
- `R/fig/NN_<seccion>.R` — un módulo por sección (01…10).

### Toolkit de helpers (cubre todos los tipos del catálogo)

| Helper | Uso |
|---|---|
| `enc_hbar` | Barra horizontal: simple, apilada 100%, apilada absoluta, agrupada. |
| `enc_piramide` | Pirámide poblacional (divergente). |
| `enc_line` | Series temporales. |
| `enc_pie` | Torta / dona. |
| `enc_scatter` | Dispersión (solo puntos). |
| `enc_dumbbell` | Dumbbell nativo (puntos + conector high-low). |
| `estilo_tabla` | Tabla tipo Anexo (encabezado navy, bordes, formatos, agregados resaltados, oculta bookkeeping). |

Utilidades: `leer_municipios` (quita agregados por Código DANE), `pick`/`pick_name` (insensible a
acentos), `ultimo_anio` (multi-año), `.anchor`, `.try` (aísla fallos por figura).

## 4. Fases (todas completadas)

- **Fase 0 — Entorno + spike.** ✔ R instalado en sandbox (vía git; CRAN bloqueado). Validado que
  `openxlsx2`+`encharter` insertan chart nativo editable en el `.xlsx` de Stata con round-trip
  intacto.
- **Fase 1 — Piloto Demografía.** ✔ 4 gráficos (urbana-rural apilada 100%, densidad, pirámide,
  envejecimiento) + 3 tablas, aprobados.
- **Fase 2 — Inventario completo.** ✔ `catalogo_figuras.xlsx`: 83 no-mapa mapeadas
  (figura→sección→hoja→columnas→tipo→helper→estado).
- **Fase 3 — Toolkit + secciones.** ✔ Helpers completados y probados; módulos `fig/01…10` escritos;
  corrida end-to-end sin errores. 78 figuras generadas.

## 5. Resumen del catálogo

- **83 figuras no-mapa** = 53 gráficos + 30 tablas.
- **Salida:** 53 nativo + 25 tablas construidas; **0 imágenes**. (5 fuera de alcance).
- **Estado:** 78 hechas, 5 fuera de alcance.

## 6. Criterios de datos

- **Multi-año:** gráficos y tablas de un solo año usan el **último año** (MDM 2024; ICM, Ley 617,
  Valor Agregado el más reciente). Excepción: mortalidad infantil como serie 2020–2024.
- **Filas agregadas:** detectadas por Código DANE vacío; fuera de los gráficos por municipio,
  resaltadas en tablas.

## 7. Cómo correr

1. Correr el flujo Stata de la provincia.
2. Elegir provincia en `run_provincia.R` (`id_provincia <- N`, 1–11).
3. `Rscript 02_Code/R_Figuras/run_provincia.R` (o *source* en RStudio).

## 8. Pendientes / a revisar

- **fig43 / fig59** (torta) y **fig82** (barra vs torta): confirmar tipo/curaduría.
- **Dumbbell (fig34/36/38):** los conectores se ven en **Excel** (no en previsualizadores).
- **fig61:** ajustada a solo rendimiento (barra), ya sin "área perdida".
- **5 fuera de alcance:** pendientes de fuente de datos (POT, POMCA/PORH, suelo rural, clima).

## 9. Riesgos / notas

- LibreOffice no es fiable para previsualizar ejes divergentes, formatos de etiqueta y conectores
  high-low; el juez es Excel.
- La vista de la carpeta conectada puede quedar desactualizada cuando Cowork corre en la nube; ante
  cambios recientes en un export, forzar lectura fresca.
- `openxlsx2` usa semántica de copia: capturar siempre el retorno (`wb <- wb_add_*(wb, ...)`).
