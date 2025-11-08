# syntax=docker/dockerfile:1.4

FROM debian:bookworm-slim AS builder

ARG BW_CLI_VERSION=2025.10.0
# Provided by Buildx automatically:
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# Map Docker's TARGETARCH -> Bitwarden's asset suffix
# amd64 => bw-linux-<ver>.zip
# arm64 => bw-linux-arm64-<ver>.zip
RUN set -eux; \
  case "${TARGETARCH}" in \
    amd64) BW_ASSET="bw-linux-${BW_CLI_VERSION}.zip" ;; \
    arm64) BW_ASSET="bw-linux-arm64-${BW_CLI_VERSION}.zip" ;; \
    *) echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
  esac; \
  URL="https://github.com/bitwarden/clients/releases/download/cli-v${BW_CLI_VERSION}/${BW_ASSET}"; \
  echo "Fetching ${URL}"; \
  curl -fL --proto '=https' --tlsv1.2 "${URL}" -o /tmp/bw.zip; \
  cd /tmp; unzip /tmp/bw.zip; \
  chmod +x bw; \
  mv bw /usr/local/bin/bw; \
  rm -f /tmp/bw.zip

# (Optional) Only check version on native amd64 builds;
# running foreign-arch binaries during multi-arch builds can be flaky.
RUN if [ "${TARGETARCH}" = "amd64" ]; then /usr/local/bin/bw --version; else echo "Skipping --version on ${TARGETARCH}"; fi

COPY entrypoint.sh /

CMD ["/entrypoint.sh"]
