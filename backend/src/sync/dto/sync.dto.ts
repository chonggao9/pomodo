// 前后端增量同步传输对象 DTO
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ClientTaskSyncDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional()
  notes?: string | null;

  @ApiPropertyOptional({ default: 'P1' })
  priority?: string;

  @ApiPropertyOptional({ default: 1 })
  ivy_order?: number;

  @ApiPropertyOptional({ default: 'pending' })
  status?: string;

  @ApiPropertyOptional({ default: 'easy' })
  workload?: string;

  @ApiPropertyOptional()
  due_date?: string | null;

  @ApiPropertyOptional()
  category_id?: string | null;

  @ApiProperty()
  created_at: string;

  @ApiProperty()
  updated_at: string;

  @ApiPropertyOptional()
  completed_at?: string | null;
}

export class ClientPomodoroSyncDto {
  @ApiProperty()
  id: string;

  @ApiPropertyOptional()
  task_id?: string | null;

  @ApiProperty({ default: 25 })
  duration_minutes: number;

  @ApiPropertyOptional()
  white_noise?: string | null;

  @ApiPropertyOptional({ default: 'completed' })
  status?: string;

  @ApiProperty()
  started_at: string;

  @ApiProperty()
  ended_at: string;
}

export class SyncPushDto {
  @ApiProperty({ type: [ClientTaskSyncDto] })
  tasks: ClientTaskSyncDto[];

  @ApiProperty({ type: [ClientPomodoroSyncDto] })
  pomodoros: ClientPomodoroSyncDto[];

  @ApiPropertyOptional()
  client_timestamp?: string;
}

export class SyncPullQueryDto {
  @ApiPropertyOptional({ description: '上次同步时间戳（ISO 8601）' })
  since?: string;
}

export class SyncPullResponseDto {
  @ApiProperty({ type: [ClientTaskSyncDto] })
  tasks: ClientTaskSyncDto[];

  @ApiProperty({ type: [ClientPomodoroSyncDto] })
  pomodoros: ClientPomodoroSyncDto[];

  @ApiProperty()
  server_timestamp: string;
}
