# 1Password Secret Management

This repository uses 1Password to manage secrets for services.

## Setup

### 1. Create Service Account in 1Password

1. Go to 1Password → Settings → Developer → Service Accounts
2. Create a service account named "GitHub Dock Deployment"
3. Grant access to vault: `Dock` (or your chosen vault name)
4. Copy the service account token

### 2. Add to GitHub Secrets

1. Go to your GitHub repo → Settings → Secrets and variables → Actions
2. Add secret: `OP_SERVICE_ACCOUNT_TOKEN` with the token from step 1

### 3. Organize Secrets in 1Password

Create items in 1Password following this structure:

**Vault Structure:**
- Single vault: `Dock` (recommended) or your custom name
- Items named: `{service}-{environment}` (e.g., `fizzy-production`, `api-staging`)

**Item Naming Convention:**
- `{service-name}-{environment}` format
- Examples: `fizzy-production`, `fizzy-staging`, `api-production`, `database-staging`

**Example: `fizzy-production` item in Dock vault:**
```
Item Type: Login or Secure Note
Fields:
  - SECRET_KEY_BASE (concealed)
  - VAPID_PRIVATE_KEY (concealed)
  - VAPID_PUBLIC_KEY (text)
  - MAILER_FROM_ADDRESS (text)
  - SMTP_ADDRESS (text)
  - SMTP_USERNAME (text)
  - SMTP_PASSWORD (concealed)
```

### 4. Field Types

- **concealed/password** - for actual secrets (encrypted, hidden)
- **text** - for non-secret configuration values

## How It Works

1. **During Deployment:**
   - Workflow installs 1Password CLI
   - Runs `scripts/inject-secrets.sh <service> <environment>`
   - Fetches secrets from 1Password item `{service}-{environment}` in `Dock` vault
   - Generates `.env` file with all fields
   - Deploys service with `.env` file

2. **Service Configuration:**
   - Each service's `docker-compose.yml` uses `env_file: - .env`
   - `.env` files are gitignored
   - Use `.env.example` as template (commit this)

## Adding Secrets for a New Service

1. Create `.env.example` in `services/{service}/`
2. Update `docker-compose.yml` to use `env_file: - .env`
3. Create `{service}-production` and `{service}-staging` items in 1Password
4. Add fields matching `.env.example`
5. Deploy - secrets automatically injected!

## Example: Complete Setup

**In 1Password (Dock vault):**
```
├─ fizzy-production
│   ├─ SECRET_KEY_BASE: abc123...
│   ├─ SMTP_PASSWORD: pass123
│   └─ ...
├─ fizzy-staging
│   ├─ SECRET_KEY_BASE: xyz789...  (different!)
│   ├─ SMTP_PASSWORD: testpass
│   └─ ...
├─ api-production
│   └─ DATABASE_URL: postgres://...
└─ api-staging
    └─ DATABASE_URL: postgres://test...
```

**Result:**
- Deploying fizzy to production → uses `fizzy-production` secrets
- Deploying fizzy to staging → uses `fizzy-staging` secrets
- Each environment has isolated secrets

## Local Development

For local testing:

```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in
op signin

# Generate .env for local testing
bash scripts/inject-secrets.sh fizzy production services/fizzy/.env

# Or specify custom vault
bash scripts/inject-secrets.sh fizzy production services/fizzy/.env "MyVault"

# Run service
cd services/fizzy && docker compose up
```

## Rotating Secrets

1. Update secret value in 1Password
2. Redeploy the service - new value automatically used
3. No code changes needed!

## Security Notes

- ✅ Secrets never committed to git
- ✅ Secrets only exist in 1Password and on servers at runtime
- ✅ Service account token stored in GitHub Secrets
- ✅ Automatic secret rotation on deployment
- ✅ Audit trail in 1Password
- ✅ Access control via 1Password vaults
- ✅ Per-environment isolation (production ≠ staging secrets)

## Troubleshooting

**"Item not found" error:**
- Check item name matches `{service}-{environment}` (e.g., `fizzy-production`)
- Verify vault name is correct (default: `Dock`)
- Ensure service account has vault access

**Empty .env generated:**
- Check field labels in 1Password match `.env.example`
- Verify service account has read access
- Check 1Password CLI logs in GitHub Actions

**Using a different vault name:**
- Default vault is `Dock`
- To use different vault, modify `VAULT` variable in script
- Or pass as 4th argument: `inject-secrets.sh service env output VaultName`
