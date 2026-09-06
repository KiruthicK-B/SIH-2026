import { Body, Controller, Get, Inject, Post, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';

interface FieldMappingInput {
  sourceField: string;
  sourceSystem: string;
  targetField: string;
  confidence: number;
  rationale: string;
}

// Persists the field mappings an admin approves out of the AI-assisted suggestion
// panel (DataStandardsTab.tsx) — the suggestion itself is stateless (mdm-service);
// this is the canonical schema registry's record of what was actually adopted.
@Controller('schema/field-mappings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('platform-admin')
export class SchemaController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async list() {
    const { rows } = await this.pool.query('SELECT * FROM field_mappings ORDER BY id DESC');
    return rows.map((r) => ({
      id: r.id,
      sourceField: r.source_field,
      sourceSystem: r.source_system,
      targetField: r.target_field,
      confidence: Number(r.confidence),
      rationale: r.rationale,
      status: r.status,
    }));
  }

  @Post()
  async approve(@Body() body: FieldMappingInput) {
    const { rows } = await this.pool.query(
      `INSERT INTO field_mappings (source_field, source_system, target_field, confidence, rationale, status)
       VALUES ($1, $2, $3, $4, $5, 'approved') RETURNING id`,
      [body.sourceField, body.sourceSystem, body.targetField, body.confidence, body.rationale],
    );
    return { id: rows[0].id };
  }
}
