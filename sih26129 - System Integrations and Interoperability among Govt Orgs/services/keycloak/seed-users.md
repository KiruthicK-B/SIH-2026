# Seed users (realm: onedesk)

Imported automatically from `realm-export.json` on first Keycloak boot (`docker-compose up`).

| Username | Password | Realm role | department claim | master_id claim |
|---|---|---|---|---|
| citizen1 | citizen123 | citizen | — | CIT-10282 |
| officer.municipal | officer123 | officer | Municipal Corporation | — |
| officer.revenue | officer123 | officer | Revenue Department | — |
| admin1 | admin123 | platform-admin | — | — |

Frontend client: `onedesk-frontend` (public, PKCE S256, redirect `http://localhost:5173/*`).
Service client: `core-api` (confidential, secret `core-api-dev-secret`, service-account only — used if core-api itself ever needs to call another protected service; not required for JWT verification, which uses the realm's public JWKS endpoint).

JWT claims consumed by the backend/frontend:
- `realm_access.roles` — one of `citizen` / `officer` / `platform-admin`.
- `department` — officer's home department (matches `Application.department` / `TimelineStep.department` strings used in the frontend, e.g. `"Municipal Corporation"`, `"Revenue Department"`).
- `master_id` — citizen's platform-wide master identity id (matches `masterIdentity.masterId` in the existing frontend mock, e.g. `CIT-10282`).

Keycloak admin console: http://localhost:8080 (admin/admin, see `KEYCLOAK_ADMIN`/`KEYCLOAK_ADMIN_PASSWORD` in `docker-compose.yml`).
