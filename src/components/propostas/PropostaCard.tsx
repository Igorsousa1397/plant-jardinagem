"use client";
import Link from "next/link";
import type { Proposta } from "@/types";
import { fmtBRL } from "@/lib/utils";

export function PropostaCard({ p }: { p: Proposta }) {
  return (
    <Link href={`/admin/propostas/${p.id}`} className="block rounded-2xl border border-linha bg-surface p-4 shadow-s1">
      <div className="flex items-start justify-between gap-2">
        <div className="font-display text-[16px] font-semibold text-verde-900">{p.condo}</div>
        <div className="flex-none font-mono text-[11px] text-tintaMuda">{p.data}</div>
      </div>
      <div className="mt-1 text-[13px] text-tintaMuda">
        Manutenção · {p.visitasMensais} visitas/mês · equipe de {p.equipe}
      </div>
      <div className="mt-2 text-[18px] font-bold text-verde-700">
        {fmtBRL(p.valorMensal)}
        <span className="text-[12px] font-medium text-tintaMuda"> / mês</span>
      </div>
    </Link>
  );
}
