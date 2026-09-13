const express = require('express');
const cors = require('cors');
const routes = require('./routes');

function createApp() {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '5mb' }));

  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.use('/api/v1', routes);

  app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: err.message ?? 'Internal server error' });
  });

  return app;
}

module.exports = { createApp };
