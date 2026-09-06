import { extname } from 'node:path';
import { Controller, Get, Inject, NotFoundException, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import type { Pool } from 'pg';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { PG_POOL } from '../db/db.module';

const CONTENT_TYPE_BY_EXTENSION: Record<string, string> = {
  '.avif': 'image/avif',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
};

@Controller('identity')
@UseGuards(JwtAuthGuard)
export class IdentityController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get('me')
  async me(@CurrentUser() user: AuthenticatedUser) {
    // Citizens get their own record. Officers/admins have no master_id (they aren't
    // citizens) but the platform's DataStandardsTab still needs one identity record
    // to illustrate entity resolution — falls back to the first one on file.
    const isPlatformRole = user.roles.includes('officer') || user.roles.includes('platform-admin');
    if (!user.masterId && !isPlatformRole) throw new NotFoundException('no master identity on this account');

    const { rows: identityRows } = user.masterId
      ? await this.pool.query('SELECT * FROM master_identity WHERE master_id = $1', [user.masterId])
      : await this.pool.query('SELECT * FROM master_identity ORDER BY master_id LIMIT 1');
    if (identityRows.length === 0) throw new NotFoundException('master identity record not found');

    const resolvedMasterId = identityRows[0].master_id;
    const { rows: deptRows } = await this.pool.query(
      'SELECT department, identifier, confidence FROM department_identifiers WHERE master_id = $1 ORDER BY department',
      [resolvedMasterId],
    );

    const identity = identityRows[0];
    return {
      masterId: identity.master_id,
      citizenName: identity.citizen_name,
      phoneNumber: identity.phone_number ?? null,
      dateOfBirth: identity.date_of_birth ? new Date(identity.date_of_birth).toISOString().slice(0, 10) : null,
      gender: identity.gender ?? null,
      address: identity.address ?? null,
      annualIncome: identity.annual_income ?? null,
      educationDetails: identity.education_details ?? null,
      panNumber: identity.pan_number ?? null,
      employmentStatus: identity.employment_status ?? null,
      employerName: identity.employer_name ?? null,
      designation: identity.designation ?? null,
      highestQualification: identity.highest_qualification ?? null,
      institutionName: identity.institution_name ?? null,
      occupation: identity.occupation ?? null,
      fatherName: identity.father_name ?? null,
      motherName: identity.mother_name ?? null,
      parentPhoneNumber: identity.parent_phone_number ?? null,
      siblings: identity.siblings ?? null,
      photoUrl: identity.photo_path ? '/identity/me/photo' : null,
      departmentIdentifiers: deptRows.map((r) => ({
        department: r.department,
        identifier: r.identifier,
        confidence: r.confidence != null ? Number(r.confidence) : undefined,
      })),
    };
  }

  @Get('me/photo')
  async photo(@CurrentUser() user: AuthenticatedUser, @Res() res: Response) {
    if (!user.masterId) throw new NotFoundException('no master identity on this account');
    const { rows } = await this.pool.query('SELECT photo_path FROM master_identity WHERE master_id = $1', [user.masterId]);
    if (rows.length === 0 || !rows[0].photo_path) throw new NotFoundException('no photo on file');
    const photoPath = rows[0].photo_path;
    // Express's bundled mime-db doesn't recognize .avif, so sendFile()'s automatic
    // Content-Type inference silently falls back to application/octet-stream for
    // it — browsers then refuse to render the (correctly-encoded) image bytes.
    res.type(CONTENT_TYPE_BY_EXTENSION[extname(photoPath).toLowerCase()] ?? 'application/octet-stream');
    res.sendFile(photoPath);
  }
}
