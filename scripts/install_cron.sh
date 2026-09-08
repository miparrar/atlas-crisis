#!/usr/bin/env bash
set -euo pipefail

hour="${1:-8}"
if [[ ! "$hour" =~ ^([0-9]|1[0-9]|2[0-3])$ ]]; then
  printf 'usage: scripts/install_cron.sh [hour-0-23]\n' >&2
  exit 1
fi

for tool in crontab flock bash make; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'missing tool: %s\n' "$tool" >&2
    exit 1
  }
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$repo_root" == *"'"* || "$repo_root" == *$'\n'* ]]; then
  printf 'unsupported repository path: %s\n' "$repo_root" >&2
  exit 1
fi

begin="# BEGIN atlas-crisis monitor"
end="# END atlas-crisis monitor"
flock_path="$(command -v flock)"
bash_path="$(command -v bash)"
make_path="$(command -v make)"
job="0 $hour * * * $flock_path -n /tmp/atlas-crisis-update.lock $bash_path -lc 'cd \"$repo_root\" && mkdir -p logs && $make_path update >> logs/update.log 2>&1'"

current="$(crontab -l 2>/dev/null || true)"
cron_file="$(mktemp)"
trap 'rm -f "$cron_file"' EXIT

printf '%s\n' "$current" |
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' > "$cron_file"

{
  printf '%s\n' "$begin"
  printf '%s\n' "$job"
  printf '%s\n' "$end"
} >> "$cron_file"

crontab "$cron_file"
printf 'Monitor instalado: todos los días a las %02d:00 (hora local).\n' "$hour"
printf 'Log: %s\n' "$repo_root/logs/update.log"
