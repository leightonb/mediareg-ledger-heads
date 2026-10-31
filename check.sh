#!/usr/bin/env bash
# Checks recorded heads against the hash the registry serves now at the same
# position. Any rewrite of history up to a recorded head changes that hash.
# Heads from before the last reset belong to a ledger the registry no longer
# serves, so they're listed as retired rather than checked.
#   ./check.sh           check every recorded head (slow: the API allows 10 requests a minute)
#   ./check.sh --latest  check only the most recent one
set -euo pipefail
API="${API:-https://api.mediareg.org/api}"

if [ "${1:-}" = "--latest" ]; then lines=$(tail -n 1 heads.jsonl); else lines=$(cat heads.jsonl); fi
if [ -z "$lines" ]; then echo "No heads recorded yet."; exit 0; fi
last_reset=$(jq -s 'map(has("reset")) | rindex(true) // -1' <<<"$lines")

failed=0
first=1
n=-1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  n=$((n + 1))
  at=$(jq -r .recordedAt <<<"$line")
  if jq -e 'has("reset")' <<<"$line" >/dev/null; then
    echo "reset    recorded $at: $(jq -r .reset <<<"$line")"
    continue
  fi
  sequence=$(jq -r .sequence <<<"$line")
  if [ "$n" -lt "$last_reset" ]; then
    echo "retired  #$sequence, recorded $at (before the last reset)"
    continue
  fi
  [ "$first" -eq 1 ] || sleep 7
  first=0
  want=$(jq -r .hash <<<"$line")
  got=$(curl -fsS "$API/verify/ledger/events/$sequence" | jq -r .hash) || got="missing"
  if [ "$got" = "$want" ]; then
    echo "ok       #$sequence, recorded $at"
  else
    echo "CHANGED  #$sequence, recorded $at: was $want, now $got"
    failed=1
  fi
done <<<"$lines"
exit "$failed"
