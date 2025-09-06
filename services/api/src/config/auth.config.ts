import { registerAs } from '@nestjs/config';

export default registerAs('auth', () => ({
  // Do not fall back to a weak hardcoded default; require explicit secret in production
  jwtSecret:
    process.env.JWT_SECRET ||
    (process.env.NODE_ENV === 'production'
      ? (() => {
          throw new Error('JWT_SECRET must be set in production');
        })()
      : 'dev-insecure-secret'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
  refreshTokenExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '7d',
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS, 10) || 12,
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT, 10) || 3600, // 1 hour
  maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS, 10) || 5,
  lockoutDuration: parseInt(process.env.LOCKOUT_DURATION, 10) || 900, // 15 minutes
}));
