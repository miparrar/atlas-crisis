#!/usr/bin/env bash
# Carga variables locales desde .Renviron sin versionar secretos.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$repo_root/.Renviron" ]]; then
  set -a
  # .Renviron debe usar asignaciones compatibles con shell: KEY=value.
  # shellcheck disable=SC1091
  source "$repo_root/.Renviron"
  set +a
fi
