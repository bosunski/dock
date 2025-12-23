#!/bin/bash
set -e

# inject-secrets.sh - Fetch secrets from 1Password and generate .env file
# Usage: inject-secrets.sh <service> <environment> <output-path> [vault-name]

SERVICE=$1
ENVIRONMENT=$2
OUTPUT_PATH=$3
VAULT=${4:-"egberinde"}  # Default vault name: "egberinde"

if [ -z "$SERVICE" ] || [ -z "$ENVIRONMENT" ] || [ -z "$OUTPUT_PATH" ]; then
    echo "Usage: inject-secrets.sh <service> <environment> <output-path> [vault-name]"
    exit 1
fi

echo "🔐 Fetching secrets for $SERVICE in $ENVIRONMENT from 1Password..."

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI (op) not found. Install: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Item naming convention: "{service}-{environment}" (e.g., "fizzy-production")
ITEM="${SERVICE}-${ENVIRONMENT}"

echo "Fetching from vault: $VAULT, item: $ITEM"

# Check if item exists
if ! op item get "$ITEM" --vault "$VAULT" &> /dev/null; then
    echo "❌ Error: Item '$ITEM' not found in vault '$VAULT'"
    echo "Please create the item in 1Password following the naming convention: {service}-{environment}"
    exit 1
fi

# Fetch all fields from the item and generate .env file
op item get "$ITEM" --vault "$VAULT" --format json | \
    jq -r '.fields[] | select(.type != "CONCEALED" and .label != "password") | "\(.label)=\(.value)"' > "$OUTPUT_PATH"

# Fetch concealed/password fields (secrets)
op item get "$ITEM" --vault "$VAULT" --format json | \
    jq -r '.fields[] | select(.type == "CONCEALED" or .label == "password") | "\(.label)=\(.value)"' >> "$OUTPUT_PATH"

if [ -s "$OUTPUT_PATH" ]; then
    echo "✅ Secrets injected into $OUTPUT_PATH"
    echo "Environment variables loaded: $(wc -l < "$OUTPUT_PATH" | xargs)"
else
    echo "⚠ No secrets found for $SERVICE in $ENVIRONMENT"
fi
