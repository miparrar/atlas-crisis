#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: scripts/update.sh <latest|new>}"
if [[ "$mode" != "latest" && "$mode" != "new" ]]; then
  printf 'invalid mode: %s (expected latest or new)\n' "$mode" >&2
  exit 1
fi

pending_csv="data/discovery/pending.csv"
pending_state="data/discovery/pending_state.yml"
pending_manifest="data/manifests/pending.txt"
catalog="data/manifests/catalog.txt"
state="data/discovery/state.yml"

Rscript src/discover.R "$mode"
Rscript src/ingest_discovered.R "$pending_csv" "$pending_manifest"

if [[ ! -s "$pending_manifest" ]]; then
  printf 'No hay publicaciones nuevas; no se modifica el catálogo ni el sitio.\n'
  exit 0
fi

bash scripts/analyze_batch.sh "$pending_manifest"
Rscript src/validate_analysis.R "$pending_manifest"
Rscript src/commit_discovery.R "$pending_manifest" "$pending_state" "$catalog" "$state"
Rscript src/validate_analysis.R "$catalog"
Rscript src/render_analysis.R "$catalog"
