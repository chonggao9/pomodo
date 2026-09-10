import { Module } from '@nestjs/common';
import { SyncGateway } from './sync.gateway.js';
import { SyncService } from './sync.service.js';
import { SyncController } from './sync.controller.js';
import { AuthModule } from '../auth/auth.module.js';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module.js';

@Module({
  imports: [AuthModule, ConfigModule, PrismaModule],
  controllers: [SyncController],
  providers: [SyncGateway, SyncService],
  exports: [SyncGateway, SyncService],
})
export class SyncModule {}
