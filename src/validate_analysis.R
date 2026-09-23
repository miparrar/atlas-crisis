# Uso: Rscript src/validate_analysis.R <manifest.txt>
source("src/analysis_contract.R")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Uso: Rscript src/validate_analysis.R <manifest.txt>")
schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
results <- validate_manifest(args[[1]], schema)
print(results)
message("Contrato, metadatos, hash y citas comprobados. La calidad interpretativa requiere revisión humana.")
