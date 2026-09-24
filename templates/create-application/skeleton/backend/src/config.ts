import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';

// Container App is granted "Key Vault Secrets User" via its user-assigned managed identity
// (see terraform-modules/keyvault + container-apps). Locally, DefaultAzureCredential falls back
// to `az login` / env vars, and DATABASE_URL can be set directly to skip Key Vault entirely.
export async function loadDatabaseUrl(): Promise<string> {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const vaultUrl = process.env.KEY_VAULT_URL;
  if (!vaultUrl) {
    throw new Error('Set DATABASE_URL (local dev) or KEY_VAULT_URL (deployed) before starting.');
  }

  const credential = new DefaultAzureCredential();
  const client = new SecretClient(vaultUrl, credential);
  const secret = await client.getSecret('db-connection-string');
  if (!secret.value) {
    throw new Error('Secret "db-connection-string" has no value in Key Vault.');
  }
  return secret.value;
}
