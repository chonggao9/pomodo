import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { TaskStatus, PomodoroType } from '@prisma/client';

@Injectable()
export class StatsService {
  constructor(private prisma: PrismaService) {}

  // ── 今日统计 ────────────────────────────────────────────
  async getDaily(userId: string, dateStr?: string) {
    const date = dateStr ? new Date(dateStr) : new Date();
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const [totalTasks, completedTasks, pomodoros] = await Promise.all([
      // 当天创建的任务
      this.prisma.task.count({
        where: { userId, createdAt: { gte: start, lte: end } },
      }),
      // 当天完成的任务
      this.prisma.task.count({
        where: { userId, completedAt: { gte: start, lte: end }, status: TaskStatus.DONE },
      }),
      // 当天番茄数
      this.prisma.pomodoro.findMany({
        where: {
          userId,
          type: PomodoroType.WORK,
          interrupted: false,
          startedAt: { gte: start, lte: end },
          endedAt: { not: null },
        },
      }),
    ]);

    const pomodoroMinutes = pomodoros.reduce((sum, p) => sum + p.duration, 0);
    const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

    return {
      date: date.toISOString().split('T')[0],
      totalTasks,
      completedTasks,
      completionRate,
      pomodoroCount: pomodoros.length,
      pomodoroMinutes,
    };
  }

  // ── 周报统计 ────────────────────────────────────────────
  async getWeekly(userId: string) {
    const results = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const daily = await this.getDaily(userId, d.toISOString().split('T')[0]);
      results.push(daily);
    }

    const totalCompleted = results.reduce((s, d) => s + d.completedTasks, 0);
    const totalPomodoros = results.reduce((s, d) => s + d.pomodoroCount, 0);
    const avgCompletion = Math.round(results.reduce((s, d) => s + d.completionRate, 0) / 7);

    return {
      days: results,
      summary: { totalCompleted, totalPomodoros, avgCompletion },
    };
  }

  // ── 任务分类分布 ────────────────────────────────────────
  async getDistribution(userId: string) {
    const lists = await this.prisma.list.findMany({
      where: { userId },
      include: {
        _count: {
          select: {
            tasks: { where: { status: TaskStatus.DONE } },
          },
        },
      },
    });

    return lists.map((l) => ({
      listId: l.id,
      listName: l.name,
      color: l.color,
      completedCount: l._count.tasks,
    }));
  }
}
