# DevOps Guide

This guide covers initial setup, maintenance, and troubleshooting for the WSO2 API Pipeline.

## Initial Server Setup

### Prerequisites

- Docker installed
- Docker network `sseris-dev-server-network` exists
- WSO2 API Manager running (`drie-wso2-api-manager`)
- GitHub self-hosted runner configured

### Step 1: Install apictl

```bash
# SSH to server
ssh user@84.247.134.135

# Run install script
cd /path/to/wso2-pipeline
chmod +x scripts/install-apictl.sh
./scripts/install-apictl.sh

# Verify
apictl version
```

### Step 2: Configure WSO2 Environment

```bash
chmod +x scripts/configure-wso2-env.sh

# Configure dev environment
./scripts/configure-wso2-env.sh dev https://apim.ayinza.dev admin YOUR_PASSWORD

# Verify
apictl list envs
```

### Step 3: Set Up GitHub Secrets

In the `wso2-pipeline` repository:

1. Go to **Settings → Secrets → Actions**
2. Add: `WSO2_ADMIN_PASSWORD` = WSO2 admin password

### Step 4: Create Personal Access Token (PAT)

For service repos to trigger wso2-pipeline:

1. Go to GitHub → Settings → Developer Settings → Personal Access Tokens
2. Generate new token with `repo` scope
3. Distribute to developers as `WSO2_PIPELINE_TOKEN`

## Daily Operations

### Monitoring

**Check workflow status:**
- https://github.com/DRIE/wso2-pipeline/actions

**Check registered services:**
```bash
cat api-registry/services.json | jq '.services[].id'
```

**Check WSO2 status:**
```bash
docker ps | grep wso2
curl -k https://apim.ayinza.dev/carbon/
```

### Manual API Registration

If automatic registration fails:

```bash
# SSH to server
cd /path/to/wso2-pipeline

# Generate API from running service
./scripts/generate-wso2-api.sh \
  --service "service-name" \
  --context "/api-path" \
  --openapi <(curl -s http://sseris-service-name:8080/q/openapi) \
  --output ./generated-api

# Deploy
apictl import api -f ./generated-api -e dev --update -k
```

### Remove an API

```bash
apictl delete api -n "API-Name" -v v1 -e dev -k
```

### List All APIs

```bash
apictl list apis -e dev -k
```

## Maintenance Tasks

### Update apictl

```bash
# Download new version
APICTL_VERSION="4.3.1"  # Check for latest
curl -L "https://github.com/wso2/product-apim-tooling/releases/download/v${APICTL_VERSION}/apictl-${APICTL_VERSION}-linux-x64.tar.gz" -o apictl.tar.gz

# Install
tar -xvf apictl.tar.gz
sudo mv apictl /usr/local/bin/
apictl version
```

### Backup API Definitions

```bash
# Export all APIs
mkdir -p backups/$(date +%Y%m%d)
apictl export apis --all -e dev -k --output backups/$(date +%Y%m%d)/
```

### Update WSO2 Password

1. Change password in WSO2 Carbon console
2. Update GitHub secret `WSO2_ADMIN_PASSWORD`
3. Re-configure apictl:
   ```bash
   apictl logout dev
   apictl login dev -u admin -p NEW_PASSWORD -k
   ```

### Clean Up Old API Versions

```bash
# List API versions
apictl list api-products -e dev -k

# Delete specific version
apictl delete api -n "API-Name" -v v1 -e dev -k
```

## Troubleshooting

### Workflow Fails: Health Check

**Symptoms**: "Service health check failed"

**Check:**
```bash
# Is container running?
docker ps | grep sseris-SERVICE_NAME

# Check logs
docker logs sseris-SERVICE_NAME --tail 100

# Test health manually
curl http://sseris-SERVICE_NAME:8080/q/health
```

**Common causes:**
- Container not on correct network
- Port mismatch (should be 8080)
- Application startup failure

### Workflow Fails: OpenAPI Fetch

**Symptoms**: "Failed to fetch OpenAPI spec"

**Check:**
```bash
# Test OpenAPI endpoint
curl http://sseris-SERVICE_NAME:8080/q/openapi

# Check if extension is installed (Quarkus)
# Service needs quarkus-smallrye-openapi dependency
```

### Workflow Fails: apictl Import

**Symptoms**: "apictl import api failed"

**Check:**
```bash
# Login manually
apictl login dev -u admin -p PASSWORD -k

# Try import with verbose
apictl import api -f ./generated-api -e dev --update -k --verbose

# Check API definition
cat ./generated-api/Meta-information/api.yaml
```

**Common causes:**
- WSO2 unreachable
- Invalid API definition
- Authentication expired

### API Not Appearing in DevPortal

**Check:**
1. API published? (Check Publisher portal)
2. Visibility set to PUBLIC?
3. No errors in WSO2 logs:
   ```bash
   docker logs drie-wso2-api-manager --tail 100
   ```

### Cannot Access WSO2

**Check:**
```bash
# Nginx proxy
curl -I https://apim.ayinza.dev

# Direct access (from server)
curl -k https://localhost:9443/carbon/

# Container running?
docker ps | grep wso2
```

## Service Registry

The `api-registry/services.json` tracks all registered services:

```json
{
  "version": "1.0.0",
  "updated_at": "2025-11-25T12:00:00Z",
  "services": [
    {
      "id": "retail-operations",
      "container_name": "sseris-retail-operations",
      "api_context": "/retail",
      "api_version": "v1",
      "api_url": "https://apim.ayinza.dev/retail/v1",
      "status": "deployed",
      "registered_at": "2025-11-25T12:00:00Z",
      "last_deployed": "2025-11-25T12:00:00Z"
    }
  ]
}
```

### Query Registry

```bash
# List all services
jq '.services[].id' api-registry/services.json

# Get service details
jq '.services[] | select(.id == "retail-operations")' api-registry/services.json

# Count services
jq '.services | length' api-registry/services.json
```

## Network Configuration

### Docker Network

All containers must be on the same network:

```bash
# Verify network exists
docker network ls | grep sseris-dev-server-network

# Create if missing
docker network create sseris-dev-server-network

# Check containers on network
docker network inspect sseris-dev-server-network | jq '.[0].Containers'
```

### Container Naming Convention

- Prefix: `sseris-`
- Pattern: `sseris-{service-name}`
- Example: `sseris-retail-operations`

## Security

### GitHub Tokens

- `WSO2_ADMIN_PASSWORD`: Store in wso2-pipeline secrets
- `WSO2_PIPELINE_TOKEN`: Distribute to developers via secure channel
- Rotate tokens periodically

### WSO2 Access

- Default admin password should be changed
- Consider enabling SSO with Keycloak
- Review API visibility settings

## Migration to New Server

1. Install Docker and create network
2. Deploy WSO2 API Manager
3. Set up Nginx reverse proxy
4. Clone wso2-pipeline repo
5. Run `install-apictl.sh`
6. Run `configure-wso2-env.sh`
7. Import API definitions from backup

All configurations are in git, making migration reproducible.

## Monitoring (Future)

Planned enhancements:
- [ ] Newman API tests
- [ ] Prometheus metrics
- [ ] Grafana dashboard
- [ ] Slack notifications
- [ ] Scheduled health checks

## Support

- GitHub Actions: Check workflow logs
- WSO2 Logs: `docker logs drie-wso2-api-manager`
- Service Registry: `api-registry/services.json`
