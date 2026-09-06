import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ConnectorsService } from '../connectors/connectors.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { WorkflowService } from '../workflow/workflow.service';

@Controller('admin/connectors')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('platform-admin')
export class AdminController {
  constructor(
    private readonly connectors: ConnectorsService,
    private readonly workflow: WorkflowService,
  ) {}

  @Get()
  @Roles('officer', 'platform-admin') // read-only for officers too; kill/restore below stay admin-only
  list() {
    return this.connectors.listRegistry();
  }

  @Post(':name/kill')
  async kill(@Param('name') name: string) {
    await this.connectors.setKillSwitch(name, true);
    await this.workflow.killConnector(name);
    return this.connectors.listRegistry();
  }

  @Post(':name/restore')
  async restore(@Param('name') name: string) {
    await this.connectors.setKillSwitch(name, false);
    await this.workflow.restoreConnector(name);
    return this.connectors.listRegistry();
  }
}
