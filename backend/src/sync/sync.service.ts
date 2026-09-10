// 前后端增量双向同步业务逻辑服务
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { SyncGateway } from './sync.gateway.js';
import {
  SyncPushDto,
  SyncPullResponseDto,
  ClientTaskSyncDto,
  ClientPomodoroSyncDto,
} from './dto/sync.dto.js';
import { TaskStatus, TaskSection, PomodoroType } from '@prisma/client';

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  constructor(
    private prisma: PrismaService,
    private syncGateway: SyncGateway,
  ) {}

  /** 接收客户端增量推送 (Push) */
  async push(userId: string, dto: SyncPushDto) {
    const now = new Date().toISOString();
    let updatedTasksCount = 0;
    let updatedPomosCount = 0;

    // 1. 处理待办任务增量 (LWW 策略)
    if (dto.tasks && dto.tasks.length > 0) {
      for (const clientTask of dto.tasks) {
        try {
          const clientUpdated = new Date(clientTask.updated_at);
          const existing = await this.prisma.task.findUnique({
            where: { id: clientTask.id },
          });

          const serverStatus = clientTask.status === 'completed'
            ? TaskStatus.DONE
            : clientTask.status === 'archived'
              ? TaskStatus.CANCELLED
              : TaskStatus.TODO;

          const priorityNum = clientTask.priority
            ? parseInt(clientTask.priority.replace(/\D/g, ''), 10) || 1
            : 1;

          if (!existing) {
            // 新增任务
            await this.prisma.task.create({
              data: {
                id: clientTask.id,
                userId,
                title: clientTask.title,
                note: clientTask.notes ?? null,
                priority: priorityNum,
                status: serverStatus,
                section: TaskSection.TODAY,
                sortOrder: clientTask.ivy_order ?? 1,
                dueDate: clientTask.due_date ? new Date(clientTask.due_date) : null,
                createdAt: new Date(clientTask.created_at),
                updatedAt: clientUpdated,
                completedAt: clientTask.completed_at ? new Date(clientTask.completed_at) : null,
              },
            });
            updatedTasksCount++;
          } else if (existing.userId === userId && clientUpdated >= existing.updatedAt) {
            // 已存在且客户端更新时间戳更新 -> 覆盖更新
            await this.prisma.task.update({
              where: { id: clientTask.id },
              data: {
                title: clientTask.title,
                note: clientTask.notes ?? null,
                priority: priorityNum,
                status: serverStatus,
                sortOrder: clientTask.ivy_order ?? existing.sortOrder,
                dueDate: clientTask.due_date ? new Date(clientTask.due_date) : null,
                updatedAt: clientUpdated,
                completedAt: clientTask.completed_at ? new Date(clientTask.completed_at) : null,
              },
            });
            updatedTasksCount++;
          }
        } catch (err) {
          this.logger.warn(`Failed to sync task ${clientTask.id}: ${err}`);
        }
      }
    }

    // 2. 处理番茄专注记录增量
    if (dto.pomodoros && dto.pomodoros.length > 0) {
      for (const pomo of dto.pomodoros) {
        try {
          const existing = await this.prisma.pomodoro.findUnique({
            where: { id: pomo.id },
          });

          if (!existing) {
            await this.prisma.pomodoro.create({
              data: {
                id: pomo.id,
                userId,
                taskId: pomo.task_id ?? null,
                duration: pomo.duration_minutes ?? 25,
                type: PomodoroType.WORK,
                interrupted: pomo.status === 'abandoned',
                startedAt: new Date(pomo.started_at),
                endedAt: pomo.ended_at ? new Date(pomo.ended_at) : new Date(),
              },
            });
            updatedPomosCount++;
          }
        } catch (err) {
          this.logger.warn(`Failed to sync pomodoro ${pomo.id}: ${err}`);
        }
      }
    }

    // 3. 触发 WebSocket 广播，通知该用户的其它活跃设备有新数据
    this.syncGateway.notifyUserDevices(userId, 'sync:data_updated', {
      server_timestamp: now,
      tasks_updated: updatedTasksCount,
      pomos_updated: updatedPomosCount,
    });

    return {
      success: true,
      processed_tasks: updatedTasksCount,
      processed_pomodoros: updatedPomosCount,
      server_timestamp: now,
    };
  }

  /** 客户端增量拉取 (Pull) */
  async pull(userId: string, since?: string): Promise<SyncPullResponseDto> {
    const serverTimestamp = new Date().toISOString();
    const sinceDate = since ? new Date(since) : new Date(0);

    // 查询该用户变更的任务
    const dbTasks = await this.prisma.task.findMany({
      where: {
        userId,
        updatedAt: { gte: sinceDate },
      },
      orderBy: { updatedAt: 'asc' },
    });

    // 映射回客户端数据结构
    const mappedTasks: ClientTaskSyncDto[] = dbTasks.map(t => ({
      id: t.id,
      title: t.title,
      notes: t.note,
      priority: `P${t.priority || 1}`,
      ivy_order: Math.round(t.sortOrder || 1),
      status: t.status === TaskStatus.DONE ? 'completed' : t.status === TaskStatus.CANCELLED ? 'archived' : 'pending',
      workload: 'easy',
      due_date: t.dueDate ? t.dueDate.toISOString().slice(0, 10) : null,
      category_id: t.listId,
      created_at: t.createdAt.toISOString(),
      updated_at: t.updatedAt.toISOString(),
      completed_at: t.completedAt ? t.completedAt.toISOString() : null,
    }));

    // 查询增量番茄记录
    const dbPomos = await this.prisma.pomodoro.findMany({
      where: {
        userId,
        startedAt: { gte: sinceDate },
      },
      orderBy: { startedAt: 'asc' },
    });

    const mappedPomos: ClientPomodoroSyncDto[] = dbPomos.map(p => ({
      id: p.id,
      task_id: p.taskId,
      duration_minutes: p.duration,
      white_noise: null,
      status: p.interrupted ? 'abandoned' : 'completed',
      started_at: p.startedAt.toISOString(),
      ended_at: p.endedAt ? p.endedAt.toISOString() : p.startedAt.toISOString(),
    }));

    return {
      tasks: mappedTasks,
      pomodoros: mappedPomos,
      server_timestamp: serverTimestamp,
    };
  }
}
