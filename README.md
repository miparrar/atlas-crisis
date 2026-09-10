# Atlas de la Crisis

El **Atlas de la Crisis** es una curaduría de autores que sigo para comprender la crisis en curso que experimentamos como humanidad, con análisis y extracción asistidos por inteligencia artificial. Surge como una ramificación de un proyecto mayor dedicado al estudio de la crisis capitalista mundial.

El Atlas trabaja con una selección de autores provenientes de distintas corrientes teóricas. El objetivo es comprenderlos en sus propios términos y reconstruir cómo interpretan los problemas que observan.

Cada lectura se organiza como una ficha orientada por cinco preguntas: **qué fenómeno, tensión o interrogante observa el autor; cómo lo explica; qué elementos constituyen esa explicación y qué función cumplen; qué evidencia utiliza para sostenerla; y qué conceptos, proposiciones, autores o marcos teóricos organizan su interpretación**.

En torno a estas preguntas se organiza la **extracción asistida por inteligencia artificial**. La IA se utiliza para identificar y estructurar estos componentes de manera sistemática, procurando preservar los términos del propio autor, distinguir entre explicación, evidencia y teoría, y evitar atribuciones que no estén respaldadas por el texto.

El formato está inspirado en las antiguas tarjetas amarillas de fichas de lectura: unidades breves, sistemáticas y comparables que, acumuladas, permiten construir un mapa de interpretaciones sobre la crisis contemporánea.

La lógica de producción del proyecto está inspirada en [**Spicy Takes**](https://www.spicytakes.org/), de Wes McKinney: curaduría de fuentes combinada con análisis estructurado mediante modelos de lenguaje.

El catálogo curatorial reúne a **Michael Roberts, Adam Tooze, Paul Krugman, Michael Pettis, Ann Pettifor, Kate Mackenzie, Fernando Rugitsky, Grace Blakeley, Branko Milanović, Stephanie Kelton y Rana Foroohar**. Michael Roberts, Adam Tooze, Paul Krugman y Kate Mackenzie tienen monitoreo e ingesta automática verificados; las demás fuentes permanecen pendientes de verificación técnica. 


## Flujo

```text
Fuentes curadas
      ↓
R: ingerir y normalizar
      ↓
Markdown + procedencia + hash
      ↓
Bash: codex exec
      ↓
JSON estructurado
      ↓
R: validar contrato, hash y citas
      ↓
Sitio estático: autores → artículos → fichas
```

R procesa datos; Bash invoca Codex; GNU Make conecta las etapas. R no llama directamente a un LLM.

## Ejecutar

Se requieren R, GNU Make, Bash, Codex CLI autenticado y las utilidades indicadas por `make doctor`.

```bash
make setup
make latest
```

`make latest` establece la primera ronda con la publicación más reciente de cada fuente cuyo monitoreo está verificado, y ejecuta ingesta, análisis, validación y sitio.

En las rondas siguientes:

```bash
make update
```

`make update` consulta solo los RSS configurados en `monitored_source_ids` y procesa todas las entradas nuevas desde la última ronda válida. El URL identifica el artículo; el hash del cuerpo, del esquema y del prompt decide si debe analizarse otra vez. El estado del feed avanza únicamente después de una validación completa.

La operación regular está explicada en [docs/monitoreo.md](docs/monitoreo.md). Para programar `make update` todos los días a las 08:00, hora local:

```bash
make install-monitor
# Otra hora: make install-monitor HOUR=14
```

La tarea usa un bloqueo para evitar ejecuciones simultáneas y escribe en `logs/update.log`.

## Lectura

Cada artículo se reorganiza alrededor de **un único problema central**. La ficha responde cinco preguntas:

1. ¿Qué fenómeno o problema identifica el autor?
2. ¿Cómo lo explica o interpreta?
3. ¿Qué elementos componen esa explicación?
4. ¿Qué evidencia utiliza?
5. ¿Qué teoría moviliza, discute o rechaza?

La extracción conserva solo los elementos que contribuyen a esa articulación. Cada afirmación incluye citas literales; las inferencias del extractor y la evidencia no disponible se señalan. Un texto parcial queda con `problem: null`.

El detalle metodológico está en [docs/contrato-de-lectura.md](docs/contrato-de-lectura.md). El contrato ejecutable está en [config/analysis_schema.json](config/analysis_schema.json) y sus instrucciones en [prompts/analyze.md](prompts/analyze.md).

## Sitio

Para reconstruir el sitio sin descargar ni invocar el LLM:

```bash
make site
```

Para revisarlo localmente:

```bash
make serve
# http://localhost:8000
```

El sitio queda en `corpus/reports/` y contiene una portada, un índice por autor y una ficha por artículo. El corpus Markdown y los JSON permanecen separados. La publicación remota debe exponer únicamente `corpus/reports/`; el proveedor de hosting todavía no está configurado.

## Principios

- Fuentes curadas explícitamente, sin descubrimiento abierto en la web.
- Pluralidad teórica sin privilegiar un mecanismo de crisis.
- Markdown normalizado como documento canónico local.
- Afirmaciones trazables mediante citas y procedencia.
- Procesamiento incremental y resultados generados fuera de Git por defecto.
- Revisión humana antes de ampliar o publicar.
