**Auditoría de Atlas de la Crisis — 7 de septiembre de 2026**

El proyecto tiene una arquitectura coherente para un prototipo de investigación: fuentes curadas, ingesta en R, documentos locales con procedencia, extracción mediante Bash y validación separada. Sin embargo, todavía no ofrece garantías suficientes para ampliar el corpus o utilizar sus resultados como base de comparaciones sistemáticas. Los principales problemas están en la extracción, la identidad de los documentos y los controles de integridad.

Se revisó el árbol de trabajo basado en el commit `8c8020d`, incluidos los cambios locales preexistentes en `Makefile`, `README.md`, `src/bootstrap.R` y los archivos nuevos del entorno `renv` y `src/check.R`. La auditoría añade únicamente este informe; no corrige la implementación ni modifica el corpus.

La revisión comprende especificación, instrucciones, código R/Bash, Makefile, fuentes, prompt, esquema, cinco documentos y sus resultados locales. Se ejecutaron comprobaciones existentes y reproducciones aisladas en `/tmp`, con un ejecutable simulado que impide llamadas reales al LLM. No se reinstalaron dependencias, no se repitieron descargas y no se ejecutaron nuevos análisis semánticos. La consulta externa se limitó a identificar y contrastar la referencia técnica; no se descubrieron ni incorporaron fuentes al corpus.

**Referencia: Spicy Takes, de Wes McKinney**

