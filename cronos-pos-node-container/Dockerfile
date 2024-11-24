### Build Layer
FROM debian:12-slim AS build

# Args to change the chain-main release version
# Example: docker build --build-arg CHAIN_MAIN_VERSION=4.2.9 -t chain-main:4.2.9 .
ARG CHAIN_MAIN_VERSION=4.2.9

# Install runtime dependencies & libraries
RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp/chain-maind
WORKDIR /tmp/chain-maind

# Download cronos chain-main build from Github release
RUN wget https://github.com/crypto-org-chain/chain-main/releases/download/v${CHAIN_MAIN_VERSION}/chain-main_${CHAIN_MAIN_VERSION}_Linux_x86_64.tar.gz \
    && tar -xzvf chain-main_${CHAIN_MAIN_VERSION}_Linux_x86_64.tar.gz


### Runtime Layer
FROM debian:12-slim AS runtime

LABEL maintainer="adie@heronimus.id"
LABEL description="Cronos-POS Node with STATE-SYNC enabled"

ENV CHAIN_MAIN=/chain-main

# Install ca-certificates
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -g 10001 chain-main && \
    useradd -u 10001 -g chain-main -s /bin/bash -d $CHAIN_MAIN chain-main

# Copy chain-maind binary
COPY --from=build /tmp/chain-maind/bin/chain-maind /usr/bin/chain-maind

# Copy helper scripts
COPY cronospos-init-mainnet.sh $CHAIN_MAIN/cronospos-init-mainnet.sh
COPY cronospos-enable-statesync.sh $CHAIN_MAIN/cronospos-enable-statesync.sh

# Set permissions
RUN chmod 755 /usr/bin/chain-maind && \
    chmod 755 $CHAIN_MAIN/cronospos-*.sh && \
    chown -R chain-main:chain-main $CHAIN_MAIN

# Change user
USER chain-main
WORKDIR $CHAIN_MAIN

# Run chain-maind by default
CMD ["chain-maind"]

# Command example:
# docker run -it --rm chain-main:4.2.9 chain-maind --help
