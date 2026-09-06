import { Controller, Get, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { verifyToken } from '../auth/jwt-auth.guard';
import { ApplicationEventsService } from '../events/application-events.service';

// Deliberately outside JwtAuthGuard: the browser's native EventSource API cannot send
// an Authorization header, so the token travels as a query param here instead and is
// verified inline with the same JWT verification used everywhere else.
@Controller('applications')
export class ApplicationsEventsController {
  constructor(private readonly events: ApplicationEventsService) {}

  @Get('events/stream')
  async stream(@Query('token') token: string, @Res() res: Response) {
    let payload: Awaited<ReturnType<typeof verifyToken>>;
    try {
      payload = await verifyToken(token);
    } catch {
      res.status(401).end();
      return;
    }

    // Same scoping rule as GET /applications: citizens only ever see their own
    // application updates, officers/admins see everything — this stream previously
    // broadcast every citizen's updates to any authenticated user, unscoped.
    const roles = (payload['realm_access'] as { roles?: string[] } | undefined)?.roles ?? [];
    const masterId = (payload['master_id'] as string | undefined) ?? null;
    const scopeToCitizen = roles.includes('citizen') ? masterId : null;

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    });
    res.write(': connected\n\n');

    const unsubscribe = this.events.subscribe((app) => {
      if (scopeToCitizen && app.citizenMasterId !== scopeToCitizen) return;
      res.write(`data: ${JSON.stringify(app)}\n\n`);
    });

    const heartbeat = setInterval(() => res.write(': heartbeat\n\n'), 20000);

    res.req.on('close', () => {
      clearInterval(heartbeat);
      unsubscribe();
      res.end();
    });
  }
}
