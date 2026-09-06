import { Body, Controller, ForbiddenException, Get, Inject, Param, Post, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';
import { WorkflowService } from '../workflow/workflow.service';
import { ApplicationsService } from './applications.service';
import type { NewApplicationInput } from './applications.types';

@Controller('applications')
@UseGuards(JwtAuthGuard)
export class ApplicationsController {
  constructor(
    private readonly service: ApplicationsService,
    private readonly workflow: WorkflowService,
    @Inject(PG_POOL) private readonly pool: Pool,
  ) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    // Citizens see only their own applications; officers/admins see everything
    // (department-scoping for officers lands in Phase 3's OfficerDashboard).
    const scopeToCitizen = user.roles.includes('citizen') ? user.masterId ?? undefined : undefined;
    return this.service.listApplications(scopeToCitizen);
  }

  @Get('assigned')
  @UseGuards(RolesGuard)
  @Roles('officer', 'platform-admin')
  assigned(@CurrentUser() user: AuthenticatedUser) {
    const department = user.roles.includes('officer') ? (user.department ?? null) : null;
    return this.service.listAssigned(department);
  }

  @Get(':id')
  get(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    const scopeToCitizen = user.roles.includes('citizen') ? user.masterId ?? undefined : undefined;
    return this.service.getApplication(id, scopeToCitizen);
  }

  @Post()
  async submit(@Body() body: NewApplicationInput, @CurrentUser() user: AuthenticatedUser) {
    const created = await this.service.submitApplication({ ...body, citizenMasterId: user.masterId ?? undefined }, user.username);
    if (created.flagship) {
      // Fire-and-forget: drives the timeline forward automatically via connector
      // calls, pushing SSE updates as it goes — the citizen doesn't need to click
      // "advance" for each department the way Phase 1's shim required.
      void this.workflow.runAutoAdvance(created.id);
    }
    return created;
  }

  @Post(':id/advance')
  @UseGuards(RolesGuard)
  @Roles('officer', 'platform-admin')
  advance(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.service.advanceApplication(id, user.username);
  }

  @Post(':id/retry')
  @UseGuards(RolesGuard)
  @Roles('officer', 'platform-admin')
  async retry(@Param('id') id: string) {
    void this.workflow.retryBlockedStep(id);
    return { retried: true };
  }

  @Post(':id/municipal-review/approve')
  @UseGuards(RolesGuard)
  @Roles('officer', 'platform-admin')
  async approveMunicipalReview(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    // Officers may only act on their own department's queue; platform-admin can
    // act on any (demo/operational override) — mirrors the OfficerDashboard scoping.
    if (user.roles.includes('officer') && user.department !== 'Municipal Corporation') {
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
         VALUES ($1, $2, $3, 'APPROVE', $4, 'Denied', 'Officer department does not match Municipal Corporation')`,
        [`aud-${Date.now()}`, user.username, user.department ?? 'Unknown', `${id}: Municipal Review`],
      );
      throw new ForbiddenException('this application is not assigned to your department');
    }
    return this.workflow.approveMunicipalReview(id, user.username);
  }
}
