"use client";
import { useEffect, useState } from "react";
import type { Proposta } from "@/types";
import { getProposta } from "@/lib/propostas";
import { PropostaForm } from "@/components/propostas/PropostaForm";

export default function EditarPropostaPage({ params }: { params: { id: string } }) {
  const [p, setP] = useState<Proposta | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProposta(params.id).then(setP).finally(() => setLoading(false));
  }, [params.id]);

  if (loading) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Carregando…</div>;
  if (!p) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Proposta não encontrada.</div>;
  return <PropostaForm inicial={p} />;
}
