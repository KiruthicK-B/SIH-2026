import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { ConsentsService } from './consents.service';

@Controller('consents')
@UseGuards(JwtAuthGuard)
export class ConsentsController {
  constructor(private readonly service: ConsentsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    const scope = user.roles.includes('citizen') ? user.masterId ?? undefined : undefined;
    return this.service.listConsents(scope);
  }

  @Get('pending')
  pending(@CurrentUser() user: AuthenticatedUser) {
    const scope = user.roles.includes('citizen') ? user.masterId ?? undefined : undefined;
    return this.service.listPendingRequests(scope);
  }

  private scope(user: AuthenticatedUser) {
    return user.roles.includes('citizen') ? user.masterId ?? undefined : undefined;
  }

  @Post('pending/:id/allow')
  allow(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.service.allowRequest(id, user.username, this.scope(user));
  }

  @Post('pending/:id/deny')
  deny(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.service.denyRequest(id, this.scope(user));
  }

  @Post(':id/revoke')
  revoke(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.service.revokeConsent(id, user.username, this.scope(user));
  }
}
