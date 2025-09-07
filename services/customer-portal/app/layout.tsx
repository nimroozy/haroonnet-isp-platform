import './globals.css'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'HaroonNet ISP - Customer Portal',
  description: 'Customer portal for HaroonNet ISP services',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <div className="min-h-screen bg-gray-50">
          <header className="bg-blue-600 text-white p-4">
            <div className="container mx-auto">
              <h1 className="text-2xl font-bold">HaroonNet ISP</h1>
              <p className="text-blue-100">Customer Portal</p>
            </div>
          </header>
          <main className="container mx-auto py-8">
            {children}
          </main>
        </div>
      </body>
    </html>
  )
}
