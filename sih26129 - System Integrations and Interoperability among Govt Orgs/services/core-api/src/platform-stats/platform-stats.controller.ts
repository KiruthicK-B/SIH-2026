import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { registry } from '../metrics/metrics';

// OverviewTab's platform-scale traffic numbers used to be a static frontend array
// (src/data/integrations.ts). They're computed here from the same in-process
// prom-client registry Prometheus itself scrapes at /metrics — real request counts
// and latency from actual traffic on this core-api instance, not illustrative numbers.
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('officer', 'platform-admin')
export class PlatformStatsController {
  constructor(private readonly audit: AuditService) {}

  @Get('traffic-summary')
  async trafficSummary() {
    const metrics = await registry.getMetricsAsJSON();
    const httpTotal = metrics.find((m) => m.name === 'onedesk_http_requests_total');
    const duration = metrics.find((m) => m.name === 'onedesk_http_request_duration_ms');

    let successful = 0;
    let failed = 0;
    for (const v of (httpTotal?.values ?? []) as Array<{ value: number; labels: Record<string, unknown> }>) {
      const status = Number(v.labels.status);
      if (status >= 400) failed += v.value;
      else successful += v.value;
    }

    const durationValues = (duration?.values ?? []) as Array<{ value: number; metricName?: string }>;
    const sum = durationValues.find((v) => v.metricName?.endsWith('_sum'))?.value ?? 0;
    const count = durationValues.find((v) => v.metricName?.endsWith('_count'))?.value ?? 0;

    return {
      apiRequests: successful + failed,
      successful,
      failed,
      avgResponseMs: count > 0 ? Math.round(sum / count) : 0,
    };
  }

  @Get('recent-events')
  async recentEvents() {
    const entries = await this.audit.list({});
    return entries.slice(0, 6).map((e) => ({
      id: e.id,
      timestamp: e.timestamp,
      type: e.action,
      actor: `${e.actor} — ${e.resource}`,
    }));
  }
}
