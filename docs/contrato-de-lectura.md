**Cómo organizo la lectura en Atlas**

Cada artículo se reconstruye alrededor de un único problema central. El proceso primero extrae las afirmaciones relevantes y luego las reorganiza según las preguntas del proyecto. Un texto puede contener tensiones o derivaciones distintas, pero se integran como partes de la misma explicación en vez de convertirse en fichas paralelas.

| Orden | Pregunta | Qué registro |
| --- | --- | --- |
| 01 · Fenómeno o problema | ¿Qué ocurre según el autor? | El problema central y su contexto temporal, geográfico o cuantitativo cuando resulte relevante |
| 02 · Explicación o interpretación | ¿Cómo lo entiende? | La tesis y las relaciones explicativas, con sus condiciones, incertidumbres y alternativas |
| 03 · Elementos constitutivos | ¿Qué compone esa explicación? | Los actores, relaciones, instituciones, procesos, variables y conceptos indispensables, indicando su función |
| 04 · Evidencia | ¿En qué se apoya? | Datos, indicadores, estudios, episodios, comparaciones y ejemplos que contribuyen a la interpretación |
| 05 · Teoría | ¿Qué marco conceptual utiliza? | Conceptos, proposiciones y referencias teóricas que emplea, discute o rechaza |

La explicación expresa la relación entre los elementos; la evidencia es el material con que el autor sostiene esa relación; la teoría aporta las categorías con que la interpreta. No se rellenan apartados sin respaldo ni se conservan digresiones que no contribuyan al problema central.

Cada afirmación lleva el mínimo de citas literales necesario. Las conexiones del extractor se marcan como inferencias. Una teoría no se atribuye por la escuela asignada al autor ni porque aparezca mencionada. La evidencia referida pero ausente se distingue de la disponible en el cuerpo y no se verifica de forma independiente.

**Publicación**

El sitio ofrece tres niveles: portada de autores, índice de artículos por autor y ficha individual. La ficha entra por una síntesis, recorre las cinco dimensiones y mantiene citas y procedencia plegadas. Los textos parciales quedan sin problema analítico y señalan su limitación.

`make latest` establece la ronda inicial con la publicación más reciente de cada fuente monitoreada; `make update` incorpora las posteriores; `make site` reconstruye el catálogo validado y `make serve` lo sirve localmente. Los pilotos acumulativos de 1, 2 y 5 documentos se conservan como pruebas técnicas del contrato.

El contrato ejecutable está en [config/analysis_schema.json](../config/analysis_schema.json) y las instrucciones de extracción en [prompts/analyze.md](../prompts/analyze.md). El sitio se genera con R y CSS locales, sin llamadas de red durante el renderizado. La identidad por URL, los hashes, la metadata y la promoción del estado de descubrimiento están documentados en [monitoreo.md](monitoreo.md).
