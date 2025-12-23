# Dock - Infrastructure and Service Deployment Platform

A complete infrastructure-as-code and service deployment platform combining Ansible for server provisioning and Docker for containerized application deployment. Features intelligent service-to-server targeting, local testing capabilities, and automatic Nginx proxy configuration.

## 📖 Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get up and running in 15 minutes
- **[Local Testing Guide](docs/LOCAL_TESTING.md)** - Test Ansible changes locally
- **[Nginx Proxy Guide](docs/NGINX_PROXY.md)** - Configure reverse proxy
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute

## 🏗️ Architecture

```
dock/
├── servers.yml             # Central server configuration
├── infra/                  # Ansible infrastructure code
│   ├── ansible.cfg
│   ├── playbook.yml
│   ├── inventory/
│   └── roles/              # common, docker, security, monitoring
│
├── services/               # Application services
│   ├── nginx/              # Reverse proxy (Docker Compose)
│   │   ├── docker-compose.yml
│   │   └── deploy.yml      # Deployment targeting config
│   ├── api/                # API service (Dockerfile)
│   │   ├── Dockerfile
│   │   └── deploy.yml
│   └── database/           # Database stack (Docker Compose)
│       ├── docker-compose.yml
│       └── deploy.yml
│
├── scripts/
│   ├── test-local.sh           # Local Ansible testing
│   ├── generate-nginx-config.py # Dynamic Nginx config
│   └── update-nginx.sh
│
├── .github/workflows/
│   ├── infrastructure.yml      # Deploy infra on changes
│   └── deploy-services.yml     # Smart service deployment
│
├── Vagrantfile                 # Local testing with Vagrant
└── docker-compose.test.yml     # Local testing with Docker
```

## 🚀 Quick Start

### Prerequisites

- GitHub repository with Actions enabled
- Target server(s) with SSH access
- GitHub Secrets configured (only SSH key required now!)

### Setup

1. **Configure Server List**

   Copy and edit [`servers.yml.example`](servers.yml.example) to [`servers.yml`](servers.yml):
   
   ```bash
   cp servers.yml.example servers.yml
   # Edit servers.yml with your actual server IPs
   ```
   
   Example configuration:
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

2. **Configure GitHub Secrets**

   Only two secrets are now required:

   ```
   SSH_PRIVATE_KEY          # Private key for SSH access to all servers
   DEPLOY_SSH_PUBLIC_KEY    # Public key for the deploy user (optional)
   ```

3. **Define Service Targets**

   Each service has a `deploy.yml` specifying where it should deploy:
   
   ```yaml
   # services/api/deploy.yml
   targets:
     roles:
       - api  # Deploy to all servers with 'api' role
   ```

2. **Customize Infrastructure**

   Update [`servers.yml`](servers.yml) with your server details. The Ansible inventory will automatically sync from this file.

3. **Add Your Services**

   Create a new directory in [`services/`](services/) for each application with a `deploy.yml` to specify targeting.

   **Option A: Docker Compose**
   ```bash
   services/myapp/
   ├── docker-compose.yml
   └── .env.example
   ```

   **Option B: Dockerfile**
   ```bash
   services/myapp/
   ├── Dockerfile
   ├── deploy.env          # Deployment configuration
   └── (application files)
   ```

## 📦 Service Deployment

### Service Targeting Configuration

Each service specifies deployment targets in `deploy.yml`:

```yaml
# services/myapp/deploy.yml
service:
  name: myapp
  type: compose  # or "dockerfile"

targets:
  # Option 1: Target specific servers
  servers:
    - prod-web-1
    - prod-web-2
  
  # Option 2: Target by role
  # roles:
  #   - web
  
  # Option 3: Target by environment
  # environments:
  #   - production

# Optional: Nginx proxy configuration
proxy:
  enabled: true
  path: /myapp
  strip_prefix: false
```

### Docker Compose Services

For services using Docker Compose (like nginx, database examples):

