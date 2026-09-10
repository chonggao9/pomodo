import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { PomodoroType } from '@prisma/client';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePomodoroDto {
  @ApiPropertyOptional({ description: '关联的任务ID' })
  @IsOptional()
  @IsString()
  taskId?: string;

  @ApiProperty({ example: 25, description: '专注时长（分钟）' })
  @IsInt()
  @Min(1)
  duration: number;

  @ApiPropertyOptional({ enum: PomodoroType, default: 'WORK' })
  @IsOptional()
  type?: PomodoroType;
}

@Injectable()
export class PomodorosService {
  constructor(private prisma: PrismaService) {}

  async start(userId: string, dto: CreatePomodoroDto) {
    return this.prisma.pomodoro.create({
      data: {
        userId,
        taskId: dto.taskId,
        duration: dto.duration,
        type: dto.type || PomodoroType.WORK,
        startedAt: new Date(),
      },
    });
  }

  async finish(userId: string, id: string, interrupted = false) {
    return this.prisma.pomodoro.update({
      where: { id },
      data: { endedAt: new Date(), interrupted },
    });
  }

  async findRecent(userId: string, days = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);
    return this.prisma.pomodoro.findMany({
      where: { userId, startedAt: { gte: since }, type: PomodoroType.WORK },
      orderBy: { startedAt: 'desc' },
      include: { task: { select: { id: true, title: true } } },
    });
  }
}
