import { registerAs } from '@nestjs/config';

export default registerAs('database', () => {
  // Ensure database credentials are set in production
  if (process.env.NODE_ENV === 'production') {
    if (!process.env.DB_PASSWORD || process.env.DB_PASSWORD.length < 12) {
      throw new Error('DB_PASSWORD must be set and be at least 12 characters long in production');
    }
    if (!process.env.DB_USER || process.env.DB_USER === 'haroonnet') {
      throw new Error('DB_USER must be set to a secure username in production (not default)');
    }
  }

  return {
    host: process.env.DB_HOST || 'mysql',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    username: process.env.DB_USER || 'haroonnet',
    password: process.env.DB_PASSWORD || 'dev-only-weak-password',
    name: process.env.DB_NAME || 'haroonnet',
  };
});
