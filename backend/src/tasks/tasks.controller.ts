import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TasksService } from './tasks.service.js';
import { CreateTaskDto, UpdateTaskDto, ReorderTasksDto, QueryTasksDto } from './dto/task.dto.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';

@ApiTags('任务')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('tasks')
export class TasksController {
  constructor(private tasksService: TasksService) {}

  @Get()
  @ApiOperation({ summary: '获取任务列表（支持分区/状态/日期/清单过滤）' })
  findAll(
    @Request() req: { user: { userId: string } },
    @Query() query: QueryTasksDto,
  ) {
    return this.tasksService.findAll(req.user.userId, query);
  }

  @Get('today')
  @ApiOperation({ summary: '获取今日任务（TODAY分区 + 今天到期的任务）' })
  findToday(@Request() req: { user: { userId: string } }) {
    return this.tasksService.findToday(req.user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取单个任务详情' })
  findOne(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.tasksService.findOne(req.user.userId, id);
  }

  @Post()
  @ApiOperation({ summary: '创建任务' })
  create(
    @Request() req: { user: { userId: string } },
    @Body() dto: CreateTaskDto,
  ) {
    return this.tasksService.create(req.user.userId, dto);
  }

  @Patch('reorder')
  @ApiOperation({ summary: '批量拖拽排序' })
  reorder(
    @Request() req: { user: { userId: string } },
    @Body() dto: ReorderTasksDto,
  ) {
    return this.tasksService.reorder(req.user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: '更新任务' })
  update(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
    @Body() dto: UpdateTaskDto,
  ) {
    return this.tasksService.update(req.user.userId, id, dto);
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: '完成任务' })
  complete(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.tasksService.complete(req.user.userId, id);
  }

  @Patch(':id/uncomplete')
  @ApiOperation({ summary: '撤销完成任务' })
  uncomplete(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.tasksService.uncomplete(req.user.userId, id);
  }

  @Delete(':id')
  @ApiOperation({ summary: '删除任务' })
  remove(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.tasksService.remove(req.user.userId, id);
  }
}