1. Create `docker-compose.yml` in `services/your-service/`
2. Create `deploy.yml` to specify target servers
3. Push changes to trigger automatic deployment to specified servers

Example structure:
```yaml
version: '3.8'
services:
  myapp:
    image: myapp:latest
    ports:
      - "8080:8080"
    networks:
      - services_network
```

### Dockerfile Services

For custom built services (like the API example):

1. Create `Dockerfile` in `services/your-service/`
2. Create `deploy.yml` with runtime configuration:
   ```yaml
   service:
     name: api
     type: dockerfile
   
   runtime:
     image_name: my-api
     image_tag: latest
     container_port: 3000
     host_port: 3000
     network: services_network
   
   targets:
     roles:
       - api
   ```
3. Push changes to trigger build and deployment

## 🔄 Workflows

### Infrastructure Deployment

**Trigger:** Changes to `infra/**` files

The infrastructure workflow:
1. Reads server configuration from `servers.yml`
2. Installs Ansible and sets up SSH
3. Runs the Ansible playbook against target servers
4. Installs Docker, configures security, sets up monitoring

**Manual deployment:**
```bash
# Via GitHub Actions UI
Actions → Infrastructure Deployment → Run workflow → Select environment
```

**Local deployment:**
```bash
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit staging
```

### Service Deployment

**Trigger:** Changes to `services/**` files

The service deployment workflow:
1. Detects which services changed
2. Reads each service's `deploy.yml` for targeting
3. Determines target servers based on roles/environments/explicit servers
4. Deploys each service to its specified servers only
5. Performs health checks on each deployment

**Manual deployment:**
```bash
# Deploy specific service via GitHub Actions UI
Actions → Service Deployment → Run workflow
# Select service and environment
```

**Local deployment with Docker Compose:**
```bash
# Copy files to server
scp -r services/myapp user@server:/opt/docker/myapp/

# SSH to server and deploy
ssh user@server
cd /opt/docker/myapp
docker compose up -d
```

**Local deployment with Dockerfile:**
```bash
# On target server
cd /opt/docker/myapp
docker build -t myapp:latest .
docker run -d --name myapp -p 8080:8080 myapp:latest
```

## 🧪 Local Testing

Test your Ansible infrastructure changes locally before deploying:

```bash
# Quick test with Docker
chmod +x scripts/test-local.sh
./scripts/test-local.sh
```

Or use Vagrant for a full VM:

```bash
vagrant up
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local
```

📖 **[Full Local Testing Guide](docs/LOCAL_TESTING.md)**

## 🌐 Nginx Reverse Proxy

Put services behind Nginx automatically:

1. Enable in service's `deploy.yml`:
   ```yaml
   proxy:
     enabled: true
     path: /api
   ```

2. Generate config:
   ```bash
   ./scripts/update-nginx.sh
   ```

3. Deploy:
   ```bash
   git push  # Auto-deploys updated nginx
   ```

📖 **[Full Nginx Proxy Guide](docs/NGINX_PROXY.md)**

## 🛠️ Infrastructure Roles

### Common Role
- Installs essential packages (curl, wget, git, vim, htop)
- Configures timezone (UTC)
- Creates deploy user with sudo access
- Sets up SSH authorized keys

### Docker Role
- Adds Docker repository
- Installs Docker CE and Docker Compose
- Configures Docker daemon with logging limits
- Creates Docker networks (services_network, monitoring_network)
- Adds users to docker group

### Security Role
- Configures UFW firewall (ports 22, 80, 443)
- Installs and configures fail2ban
- Disables root login
- Disables password authentication

### Monitoring Role
- Installs prometheus-node-exporter
- Installs ctop for container monitoring

## 📋 Example Services

### 1. Nginx (Docker Compose)
Reverse proxy with health checks and logging.

**Location:** [`services/nginx/`](services/nginx/)

**Deploy:**
```bash
cd services/nginx
docker compose up -d
```

### 2. API (Dockerfile)
Node.js API service with custom build.

**Location:** [`services/api/`](services/api/)

