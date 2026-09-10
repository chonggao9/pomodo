// 增量同步控制器
import { Controller, Post, Get, Body, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SyncService } from './sync.service.js';
import { SyncPushDto, SyncPullQueryDto } from './dto/sync.dto.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';

@ApiTags('端云数据同步')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  @ApiOperation({ summary: '客户端增量数据上报同步 (Push)' })
  push(
    @Request() req: { user: { userId: string } },
    @Body() dto: SyncPushDto,
  ) {
    return this.syncService.push(req.user.userId, dto);
  }

  @Get('pull')
  @ApiOperation({ summary: '客户端拉取云端增量数据 (Pull)' })
  pull(
    @Request() req: { user: { userId: string } },
    @Query() query: SyncPullQueryDto,
  ) {
    return this.syncService.pull(req.user.userId, query.since);
  }
}
