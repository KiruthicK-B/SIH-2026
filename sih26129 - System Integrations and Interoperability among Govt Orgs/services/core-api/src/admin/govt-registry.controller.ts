import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Post, Res, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { memoryStorage } from 'multer';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';

const DIGILOCKER_ADAPTER_URL = process.env.DIGILOCKER_ADAPTER_URL ?? 'http://digilocker-adapter:4005';

// Proxies the platform console's "Govt Identity Registry" tab to digilocker-adapter's
// own admin surface — the adapter itself has no auth (matches every other adapter in
// this project), so RBAC is enforced here before the call is ever forwarded.
@Controller('admin/govt-registry')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('platform-admin')
export class GovtRegistryController {
  @Get()
  async list() {
    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/admin/records`);
    if (!res.ok) throw new BadRequestException('could not reach the govt identity registry');
    return res.json();
  }

  @Post()
  async create(@Body() body: Record<string, unknown>) {
    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/admin/records`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const responseBody = await res.json();
    if (!res.ok) throw new BadRequestException(responseBody.message ?? 'could not create the registry record');
    return responseBody;
  }

  @Get(':aadhaarNumber/photo')
  async photo(@Param('aadhaarNumber') aadhaarNumber: string, @Res() res: Response) {
    const upstream = await fetch(`${DIGILOCKER_ADAPTER_URL}/photo/${aadhaarNumber}`);
    if (!upstream.ok) throw new NotFoundException('no photo on file for this record');
    const buffer = Buffer.from(await upstream.arrayBuffer());
    res.type(upstream.headers.get('content-type') ?? 'image/jpeg');
    res.send(buffer);
  }

  @Post(':aadhaarNumber/photo')
  @UseInterceptors(FileInterceptor('file', { storage: memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadPhoto(@Param('aadhaarNumber') aadhaarNumber: string, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('no file attached');

    const form = new FormData();
    form.append('photo', new Blob([new Uint8Array(file.buffer)], { type: file.mimetype }), file.originalname);
    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/admin/records/${aadhaarNumber}/photo`, { method: 'POST', body: form });
    if (!res.ok) throw new BadRequestException('could not upload photo to the govt identity registry');
    return res.json();
  }

  // DEMO / MOCK GOVERNMENT DATA — simulates an authoritative identity status change
  // (e.g. reported deceased) for the adversarial-hardening demo. platform-admin only,
  // same RBAC as every route in this controller; never implies a real government
  // registry is writable this way.
  @Post(':aadhaarNumber/identity-status')
  async setIdentityStatus(@Param('aadhaarNumber') aadhaarNumber: string, @Body('status') status: string) {
    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/admin/records/${aadhaarNumber}/identity-status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    const responseBody = await res.json();
    if (!res.ok) throw new BadRequestException(responseBody.message ?? 'could not update identity status');
    return responseBody;
  }
}
