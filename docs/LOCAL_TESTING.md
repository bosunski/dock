# Local Testing Guide

This guide explains how to test your Ansible infrastructure changes locally before deploying to real servers.

## Quick Start

The easiest way to test:

```bash
chmod +x scripts/test-local.sh
./scripts/test-local.sh
```

This automatically:
1. Starts a Docker container that simulates a remote server
2. Configures SSH access
3. Runs your Ansible playbooks
4. Shows you what would happen on production

## Option 1: Docker-based Testing (Recommended)

### Start Test Server

```bash
docker-compose -f docker-compose.test.yml up -d
```

This creates a container with:
- SSH server on port 2222
- Deploy user with sudo access
- All ports exposed for testing services

### Wait for SSH

```bash
# Give it a few seconds to start
sleep 10

# Test connectivity
ssh -p 2222 -o StrictHostKeyChecking=no deploy@localhost
# Password: deploy
```

### Run Ansible

```bash
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local -v
```

The `local` group in inventory points to `127.0.0.1:2222`.

### Test Services

After Ansible completes, you can deploy services to the test server:

```bash
# Copy service files
scp -P 2222 -r services/api deploy@localhost:/opt/docker/api/

# SSH and deploy
ssh -p 2222 deploy@localhost
cd /opt/docker/api
docker build -t my-api .
docker run -d --name api -p 3000:3000 my-api
```

Access at: `http://localhost:3000`

### Clean Up

```bash
# Stop and remove test server
docker-compose -f docker-compose.test.yml down

# Remove volumes too
docker-compose -f docker-compose.test.yml down -v
```

## Option 2: Vagrant-based Testing

Vagrant provides a full VM for more realistic testing.

### Prerequisites

```bash
# Install VirtualBox
brew install virtualbox

# Install Vagrant
brew install vagrant
```

### Start VM

```bash
vagrant up
```

This creates an Ubuntu 22.04 VM with:
- 2GB RAM, 2 CPUs
- Port forwarding: 80→8080, 443→8443, 22→2222
- Synced folder for easy file access

### Run Ansible

```bash
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local
```

### SSH to VM

```bash
vagrant ssh

# Or use standard SSH
ssh -p 2222 vagrant@localhost
# Password: vagrant
```

### Test Your Services

```bash
# On your host machine
scp -P 2222 -r services/api vagrant@localhost:/opt/docker/api/

# SSH to VM
vagrant ssh
cd /opt/docker/api
docker build -t my-api .
docker run -d --name api -p 3000:3000 my-api

# Access from host
curl http://localhost:8080  # Forwarded to VM port 80
```

### Clean Up

```bash
# Stop VM
vagrant halt

# Destroy VM (frees disk space)
vagrant destroy
```

## Testing Workflow

1. **Make changes** to Ansible roles or playbooks
2. **Run local test**: `./scripts/test-local.sh`
3. **Verify output** and check for errors
4. **Iterate** until working correctly
5. **Commit and push** to deploy to staging
6. **Test on staging** before production

## Common Testing Scenarios

### Test Docker Installation

```bash
ssh -p 2222 deploy@localhost "docker --version"
ssh -p 2222 deploy@localhost "docker compose version"
```

### Test Service Deployment

```bash
# Copy and deploy nginx
scp -P 2222 -r services/nginx/* deploy@localhost:/opt/docker/nginx/
ssh -p 2222 deploy@localhost "cd /opt/docker/nginx && docker compose up -d"

# Check it's running
curl http://localhost:8080/health
```

### Test Security Configuration

```bash
# Check firewall
ssh -p 2222 deploy@localhost "sudo ufw status"

# Check fail2ban
ssh -p 2222 deploy@localhost "sudo fail2ban-client status"

# Check SSH config
ssh -p 2222 deploy@localhost "sudo grep PermitRootLogin /etc/ssh/sshd_config"
```

### Test Monitoring

```bash
# Check node exporter
curl http://localhost:9100/metrics

# Check Docker stats with ctop
ssh -p 2222 deploy@localhost "sudo ctop"
```

## Troubleshooting

### Can't connect to SSH

```bash
# Check if container is running
docker ps | grep dock-test-server

# Check logs
docker-compose -f docker-compose.test.yml logs

# Restart container
docker-compose -f docker-compose.test.yml restart
```

### Ansible connection fails

```bash
# Test SSH connection manually
ssh -p 2222 -o StrictHostKeyChecking=no deploy@localhost

# Check inventory
cat infra/inventory/hosts.yml | grep -A5 local-test

# Run with maximum verbosity
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local -vvvv
```

### Port already in use

```bash
# Check what's using the port
lsof -i :2222

# Use different port in docker-compose.test.yml
# Change "2222:22" to "2223:22"
```

## CI/CD Integration

You can add local testing to your CI pipeline:

```yaml
# .github/workflows/test.yml
name: Test Infrastructure

on: [pull_request]

jobs:
  test-ansible:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start test server
        run: docker-compose -f docker-compose.test.yml up -d
      
      - name: Wait for SSH
        run: sleep 10
      
      - name: Run Ansible
        run: |
          pip install ansible
          cd infra
          ansible-playbook -i inventory/hosts.yml playbook.yml --limit local -v
      
      - name: Cleanup
        if: always()
        run: docker-compose -f docker-compose.test.yml down
```

## Best Practices

1. **Always test locally first** before deploying to real servers
2. **Test incrementally** - run after each role/task change
3. **Check logs** - use `-v`, `-vv`, or `-vvv` for verbose output
4. **Clean state** - destroy and recreate test environment between major changes
5. **Match production** - keep test environment similar to real servers
6. **Document changes** - note what worked and what didn't

## Next Steps

After successful local testing:

1. Commit your changes
2. Push to trigger staging deployment
3. Verify on staging environment
4. Deploy to production with confidence
