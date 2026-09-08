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

read_canonical_document <- function(path) {
  lines <- readr::read_lines(path)
  boundaries <- which(lines == "---")
  if (length(boundaries) < 2L || boundaries[[1]] != 1L) stop("Front matter inválido: ", path)
  end <- boundaries[[2]]
  metadata <- yaml::yaml.load(paste(lines[seq.int(2L, end - 1L)], collapse = "\n"))
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
  if (any(!nzchar(stringr::str_trim(quotes))) || any(!stringr::str_detect(document$body, stringr::fixed(quotes)))) {
    stop("Cita no literal o vacía en el cuerpo del documento")
  }
  invisible(length(quotes))
}

analysis_path <- function(document_path) {
  relative <- document_path |>
    stringr::str_remove("^corpus/posts/") |>
    stringr::str_replace("\\.md$", ".json")
  file.path("data", "analysis", relative)
}
