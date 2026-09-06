import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { PlatformStatsController } from './platform-stats.controller';

@Module({
  imports: [AuditModule],
  controllers: [PlatformStatsController],
})
export class PlatformStatsModule {}
