import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { RegisterDto, LoginDto } from './dto/auth.dto.js';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ── 注册 ──────────────────────────────────────────────
  async register(dto: RegisterDto) {
    if (!dto.phone && !dto.email) {
      throw new BadRequestException('手机号或邮箱至少填写一项');
    }

    // 检查已存在
    if (dto.phone) {
      const existing = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
      if (existing) throw new ConflictException('该手机号已注册');
    }
    if (dto.email) {
      const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (existing) throw new ConflictException('该邮箱已注册');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email: dto.email,
        nickname: dto.nickname || 'FlowTask用户',
        passwordHash,
      },
    });

    return this.generateTokens(user.id);
  }

  // ── 登录 ──────────────────────────────────────────────
  async login(dto: LoginDto) {
    if (!dto.phone && !dto.email) {
      throw new BadRequestException('手机号或邮箱至少填写一项');
    }

    const user = await this.prisma.user.findFirst({
      where: dto.phone ? { phone: dto.phone } : { email: dto.email },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('账号或密码错误');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('账号或密码错误');
    }

    return this.generateTokens(user.id);
  }

  // ── 刷新 Token ────────────────────────────────────────
  async refreshToken(token: string) {
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
      return this.generateTokens(payload.sub);
    } catch {
      throw new UnauthorizedException('Refresh Token 无效或已过期');
    }
  }

  // ── 获取当前用户 ────────────────────────────────────────
  async getProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        email: true,
        nickname: true,
        avatar: true,
        isPro: true,
        proExpireAt: true,
        createdAt: true,
      },
    });
  }

  // ── 内部：生成 Token 对 ──────────────────────────────────
  private generateTokens(userId: string) {
    const payload = { sub: userId };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: 7 * 24 * 60 * 60, // 7 天
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: 30 * 24 * 60 * 60, // 30 天
    });

    return { accessToken, refreshToken };
  }
}
