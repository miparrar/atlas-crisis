# Atlas de la Crisis

Atlas cartografía interpretaciones de la crisis económica mundial. Reúne textos de autores seleccionados, reconstruye sus explicaciones y conserva el vínculo entre cada afirmación y el pasaje que la respalda.

El proyecto toma de [Spicy Takes](https://www.spicytakes.org/) el flujo de archivo, análisis y publicación por autor. Cambia el objeto: aquí no se puntúa qué tan provocadora es una cita, sino que se organiza la explicación económica de cada texto.

La selección inicial es **Michael Roberts, Adam Tooze y Paul Krugman**. Las fuentes se definen en [config/sources.yml](config/sources.yml) y se documentan en [docs/fuentes-iniciales.md](docs/fuentes-iniciales.md). La disponibilidad técnica no determina la relevancia intelectual de un autor.

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

`make latest` establece la primera ronda: toma la publicación más reciente de Michael Roberts, Adam Tooze y Paul Krugman, y ejecuta ingesta, análisis, validación y sitio.

En las rondas siguientes:

```bash
make update
```

`make update` consulta solo sus RSS configurados y procesa todas las entradas nuevas desde la última ronda válida. El URL identifica el artículo; el hash del cuerpo, del esquema y del prompt decide si debe analizarse otra vez. El estado del feed avanza únicamente después de una validación completa.

Los objetivos `pilot-1`, `pilot-2` y `pilot-5` se conservan como pruebas técnicas acumulativas. La operación regular está explicada en [docs/monitoreo.md](docs/monitoreo.md).
Para programar `make update` todos los días a las 08:00, hora local:

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
