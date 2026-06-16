"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Trash2 } from "lucide-react";
import type { Proposta } from "@/types";
import { getProposta, deleteProposta } from "@/lib/propostas";
import { fmtBRL, dataExtenso } from "@/lib/utils";
import { PROPOSTA, ESCOPOS, ESCOPO_PADRAO } from "@/lib/proposta-conteudo";
import { Button } from "@/components/ui/Button";

export function PropostaPreview({ id }: { id: string }) {
  const router = useRouter();
  const [p, setP] = useState<Proposta | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProposta(id).then(setP).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Carregando…</div>;
  if (!p) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Proposta não encontrada.</div>;

  const remover = async () => {
    await deleteProposta(p.id);
    router.push("/admin/propostas");
  };
  const enviar = () => {
    const txt = encodeURIComponent(
      `Olá! Segue a proposta comercial da Plant Jardinagem para o ${p.condo}. Investimento: ${fmtBRL(p.valorMensal)} / mês.`
    );
    window.open(`https://wa.me/?text=${txt}`, "_blank");
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.push("/admin/propostas")} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="flex-1 font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Proposta</span>
        <button onClick={remover} aria-label="Excluir" className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-tintaMuda hover:bg-erroBg hover:text-erro">
          <Trash2 size={16} />
        </button>
      </header>

      <article className="mx-3.5 mt-1.5 overflow-hidden rounded-[18px] border border-linha bg-surface shadow-s2">
        <div className="bg-salvia px-5 py-6 text-white">
          <div className="font-display text-[26px] font-semibold leading-tight">Proposta Comercial</div>
          <div className="mt-0.5 text-[15px] opacity-95">{p.condo}</div>
          <div className="mt-1 font-mono text-[11px] opacity-80">São Paulo, {dataExtenso(p.data)}.</div>
        </div>

        <div className="space-y-4 p-5">
          <p className="text-[13px] leading-relaxed text-tintaMuda">{PROPOSTA.intro}</p>

          <div>
            <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Investimento</h3>
            <div className="mt-1 text-[24px] font-bold text-verde-700">
              {fmtBRL(p.valorMensal)}
              <span className="text-[13px] font-medium text-tintaMuda"> / mês</span>
            </div>
          </div>

          <div>
            <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Execução do serviço</h3>
            <ul className="mt-1 list-disc space-y-1.5 pl-5 text-[13px] leading-relaxed text-tinta">
              {(ESCOPOS[p.escopo] ?? ESCOPOS[ESCOPO_PADRAO]).execucao.map((l, i) => (
                <li key={i}>{l}</li>
              ))}
            </ul>
          </div>

          <div className="border-t border-linha pt-3 text-[12px] text-tintaMuda">
            Prazo do contrato: {p.prazoMeses} meses · Validade da proposta: {p.validadeDias} dias
          </div>
        </div>
      </article>

      <div className="flex gap-3 px-[18px] py-2">
        <Button variant="gold" block onClick={() => window.open(`/api/propostas/${p.id}/pdf`, "_blank")}>Gerar PDF</Button>
        <Button block onClick={enviar}>Enviar</Button>
      </div>
    </div>
  );
}
