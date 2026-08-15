# Guía de migración — dónde quedó cada cosa

El 8 de agosto de 2026 se reestructuró el repositorio y se migró el pipeline de
Stata a R. Este documento es el mapa de equivalencias, para quien vuelva a un
archivo que ya no está donde lo dejó.

Nada se borró salvo copias byte a byte. Todo lo retirado está en `99_Legacy/`.

---

## Por qué se hizo

El pipeline no era replicable en ninguna máquina que no fuera la de quien lo
escribió:

- Cuatro raíces de rutas absolutas distintas, de cuatro computadores
  (`D:/LAURA/…`, `D:\IA Provincias\…`, dos OneDrive personales). Correr el
  pipeline exigía editar rutas dentro de los `.do`.
- Dos scripts leían y escribían **fuera** del repositorio; sus resultados se
  copiaban a mano.
- Código vigente y obsoleto mezclados en la misma carpeta.
- El pipeline de figuras en R estaba duplicado byte a byte en dos ubicaciones.
- ~117 MB de archivos duplicados exactos y 14 archivos de basura versionados.
- Errores latentes que abortaban la ejecución (`use ..., replace`) o que la
  rompían en silencio (la provincia 5 desaparecía al actualizarse su Excel).

---

## Mapa de equivalencias

### Código

| Antes | Ahora |
|---|---|
| `02_Code/Tablas_Diagnostico/00_master.do` | `02_Code/run_provincia.R` |
| `02_Code/Tablas_Diagnostico/NN_Seccion.do` | `02_Code/03_tablas/NN_seccion.R` (+ figuras en `02_Code/04_figuras/NN_seccion.R`) |
| `02_Code/00_Homogeneizacion_Inputs/*.do` | `02_Code/01_homogeneizacion/*.R` |
| `02_Code/00_BuildData.do` (bloque del crosswalk) | `02_Code/01_homogeneizacion/crosswalk_territorial.R` |
| `02_Code/00_BuildData.do` (resto) | retirado: alimentaba un análisis PCA cuyo código nunca estuvo en el repositorio |
| `02_Code/01_BuildFinalData.R` | retirado por lo mismo (`99_Legacy/codigo/stata_pipeline/`) |
| `02_Code/Figuras R/` (openxlsx2 + encharter) | `02_Code/04_figuras/` (ggplot2) |
| `02_Code/Tablas_Diagnostico/Figuras R/` | eliminado (era copia byte a byte) |
| `02_Code/02_Tablas_*.do`, `03_Gráficos.do` | `99_Legacy/codigo/` |
| Todo el Stata vigente | `99_Legacy/codigo/stata_pipeline/` (con su README) |
| Los `.R` con rutas `C:/Users/espin/…` | `02_Code/01_homogeneizacion/externos/` |

**El bloque de rutas ya no existe.** Antes cada `.do` empezaba con
`global path "D:/…"`. Ahora la raíz se detecta sola en
`02_Code/R/00_config.R`, que es el único archivo del repositorio con lógica de
rutas. Si necesita fijarla, use la variable de entorno `PROVINCIAS_ROOT`.

### Datos

| Antes | Ahora | Por qué |
|---|---|---|
| `01_Data/00_Inputs/códigos_provincias.dta` | `01_Data/01_Derived/codigos_provincias.dta` | es un derivado, no una fuente; y el nombre pasa a ASCII |
| `01_Data/00_Inputs/subreg_completo.dta` | `01_Data/01_Derived/subreg_completo.dta` | ídem |
| `01_Data/00_Inputs/ECV_raw.dta` | `01_Data/01_Derived/` | ídem |
| `01_Data/00_Inputs/POTA/` | eliminado | copia byte a byte de `TABLAS MUNICIPALES octubre/`, que es la que lee el código |
| `01_Data/00_Inputs/Fichas/` | eliminado | copia byte a byte de la de `00_Documentos/Fichas Tecnicas/POTA/` |
| `01_Data/01_Derived/pca_ds*`, `labels_2.xlsx` | `99_Legacy/datos/` | sin productor ni consumidor en toda la historia del repo |

### Salidas

| Antes | Ahora |
|---|---|
| `03_Outputs/tablas_*.xlsx` (todas las provincias juntas) | `03_Outputs/<Provincia>/<NN_Seccion>/*.xlsx` |
| `03_Outputs/Gráficos/` | `99_Legacy/outputs/graficos_stata_legacy/` |
| Gráficos incrustados dentro del `.xlsx` | `03_Outputs/<Provincia>/<NN_Seccion>/figuras/*.{png,pdf}` |

Ya no hay que correr Stata y después R en ese orden: un solo comando hace todo.

**Las salidas ya no se versionan.** Eran 1.519 archivos y 144 MB que se
reescriben enteros en cada corrida. Se regeneran con `Rscript 02_Code/run_all.R`
en unos minutos.

---

## Si trabaja en la rama `actualización`

El equipo venía subiendo archivos por la web de GitHub a la estructura vieja.
Al integrar esa rama:

- **Archivos modificados** que aquí cambiaron de sitio: git sigue el
  renombramiento solo. Si no lo hace, busque el destino en las tablas de arriba.
- **Archivos nuevos** en carpetas que ya no existen (`02_Code/Tablas_Diagnostico/`,
  `02_Code/00_Homogeneizacion_Inputs/`, `02_Code/Figuras R/`,
  `01_Data/00_Inputs/POTA/`): git los recrea en su ubicación vieja. Muévalos a la
  nueva según el mapa. `Rscript 02_Code/99_checks/check_pipeline.R` avisa cuando
  esto pasa.
- **Excel modificados en las dos ramas**: no se pueden fusionar. Quédese con la
  versión del colaborador (`git checkout --theirs <archivo>`) y vuelva a correr
  el pipeline, que regenera lo derivado.

Recomendación: avisar al equipo de que a partir de ahora suban sobre la
estructura nueva, y hacer la integración en una sola ventana de tiempo.

---

## Volver atrás

El estado anterior a la reestructuración está etiquetado:

```bash
git show pre_restructura_20260808          # ver el punto de partida
git diff pre_restructura_20260808 --stat   # todo lo que cambió
git checkout pre_restructura_20260808 -- <archivo>   # recuperar un archivo
```

El historial completo está intacto: no se reescribió nada.
