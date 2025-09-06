import { registerAs } from '@nestjs/config';

export default registerAs('auth', () => {
  // Ensure JWT_SECRET is set in production
  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret || (process.env.NODE_ENV === 'production' && jwtSecret.length < 32)) {
    throw new Error('JWT_SECRET must be set and be at least 32 characters long in production');
  }
  
  return {
    jwtSecret: jwtSecret || 'dev-only-weak-secret-change-in-production',
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
    refreshTokenExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '7d',
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS, 10) || 12,
    sessionTimeout: parseInt(process.env.SESSION_TIMEOUT, 10) || 3600, // 1 hour
    maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS, 10) || 5,
    lockoutDuration: parseInt(process.env.LOCKOUT_DURATION, 10) || 900, // 15 minutes
  };
});
