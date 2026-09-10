import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTaskDto, UpdateTaskDto, ReorderTasksDto, QueryTasksDto } from './dto/task.dto.js';
import { TaskSection, TaskStatus } from '@prisma/client';

@Injectable()
export class TasksService {
  constructor(private prisma: PrismaService) {}

  // ── 查询任务列表 ────────────────────────────────────────
  async findAll(userId: string, query: QueryTasksDto) {
    const where: Record<string, unknown> = { userId };

    if (query.section) where.section = query.section;
    if (query.status) {
      where.status = query.status;
    } else {
      // 默认只返回未完成任务
      where.status = TaskStatus.TODO;
    }
    if (query.listId) where.listId = query.listId;
    if (query.dueDate) {
      const start = new Date(query.dueDate);
      const end = new Date(query.dueDate);
      end.setDate(end.getDate() + 1);
      where.dueDate = { gte: start, lt: end };
    }

    return this.prisma.task.findMany({
      where,
      include: {
        tags: { include: { tag: true } },
        children: { where: { status: TaskStatus.TODO }, orderBy: { sortOrder: 'asc' } },
        list: { select: { id: true, name: true, color: true } },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    });
  }

  // ── 今天视图（TODAY + 今天到期的INBOX任务） ─────────────
  async findToday(userId: string) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    return this.prisma.task.findMany({
      where: {
        userId,
        status: TaskStatus.TODO,
        OR: [
          { section: TaskSection.TODAY },
          {
            section: TaskSection.INBOX,
            dueDate: { gte: todayStart, lte: todayEnd },
          },
        ],
      },
      include: {
        tags: { include: { tag: true } },
        list: { select: { id: true, name: true, color: true } },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    });
  }

  // ── 创建任务 ────────────────────────────────────────────
  async create(userId: string, dto: CreateTaskDto) {
    const { tagIds, ...taskData } = dto;

    // 计算默认 sortOrder（追加到末尾）
    const maxOrder = await this.prisma.task.aggregate({
      where: { userId, section: dto.section || TaskSection.INBOX },
      _max: { sortOrder: true },
    });
    const sortOrder = (maxOrder._max.sortOrder || 0) + 1000;

    return this.prisma.task.create({
      data: {
        ...taskData,
        userId,
        sortOrder,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        tags: tagIds?.length
          ? { create: tagIds.map((tagId) => ({ tagId })) }
          : undefined,
      },
      include: {
        tags: { include: { tag: true } },
        list: { select: { id: true, name: true, color: true } },
      },
    });
  }

  // ── 获取单个任务 ────────────────────────────────────────
  async findOne(userId: string, id: string) {
    const task = await this.prisma.task.findUnique({
      where: { id },
      include: {
        tags: { include: { tag: true } },
        children: { orderBy: { sortOrder: 'asc' } },
        list: { select: { id: true, name: true, color: true } },
        pomodoros: { orderBy: { startedAt: 'desc' }, take: 10 },
      },
    });

    if (!task) throw new NotFoundException('任务不存在');
    if (task.userId !== userId) throw new ForbiddenException('无权限访问此任务');

    return task;
  }

  // ── 更新任务 ────────────────────────────────────────────
  async update(userId: string, id: string, dto: UpdateTaskDto) {
    await this.findOne(userId, id); // 权限检查

    const { tagIds, ...taskData } = dto;

    return this.prisma.task.update({
      where: { id },
      data: {
        ...taskData,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        tags: tagIds !== undefined
          ? {
              deleteMany: {},
              create: tagIds.map((tagId) => ({ tagId })),
            }
          : undefined,
      },
      include: {
        tags: { include: { tag: true } },
        list: { select: { id: true, name: true, color: true } },
      },
    });
  }

  // ── 完成任务 ────────────────────────────────────────────
  async complete(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.task.update({
      where: { id },
      data: {
        status: TaskStatus.DONE,
        completedAt: new Date(),
      },
    });
  }

  // ── 撤销完成 ────────────────────────────────────────────
  async uncomplete(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.task.update({
      where: { id },
      data: { status: TaskStatus.TODO, completedAt: null },
    });
  }

  // ── 删除任务 ────────────────────────────────────────────
  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    await this.prisma.task.delete({ where: { id } });
    return { success: true };
  }

  // ── 批量拖拽排序 ────────────────────────────────────────
  async reorder(userId: string, dto: ReorderTasksDto) {
    const updates = dto.taskIds.map((taskId, index) =>
      this.prisma.task.updateMany({
        where: { id: taskId, userId },
        data: {
          sortOrder: (index + 1) * 1000,
          ...(dto.section ? { section: dto.section } : {}),
        },
      }),
    );
    await this.prisma.$transaction(updates);
    return { success: true };
  }
}
