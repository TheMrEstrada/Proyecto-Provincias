#!/usr/bin/env python3
"""
Extrae la REFERENCIA de validación desde el Anexo 1 del informe.

El Anexo 1 ("Contexto departamental y provincial extendido", en 00_Documentos/)
es el producto final publicado del pipeline anterior para la provincia
Bioenergética del Norte de Antioquia (id 2): 52 tablas numeradas y 62 figuras
ya curadas. Sirve como patrón para validar la migración a R:

  - tests/referencia/tablas/tabla_NN.csv   valores esperados por tabla
  - tests/referencia/tablas/indice.csv     nº de tabla, título, filas, columnas
  - tests/referencia/figuras/img_NN.<ext>  las 62 figuras tal como se publicaron

Uso:
    python3 tests/extraer_referencia_anexo1.py

Requiere: python-docx (pip install python-docx)

Nota: la referencia NO se versiona (ver .gitignore); se regenera con este script
a partir del .docx, que sí está versionado.
"""

from __future__ import annotations

import csv
import re
import shutil
import sys
import zipfile
from pathlib import Path

try:
    import docx
except ImportError:
    sys.exit("Falta python-docx. Instale con: pip install python-docx")

# --- Rutas -------------------------------------------------------------------
RAIZ = Path(__file__).resolve().parent.parent
DOCX = RAIZ / "00_Documentos" / "Anexo 1. Contexto departamental y provincial extendido.docx"
SALIDA = RAIZ / "tests" / "referencia"
DIR_TABLAS = SALIDA / "tablas"
DIR_FIGURAS = SALIDA / "figuras"

PATRON_TITULO = re.compile(r"^(Tabla|Figura|Gr[áa]fico|Mapa|Ilustraci[óo]n)\s*(\d+)[.\s]", re.IGNORECASE)


def texto_celda(celda) -> str:
    """Texto de la celda, colapsando espacios. Las celdas combinadas de Word
    repiten su contenido en cada posición; eso se conserva tal cual para que la
    forma de la tabla sea comparable con la del .xlsx que genera el pipeline."""
    return " ".join(celda.text.split())


def titulo_de_cada_tabla(documento) -> list[str]:
    """Título que le corresponde a cada tabla, en el orden de las tablas.

    Recorre el cuerpo del documento en su orden real (párrafos y tablas
    intercalados) y asigna a cada tabla el último título "Tabla N." que la
    precede. Emparejar por posición en dos listas independientes no funciona:
    el documento tiene tablas sin título (las que solo contienen mapas) y eso
    desfasa todas las asignaciones siguientes.
    """
    cuerpo = documento.element.body
    titulos: list[str] = []
    ultimo = ""
    parrafos = {p._element: p for p in documento.paragraphs}
    tablas = {t._element: t for t in documento.tables}

    for hijo in cuerpo.iterchildren():
        if hijo in parrafos:
            texto = parrafos[hijo].text.strip()
            m = PATRON_TITULO.match(texto)
            if m and m.group(1).lower() == "tabla":
                ultimo = texto
        elif hijo in tablas:
            titulos.append(ultimo)
            ultimo = ""  # un título no se reutiliza para dos tablas
    return titulos


def main() -> int:
    if not DOCX.exists():
        sys.exit(f"No se encuentra el Anexo 1 en:\n  {DOCX}")

    DIR_TABLAS.mkdir(parents=True, exist_ok=True)
    DIR_FIGURAS.mkdir(parents=True, exist_ok=True)

    documento = docx.Document(str(DOCX))
    titulos_tabla = titulo_de_cada_tabla(documento)

    # --- Tablas --------------------------------------------------------------
    indice: list[dict] = []
    for i, tabla in enumerate(documento.tables, start=1):
        filas = [[texto_celda(c) for c in fila.cells] for fila in tabla.rows]
        if not filas or all(not celda for fila in filas for celda in fila):
            continue  # tablas usadas solo como contenedor de imágenes (mapas)

        destino = DIR_TABLAS / f"tabla_{i:02d}.csv"
        with destino.open("w", newline="", encoding="utf-8") as fh:
            csv.writer(fh).writerows(filas)

        titulo = titulos_tabla[i - 1] if i <= len(titulos_tabla) else ""
        indice.append(
            {
                "archivo": destino.name,
                "titulo": titulo,
                "filas": len(filas),
                "columnas": max(len(f) for f in filas),
            }
        )

    with (DIR_TABLAS / "indice.csv").open("w", newline="", encoding="utf-8") as fh:
        escritor = csv.DictWriter(fh, fieldnames=["archivo", "titulo", "filas", "columnas"])
        escritor.writeheader()
        escritor.writerows(indice)

    # --- Figuras (media embebida del .docx) ----------------------------------
    n_figuras = 0
    with zipfile.ZipFile(DOCX) as zf:
        for nombre in sorted(n for n in zf.namelist() if n.startswith("word/media/")):
            destino = DIR_FIGURAS / Path(nombre).name
            with zf.open(nombre) as origen, destino.open("wb") as fh:
                shutil.copyfileobj(origen, fh)
            n_figuras += 1

    print(f"Referencia extraída en {SALIDA.relative_to(RAIZ)}/")
    print(f"  tablas:  {len(indice)}  (+ indice.csv)")
    print(f"  figuras: {n_figuras}")
    con_titulo = sum(1 for f in indice if f["titulo"])
    print(f"  tablas con título asociado: {con_titulo} de {len(indice)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
