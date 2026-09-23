# Uso: Rscript src/check.R (contratos del proyecto; no instala ni llama al LLM).
list.files("src", pattern = "\\.R$", full.names = TRUE) |>
  purrr::walk(\(path) invisible(parse(file = path)))

schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
if (!identical(schema$type, "object") ||
    !setequal(unlist(schema$required), names(schema$properties))) {
  stop("Esquema inválido: se esperaba un objeto con todas sus propiedades obligatorias.")
}

source_config <- yaml::read_yaml("config/sources.yml")
sources <- source_config$sources
if (!is.list(sources) || length(sources) == 0L) stop("No hay fuentes configuradas.")
source_ids <- purrr::map_chr(sources, "id")
if (anyDuplicated(source_ids)) stop("Identificadores de fuentes duplicados en config/sources.yml.")

required_source_fields <- c(
  "id", "author", "tradition", "publication", "focus", "curatorial_note",
  "base_url", "discovery", "access", "enabled", "monitor", "extraction_status"
)
required_text_fields <- c("id", "author", "tradition", "publication", "curatorial_note",
                          "base_url", "discovery", "access", "extraction_status")

purrr::walk(sources, function(source) {
  missing_fields <- setdiff(required_source_fields, names(source))
  if (length(missing_fields) > 0L) {
    source_label <- if (is.null(source$id)) "(sin id)" else source$id
    stop("Fuente incompleta ", source_label, ": ",
         paste(missing_fields, collapse = ", "))
  }
  invalid_text <- purrr::keep(required_text_fields, function(field) {
    value <- source[[field]]
    !is.character(value) || length(value) != 1L || !nzchar(stringr::str_trim(value))
  })
  if (length(invalid_text) > 0L) {
    stop("Fuente ", source$id, " tiene campos textuales inválidos: ", paste(invalid_text, collapse = ", "))
  }
  if (!is.character(source$focus) || length(source$focus) == 0L || any(!nzchar(source$focus))) {
    stop("Fuente sin foco curatorial válido: ", source$id)
  }
  if (!stringr::str_detect(source$base_url, "^https?://")) {
    stop("URL base inválida para ", source$id)
  }
  if (!is.logical(source$enabled) || length(source$enabled) != 1L ||
      !is.logical(source$monitor) || length(source$monitor) != 1L) {
    stop("enabled y monitor deben ser booleanos escalares en ", source$id)
  }
  if (isTRUE(source$monitor) && !isTRUE(source$enabled)) {
    stop("Fuente monitoreada pero deshabilitada: ", source$id)
  }
  if (!is.null(source$exclude_title_regex)) {
    tryCatch(
      stringr::str_detect("", stringr::regex(source$exclude_title_regex)),
      error = \(error) stop("Patrón de exclusión inválido para ", source$id, ": ", error$message)
    )
  }
})

monitor_flags <- sources |>
  purrr::keep(\(source) isTRUE(source$monitor)) |>
  purrr::map_chr("id")
if (!setequal(monitor_flags, source_config$monitored_source_ids)) {
  stop("Los indicadores monitor no coinciden con monitored_source_ids.")
}
if (length(source_config$monitored_source_ids) == 0L ||
    anyDuplicated(source_config$monitored_source_ids) ||
    !all(source_config$monitored_source_ids %in% source_ids)) {
  stop("monitored_source_ids está vacío o contiene fuentes duplicadas o desconocidas.")
}

purrr::walk(source_config$monitored_source_ids, function(source_id) {
  source <- sources[[match(source_id, source_ids)]]
  required_fields <- c("base_url", "feed_url", "archive_url", "platform", "language",
                       "source_verified_at", "access_note")
  if (any(!required_fields %in% names(source))) {
    stop("Fuente monitoreada incompleta: ", source_id, "; faltan ",
         paste(setdiff(required_fields, names(source)), collapse = ", "))
  }
  if (!stringr::str_detect(source$feed_url, "^https?://") ||
      !stringr::str_detect(source$archive_url, "^https?://")) {
    stop("URLs de feed o archivo inválidas: ", source_id)
  }
  required_selectors <- c("title", "body", "date")
  if (is.null(source$selectors) || any(!required_selectors %in% names(source$selectors))) {
    stop("Faltan selectores de monitoreo para: ", source_id)
  }
  invalid_selectors <- purrr::keep(required_selectors, function(field) {
    !is.character(source$selectors[[field]]) || length(source$selectors[[field]]) != 1L ||
      !nzchar(stringr::str_trim(source$selectors[[field]]))
  })
  if (length(invalid_selectors) > 0L) {
    stop("Selectores vacíos para ", source_id, ": ", paste(invalid_selectors, collapse = ", "))
  }
})

message("Esquema, sintaxis y catálogo de fuentes: ok.")
message("Estas comprobaciones no certifican la calidad interpretativa del corpus.")
