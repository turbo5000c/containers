# syntax=docker/dockerfile:1.4
# ---- Builder: fetch a pinned native 'bw' binary from Bitwarden clients releases
FROM debian:bookworm-slim AS builder

# Pin the CLI version you want (matches tag 'cli-v${BW_CLI_VERSION}' in bitwarden/clients)
ARG BW_CLI_VERSION=2025.10.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# Download the native Linux zip from the unified clients repo, verify it's executable, move to /usr/local/bin
RUN set -eux; \
  curl -fL --proto '=https' --tlsv1.2 \
    "https://github.com/bitwarden/clients/releases/download/cli-v${BW_CLI_VERSION}/bw-linux-${BW_CLI_VERSION}.zip" \
    -o /tmp/bw.zip; \
  cd /tmp; unzip /tmp/bw.zip; chmod +x bw; \
  mv bw /usr/local/bin/bw; rm -f /tmp/bw.zip; \
  /usr/local/bin/bw --version

# ---- Runtime: slim image, non-root, minimal deps
FROM debian:bookworm-slim

# CA certs for TLS and tini for clean signal handling (optional but nice)
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

# Create an unprivileged user
RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin app
USER app:app
WORKDIR /home/app

# Bring in the CLI
COPY --from=builder /usr/local/bin/bw /usr/local/bin/bw

# Add a hardened entrypoint that logs in and launches `bw serve`
# Supported auth:
#   - API key (recommended for service use): BW_CLIENTID + BW_CLIENTSECRET + BW_PASSWORD (to unlock)
#   - User creds (fallback): BW_USER + BW_PASSWORD
# Required:
#   - BW_HOST, e.g. https://vault.bitwarden.com or your self-hosted URL
COPY --chown=app:app entrypoint.sh /home/app/entrypoint.sh
RUN chmod +x /home/app/entrypoint.sh

EXPOSE 8087

# Tini as PID1 for proper signal handling
ENTRYPOINT ["/usr/bin/tini","--","/home/app/entrypoint.sh"]
