# 03_Outputs — Salidas del pipeline

Esta carpeta la **genera el pipeline**; su contenido no se versiona (salvo este archivo).

> **No borre este README.** `02_Code/R/00_config.R` localiza la raíz del proyecto
> buscando la carpeta `03_Outputs`. Git no versiona carpetas vacías, así que sin
> este archivo la carpeta desaparecería en un clon nuevo y el pipeline no encontraría
> la raíz.

## Estructura generada

```
03_Outputs/
└── <Provincia>/                    # p. ej. Turistica_Agroecologica
    ├── 01_Generalidades/
    │   ├── distribucion_territorial.xlsx     # tablas (una hoja por tabla)
    │   └── figuras/
    │       ├── fig_01_<slug>.png             # 300 dpi, para Word/PowerPoint
    │       └── fig_01_<slug>.pdf             # vectorial, para impresión/LaTeX
    ├── 02_Demografia/
    │   ├── demografia.xlsx
    │   └── figuras/
    └── ...  (hasta 10_Seguridad)
```

Las 11 carpetas de provincia y sus nombres exactos están definidos en
`02_Code/R/00_config.R` (tabla `PROVINCIAS`).

## Cómo se genera

```bash
# Una provincia
ID_PROVINCIA=4 Rscript 02_Code/run_provincia.R

# Las 11 provincias
Rscript 02_Code/run_all.R
```

Ver `README.md` en la raíz del repositorio para el pipeline completo.

## Salidas del pipeline anterior (Stata)

Las tablas y gráficos producidos por el pipeline Stata están en
`99_Legacy/outputs/`. Se conservan como referencia visual y de contenido;
no las regenera ningún script vigente.
