import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { vi } from 'vitest';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        $connect: vi.fn().mockResolvedValue(undefined),
        $disconnect: vi.fn().mockResolvedValue(undefined),
      })
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/health (GET)', async () => {
    const res = await request(app.getHttpServer())
      .get('/health')
      .expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('FlowTask API');
  });

  afterEach(async () => {
    await app.close();
  });
});
