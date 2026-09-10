import {
  IsString, IsOptional, IsInt, IsEnum, IsDateString, Min, Max, IsArray
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { TaskSection, TaskStatus } from '@prisma/client';

export class CreateTaskDto {
  @ApiProperty({ example: '完成产品原型设计', description: '任务标题' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ example: '需要包含登录/任务/统计三个模块' })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({ example: '2026-09-10' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ example: '14:30' })
  @IsOptional()
  @IsString()
  dueTime?: string;

  @ApiPropertyOptional({ enum: [1, 2, 3, 4], default: 4, description: '优先级 1=最高 P1, 4=最低 P4' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(4)
  priority?: number;

  @ApiPropertyOptional({ enum: TaskSection, default: 'INBOX' })
  @IsOptional()
  @IsEnum(TaskSection)
  section?: TaskSection;

  @ApiPropertyOptional({ description: '父任务ID（创建子任务时使用）' })
  @IsOptional()
  @IsString()
  parentId?: string;

  @ApiPropertyOptional({ description: '所属清单ID' })
  @IsOptional()
  @IsString()
  listId?: string;

  @ApiPropertyOptional({ example: '0 9 * * *', description: '重复规则（cron表达式）' })
  @IsOptional()
  @IsString()
  repeatRule?: string;

  @ApiPropertyOptional({ type: [String], description: '标签ID数组' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tagIds?: string[];
}

export class UpdateTaskDto extends PartialType(CreateTaskDto) {
  @ApiPropertyOptional({ enum: TaskStatus })
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;
}

export class ReorderTasksDto {
  @ApiProperty({ description: '任务ID排序数组（按新顺序排列）', type: [String] })
  @IsArray()
  @IsString({ each: true })
  taskIds: string[];

  @ApiPropertyOptional({ enum: TaskSection, description: '同时更新分区' })
  @IsOptional()
  @IsEnum(TaskSection)
  section?: TaskSection;
}

export class QueryTasksDto {
  @ApiPropertyOptional({ enum: TaskSection })
  @IsOptional()
  @IsEnum(TaskSection)
  section?: TaskSection;

  @ApiPropertyOptional({ enum: TaskStatus })
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @ApiPropertyOptional({ example: '2026-09-10' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  listId?: string;
}
