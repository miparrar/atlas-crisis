# Atlas de la Crisis

**Cartografiar la crisis económica.**

Atlas de la Crisis es un proyecto de investigación reproducible para reunir, organizar y analizar interpretaciones contemporáneas sobre la crisis económica. El objetivo es construir un corpus plural de posts y blogs de economistas y otros autores relevantes, provenientes de distintas escuelas y tradiciones teóricas, y transformar ese corpus en información estructurada que permita comparar tesis, argumentos, mecanismos, evidencia y conceptos.

El proyecto se inspira en **Spicy Takes**, de Wes McKinney, especialmente en su idea de construir un corpus curado de publicaciones, normalizar los textos y procesarlos de forma sistemática con modelos de lenguaje. Atlas de la Crisis adapta ese enfoque a una pregunta distinta: no identificar las opiniones más provocadoras, sino **cartografiar las distintas explicaciones de la crisis económica y las relaciones entre ellas**.

## Principios

- Corpus curado: las fuentes se definen explícitamente.
- Pluralidad teórica: se incorporan autores de distintas escuelas y posiciones.
- Trazabilidad: cada documento conserva URL de origen, fecha de recuperación y hash del contenido.
- Reproducibilidad: la ingesta, el procesamiento y la validación se ejecutan mediante scripts.
- Separación de responsabilidades: Bash orquesta y llama a Codex CLI; R procesa, valida y estructura datos.
- Procesamiento incremental: un documento no se vuelve a analizar si su contenido no ha cambiado.

## Flujo inicial

```text
fuentes curadas
      ↓
descubrimiento de posts
      ↓
descarga y normalización
      ↓
Markdown + procedencia + hash
      ↓
codex exec
      ↓
JSON estructurado
      ↓
R
      ↓
validación y datos analíticos
```

## Piloto

El desarrollo inicial avanza de manera acumulativa:

1. un post;
2. dos posts;
3. cinco posts.

El objetivo del piloto no es escalar rápidamente, sino comprobar que cada etapa sea correcta, reproducible y trazable antes de ampliar el corpus.

## Estado

Proyecto en etapa inicial de diseño e implementación.
