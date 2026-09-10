import { Controller, Post, Patch, Get, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PomodorosService, CreatePomodoroDto } from './pomodoros.service.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';

@ApiTags('番茄专注')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('pomodoros')
export class PomodorosController {
  constructor(private pomodorosService: PomodorosService) {}

  @Post('start')
  @ApiOperation({ summary: '开始一个番茄' })
  start(@Request() req: { user: { userId: string } }, @Body() dto: CreatePomodoroDto) {
    return this.pomodorosService.start(req.user.userId, dto);
  }

  @Patch(':id/finish')
  @ApiOperation({ summary: '结束番茄（正常完成）' })
  finish(@Request() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.pomodorosService.finish(req.user.userId, id, false);
  }

  @Patch(':id/interrupt')
  @ApiOperation({ summary: '中断番茄' })
  interrupt(@Request() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.pomodorosService.finish(req.user.userId, id, true);
  }

  @Get('recent')
  @ApiOperation({ summary: '最近番茄记录（默认7天）' })
  recent(@Request() req: { user: { userId: string } }, @Query('days') days?: number) {
    return this.pomodorosService.findRecent(req.user.userId, days || 7);
  }
}
