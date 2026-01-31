FROM debian:trixie-slim

# Update and install needed utils
RUN apt update && \
    apt upgrade -y && \
    apt install -y curl unzip && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Fix for favorites.json error
RUN favorites_path="/root/My Games/Terraria" && mkdir -p "$favorites_path" && echo "{}" > "$favorites_path/favorites.json"

RUN mkdir /tmp/terraria && \
    cd /tmp/terraria && \
    curl -sL https://www.terraria.org/api/download/pc-dedicated-server/terraria-server-1453.zip --output terraria-server.zip && \
    unzip -q terraria-server.zip && \
    mv */Linux /vanilla && \
    mv */Windows/serverconfig.txt /vanilla/serverconfig-default.txt && \
    rm -R /tmp/* && \
    chmod +x /vanilla/TerrariaServer* && \
    if [ ! -f /vanilla/TerrariaServer ]; then echo "Missing /vanilla/TerrariaServer"; exit 1; fi

COPY run-vanilla.sh /vanilla/run.sh
RUN chmod +x /vanilla/run.sh

# Create non-root user
RUN useradd -m -u 1000 terraria && chown -R terraria:terraria /vanilla && chown -R terraria:terraria /config

# Metadata
ARG VCS_REF
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.source="https://github.com/LeviPringle/Terraria-Server"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="Terraria Server"
LABEL VANILLA_VERSION=1453

# Allow for external data
VOLUME ["/config"]

EXPOSE 7777/tcp 7777/udp

HEALTHCHECK --interval=30s --timeout=5s CMD ss -ltn | grep -q ':7777' || exit 1
USER terraria