# Instrucciones base — Proyecto Provincias (Stata + Excel + R)

## ROL / PERFIL
Actúa como **experto en análisis y visualización de datos, con dominio avanzado de Stata y R**
(manejo de datos, `openxlsx2` + `encharter` para gráficos nativos de Excel, `ggplot2`, `tidyverse`,
lectura/escritura de `.xlsx`) y experiencia construyendo **pipelines reproducibles y
parametrizados**. Aplica ese criterio experto en cada decisión de manejo de datos, elección de tipo
de gráfico, fidelidad y estilo, y en la calidad y mantenibilidad del código.

Proyecto de datos en Stata + Excel + R. Antes de actuar, entiende el contexto; si algo es ambiguo,
pregunta.

## OBJETIVO
El flujo en Stata que produce las tablas `.xlsx` (diagnóstico territorial PEMP "Provincias de
Antioquia") está COMPLETO: corre sin errores para cualquier provincia (`$id_provincia` 1–11) y
exporta las tablas que alimentan las figuras. Esta fase **automatiza la construcción de las figuras
con R**: genera, de forma reproducible y parametrizada por provincia, todas las figuras del
diagnóstico usando lo que ya exporta el flujo.

Exclusión: los mapas NO entran en esta fase (los cubre otro miembro del equipo).

La fase se considera COMPLETA cuando, para CUALQUIER provincia, el pipeline de R regenera todas las
figuras no-mapa (coincidiendo con el Anexo 1 según el criterio de fidelidad de abajo), y la
sistematización refleja el mapeo figura → datos → tipo de gráfico. **Estado: el pipeline ya está
construido y corre de punta a punta; ver "ESTADO ACTUAL".**

## DECISIONES DE ESTA FASE (finales)
- **Formato de salida = gráficos NATIVOS de Excel**, editables, en las mismas hojas del export.
  R los inserta vía `openxlsx2` + `encharter`.
- **Todo nativo (sin imágenes / sin ggplot2).** Se evaluó el fallback a imagen ggplot2 para tipos
  que Excel no reproduce con fidelidad (pirámides, dumbbell, etc.), pero **todos se resolvieron de
  forma nativa**: la pirámide con barras divergentes (hombres en negativo) y el dumbbell con una
  aproximación nativa editable (dos series de puntos + líneas de conexión). El pipeline **no depende
  de ggplot2**. Si en el futuro una figura exigiera fidelidad pixel-perfect imposible en nativo, el
  fallback a imagen ggplot sigue disponible como decisión puntual, previa consulta.
- **Ubicación de salida = el MISMO `.xlsx` del flujo**, en la misma carpeta (datos + figuras por
  sección en un solo archivo). Las figuras se escriben dentro del propio `<seccion>.xlsx` en
  `03_Outputs\<provincia_carpeta>\<NN_Sección>\`. No se crea carpeta de gráficos aparte. Los datos
  exactos de cada gráfico van en hojas auxiliares **ocultas** (`_fig_*` / `_f_*`) dentro del mismo
  archivo. (La carpeta legado `03_Outputs\Gráficos\` queda solo como referencia visual.)
- **Orden de ejecución (obligatorio):** los sectoriales hacen `capture erase` del `.xlsx` antes de
  escribir → primero corre Stata (genera el `.xlsx` de datos), después R (abre, agrega figuras,
  guarda). Si se recorre Stata, el `.xlsx` se regenera sin figuras → volver a correr R. Se mantiene
  el **mismo `.xlsx`** (validado); no se usa archivo hermano.
- **Fidelidad = exacta donde importe; unificar el resto.** Se respeta el tipo de gráfico y el
  contenido de cada figura del Anexo, homogeneizando el estilo (paleta, tipografía, ejes, leyendas)
  con una plantilla común (`R/01_tema.R`).
- **Listado de figuras:** el Anexo 1 (`Anexo 1. Contexto departamental y provincial extendido.docx`)
  es la referencia; la hoja *Figuras* de la sistematización es el registro. El mapeo consolidado
  está en `catalogo_figuras.xlsx`. Excluir mapas.
- **Entorno R (híbrido):** en el sandbox R se instala vía git (CRAN está bloqueado ahí); la corrida
  final es en tu máquina (R local, CRAN normal). La lógica de cada figura se valida contra los datos
  y con render de revisión.
- **Parametrizado por `$id_provincia` (1–11)**, igual que el flujo. Provincia de prueba: 4 (Turística
  y Agroecológica); validado también en la 3.

## MAPA DE CARPETAS
Raíz del proyecto (carpeta conectada): `D:\IA Provincias\Proyecto datos y tablas 2\`.
(Detalle conocido: los `.do` de Stata usan `$path = D:\IA Provincias\Proyecto datos y tablas` sin el
"2"; hay que fijar `$path` al correr Stata. El pipeline de R **no** depende de esto: detecta la raíz
por su propia ubicación.)

En la raíz: `Anexo 1 …docx` (referencia de figuras), `Sistematización figuras y variables …xlsx`
(registro; hojas Figuras/Variables/Fuentes + backups con timestamp), `catalogo_figuras.xlsx` (tabla
maestra figura→datos→tipo→estado), `Pendientes - Proyecto Provincias (consolidado).md`.

Subcarpetas:
- `01_Data\00_Inputs\` — insumos crudos. `01_Data\01_Derived\` — derivados (`*_PROVINCIAS.xlsx`,
  `ECV_*.dta`, `percepcion_seguridad.dta`, etc.).
- `02_Code\` — proyecto R base + `02_Tablas_*.do` + `03_Gráficos.do` (lógica de gráficos legado en
  Stata, referencia) + `00_Homogeneizacion_Inputs\`.
- `02_Code\Tablas_Diagnostico\` — el flujo Stata: `00_master.do` + sectoriales.
- **`02_Code\R_Figuras\` — el pipeline de figuras en R (esta fase).** Contiene `run_provincia.R`,
  `README.md` y `R/` (`00_setup.R`, `00_config.R`, `01_tema.R`, `02_utils.R`, `fig/01…10`).
- `03_Outputs\<provincia_carpeta>\<NN_Sección>\<seccion>.xlsx` — salidas del flujo = fuente de datos
  Y destino de las figuras.
- `03_Outputs\Gráficos\` — figuras legado (referencia visual; las nuevas NO van ahí).

## ARQUITECTURA DEL PIPELINE R
- `run_provincia.R` — orquestador. Se elige la provincia en la línea `id_provincia <- N` (o vía la
  variable de entorno `ID_PROVINCIA`); recorre las 10 secciones e inserta figuras + tablas.
- `R/00_setup.R` — instala/carga dependencias en R fresco (`openxlsx2` ≥ 1.28, `encharter` ≥ 0.10;
  arrastran R6/Rcpp/stringi). Sin pasos manuales.
- `R/00_config.R` — valida `id_provincia`; **autodetecta la raíz** subiendo hasta la carpeta que
  contiene `03_Outputs` (funciona en cualquier clon/SO; escape opcional `PROVINCIAS_ROOT`).
- `R/01_tema.R` — plantilla de estilo (paleta navy `#1F3864` / azul `#4472C4` / claro `#9DC3E6`,
  tipografía, paleta categórica).
