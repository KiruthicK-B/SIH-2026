import os

import jwt
from fastapi import HTTPException, Request
from jwt import PyJWKClient

# Mirrors core-api's auth/jwt-auth.guard.ts exactly — same JWKS endpoint, same RS256
# allow-list, same fail-closed issuer check. Every service in this system verifies
# Keycloak-issued tokens independently; none trust a caller's say-so.
JWKS_URI = os.environ.get("KEYCLOAK_JWKS_URI", "http://keycloak:8080/realms/onedesk/protocol/openid-connect/certs")
ISSUER = os.environ.get("KEYCLOAK_ISSUER")

_jwk_client = PyJWKClient(JWKS_URI, cache_keys=True)


def require_auth(request: Request) -> dict:
    if not ISSUER:
        raise HTTPException(status_code=500, detail="KEYCLOAK_ISSUER not configured")

    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    token = auth_header[len("Bearer ") :]

    try:
        signing_key = _jwk_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=ISSUER,
            options={"verify_aud": False},  # matches core-api's guard — no audience check, aud isn't client-specific here
        )
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="invalid or expired token")

    return payload
