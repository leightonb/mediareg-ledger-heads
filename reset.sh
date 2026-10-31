#!/usr/bin/env bash
# Records that the registry's ledger was deliberately restarted, so the daily
# check and record carry on from its new head instead of failing. Heads before
# the reset stay in heads.jsonl, and the reset itself is public and dated.
#   ./reset.sh "Why the ledger was restarted"
set -euo pipefail
reason="${1:?usage: reset.sh \"why the ledger was restarted\"}"

jq -cn --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg reason "$reason" \
  '{recordedAt: $at, reset: $reason}' >> heads.jsonl
echo "Recorded a reset: $reason"
