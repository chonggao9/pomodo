import { IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateListDto {
  @ApiProperty({ example: '工作任务' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: '#FF6B6B' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'briefcase' })
  @IsOptional()
  @IsString()
  icon?: string;
}

export class UpdateListDto extends CreateListDto {}
