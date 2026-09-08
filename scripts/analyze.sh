#!/usr/bin/env bash
set -euo pipefail

input="${1:?usage: scripts/analyze.sh <document.md>}"
schema="config/analysis_schema.json"
prompt_template="prompts/analyze.md"

if [[ ! -f "$input" ]]; then
  printf 'missing input: %s\n' "$input" >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  printf 'codex CLI not found in PATH\n' >&2
  exit 1
fi

content_hash="$(
  Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); cat(document$metadata$content_sha256)' "$input"
)"

relative="${input#corpus/posts/}"
stem="${relative%.md}"
output="data/analysis/${stem}.json"
meta="data/analysis/${stem}.meta.json"

mkdir -p "$(dirname "$output")"

schema_hash="$(sha256sum "$schema" | cut -d' ' -f1)"
prompt_hash="$(sha256sum "$prompt_template" | cut -d' ' -f1)"

if [[ -f "$output" && -f "$meta" ]]; then
  cached_hash="$(
    sed -n 's/.*"content_sha256": "\([^"]*\)".*/\1/p' "$meta"
  )"
  cached_schema_hash="$(
    sed -n 's/.*"schema_sha256": "\([^"]*\)".*/\1/p' "$meta"
  )"

  cached_prompt_hash="$(
    sed -n 's/.*"prompt_sha256": "\([^"]*\)".*/\1/p' "$meta"
  )"

  if [[ "$cached_hash" == "$content_hash" && "$cached_schema_hash" == "$schema_hash" && "$cached_prompt_hash" == "$prompt_hash" ]] &&
      Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); analysis <- jsonlite::fromJSON(args[[2]], simplifyVector = FALSE); validate_analysis(analysis, document, schema)' "$input" "$output" >/dev/null 2>&1
  then
    printf 'cached: %s\n' "$input"
    exit 0
  fi
fi

tmp_output="$(mktemp)"
tmp_prompt="$(mktemp)"
trap 'rm -f "$tmp_output" "$tmp_prompt"' EXIT

cat "$prompt_template" "$input" > "$tmp_prompt"

codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  --config 'model_reasoning_effort="medium"' \
  --output-schema "$schema" \
  --output-last-message "$tmp_output" \
  - < "$tmp_prompt"

if [[ ! -s "$tmp_output" ]]; then
  printf 'codex produced no final output for %s\n' "$input" >&2
  exit 1
fi

Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); analysis <- jsonlite::fromJSON(args[[2]], simplifyVector = FALSE); validate_analysis(analysis, document, schema)' "$input" "$tmp_output"

mv "$tmp_output" "$output"
codex_version="$(codex --version 2>/dev/null || true)"

cat > "$meta" <<EOF
{
  "document": "$input",
  "content_sha256": "$content_hash",
  "schema_sha256": "$schema_hash",
  "prompt_sha256": "$prompt_hash",
  "codex_version": "$codex_version"
}
EOF

printf 'analyzed: %s -> %s\n' "$input" "$output"
