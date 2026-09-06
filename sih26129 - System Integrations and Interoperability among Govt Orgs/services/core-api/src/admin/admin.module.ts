import { Module } from '@nestjs/common';
import { ConnectorsModule } from '../connectors/connectors.module';
import { WorkflowModule } from '../workflow/workflow.module';
import { AdminController } from './admin.controller';
import { GovtRegistryController } from './govt-registry.controller';

@Module({
  imports: [ConnectorsModule, WorkflowModule],
  controllers: [AdminController, GovtRegistryController],
})
export class AdminModule {}