**Deploy:**
```bash
cd services/api
docker build -t my-api .
docker run -d -p 3000:3000 --name api my-api
```

### 3. Database (Docker Compose)
PostgreSQL + Redis with persistent storage.

**Location:** [`services/database/`](services/database/)

**Configure:**
```bash
cp services/database/.env.example services/database/.env
# Edit .env with your credentials
```

## 🔐 Security Best Practices

1. **Secrets Management**
   - Never commit secrets to the repository
   - Use GitHub Secrets for sensitive data
   - Use `.env.example` files as templates

2. **SSH Access**
   - Use SSH keys, not passwords
   - Disable root login (done by security role)
   - Use dedicated deploy user

3. **Firewall**
   - Only allow necessary ports
   - Use UFW (configured by security role)
   - Consider using VPN for internal services

4. **Container Security**
   - Run containers as non-root when possible
   - Use official images or scan custom images
   - Keep images updated

## 🎯 Usage Examples

### Adding a New Service

1. **Create service directory:**
   ```bash
   mkdir -p services/my-new-service
   ```

2. **Create deploy configuration:**
   ```bash
   cat > services/my-new-service/deploy.yml <<EOF
   service:
     name: my-new-service
     type: compose  # or "dockerfile"
   
   targets:
     roles:
       - web  # Deploy to servers with 'web' role
   
   proxy:
     enabled: true  # Put behind Nginx
     path: /myapp
   EOF
   ```

3. **Option A - Docker Compose:**
   ```bash
   cat > services/my-new-service/docker-compose.yml <<EOF
   version: '3.8'
   services:
     app:
       image: my-app:latest
       ports:
         - "8080:8080"
       networks:
         - services_network
   
   networks:
     services_network:
       external: true
   EOF
   ```

4. **Option B - Dockerfile:**
   ```bash
   cat > services/my-new-service/Dockerfile <<EOF
   FROM node:18-alpine
   WORKDIR /app
   COPY . .
   CMD ["npm", "start"]
   EOF
   ```

5. **Update Nginx (if proxied):**
   ```bash
   ./scripts/update-nginx.sh
   ```

6. **Commit and push:**
   ```bash
   git add services/my-new-service
   git commit -m "Add my-new-service"
   git push  # Auto-deploys to servers with 'web' role
   ```

### Deploying to Production

1. **Merge to main branch** (triggers staging deployment)
2. **Go to Actions → Service Deployment**
3. **Click "Run workflow"**
4. **Select:**
   - Service: `my-new-service` (or `all`)
   - Environment: `production`
5. **Click "Run workflow"**

### Updating Infrastructure

1. **Edit Ansible files:**
   ```bash
   vim infra/roles/docker/tasks/main.yml
   ```

2. **Commit and push:**
   ```bash
   git add infra/
   git commit -m "Update Docker configuration"
   git push
   ```

3. **Workflow automatically runs** against staging

4. **For production:**
   - Go to Actions → Infrastructure Deployment
   - Run workflow with environment: `production`

## 🐛 Troubleshooting

### Service won't start

```bash
# Check container logs
ssh user@server
docker logs <service-name>

# Check container status
docker ps -a | grep <service-name>

# Restart service
cd /opt/docker/<service-name>
docker compose restart  # or docker restart <service-name>
```

### Infrastructure playbook fails

```bash
# Run with verbose output
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml -vvv

# Test connectivity
ansible all -i inventory/hosts.yml -m ping

# Run specific role
ansible-playbook -i inventory/hosts.yml playbook.yml --tags docker
```

### GitHub Actions workflow fails

1. Check workflow logs in Actions tab
2. Verify GitHub Secrets are configured correctly
3. Test SSH connection manually
4. Check server disk space and resources

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Ansible Documentation](https://docs.ansible.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test locally if possible
4. Submit a pull request

## 📝 License

MIT License - feel free to use this template for your projects!

## 🙋 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review workflow logs in GitHub Actions
3. Open an issue in this repository

---

**Happy Deploying! 🚀**
