import type { Metadata, Viewport } from "next";
import { Urbanist, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";
import { Splash } from "@/components/ui/Splash";

const urbanist = Urbanist({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-ui",
  display: "swap",
});
const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Plant Jardinagem",
  description: "Relatórios, propostas, financeiro e ponto — Plant Jardinagem e Paisagismo.",
  manifest: "/manifest.webmanifest",
};

export const viewport: Viewport = {
  themeColor: "#1E3A2B",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR" className={`${urbanist.variable} ${mono.variable}`}>
      <body className="font-sans">
        <Splash />
        {children}
      </body>
    </html>
  );
}
