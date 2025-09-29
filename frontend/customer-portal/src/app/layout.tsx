import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'AIQSO Platform - Multi-Tenant SaaS',
  description: 'Open-source, self-hosted multi-tenant platform with modular services',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}