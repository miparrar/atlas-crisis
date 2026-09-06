library(tidyverse)
library(jsonlite)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop("usage: Rscript src/validate_analysis.R <manifest.txt>")
}

manifest_path <- args[[1]]

documents <- read_lines(manifest_path) |>
  discard(~ .x == "")

analysis_path <- function(document_path) {
  relative <- document_path |>
    str_remove("^corpus/posts/") |>
    str_replace("\\.md$", ".json")

  file.path("data", "analysis", relative)
}

validate_one <- function(document_path) {
  output <- analysis_path(document_path)

  if (!file.exists(output)) {
    stop("missing analysis: ", output)
  }

  document <- read_file(document_path)
  analysis <- fromJSON(output, simplifyVector = FALSE)

  quotes <- if (is.null(analysis$key_quotes)) {
    list()
  } else {
    analysis$key_quotes
  }

  invalid_quotes <- quotes |>
    keep(~ !str_detect(document, fixed(.x)))

  if (length(invalid_quotes) > 0) {
    stop("non-verbatim quote detected in: ", output)
  }

  tibble(
    document = document_path,
    analysis = output,
    quotes = length(quotes),
    valid = TRUE
  )
}

results <- documents |>
  map_dfr(validate_one)

print(results)
