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

## Frontend wiring

Point `onedesk/.env.local` at the Kong proxy — see `.env.example` in this folder.

`onedesk`'s dev server is pinned to a fixed port (`npm run dev` → `vite --port 5190
--strictPort`) because that exact origin is registered as the Keycloak client's redirect
URI and in Kong's CORS config (`keycloak/realm-export.json`, `gateway/kong.yml`). If
port 5190 is ever changed, update both of those and re-import the realm (drop + recreate
the `keycloak` Postgres database, then `docker compose up -d keycloak` — Keycloak only
imports a realm that doesn't already exist).
