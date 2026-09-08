**Fuentes iniciales de Atlas de la Crisis**

Selección del 7 de septiembre de 2026: Michael Roberts, Adam Tooze y Paul Krugman. La configuración canónica está en [config/sources.yml](../config/sources.yml), bajo `initial_source_ids`. Los demás autores del catálogo quedan como candidatos para una etapa posterior. El orden de trabajo no implica una jerarquía teórica.

| Autor | Publicación seleccionada | Orientación descriptiva del proyecto | Acceso |
| --- | --- | --- | --- |
| Michael Roberts | [Michael Roberts Blog](https://thenextrecession.wordpress.com/) | Economía marxista | Público; verificar integridad por artículo |
| Adam Tooze | [Chartbook](https://adamtooze.substack.com/about) | Historia económica y economía política | Mixto: ensayos gratuitos y contenidos de pago |
| Paul Krugman | [Paul Krugman](https://paulkrugman.substack.com/about) | Economía neokeynesiana | Mixto: mayoría de publicaciones gratuitas y algunas de pago |

Las etiquetas orientan la descripción del catálogo y no agotan las posiciones de cada autor. Cada artículo se analizará en sus propios términos. La selección corresponde a estas publicaciones concretas, no a toda la obra de sus autores: otros sitios, columnas periodísticas o libros requerirían una incorporación explícita.

Roberts presenta su blog como el de un economista marxista. Tooze describe Chartbook como una publicación que combina economía, historia, estadísticas y gráficos, y distingue sus ensayos gratuitos de contenidos para suscriptores como Top Links. Krugman señala que publica principalmente en su Substack desde su salida del New York Times y que combina textos gratuitos y de pago. Estas descripciones se contrastaron con las páginas enlazadas; las etiquetas analíticas de la tabla son decisiones del proyecto.

**Localización de publicaciones**

| Fuente | RSS para publicaciones recientes | Archivo para explorar cobertura histórica |
| --- | --- | --- |
| Michael Roberts | [Feed](https://thenextrecession.wordpress.com/feed/) | [Blog](https://thenextrecession.wordpress.com/blog/) |
| Adam Tooze | [Feed](https://adamtooze.substack.com/feed) | [Archivo](https://adamtooze.substack.com/archive) |
| Paul Krugman | [Feed](https://paulkrugman.substack.com/feed) | [Archivo](https://paulkrugman.substack.com/archive) |

Los seis destinos respondieron HTTP 200 durante la verificación. Los tres feeds eran RSS válidos y contenían, respectivamente, 10, 20 y 20 entradas. Son observaciones de esa fecha, no garantías de disponibilidad futura ni de cobertura completa. La accesibilidad de los archivos no certifica todavía su paginación o extracción automática.

El RSS servirá para localizar entradas, conservando el enlace al artículo como procedencia. No se asumirá que el texto del feed es el artículo completo. La implementación actual sigue utilizando URLs manuales del piloto; todavía no consume los feeds.

**Criterios de selección de documentos**

- Incluir textos sustantivos de autoría identificable sobre crisis económica en sentido amplio: diagnósticos, mecanismos, evidencia, controversias y respuestas de política. La selección no exigirá una teoría o mecanismo determinado.
- Incorporar al corpus analizable solo textos completos de acceso público. Registrar por separado entradas restringidas o parciales, sin convertir la falta de acceso en ausencia de argumentos del autor.
- Excluir comentarios de lectores, navegación, formularios, publicidad de suscripciones y adelantos incompletos.
- Seleccionar ensayos y comentarios propios; excluir listas de enlaces sin desarrollo sustantivo y entradas exclusivamente audiovisuales. En Chartbook, revisar el tipo de entrada antes de incorporarla.
- Conservar el idioma original, los enlaces y las referencias a gráficos o tablas. La calidad de esa conservación se comprobará en la etapa de ingesta.

Quedan por definir el intervalo temporal y las URLs de la nueva muestra. No se establece todavía un número de artículos por autor ni se pretende representatividad estadística.

**Progresión acordada**

Esta entrega cierra la definición de las tres fuentes y sus vías de localización. Después corresponde seleccionar los artículos y validar la extracción: Roberts necesita limpieza; Krugman necesita corregir título y cuerpo; Tooze aún no tiene un extractor validado. Por esa razón, su selección curatorial no cambia automáticamente `enabled`.

El piloto anterior de cinco documentos se conserva como antecedente técnico y no representa esta nueva selección. Antes de volver a ejecutarlo, habrá que adaptarlo. La progresión 1 → 2 → 5 se refiere a documentos acumulativos, no al número de autores. Las políticas añadidas al YAML documentan las decisiones de esta etapa; su aplicación automática queda pendiente de la implementación de ingesta.
