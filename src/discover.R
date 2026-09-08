# Uso: Rscript src/discover.R <latest|new>
# Consulta únicamente los RSS de initial_source_ids configurados en sources.yml.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1]] %in% c("latest", "new")) {
  stop("Uso: Rscript src/discover.R <latest|new>")
}
mode <- args[[1]]

read_node <- function(item, names) {
  xpath <- paste0("./*[", paste0("local-name()='", names, "'", collapse = " or "), "]")
  node <- xml2::xml_find_first(item, xpath)
  if (inherits(node, "xml_missing")) "" else xml2::xml_text(node) |> stringr::str_squish()
}

read_link <- function(item) {
  node <- xml2::xml_find_first(item, "./*[local-name()='link']")
  link <- if (inherits(node, "xml_missing")) "" else xml2::xml_text(node) |> stringr::str_squish()
  if (!nzchar(link) && !inherits(node, "xml_missing")) link <- xml2::xml_attr(node, "href")
  if (!nzchar(link)) link <- read_node(item, "guid")
  sub("#.*$", "", link)
}

read_feed <- function(source) {
  response <- httr2::request(source$feed_url) |>
    httr2::req_user_agent("atlas-crisis/0.1 research corpus") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  xml <- xml2::read_xml(httr2::resp_body_raw(response))
  items <- xml2::xml_find_all(xml, "//*[local-name()='item']")
  if (length(items) == 0L) items <- xml2::xml_find_all(xml, "//*[local-name()='entry']")
  if (length(items) == 0L) stop("Feed sin publicaciones: ", source$feed_url)

  tibble::tibble(
    source_id = source$id,
    feed_title = purrr::map_chr(items, read_node, "title"),
    url = purrr::map_chr(items, read_link),
    feed_published_at = purrr::map_chr(
      items,
      read_node,
      c("pubDate", "published", "updated")
    )
  ) |>
    dplyr::filter(nzchar(url), startsWith(url, source$base_url)) |>
    dplyr::distinct(url, .keep_all = TRUE)
}

config <- yaml::read_yaml("config/sources.yml")
selected <- purrr::map(config$initial_source_ids, function(source_id) {
  source <- purrr::detect(config$sources, \(item) identical(item$id, source_id))
  if (is.null(source)) stop("Fuente inicial desconocida: ", source_id)
  if (!isTRUE(source$monitor)) stop("Monitoreo no habilitado: ", source_id)
  if (is.null(source$feed_url)) stop("Fuente inicial sin feed_url: ", source_id)
  source
})
feeds <- rlang::set_names(purrr::map(selected, read_feed), config$initial_source_ids)

state_path <- file.path("data", "discovery", "state.yml")
state <- if (file.exists(state_path)) yaml::read_yaml(state_path) else list(sources = list())
select_items <- function(items, source_id) {
  if (mode == "latest") return(dplyr::slice_head(items, n = 1L))
  previous_url <- state$sources[[source_id]]$latest_url
  if (is.null(previous_url)) stop("No existe baseline para ", source_id, ". Ejecuta make latest.")
  previous_index <- match(previous_url, items$url)
  if (is.na(previous_index)) {
    stop("El último URL observado ya no aparece en el feed de ", source_id,
         "; se requiere revisión manual.")
  }
  if (previous_index == 1L) return(dplyr::slice_head(items, n = 0L))
  dplyr::slice_head(items, n = previous_index - 1L)
}

pending <- purrr::imap(feeds, select_items) |>
  purrr::list_rbind() |>
  dplyr::mutate(discovered_at = format(Sys.time(), tz = "UTC", usetz = TRUE))
next_state <- list(
  version = 1,
  updated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
  sources = purrr::map(feeds, function(items) {
    list(latest_url = items$url[[1]], latest_title = items$feed_title[[1]])
  })
)

discovery_dir <- file.path("data", "discovery")
dir.create(discovery_dir, recursive = TRUE, showWarnings = FALSE)
readr::write_csv(
  pending,
  file.path(discovery_dir, "pending.csv")
)
yaml::write_yaml(next_state, file.path(discovery_dir, "pending_state.yml"))
message("Descubrimiento ", mode, ": ", nrow(pending), " publicación(es) pendiente(s).")
if (nrow(pending) > 0L) print(pending |> dplyr::select(source_id, feed_title, url))
