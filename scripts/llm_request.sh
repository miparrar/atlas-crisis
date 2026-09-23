#!/usr/bin/env bash
set -euo pipefail

source scripts/load_env.sh

backend="${1:?usage: scripts/llm_request.sh <codex|gpt|deepseek> <model> <prompt> <schema> <output>}"
model="${2-}"
prompt_file="${3:?missing prompt file}"
schema_file="${4:?missing schema file}"
output_file="${5:?missing output file}"

if [[ ! -s "$prompt_file" || ! -s "$schema_file" ]]; then
  printf 'missing prompt or schema input\n' >&2
  exit 1
fi

case "$backend" in
  codex)
    command -v codex >/dev/null 2>&1 || {
      printf 'codex CLI not found in PATH\n' >&2
      exit 1
    }
    args=(codex exec --sandbox read-only --skip-git-repo-check
      --config 'model_reasoning_effort="medium"'
      --output-schema "$schema_file" --output-last-message "$output_file" -)
    if [[ -n "$model" ]]; then
      args=(codex exec --model "$model" --sandbox read-only --skip-git-repo-check
        --config 'model_reasoning_effort="medium"'
        --output-schema "$schema_file" --output-last-message "$output_file" -)
    fi
    "${args[@]}" < "$prompt_file"
    ;;
  gpt|deepseek)
    command -v curl >/dev/null 2>&1 || { printf 'curl no está instalado\n' >&2; exit 1; }
    command -v python3 >/dev/null 2>&1 || { printf 'python3 no está instalado\n' >&2; exit 1; }
    if [[ "$backend" == "gpt" ]]; then
      api_key="${OPENAI_API_KEY:-}"
      base_url="${OPENAI_BASE_URL:-https://api.openai.com/v1}"
    else
      api_key="${DEEPSEEK_API_KEY:-}"
      base_url="${DEEPSEEK_BASE_URL:-https://api.deepseek.com}"
    fi
    if [[ -z "$api_key" ]]; then
      printf 'Falta la clave de API para %s\n' "$backend" >&2
      exit 1
    fi
    request_file="$(mktemp)"
    response_file="$(mktemp)"
    trap 'rm -f "$request_file" "$response_file"' EXIT
    python3 scripts/llm_payload.py "$prompt_file" "$schema_file" "$model" "$backend" > "$request_file"
    if ! curl --fail-with-body --silent --show-error --retry 3 --retry-delay 1 \
      -X POST "${base_url%/}/chat/completions" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      --data-binary "@$request_file" > "$response_file"; then
      cat "$response_file" >&2 || true
      exit 1
    fi
    python3 scripts/llm_extract.py "$response_file" "$output_file"
    ;;
  *)
    printf 'backend LLM inválido: %s (use codex, gpt o deepseek)\n' "$backend" >&2
    exit 1
    ;;
esac
