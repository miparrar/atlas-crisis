# Uso: Rscript src/commit_discovery.R <pending-manifest> <pending-state> <catalog> <state>
# Valida el catálogo candidato y promueve catálogo + estado como una transición protegida.
source("src/analysis_contract.R")

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

pending <- readr::read_lines(pending_manifest) |>
  purrr::discard(\(path) !nzchar(stringr::str_trim(path)))
catalog <- if (file.exists(catalog_path)) {
  readr::read_lines(catalog_path) |>
    purrr::discard(\(path) !nzchar(stringr::str_trim(path)))
} else {
  character()
}
candidate <- unique(c(catalog, pending))
if (length(candidate) == 0L) stop("No hay documentos para promover")

pending_state_value <- yaml::read_yaml(pending_state)
if (!is.list(pending_state_value) || is.null(pending_state_value$sources)) {
  stop("Estado pendiente inválido: falta sources")
}

schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE)
candidate_path <- tempfile("catalog-candidate-", tmpdir = dirname(catalog_path), fileext = ".txt")
state_candidate_path <- tempfile("state-candidate-", tmpdir = dirname(state_path), fileext = ".yml")
write_on_exit <- c(candidate_path, state_candidate_path)
on.exit(unlink(write_on_exit[file.exists(write_on_exit)]), add = TRUE)
dir.create(dirname(catalog_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(state_path), recursive = TRUE, showWarnings = FALSE)
readr::write_lines(candidate, candidate_path)
if (!file.copy(pending_state, state_candidate_path, overwrite = TRUE)) {
  stop("No se pudo preparar el estado candidato")
}

# La validación ocurre antes de modificar el catálogo o el estado confirmado.
validate_manifest(candidate_path, schema)

catalog_backup <- tempfile("catalog-backup-", tmpdir = dirname(catalog_path), fileext = ".txt")
state_backup <- tempfile("state-backup-", tmpdir = dirname(state_path), fileext = ".yml")
catalog_exists <- file.exists(catalog_path)
state_exists <- file.exists(state_path)

restore_path <- function(path, backup, existed) {
  if (file.exists(path)) unlink(path)
  if (existed && file.exists(backup) && !file.rename(backup, path)) {
    stop("No se pudo restaurar ", path)
  }
}

catalog_reserved <- FALSE
state_reserved <- FALSE
catalog_promoted <- FALSE
state_promoted <- FALSE
tryCatch({
  if (catalog_exists && !file.rename(catalog_path, catalog_backup)) {
    stop("No se pudo reservar el catálogo actual")
  }
  catalog_reserved <- catalog_exists
  if (!file.rename(candidate_path, catalog_path)) {
    stop("No se pudo promover el catálogo candidato")
  }
  catalog_promoted <- TRUE

  if (state_exists && !file.rename(state_path, state_backup)) {
    stop("No se pudo reservar el estado actual")
  }
  state_reserved <- state_exists
  if (!file.rename(state_candidate_path, state_path)) {
    stop("No se pudo promover el estado candidato")
  }
  state_promoted <- TRUE
}, error = function(error) {
  if (state_reserved || state_promoted) restore_path(state_path, state_backup, state_exists)
  if (catalog_reserved || catalog_promoted) restore_path(catalog_path, catalog_backup, catalog_exists)
  stop(conditionMessage(error), call. = FALSE)
})

unlink(catalog_backup)
unlink(state_backup)
message("Catálogo monitoreado: ", length(candidate), " documento(s).")
