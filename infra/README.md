# Infrastructure Directory

This directory contains Ansible configuration for provisioning and managing Docker host infrastructure.

## Structure

```
infra/
├── ansible.cfg           # Ansible configuration
├── playbook.yml          # Main playbook
├── inventory/            # Server inventory
│   └── hosts.yml         # Host definitions
└── roles/                # Ansible roles
    ├── common/           # Base system setup
    ├── docker/           # Docker installation
    ├── security/         # Security hardening
    └── monitoring/       # Monitoring tools
```

## Roles

### Common
- Installs essential packages (curl, wget, git, vim, htop)
- Sets timezone to UTC
- Creates deploy user with sudo access
- Configures SSH keys

### Docker
- Installs Docker CE and Docker Compose
- Configures Docker daemon
- Creates Docker networks
- Sets up log rotation
- Adds users to docker group

### Security
- Configures UFW firewall
- Installs fail2ban
- Disables root login
- Disables password authentication
- Hardens SSH configuration

### Monitoring
- Installs prometheus-node-exporter
- Installs ctop for container monitoring
- Sets up basic monitoring infrastructure

## Usage

### Prerequisites

1. **Install Ansible:**
   ```bash
   pip install ansible
   ```

2. **Configure inventory:**
   Edit [`inventory/hosts.yml`](inventory/hosts.yml) with your server details

3. **Set environment variables:**
   ```bash
   export PROD_SERVER_IP="your-prod-ip"
   export STAGING_SERVER_IP="your-staging-ip"
   export DEPLOY_USER="deploy"
   export SSH_KEY_PATH="~/.ssh/id_rsa"
   ```

### Running Playbooks

**Deploy to staging:**
```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --limit staging
```

**Deploy to production:**
```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --limit production
```

**Run specific role:**
```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --tags docker
```

**Dry run (check mode):**
```bash
ansible-playbook -i inventory/hosts.yml playbook.yml --check
```

**Verbose output:**
```bash
ansible-playbook -i inventory/hosts.yml playbook.yml -vvv
```

## Configuration

### Inventory Variables

The inventory file supports environment variables:

```yaml
ansible_host: "{{ lookup('env', 'PROD_SERVER_IP') }}"
ansible_user: "{{ lookup('env', 'DEPLOY_USER') }}"
ansible_ssh_private_key_file: "{{ lookup('env', 'SSH_KEY_PATH') }}"
```

### Custom Variables

Add custom variables to role defaults or vars:

```yaml
# roles/docker/defaults/main.yml
docker_version: "24.0"
deploy_user: "deploy"
```

## Testing

### Test Connectivity

```bash
ansible all -i inventory/hosts.yml -m ping
```

### Check Server Facts

```bash
ansible all -i inventory/hosts.yml -m setup
```

### List Hosts

```bash
ansible all -i inventory/hosts.yml --list-hosts
```

## Adding New Roles

1. Create role structure:
   ```bash
   mkdir -p roles/myrole/{tasks,handlers,templates,files,vars,defaults}
   ```

2. Create main task file:
   ```bash
   touch roles/myrole/tasks/main.yml
   ```

3. Add role to playbook:
   ```yaml
   roles:
     - common
     - docker
     - myrole
   ```

## Security Considerations

1. **SSH Keys**: Never commit private keys
2. **Passwords**: Use Ansible Vault for sensitive data
3. **Firewall**: Roles configure UFW by default
4. **Updates**: Regularly update roles for security patches

## Troubleshooting

### Connection Issues

```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa user@server

# Check SSH config
ansible-playbook -i inventory/hosts.yml playbook.yml -vvv
```

### Permission Errors

```bash
# Ensure deploy user has sudo rights
ansible all -i inventory/hosts.yml -m shell -a "sudo whoami"
```

### Role Failures

```bash
# Run specific role with verbose output
ansible-playbook -i inventory/hosts.yml playbook.yml --tags docker -vvv
```

## CI/CD Integration

This infrastructure code is automatically deployed via GitHub Actions when changes are pushed to the `infra/` directory. See [`.github/workflows/infrastructure.yml`](../.github/workflows/infrastructure.yml).

## Best Practices

1. **Idempotency**: Ensure tasks can run multiple times safely
2. **Testing**: Test on staging before production
3. **Documentation**: Document role variables and requirements
4. **Version Control**: Tag stable infrastructure versions
5. **Secrets**: Use Ansible Vault or environment variables

## Useful Commands

```bash
# List all tags
ansible-playbook -i inventory/hosts.yml playbook.yml --list-tags

# List all tasks
ansible-playbook -i inventory/hosts.yml playbook.yml --list-tasks

# Syntax check
ansible-playbook -i inventory/hosts.yml playbook.yml --syntax-check

# Get facts for specific group
ansible production -i inventory/hosts.yml -m setup
```
