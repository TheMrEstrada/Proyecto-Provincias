# Plan de escritura de los diagnósticos provinciales

Cómo pasar de un informe escrito a mano para una provincia a once informes
comparables, sin volver a redactar once veces lo mismo ni perder la voz del
documento original.

El patrón es el **Anexo 1** (`00_Documentos/Anexo 1. Contexto departamental y
provincial extendido.docx`), escrito para la provincia Bioenergética del Norte.
Este plan describe qué conservar de él, qué cambia ahora que el pipeline produce
más material, y en qué orden trabajar.

---

## 1. Qué es hoy el Anexo 1

Medido, no recordado:

| | Anexo 1 (provincia 2) | Lo que el pipeline entrega hoy, por provincia |
|---|---:|---:|
| Palabras de cuerpo | ~27.400 | — |
| Secciones de primer nivel | 10 | 10 |
| Subsecciones | 16 | — |
| Tablas | 57 | **68 hojas** de tabla |
| Gráficas | 25 | **64 figuras** |
| Mapas | **1** | **10 mapas** |

Dos conclusiones se siguen de ahí.

**La estructura no hay que inventarla.** Los diez encabezados de nivel 3 del
Anexo 1 coinciden uno a uno con las diez secciones del pipeline. La correspondencia
es exacta y es el andamiaje de los once documentos.

**El material visual se multiplicó.** El Anexo 1 tenía un mapa; ahora hay diez
por provincia, más el doble de gráficas. Escribir once veces el mismo texto con
más figuras encima no es el objetivo: el objetivo es que las figuras carguen lo
que hoy carga la prosa descriptiva, y que la prosa haga lo que una figura no
puede — interpretar, comparar y señalar la implicación de política.

---

## 2. La estructura canónica

Se conserva la del Anexo 1, con la numeración de secciones del pipeline entre
corchetes para que sea evidente de dónde sale cada cifra.

```
Contexto departamental y provincial
├── Generalidades — contexto departamental y provincial      [01]
├── Demografía                                               [02]
├── Ordenamiento del Territorio                              [03]
│   ├── Planes de Ordenamiento Territorial
│   ├── Tránsito y transporte
│   ├── Ciencia, Tecnología e Innovación
│   └── Vivienda y servicios
├── Gobernabilidad y capacidades territoriales               [04]
│   ├── Gobernabilidad
│   ├── Finanzas territoriales
│   └── Índice de Ciudades Modernas (ICM)
├── Economía y desarrollo                                    [05]
│   ├── Pobreza y mercado laboral
│   ├── Productividad y competitividad
│   ├── Mercado minero-energético
│   └── Turismo
├── Desarrollo Rural                                         [06]
├── Ambiental                                                [07]
│   ├── Recursos naturales
│   └── Sostenibilidad ambiental y cambio climático
├── Educación                                                [08]
├── Salud                                                    [09]
└── Seguridad, Paz y Derechos Humanos                        [10]
    ├── Seguridad y convivencia ciudadana
    ├── Paz
    └── Derechos Humanos
```

**No se reordena y no se añaden secciones.** Once documentos con la misma
estructura se pueden leer en paralelo, comparar y consolidar; once documentos
cada uno con su lógica, no.

---

## 3. La voz que hay que conservar

El Anexo 1 tiene una voz reconocible y vale la pena describirla para poder
sostenerla:

- **Institucional y situada.** Declara desde el principio su marco: la Guía
  Metodológica del DNP para la formulación de los Planes Estratégicos, el Visor
  Territorial de Asociatividad, la categorización del Centro de Estudios e
  Incidencia Valor Público y los Hechos Provinciales de la versión preliminar
  del Plan.
- **Comparativa por defecto.** Cada cifra provincial se lee contra la subregión
  y contra el departamento. Ese triple contraste es la unidad de análisis del
  documento, no un adorno.
- **Explícita sobre el territorio.** Nombra municipios y sus pertenencias
  administrativas, incluidas las excepciones (en la provincia 2, que Anorí
  pertenece al Nordeste y no al Norte).
- **Sobria.** Sin adjetivación, sin llamados a la acción, sin conclusiones que
  el dato no sostenga.

### Tres reglas de redacción

**Regla A — la cifra que se escribe existe en una tabla.** Toda cifra del texto
debe poder señalarse en una hoja del `.xlsx` de su sección. Si no está, no se
escribe. Si hace falta, se añade al pipeline y se regenera.

