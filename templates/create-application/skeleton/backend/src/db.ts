import { Pool } from 'pg';
import { loadDatabaseUrl } from './config';

let pool: Pool | undefined;

export async function getPool(): Promise<Pool> {
  if (!pool) {
    const connectionString = loadDatabaseUrl();
    // The lightweight demo Postgres (a plain container, not Flexible Server) doesn't terminate
    // TLS, so `sslmode=disable` is expected here — set `ssl: { rejectUnauthorized: true }` if you
    // move to the production PostgreSQL Flexible Server module.
    pool = new Pool({ connectionString });
    await pool.query(`
      CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
  }
  return pool;
}
