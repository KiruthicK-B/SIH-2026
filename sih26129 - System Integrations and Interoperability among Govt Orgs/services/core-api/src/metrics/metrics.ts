import * as client from 'prom-client';

// Q&A insurance, not a demo centerpiece (see build plan) — real Prometheus metrics,
// kept minimal: default Node process metrics + two counters that mean something for
// this platform specifically (HTTP traffic, connector call outcomes).
client.collectDefaultMetrics();

export const registry = client.register;

export const httpRequestsTotal = new client.Counter({
  name: 'onedesk_http_requests_total',
  help: 'Total HTTP requests handled by core-api',
  labelNames: ['method', 'route', 'status'] as const,
});

export const connectorCallsTotal = new client.Counter({
  name: 'onedesk_connector_calls_total',
  help: 'Total outbound calls to department connectors',
  labelNames: ['department', 'outcome'] as const,
});

export const httpRequestDurationMs = new client.Histogram({
  name: 'onedesk_http_request_duration_ms',
  help: 'HTTP request duration in milliseconds',
  buckets: [10, 25, 50, 100, 250, 500, 1000, 2500],
});
