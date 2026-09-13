import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminModule } from './admin/admin.module';
import { ApplicationsModule } from './applications/applications.module';
import { ArchitectureModule } from './architecture/architecture.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { ConnectorsModule } from './connectors/connectors.module';
import { ConsentsModule } from './consents/consents.module';
import { DataMappingModule } from './data-mapping/data-mapping.module';
import { DataQualityModule } from './data-quality/data-quality.module';
import { DbModule } from './db/db.module';
import { DepartmentsModule } from './departments/departments.module';
import { DocumentsModule } from './documents/documents.module';
import { EventsModule } from './events/events.module';
import { GrievancesModule } from './grievances/grievances.module';
import { HealthController } from './health.controller';
import { IdentityModule } from './identity/identity.module';
import { InteropModule } from './interop/interop.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PlatformStatsModule } from './platform-stats/platform-stats.module';
import { SchemaModule } from './schema/schema.module';
import { ScopesModule } from './scopes/scopes.module';
import { ServicesModule } from './services/services.module';
import { SlaModule } from './sla/sla.module';
import { WorkflowModule } from './workflow/workflow.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DbModule,
    EventsModule,
    ConnectorsModule,
    WorkflowModule,
    ApplicationsModule,
    ConsentsModule,
    AuditModule,
    AdminModule,
    SchemaModule,
    DepartmentsModule,
    IdentityModule,
    InteropModule,
    AuthModule,
    ServicesModule,
    SlaModule,
    DataQualityModule,
    NotificationsModule,
    DocumentsModule,
    GrievancesModule,
    PlatformStatsModule,
    DataMappingModule,
    ArchitectureModule,
    ScopesModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
