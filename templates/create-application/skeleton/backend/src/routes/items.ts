import { Router } from 'express';
import { getPool } from '../db';

export const itemsRouter = Router();

itemsRouter.get('/api/items', async (_req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.query('SELECT id, name, created_at FROM items ORDER BY id DESC LIMIT 50');
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

itemsRouter.post('/api/items', async (req, res, next) => {
  try {
    const { name } = req.body ?? {};
    if (typeof name !== 'string' || name.trim().length === 0) {
      res.status(400).json({ error: 'name is required' });
      return;
    }
    const pool = await getPool();
    const result = await pool.query('INSERT INTO items (name) VALUES ($1) RETURNING id, name, created_at', [name]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});
