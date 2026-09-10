import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module.js';

// Users 模块（当前通过 Auth 管理用户，这里留扩展入口）
@Module({
  imports: [PrismaModule],
})
export class UsersModule {}
