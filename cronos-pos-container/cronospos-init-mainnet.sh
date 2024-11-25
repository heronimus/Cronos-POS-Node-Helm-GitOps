#!/bin/bash

# Constants
CHAIN_ID="crypto-org-chain-mainnet-1"
CHAIN_MAIND_DIR="$HOME/.chain-maind"
GENESIS_URL="https://raw.githubusercontent.com/crypto-org-chain/mainnet/main/crypto-org-chain-mainnet-1/genesis.json"
GENESIS_CHECKSUM="d299dcfee6ae29ca280006eaa065799552b88b978e423f9ec3d8ab531873d882"

# helper usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") --moniker-id=<moniker_id>
Initialize chain-maind with the specified moniker ID

Options:
  --moniker-id=<id>    Specify the moniker ID for initialization
  --help, -h           Show this help message
EOF
}

# Parse Arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_usage
    exit 0
elif [[ "$1" == --moniker-id=* ]]; then
    MONIKER_ID="${1#*=}"
    if [[ -z "$MONIKER_ID" ]]; then
        echo "ERROR: Moniker ID cannot be empty"
        exit 1
    fi
else
    echo "ERROR: Required argument --moniker-id=<moniker_id> not provided"
    echo "Use --help or -h for usage information"
    exit 1
fi

# Check if chain-maind is installed
if ! command -v chain-maind &> /dev/null; then
    echo "ERROR: chain-maind is not installed. Please chain-maind to continue."
    exit 1
fi

# Check if ~/.chain-maind directory exists
if [ -f "$CHAIN_MAIND_DIR/config/config.toml" ]; then
    echo "WARN: $CHAIN_MAIND_DIR/config/ directory already exists, skipping chain-maind initialization."
    exit 0
fi


# Init & Configure chain-maind
# Docs: https://docs.cronos-pos.org/for-node-hosts/getting-started/mainnet_validator#step-2-1.-initialize-chain-maind
chain-maind init $MONIKER_ID --chain-id crypto-org-chain-mainnet-1

# Download and verify Cronos-POS mainnet genesis.json
echo "INFO: Downloading genesis.json..."
if ! curl -s "$GENESIS_URL" > ~/.chain-maind/config/genesis.json ; then
    echo "ERROR: Failed to download genesis.json"
    exit 1
fi
calculated_checksum=$(sha256sum "$CHAIN_MAIND_DIR/config/genesis.json" | awk '{print $1}')
if [[ "$calculated_checksum" == "$GENESIS_CHECKSUM" ]]; then
    echo "INFO: genesis.json checksum OK"
else
    echo "ERROR: genesis.json checksum MISMATCHED"
    exit 1
fi

## Update configurations
echo "INFO: Updating configuration files..."

# Update minimum gas price to avoid transaction spamming
sed -i.bak -E 's#^(minimum-gas-prices[[:space:]]+=[[:space:]]+)""$#\1"0.025basecro"#' "$CHAIN_MAIND_DIR/config/app.toml"

## Extra customization
# Increase chunk_request_timeout from "10s" --> "30s"
sed -i.bak -E 's#^(discovery_time[[:space:]]+=[[:space:]]+).*$#\1"60s"#' "$CHAIN_MAIND_DIR/config/config.toml"

sed -i.bak -E 's#^(chunk_fetchers[[:space:]]+=[[:space:]]+).*$#\1"8"#' "$CHAIN_MAIND_DIR/config/config.toml"

# Change Tendermint RPC listening interface from 127.0.0.1 --> 0.0.0.0, exposed it outside the container
sed -i.bak -E 's#^(laddr[[:space:]]+=[[:space:]]+)"tcp://127.0.0.1:26657"#\1"tcp://0.0.0.0:26657"#' "$CHAIN_MAIND_DIR/config/config.toml"

# Enable Rest API endpoint (1317)
sed -i.bak -E '/\[api\]/,/\[.*\]/ s/^enable = false/enable = true/' "$CHAIN_MAIND_DIR/config/app.toml"

# Change gRPC (9090) & gRPC-web (9091) listening interface from 127.0.0.1 --> 0.0.0.0
sed -i.bak -E 's#^(address[[:space:]]+=[[:space:]]+)"127.0.0.1:9090"#\1"0.0.0.0:9090"#' "$CHAIN_MAIND_DIR/config/app.toml"
sed -i.bak -E 's#^(address[[:space:]]+=[[:space:]]+)"127.0.0.1:9091"#\1"0.0.0.0:9091"#' "$CHAIN_MAIND_DIR/config/app.toml"
echo "INFO: Configuration complete"
