import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Park at Balboa Park — Free & Paid Parking Guide',
  description:
    'Find the best parking spot at Balboa Park, San Diego. Free and paid parking recommendations based on where you are going and who you are.',
  icons: {
    icon: '/favicon.svg',
  },
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} h-screen overflow-hidden bg-stone-50`}>
        {children}
      </body>
    </html>
  )
}
