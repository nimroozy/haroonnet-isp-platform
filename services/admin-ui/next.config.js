/** @type {import('next').NextConfig} */
const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

const nextConfig = {
  output: 'standalone',
  experimental: {
    serverComponentsExternalPackages: ['@tanstack/react-query'],
  },
  env: {
    NEXT_PUBLIC_API_URL: apiUrl,
  },
  images: {
    domains: ['localhost'],
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${apiUrl}/api/v1/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
