import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import { healthRouter } from './routes/health';
import { itemsRouter } from './routes/items';

const app = express();
app.use(cors());
app.use(express.json());
app.use(healthRouter);
app.use(itemsRouter);

// Without this, an unhandled DB error in a route crashes the whole process instead of
// returning a 500 — surfacing the real error is far more useful than a silent restart loop.
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err);
  res.status(500).json({ error: err.message });
});

const port = process.env.PORT ? Number(process.env.PORT) : 3001;
app.listen(port, () => {
  console.log(`${{values.appName}}-backend listening on :${port}`);
});
