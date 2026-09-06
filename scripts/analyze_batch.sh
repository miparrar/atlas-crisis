#!/usr/bin/env bash
set -euo pipefail

manifest="${1:?usage: scripts/analyze_batch.sh <manifest.txt>}"

if [[ ! -f "$manifest" ]]; then
  printf 'missing manifest: %s\n' "$manifest" >&2
  exit 1
fi

while IFS= read -r document; do
  [[ -z "$document" ]] && continue
  scripts/analyze.sh "$document"
done < "$manifest"
