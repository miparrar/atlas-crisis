library(tidyverse)
library(yaml)
library(rvest)
library(httr2)
library(digest)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop("usage: Rscript src/ingest_pilot.R <pilot_1|pilot_2|pilot_5>")
}

pilot_id <- args[[1]]

sources_cfg <- read_yaml("config/sources.yml")
pilot_cfg <- read_yaml("config/pilot.yml")

sources <- sources_cfg$sources |>
  map_dfr(\(source) {
    tibble(
      id = source$id,
      author = source$author,
      publication = source$publication,
      tradition = source$tradition,
      selectors = list(source$selectors)
    )
  })

pilot_keys <- pilot_cfg$pilots[[pilot_id]]

if (is.null(pilot_keys)) {
  stop("unknown pilot: ", pilot_id)
}

documents <- pilot_keys |>
  map_dfr(\(key) {
    entry <- pilot_cfg$documents[[key]]

    tibble(
      document_id = key,
      source_id = entry$source_id,
      url = entry$url
    )
  }) |>
  left_join(sources, by = c("source_id" = "id"))

pick_text <- function(html, selector, squash = TRUE) {
  if (is.null(selector) || is.na(selector)) {
    return(NA_character_)
  }

  node <- html |>
    html_element(selector)

  if (is.na(node)) {
    return(NA_character_)
  }

  text <- node |>
    html_text2()

  if (squash) {
    str_squish(text)
  } else {
    str_trim(text)
  }
}

normalize_body <- function(text) {
  text |>
    str_replace_all("\\r\\n?", "\n") |>
    str_replace_all("[ \t]+", " ") |>
    str_replace_all("\n{3,}", "\n\n") |>
    str_trim()
}

slugify <- function(text) {
  text |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_replace_all("(^-|-$)", "")
}

ingest_one <- function(document_id, source_id, url, author, publication, tradition, selectors) {
  response <- request(url) |>
    req_user_agent("atlas-crisis/0.1 research corpus") |>
    req_retry(max_tries = 3) |>
    req_perform()

  html <- response |>
    resp_body_html()

  title <- pick_text(html, selectors$title)
  body <- pick_text(html, selectors$body, squash = FALSE)
  published_at <- pick_text(html, selectors$date)

  if (is.na(body) || nchar(body) < 300) {
    stop("body extraction failed or was too short: ", url)
  }

  body <- normalize_body(body)
  content_sha256 <- digest(body, algo = "sha256", serialize = FALSE)

  title <- coalesce(title, document_id)
  published_at <- coalesce(published_at, "")

  slug <- slugify(title)

  output_dir <- file.path("corpus", "posts", source_id)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  output <- file.path(output_dir, paste0(slug, ".md"))

  front_matter <- c(
    "---",
    paste0('source_id: "', source_id, '"'),
    paste0('author: "', str_replace_all(author, '"', '\\"'), '"'),
    paste0('title: "', str_replace_all(title, '"', '\\"'), '"'),
    paste0('published_at: "', str_replace_all(published_at, '"', '\\"'), '"'),
    paste0('source_url: "', url, '"'),
    paste0('retrieved_at: "', format(Sys.time(), tz = "UTC", usetz = TRUE), '"'),
    paste0('content_sha256: "', content_sha256, '"'),
    "---",
    "",
    body,
    ""
  )

  writeLines(front_matter, output)

  tibble(
    document_id = document_id,
    path = output,
    content_sha256 = content_sha256
  )
}

manifest <- documents |>
  pmap_dfr(ingest_one)

manifest_dir <- file.path("data", "manifests")
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

manifest_path <- file.path(manifest_dir, paste0(pilot_id, ".txt"))

manifest |>
  pull(path) |>
  write_lines(manifest_path)

message("wrote manifest: ", manifest_path)
