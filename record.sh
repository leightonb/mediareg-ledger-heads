#!/usr/bin/env bash
# Appends the registry's current ledger head to heads.jsonl. Refuses if the
# head went backwards: the ledger only ever grows.
set -euo pipefail
API="${API:-https://api.mediareg.org/api}"

head=$(curl -fsS "$API/verify/ledger/head")
sequence=$(jq -r .sequence <<<"$head")
hash=$(jq -r .hash <<<"$head")

last=$(tail -n 1 heads.jsonl | jq -r '.sequence // empty')
if [ -n "$last" ] && [ "$sequence" -lt "$last" ]; then
  echo "The ledger head went backwards, from #$last to #$sequence." >&2
  exit 1
fi

jq -cn --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson sequence "$sequence" --arg hash "$hash" \
  '{recordedAt: $at, sequence: $sequence, hash: $hash}' >> heads.jsonl
echo "Recorded #$sequence $hash"
