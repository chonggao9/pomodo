import { IsEmail, IsOptional, IsString, MinLength, IsMobilePhone } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiPropertyOptional({ example: '13800138000', description: '手机号（与邮箱二选一）' })
  @IsOptional()
  @IsMobilePhone('zh-CN')
  phone?: string;

  @ApiPropertyOptional({ example: 'user@example.com', description: '邮箱（与手机号二选一）' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiProperty({ example: 'MyPassword123', description: '密码（至少8位）' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiPropertyOptional({ example: '效率达人', description: '昵称' })
  @IsOptional()
  @IsString()
  nickname?: string;
}

export class LoginDto {
  @ApiPropertyOptional({ example: '13800138000' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'user@example.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiProperty({ example: 'MyPassword123' })
  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'Refresh Token' })
  @IsString()
  refreshToken: string;
}
