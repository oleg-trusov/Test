import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'LUMÉA Suite',
    template: '%s | LUMÉA Suite',
  },
  description: 'Booking, calendar and CRM platform for service businesses.',
  applicationName: 'LUMÉA Suite',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="cs">
      <body>{children}</body>
    </html>
  );
}
