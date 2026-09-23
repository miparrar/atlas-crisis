# Pruebas de rechazo del contrato analítico; texto sintético, sin red ni LLM.
source("src/analysis_contract.R")
schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
body <- "Los precios aumentan. El autor propone una restricción de oferta como explicación."
claim <- list(description = "El autor identifica un aumento de precios.",
              attribution = "explicita", supporting_quotes = list("Los precios aumentan."))
problem <- list(phenomenon = claim, explanation = NULL, constitutive_elements = list(), evidence = list(), theory = list())
valid <- list(schema_version = "2", summary = "El autor examina un aumento de precios.",
              document_status = "analizable", limitations = list(), problem = problem)
document <- list(body = body)
validate_analysis(valid, document, schema)
reject <- function(value) {
  stopifnot(inherits(tryCatch({validate_analysis(value, document, schema); NULL}, error = identity), "error"))
}
reject(list())
invalid <- valid
invalid$key_quotes <- list("Los precios aumentan.")
reject(invalid)
invalid <- valid
invalid$summary <- 42
reject(invalid)
invalid <- valid
invalid$problem$phenomenon$supporting_quotes <- list("source_id: autor")
reject(invalid)
invalid <- valid
invalid$problem$phenomenon$supporting_quotes <- list()
reject(invalid)
invalid <- valid
invalid$problem$phenomenon$attribution <- "certeza"
reject(invalid)
invalid <- valid
invalid$document_status <- "parcial"
reject(invalid)
partial <- valid
partial$document_status <- "parcial"
partial$limitations <- list("Solo se dispone de un adelanto.")
partial["problem"] <- list(NULL)
validate_analysis(partial, document, schema)

short <- short_document_analysis("Texto demasiado breve para elaborar una ficha analítica.")
validate_analysis(short, document, schema)
stopifnot(short$document_status == "sin_contenido_analitico", is.null(short$problem))

invalid <- valid
invalid$problems <- list(problem, problem)
reject(invalid)
# Una teoría nueva también debe estar respaldada por una cita real.
invalid <- valid
invalid$problem$theory <- list(list(name = "Marco", description = "Interpretación",
  attribution = "inferencia", role = "utilizada", supporting_quotes = list("Cita inexistente")))
reject(invalid)
# El hash canónico se comprueba independientemente del JSON.
path <- tempfile(fileext = ".md")
content_hash <- digest::digest(body, algo = "sha256", serialize = FALSE)
writeLines(c(
  "---",
  'source_id: "test"',
  'document_id: "test-document"',
  'author: "Autor"',
  'publication: "Publicación"',
  'title: "Título"',
  'published_at: ""',
  'source_url: "https://example.test/post"',
  'discovered_at: "2026-09-21T00:00:00Z"',
  'retrieved_at: "2026-09-21T00:00:00Z"',
  'access_status: "full_text_candidate"',
  paste0('content_sha256: "', content_hash, '"'),
  "---", "", body
), path)
stopifnot(identical(read_canonical_document(path)$body, body))
cat("\nCambio", file = path, append = TRUE)
stopifnot(inherits(tryCatch({read_canonical_document(path); NULL}, error = identity), "error"))
unlink(path)
message("Contrato analítico: aceptación, rechazos, citas anidadas y hash correctos.")
