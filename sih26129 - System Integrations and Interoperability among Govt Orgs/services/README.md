# OneDesk backend services (Grand Finale build)

Backs the existing `../onedesk` frontend. See `../HLD.md`, `../ANALYSIS.md`, and the
build plan for the full architecture/phase breakdown.

## Boot everything

```sh
cd services
docker compose up --build
```

- Kong proxy: http://localhost:8010 (routes `/api/*` → core-api, `/mdm/*` → mdm-service)
- Kong admin API: http://localhost:8011
- core-api direct (bypasses gateway, dev convenience): http://localhost:3000
- mdm-service direct: http://localhost:8000
- Keycloak: http://localhost:8080 (admin/admin) — realm `onedesk` auto-imported from
  `keycloak/realm-export.json` on first boot; seed users in `keycloak/seed-users.md`
- Postgres: localhost:5432 (onedesk/onedesk), databases `core_api`, `keycloak`,
  `municipal_adapter` created by `db/init-multiple-dbs.sh`
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (anonymous viewer access, dev-only)

## Verify Phase 0 (infra skeleton)

```sh
curl http://localhost:3000/health          # core-api direct
curl http://localhost:8010/api/health      # core-api through Kong
curl http://localhost:8000/health          # mdm-service direct
curl http://localhost:8010/mdm/health      # mdm-service through Kong
curl http://localhost:8080/realms/onedesk  # Keycloak realm imported
```

All five should return 200. See the build plan's Verification section for the fuller
checklist (auth, orchestration, kill-switch, consent enforcement, RBAC) that applies
once the later phases land.

## Live department portals (Trade & Establishment Clearance)

Three independently-run department systems — own backend protocol, own database
engine, own officer login — that core-api's Trade & Establishment Clearance flow
submits to for real, asynchronous human review. See
[`../LIVE_DEPARTMENT_PORTALS_PLAN.md`](../LIVE_DEPARTMENT_PORTALS_PLAN.md) for the
full design; this is the boot/verify cheat sheet.

```sh
cd services
docker compose -f docker-compose.dept-portals.yml up --build
```

Joins the main stack's network (`onedesk_default`) — boot `docker-compose.yml` first.

| Portal | Protocol · DB | Officer UI | Backend |
|---|---|---|---|
| Business Registry | SOAP/XML · MySQL | http://localhost:5301 | :4301 |
| License Authority | GraphQL · MongoDB | http://localhost:5302 | :4302 |
| Revenue Department | REST/JSON · PostgreSQL | http://localhost:5303 | :4303 |

Each portal's officer login is `admin1` / `admin123` — local to that portal, not
Keycloak, not OneDesk, by design (a real siloed government system wouldn't share
your IdP either), and shared across all three rather than a different account per
portal.

Each officer UI is live — a stats strip, status tabs, and an `EventSource` connection
(`GET /api/events?token=...`, same pattern as core-api's own
`applications-events.controller.ts`) push new/decided cases into the list the moment
core-api submits or an officer somewhere else decides. The header's ● Live / ●
Offline pill reflects the stream's actual connection state.

To see the flow end-to-end: apply for "Trade & Establishment Clearance" as a citizen
in the OneDesk frontend, grant each department's consent request as it comes up on
the application page, then sign in to each portal above (in order — Business
Registry, then License Authority, then Revenue) and Approve the case. Each approval
fires a signed webhook back to core-api (`POST /interop/dept-callback/:department`,
HMAC-verified) that auto-advances the application to the next department.

```sh
curl http://localhost:4301/health   # business-registry-portal
curl http://localhost:4302/health   # license-authority-portal
curl http://localhost:4303/health   # revenue-portal
```

## Frontend wiring

Point `onedesk/.env.local` at the Kong proxy — see `.env.example` in this folder.

`onedesk`'s dev server is pinned to a fixed port (`npm run dev` → `vite --port 5190
--strictPort`) because that exact origin is registered as the Keycloak client's redirect
URI and in Kong's CORS config (`keycloak/realm-export.json`, `gateway/kong.yml`). If
port 5190 is ever changed, update both of those and re-import the realm (drop + recreate
the `keycloak` Postgres database, then `docker compose up -d keycloak` — Keycloak only
imports a realm that doesn't already exist).
