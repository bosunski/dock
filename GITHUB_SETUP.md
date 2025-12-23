# GitHub Actions Setup

This repository uses GitHub Secrets and Variables to securely manage server configuration and SSH keys.

## Required GitHub Secrets

Go to your repository on GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

### 1. DEPLOY_SSH_PRIVATE_KEY
Your SSH private key for accessing servers.

```bash
# Get your private key content:
cat ~/.ssh/id_ed25519

# Copy the entire output including:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ... key content ...
# -----END OPENSSH PRIVATE KEY-----
```

### 2. DEPLOY_SSH_PUBLIC_KEY
Your SSH public key (optional, used for initial server setup).

```bash
cat ~/.ssh/id_ed25519.pub
```

## Required GitHub Variables

Go to your repository on GitHub → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**

### 1. SERVERS_CONFIG
Name: `SERVERS_CONFIG`

Value: Copy the **entire contents** of your `servers.yml` file:

```yaml
# Server Configuration
# Define all servers here with their IPs and metadata

servers:
  # Production server
  prod-web-1:
    ip: 172.199.8.54
    environment: production
    roles:
      - web
      - api
    ssh_user: azureuser
    tags:
      - frontend
      - backend

  prod-web-2:
    ip: 10.0.1.11
    environment: production
    roles:
      - web
      - api
    ssh_user: deploy
    tags:
      - frontend
      - backend

  prod-db-1:
    ip: 10.0.1.20
    environment: production
    roles:
      - database
    ssh_user: deploy
    tags:
      - database

# Environment groups for easy targeting
environments:
  production:
    - prod-web-1
    - prod-web-2
    - prod-db-1
  staging:
    - staging-web-1
    - staging-db-1

# Role-based groups for service targeting
role_groups:
  web:
    - prod-web-1
    - prod-web-2
  database:
    - prod-db-1
  all:
    - prod-web-1
    - prod-web-2
    - prod-db-1
```

⚠️ **Important**: Copy your actual `servers.yml` content, including any customizations you've made.

## Security Notes

- `servers.yml` is gitignored to keep server IPs private
- Use `servers.yml.example` as a template for new deployments
- The workflows reconstruct `servers.yml` from the `SERVERS_CONFIG` variable during runtime
- SSH keys are stored as secrets and never exposed in logs

## Verification

After adding the secrets and variables:

1. Go to **Actions** tab
2. Select **Infrastructure Deployment** workflow
3. Click **Run workflow**
4. Select environment and run

If successful, your infrastructure will be deployed to the configured servers.
