// The lightweight demo architecture passes DATABASE_URL straight in as a Container App secret
// env var (see terraform-modules/container-apps) — no Key Vault round-trip needed. Swap this for
// a Key Vault-backed lookup if you move to the production module composition documented in
// terraform-modules/README.md.
export function loadDatabaseUrl(): string {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error('Set DATABASE_URL before starting.');
  }
  return url;
}
