// ── TokenScope — DEV (rg-tokenscope-dev) ─────────────────────────────────
// Private posture: VNet, private endpoints on Key Vault / Postgres / Redis /
// ACR, internal-only Container Apps ingress. Non-secret settings and every
// secret come from the GitHub environment `dev` (see .github/workflows/).

using '../main.bicep'

param env = 'dev'
param projectName = 'tokenscope'
param imageTag = 'latest'
param deployRbac = true

param tags = {
  project: 'tokenscope'
  organisation: readEnvironmentVariable('ORG_NAME', 'insight')
  environment: 'dev'
  managedBy: 'github-actions'
}

// ── Secrets ──────────────────────────────────────────────────────────────
param pgAdminLogin = readEnvironmentVariable('PG_ADMIN_LOGIN')
param pgAdminPassword = readEnvironmentVariable('PG_ADMIN_PASSWORD')
param sessionSecret = readEnvironmentVariable('SESSION_SECRET')
param hmacSessionKey = readEnvironmentVariable('HMAC_SESSION_KEY')
param internalWorkerHmacKey = readEnvironmentVariable('INTERNAL_WORKER_HMAC_KEY')
param oidcSessionSecret = readEnvironmentVariable('OIDC_SESSION_SECRET')
param oidcAuthSessionSecret = readEnvironmentVariable('OIDC_AUTH_SESSION_SECRET')
param oidcTokenKey = readEnvironmentVariable('OIDC_TOKEN_KEY')
param entraIdClientSecret = readEnvironmentVariable('ENTRA_CLIENT_SECRET', '')
param anthropicApiKey = readEnvironmentVariable('ANTHROPIC_API_KEY', '')
param opsAlertNtfyUrl = readEnvironmentVariable('OPS_ALERT_NTFY_URL', '')

// ── Sign-in / public entry point (empty until a WAF / Front Door fronts the app) ─
param appPublicOrigin = readEnvironmentVariable('APP_PUBLIC_ORIGIN', '')
param entraIdTenantId = readEnvironmentVariable('ENTRA_TENANT_ID', '')
param entraIdClientId = readEnvironmentVariable('ENTRA_CLIENT_ID', '')
param entraIdRedirectUri = readEnvironmentVariable('ENTRA_REDIRECT_URI', '')
param bootstrapAdminEmail = readEnvironmentVariable('BOOTSTRAP_ADMIN_EMAIL', '')
param allowPersonaOverride = false
param alertNotificationEmail = readEnvironmentVariable('ALERT_NOTIFICATION_EMAIL', '')

// Empty = no scheduled worker jobs. Set to https://<containerAppUrl> once the app is up.
param workerBaseUrl = readEnvironmentVariable('WORKER_BASE_URL', '')

// ── Networking (private) ─────────────────────────────────────────────────
param enablePrivateNetworking = true
param vnetAddressSpace = '10.10.0.0/24'
param containerAppsSubnetPrefix = '10.10.0.0/27'
param privateEndpointsSubnetPrefix = '10.10.0.32/28'
param amplsSubnetPrefix = ''
param buildSubnetPrefix = ''
param registerDnsZoneGroups = true
param monitorQueryPrivateOnly = false

param enableFrontDoor = false
param keyVaultCreateMode = 'default'
