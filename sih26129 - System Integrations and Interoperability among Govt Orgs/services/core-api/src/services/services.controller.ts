import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PG_POOL } from '../db/db.module';

@Controller('services')
@UseGuards(JwtAuthGuard)
export class ServicesController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async list() {
    const [categories, services] = await Promise.all([
      this.pool.query('SELECT name FROM service_categories ORDER BY name'),
      this.pool.query('SELECT * FROM services ORDER BY name'),
    ]);
    return {
      categories: categories.rows.map((r) => r.name),
      services: services.rows.map((r) => ({
        id: r.id,
        name: r.name,
        department: r.department,
        category: r.category,
        processingTime: r.processing_time,
        requiredDocuments: r.required_documents,
        description: r.description,
      })),
    };
  }
}
