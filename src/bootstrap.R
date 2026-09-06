required <- c(
  "tidyverse",
  "yaml",
  "rvest",
  "httr2",
  "digest",
  "jsonlite"
)

installed <- rownames(installed.packages())
missing <- setdiff(required, installed)

if (length(missing) == 0) {
  message("R dependencies already installed.")
  quit(status = 0)
}

message("Installing missing R packages: ", paste(missing, collapse = ", "))

install.packages(
  missing,
  repos = "https://cloud.r-project.org"
)
