#!/usr/bin/env bash
set -euo pipefail

site_dir="corpus/reports"
pages_dir="docs"

if [[ "$(git branch --show-current)" != "main" ]]; then
  printf 'La publicación requiere estar en la rama main.\n' >&2
  exit 1
fi

if [[ ! -s "$site_dir/index.html" ]]; then
  printf 'Falta el sitio generado: ejecuta make site.\n' >&2
  exit 1
fi

staged_other="$(git diff --cached --name-only | awk '$0 !~ /^docs\// {print}')"
if [[ -n "$staged_other" ]]; then
  printf 'Hay cambios staged fuera de docs; publícalos por separado:\n%s\n' "$staged_other" >&2
  exit 1
fi

mkdir -p "$pages_dir"
cp -R "$site_dir"/. "$pages_dir"/
git add -- "$pages_dir"

if git diff --cached --quiet -- "$pages_dir"; then
  printf 'La página ya está actualizada; no hay cambios para publicar.\n'
  exit 0
fi

git commit -m "build: update published site"
git push origin main
