import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  NotFoundException,
  Param,
  Post,
  Query,
  Res,
  UnauthorizedException,
} from '@nestjs/common';
import type { Response } from 'express';
import { DocumentsService } from '../documents/documents.service';
import { WorkflowService } from '../workflow/workflow.service';
import { DEPARTMENT_BY_SLUG, verifyCallbackSignature, verifyDocumentAccess } from './interop-secrets';

// No JwtAuthGuard on this controller on purpose — these callers are external
// department systems outside OneDesk's Keycloak trust boundary by design (see
// LIVE_DEPARTMENT_PORTALS_PLAN.md §6); their credential is the per-department HMAC
// signature verified on every route below.
interface DeptCallbackBody {
  applicationId: string;
  decision: 'APPROVED' | 'REJECTED';
  remark: string;
  decidedBy: string;
  decidedAt: string;
}

@Controller('interop')
export class InteropController {
  constructor(
    private readonly workflow: WorkflowService,
    private readonly documents: DocumentsService,
  ) {}

  @Post('dept-callback/:departmentSlug')
  async deptCallback(
    @Param('departmentSlug') departmentSlug: string,
    @Body() body: DeptCallbackBody,
    @Headers('x-signature') signature?: string,
  ) {
    const department = DEPARTMENT_BY_SLUG[departmentSlug];
    if (!department) throw new NotFoundException(`unknown department "${departmentSlug}"`);
    if (body.decision !== 'APPROVED' && body.decision !== 'REJECTED') {
      throw new BadRequestException('decision must be APPROVED or REJECTED');
    }
    if (!body.applicationId || !body.decidedBy || !body.decidedAt) {
      throw new BadRequestException('applicationId, decidedBy, and decidedAt are required');
    }
    if (!signature || !verifyCallbackSignature(department, body, signature)) {
      throw new UnauthorizedException('invalid callback signature');
    }

    await this.workflow.handleDeptCallback(department, body.applicationId, body.decision, body.remark ?? '', body.decidedBy);
    return { received: true };
  }

  /**
   * Serves one citizen-uploaded document to the department that was handed this
   * exact URL with the case. The file itself never leaves OneDesk as part of the
   * submit payload — departments get a signed pointer back here instead, so
   * (a) the bytes stay on the platform that owns them, and (b) every fetch is a
   * request OneDesk can see rather than an opaque copy sitting in a department's
   * database. Signature is per-department, so one department cannot mint a URL for
   * another's case, and it covers the applicationId so a department cannot swap in
   * an unrelated document's id.
   */
  @Get('documents/:departmentSlug/:applicationId/:docId')
  async document(
    @Param('departmentSlug') departmentSlug: string,
    @Param('applicationId') applicationId: string,
    @Param('docId') docId: string,
    @Query('exp') exp: string,
    @Query('sig') sig: string,
    @Res() res: Response,
  ) {
    const department = DEPARTMENT_BY_SLUG[departmentSlug];
    if (!department) throw new NotFoundException(`unknown department "${departmentSlug}"`);

    const expiresAt = Number(exp);
    if (!Number.isFinite(expiresAt)) throw new BadRequestException('invalid exp');
    if (Date.now() > expiresAt) throw new UnauthorizedException('document link has expired');
    if (!verifyDocumentAccess(docId, applicationId, department, expiresAt, sig ?? '')) {
      throw new UnauthorizedException('invalid document signature');
    }

    const doc = await this.documents.getFileForApplication(docId, applicationId);
    if (!doc) throw new NotFoundException('document not found for this application, or has no attached file');

    res.type(doc.mimeType ?? 'application/octet-stream');
    res.setHeader('X-Document-Name', encodeURIComponent(doc.name));
    res.sendFile(doc.filePath);
  }
}
