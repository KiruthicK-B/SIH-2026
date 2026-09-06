import { Module } from '@nestjs/common';
import { ScopesModule } from '../scopes/scopes.module';
import { IdentifierResolutionController } from './identifier-resolution.controller';
import { KeycloakAdminService } from './keycloak-admin.service';

@Module({
  imports: [ScopesModule],
  controllers: [IdentifierResolutionController],
  providers: [KeycloakAdminService],
})
export class AuthModule {}
