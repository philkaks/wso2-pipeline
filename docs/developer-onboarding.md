# Backend Developer Onboarding Guide

This guide helps backend developers integrate their Quarkus microservices with the WSO2 API Gateway.

**Time Required**: ~5 minutes

## Overview

```
┌──────────────────────────────────────────────────────────────────┐
│ What You Do (ONE file)              What Happens Automatically   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Edit service-metadata.yml    →    Build Docker image           │
│  Push to dev branch           →    Deploy to server             │
│                                →    Health check                 │
│                                →    Register with WSO2           │
│                                →    Track in registry            │
│                                                                  │
│  Result: API live at apim.ayinza.dev/{context}/v1               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Prerequisites

Your Quarkus service needs:

| Requirement | Details | How to Add |
|-------------|---------|------------|
| Health Endpoint | `/q/health` | Built into Quarkus |
| OpenAPI Spec | `/q/openapi` | Add `quarkus-smallrye-openapi` |
| Dockerfile | JVM Dockerfile | At `api/src/main/docker/Dockerfile.jvm` |
| Docker Compose | Deployment config | At `api/docker-compose.yml` |

### Add OpenAPI Support

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-smallrye-openapi</artifactId>
</dependency>
```

### Standard Dockerfile

Use the standard Quarkus JVM Dockerfile. Example at:
`api/src/main/docker/Dockerfile.jvm`

```dockerfile
FROM registry.access.redhat.com/ubi8/openjdk-22:1.20

ENV LANGUAGE='en_US:en'

COPY --chown=185 target/quarkus-app/lib/ /deployments/lib/
COPY --chown=185 target/quarkus-app/*.jar /deployments/
COPY --chown=185 target/quarkus-app/app/ /deployments/app/
COPY --chown=185 target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER 185
ENV JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

ENTRYPOINT [ "/opt/jboss/container/java/run/run-java.sh" ]
```

## Integration Steps

### Step 1: Copy Integration Files

```bash
cd your-service-repo

# Create workflow directory
mkdir -p .github/workflows

# Copy from wso2-pipeline (DO NOT MODIFY deploy.yml)
cp /path/to/wso2-pipeline/integration-kit/.github/workflows/deploy.yml .github/workflows/
cp /path/to/wso2-pipeline/integration-kit/service-metadata.yml ./
```

### Step 2: Edit service-metadata.yml

**This is the ONLY file you need to edit:**

```yaml
service:
  name: "your-service-name"              # Unique identifier
  display_name: "Your Service API"       # Shown in DevPortal
  description: "What your API does"

api:
  context: "/your-path"                  # URL path
```

**Naming Conventions:**

| Field | Rules | Example |
|-------|-------|---------|
| `service.name` | Lowercase, hyphens, unique | `retail-operations` |
| `api.context` | Starts with `/`, short | `/retail` |

### Step 3: Push to Deploy

```bash
git add .
git commit -m "Add WSO2 API integration"
git push origin dev
```

**Important**: Only pushes to `dev` branch trigger deployment.

## What Happens Automatically

| Step | Action | Duration |
|------|--------|----------|
| 1. Build | Maven build, Docker image | ~2 min |
| 2. Push | Image to Harbor registry | ~30 sec |
| 3. Deploy | Container started | ~30 sec |
| 4. Health | Wait for `/q/health` OK | ~1 min |
| 5. Register | API registered with WSO2 | ~1 min |
| 6. Track | Deployment recorded | immediate |

**Total time**: ~5 minutes

## Verify Your Deployment

### Check Workflow Status

1. Go to your repo → **Actions** tab
2. Look for "Deploy" workflow run

### Access Your API

| Endpoint | URL |
|----------|-----|
| API Gateway | `https://apim.ayinza.dev{context}/v1` |
| Developer Portal | `https://apim.ayinza.dev/devportal` |
| Direct Health Check | `http://sseris-{service-name}:8080/q/health` |

Example: `context: "/retail"` → `https://apim.ayinza.dev/retail/v1`

### Check Deployment Registry

After deployment, your service is tracked at:
```
wso2-pipeline/registry/services/{service-name}/release.json
```

## API Documentation

Your OpenAPI spec automatically becomes API documentation in DevPortal.

### Improve Your OpenAPI

Add annotations to your Quarkus resources:

```java
@Path("/products")
@Tag(name = "Products", description = "Product management")
public class ProductResource {

    @GET
    @Operation(summary = "List products",
               description = "Returns paginated list of products")
    @APIResponse(responseCode = "200",
                 description = "List of products",
                 content = @Content(schema = @Schema(implementation = ProductList.class)))
    public Response listProducts() {
        // ...
    }
}
```

## Important Rules

### DO NOT Modify deploy.yml

The workflow file is **standardized**. You cannot change:
- Branch policies (only `dev` triggers)
- Container naming (`sseris-{service-name}`)
- Registry settings
- Network configuration

This ensures:
- Consistent deployments across all 30+ services
- Centralized governance
- Easy updates (DevOps changes once, all benefit)

### Your Container

Your container is named: `sseris-{service-name}`

It runs on the `sseris-dev-server-network` Docker network.

## Troubleshooting

### Build Fails

```bash
# Test locally first
cd api && ./mvnw clean package -DskipTests

# Check Maven settings
cat ~/.m2/settings.xml
```

### Health Check Fails

```bash
# Check container logs
docker logs sseris-{service-name} --tail 100

# Common causes:
# - Database connection issues
# - Missing environment variables
# - Port binding issues
```

### API Not in DevPortal

1. Check workflow in GitHub Actions
2. Verify OpenAPI spec:
   ```bash
   curl http://sseris-{service-name}:8080/q/openapi
   ```
3. Check [wso2-pipeline Actions](https://github.com/DRIE/wso2-pipeline/actions)

### Changes Not Deployed

- Make sure you pushed to `dev` branch
- Feature branches don't trigger deployment
- Check that `.github/workflows/deploy.yml` exists

## Complete Example

### service-metadata.yml

```yaml
# retail-operations-service/service-metadata.yml
service:
  name: "retail-operations"
  display_name: "Retail Operations API"
  description: "Manage stores, products, and inventory"

api:
  context: "/retail"
```

### Result

| Property | Value |
|----------|-------|
| Container | `sseris-retail-operations` |
| API URL | `https://apim.ayinza.dev/retail/v1` |
| DevPortal | `https://apim.ayinza.dev/devportal` |

## Quick Reference

```
Files you need:
├── service-metadata.yml        ← EDIT THIS (only this!)
├── .github/workflows/
│   └── deploy.yml              ← DO NOT MODIFY
└── api/
    ├── pom.xml                 ← Add quarkus-smallrye-openapi
    ├── docker-compose.yml
    └── src/main/docker/
        └── Dockerfile.jvm
```

## Need Help?

- [wso2-pipeline Actions](https://github.com/DRIE/wso2-pipeline/actions) - Check deployment logs
- [Developer Portal](https://apim.ayinza.dev/devportal) - View published APIs
- [Integration Kit README](../integration-kit/README.md) - Detailed setup guide
- Contact DevOps team
