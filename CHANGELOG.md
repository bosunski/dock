# Changelog - Major Updates

## Overview

This update transforms the repository into a fully-featured infrastructure and deployment platform with intelligent service targeting, local testing, and automatic proxy configuration.

## Key Changes

### 1. Server Configuration Management

**Before:** Server IPs stored in GitHub Secrets  
**After:** Centralized in `servers.yml` with rich metadata

#### What Changed:
- Created `servers.yml` for central server configuration
- Each server has: IP, environment, roles, SSH user, tags
- Servers organized by environment and role groups
- GitHub workflows read from `servers.yml` instead of secrets

#### Benefits:
- Easy to add/remove servers without touching secrets
- Role-based targeting (deploy to "all web servers")
- Clear visibility of infrastructure
- Version controlled server list

#### Files:
- `servers.yml` - Main configuration
- `servers.yml.example` - Template
- `.gitignore` - Updated to ignore servers.yml (optional)

### 2. Service Deployment Targeting

**Before:** Services deployed to all servers in environment  
**After:** Each service specifies exactly where it deploys

#### What Changed:
- Added `deploy.yml` to each service
- Services can target by: servers, roles, or environments
- Deployment matrix built from service + server configs
- Each service deploys only to its designated servers

#### Benefits:
- Database services only deploy to database servers
- API services only to API servers
- No manual workflow configuration needed
- Parallel deployments to multiple servers

#### Files:
- `services/*/deploy.yml` - Service deployment configuration
- `.github/workflows/deploy-services.yml` - Updated to use targeting

#### Example:
```yaml
# services/api/deploy.yml
targets:
  roles:
    - api  # Deploys to all servers with 'api' role
```

### 3. Local Testing Infrastructure

**Before:** No local testing capability  
**After:** Two options for local testing

#### What Changed:
- Added Docker-based test environment
- Added Vagrant-based test environment
- Automated test script: `scripts/test-local.sh`
- Local environment in Ansible inventory

#### Benefits:
- Test Ansible changes before production
- No risk to real servers
- Fast iteration cycle
- Works on any machine with Docker or Vagrant

#### Files:
- `docker-compose.test.yml` - Docker test environment
- `Vagrantfile` - Vagrant VM configuration
- `scripts/test-local.sh` - Automated testing script
- `scripts/setup-test-server.sh` - Container setup
- `docs/LOCAL_TESTING.md` - Complete testing guide

#### Usage:
```bash
./scripts/test-local.sh  # Runs full test cycle
```

### 4. Nginx Proxy Configuration

**Before:** Manual nginx configuration  
**After:** Auto-generated from service definitions

#### What Changed:
- Services specify proxy config in `deploy.yml`
- Python script generates nginx.conf automatically
- Support for multiple backends and domains
- Helper script to update and deploy

#### Benefits:
- Consistent nginx configuration
- No manual editing needed
- Services automatically added to proxy
- Clear separation of concerns

#### Files:
- `scripts/generate-nginx-config.py` - Config generator
- `scripts/update-nginx.sh` - Helper script
- `services/*/deploy.yml` - Proxy configuration per service
- `docs/NGINX_PROXY.md` - Complete proxy guide

#### Example:
```yaml
# services/api/deploy.yml
proxy:
  enabled: true
  path: /api
  strip_prefix: true
```

Then run: `./scripts/update-nginx.sh`

### 5. Enhanced Workflows

**Before:** Basic deployment to predefined servers  
**After:** Intelligent, targeted deployments

#### What Changed:
- Infrastructure workflow reads `servers.yml`
- Service workflow builds deployment matrix dynamically
- Each service deploys only to its target servers
- Parallel deployments for multiple servers
- Detailed deployment logging

#### Benefits:
- Faster deployments (parallel)
- More reliable (targeted)
- Better visibility (per-server logs)
- Flexible (easy to change targets)

#### Files:
- `.github/workflows/infrastructure.yml` - Updated
- `.github/workflows/deploy-services.yml` - Complete rewrite

### 6. Documentation

**Before:** Single README  
**After:** Comprehensive documentation suite

#### What Added:
- `QUICKSTART.md` - 15-minute setup guide
- `docs/LOCAL_TESTING.md` - Complete testing guide
- `docs/NGINX_PROXY.md` - Proxy configuration guide
- `CHANGELOG.md` - This file
- Updated main README with new features
- Updated service and infra READMEs

