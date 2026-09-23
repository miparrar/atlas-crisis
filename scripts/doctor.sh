#!/usr/bin/env bash
set -euo pipefail

llm="${1:?usage: scripts/doctor.sh <codex|gpt|deepseek> <model>}"
model="${2-}"
source scripts/load_env.sh

for tool in Rscript bash awk sed cut sha256sum mktemp; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'Falta herramienta: %s\n' "$tool" >&2
    exit 1
  }
done

case "$llm" in
  codex)
    command -v codex >/dev/null 2>&1 || { printf 'Falta herramienta: codex\n' >&2; exit 1; }
    codex login status || { printf 'Autentica Codex con: codex login\n' >&2; exit 1; }
    ;;
  gpt)
    command -v curl >/dev/null 2>&1 || { printf 'Falta herramienta: curl\n' >&2; exit 1; }
    command -v python3 >/dev/null 2>&1 || { printf 'Falta herramienta: python3\n' >&2; exit 1; }
    test -n "${OPENAI_API_KEY:-}" || { printf 'Falta OPENAI_API_KEY en .Renviron o el entorno.\n' >&2; exit 1; }
    ;;
  deepseek)
    command -v curl >/dev/null 2>&1 || { printf 'Falta herramienta: curl\n' >&2; exit 1; }
    command -v python3 >/dev/null 2>&1 || { printf 'Falta herramienta: python3\n' >&2; exit 1; }
    test -n "${DEEPSEEK_API_KEY:-}" || { printf 'Falta DEEPSEEK_API_KEY en .Renviron o el entorno.\n' >&2; exit 1; }
    ;;
  *)
    printf 'Backend LLM inválido: %s\n' "$llm" >&2
    exit 1
    ;;
esac

printf 'Backend LLM: %s | modelo: %s\n' "$llm" "$model"
