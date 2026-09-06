import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import type { AuthenticatedUser } from './jwt.types';

const client = jwksClient({
  jwksUri: process.env.KEYCLOAK_JWKS_URI ?? 'http://keycloak:8080/realms/onedesk/protocol/openid-connect/certs',
  cache: true,
  cacheMaxAge: 10 * 60 * 1000,
});

// Which registered Keycloak clients are allowed to mint tokens this API accepts —
// checked via the standard OIDC `azp` claim. Without this, any token signed by the
// realm's key is accepted regardless of which client requested it.
const ALLOWED_TOKEN_CLIENTS = (process.env.ALLOWED_TOKEN_CLIENTS ?? 'onedesk-frontend').split(',').map((c) => c.trim());

function getSigningKey(kid: string): Promise<string> {
  return new Promise((resolve, reject) => {
    client.getSigningKey(kid, (err: Error | null, key?: jwksClient.SigningKey) => {
      if (err || !key) return reject(err ?? new Error('signing key not found'));
      resolve(key.getPublicKey());
    });
  });
}

export function verifyToken(token: string): Promise<jwt.JwtPayload> {
  return new Promise((resolve, reject) => {
    // Fail closed: an unset issuer would otherwise make jsonwebtoken silently skip
    // issuer validation entirely, rather than a config error surfacing as a real one.
    if (!process.env.KEYCLOAK_ISSUER) return reject(new Error('KEYCLOAK_ISSUER not configured'));

    const decoded = jwt.decode(token, { complete: true });
    const kid = decoded?.header?.kid;
    if (!decoded || !kid) return reject(new Error('malformed token'));

    getSigningKey(kid)
      .then((publicKey) => {
        jwt.verify(
          token,
          publicKey,
          { algorithms: ['RS256'], issuer: process.env.KEYCLOAK_ISSUER },
          (verifyErr: jwt.VerifyErrors | null, payload?: jwt.JwtPayload | string) => {
            if (verifyErr || !payload || typeof payload === 'string') return reject(verifyErr ?? new Error('invalid token'));
            // `azp` (authorized party) — which Keycloak client requested this token.
            // Rejects a token that's validly signed by the realm but was never meant
            // for a client this API should trust (e.g. minted for a different app
            // registered in the same realm).
            const azp = payload['azp'] as string | undefined;
            if (!azp || !ALLOWED_TOKEN_CLIENTS.includes(azp)) return reject(new Error('token not issued for an allowed client'));
            resolve(payload);
          },
        );
      })
      .catch(reject);
  });
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const authHeader: string | undefined = req.headers['authorization'];
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('missing bearer token');
    }
    const token = authHeader.slice('Bearer '.length);

    let payload: jwt.JwtPayload;
    try {
      payload = await verifyToken(token);
    } catch {
      throw new UnauthorizedException('invalid or expired token');
    }

    const user: AuthenticatedUser = {
      sub: String(payload.sub),
      username: (payload['preferred_username'] as string) ?? String(payload.sub),
      roles: (payload['realm_access'] as { roles?: string[] } | undefined)?.roles ?? [],
      department: (payload['department'] as string | undefined) ?? null,
      masterId: (payload['master_id'] as string | undefined) ?? null,
    };
    req.user = user;
    return true;
  }
}
