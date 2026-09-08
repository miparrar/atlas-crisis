source("src/discovery_contract.R")

items <- tibble::tibble(
  source_id = "adam_tooze",
  feed_title = c(
    "Top Links 1218 Why AI is coming to dominate coding",
    "Chartbook 474 A substantive article"
  ),
  url = c(
    "https://adamtooze.substack.com/p/top-links-1218",
    "https://adamtooze.substack.com/p/chartbook-474"
  )
)
source_config <- list(id = "adam_tooze", exclude_title_regex = "^Top Links\\b")

filtered <- suppressMessages(filter_discovery_items(items, source_config))
stopifnot(
  nrow(filtered) == 1L,
  identical(filtered$feed_title, "Chartbook 474 A substantive article")
)

unfiltered <- filter_discovery_items(items, list(id = "adam_tooze"))
stopifnot(identical(unfiltered, items))

empty <- suppressMessages(filter_discovery_items(items[1, ], source_config))
stopifnot(nrow(empty) == 0L)

message("Contrato de descubrimiento: reglas configuradas y ausentes correctas.")
