"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import type { Proposta } from "@/types";
import { listPropostas } from "@/lib/propostas";
import { PropostaCard } from "@/components/propostas/PropostaCard";

export default function PropostasPage() {
  const [propostas, setPropostas] = useState<Proposta[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listPropostas().then(setPropostas).finally(() => setLoading(false));
  }, []);

  return (
    <div className="pb-28">
      <header className="px-[18px] pb-2 pt-5">
        <div className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Admin · Claiton</div>
        <h1 className="mt-0.5 font-display text-[28px] font-semibold tracking-tight text-verde-900">Propostas</h1>
      </header>

      <section className="px-[18px]">
        {loading ? (
          <div className="flex flex-col gap-3.5">
            <div className="h-24 animate-pulse rounded-2xl border border-linha bg-surface2" />
            <div className="h-24 animate-pulse rounded-2xl border border-linha bg-surface2" />
          </div>
        ) : propostas.length === 0 ? (
          <p className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
            Nenhuma proposta ainda. Toque no + para criar a primeira.
          </p>
        ) : (
          <div className="flex flex-col gap-3.5">
            {propostas.map((p) => <PropostaCard key={p.id} p={p} />)}
          </div>
        )}
      </section>

      <div className="pointer-events-none fixed inset-x-0 bottom-[84px] z-30 mx-auto flex max-w-md justify-end px-[18px]">
        <Link href="/admin/propostas/nova" aria-label="Nova proposta" className="pointer-events-auto grid h-14 w-14 place-items-center rounded-full bg-verde-700 text-[28px] text-white shadow-s3">+</Link>
      </div>
    </div>
  );
}
