import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('System')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Get API status' })
  @ApiResponse({ status: 200, description: 'API is running' })
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({
    status: 200,
    description: 'Health check passed',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', example: '2024-01-01T00:00:00.000Z' },
        uptime: { type: 'number', example: 123.456 },
        version: { type: 'string', example: '1.0.0' },
        environment: { type: 'string', example: 'development' },
        database: { type: 'string', example: 'connected' },
        redis: { type: 'string', example: 'connected' }
      }
    }
  })
  async getHealth() {
    return this.appService.getHealthCheck();
  }

  @Get('version')
  @ApiOperation({ summary: 'Get API version information' })
  @ApiResponse({
    status: 200,
    description: 'Version information',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'HaroonNet ISP Platform API' },
        version: { type: 'string', example: '1.0.0' },
        description: { type: 'string', example: 'Comprehensive ISP billing and RADIUS management platform' },
        author: { type: 'string', example: 'HaroonNet Development Team' },
        license: { type: 'string', example: 'MIT' }
      }
    }
  })
  getVersion() {
    return this.appService.getVersion();
  }
}
