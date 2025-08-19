import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Insight Hunter",
  description: "Financial Insights Made Simple",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
