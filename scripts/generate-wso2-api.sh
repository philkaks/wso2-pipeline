#!/bin/bash
# Generate WSO2 API definition from OpenAPI spec
# This script creates the folder structure required by apictl import

set -e

# Default values
SERVICE_NAME=""
API_CONTEXT=""
OPENAPI_FILE=""
OUTPUT_DIR="./generated-api"
API_VERSION="v1"
CONTAINER_PREFIX="sseris"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --service) SERVICE_NAME="$2"; shift 2;;
    --context) API_CONTEXT="$2"; shift 2;;
    --openapi) OPENAPI_FILE="$2"; shift 2;;
    --output) OUTPUT_DIR="$2"; shift 2;;
    --version) API_VERSION="$2"; shift 2;;
    --prefix) CONTAINER_PREFIX="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 --service NAME --context /path --openapi FILE [--output DIR] [--version v1] [--prefix sseris]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# Validate required arguments
if [[ -z "$SERVICE_NAME" || -z "$API_CONTEXT" || -z "$OPENAPI_FILE" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --service NAME --context /path --openapi FILE"
  exit 1
fi

if [[ ! -f "$OPENAPI_FILE" ]]; then
  echo "Error: OpenAPI file not found: $OPENAPI_FILE"
  exit 1
fi

echo "Generating WSO2 API definition..."
echo "  Service: $SERVICE_NAME"
echo "  Context: $API_CONTEXT"
echo "  OpenAPI: $OPENAPI_FILE"
echo "  Output: $OUTPUT_DIR"

# Create API project structure
mkdir -p "${OUTPUT_DIR}/Definitions"

# Copy OpenAPI spec
cp "${OPENAPI_FILE}" "${OUTPUT_DIR}/Definitions/swagger.yaml"

# Extract API info from OpenAPI
API_TITLE=$(jq -r '.info.title // "API"' "${OPENAPI_FILE}" | tr -d '"')
API_DESCRIPTION=$(jq -r '.info.description // "Auto-registered API"' "${OPENAPI_FILE}" | tr -d '"')

# Sanitize API name (remove special characters, replace spaces with dashes)
API_NAME=$(echo "${API_TITLE}" | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/ /-/g')

# Container name for backend endpoint
CONTAINER_NAME="${CONTAINER_PREFIX}-${SERVICE_NAME}"

echo "  API Name: $API_NAME"
echo "  Container: $CONTAINER_NAME"

# Generate api.yaml at root level (required by apictl 4.x)
cat > "${OUTPUT_DIR}/api.yaml" <<EOF
type: api
version: v4.3.0
data:
  name: ${API_NAME}
  description: "${API_DESCRIPTION}"
  context: ${API_CONTEXT}
  version: ${API_VERSION}
  provider: admin
  lifeCycleStatus: PUBLISHED

  endpointConfig:
    endpoint_type: http
    production_endpoints:
      url: http://${CONTAINER_NAME}:8080
    sandbox_endpoints:
      url: http://${CONTAINER_NAME}:8080

  visibility: PUBLIC
  visibleRoles: []
  visibleTenants: []

  tier: Unlimited
  subscriptionAvailability: CURRENT_TENANT

  transport:
    - http
    - https

  securityScheme:
    - oauth2

  corsConfiguration:
    corsConfigurationEnabled: true
    accessControlAllowOrigins:
      - "*"
    accessControlAllowCredentials: false
    accessControlAllowHeaders:
      - authorization
      - Access-Control-Allow-Origin
      - Content-Type
      - SOAPAction
      - apikey
      - Internal-Key
    accessControlAllowMethods:
      - GET
      - POST
      - PUT
      - DELETE
      - PATCH
      - OPTIONS

  tags:
    - ${SERVICE_NAME}
    - auto-registered

  additionalProperties: []
EOF

# Generate deployment_environments.yaml
cat > "${OUTPUT_DIR}/deployment_environments.yaml" <<EOF
type: deployment_environments
version: v4.3.0
data:
  - displayOnDevportal: true
    deploymentEnvironment: Default
EOF

echo ""
echo "API definition generated successfully at: ${OUTPUT_DIR}"
echo ""
echo "To deploy, run:"
echo "  apictl import api -f ${OUTPUT_DIR} -e dev --update -k"
