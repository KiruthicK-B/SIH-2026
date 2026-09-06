import { Module } from '@nestjs/common';
import { ConnectorsModule } from '../connectors/connectors.module';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { WorkflowService } from './workflow.service';

@Module({
  imports: [ConnectorsModule, NotificationsModule, DocumentsModule],
  providers: [WorkflowService],
  exports: [WorkflowService],
})
export class WorkflowModule {}
