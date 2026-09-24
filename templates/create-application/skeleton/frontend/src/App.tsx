import { useEffect, useState } from 'react';

// Baked in at build time by CI (see .github/workflows/ci-cd.yaml, VITE_API_URL build arg).
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3001';

interface HealthResponse {
  status: string;
  service: string;
}

export function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch(`${API_URL}/health`)
      .then((res) => res.json())
      .then(setHealth)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <main style={{ fontFamily: 'sans-serif', padding: '2rem' }}>
      <h1>${{values.appName}}</h1>
      <p>Frontend scaffolded by Backstage. Owner: ${{values.owner}} | Team: ${{values.teamName}}</p>
      <h2>Backend status</h2>
      {error && <p style={{ color: 'crimson' }}>Error reaching backend: {error}</p>}
      {health && <pre>{JSON.stringify(health, null, 2)}</pre>}
      {!health && !error && <p>Checking {API_URL}/health...</p>}
    </main>
  );
}
