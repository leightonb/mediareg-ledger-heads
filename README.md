# Media Registry ledger heads

A daily public record of the newest point in [Media Registry](https://mediareg.org)'s
ledger, so that rewriting its history after the fact would show.

## What this is

Media Registry records who owns what in a ledger where every event is hashed together
with the one before it ([how the ledger works](https://mediareg.org/how-it-works)). Change
any past event, and its hash changes, and so does the hash of every event after it.

Every day, a GitHub Action in this repository:

1. asks the registry for the hash it now has at the position recorded the day before, and
   fails if it's different, or if the ledger has shrunk;
2. records today's newest position and hash in [`heads.jsonl`](heads.jsonl), one line a day.

The ledger only reveals positions and hashes here: no items, owners or anything else.

## Check it yourself

You need `bash`, `curl` and `jq`. From a clone of this repository:

```bash
./check.sh --latest   # the most recent recorded head
./check.sh            # every recorded head (slow: the registry allows 10 requests a minute)
```

Each line says `ok` if the registry still has the same hash at that position, or `CHANGED`
if it doesn't.

Better still, keep your own clone and pull it now and then. The owner of this repository
could rewrite its history too, but not the copies other people already hold.

## What it doesn't prove

This detects a rewrite of anything up to a recorded head, unless the registry also serves
false hashes for old positions, consistently, to everyone who checks. Closing that gap needs
Merkle consistency proofs, which are planned but not built
([specification](https://mediareg.org/spec), Section 10).
