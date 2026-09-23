#!/usr/bin/env bash
set -euo pipefail

site_dir="${1:-corpus/reports}"
server="${RS_CONNECT_SERVER:-connect.posit.cloud}"
account="${RS_CONNECT_ACCOUNT:-miparrar}"
app_id="${RS_CONNECT_APP_ID:-01a081a7-cfb9-5b45-0b53-29a9a00cf0b9}"

if [[ ! -s "$site_dir/index.html" ]]; then
  printf 'Falta el sitio generado: ejecuta make site.\n' >&2
  exit 1
fi

RSCONNECT_SITE_DIR="$site_dir" \
RSCONNECT_SERVER="$server" \
RSCONNECT_ACCOUNT="$account" \
RSCONNECT_APP_ID="$app_id" \
Rscript -e '
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Falta el paquete R rsconnect. Instálalo con renv::install(\"rsconnect\").")
}

rsconnect::deployApp(
  appDir = Sys.getenv("RSCONNECT_SITE_DIR"),
  appId = Sys.getenv("RSCONNECT_APP_ID"),
  account = Sys.getenv("RSCONNECT_ACCOUNT"),
  recordDir = ".",
  server = Sys.getenv("RSCONNECT_SERVER"),
  launch.browser = FALSE,
  forceUpdate = TRUE
)
'
