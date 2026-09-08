# Reglas puras para filtrar formatos no elegibles declarados por fuente.
filter_discovery_items <- function(items, source) {
  pattern <- source$exclude_title_regex
  if (is.null(pattern) || !nzchar(pattern)) return(items)

  excluded <- stringr::str_detect(
    items$feed_title,
    stringr::regex(pattern, ignore_case = TRUE)
  )
  if (any(excluded)) {
    message("Excluidas por regla curatorial [", source$id, "]: ",
            sum(excluded), " entrada(s) del feed.")
  }
  dplyr::filter(items, !excluded)
}
