import { CanActivate, ExecutionContext, ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import { ROLES_KEY } from './roles.decorator';
import type { AuthenticatedUser } from './jwt.types';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    @Inject(PG_POOL) private readonly pool: Pool,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const req = context.switchToHttp().getRequest();
    const user: AuthenticatedUser | undefined = req.user;
    const allowed = !!user && required.some((r) => user.roles.includes(r));

    if (!allowed) {
      // Server-side RBAC enforcement — closes the gap where role was only a
      // client-side/localStorage value. Every denial is itself audited so the
      // "who tried to access what without permission" question has a real answer.
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
         VALUES ($1, $2, $3, 'READ', $4, 'Denied', 'RBAC: insufficient role')`,
        [
          `aud-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
          user?.username ?? 'unknown',
          user?.department ?? 'Unknown',
          `${req.method} ${req.originalUrl ?? req.url}`,
        ],
      );
      throw new ForbiddenException(`requires one of roles: ${required.join(', ')}`);
    }
    return true;
  }
}
