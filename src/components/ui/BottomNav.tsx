"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const items = [
  { href: "/admin/home", label: "Home", path: "M3 11l9-8 9 8M5 9v11h5v-6h4v6h5V9" },
  { href: "/admin/propostas", label: "Propostas", path: "M6 2h9l4 4v16H6z M9 12h7M9 16h5" },
  { href: "/admin/financeiro", label: "Financeiro", path: "M12 1v22M6 6h9a3 3 0 010 6H8a3 3 0 000 6h11" },
  { href: "/admin/ponto", label: "Ponto", path: "M12 3a9 9 0 100 18 9 9 0 000-18z M12 8v4l3 2" },
];

export function BottomNav() {
  const pathname = usePathname();
  if (pathname.endsWith("/novo") || pathname.endsWith("/editar")) return null;

  return (
    <nav className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md border-t border-linha bg-surface px-2 pb-3 pt-2">
      {items.map((it) => {
        const on =
          pathname.startsWith(it.href) ||
          (it.href === "/admin/home" && pathname.startsWith("/admin/relatorios"));
        return (
          <Link
            key={it.href}
            href={it.href}
            className={cn(
              "flex flex-1 flex-col items-center gap-1 rounded-[10px] px-1 py-[7px] text-[11px] font-semibold",
              on ? "bg-verde-50 text-verde-700" : "text-tintaMuda"
            )}
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round">
              <path d={it.path} />
            </svg>
            {it.label}
          </Link>
        );
      })}
    </nav>
  );
}