- `R/02_utils.R` — helpers: `enc_hbar` (barra simple/apilada 100%/apilada absoluta/agrupada),
  `enc_piramide`, `enc_line`, `enc_pie`, `enc_scatter`, `enc_dumbbell`, `estilo_tabla`; y utilidades
  `leer_municipios`, `pick`/`pick_name` (insensible a acentos), `ultimo_anio`, `.anchor`, `.try`.
- `R/fig/NN_<seccion>.R` — un módulo por sección (espejo de los sectoriales de Stata).

Cómo correrlo (tras correr Stata para la provincia): `Rscript 02_Code\R_Figuras\run_provincia.R`
(o *source* en RStudio). Elegir provincia en `run_provincia.R`.

## CONVENCIONES A RESPETAR
- Parametrizar por `$id_provincia`; la entrada es el export de esa provincia en `03_Outputs\`. Nada
  de rutas fijas a una sola provincia. No mapas.
- **Todo gráfico nativo de Excel**, dentro del `.xlsx`, con estilo unificado (plantilla común)
  manteniendo el tipo de cada figura del Anexo. Reutilizar los helpers existentes; no reinventar.
- Selección de columnas **insensible a acentos** (funciona en cualquier locale/OS). Formatos de
  número estándar de Excel (`#,##0`, `0.0`, `0.0%`) que se localizan solos.
