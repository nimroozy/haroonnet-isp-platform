import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): object {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'HaroonNet ISP API',
      version: '1.0.0',
    };
  }

  getHello(): string {
    return 'Welcome to HaroonNet ISP Platform API!';
  }
}
