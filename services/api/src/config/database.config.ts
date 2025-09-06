import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  host: process.env.DB_HOST || 'mysql',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  username: process.env.DB_USER || 'haroonnet',
  password: process.env.DB_PASSWORD || 'haroonnet123',
  name: process.env.DB_NAME || 'haroonnet',
}));
