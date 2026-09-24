import cors from 'cors';
import express from 'express';
import { healthRouter } from './routes/health';
import { itemsRouter } from './routes/items';

const app = express();
app.use(cors());
app.use(express.json());
app.use(healthRouter);
app.use(itemsRouter);

const port = process.env.PORT ? Number(process.env.PORT) : 3001;
app.listen(port, () => {
  console.log(`${{values.appName}}-backend listening on :${port}`);
});
