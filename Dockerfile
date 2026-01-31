FROM debian:trixie-slim

# Update and install needed utils
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl vim zip unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# fix for favorites.json error
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

# create non-root user
RUN useradd -m -u 1000 terraria && chown -R terraria:terraria /vanilla

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

# Run the server as non-root
USER terraria
WORKDIR /vanilla
ENTRYPOINT ["./run.sh"]