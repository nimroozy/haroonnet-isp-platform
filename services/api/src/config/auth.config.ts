import { registerAs } from '@nestjs/config';

export default registerAs('auth', () => ({
  // Do NOT fallback to a weak default secret in production.
  // Force the JWT_SECRET environment variable to be set.
  jwtSecret: process.env.JWT_SECRET ?? (() => { throw new Error('JWT_SECRET environment variable is required'); })(),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
  refreshTokenExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '7d',
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS, 10) || 12,
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT, 10) || 3600, // 1 hour
  maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS, 10) || 5,
  lockoutDuration: parseInt(process.env.LOCKOUT_DURATION, 10) || 900, // 15 minutes
}));
