#!/usr/bin/env bash
# One-time Withings OAuth setup.
# Opens browser for user consent, captures the auth code via a tiny local server,
# exchanges it for tokens, and writes WITHINGS_REFRESH_TOKEN to .env.
#
# Usage: bash skills/withings/auth.sh
#
# Requirements: WITHINGS_CLIENT_ID + WITHINGS_CLIENT_SECRET already in .env.

set -euo pipefail

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.env"
[ -f "$ENV_FILE" ] || { echo "missing .env at $ENV_FILE"; exit 1; }
# shellcheck disable=SC1090
source "$ENV_FILE"

: "${WITHINGS_CLIENT_ID:?Set WITHINGS_CLIENT_ID in .env first}"
: "${WITHINGS_CLIENT_SECRET:?Set WITHINGS_CLIENT_SECRET in .env first}"

REDIRECT_URI="http://localhost:8765/callback"
SCOPE="user.metrics,user.activity,user.info"
STATE="$(head -c 16 /dev/urandom | xxd -p)"

AUTH_URL="https://account.withings.com/oauth2_user/authorize2?response_type=code&client_id=${WITHINGS_CLIENT_ID}&state=${STATE}&scope=${SCOPE}&redirect_uri=${REDIRECT_URI}"

echo
echo "========================================================"
echo "Withings OAuth setup"
echo "========================================================"
echo
echo "1) Open this URL in your browser (or it'll open automatically):"
echo
echo "   $AUTH_URL"
echo
echo "2) Log into Withings → click 'Allow this app'"
echo "3) You'll be redirected to localhost — this script captures the code"
echo

# Try to open browser (mac/linux)
( command -v open >/dev/null && open "$AUTH_URL" ) \
  || ( command -v xdg-open >/dev/null && xdg-open "$AUTH_URL" ) \
  || true

# Tiny netcat-based capture server: listens on 8765, reads request line, returns thank-you page.
TMP="$(mktemp)"
echo "Listening on http://localhost:8765/callback ..."
{
  printf "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"
  printf '<html><body style="font-family:sans-serif;text-align:center;padding:50px"><h1>OK</h1><p>Withings authorized. You can close this tab.</p></body></html>'
} | nc -l -p 8765 -q 1 > "$TMP" 2>/dev/null \
  || { echo "nc failed — install ncat or use python fallback below"; exit 1; }

# Parse "GET /callback?code=...&state=... HTTP/1.1"
REQ_LINE="$(head -n 1 "$TMP")"
CODE="$(echo "$REQ_LINE" | grep -oP 'code=\K[^& ]+' || true)"
RECEIVED_STATE="$(echo "$REQ_LINE" | grep -oP 'state=\K[^& ]+' || true)"
rm -f "$TMP"

[ -n "$CODE" ] || { echo "no auth code received"; exit 1; }
[ "$RECEIVED_STATE" = "$STATE" ] || { echo "state mismatch — possible CSRF, aborting"; exit 1; }

echo "Got auth code, exchanging for tokens..."

RESP="$(curl -s -X POST "https://wbsapi.withings.net/v2/oauth2" \
  -d "action=requesttoken" \
  -d "client_id=${WITHINGS_CLIENT_ID}" \
  -d "client_secret=${WITHINGS_CLIENT_SECRET}" \
  -d "grant_type=authorization_code" \
  -d "code=${CODE}" \
  -d "redirect_uri=${REDIRECT_URI}")"

STATUS="$(echo "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["status"])')"
[ "$STATUS" = "0" ] || { echo "token exchange failed: $RESP"; exit 1; }

REFRESH="$(echo "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["body"]["refresh_token"])')"

# Write/replace WITHINGS_REFRESH_TOKEN in .env
if grep -q '^WITHINGS_REFRESH_TOKEN=' "$ENV_FILE"; then
  sed -i.bak "s|^WITHINGS_REFRESH_TOKEN=.*|WITHINGS_REFRESH_TOKEN=${REFRESH}|" "$ENV_FILE"
else
  printf '\nWITHINGS_REFRESH_TOKEN=%s\n' "$REFRESH" >> "$ENV_FILE"
fi
rm -f "${ENV_FILE}.bak"

echo
echo "✅ Done. Refresh token saved to .env"
echo "   Test with: bash skills/withings/api.sh measure getmeas meastypes=1 limit=1"
