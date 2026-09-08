# Uso: Rscript src/ingest_discovered.R <discovery.csv> <manifest.txt>
# Descarga únicamente las publicaciones previamente descubiertas en fuentes curadas.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Uso: Rscript src/ingest_discovered.R <discovery.csv> <manifest.txt>")
}
discovery_path <- args[[1]]
manifest_path <- args[[2]]

normalize_body <- function(text) {
  text |>
    stringr::str_replace_all("\\r\\n?", "\n") |>
    stringr::str_replace_all("[ \\t]+", " ") |>
    stringr::str_replace_all("\n{3,}", "\n\n") |>
    stringr::str_trim()
}

pick_node <- function(html, selector) {
  if (is.null(selector) || !nzchar(selector)) return(NULL)
  node <- rvest::html_element(html, selector)
  if (inherits(node, "xml_missing")) NULL else node
}

pick_text <- function(html, selector, squash = TRUE) {
  node <- pick_node(html, selector)
  if (is.null(node)) return(NA_character_)
  value <- rvest::html_text2(node)
  if (squash) stringr::str_squish(value) else stringr::str_trim(value)
}

slugify <- function(text) {
  text |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "-") |>
    stringr::str_replace_all("(^-|-$)", "") |>
    stringr::str_sub(1L, 90L)
}

quote_yaml <- function(value) jsonlite::toJSON(value, auto_unbox = TRUE)

existing_path_for_url <- function(source_id, url) {
  root <- file.path("corpus", "posts", source_id)
  if (!dir.exists(root)) return(NA_character_)
  candidates <- list.files(root, pattern = "\\.md$", full.names = TRUE)
  matches <- purrr::keep(candidates, function(path) {
    any(readr::read_lines(path, n_max = 20L) == paste0("source_url: ", quote_yaml(url)))
  })
  if (length(matches) > 1L) stop("URL duplicado en el corpus: ", url)
  if (length(matches) == 1L) matches[[1]] else NA_character_
}

config <- yaml::read_yaml("config/sources.yml")
sources <- rlang::set_names(config$sources, purrr::map_chr(config$sources, "id"))
discovery <- readr::read_csv(discovery_path, show_col_types = FALSE)

required_columns <- c("source_id", "feed_title", "url", "feed_published_at", "discovered_at")
if (!all(required_columns %in% names(discovery))) {
  stop("Descubrimiento inválido; faltan columnas: ",
       paste(setdiff(required_columns, names(discovery)), collapse = ", "))
}

ingest_one <- function(source_id, feed_title, url, feed_published_at, discovered_at) {
  source <- sources[[source_id]]
  if (is.null(source) || !isTRUE(source$monitor)) stop("Fuente no monitoreada: ", source_id)
  if (!startsWith(url, source$base_url)) stop("URL fuera de la fuente curada: ", url)

  response <- httr2::request(url) |>
    httr2::req_user_agent("atlas-crisis/0.1 research corpus") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  html <- httr2::resp_body_html(response)
  body_node <- pick_node(html, source$selectors$body)
  if (is.null(body_node)) stop("No se encontró el cuerpo: ", url)
  if (!is.null(source$selectors$remove)) {
    body_node |>
      rvest::html_elements(source$selectors$remove) |>
      xml2::xml_remove()
  }

  title <- pick_text(html, source$selectors$title)
  if (is.na(title) || !nzchar(title)) title <- feed_title
  body <- rvest::html_text2(body_node) |> normalize_body()
  if (!is.null(source$selectors$truncate_at) &&
      stringr::str_detect(body, stringr::fixed(source$selectors$truncate_at))) {
    body <- stringr::str_split_i(body, stringr::fixed(source$selectors$truncate_at), 1L) |> stringr::str_trim()
  }
  published_at <- pick_text(html, source$selectors$date)
  if (is.na(published_at) || !nzchar(published_at)) published_at <- feed_published_at

  access_status <- "full_text_candidate"
  partial_markers <- stringr::regex(
    "subscribe to read|paid subscribers|upgrade to paid|rest of this post is for paid",
    ignore_case = TRUE
  )
  if (nchar(body) < 800L || stringr::str_detect(body, partial_markers)) {
    access_status <- "partial_candidate"
  }
  if (nchar(body) < 300L) stop("Cuerpo demasiado corto: ", url)

  content_sha256 <- digest::digest(body, algo = "sha256", serialize = FALSE)
  output_dir <- file.path("corpus", "posts", source_id)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output <- existing_path_for_url(source_id, url)
  if (is.na(output)) {
    url_id <- substr(digest::digest(url, algo = "sha256", serialize = FALSE), 1L, 10L)
    output <- file.path(output_dir, paste0(slugify(title), "-", url_id, ".md"))
  }
  document_id <- tools::file_path_sans_ext(basename(output))

  front_matter <- c(
    "---",
    paste0("source_id: ", quote_yaml(source_id)),
    paste0("document_id: ", quote_yaml(document_id)),
    paste0("author: ", quote_yaml(source$author)),
    paste0("publication: ", quote_yaml(source$publication)),
    paste0("title: ", quote_yaml(title)),
    paste0("published_at: ", quote_yaml(published_at)),
    paste0("source_url: ", quote_yaml(url)),
    paste0("discovered_at: ", quote_yaml(discovered_at)),
    paste0("retrieved_at: ", quote_yaml(format(Sys.time(), tz = "UTC", usetz = TRUE))),
    paste0("access_status: ", quote_yaml(access_status)),
    paste0("content_sha256: ", quote_yaml(content_sha256)),
    "---", "", body, ""
  )
  readr::write_lines(front_matter, output)
  message("Ingerido: ", output, " [", access_status, "]")
  output
}

paths <- if (nrow(discovery) == 0L) {
  character()
} else {
  purrr::pmap_chr(discovery[required_columns], ingest_one)
}
dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
readr::write_lines(paths, manifest_path)
message("Manifiesto pendiente: ", manifest_path, " (", length(paths), ")")
