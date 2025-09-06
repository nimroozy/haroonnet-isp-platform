/** @type {import('next').NextConfig} */
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';
const nextConfig = {
  output: 'standalone',
  serverExternalPackages: ['@tanstack/react-query'],
  env: {
    NEXT_PUBLIC_API_URL: API_URL,
  },
  images: {
    domains: ['localhost'],
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${API_URL}/api/v1/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
