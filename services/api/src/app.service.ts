import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import Redis from 'ioredis';

@Injectable()
export class AppService {
  private redis: Redis;

  constructor(
    private configService: ConfigService,
    @InjectDataSource() private dataSource: DataSource,
  ) {
    this.redis = new Redis({
      host: this.configService.get('redis.host'),
      port: this.configService.get('redis.port'),
      password: this.configService.get('redis.password'),
      retryDelayOnFailover: 100,
      maxRetriesPerRequest: 3,
    });
  }

  getHello(): string {
    return 'HaroonNet ISP Platform API is running! 🚀';
  }

  async getHealthCheck() {
    const startTime = Date.now();

    // Check database connection
    let databaseStatus = 'disconnected';
    try {
      await this.dataSource.query('SELECT 1');
      databaseStatus = 'connected';
    } catch (error) {
      databaseStatus = 'error';
    }

    // Check Redis connection
    let redisStatus = 'disconnected';
    try {
      await this.redis.ping();
      redisStatus = 'connected';
    } catch (error) {
      redisStatus = 'error';
    }

    const responseTime = Date.now() - startTime;

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: this.getVersion().version,
      environment: this.configService.get('NODE_ENV'),
      database: databaseStatus,
      redis: redisStatus,
      responseTime: `${responseTime}ms`,
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        external: Math.round(process.memoryUsage().external / 1024 / 1024),
      },
    };
  }

  getVersion() {
    // In a real application, this would be read from package.json
    return {
      name: 'HaroonNet ISP Platform API',
      version: '1.0.0',
      description: 'Comprehensive ISP billing and RADIUS management platform',
      author: 'HaroonNet Development Team',
      license: 'MIT',
      buildDate: new Date().toISOString(),
      nodeVersion: process.version,
      platform: process.platform,
      architecture: process.arch,
    };
  }
}
