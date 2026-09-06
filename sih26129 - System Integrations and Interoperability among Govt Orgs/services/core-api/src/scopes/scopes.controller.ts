import { BadRequestException, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { ScopesService } from './scopes.service';

@Controller('identity/scopes')
@UseGuards(JwtAuthGuard)
export class ScopesController {
  constructor(private readonly scopes: ScopesService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    if (!user.masterId) throw new BadRequestException('only citizens have data-sharing scopes');
    return this.scopes.listGrants(user.masterId);
  }

  @Post(':key/grant')
  grant(@Param('key') key: string, @CurrentUser() user: AuthenticatedUser) {
    if (!user.masterId) throw new BadRequestException('only citizens have data-sharing scopes');
    return this.scopes.grantScope(user.masterId, key);
  }

  @Post(':key/revoke')
  revoke(@Param('key') key: string, @CurrentUser() user: AuthenticatedUser) {
    if (!user.masterId) throw new BadRequestException('only citizens have data-sharing scopes');
    return this.scopes.revokeScope(user.masterId, key);
  }
}
