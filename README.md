# WSO2 API Pipeline

Automated API Gateway registration for DRIE microservices using WSO2 API Manager.

## Overview

This pipeline provides **centralized, automated CI/CD** for all Quarkus backend services. Developers edit ONE file, push to `dev`, and their API is automatically built, deployed, and registered with WSO2.

### Key Features

- **Zero Manual Registration**: APIs auto-register on deployment
- **Single File Config**: Developers only edit `service-metadata.yml`
- **Centralized Governance**: Branch policies, naming conventions enforced
- **Deployment Tracking**: Every deployment recorded in registry
- **Single Gateway**: All APIs via `apim.ayinza.dev/{context}/v1`
- **Developer Portal**: APIs browsable in WSO2 DevPortal

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  Service Repo                         wso2-pipeline (This Repo)             │
│  ───────────                          ─────────────────────────             │
│                                                                             │
│  service-metadata.yml  ─────────────► .github/workflows/                    │
│  .github/workflows/deploy.yml ──────► build-deploy-register.yml             │
│                                              │                              │
│                                              ▼                              │
│  Push to dev branch ─────────────────► Build → Deploy → Register → Track   │
│                                                                             │
│                                              │                              │
│                                              ▼                              │
│                                       API Live at                           │
│                                       apim.ayinza.dev/{context}/v1          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### For Backend Developers

**Time: 5 minutes**

1. Copy files from `integration-kit/` to your service repo
2. Edit `service-metadata.yml` (4 fields only)
3. Push to `dev` branch
4. API auto-registers in ~5 minutes

```yaml
# service-metadata.yml - THE ONLY FILE YOU EDIT
service:
  name: "retail-operations"
  display_name: "Retail Operations API"
  description: "Manage retail operations"

api:
  context: "/retail"
```

See [docs/developer-onboarding.md](./docs/developer-onboarding.md) for complete guide.

### For Frontend Developers

1. Visit [Developer Portal](https://apim.ayinza.dev/devportal)
2. Browse available APIs
3. Subscribe and get API key
4. Start using the APIs

See [docs/frontend-developer-guide.md](./docs/frontend-developer-guide.md)

### For DevOps

See [docs/devops-guide.md](./docs/devops-guide.md) for:
- Initial server setup
- Maintenance procedures
- Troubleshooting

## Repository Structure

```
wso2-pipeline/
├── .github/workflows/
│   └── build-deploy-register.yml   # Reusable workflow (called by all services)
├── scripts/
│   ├── install-apictl.sh           # Install WSO2 apictl
│   ├── configure-wso2-env.sh       # Configure WSO2 environment
│   ├── generate-wso2-api.sh        # Generate API definition from OpenAPI
│   └── update-registry.sh          # Update service registry
├── registry/
│   └── services/
│       └── {service-name}/
│           └── release.json        # Auto-generated deployment record
├── integration-kit/                # Templates for developers
│   ├── .github/workflows/
│   │   └── deploy.yml              # Standardized workflow (DO NOT MODIFY)
│   ├── service-metadata.yml        # Template to copy and edit
│   └── README.md                   # Integration guide
├── docs/
│   ├── README.md                   # Documentation index
│   ├── developer-onboarding.md     # Backend developer guide
│   ├── frontend-developer-guide.md
│   └── devops-guide.md
└── README.md                       # This file
```

## Centralized Governance

All deployment settings are managed centrally in this repo:

| Setting | Value | Where Defined |
|---------|-------|---------------|
| Branch Policy | `dev` triggers deploy | `.github/workflows/build-deploy-register.yml` |
| Container Naming | `sseris-{service-name}` | `.github/workflows/build-deploy-register.yml` |
| Docker Network | `sseris-dev-server-network` | `.github/workflows/build-deploy-register.yml` |
| Registry | Harbor at `84.247.134.135:8081` | `.github/workflows/build-deploy-register.yml` |
| WSO2 Environment | `dev` | `.github/workflows/build-deploy-register.yml` |

**Benefits**:
- Consistent deployments across 30+ services
- Update once, all services benefit
- Developers can't accidentally break standards

## Deployment Tracking

Every deployment creates/updates a registry entry:

```json
// registry/services/retail-operations/release.json
{
  "service": "retail-operations",
  "displayName": "Retail Operations API",
  "apiContext": "/retail",
  "apiUrl": "https://apim.ayinza.dev/retail/v1",
  "commit": "abc123...",
  "repository": "DRIE/retail-operations-service",
  "deployedAt": "2025-11-25T10:30:00Z",
  "deployedBy": "developer",
  "status": "deployed"
}
```

## Configuration

### Environment Variables (Central)

| Variable | Description | Value |
|----------|-------------|-------|
| `WSO2_URL` | WSO2 API Manager URL | `https://apim.ayinza.dev` |
| `WSO2_ENV` | apictl environment name | `dev` |
| `REGISTRY` | Harbor registry | `84.247.134.135:8081` |
| `PROJECT` | Harbor project | `library` |
| `CONTAINER_PREFIX` | Container name prefix | `sseris` |
| `DOCKER_NETWORK` | Docker network | `sseris-dev-server-network` |

### Required Secrets

Secrets are inherited via `secrets: inherit` from the calling repo:

| Secret | Description |
|--------|-------------|
| `HARBOR_USERNAME` | Harbor registry username |
| `HARBOR_PASSWORD` | Harbor registry password |
| `NEXUS_USER` | Nexus Maven repo username |
| `NEXUS_PASS` | Nexus Maven repo password |
| `DB_USERNAME` | Database username |
| `DB_PASSWORD` | Database password |
| `KEYCLOAK_CLIENT_SECRET` | Keycloak OIDC secret |
| `WSO2_ADMIN_PASSWORD` | WSO2 admin password |

## URLs

| Service | URL |
|---------|-----|
| **API Gateway** | `https://apim.ayinza.dev` |
| **Publisher Portal** | `https://apim.ayinza.dev/publisher` |
| **Developer Portal** | `https://apim.ayinza.dev/devportal` |
| **Admin Console** | `https://apim.ayinza.dev/admin` |

## Roadmap

### Current (Phase 1)
- [x] Reusable workflow for backend services
- [x] Automatic WSO2 API registration
- [x] Deployment tracking (release.json)
- [x] Integration kit for developers

### Planned
- [ ] **Phase 2**: Environment branches (`qa`, `prod`) with PR-based promotion
- [ ] **Phase 3**: Frontend pipeline (separate `frontend-pipeline` repo)
- [ ] **Phase 4**: HashiCorp Vault integration for secrets
- [ ] **Phase 5**: Postman/Newman automated API testing

## Support

- [GitHub Actions](https://github.com/DRIE/wso2-pipeline/actions) - Check workflow status
- [Developer Portal](https://apim.ayinza.dev/devportal) - View published APIs
- [docs/](./docs/) - Detailed guides
- Contact DevOps team for issues
