# Funciones compartidas de validación del contrato. Sin llamadas al LLM.
# Valida el subconjunto de JSON Schema utilizado por el proyecto y rechaza
# palabras clave no soportadas, para no omitir restricciones silenciosamente.
validate_schema_value <- function(value, schema, root = schema, path = "$") {
  allowed <- c("type", "properties", "required", "additionalProperties", "items",
               "enum", "minItems", "minLength", "anyOf", "$ref", "$defs", "description")
  unknown <- setdiff(names(schema), allowed)
  if (length(unknown) > 0L) stop("Restricciones no soportadas: ", paste(unknown, collapse = ", "))
  fail <- function(...) stop(path, ": ", ..., call. = FALSE)
  if (!is.null(schema[["$ref"]])) {
    ref <- schema[["$ref"]]
    if (!startsWith(ref, "#/$defs/")) fail("referencia de esquema no soportada")
    definition <- root[["$defs"]][[sub("^#/\\$defs/", "", ref)]]
    if (is.null(definition)) fail("referencia desconocida")
    return(validate_schema_value(value, definition, root, path))
  }
  if (!is.null(schema$anyOf)) {
    valid <- purrr::some(schema$anyOf, function(option) {
      tryCatch({validate_schema_value(value, option, root, path); TRUE}, error = function(e) FALSE)
    })
    if (!valid) fail("no coincide con ninguna alternativa del esquema")
    return(invisible(TRUE))
  }
  actual <- if (is.null(value)) "null" else if (is.list(value)) {
    if (is.null(names(value))) "array" else "object"
  } else if (is.character(value) && length(value) == 1L) "string" else "other"
  if (!actual %in% unlist(schema$type)) fail("tipo incorrecto: ", actual)
  if (!is.null(schema$enum) && !value %in% unlist(schema$enum)) fail("valor fuera del vocabulario")
  if (actual == "string" && !is.null(schema$minLength) && nchar(value) < schema$minLength) fail("texto vacío")
  if (actual == "object") {
    missing <- setdiff(unlist(schema$required), names(value))
    extra <- setdiff(names(value), names(schema$properties))
    if (length(missing) > 0L) fail(paste("faltan campos:", paste(missing, collapse = ", ")))
    if (identical(schema$additionalProperties, FALSE) && length(extra) > 0L) fail("campos no permitidos")
    purrr::iwalk(value, \(item, name) validate_schema_value(item, schema$properties[[name]], root, paste0(path, ".", name)))
  }
  if (actual == "array") {
    if (!is.null(schema$minItems) && length(value) < schema$minItems) fail("faltan elementos")
    purrr::iwalk(value, \(item, index) validate_schema_value(item, schema$items, root, paste0(path, "[", index, "]")))
  }
  invisible(TRUE)
}

required_document_metadata <- c(
  "source_id", "document_id", "author", "publication", "title",
  "published_at", "source_url", "discovered_at", "retrieved_at",
  "access_status", "content_sha256"
)

validate_document_metadata <- function(metadata, path = "document") {
  fail <- function(...) stop(path, ": ", ..., call. = FALSE)
  missing <- setdiff(required_document_metadata, names(metadata))
  if (length(missing) > 0L) fail("faltan metadatos: ", paste(missing, collapse = ", "))

  scalar_fields <- setdiff(required_document_metadata, "published_at")
  invalid_scalar <- purrr::keep(scalar_fields, function(field) {
    value <- metadata[[field]]
    !is.character(value) || length(value) != 1L || !nzchar(stringr::str_trim(value))
  })
  if (length(invalid_scalar) > 0L) {
    fail("metadatos vacíos o no escalares: ", paste(invalid_scalar, collapse = ", "))
  }
  if (!is.null(metadata$published_at) &&
      (!is.character(metadata$published_at) || length(metadata$published_at) != 1L)) {
    fail("published_at debe ser texto escalar o null cuando no está disponible")
  }
  if (!stringr::str_detect(metadata$source_url, "^https?://")) {
    fail("source_url no es una URL HTTP(S)")
  }
  if (!stringr::str_detect(metadata$content_sha256, "^[0-9a-f]{64}$")) {
    fail("content_sha256 no es un SHA-256 hexadecimal")
  }
  if (!is.null(metadata$ingestion_note) &&
      (!is.character(metadata$ingestion_note) || length(metadata$ingestion_note) != 1L ||
       !nzchar(stringr::str_trim(metadata$ingestion_note)))) {
    fail("ingestion_note debe ser texto no vacío cuando existe")
  }
  invisible(TRUE)
}

read_canonical_document <- function(path) {
  lines <- readr::read_lines(path)
  boundaries <- which(lines == "---")
  if (length(boundaries) < 2L || boundaries[[1]] != 1L) stop("Front matter inválido: ", path)
  end <- boundaries[[2]]
  metadata <- yaml::yaml.load(paste(lines[seq.int(2L, end - 1L)], collapse = "\n"))
  validate_document_metadata(metadata, path)
  body <- paste(lines[seq_along(lines) > end], collapse = "\n") |>
    stringr::str_replace_all("\\r\\n?", "\n") |>
    stringr::str_replace_all("[ \\t]+", " ") |>
    stringr::str_replace_all("\n{3,}", "\n\n") |>
    stringr::str_trim()
  hash <- digest::digest(body, algo = "sha256", serialize = FALSE)
  if (!identical(hash, metadata$content_sha256)) stop("Hash del cuerpo incorrecto: ", path)
  list(metadata = metadata, body = body)
}

