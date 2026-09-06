import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { diskStorage } from 'multer';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { DocumentsService } from './documents.service';

const UPLOAD_DIR = process.env.UPLOAD_DIR ?? '/app/uploads';

@Controller('documents')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(private readonly service: DocumentsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    const scope = user.roles.includes('citizen') ? (user.masterId ?? undefined) : undefined;
    return this.service.list(scope);
  }

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: UPLOAD_DIR,
        // Never build the on-disk path from the client-supplied filename — a name
        // like "../../../etc/x" would escape UPLOAD_DIR. The original name is kept
        // separately as the `name` DB column for display; only a safe extension
        // (extname only ever reads past the last path separator) survives here.
        filename: (_req, file, cb) => cb(null, `${randomUUID()}${extname(file.originalname)}`),
      }),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async upload(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: AuthenticatedUser) {
    if (!file) throw new BadRequestException('no file attached');
    if (!user.masterId) throw new BadRequestException('only citizens can upload documents');
    const id = await this.service.uploadDocument(user.masterId, file.originalname, file.path, file.mimetype, file.size);
    return { id };
  }

  @Get(':id/file')
  async file(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser, @Res() res: Response) {
    const scope = user.roles.includes('citizen') ? (user.masterId ?? undefined) : undefined;
    const doc = await this.service.getFile(id, scope);
    if (!doc) throw new NotFoundException('document not found or has no attached file');
    res.type(doc.mimeType ?? 'application/octet-stream');
    res.sendFile(doc.filePath);
  }
}
