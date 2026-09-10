import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';
import { TasksModule } from './tasks/tasks.module.js';
import { ListsModule } from './lists/lists.module.js';
import { PomodorosModule } from './pomodoros/pomodoros.module.js';
import { StatsModule } from './stats/stats.module.js';
import { SyncModule } from './sync/sync.module.js';

@Module({
  imports: [
    // 配置模块（读取 .env）
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    // Prisma 数据库模块
    PrismaModule,
    // 业务模块
    AuthModule,
    UsersModule,
    TasksModule,
    ListsModule,
    PomodorosModule,
    StatsModule,
    SyncModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
