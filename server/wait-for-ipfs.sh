#!/usr/bin/env bash
set -e
API_URL="${1:-http://127.0.0.1:5001/api/v0/version}"
TRIES=60
SLEEP=2

for i in $(seq 1 $TRIES); do
  if curl -s --max-time 2 "$API_URL" >/dev/null; then
    exit 0
  fi
  sleep $SLEEP
done

echo "IPFS API not responding after $((TRIES*SLEEP))s" >&2
exit 1
