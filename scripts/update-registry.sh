#!/bin/bash
# Update the service registry (services.json) with deployment information
# This script is called after successful API registration

set -e

REGISTRY_FILE="./api-registry/services.json"

# Default values
SERVICE_NAME=""
API_CONTEXT=""
STATUS="deployed"
API_VERSION="v1"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --service) SERVICE_NAME="$2"; shift 2;;
    --context) API_CONTEXT="$2"; shift 2;;
    --status) STATUS="$2"; shift 2;;
    --version) API_VERSION="$2"; shift 2;;
    --registry) REGISTRY_FILE="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 --service NAME --context /path [--status deployed] [--version v1]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# Validate required arguments
if [[ -z "$SERVICE_NAME" || -z "$API_CONTEXT" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --service NAME --context /path"
  exit 1
fi

# Ensure registry file exists
if [[ ! -f "$REGISTRY_FILE" ]]; then
  echo "Creating new registry file..."
  cat > "$REGISTRY_FILE" <<EOF
{
  "version": "1.0.0",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "services": []
}
EOF
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTAINER_NAME="sseris-${SERVICE_NAME}"
API_URL="https://apim.ayinza.dev${API_CONTEXT}/${API_VERSION}"

echo "Updating registry for: ${SERVICE_NAME}"

# Check if service already exists in registry
if jq -e ".services[] | select(.id == \"${SERVICE_NAME}\")" "$REGISTRY_FILE" > /dev/null 2>&1; then
  # Update existing service
  echo "Updating existing service entry..."
  jq --arg service "$SERVICE_NAME" \
     --arg context "$API_CONTEXT" \
     --arg status "$STATUS" \
     --arg version "$API_VERSION" \
     --arg timestamp "$TIMESTAMP" \
     --arg url "$API_URL" \
     --arg container "$CONTAINER_NAME" \
     '
     .updated_at = $timestamp |
     (.services[] | select(.id == $service)) |= . + {
       "api_context": $context,
       "api_version": $version,
       "status": $status,
       "last_deployed": $timestamp,
       "api_url": $url,
       "container_name": $container
     }
     ' "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
else
  # Add new service
  echo "Adding new service entry..."
  jq --arg service "$SERVICE_NAME" \
     --arg context "$API_CONTEXT" \
     --arg status "$STATUS" \
     --arg version "$API_VERSION" \
     --arg timestamp "$TIMESTAMP" \
     --arg url "$API_URL" \
     --arg container "$CONTAINER_NAME" \
     '
     .updated_at = $timestamp |
     .services += [{
       "id": $service,
       "container_name": $container,
       "api_context": $context,
       "api_version": $version,
       "api_url": $url,
       "status": $status,
       "registered_at": $timestamp,
       "last_deployed": $timestamp
     }]
     ' "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
fi

echo "Registry updated successfully!"
echo ""
echo "Service: ${SERVICE_NAME}"
echo "API URL: ${API_URL}"
echo "Status: ${STATUS}"
