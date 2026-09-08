# Uso: Rscript src/commit_discovery.R <pending-manifest> <pending-state> <catalog> <state>
# Se ejecuta solo después de analizar y validar todo el lote pendiente.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop("Uso: Rscript src/commit_discovery.R <pending-manifest> <pending-state> <catalog> <state>")
}
pending_manifest <- args[[1]]
pending_state <- args[[2]]
catalog_path <- args[[3]]
state_path <- args[[4]]

if (!file.exists(pending_manifest)) stop("Falta manifiesto pendiente: ", pending_manifest)
if (!file.exists(pending_state)) stop("Falta estado pendiente: ", pending_state)

pending <- readr::read_lines(pending_manifest) |> purrr::discard(\(path) path == "")
catalog <- if (file.exists(catalog_path)) {
  readr::read_lines(catalog_path) |> purrr::discard(\(path) path == "")
} else {
  character()
}
catalog <- unique(c(catalog, pending))
dir.create(dirname(catalog_path), recursive = TRUE, showWarnings = FALSE)
readr::write_lines(catalog, catalog_path)
dir.create(dirname(state_path), recursive = TRUE, showWarnings = FALSE)
copied <- file.copy(pending_state, state_path, overwrite = TRUE)
if (!copied) stop("No se pudo promover el estado pendiente: ", pending_state)
message("Catálogo monitoreado: ", length(catalog), " documento(s).")