La referencia mencionada como «spicytask» corresponde a [Spicy Takes](https://www.spicytakes.org/). Su presentación pública organiza blogs por autor y ofrece resúmenes, citas y puntuaciones de provocación. También dispone de una [página de analítica](https://www.spicytakes.org/analytics). La comparación de esta auditoría se limita a esas capacidades observables: el enlace público a su repositorio, `https://github.com/wesm/spicytakes.org`, devolvió 404 durante la consulta, por lo que no se verificó su implementación interna.

| Dimensión | Referencia observable | Atlas de la Crisis |
| --- | --- | --- |
| Selección | Colección de blogs escogidos | Catálogo explícito de 11 fuentes; 5 habilitadas |
| Extracción | Resúmenes y citas por publicación | Tesis, argumentos, mecanismos, evidencia y citas |
| Consulta | Navegación por autores y analítica | Archivos locales; aún sin etapa de comparación |
| Criterio analítico | Interés y provocación de las citas | Explicaciones de crisis y sus fundamentos |

La adaptación es pertinente. Para Atlas, la prioridad es poder reconstruir qué sostiene cada autor y sobre qué pasaje se apoya cada extracción. Una puntuación de provocación no resulta necesaria para ese objetivo. La interfaz y la escala de Spicy Takes pueden orientar etapas posteriores, pero no sustituyen la validación del corpus.

**Hallazgos, por prioridad**

P1 significa corregir antes de ampliar el corpus; P2, resolver antes de usarlo para comparaciones sistemáticas; P3, mejora operativa posterior.

1. **P1 — El validador acepta análisis que incumplen el contrato.**

   En [src/validate_analysis.R](../src/validate_analysis.R), líneas 30–50, se lee el JSON y se comprueban únicamente las citas. Si `key_quotes` no existe, se utiliza una lista vacía y se devuelve `valid = TRUE`. Las pruebas reprodujeron la aceptación de `{}`, de `summary` numérico y de una cita situada exclusivamente en el front matter. También se aceptó un análisis sin archivo de metadatos asociado.

   `--output-schema` está presente en la generación, pero eso no certifica después los archivos almacenados o reutilizados. Tampoco `src/check.R` valida cada resultado: comprueba una parte de la estructura del esquema y la configuración.

   **Acción:** validar el JSON completo contra el esquema, los campos de procedencia, el hash recalculado y la correspondencia del análisis con el documento. Comprobar las citas únicamente contra el cuerpo normalizado. Un resultado sin citas puede ser legítimo; uno sin los campos obligatorios no lo es.

2. **P1 — Los títulos incorrectos pueden causar sobrescritura de documentos.**

   Los selectores `h1` de [config/sources.yml](../config/sources.yml), líneas 26, 76 y 115, produjeron los títulos «Paul Krugman», «Building a New Economics» y «The Grumpy Economist», aunque los cuerpos contienen títulos de artículos distintos. En [src/ingest_pilot.R](../src/ingest_pilot.R), líneas 106–114, el nombre de archivo depende únicamente del título transformado. `document_id` no participa en la ruta.

   **Consecuencia:** dos artículos de una fuente con el mismo título extraído se escribirían en la misma ruta, y compartirían también la ruta del análisis. Los títulos incorrectos ya se observan; la sobrescritura es una consecuencia del código, no una pérdida observada en este piloto de un artículo por fuente.

   **Acción:** identificar archivos mediante el `document_id` estable o una identidad derivada de la URL, corregir los selectores de título y rechazar rutas duplicadas antes de escribir.

3. **P1 — Un adelanto de 307 caracteres se procesa como documento válido.**

   [El documento de Steve Keen](../corpus/posts/steve_keen/building-a-new-economics.md), líneas 11–27, contiene un título, una breve insinuación, contadores e invitación a suscribirse. El umbral de 300 caracteres de `src/ingest_pilot.R`, líneas 99–100, permite su ingreso. Su JSON reconoce que no hay argumento desarrollado ni evidencia, pero igualmente recibe `valid = TRUE`.

   **Consecuencia:** la ausencia de contenido accesible puede confundirse con ausencia de mecanismos o evidencia en la obra del autor. Esto compromete la comparación entre tradiciones.

   **Acción:** registrar integridad y acceso por documento, separar completos de parciales y bloquear su inclusión como artículos completos. Mantener a Keen en el catálogo intelectual y seleccionar un texto público sustantivo para el piloto. No eludir restricciones de acceso.

4. **P1 — La extracción incorpora comentarios ajenos al autor.**

   El selector `div.entry-content, article` de [config/sources.yml](../config/sources.yml), línea 103, es una unión CSS; no significa «usar el primero y recurrir al segundo si falta». La función `html_element()` selecciona el primer elemento coincidente en el documento. Una reproducción con HTML sintético confirmó que puede seleccionar el contenedor `article` y arrastrar comentarios.

   El corpus de Bill Mitchell incluye artículos relacionados, dos comentarios, un formulario y JavaScript al final. La contaminación alcanza el [análisis generado](../data/analysis/bill_mitchell/latest-australian-national-accounts-data-provide-no-justification-for-further-interest-rate-rises.json), líneas 105–122: incorpora un nombre y China procedentes de comentarios. El modelo señala ese origen dentro de cadenas de texto, pero los elementos quedan en los mismos campos que las menciones del autor.

   **Acción:** seleccionar el cuerpo específico, retirar componentes ajenos antes de normalizar y comprobar por separado cada alternativa de selector. Los comentarios requieren otra unidad documental si en el futuro se decide estudiarlos.

5. **P1 — La caché puede reutilizar resultados desactualizados o corruptos.**

   [scripts/analyze.sh](../scripts/analyze.sh), líneas 18–51, confía en el hash declarado en el Markdown y compara solamente contenido y esquema. Las pruebas confirmaron `cached` después de modificar el prompt, modificar el cuerpo conservando el front matter y reemplazar el resultado por texto que no es JSON.

   El cambio del esquema sí invalidó la caché, como corresponde. El código tampoco registra el modelo efectivo: los metadatos conservan únicamente documento, hash del contenido, hash del esquema y versión de la CLI.

   **Acción:** recalcular y verificar el hash del cuerpo, incorporar el prompt a la identidad del contrato, fijar y registrar la configuración analítica relevante y validar el resultado antes de reutilizarlo. Mantener `retrieved_at` fuera de la clave semántica. Validar también antes de promover una salida nueva al destino definitivo.

6. **P2 — La normalización pierde enlaces y evidencia visual.**

   [src/ingest_pilot.R](../src/ingest_pilot.R), líneas 61–62, usa `html_text2()`: extrae texto, pero no conserva la estructura de enlaces e imágenes como Markdown. En [bond-bust.md](../corpus/posts/michael_roberts/bond-bust.md), líneas 43 y 59, quedan referencias a figuras y a un trabajo enlazado sin el recurso correspondiente.

   **Consecuencia:** el LLM puede reconocer la descripción textual de una figura, pero no comprobar sus valores ni recuperar desde el documento canónico el destino de un enlace perdido. El HTML abierto en el IDE declara `quarto-1.10.18`: es una representación generada, no una captura del HTML original que resuelva esta pérdida.

   **Acción:** conservar enlaces, pies, referencias a imágenes y tablas en la transformación; marcar explícitamente la evidencia visual no disponible. Guardar localmente la respuesta original facilitaría auditar la transformación, aunque el documento canónico siga siendo Markdown. No hace falta incorporar PDFs ni fuentes fuera del alcance inicial.

7. **P2 — La trazabilidad existe por archivo, pero es débil por afirmación.**

   [config/analysis_schema.json](../config/analysis_schema.json), líneas 21–38, representa tesis, argumentos y mecanismos como texto libre. Las citas son una lista independiente. El [prompt](../prompts/analyze.md), líneas 8–10, pide distinguir afirmaciones e inferencias, pero el esquema no ofrece una representación estructurada para esa distinción.

   Hay un vínculo útil entre documento, JSON y metadatos; no se trata de ausencia total de procedencia. La limitación es que no puede verificarse automáticamente qué pasaje respalda cada mecanismo, si expresa una hipótesis, una posición rechazada o una afirmación propia del autor.

   **Acción:** representar las afirmaciones con identidad, pasaje de apoyo y carácter explícito o inferido; conservar atribución y modalidad cuando corresponda. Añadir revisión humana registrada y ejemplos de referencia. Cualquier cambio debe actualizar conjuntamente esquema, prompt, validación y pilotos 1 → 2 → 5.

8. **P2 — El diseño plural todavía no equivale a una muestra comparativa justificada.**

   El catálogo incluye fuentes deshabilitadas de distintas tradiciones, lo que respeta la separación entre relevancia intelectual y disponibilidad técnica. Sin embargo, el piloto contiene cinco documentos, uno parcial, y no registra criterios de inclusión por texto, cobertura temporal o sesgos de acceso. `discovery` declara RSS, sitemap o archivo, pero la implementación actual consume únicamente las URLs manuales de `config/pilot.yml`.

   Esto es razonable para un piloto técnico. No permite inferir frecuencias o representatividad de las teorías de crisis.

   **Acción:** documentar la finalidad de la muestra y las exclusiones; registrar acceso, completitud y revisión. Diseñar luego una comparación de episodios, diagnósticos y mecanismos manteniendo las categorías propias de cada autor. El idioma de los análisis también debe fijarse si se pretende una salida homogénea: actualmente los resultados locales están en inglés.

**Comprobaciones realizadas**

| Comprobación | Resultado observado | Alcance |
| --- | --- | --- |
| `make check` | Pasa | Entorno instalado, sintaxis y controles de configuración |
| `make validate-5` | Pasa: 5 documentos y 25 citas | Coincidencia textual con el Markdown completo |
| Recalcular SHA-256 del cuerpo normalizado | Coincide en 5 de 5 | Integridad de los cuerpos locales respecto de sus hashes declarados |
| JSON vacío o tipos incorrectos | Aceptados por `validate_one()` | Defecto reproducido |
| Cita solo en front matter | Aceptada | Defecto reproducido |
| Cita inexistente | Rechazada | Control positivo del detector |
| Ausencia del archivo `.meta.json` | Aceptada | Procedencia del análisis no comprobada |
| Modificar prompt, cuerpo sin actualizar hash o corromper JSON | Caché reutilizada | Defectos reproducidos con copias |
| Modificar esquema | Intenta invocar el ejecutable simulado, que sale con código 90 | Invalidación existente confirmada; ninguna llamada real |
| Selector combinado con HTML sintético | Incluye comentario exterior al cuerpo | Causa de contaminación reproducida |

Los cuerpos normalizados tienen 14.550 caracteres para Roberts, 3.064 para Krugman, 307 para Keen, 9.268 para Mitchell y 8.595 para Cochrane. Estas longitudes describen lo extraído; no certifican completitud. Los archivos generados enlazados en el informe son locales y, por diseño, no estarán disponibles en un clon limpio.

Las reproducciones auxiliares de esta sesión quedaron en `/tmp/atlas-audit.R` y `/tmp/atlas-audit-results.txt`. No constituyen una suite permanente. No se encontró una suite de regresión ni configuración de CI entre los archivos revisados. Tampoco se verificó la restauración en una máquina limpia ni se certificó exhaustivamente cada afirmación de los JSON contra la publicación original.

**Aspectos que conviene conservar y orden de trabajo**

La separación entre R, Bash y Make cumple el contrato del proyecto. Los scripts son pequeños y el código de transformación utiliza pipelines y nombres claros. La ingesta calcula SHA-256 sobre el cuerpo, excluyendo la fecha de descarga; el esquema exige los campos analíticos y restringe propiedades adicionales; los pilotos están definidos de forma acumulativa. El entorno local con `renv` supera las comprobaciones, y Git excluye los resultados generados.

Los archivos del entorno reproducible todavía aparecen entre los cambios locales sin incorporar a un commit. Esto limita lo que recibe un clon del estado versionado; no invalida el entorno que se comprobó aquí. El README también contenía un enlace a esta auditoría antes de que existiera el archivo; la incorporación del informe resuelve ese enlace.

El orden recomendado es:

1. Corregir títulos, identidad documental, extracción del cuerpo y clasificación de textos parciales.
2. Completar validación y caché, con pruebas de rechazo de los casos reproducidos y una prueba de dos artículos de la misma fuente.
3. Repetir y revisar los pilotos 1 → 2 → 5; registrar la aprobación humana de texto y análisis.
4. Fortalecer el esquema de afirmaciones y procedencia antes de construir comparaciones entre autores.
5. Como mejora P3, modelar dependencias por artefacto en Make y separar actualización remota de análisis local. Actualmente los objetivos son `.PHONY` y vuelven a descargar los artículos en cada piloto; la incrementabilidad semántica depende del script Bash. Añadir registro de ejecución y protección frente a escrituras concurrentes cuando se habilite el procesamiento paralelo.

El criterio para ampliar el corpus debe ser que ningún documento parcial o contaminado pase como completo, que ningún resultado inválido se reutilice y que las afirmaciones puedan revisarse contra sus fuentes. Después, una tabla comparativa y una vista de consulta aportarían la primera expresión efectiva del atlas.
