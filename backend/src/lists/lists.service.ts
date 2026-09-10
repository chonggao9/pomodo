import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateListDto, UpdateListDto } from './dto/list.dto.js';

@Injectable()
export class ListsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string) {
    return this.prisma.list.findMany({
      where: { userId },
      include: {
        _count: { select: { tasks: { where: { status: 'TODO' } } } },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async create(userId: string, dto: CreateListDto) {
    const maxOrder = await this.prisma.list.aggregate({
      where: { userId },
      _max: { sortOrder: true },
    });
    return this.prisma.list.create({
      data: {
        ...dto,
        userId,
        sortOrder: (maxOrder._max.sortOrder || 0) + 1000,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateListDto) {
    await this.checkOwner(userId, id);
    return this.prisma.list.update({ where: { id }, data: dto });
  }

  async remove(userId: string, id: string) {
    await this.checkOwner(userId, id);
    await this.prisma.list.delete({ where: { id } });
    return { success: true };
  }

  private async checkOwner(userId: string, id: string) {
    const list = await this.prisma.list.findUnique({ where: { id } });
    if (!list) throw new NotFoundException('清单不存在');
    if (list.userId !== userId) throw new ForbiddenException('无权限');
    return list;
  }
}