**Regla B — el texto no repite la figura, la interpreta.** Si el párrafo se
puede sustituir por la lectura de las barras, sobra. Lo que la figura no dice —
por qué importa, con qué se relaciona, qué implica para el Plan — es lo que
justifica el párrafo.

**Regla C — el año va en la primera mención.** Los indicadores tienen cortes
distintos y algunos son posteriores al informe de 2026. Cada afirmación lleva su
año la primera vez que aparece en la sección.

---

## 4. Cómo entra el material nuevo

### 4.1 Mapas

Los diez mapas por provincia responden preguntas que las tablas no responden.
No van «donde quepan»: cada uno tiene un lugar y una función.

| Mapa | Sección | Qué pregunta responde |
|---|---|---|
| `mapa_00_localizacion` | Generalidades | Dónde queda la provincia y qué la rodea. **Va primero, antes de cualquier cifra.** |
| `mapa_01_area` | Generalidades | Cómo se reparte el territorio entre municipios |
| `mapa_02_densidad` | Demografía | Dónde vive la gente |
| `mapa_03_deficit_vivienda` | Ordenamiento | Si el déficit es contiguo o disperso |
| `mapa_05_va_percapita` | Economía | Dónde se genera el valor |
| `mapa_07_perdida_cobertura` | Ambiental | Dónde se pierde el bosque |
| `mapa_08_cobertura_neta` | Educación | Dónde se queda corta la cobertura |
| `mapa_09_mortalidad_infantil` | Salud | Dónde muere más gente antes del primer año |
| `mapa_10_homicidios` | Seguridad | La geografía interna de la violencia |
| `mapa_10_homicidios_dpto` | Seguridad | Si el patrón provincial es excepcional en Antioquia |

**Regla D — un mapa se comenta o se quita.** Un mapa sin un párrafo que diga qué
patrón muestra es decoración. El párrafo debe nombrar el patrón: contigüidad,
frontera, corredor, concentración o ausencia de patrón. «No hay patrón espacial»
es un hallazgo legítimo y hay que escribirlo cuando sea el caso.

### 4.2 Figuras

De 25 a 64 por provincia. No todas entran al cuerpo del documento.

- **Al cuerpo:** las que sostienen una afirmación del texto. Como referencia, de
  6 a 10 por sección.
- **A un anexo de figuras:** el resto. Existen, son trazables y están
  disponibles, pero no interrumpen la lectura.

El criterio para decidir es la Regla B: si hay un párrafo que la figura hace
falta para entender, la figura va al cuerpo.

---

## 5. Qué se automatiza y qué se escribe

Esta es la decisión que determina cuánto cuesta el trabajo.

### Se genera (no se escribe once veces)

- La composición municipal de la provincia y sus subregiones.
- Los cuadros de cifras clave: población, área, densidad, participaciones.
- El pie de cada tabla y de cada figura, con su fuente y su año.
- El inventario de tablas, figuras y mapas disponibles por sección.
- Las oraciones puramente descriptivas de encuadre («la provincia está
  conformada por N municipios, de los cuales…»), que salen del crosswalk.

- La **frase factual** de cada subsección: quién concentra, quién está arriba y
  quién abajo, cómo se compara la provincia con su subregión y con el
  departamento. Está calcada de la sintaxis del Anexo 1 y sus cifras se leen de
  las tablas, no se escriben.

```bash
Rscript 02_Code/05_documento/generar_borrador.R         # las once, en Word
Rscript 02_Code/05_documento/generar_borrador.R 4       # solo la provincia 4
# salida: 04_Docs/borradores/<Provincia>/<Provincia>_diagnostico.docx
```

El borrador trae la estructura del Anexo 1, sus 74 figuras y mapas, seis tablas
y unas 4.600 palabras de prosa ya redactada. Los estilos y la jerarquía de
encabezados son los del Anexo, de modo que se puede pegar en el documento
maestro sin recolocar nada.

Quedan 22 notas **Verificar con el equipo** por documento: los puntos donde una
afirmación exigiría una fuente que el flujo no tiene. Ese es el trabajo que no
se automatiza.

Para planear el reparto sin cargar las figuras, `generar_esqueleto.R` produce la
versión ligera en Markdown:

```bash
Rscript 02_Code/05_documento/generar_esqueleto.R        # las once
# salida: 04_Docs/borradores/<Provincia>/esqueleto.md
```

### Se escribe provincia por provincia

