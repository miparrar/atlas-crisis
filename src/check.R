# Uso: Rscript src/check.R (comprobaciones locales sin instalación ni LLM).
required <- c("renv", "yaml", "rvest", "httr2", "digest", "jsonlite", "xml2",
              "stringi", "readr", "purrr", "stringr", "dplyr", "rlang", "tibble")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Faltan paquetes R: ", paste(missing, collapse = ", "), ". Ejecuta make setup.")
}

lock <- renv::lockfile_read("renv.lock")
current_r <- paste(R.version$major, R.version$minor, sep = ".")
major_minor <- function(version) sub("^([0-9]+\\.[0-9]+).*", "\\1", version)
if (major_minor(current_r) != major_minor(lock$R$Version)) {
  stop("Versión de R incompatible: se esperaba ", lock$R$Version, "; se encontró ", current_r)
}

unrecorded <- setdiff(required, names(lock$Packages))
if (length(unrecorded) > 0L) {
  stop("Dependencias ausentes de renv.lock: ", paste(unrecorded, collapse = ", "))
}

mismatched <- names(lock$Packages) |>
  purrr::keep(function(package) {
    !requireNamespace(package, quietly = TRUE) ||
      utils::packageVersion(package) != package_version(lock$Packages[[package]]$Version)
  })
if (length(mismatched) > 0L) {
  stop("Paquetes distintos de renv.lock: ", paste(mismatched, collapse = ", "),
       ". Ejecuta make setup.")
}

list.files("src", pattern = "\\.R$", full.names = TRUE) |>
  purrr::walk(\(path) invisible(parse(file = path)))

schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
if (!identical(schema$type, "object") ||
    !setequal(unlist(schema$required), names(schema$properties))) {
  stop("Esquema inválido: se esperaba un objeto con todas sus propiedades obligatorias.")
}

source_config <- yaml::read_yaml("config/sources.yml")
sources <- source_config$sources
source_ids <- purrr::map_chr(sources, "id")
if (anyDuplicated(source_ids)) {
  stop("Identificadores de fuentes duplicados en config/sources.yml.")
}

required_source_fields <- c(
  "id", "author", "tradition", "publication", "focus", "curatorial_note",
  "base_url", "discovery", "access", "enabled", "monitor", "extraction_status"
)
purrr::walk(sources, function(source) {
  missing_fields <- setdiff(required_source_fields, names(source))
  if (length(missing_fields) > 0L) {
    stop("Fuente incompleta ", source$id, ": ", paste(missing_fields, collapse = ", "))
  }
  if (length(source$focus) == 0L) stop("Fuente sin foco curatorial: ", source$id)
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
  if (!isTRUE(source$monitor)) stop("Fuente monitoreada sin monitor: ", source_id)
  required_fields <- c("base_url", "feed_url")
  if (any(!required_fields %in% names(source))) stop("Fuente monitoreada incompleta: ", source_id)
  required_selectors <- c("title", "body", "date")
  if (is.null(source$selectors) || any(!required_selectors %in% names(source$selectors))) {
    stop("Faltan selectores de monitoreo para: ", source_id)
  }
})

message("Dependencias R, sintaxis, esquema y catálogo de fuentes: ok.")
message("Estas comprobaciones no certifican la calidad del corpus ni de los análisis.")
