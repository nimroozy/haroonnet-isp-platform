import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';
import { Toaster } from '@/components/ui/sonner';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'HaroonNet ISP Platform - Admin Portal',
  description: 'Comprehensive ISP billing and RADIUS management platform',
  keywords: ['ISP', 'RADIUS', 'Billing', 'Management', 'Mikrotik'],
  authors: [{ name: 'HaroonNet Development Team' }],
  viewport: 'width=device-width, initial-scale=1',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          <div className="min-h-screen bg-background font-sans antialiased">
            {children}
          </div>
          <Toaster />
        </Providers>
      </body>
    </html>
  );
}
