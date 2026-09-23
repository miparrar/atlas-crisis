#!/usr/bin/env bash
set -euo pipefail

source scripts/load_env.sh

input="${1:?usage: scripts/analyze.sh <document.md>}"
llm="${LLM:-deepseek}"
model="${MODEL:-}"
schema="config/analysis_schema.json"
prompt_template="prompts/analyze.md"

case "$llm" in
  codex) ;;
  gpt) model="${model:-gpt-5}" ;;
  deepseek) model="${model:-deepseek-v4-pro}" ;;
  *) printf 'backend LLM inválido: %s\n' "$llm" >&2; exit 1 ;;
esac

if [[ ! -f "$input" ]]; then
  printf 'missing input: %s\n' "$input" >&2
  exit 1
fi

content_hash="$(
  Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); cat(document$metadata$content_sha256)' "$input"
)"

ingestion_note="$(
  Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); note <- document$metadata$ingestion_note; if (!is.null(note) && length(note) == 1L && nzchar(note)) cat(note)' "$input"
)"

relative="${input#corpus/posts/}"
stem="${relative%.md}"
output="data/analysis/${stem}.json"
meta="data/analysis/${stem}.meta.json"

mkdir -p "$(dirname "$output")"
schema_hash="$(sha256sum "$schema" | cut -d' ' -f1)"
prompt_hash="$(sha256sum "$prompt_template" | cut -d' ' -f1)"

# La insuficiencia documental es determinista y prevalece sobre cualquier caché.
if [[ -n "$ingestion_note" ]]; then
  tmp_output="$(mktemp)"
  trap 'rm -f "$tmp_output"' EXIT

  Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); analysis <- short_document_analysis(args[[2]]); validate_analysis(analysis, read_canonical_document(args[[1]]), schema); jsonlite::write_json(analysis, args[[3]], auto_unbox = TRUE, pretty = TRUE, null = "null")' "$input" "$ingestion_note" "$tmp_output"

  mv "$tmp_output" "$output"
  cat > "$meta" <<EOF
{
  "document": "$input",
  "content_sha256": "$content_hash",
  "schema_sha256": "$schema_hash",
  "prompt_sha256": "$prompt_hash",
  "llm_backend": "$llm",
  "model": "$model",
  "provider_version": "not_invoked: document too short"
}
EOF

  printf 'insufficient: %s -> %s\n' "$input" "$output"
  exit 0
fi

if [[ -f "$output" && -f "$meta" ]]; then
  cached_hash="$(sed -n 's/.*"content_sha256": "\([^"\]*\)".*/\1/p' "$meta")"
  cached_schema_hash="$(sed -n 's/.*"schema_sha256": "\([^"\]*\)".*/\1/p' "$meta")"
  cached_prompt_hash="$(sed -n 's/.*"prompt_sha256": "\([^"\]*\)".*/\1/p' "$meta")"
  cached_backend="$(sed -n 's/.*"llm_backend": "\([^"\]*\)".*/\1/p' "$meta")"
  cached_model="$(sed -n 's/.*"model": "\([^"\]*\)".*/\1/p' "$meta")"

  if [[ "$cached_hash" == "$content_hash" &&
        "$cached_schema_hash" == "$schema_hash" &&
        "$cached_prompt_hash" == "$prompt_hash" &&
        "$cached_backend" == "$llm" &&
        "$cached_model" == "$model" ]] &&
      Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); validate_analysis_output(args[[1]], schema)' "$input" >/dev/null 2>&1
  then
    printf 'cached: %s [%s/%s]\n' "$input" "$llm" "$model"
    exit 0
  fi
fi

tmp_output="$(mktemp)"
tmp_repaired="$(mktemp)"
tmp_prompt="$(mktemp)"
trap 'rm -f "$tmp_output" "$tmp_repaired" "$tmp_prompt"' EXIT

python3 scripts/build_analysis_prompt.py "$prompt_template" "$input" "$tmp_prompt"
if [[ "$llm" != "codex" ]]; then
  {
    printf '\n\nEsquema JSON obligatorio:\n'
    cat "$schema"
  } >> "$tmp_prompt"
fi

valid=0
validation_error=""
for attempt in 1 2; do
  : > "$tmp_output"
  : > "$tmp_repaired"
  if scripts/llm_request.sh "$llm" "$model" "$tmp_prompt" "$schema" "$tmp_output"; then
    if ! python3 scripts/resolve_quote_refs.py "$input" "$tmp_output" "$tmp_repaired"; then
      printf 'No se pudieron resolver las citas de %s (attempt %s)\n' "$input" "$attempt" >&2
      validation_error="No se pudo inspeccionar las citas de forma determinista."
    elif validation_error="$(Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); document <- read_canonical_document(args[[1]]); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); analysis <- jsonlite::fromJSON(args[[2]], simplifyVector = FALSE); validate_analysis(analysis, document, schema)' "$input" "$tmp_repaired" 2>&1)"; then
      valid=1
      break
    else
      printf 'analysis validation failed for %s (attempt %s):\n%s\n' "$input" "$attempt" "$validation_error" >&2
    fi
  else
    printf '%s failed for %s (attempt %s)\n' "$llm" "$input" "$attempt" >&2
    validation_error="$llm no produjo una salida válida."
  fi

  if [[ "$attempt" -eq 1 ]]; then
    printf '%s\n' '' \
      'REVISIÓN OBLIGATORIA: tu salida anterior no pasó la validación. Regenera el JSON completo. Cada supporting_quotes debe contener únicamente IDs de bloques como Q0001; no escribas ni reescribas el texto de las citas. Usa solo IDs presentes en el documento.' \
      'DIAGNÓSTICO DEL VALIDADOR:' >> "$tmp_prompt"
    printf '%s\n' "$validation_error" >> "$tmp_prompt"
  fi
done

if [[ "$valid" -ne 1 ]]; then
  printf 'analysis failed after 2 attempts for %s\n' "$input" >&2
  exit 1
fi

mv "$tmp_repaired" "$output"
case "$llm" in
  codex) provider_version="$(codex --version 2>/dev/null || true)" ;;
  gpt) provider_version="openai-api" ;;
  deepseek) provider_version="deepseek-api" ;;
esac

cat > "$meta" <<EOF
{
  "document": "$input",
  "content_sha256": "$content_hash",
  "schema_sha256": "$schema_hash",
  "prompt_sha256": "$prompt_hash",
  "llm_backend": "$llm",
  "model": "$model",
  "provider_version": "$provider_version"
}
EOF

printf 'analyzed: %s -> %s [%s/%s]\n' "$input" "$output" "$llm" "$model"
