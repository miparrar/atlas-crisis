# Uso: Rscript src/bootstrap.R (desde la raíz del repositorio).
if (!file.exists("renv.lock") || !file.exists("renv/activate.R")) {
  stop("Ejecuta desde la raíz del repositorio, con renv.lock y renv/activate.R presentes.")
}

# .Rprofile activa renv normalmente; también admitir la invocación directa.
if (!requireNamespace("renv", quietly = TRUE)) {
  source("renv/activate.R")
}

lock <- renv::lockfile_read("renv.lock")
current_r <- paste(R.version$major, R.version$minor, sep = ".")
major_minor <- function(version) sub("^([0-9]+\\.[0-9]+).*", "\\1", version)

if (major_minor(current_r) != major_minor(lock$R$Version)) {
  stop("Versión de R incompatible: renv.lock registra ", lock$R$Version,
       "; la versión actual es ", current_r)
}

renv::restore(lockfile = "renv.lock", prompt = FALSE)
message("Entorno R restaurado desde renv.lock.")
