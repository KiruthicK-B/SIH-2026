import { Pool } from 'pg';
import { NestFactory } from '@nestjs/core';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';
import { runMigrations } from './db/migrate';
import { httpRequestDurationMs, httpRequestsTotal } from './metrics/metrics';
import { WorkflowService } from './workflow/workflow.service';

async function bootstrap() {
  const migrationPool = new Pool({ connectionString: process.env.DATABASE_URL });
  await runMigrations(migrationPool);

  const app = await NestFactory.create(AppModule);
  // Explicit origin, not enableCors()'s wildcard default — matches Kong's own cors
  // plugin (services/gateway/kong.yml), which is the intended single entry point.
  app.enableCors({ origin: process.env.FRONTEND_ORIGIN ?? 'http://localhost:5190', credentials: true });
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = process.hrtime.bigint();
    res.on('finish', () => {
      httpRequestsTotal.inc({ method: req.method, route: req.baseUrl || req.path, status: String(res.statusCode) });
      httpRequestDurationMs.observe(Number(process.hrtime.bigint() - start) / 1_000_000);
    });
    next();
  });
  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port, '0.0.0.0');

  // Resume any flagship application whose active step isn't the officer-gated
  // Municipal Review — covers the seeded demo application (BL-2026-00128), which
  // was inserted directly by SQL rather than through the submit endpoint, so it
  // never went through runAutoAdvance. Safe to re-run on every hot-reload: once a
  // step reaches Municipal Review (or the flow completes) this becomes a no-op.
  const { rows: resumable } = await migrationPool.query(`
    SELECT DISTINCT a.id FROM applications a
    JOIN timeline_steps t ON t.application_id = a.id
    WHERE a.flagship = true AND t.status = 'active' AND t.department != 'Municipal Corporation'
  `);
  const workflow = app.get(WorkflowService);
  for (const row of resumable) {
    void workflow.runAutoAdvance(row.id);
  }
  await migrationPool.end();
}

bootstrap();
