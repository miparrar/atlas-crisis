# Uso: Rscript src/validate_analysis.R <manifest.txt>
source("src/analysis_contract.R")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Uso: Rscript src/validate_analysis.R <manifest.txt>")
schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
documents <- readr::read_lines(args[[1]]) |> purrr::discard(\(x) x == "")
if (length(documents) == 0L) stop("Manifiesto vacío")
results <- purrr::map_dfr(documents, function(path) {
  output <- analysis_path(path)
  document <- read_canonical_document(path)
  analysis <- jsonlite::fromJSON(output, simplifyVector = FALSE)
  quotes <- validate_analysis(analysis, document, schema)
  tibble::tibble(document = path, status = analysis$document_status,
                 problem = !is.null(analysis$problem), quotes = quotes, valid = TRUE)
})
print(results)
message("Contrato, hash y citas comprobados. La calidad interpretativa requiere revisión humana.")