collect_analysis_quotes <- function(value) {
  if (!is.list(value)) return(character())
  direct <- unlist(value$supporting_quotes, use.names = FALSE)
  nested <- value[setdiff(names(value), "supporting_quotes")]
  if (is.null(names(value))) nested <- value
  c(direct, unlist(purrr::map(nested, collect_analysis_quotes), use.names = FALSE))
}

validate_analysis <- function(analysis, document, schema) {
  validate_schema_value(analysis, schema)
  if (analysis$document_status == "analizable" && is.null(analysis$problem)) stop("Falta el problema central en ficha analizable")
  if (analysis$document_status != "analizable" && !is.null(analysis$problem)) stop("Un documento insuficiente no puede tener un problema analítico")
  if (analysis$document_status != "analizable" && length(analysis$limitations) == 0L) stop("Falta explicar la limitación documental")
  quotes <- collect_analysis_quotes(analysis)
  trimmed_quotes <- stringr::str_trim(quotes)
  empty_quotes <- which(!nzchar(trimmed_quotes))
  missing_quotes <- which(nzchar(trimmed_quotes) &
    !stringr::str_detect(document$body, stringr::fixed(trimmed_quotes)))
  if (length(empty_quotes) > 0L || length(missing_quotes) > 0L) {
    describe_quote <- function(index) {
      value <- stringr::str_replace_all(trimmed_quotes[[index]], "\\s+", " ")
      paste0("#", index, "=\"", stringr::str_sub(value, 1L, 180L),
             if (nchar(value) > 180L) "…" else "\"")
    }
    details <- c(
      if (length(empty_quotes) > 0L) paste0("vacías: ", paste(empty_quotes, collapse = ", ")),
      if (length(missing_quotes) > 0L) paste0("no encontradas: ",
        paste(purrr::map_chr(missing_quotes, describe_quote), collapse = "; "))
    )
    stop("Citas inválidas en el cuerpo del documento (", paste(details, collapse = "; "), ")")
  }
  invisible(length(quotes))
}

analysis_path <- function(document_path) {
  relative <- document_path |>
    stringr::str_remove("^corpus/posts/") |>
    stringr::str_replace("\\.md$", ".json")
  file.path("data", "analysis", relative)
}

analysis_meta_path <- function(document_path) {
  analysis_path(document_path) |>
    stringr::str_replace("\\.json$", ".meta.json")
}

file_sha256 <- function(path) {
  digest::digest(readr::read_file(path), algo = "sha256", serialize = FALSE)
}

validate_analysis_output <- function(document_path, schema,
                                      schema_path = "config/analysis_schema.json",
                                      prompt_path = "prompts/analyze.md") {
  output_path <- analysis_path(document_path)
  metadata_path <- analysis_meta_path(document_path)
  if (!file.exists(output_path)) stop("Falta análisis: ", output_path, call. = FALSE)
  if (!file.exists(metadata_path)) stop("Falta metadata del análisis: ", metadata_path, call. = FALSE)

  document <- read_canonical_document(document_path)
  analysis <- jsonlite::fromJSON(output_path, simplifyVector = FALSE)
  quotes <- tryCatch(
    validate_analysis(analysis, document, schema),
    error = function(error) stop("Análisis inválido ", document_path, ": ",
                                 conditionMessage(error), call. = FALSE)
  )
  analysis_metadata <- jsonlite::fromJSON(metadata_path, simplifyVector = FALSE)
  required <- c("document", "content_sha256", "schema_sha256", "prompt_sha256",
                "llm_backend", "model", "provider_version")
  missing <- setdiff(required, names(analysis_metadata))
  if (length(missing) > 0L) {
    stop("Metadata de análisis incompleta ", metadata_path, ": ",
         paste(missing, collapse = ", "),
         ". Ejecuta make reanalyze para regenerar las fichas legacy.",
         call. = FALSE)
  }

  expected <- c(
    document = document_path,
    content_sha256 = document$metadata$content_sha256,
    schema_sha256 = file_sha256(schema_path),
    prompt_sha256 = file_sha256(prompt_path)
  )
  mismatched <- purrr::keep(names(expected), function(field) {
    !identical(as.character(analysis_metadata[[field]]), expected[[field]])
  })
  if (length(mismatched) > 0L) {
    stop("Metadata de análisis obsoleta o inconsistente ", metadata_path, ": ",
         paste(mismatched, collapse = ", "), call. = FALSE)
  }

  list(document = document, analysis = analysis, metadata = analysis_metadata,
       quotes = quotes)
}

validate_manifest <- function(manifest_path, schema) {
  documents <- readr::read_lines(manifest_path) |>
    purrr::discard(\(path) !nzchar(stringr::str_trim(path)))
  if (length(documents) == 0L) stop("Manifiesto vacío: ", manifest_path, call. = FALSE)
  purrr::map_dfr(documents, function(path) {
    validated <- validate_analysis_output(path, schema)
    tibble::tibble(
      document = path,
      status = validated$analysis$document_status,
      problem = !is.null(validated$analysis$problem),
      quotes = validated$quotes,
      valid = TRUE
    )
  })
}

short_document_analysis <- function(note) {
  list(
    schema_version = "2",
    summary = note,
    document_status = "sin_contenido_analitico",
    limitations = list(note),
    problem = NULL
  )
}
