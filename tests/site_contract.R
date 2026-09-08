# Pruebas del orden cronológico del sitio; no leen corpus generado.
source("src/site_contract.R")

entry <- function(title, published_at) {
  list(metadata = list(title = title, published_at = published_at))
}

entries <- list(
  entry("Antiguo", "September 4, 2026"),
  entry("Sin fecha", ""),
  entry("Más reciente", "2026-09-08T10:30:00Z"),
  entry("Intermedio", "Mon, 07 Sep 2026 08:00:00 +0000"),
  entry("Fecha inválida", "Foo 2, 2026")
)
ordered <- order_entries_newest_first(entries)
stopifnot(
  identical(
    purrr::map_chr(ordered, \(item) item$metadata$title),
    c("Más reciente", "Intermedio", "Antiguo", "Sin fecha", "Fecha inválida")
  )
)

same_day <- list(entry("Primero", "Sep 08, 2026"), entry("Segundo", "September 8, 2026"))
stopifnot(identical(order_entries_newest_first(same_day), same_day))
message("Contrato del sitio: artículos ordenados del más reciente al más antiguo.")
