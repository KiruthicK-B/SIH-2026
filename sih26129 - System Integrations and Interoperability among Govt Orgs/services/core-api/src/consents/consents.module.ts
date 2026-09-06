import { Module } from '@nestjs/common';
import { EligibilityModule } from '../eligibility/eligibility.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ConsentsController } from './consents.controller';
import { ConsentsService } from './consents.service';

@Module({
  imports: [EligibilityModule, NotificationsModule],
  controllers: [ConsentsController],
  providers: [ConsentsService],
  exports: [ConsentsService],
})
export class ConsentsModule {}
