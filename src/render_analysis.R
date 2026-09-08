# Uso: Rscript src/render_analysis.R <manifest.txt>
# Genera un sitio HTML estático en corpus/reports/, sin red ni LLM.
source("src/analysis_contract.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Uso: Rscript src/render_analysis.R <manifest.txt>")

escape_html <- function(text) {
  if (is.null(text)) return("")
  stringr::str_replace_all(
    as.character(text),
    c("&" = "&amp;", "<" = "&lt;", ">" = "&gt;", '"' = "&quot;", "'" = "&#39;")
  )
}

join_html <- function(items, render) {
  paste(purrr::map_chr(items, render), collapse = "\n")
}

html_page <- function(title, body, css) {
  paste0(
    '<!doctype html><html lang="es"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    "<title>", escape_html(title), " · Atlas de la Crisis</title>",
    "<style>", css, "</style></head><body><main>", body, "</main></body></html>"
  )
}

render_quotes <- function(quotes) {
  paste0(
    '<details class="quotes"><summary>',
    if (length(quotes) == 1L) "Cita de respaldo" else paste(length(quotes), "citas de respaldo"),
    "</summary>",
    join_html(quotes, \(quote) paste0("<blockquote>", escape_html(quote), "</blockquote>")),
    "</details>"
  )
}

render_inference <- function(attribution) {
  if (attribution == "inferencia") '<span class="inference">Inferencia</span>' else ""
}

render_claim <- function(claim) {
  if (is.null(claim)) return('<p class="empty">No desarrollada en el texto.</p>')
  paste0(
    '<div class="item">', render_inference(claim$attribution),
    "<p>", escape_html(claim$description), "</p>",
    render_quotes(claim$supporting_quotes), "</div>"
  )
}

render_list <- function(items, render) {
  if (length(items) == 0L) return('<p class="empty">No identificado en el texto.</p>')
  join_html(items, render)
}

render_evidence <- function(item) {
  source <- if (is.null(item$source)) "Fuente no identificada" else item$source
  unavailable <- if (item$availability == "referida_no_disponible") {
    '<span class="unavailable">No disponible en el cuerpo</span>'
  } else {
    ""
  }
  paste0(
    '<div class="item"><p>', escape_html(item$description), "</p>",
    '<p class="meta">', escape_html(item$kind), " · ", escape_html(source), unavailable, "</p>",
    render_quotes(item$supporting_quotes), "</div>"
  )
}

render_theory <- function(item) {
  roles <- c(utilizada = "Utilizada", discutida = "Discutida", rechazada = "Rechazada")
  paste0(
    '<div class="item"><p class="item-title">', escape_html(item$name),
    '<span class="meta">', roles[[item$role]], "</span>",
    render_inference(item$attribution), "</p>",
    "<p>", escape_html(item$description), "</p>",
    render_quotes(item$supporting_quotes), "</div>"
  )
}

render_section <- function(number, title, content) {
  paste0(
    '<section class="section"><h3><span>', number, "</span>", title, "</h3>",
    content, "</section>"
  )
}

render_problem <- function(problem) {
  if (is.null(problem)) return("")
  paste0(
    '<article class="problem">',
    render_section("01", "Fenómeno o problema", render_claim(problem$phenomenon)),
    render_section("02", "Explicación o interpretación", render_claim(problem$explanation)),
    render_section("03", "Elementos constitutivos", render_list(problem$constitutive_elements, render_claim)),
    render_section("04", "Evidencia", render_list(problem$evidence, render_evidence)),
    render_section("05", "Teoría", render_list(problem$theory, render_theory)),
    "</article>"
  )
}

render_limitations <- function(limitations) {
  if (length(limitations) == 0L) return("")
  paste0(
    '<aside class="limitations"><strong>Limitaciones</strong><ul>',
    join_html(limitations, \(item) paste0("<li>", escape_html(item), "</li>")),
    "</ul></aside>"
  )
}

render_date <- function(published_at) {
  if (is.null(published_at) || !nzchar(published_at)) return("")
  paste0("<span>", escape_html(published_at), "</span>")
}

status_label <- function(status) {
  c(
    analizable = "Pendiente de revisión humana",
    parcial = "Documento parcial",
    sin_contenido_analitico = "Sin contenido analítico suficiente"
  )[[status]]
}

read_entry <- function(path, schema) {
  document <- read_canonical_document(path)
  analysis <- jsonlite::fromJSON(analysis_path(path), simplifyVector = FALSE)
  validate_analysis(analysis, document, schema)
  relative <- path |>
    stringr::str_remove("^corpus/posts/") |>
    stringr::str_replace("\\.md$", ".html")
  list(
    path = path,
    source_id = document$metadata$source_id,
    metadata = document$metadata,
    analysis = analysis,
    relative = relative
  )
}

