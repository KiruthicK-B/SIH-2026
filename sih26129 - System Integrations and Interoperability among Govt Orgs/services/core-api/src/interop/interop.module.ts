import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { WorkflowModule } from '../workflow/workflow.module';
import { InteropController } from './interop.controller';

@Module({
  imports: [WorkflowModule, DocumentsModule],
  controllers: [InteropController],
})
export class InteropModule {}
