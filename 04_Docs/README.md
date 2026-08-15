# 04_Docs — Documentación metodológica

Lo que hay que leer antes de citar una cifra del proyecto, y lo que hay que
correr para volver a producirla.

```
04_Docs/
  anexo_metodologico.tex        el documento: fuentes, protocolos, limpieza,
  anexo_metodologico.pdf        agregación, trazabilidad y actualización
  preambulo.tex                 formato (colores del sistema visual del proyecto)
  tablas/                       fragmentos .tex GENERADOS — no editar a mano
  auditoria/                    CSV de respaldo de cada afirmación del anexo
  plan_escritura_provincial.md  cómo escribir los once informes
  borradores/<Provincia>/       diagnóstico provincial en Word (generado)
  comparativo/                  panel de las once provincias y su documento
```

## El anexo metodológico

Documenta cómo se construye cada cifra publicada: de qué archivo sale, qué
transformaciones sufre, con qué fórmula se agrega y cómo se actualiza.

**Ninguna cifra del anexo está escrita a mano.** Todas entran por
`\input{tablas/...}` o por las macros de `tablas/cifras.tex`, que se generan
desde las salidas reales del pipeline. Si el pipeline cambia, se regeneran las
tablas y el anexo queda al día sin que nadie tenga que acordarse de actualizar
un número dentro del texto.

### Regenerarlo todo, en orden

```bash
Rscript 02_Code/run_all.R                             # 1. tablas, figuras, mapas
Rscript 02_Code/06_comparativo/generar_comparativo.R  # 2. panel + comparativo
Rscript 02_Code/05_documento/generar_borrador.R       # 3. once diagnósticos
Rscript 02_Code/99_checks/auditoria_end_to_end.R      # 4. trazabilidad
Rscript 02_Code/99_checks/auditoria_redaccion.R       # 5. redacción + control
Rscript 02_Code/99_checks/diccionario_indicadores.R   # 6. diccionario
Rscript 02_Code/99_checks/generar_tablas_anexo.R      # 7. tablas del anexo
cd 04_Docs && latexmk -pdf anexo_metodologico.tex     # 8. PDF
```

Los pasos 2, 3 y 4 dependen del anterior y fallan con un mensaje claro si se
saltan.

## La auditoría

`auditoria/` guarda un CSV por comprobación. Son la evidencia del anexo y se
pueden comparar entre corridas para ver qué cambió al actualizar una fuente.

| Archivo | Qué responde |
|---|---|
| `A1_procedencia.csv` | Qué lee y qué escribe cada script |
| `A2_derivados.csv` | Qué derivado produce cada script, y cuáles no tienen productor |
| `A3_insumos_curados.csv` | Los tableros armados a mano y quién los usa |
| `A4_scripts_externos.csv` | Scripts heredados con rutas de otra máquina |
| `B1_inventario_insumos.csv` | Huella, peso y fecha de cada fuente |
| `C0_indice_hojas.csv` | Todas las hojas generadas |
| `C1_cobertura_municipal.csv` | Municipios de más o de menos en cada hoja |
| `D1_agregados.csv` | Cada fila de total, recomputada |
| `E1_rangos.csv` | Valores implausibles |
| `F1_figuras.csv` | Cada figura y su hoja de datos |
| `F2_figuras_codigo.csv` | Nota de fuente y subtítulo de cada figura |
| `G1`, `G2` | Catálogo declarado frente a lo implementado |
| `H1_diccionario_indicadores.csv` | Los 330 indicadores publicados y su respaldo documental |
| `H2_fichas_tecnicas.csv` | Las fichas existentes y si alguna las usa |
| `H3_cobertura_documental.csv` | Cobertura de fichas por sección |
| `R1_cifras_en_prosa.csv` | Cifras del texto sin procedencia registrada |
| `R2_resumen_redaccion.csv` | Cifras auditadas y proporción con procedencia |
| `R3_poder_deteccion.csv` | Poder de detección medido de la auditoría |

`RESUMEN.md` es la lectura de un vistazo.

## El plan de escritura

`plan_escritura_provincial.md` explica cómo pasar del Anexo 1 —escrito para una
provincia— a once informes comparables: qué estructura conservar, qué voz
sostener, qué se genera y qué se escribe, en qué orden y con qué lista de
verificación.

## Los borradores provinciales

`borradores/<Provincia>/<Provincia>_diagnostico.docx` es el borrador en Word de
cada provincia, con la estructura del Anexo 1, sus 74 figuras y mapas, seis
tablas y una redacción factual generada desde las tablas publicadas.

```bash
Rscript 02_Code/05_documento/generar_borrador.R       # las once
Rscript 02_Code/05_documento/generar_borrador.R 4     # solo la provincia 4
```

Requiere `pandoc`; sin él se genera solo el Markdown intermedio.

**Qué contiene y qué queda pendiente.** El documento está redactado de punta a
punta: unas 4.600 palabras de prosa por provincia, sin marcadores de redacción.
Cada afirmación se apoya en una cifra calculada o en una medida derivada
(concentración, brecha interna, posición frente a la subregión y el
departamento, contigüidad espacial real sobre la cartografía).

Lo que queda son **22 notas «Verificar con el equipo»** por documento. Marcan
los puntos donde el informe querría afirmar algo que exige una fuente que este
flujo no tiene: causas, contexto institucional, información de campo. No se
inventaron: se señalaron.

Los estilos salen de `02_Code/05_documento/plantilla_estilos.docx`, derivada del
propio Anexo 1, de modo que los once borradores se ven como el informe
entregado. La jerarquía de encabezados es la del Anexo (capítulo en Heading 2,
secciones en Heading 3, subsecciones en Heading 4), así que un borrador se puede
pegar en el documento maestro sin recolocar niveles.

**Se regeneran, no se editan.** Si una cifra está mal, se corrige en el flujo y
se vuelve a generar; lo que se redacte va en la copia de trabajo del equipo.

### Los esqueletos

`borradores/<Provincia>/esqueleto.md` es la versión ligera: encuadre, inventario
de material y encargos, sin figuras embebidas. Sirve para planear el reparto.

```bash
Rscript 02_Code/05_documento/generar_esqueleto.R      # las once
Rscript 02_Code/05_documento/generar_esqueleto.R 4    # solo la provincia 4
```