- Filas agregadas (TOTAL / PROMEDIO PONDERADO PROVINCIA/SUBREGIÓN/DEPARTAMENTO) se detectan por
  **Código DANE vacío**: se excluyen de los gráficos por municipio y se resaltan en las tablas.
  Hojas ECV con columnas `_mun`/`_ofi` (municipal/agregado): usar la correcta por figura.
- Hojas multi-año: gráficos y tablas de un solo año usan el **último año** (excepción: series
  explícitas como mortalidad infantil 2020–2024).
- Los `.xlsx` se bloquean si están abiertos en Excel (PermissionError): pedir cerrarlos. No borrar
  archivos sin permiso. Antes de editar la sistematización, copia de respaldo con timestamp.

## ENTORNO
- Sandbox: R + `openxlsx2` + `encharter` instalados vía git (CRAN bloqueado). Local: instalación
  automática desde CRAN por `00_setup.R`. Validar la lógica de cada figura además del render.
- Paquetes del pipeline: `openxlsx2`, `encharter` (+ R6, Rcpp, stringi). No se usa ggplot2/mschart
  salvo decisión puntual de fallback.

## PREFERENCIAS
Español, conciso y directo. **No dar la razón por defecto**: ser crítico, usar contrapreguntas y
priorizar la validez según evidencia y lógica, con criterio de experto en análisis y visualización.
Cuando una decisión afecte la salida (tipo de gráfico, nativo vs imagen, estilo), proponerla antes.

## ESTADO ACTUAL
- Flujo Stata + Excel COMPLETO (validado provincias 3 y 4). Sistematización actualizada y
  sincronizada con GitHub.
- **Pipeline de figuras en R construido y funcionando de punta a punta.** De las 83 figuras no-mapa:
  **78 construidas** (53 gráficos + 25 tablas), todas nativas; **5 fuera de alcance** (sin fuente en
  el export): Instrumentos POT (fig11), POMCA/PORH (fig14), suelo rural (fig56/57), Clima/Hidrografía
  /Vegetación (fig62).
- Toolkit de helpers completo y probado con datos reales. Catálogo maestro en `catalogo_figuras.xlsx`.
- Revisar más adelante (registrado en el `.md` de pendientes): fig43/fig59 (torta) y fig82 (barra vs
  torta); confirmar en Excel los conectores de los dumbbell (fig34/36/38). Pendientes previos del
  proyecto (citas/referencias, aves/suelo rural, IDF/SRDAFT, homogenizaciones) siguen en el `.md`.

## DEFINICIÓN DE "HECHO" (por figura/sección)
- Se genera automáticamente para cualquier provincia leyendo el export del flujo.
- Coincide con el Anexo 1 en tipo de gráfico, series y orden (exacta donde importe; estilo unificado
  en el resto).
- Queda dentro del mismo `<seccion>.xlsx` del flujo, en la hoja correspondiente, como **gráfico
  nativo editable** (con sus datos en hoja auxiliar oculta). Nada de carpeta de gráficos aparte.
- El catálogo/sistematización registran tipo de gráfico y hoja/columnas de origen; los pendientes
  quedan actualizados.
