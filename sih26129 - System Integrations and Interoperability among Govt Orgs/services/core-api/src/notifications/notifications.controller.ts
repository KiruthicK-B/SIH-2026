import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  private scope(user: AuthenticatedUser) {
    return user.roles.includes('citizen') ? (user.masterId ?? undefined) : undefined;
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(this.scope(user));
  }

  @Post(':id/read')
  markRead(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.service.markRead(id, this.scope(user));
  }

  @Post('read-all')
  markAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.service.markAllRead(this.scope(user));
  }
}