render_article <- function(entry, css) {
  metadata <- entry$metadata
  analysis <- entry$analysis
  body <- paste0(
    '<header class="page-header"><p class="brand"><a href="../index.html">Atlas de la Crisis</a></p>',
    "<h1>", escape_html(metadata$title), "</h1>",
    '<p class="byline"><a href="index.html"><strong>', escape_html(metadata$author), "</strong></a>",
    render_date(metadata$published_at),
    '<a href="', escape_html(metadata$source_url), '">Texto original ↗</a></p>',
    '<p class="status">', status_label(analysis$document_status), "</p></header>",
    '<section class="summary"><h2>Síntesis</h2><p>', escape_html(analysis$summary), "</p></section>",
    render_limitations(analysis$limitations),
    render_problem(analysis$problem),
    '<footer><details class="provenance"><summary>Procedencia</summary>',
    "<p>Extracción automática. Las citas se comprobaron contra el documento local; la interpretación y la evidencia requieren revisión humana.</p><dl>",
    "<dt>Documento</dt><dd>", escape_html(entry$path), "</dd>",
    "<dt>Recuperado</dt><dd>", escape_html(metadata$retrieved_at), "</dd>",
    "<dt>SHA-256</dt><dd><code>", escape_html(metadata$content_sha256), "</code></dd>",
    "<dt>Contrato</dt><dd>v", escape_html(analysis$schema_version), "</dd>",
    "</dl></details></footer>"
  )
  html_page(metadata$title, body, css)
}

render_article_link <- function(entry) {
  paste0(
    '<article class="article-link"><h2><a href="', escape_html(basename(entry$relative)), '">',
    escape_html(entry$metadata$title), "</a></h2>",
    '<p class="meta">', escape_html(entry$metadata$published_at), " · ",
    escape_html(status_label(entry$analysis$document_status)), "</p>",
    "<p>", escape_html(entry$analysis$summary), "</p></article>"
  )
}

render_author <- function(entries, source, css) {
  author <- entries[[1]]$metadata$author
  count <- length(entries)
  body <- paste0(
    '<header class="page-header"><p class="brand"><a href="../index.html">Atlas de la Crisis</a></p>',
    "<h1>", escape_html(author), "</h1>",
    '<p class="lede">', escape_html(source$publication), "</p>",
    '<p class="site-count">', count, if (count == 1L) " artículo" else " artículos", "</p></header>",
    '<section class="listing" aria-label="Artículos">',
    join_html(entries, render_article_link), "</section>"
  )
  html_page(author, body, css)
}

render_author_link <- function(entries, source) {
  count <- length(entries)
  paste0(
    '<article class="author-link"><h2><a href="', escape_html(source$id), '/index.html">',
    escape_html(source$author), "</a></h2>",
    "<p>", escape_html(source$publication), "</p>",
    '<p class="meta">', count, if (count == 1L) " artículo" else " artículos", "</p></article>"
  )
}

render_home <- function(groups, sources, css) {
  article_count <- sum(purrr::map_int(groups, length))
  author_count <- length(groups)
  cards <- purrr::imap_chr(groups, function(entries, source_id) {
    render_author_link(entries, sources[[source_id]])
  }) |>
    paste(collapse = "\n")
  body <- paste0(
    '<header class="page-header home"><p class="brand">Atlas de la Crisis</p>',
    "<h1>Interpretaciones de la crisis económica</h1>",
    '<p class="lede">Lecturas trazables de cómo distintos autores identifican y explican un problema económico central.</p>',
    '<p class="site-count">', author_count, if (author_count == 1L) " autor" else " autores",
    " · ", article_count, if (article_count == 1L) " artículo" else " artículos", "</p></header>",
    '<section class="listing" aria-label="Autores"><h2>Autores</h2>', cards, "</section>"
  )
  html_page("Inicio", body, css)
}

schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
css <- readr::read_file("templates/analysis.css")
documents <- readr::read_lines(args[[1]]) |>
  purrr::discard(\(path) path == "")
if (length(documents) == 0L) stop("Manifiesto vacío")

entries <- purrr::map(documents, read_entry, schema = schema)
groups <- split(entries, purrr::map_chr(entries, "source_id"))
source_list <- yaml::read_yaml("config/sources.yml")$sources
sources <- rlang::set_names(source_list, purrr::map_chr(source_list, "id"))
unknown_sources <- setdiff(names(groups), names(sources))
if (length(unknown_sources) > 0L) stop("Fuentes desconocidas: ", paste(unknown_sources, collapse = ", "))

report_root <- file.path("corpus", "reports")
unlink(report_root, recursive = TRUE)
dir.create(report_root, recursive = TRUE, showWarnings = FALSE)
readr::write_file(render_home(groups, sources, css), file.path(report_root, "index.html"))
readr::write_file("", file.path(report_root, ".nojekyll"))

purrr::iwalk(groups, function(author_entries, source_id) {
  author_dir <- file.path(report_root, source_id)
  dir.create(author_dir, recursive = TRUE, showWarnings = FALSE)
  readr::write_file(
    render_author(author_entries, sources[[source_id]], css),
    file.path(author_dir, "index.html")
  )
  purrr::walk(author_entries, function(entry) {
    output <- file.path(report_root, entry$relative)
    dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
    readr::write_file(render_article(entry, css), output)
    message("Ficha generada: ", output)
  })
})
message("Sitio generado: ", file.path(report_root, "index.html"))
