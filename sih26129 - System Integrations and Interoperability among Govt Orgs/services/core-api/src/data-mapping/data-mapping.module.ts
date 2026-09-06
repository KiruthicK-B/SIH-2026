import { Module } from '@nestjs/common';
import { DataMappingController } from './data-mapping.controller';

@Module({
  controllers: [DataMappingController],
})
export class DataMappingModule {}
