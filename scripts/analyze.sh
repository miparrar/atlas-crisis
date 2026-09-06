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
  awk -F': ' '
    /^content_sha256:/ {
      gsub(/"/, "", $2)
      print $2
      exit
    }
  ' "$input"
)"

if [[ -z "$content_hash" ]]; then
  content_hash="$(sha256sum "$input" | cut -d' ' -f1)"
fi

relative="${input#corpus/posts/}"
stem="${relative%.md}"
output="data/analysis/${stem}.json"
meta="data/analysis/${stem}.meta.json"

mkdir -p "$(dirname "$output")"

if [[ -f "$output" && -f "$meta" ]] && command -v jq >/dev/null 2>&1; then
  cached_hash="$(jq -r '.content_sha256 // empty' "$meta")"
  schema_hash="$(sha256sum "$schema" | cut -d' ' -f1)"
  cached_schema_hash="$(jq -r '.schema_sha256 // empty' "$meta")"

  if [[ "$cached_hash" == "$content_hash" && "$cached_schema_hash" == "$schema_hash" ]]; then
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

if command -v jq >/dev/null 2>&1; then
  jq empty "$tmp_output"
fi

mv "$tmp_output" "$output"
schema_hash="$(sha256sum "$schema" | cut -d' ' -f1)"
codex_version="$(codex --version 2>/dev/null || true)"

cat > "$meta" <<EOF
{
  "document": "$input",
  "content_sha256": "$content_hash",
  "schema_sha256": "$schema_hash",
  "codex_version": "$codex_version"
}
EOF

printf 'analyzed: %s -> %s\n' "$input" "$output"
