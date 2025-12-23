# 1Password Secret Management

This repository uses 1Password to manage secrets for services.

## Setup

### 1. Create Service Account in 1Password

1. Go to 1Password → Settings → Developer → Service Accounts
2. Create a service account named "GitHub Dock Deployment"
3. Grant access to vault: `egberinde` (or your chosen vault name)
4. Copy the service account token

### 2. Add to GitHub Secrets

1. Go to your GitHub repo → Settings → Secrets and variables → Actions
2. Add secret: `OP_SERVICE_ACCOUNT_TOKEN` with the token from step 1

### 3. Organize Secrets in 1Password

Create items in 1Password following this structure:

**Vault Structure:**
- Single vault: `egberinde` (recommended) or your custom name
- Items named: `{service}-{environment}` (e.g., `fizzy-production`, `api-staging`)

**Item Naming Convention:**
- `{service-name}-{environment}` format
- Examples: `fizzy-production`, `fizzy-staging`, `api-production`, `database-staging`

**Example: `fizzy-production` item in egberinde vault:**
```
Item Type: Login or Secure Note
Files/Documents:
  - dotenv (file containing your .env content)
```

**The `dotenv` document should contain your environment variables:**
```env
SECRET_KEY_BASE=abc123...
VAPID_PRIVATE_KEY=xyz789...
VAPID_PUBLIC_KEY=def456...
MAILER_FROM_ADDRESS=noreply@example.com
SMTP_ADDRESS=smtp.example.com
SMTP_USERNAME=user@example.com
SMTP_PASSWORD=password123
```

## How It Works

1. **During Deployment:**
   - Workflow checks if service requires secrets (via `secrets.required` in deploy.yml)
   - If required: installs 1Password CLI and fetches the `dotenv` document from `{service}/{environment}.env` reference
   - Writes content directly to `.env` file
   - Deploys service with `.env` file

2. **Service Configuration:**
   - Add `secrets.required: true` in service's `deploy.yml` if it needs secrets
   - Each service's `docker-compose.yml` uses `env_file: - .env`
   - `.env` files are gitignored
   - Use `.env.example` as template (commit this)

## Adding Secrets for a New Service

1. **In `services/{service}/deploy.yml`**, add:
   ```yaml
   secrets:
     required: true  # Only if service needs secrets
   ```

2. Create `.env.example` in `services/{service}/` documenting required variables

3. Update `docker-compose.yml` to use `env_file: - .env`

4. In 1Password, create item `{service}-{environment}` (e.g., `fizzy-production`)

5. Upload your `.env` content as a document named `dotenv` or `{environment}.env`

6. Deploy - secrets automatically injected!

**Note:** Services without `secrets.required: true` will skip secret loading and won't fail if no 1Password item exists.

## Example: Complete Setup

**In 1Password (egberinde vault):**
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
