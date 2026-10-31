#!/usr/bin/env bash
# Appends the registry's current ledger head to heads.jsonl. Refuses if the
# head went backwards or the ledger is empty: the ledger only ever grows,
# except straight after a reset recorded with ./reset.sh.
set -euo pipefail
API="${API:-https://api.mediareg.org/api}"

last_line=$(tail -n 1 heads.jsonl)
after_reset=false
if [ -n "$last_line" ] && jq -e 'has("reset")' <<<"$last_line" >/dev/null; then after_reset=true; fi

body=$(mktemp)
trap 'rm -f "$body"' EXIT
status=$(curl -sS -o "$body" -w '%{http_code}' "$API/verify/ledger/head")
if [ "$status" = 404 ] && [ "$after_reset" = true ]; then
  echo "The ledger has been empty since the reset; nothing to record yet."
  exit 0
fi
if [ "$status" != 200 ]; then
  echo "The registry answered $status for the ledger head." >&2
  exit 1
fi
sequence=$(jq -r .sequence "$body")
hash=$(jq -r .hash "$body")

last=$(jq -r '.sequence // empty' <<<"$last_line")
if [ "$after_reset" = false ] && [ -n "$last" ] && [ "$sequence" -lt "$last" ]; then
  echo "The ledger head went backwards, from #$last to #$sequence." >&2
  exit 1
fi

jq -cn --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson sequence "$sequence" --arg hash "$hash" \
  '{recordedAt: $at, sequence: $sequence, hash: $hash}' >> heads.jsonl
echo "Recorded #$sequence $hash"
