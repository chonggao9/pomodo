import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('系统')
@Controller()
export class AppController {
  @Get('health')
  @ApiOperation({ summary: '健康检查' })
  health() {
    return {
      status: 'ok',
      service: 'FlowTask API',
      version: '0.1.0',
      timestamp: new Date().toISOString(),
    };
  }
}
