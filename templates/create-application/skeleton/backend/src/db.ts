import { Pool } from 'pg';
import { loadDatabaseUrl } from './config';

let pool: Pool | undefined;

export async function getPool(): Promise<Pool> {
  if (!pool) {
    const connectionString = await loadDatabaseUrl();
    pool = new Pool({ connectionString, ssl: { rejectUnauthorized: true } });
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
