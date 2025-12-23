# Services Directory

This directory contains all deployable services. Each service should be in its own subdirectory.

## Service Types

### Docker Compose Services
Services that use `docker-compose.yml` for orchestration.

**Required files:**
- `docker-compose.yml` - Docker Compose configuration
- `.env.example` - Example environment variables (optional)

**Example:**
```
services/nginx/
├── docker-compose.yml
├── nginx.conf
└── README.md
```

### Dockerfile Services
Services that build from a custom Dockerfile.

**Required files:**
- `Dockerfile` - Container build instructions
- `deploy.env` - Deployment configuration (optional)

**Example:**
```
services/api/
├── Dockerfile
├── deploy.env
├── package.json
└── server.js
```

## Adding a New Service

1. Create a new directory: `services/your-service-name/`
2. Add either `docker-compose.yml` OR `Dockerfile`
3. Include necessary application files
4. Add `.env.example` or `deploy.env` for configuration
5. Commit and push - deployment happens automatically!

## Environment Variables

### For Docker Compose
Create a `.env` file (gitignored) based on `.env.example`:
```bash
cp .env.example .env
# Edit .env with your values
```

### For Dockerfile
Create `deploy.env` with deployment settings:
```bash
SERVICE_NAME=myservice
IMAGE_NAME=myservice
IMAGE_TAG=latest
CONTAINER_PORT=8080
HOST_PORT=8080
NETWORK=services_network
```

## Networks

Services should use the `services_network` Docker network for inter-service communication:

```yaml
networks:
  services_network:
    external: true
```

## Current Services

- **nginx/** - Reverse proxy with health monitoring
- **api/** - Example Node.js API service
- **database/** - PostgreSQL + Redis stack

## Best Practices

1. **Health Checks** - Always include health check endpoints
2. **Logging** - Configure proper log rotation
3. **Secrets** - Never commit secrets; use environment variables
4. **Documentation** - Add a README.md for complex services
5. **Testing** - Test locally before pushing
6. **Versioning** - Tag images with versions, not just `latest`

## Troubleshooting

### Service won't deploy
- Check workflow logs in GitHub Actions
- Verify all required files are present
- Ensure network configuration is correct

### Container won't start
```bash
# Check logs on server
docker logs <service-name>

# Check container status
docker ps -a | grep <service-name>
```

### Inter-service communication fails
- Verify all services use `services_network`
- Check that services reference each other by service name
- Ensure ports are exposed correctly
