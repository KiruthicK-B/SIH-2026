import { Global, Module } from '@nestjs/common';
import { ApplicationEventsService } from './application-events.service';

@Global()
@Module({
  providers: [ApplicationEventsService],
  exports: [ApplicationEventsService],
})
export class EventsModule {}
