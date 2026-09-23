#!/usr/bin/env bash
set -euo pipefail

manifest="${1:?usage: scripts/analyze_batch.sh <manifest.txt>}"

if [[ ! -f "$manifest" ]]; then
  printf 'missing manifest: %s\n' "$manifest" >&2
  exit 1
fi

llm="${LLM:-deepseek}"
model="${MODEL:-}"
case "$llm" in
  codex) ;;
  gpt) model="${model:-gpt-5}" ;;
  deepseek) model="${model:-deepseek-v4-pro}" ;;
  *) printf 'backend LLM inválido: %s\n' "$llm" >&2; exit 1 ;;
esac

checkpoint_dir="data/manifests/.analysis-checkpoints"
mkdir -p "$checkpoint_dir"
manifest_hash="$(sha256sum "$manifest" | cut -d' ' -f1)"
batch_key="$(printf '%s\n%s\n%s\n' "$manifest_hash" "$llm" "$model" | sha256sum | cut -d' ' -f1)"
checkpoint="$checkpoint_dir/${batch_key}.tsv"
touch "$checkpoint"

checkpoint_status() {
  awk -F '\t' -v document="$1" '$1 == document { status = $2 } END { print status }' "$checkpoint"
}

checkpoint_mark() {
  local document="$1"
  local status="$2"
  local now
  local temporary
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  temporary="$(mktemp "${checkpoint}.XXXXXX")"
  awk -F '\t' -v document="$document" '$1 != document' "$checkpoint" > "$temporary"
  printf '%s\t%s\t%s\n' "$document" "$status" "$now" >> "$temporary"
  mv "$temporary" "$checkpoint"
}

failed=0
resumed=0
while IFS= read -r document; do
  [[ -z "$document" ]] && continue
  status="$(checkpoint_status "$document")"
  if [[ "$status" == "done" ]] &&
      Rscript -e 'args <- commandArgs(TRUE); source("src/analysis_contract.R"); schema <- jsonlite::fromJSON("config/analysis_schema.json", simplifyVector = FALSE); validate_analysis_output(args[[1]], schema)' "$document" >/dev/null 2>&1; then
    printf 'checkpoint: %s\n' "$document"
    resumed=$((resumed + 1))
    continue
  fi

  error_log="$(mktemp)"
  if scripts/analyze.sh "$document" 2>"$error_log"; then
    checkpoint_mark "$document" done
  else
    cat "$error_log" >&2
    checkpoint_mark "$document" failed
    failed=1
  fi
  rm -f "$error_log"
done < "$manifest"

printf 'Checkpoint de análisis: %s (%s documento(s) ya completos)\n' "$checkpoint" "$resumed"
if [[ "$failed" -ne 0 ]]; then
  printf 'El lote quedó pendiente. Repite make update para reanudar; los documentos completos se omitirán.\n' >&2
  exit 1
fi
