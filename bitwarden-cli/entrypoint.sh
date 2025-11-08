#!/bin/bash
set -euo pipefail

: "${BW_HOST:?BW_HOST is required (e.g., https://vault.bitwarden.com)}"
bw config server "${BW_HOST}"

login_with_apikey() {
  echo "Logging in using API key"
  export BW_CLIENTID BW_CLIENTSECRET
  # bw login --apikey returns a token to stdout; --raw suppresses extra messages
  local login_token
  login_token="$(bw login --apikey --raw)"
  export BW_SESSION
  # Unlock with org/user password passed via env var (no echo)
  BW_SESSION="$(BW_PASSWORD="${BW_PASSWORD:?missing}" bw unlock --raw)"
}

login_with_user() {
  echo "Logging in using username/password"
  : "${BW_USER:?BW_USER required when no API key is set}"
  export BW_SESSION
  BW_SESSION="$(BW_PASSWORD="${BW_PASSWORD:?missing}" bw login "${BW_USER}" --raw)"
}

if [[ -n "${BW_CLIENTID:-}" && -n "${BW_CLIENTSECRET:-}" ]]; then
  login_with_apikey
else
  login_with_user
fi

# Ensure session is valid
bw unlock --check

echo "Starting bw serve on 0.0.0.0:8087"
# 'bw serve' has no built-in auth; restrict network access at the platform level!
exec bw serve --hostname 0.0.0.0 --port 8087
