# Monitoreo de fuentes

Atlas no busca autores ni artículos en la web abierta. Consulta únicamente los RSS de las fuentes declaradas en `monitored_source_ids` dentro de `config/sources.yml`: actualmente Michael Roberts, Adam Tooze y Paul Krugman. Los demás autores permanecen en el catálogo curatorial sin automatización.

## Primera ronda

```bash
make latest
```

Este comando toma una publicación —la más reciente— de cada fuente monitoreada, descarga el cuerpo desde el sitio oficial, lo normaliza, analiza, valida y reconstruye el sitio.

## Rondas posteriores

```bash
make update
```

El comando compara cada RSS con `data/discovery/state.yml`. Procesa las entradas que aparecen antes del último URL observado, es decir, las publicadas después de la ronda anterior. Si ese URL ya no aparece en el RSS, se detiene para evitar saltarse publicaciones silenciosamente.

La actualización es transaccional: primero se escribe un estado pendiente; el estado estable solo avanza cuando todo el lote pasó ingesta, análisis y validación. Una falla deja los artículos pendientes para el siguiente intento.

## Identidad, cambios y procedencia

- El URL de la entrada identifica la publicación.
- `content_sha256` identifica la versión normalizada de su cuerpo.
- Los hashes del esquema y del prompt identifican el contrato analítico.
- La metadata conserva autor, publicación, URL, fechas de descubrimiento, publicación y recuperación, estado de acceso y hash.

Un URL nuevo crea un documento. Cuando un URL se vuelve a ingerir, el mismo cuerpo reutiliza el análisis y un cuerpo modificado lo invalida.

Los artefactos operativos son:

- `data/discovery/state.yml`: posición confirmada de cada feed.
- `data/discovery/pending.csv`: descubrimiento de la ronda en curso.
- `data/manifests/pending.txt`: documentos que deben analizarse.
- `data/manifests/catalog.txt`: catálogo acumulado validado.

## Automatización

Para instalar una tarea cron local diaria a las 08:00:

```bash
make install-monitor
```

La hora puede cambiarse, por ejemplo, con `make install-monitor HOUR=14`. La instalación es idempotente: reemplaza únicamente el bloque identificado como Atlas y conserva las demás tareas del usuario. `flock` evita rondas simultáneas y la salida queda en `logs/update.log`.

El equipo debe permanecer encendido a la hora programada y conservar una sesión válida de Codex. Si se necesita ejecución independiente de este equipo, debe configurarse posteriormente un runner remoto con sus credenciales y una estrategia explícita de persistencia o publicación de los artefactos generados.

## Exclusiones curatoriales

Una fuente puede declarar `exclude_title_regex` para formatos recurrentes que incumplen la política documental. La regla se aplica a los metadatos del feed antes de calcular las entradas nuevas. Actualmente Chartbook excluye `Top Links`, porque es una selección de enlaces y puede presentar acceso restringido; los artículos ordinarios siguen sujetos a validación estricta del cuerpo. Una exclusión no elimina al autor ni amplía el descubrimiento fuera de la fuente configurada.
