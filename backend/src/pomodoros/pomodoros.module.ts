import { Module } from '@nestjs/common';
import { PomodorosController } from './pomodoros.controller.js';
import { PomodorosService } from './pomodoros.service.js';
import { PrismaModule } from '../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [PomodorosController],
  providers: [PomodorosService],
})
export class PomodorosModule {}
