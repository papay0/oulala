#!/usr/bin/env bash
# Withings API call helper. Refreshes the access token (rotating the refresh token
# in .env), then makes the request.
#
# Usage:
#   bash skills/withings/api.sh <service> <action> [extra=params ...]
#
# Examples:
#   bash skills/withings/api.sh measure getmeas meastypes=1 limit=1
#   bash skills/withings/api.sh measure getmeas meastypes=1,6,76,77,88 limit=10
#   bash skills/withings/api.sh sleep getsummary startdateymd=2026-04-25 enddateymd=2026-04-26
#
# Outputs JSON to stdout.

set -euo pipefail

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.env"
[ -f "$ENV_FILE" ] || { echo "missing .env" >&2; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

: "${WITHINGS_CLIENT_ID:?missing in .env}"
: "${WITHINGS_CLIENT_SECRET:?missing in .env}"
: "${WITHINGS_REFRESH_TOKEN:?missing in .env — run skills/withings/auth.sh}"

SERVICE="${1:?service required (e.g. measure, sleep, heart)}"
ACTION="${2:?action required (e.g. getmeas)}"
shift 2

# Refresh the access token. Withings rotates the refresh token on every call.
REFRESH_RESP="$(curl -s -X POST "https://wbsapi.withings.net/v2/oauth2" \
  -d "action=requesttoken" \
  -d "client_id=${WITHINGS_CLIENT_ID}" \
  -d "client_secret=${WITHINGS_CLIENT_SECRET}" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=${WITHINGS_REFRESH_TOKEN}")"

STATUS="$(echo "$REFRESH_RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("status","?"))')"
if [ "$STATUS" != "0" ]; then
  echo "Withings refresh failed: $REFRESH_RESP" >&2
  exit 1
fi

ACCESS="$(echo "$REFRESH_RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["body"]["access_token"])')"
NEW_REFRESH="$(echo "$REFRESH_RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["body"]["refresh_token"])')"

# Persist the rotated refresh token immediately
sed -i.bak "s|^WITHINGS_REFRESH_TOKEN=.*|WITHINGS_REFRESH_TOKEN=${NEW_REFRESH}|" "$ENV_FILE"
rm -f "${ENV_FILE}.bak"

# Build the API URL — sleep service uses /v2/sleep, others vary
case "$SERVICE" in
  sleep)    URL="https://wbsapi.withings.net/v2/sleep" ;;
  heart)    URL="https://wbsapi.withings.net/v2/heart" ;;
  user)     URL="https://wbsapi.withings.net/v2/user" ;;
  notify)   URL="https://wbsapi.withings.net/notify" ;;
  measure)  URL="https://wbsapi.withings.net/measure" ;;
  *)        URL="https://wbsapi.withings.net/${SERVICE}" ;;
esac

# Build form data
DATA=("-d" "action=${ACTION}")
for kv in "$@"; do
  DATA+=("-d" "$kv")
done

curl -s -X POST "$URL" \
  -H "Authorization: Bearer ${ACCESS}" \
  "${DATA[@]}"
