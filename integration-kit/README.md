# WSO2 API Integration Kit

Integrate your Quarkus microservice with WSO2 API Manager in 5 minutes.

## How It Works

```
Your Service Repo                    wso2-pipeline (Central)
├── service-metadata.yml  ────────►  Reads your config
├── .github/workflows/
│   └── deploy.yml        ────────►  Calls reusable workflow
└── api/
    └── (your code)
                                     ┌─────────────────────────┐
    Push to dev branch  ──────────►  │ Build → Deploy → WSO2   │
                                     │ Register → Track        │
                                     └─────────────────────────┘
```

**Key Principle**: You only edit ONE file (`service-metadata.yml`). Everything else is centrally managed.

## Quick Setup

### Step 1: Copy Files

```bash
# From your service repository root:
mkdir -p .github/workflows

# Copy workflow file (DO NOT MODIFY)
cp /path/to/wso2-pipeline/integration-kit/.github/workflows/deploy.yml .github/workflows/

# Copy metadata template
cp /path/to/wso2-pipeline/integration-kit/service-metadata.yml ./
```

### Step 2: Edit service-metadata.yml

This is the **ONLY** file you need to edit:

```yaml
service:
  name: "retail-operations"           # Your service identifier (lowercase, hyphens)
  display_name: "Retail Operations API"  # Name shown in DevPortal
  description: "Manage retail operations"
  oidc_client_id: "drie-retail-ops"   # Your Keycloak client ID
  database: "retail_ops_db"           # PostgreSQL database (auto-created if missing)

api:
  context: "/retail"                  # Your API path
```

### Step 3: Push to Deploy

```bash
git add .
git commit -m "Add WSO2 API integration"
git push origin dev
```

## What Gets Deployed

When you push to `dev`:

| Step | Action |
|------|--------|
| 1. Build | Maven build, Docker image pushed to Harbor |
| 2. Deploy | Container started with your service |
| 3. Health | Waits for `/q/health` to return OK |
| 4. Register | API registered with WSO2 automatically |
| 5. Track | Deployment recorded in registry |

## Your API Endpoints

After deployment:

| Endpoint | URL |
|----------|-----|
| **API Gateway** | `https://apim.ayinza.dev{context}/v1` |
| **Developer Portal** | `https://apim.ayinza.dev/devportal` |
| **Health Check** | `http://sseris-{service-name}:8080/q/health` |

Example: If `context: "/retail"` → API URL is `https://apim.ayinza.dev/retail/v1`

## Requirements

Your Quarkus service must have:

| Requirement | Details |
|-------------|---------|
| Health endpoint | `/q/health` (standard Quarkus) |
| OpenAPI spec | `/q/openapi` (requires extension) |
| Dockerfile | At `api/src/main/docker/Dockerfile.jvm` |
| docker-compose.yml | At `api/docker-compose.yml` |

### Add OpenAPI Support

If not already added to your `pom.xml`:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-smallrye-openapi</artifactId>
</dependency>
```

### Configure OpenAPI Metadata (REQUIRED)

Your OpenAPI spec **must** include `info` section for WSO2 registration to work.

Add to your `application.properties`:

```properties
# OpenAPI Configuration (REQUIRED for WSO2 API registration)
quarkus.smallrye-openapi.info-title=Your API Name
quarkus.smallrye-openapi.info-description=Description of your API
quarkus.smallrye-openapi.info-version=1.0.0
quarkus.smallrye-openapi.info-contact-name=Your Team
quarkus.smallrye-openapi.info-contact-email=team@ayinza.com
```

Or in `application.yml`:

```yaml
quarkus:
  smallrye-openapi:
    info-title: Your API Name
    info-description: Description of your API
    info-version: 1.0.0
```

**Why this matters**: The API name registered in WSO2 comes from the OpenAPI `info.title`. Without it, registration will fail.

### Dockerfile Location

Your Dockerfile should be at: `api/src/main/docker/Dockerfile.jvm`

Standard Quarkus JVM Dockerfile works out of the box.

## Important Notes

### DO NOT Modify deploy.yml

The workflow file is **standardized**. All configuration comes from:
- `service-metadata.yml` - Your service config
- `wso2-pipeline` - Centralized deployment settings

This ensures:
- Consistent deployments across all services
- Centralized governance (branch policies, naming conventions)
- Easy updates (change once in wso2-pipeline, all services benefit)

### Branch Policy

- **dev** branch: Triggers deployment
- Future: `qa`, `prod` branches with PR-based promotion

### Container Naming

Your container will be named: `sseris-{service-name}`

Example: `service.name: "retail-operations"` → Container: `sseris-retail-operations`

## Troubleshooting

### Build fails

```bash
# Check if Maven builds locally
cd api && ./mvnw clean package -DskipTests
```

### Health check fails

```bash
# Check container logs
docker logs sseris-{service-name} --tail 100

# Test health endpoint directly
curl http://sseris-{service-name}:8080/q/health
```

### API not appearing in DevPortal

1. Check workflow run in GitHub Actions
2. Verify service is healthy
3. Check OpenAPI spec: `curl http://sseris-{service-name}:8080/q/openapi`

### Need Help?

- Check [wso2-pipeline Actions](https://github.com/DRIE/wso2-pipeline/actions)
- Review [developer-onboarding.md](../docs/developer-onboarding.md)
- Contact the DevOps team
