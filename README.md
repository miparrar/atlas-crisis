# Atlas de la Crisis

**Cartografiar la crisis económica.**

Atlas de la Crisis es un proyecto de investigación reproducible para reunir, organizar y analizar interpretaciones contemporáneas sobre la crisis económica. El objetivo es construir un corpus plural de posts y blogs de economistas y otros autores relevantes, provenientes de distintas escuelas y tradiciones teóricas, y transformar ese corpus en información estructurada que permita comparar tesis, argumentos, mecanismos, evidencia y conceptos.

El proyecto se inspira en **Spicy Takes**, de Wes McKinney, especialmente en su idea de construir un corpus curado de publicaciones, normalizar los textos y procesarlos de forma sistemática con modelos de lenguaje. Atlas de la Crisis adapta ese enfoque a una pregunta distinta: no identificar las opiniones más provocadoras, sino **cartografiar las distintas explicaciones de la crisis económica y las relaciones entre ellas**.

## Flujo

R cumple dos funciones concretas. Primero hace la ingesta: lee la configuración del piloto, descarga el post, extrae su contenido, lo normaliza y escribe un Markdown con procedencia y hash. Después de Codex, R valida la salida estructurada.

\`\`\`text
config/pilot.yml
      ↓
R: descargar + limpiar
(ingesta)
      ↓
Markdown + procedencia + hash
      ↓
Bash: codex exec
(análisis semántico)
      ↓
JSON
      ↓
R: validar
(control de calidad)
\`\`\`

Codex no se invoca desde R. Toda interacción batch con el LLM ocurre desde Bash mediante Codex CLI.

## Ejecución

Requisitos del sistema:

- R / \`Rscript\`
- Codex CLI instalado y autenticado
- \`sha256sum\`

Después de clonar:

\`\`\`bash
make doctor
make bootstrap
make pilot-1
\`\`\`

\`make bootstrap\` instala los paquetes R faltantes para el piloto.

Si \`pilot-1\` funciona correctamente, continuar con:

\`\`\`bash
make pilot-2
make pilot-5
\`\`\`

Los pilotos son acumulativos. Los documentos cuyo contenido y esquema no hayan cambiado reutilizan el análisis previo y no vuelven a consumir una llamada de Codex.

## Principios

- Corpus curado: las fuentes se definen explícitamente.
- Pluralidad teórica: se incorporan autores de distintas escuelas y posiciones.
- Trazabilidad: cada documento conserva URL de origen, fecha de recuperación y hash del contenido.
- Reproducibilidad: la ingesta, el procesamiento y la validación se ejecutan mediante scripts.
- Separación de responsabilidades: Bash orquesta y llama a Codex CLI; R procesa, valida y estructura datos.
- Procesamiento incremental: un documento no se vuelve a analizar si su contenido no ha cambiado.

## Piloto

El desarrollo inicial avanza de manera acumulativa:

1. un post;
2. dos posts;
3. cinco posts.

El objetivo del piloto no es escalar rápidamente, sino comprobar que cada etapa sea correcta, reproducible y trazable antes de ampliar el corpus.

## Estado

Proyecto en etapa inicial. El primer objetivo operativo es validar el flujo completo con un único post.
