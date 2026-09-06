import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { AuditService } from './audit.service';

// Server-side mirror of the frontend's RequirePlatformAccess gate — previously that
// gate was client-side only (role read from localStorage), so anyone could hit this
// data by editing localStorage. Now the JWT role claim is checked here too.
@Controller('audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('officer', 'platform-admin')
export class AuditController {
  constructor(private readonly service: AuditService) {}

  @Get()
  list(
    @Query('department') department?: string,
    @Query('action') action?: string,
    @Query('result') result?: string,
    @Query('date') date?: string,
  ) {
    return this.service.list({ department, action, result, date });
  }

  @Get('departments')
  departments() {
    return this.service.listDistinct('department');
  }

  @Get('actions')
  actions() {
    return this.service.listDistinct('action');
  }
}
