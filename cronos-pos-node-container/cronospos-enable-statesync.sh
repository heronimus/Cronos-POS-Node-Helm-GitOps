#!/bin/bash

# Constants
CONFIG_PATH="$HOME/.chain-maind/config/config.toml"

## Multiple RPC endpoints added to prevent timeouts that commonly occur
## when using just the default RPC endpoint `https://rpc.mainnet.cronos-pos.org:443`
RPC_ENDPOINTS=(
    "https://rpc.mainnet.cronos-pos.org:443"
    "https://cronos-pos-rpc.publicnode.com:443"
    "https://cryptocom-rpc.polkachu.com:443"
    "https://rpc-cryptoorgchain.ecostake.com:443"
)

## While the documentation suggests using `persistent_peers`,
## I switched to using `seeds` instead because the existing peers frequently disconnect or reject connections,
## likely due to their peer slots being at capacity. Also added additional public seeds node.
SEED_NODES=(
    "87c3adb7d8f649c51eebe0d3335d8f9e28c362f2@seed-0.cronos-pos.org:26656"
    "e1d7ff02b78044795371beb1cd5fb803f9389256@seed-1.cronos-pos.org:26656"
    "2c55809558a4e491e9995962e10c026eb9014655@seed-2.cronos-pos.org:26656"
    "8542cd7e6bf9d260fef543bc49e59be5a3fa9074@seed.publicnode.com:26656"
    "ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:20256"
)

# Function to display usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [--custom-height=<height>]

Options:
  --custom-height=<height>  Set custom block height for state sync
  --help, -h               Show this help message
EOF
}

# Parse Arguments "--custom-height" to replace default BLOCK_HEIGHT value
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_usage
    exit 0
elif [[ "${1:-}" == --custom-height=* ]]; then
    CUSTOM_HEIGHT="${1#*=}"
    if [[ -z "$CUSTOM_HEIGHT" ]]; then
        echo "ERROR: Custom height value cannot be empty"
        exit 1
    fi
fi

# Check if config file exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: Config file not found $CONFIG_PATH"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is not installed. Please install jq to continue."
    exit 1
fi

# Set BLOCK_HEIGHT & TRUST_HASH
if [ -n "$CUSTOM_HEIGHT" ]; then
    BLOCK_HEIGHT=$CUSTOM_HEIGHT
else
    LATEST_HEIGHT=$(curl -s https://rpc.mainnet.cronos-pos.org:443/block | jq -r .result.block.header.height)
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
fi

TRUST_HASH=$(curl -s "https://rpc.mainnet.cronos-pos.org:443/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

## Configure node config to use STATE-SYNC
## Docs: https://docs.cronos-pos.org/for-node-hosts/getting-started/mainnet_validator#step-2-3.-enable-state-sync

# Construct RPC & SEEDS servers string (comma separated)
RPC_SERVERS=$(IFS=,; echo "${RPC_ENDPOINTS[*]}")
SEEDS=$(IFS=,; echo "${SEED_NODES[*]}")

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$RPC_SERVERS\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"$SEEDS\"|" "$CONFIG_PATH"

echo "INFO: Configuration updated RPC_SERVERS: $RPC_SERVERS"
echo "INFO: Configuration updated SEEDS: $SEEDS"
echo "INFO: STATE-SYNC enabled with trust_height=$BLOCK_HEIGHT"
