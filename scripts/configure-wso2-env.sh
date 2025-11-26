#!/bin/bash
# Configure WSO2 API Manager environment for apictl
# Run this after installing apictl

set -e

# Configuration
WSO2_ENV_NAME="${1:-dev}"
WSO2_URL="${2:-https://apim.ayinza.dev}"
WSO2_USER="${3:-admin}"
WSO2_PASS="${4:-admin}"

echo "Configuring WSO2 environment: ${WSO2_ENV_NAME}"
echo "WSO2 URL: ${WSO2_URL}"

# Remove existing environment if exists
apictl remove env "${WSO2_ENV_NAME}" 2>/dev/null || true

# Add environment
apictl add env "${WSO2_ENV_NAME}" \
  --apim "${WSO2_URL}" \
  --token "${WSO2_URL}/oauth2/token"

echo "Environment '${WSO2_ENV_NAME}' configured successfully!"

# Login
echo "Logging in to ${WSO2_ENV_NAME}..."
apictl login "${WSO2_ENV_NAME}" -u "${WSO2_USER}" -p "${WSO2_PASS}" -k

echo "Successfully logged in to WSO2 API Manager!"

# List environments
echo ""
echo "Configured environments:"
apictl list envs
