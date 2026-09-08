# Funciones puras compartidas por el generador y sus pruebas.
parse_publication_date <- function(value) {
  if (is.null(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
    return(as.Date(NA))
  }

  value <- stringr::str_squish(value)
  iso_date <- stringr::str_extract(value, "^\\d{4}-\\d{2}-\\d{2}")
  if (!is.na(iso_date)) return(as.Date(iso_date))

  months <- rlang::set_names(
    sprintf("%02d", seq_len(12L)),
    c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
  )
  month_day_year <- stringr::str_match(
    value,
    "^(?:[A-Za-z]{3},\\s+)?([A-Za-z]+)\\s+(\\d{1,2}),?\\s+(\\d{4})"
  )
  day_month_year <- stringr::str_match(
    value,
    "^(?:[A-Za-z]{3},\\s+)?(\\d{1,2})\\s+([A-Za-z]+)\\s+(\\d{4})"
  )

  if (!is.na(month_day_year[1L, 1L])) {
    month <- months[stringr::str_to_lower(month_day_year[1L, 2L]) |> stringr::str_sub(1L, 3L)] |>
      unname()
    day <- month_day_year[1L, 3L]
    year <- month_day_year[1L, 4L]
  } else if (!is.na(day_month_year[1L, 1L])) {
    month <- months[stringr::str_to_lower(day_month_year[1L, 3L]) |> stringr::str_sub(1L, 3L)] |>
      unname()
    day <- day_month_year[1L, 2L]
    year <- day_month_year[1L, 4L]
  } else {
    return(as.Date(NA))
  }

  if (is.na(month)) return(as.Date(NA))
  as.Date(sprintf("%s-%s-%02d", year, month, as.integer(day)))
}

order_entries_newest_first <- function(entries) {
  dates <- purrr::map(entries, \(entry) parse_publication_date(entry$metadata$published_at)) |>
    do.call(what = c)
  entries[order(dates, decreasing = TRUE, na.last = TRUE, method = "radix")]
}