- La lectura de cada patrón: qué muestra la figura o el mapa y por qué importa.
- Las excepciones territoriales y las particularidades productivas.
- El vínculo con los Hechos Provinciales de cada Plan.
- Las implicaciones para la formulación estratégica.

Ese es el trabajo real y no se automatiza. Todo lo demás sí.

---

## 6. Orden de trabajo

**Fase 0 — cerrar el patrón (una sola vez).**
Reescribir el Anexo 1 de la provincia 2 con la estructura y las reglas de este
plan, incorporando los diez mapas y la selección de figuras. Queda como el
documento de referencia contra el que se comparan los demás. Es el único que se
escribe sin ayuda del esqueleto, porque su prosa ya existe.

**Fase 1 — dos provincias contrastantes.**
Una provincia grande y diversa y una pequeña y homogénea. Sirven para descubrir
qué partes del patrón no viajan: qué párrafos dependían de rasgos propios de la
provincia 2 y hay que reformular en términos generales.

**Fase 2 — las ocho restantes, por lotes de tres.**
Con el patrón ya probado. Al cerrar cada lote, una revisión cruzada: dos
provincias del lote las lee alguien que no las escribió, contra la lista de
verificación de la sección 7.

**Fase 3 — consolidación.**
Un documento departamental que compare las once. Solo tiene sentido al final:
necesita que las once digan lo mismo de la misma manera.

### Reparto sugerido

Por **sección temática** y no por provincia: quien escribe Salud escribe las
once Salud. Se aprende la fuente una vez, se detectan las inconsistencias entre
provincias de inmediato y el vocabulario queda uniforme sin tener que negociarlo.

---

## 7. Lista de verificación por sección

Antes de dar una sección por terminada, en cualquier provincia:

- [ ] ¿Cada cifra del texto está en una hoja del `.xlsx` de la sección?
- [ ] ¿Cada afirmación lleva su año la primera vez que aparece?
- [ ] ¿Cada figura y cada mapa del cuerpo tienen un párrafo que los use?
- [ ] ¿Hay comparación explícita contra subregión y departamento?
- [ ] ¿Los municipios sin dato están declarados como tales y no leídos como cero?
- [ ] ¿Se nombraron las excepciones territoriales de la provincia?
- [ ] ¿Ninguna conclusión va más allá de lo que el dato sostiene?
- [ ] ¿La sección se puede leer en paralelo con la misma sección de otra
      provincia sin tropezar con diferencias de formato?

---

## 8. Advertencias que el texto debe recoger

Salen de la auditoría (`04_Docs/anexo_metodologico.pdf`) y no son opcionales:
si el informe publica la cifra, publica también su límite.

| Dónde | Qué hay que decir |
|---|---|
| Educación | La cobertura neta supera el 100 % en 284 de 1.750 registros municipio-año. Viene así de la fuente. Una cobertura *neta* no puede exceder el 100 %: o la serie es de cobertura bruta, o matrícula y proyección de población no son consistentes. |
| Salud | En municipios con pocos nacimientos, la mortalidad infantil se mueve mucho con un solo caso. No se debe leer como tendencia. |
| Seguridad (percepción) | La encuesta es representativa a nivel de **subregión**, no de provincia. Se rotula por subregión. |
| Economía | El valor agregado va a precios constantes de 2015; el Anexo 1 lo publicó a corrientes. Las dos cifras son correctas y no son comparables entre sí. |
| Conflicto armado | Las cifras son **victimizaciones**, no personas: una persona puede aparecer en más de un hecho. |
| Ordenamiento | El catastro no cubre el Área Metropolitana ni dos municipios de la provincia 5. |
| Todas | Diez de las once provincias no tienen informe publicado contra el cual contrastar. La verificación externa existe solo para la provincia 2. |

---

## 9. Qué falta resolver antes de la Fase 2

Tres cosas que conviene cerrar mientras se escriben las dos primeras provincias,
porque afectan a las once:

1. **Confirmar con el MEN qué serie es la «cobertura neta».** Es la única
   advertencia de la lista anterior que puede desaparecer en vez de tener que
   escribirse once veces.
2. **Decidir si el valor agregado se publica a corrientes o a constantes.**
   Cambiar de criterio después de escribir seis provincias cuesta seis
   reescrituras.
3. **Completar las fichas técnicas de los indicadores que hoy no tienen.** El
   pipeline publica 330 indicadores y solo 12 tienen ficha. Sin ellas, cada
   redactor reinventa la definición de cada indicador, y once redactores
   producen once definiciones.
