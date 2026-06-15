#!/usr/bin/env bash
# Plant Jardinagem — ícones da navegação inferior (lucide-react)
# IMPORTANTE: rode antes  ->  npm install lucide-react
set -e

if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
if ! grep -q "lucide-react" package.json; then
  echo "AVISO: lucide-react não está instalado. Rode:  npm install lucide-react"
fi
echo "Atualizando ícones da navegação..."

mkdir -p "src/components/ui"
cat > "src/components/ui/BottomNav.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, FileText, Wallet, Clock, type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

const items: { href: string; label: string; Icon: LucideIcon }[] = [
  { href: "/admin/home", label: "Home", Icon: Home },
  { href: "/admin/propostas", label: "Propostas", Icon: FileText },
  { href: "/admin/financeiro", label: "Financeiro", Icon: Wallet },
  { href: "/admin/ponto", label: "Ponto", Icon: Clock },
];

export function BottomNav() {
  const pathname = usePathname();
  // Formulários têm barra de ação própria — escondem a navegação.
  if (pathname.endsWith("/novo") || pathname.endsWith("/editar")) return null;

  return (
    <nav className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md border-t border-linha bg-surface px-2 pb-3 pt-2">
      {items.map(({ href, label, Icon }) => {
        const on =
          pathname.startsWith(href) ||
          (href === "/admin/home" && pathname.startsWith("/admin/relatorios"));
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex flex-1 flex-col items-center gap-1 rounded-[10px] px-1 py-[7px] text-[11px] font-semibold",
              on ? "bg-verde-50 text-verde-700" : "text-tintaMuda"
            )}
          >
            <Icon size={22} strokeWidth={on ? 2.4 : 2} />
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
__PLANT_EOF__
echo "  ok  src/components/ui/BottomNav.tsx"
echo ""
echo "Feito. Reinicie o npm run dev se estiver rodando."
