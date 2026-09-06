require('dotenv').config();
const { createApp } = require('./src/app');
const { ensureTables, waitForPostgres, pool } = require('./src/db');

const PORT = Number(process.env.PORT) || 8080;

async function startServer() {
  await waitForPostgres();
  await ensureTables();
  const app = createApp();
  const server = await new Promise((resolve) => {
    const s = app.listen(PORT, () => resolve(s));
  });
  console.log(`AGRIVA backend listening on http://localhost:${PORT}`);
  return { app, server, pool };
}

module.exports = { startServer };

if (require.main === module) {
  startServer().catch((err) => {
    console.error('Failed to start server:', err);
    process.exit(1);
  });
}
