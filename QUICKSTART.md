# Quick Start Guide

Get up and running with Dock in minutes!

## 1. Initial Setup (5 minutes)

### Configure Your Servers

```bash
# Copy example configuration
cp servers.yml.example servers.yml

# Edit with your server IPs
vim servers.yml
```

Update with your actual server information:

```yaml
servers:
  prod-web-1:
    ip: YOUR_SERVER_IP
    environment: production
    roles:
      - web
      - api
    ssh_user: deploy
```

### Set Up GitHub Secrets

Only two secrets needed:

1. Go to: Settings → Secrets and variables → Actions
2. Add secrets:
   - `SSH_PRIVATE_KEY`: Your private key for server access
   - `DEPLOY_SSH_PUBLIC_KEY`: Your public key (optional)

### Initial Commit

```bash
git add servers.yml .
git commit -m "Configure servers"
git push
```

## 2. Test Locally (2 minutes)

Before deploying to real servers, test locally:

```bash
# Quick test with Docker
./scripts/test-local.sh
```

This runs your Ansible playbooks against a local Docker container.

## 3. Deploy Infrastructure (10 minutes)

```bash
# Commit any infra changes
git add infra/
git commit -m "Initial infrastructure"
git push
```

Watch the deployment:
- Go to Actions tab
- Click "Infrastructure Deployment"
- Monitor the run

Or deploy manually:

```bash
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit staging
```

## 4. Add Your First Service (5 minutes)

### Create Service Structure

```bash
mkdir -p services/myapp
```

### Option A: Docker Compose Service

```bash
# Create docker-compose.yml
cat > services/myapp/docker-compose.yml <<EOF
version: '3.8'

services:
  myapp:
    image: nginx:alpine
    container_name: myapp
    ports:
      - "8080:80"
    networks:
      - services_network

networks:
  services_network:
    external: true
EOF

# Create deployment config
cat > services/myapp/deploy.yml <<EOF
service:
  name: myapp
  type: compose

targets:
  roles:
    - web

proxy:
  enabled: true
  path: /myapp
EOF
```

### Option B: Dockerfile Service

```bash
# Create Dockerfile
cat > services/myapp/Dockerfile <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# Create deployment config
cat > services/myapp/deploy.yml <<EOF
service:
  name: myapp
  type: dockerfile

runtime:
  image_name: myapp
  image_tag: latest
  container_port: 3000
  host_port: 3000
  network: services_network

targets:
  roles:
    - api

proxy:
  enabled: true
  path: /api
  strip_prefix: true
EOF
```

### Deploy the Service

```bash
# If using nginx proxy, update config
./scripts/update-nginx.sh

# Commit and push
git add services/myapp
git commit -m "Add myapp service"
git push
```

The service automatically deploys to servers matching the target roles!

## 5. Verify Deployment (2 minutes)

### Check GitHub Actions

- Go to Actions tab
- Click "Service Deployment"
- Verify successful deployment

### Test the Service

```bash
# Replace with your server IP
curl http://YOUR_SERVER_IP:8080

# If behind nginx
curl http://YOUR_SERVER_IP/myapp
```

### SSH to Server

```bash
# Check running containers
ssh deploy@YOUR_SERVER_IP "docker ps"

# Check logs
ssh deploy@YOUR_SERVER_IP "docker logs myapp"
```

## Common Workflows

### Adding a New Server

1. Edit `servers.yml`:
   ```yaml
   servers:
     prod-web-2:
       ip: NEW_SERVER_IP
       environment: production
       roles:
         - web
       ssh_user: deploy
   ```

2. Push changes:
   ```bash
   git add servers.yml
   git commit -m "Add prod-web-2"
   git push
   ```

3. Run infrastructure workflow manually for the new server

### Updating a Service

1. Edit service files
2. Push changes:
   ```bash
   git add services/myapp/
   git commit -m "Update myapp"
   git push
   ```

The service auto-deploys to its target servers!

### Deploying to Production

Services deploy to staging automatically. For production:

1. Go to Actions → Service Deployment
2. Click "Run workflow"
3. Select:
   - Service: `myapp` (or `all`)
   - Environment: `production`
4. Click "Run workflow"

### Rolling Back a Service

```bash
# SSH to server
ssh deploy@YOUR_SERVER_IP

# Stop current version
cd /opt/docker/myapp
docker compose down  # or: docker stop myapp

# Redeploy previous version (manual method)
# Or trigger workflow to redeploy specific commit
```

## Troubleshooting

### Service Won't Deploy

1. Check GitHub Actions logs
2. Verify `deploy.yml` syntax
3. Check server is accessible:
   ```bash
   ssh deploy@YOUR_SERVER_IP
   ```

### Ansible Fails

1. Test locally first:
   ```bash
   ./scripts/test-local.sh
   ```

2. Check syntax:
   ```bash
   cd infra
   ansible-playbook playbook.yml --syntax-check
   ```

3. Run with verbose output:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbook.yml -vvv
   ```

### Container Won't Start

```bash
# SSH to server
ssh deploy@YOUR_SERVER_IP

# Check container status
docker ps -a | grep myapp

# Check logs
docker logs myapp

# Check Docker network
docker network ls
docker network inspect services_network
```

## Next Steps

- [Local Testing Guide](docs/LOCAL_TESTING.md) - Test changes before deploying
- [Nginx Proxy Guide](docs/NGINX_PROXY.md) - Configure reverse proxy
- [Main README](README.md) - Full documentation
- [Services README](services/README.md) - Service configuration details
- [Infrastructure README](infra/README.md) - Ansible roles and playbooks

## Tips

1. **Always test locally** before deploying to production
2. **Use staging first** - let changes deploy to staging automatically
3. **Monitor logs** during deployment
4. **Keep servers.yml updated** with accurate server info
5. **Document your services** in their directories
6. **Use semantic versioning** for service images
7. **Back up data** before major changes

## Getting Help

- Check the docs in the `docs/` directory
- Review example services in `services/`
- Look at workflow runs in Actions tab
- Check service logs on the server

---

**You're all set!** 🚀

Your infrastructure is provisioned, services are deployed, and you have automatic CI/CD pipelines in place.
