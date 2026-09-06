import { EventEmitter } from 'node:events';
import { Injectable } from '@nestjs/common';
import type { Application } from '../applications/applications.types';

@Injectable()
export class ApplicationEventsService {
  private readonly emitter = new EventEmitter();

  constructor() {
    this.emitter.setMaxListeners(200);
  }

  publish(app: Application) {
    this.emitter.emit('update', app);
  }

  subscribe(listener: (app: Application) => void): () => void {
    this.emitter.on('update', listener);
    return () => this.emitter.off('update', listener);
  }
}