## Migration Guide

If you're upgrading from the old version:

### Step 1: Create servers.yml

```bash
cp servers.yml.example servers.yml
# Edit with your server IPs
```

### Step 2: Add deploy.yml to Each Service

For each existing service:

```bash
cat > services/YOURSERVICE/deploy.yml <<EOF
service:
  name: YOURSERVICE
  type: compose  # or dockerfile

targets:
  environments:
    - staging
    - production

proxy:
  enabled: false  # or true if behind nginx
EOF
```

### Step 3: Update Ansible Inventory

The inventory now references servers.yml. Keep your IPs in servers.yml and the workflow will sync them.

### Step 4: Test Locally

```bash
./scripts/test-local.sh
```

### Step 5: Remove Old Secrets

You can now remove (but keep for SSH keys):
- `STAGING_SERVER_IP`
- `PROD_SERVER_IP`
- `DEPLOY_USER`

Keep:
- `SSH_PRIVATE_KEY`
- `DEPLOY_SSH_PUBLIC_KEY`

### Step 6: Push Changes

```bash
git add .
git commit -m "Upgrade to new architecture"
git push
```

## Breaking Changes

### GitHub Secrets

Environment variable secrets for server IPs are no longer used. Update your secrets configuration.

### Service Deployment

Services without `deploy.yml` may not deploy. Add `deploy.yml` to all services.

### Ansible Inventory

The inventory format changed. Existing inventory will be overwritten by workflow from `servers.yml`.

## New Requirements

### For Local Testing:
- Docker or Vagrant installed
- Python 3.x with PyYAML

### For Nginx Generation:
- Python 3.x with PyYAML

Install with:
```bash
pip install PyYAML
```

## Configuration Examples

### Minimal Service

```yaml
# services/minimal/deploy.yml
service:
  name: minimal
  type: compose

targets:
  environments:
    - staging
```

### Full-Featured Service

```yaml
# services/advanced/deploy.yml
service:
  name: advanced
  type: dockerfile

runtime:
  image_name: my-app
  image_tag: v1.2.3
  container_port: 3000
  host_port: 3000
  network: services_network

targets:
  roles:
    - api
  # Or specific servers:
  # servers:
  #   - prod-web-1
  #   - prod-web-2

proxy:
  enabled: true
  path: /api
  strip_prefix: true

health_check:
  enabled: true
  endpoint: /health
  interval: 30

deployment:
  strategy: rolling
  wait_for_health: true
  timeout: 300
```

### Server Configuration

```yaml
# servers.yml
servers:
  prod-web-1:
    ip: 10.0.1.10
    environment: production
    roles:
      - web
      - api
    ssh_user: deploy
    tags:
      - frontend
      - backend

environments:
  production:
    - prod-web-1

role_groups:
  web:
    - prod-web-1
  api:
    - prod-web-1
```

## Testing the Changes

### Test Local Environment

```bash
./scripts/test-local.sh
```

### Test Service Deployment

```bash
# Make a change to a service
echo "# Updated" >> services/api/README.md

# Commit and push
git add services/api/
git commit -m "Test deployment"
git push

# Watch in Actions tab
```

### Test Nginx Generation

```bash
./scripts/update-nginx.sh
cat services/nginx/nginx.conf
```

## Troubleshooting

### "No module named 'yaml'"

```bash
pip install PyYAML
```

### "Permission denied" for scripts

```bash
chmod +x scripts/*.sh
```

### Services not deploying

Check that each service has `deploy.yml` with valid targets.

### Ansible can't connect

Verify `servers.yml` has correct IPs and SSH settings.

## Performance Improvements

- Parallel service deployments (faster CI/CD)
- Targeted deployments (less overhead)
- Local testing (faster development cycle)
- Cached Docker builds (faster container builds)

## Security Improvements

- Server IPs in version control (optional, can be gitignored)
- Reduced secret dependencies
- Role-based access control via targeting
- Continued SSH hardening via Ansible

## Future Enhancements

Potential additions:
- Multi-region support
- Blue-green deployments
- Canary deployments
- Automatic rollbacks
- Health check monitoring
- Log aggregation
- Metrics collection
- Secret management integration
- Terraform integration

## Questions?

- Check the documentation in `docs/`
- Review example services
- Open an issue
- Read the CONTRIBUTING.md

---

**Thank you for using Dock!** 🚀
