import { Module } from '@nestjs/common';
import { ConnectorsModule } from '../connectors/connectors.module';
import { EligibilityModule } from '../eligibility/eligibility.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { WorkflowModule } from '../workflow/workflow.module';
import { ConsentsController } from './consents.controller';
import { ConsentsService } from './consents.service';

@Module({
  imports: [EligibilityModule, NotificationsModule, WorkflowModule, ConnectorsModule],
  controllers: [ConsentsController],
  providers: [ConsentsService],
  exports: [ConsentsService],
})
export class ConsentsModule {}
