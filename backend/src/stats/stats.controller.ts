import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { StatsService } from './stats.service.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';

@ApiTags('数据统计')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('stats')
export class StatsController {
  constructor(private statsService: StatsService) {}

  @Get('daily')
  @ApiOperation({ summary: '每日统计（完成率/番茄数）' })
  daily(@Request() req: { user: { userId: string } }, @Query('date') date?: string) {
    return this.statsService.getDaily(req.user.userId, date);
  }

  @Get('weekly')
  @ApiOperation({ summary: '周报（近7天趋势）' })
  weekly(@Request() req: { user: { userId: string } }) {
    return this.statsService.getWeekly(req.user.userId);
  }

  @Get('distribution')
  @ApiOperation({ summary: '任务分类分布' })
  distribution(@Request() req: { user: { userId: string } }) {
    return this.statsService.getDistribution(req.user.userId);
  }
}
