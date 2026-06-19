"use client";
import Link from "next/link";
import type { Report } from "@/types";
import { parseBR } from "@/lib/utils";

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

function rotulo(d: Date): { texto: string; classe: string } {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const alvo = new Date(d);
  alvo.setHours(0, 0, 0, 0);
  const dias = Math.round((alvo.getTime() - hoje.getTime()) / 86_400_000);
  if (dias < 0) return { texto: `Atrasado ${Math.abs(dias)}d`, classe: "bg-atencaoBg text-atencao" };
  if (dias === 0) return { texto: "Hoje", classe: "bg-atencaoBg text-atencao" };
  if (dias === 1) return { texto: "Amanhã", classe: "bg-verde-50 text-verde-700" };
  if (dias <= 7) return { texto: `em ${dias} dias`, classe: "bg-verde-50 text-verde-700" };
  return { texto: `em ${dias} dias`, classe: "bg-surface2 text-tintaMuda" };
}

export function Agenda({ reports }: { reports: Report[] }) {
  const itens = reports
    .map((r) => ({ r, d: parseBR(r.proximaVisita ?? "") }))
    .filter((e): e is { r: Report; d: Date } => e.d !== null)
    .sort((a, b) => a.d.getTime() - b.d.getTime());

  if (itens.length === 0) {
    return (
      <div className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda shadow-s1">
        Nenhuma visita agendada.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
      {itens.map(({ r, d }, i) => {
        const tag = rotulo(d);
        return (
          <Link
            key={r.id}
            href={`/admin/relatorios/${r.id}`}
            className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}
          >
            <div className="flex h-12 w-12 flex-none flex-col items-center justify-center rounded-[12px] bg-verde-50 text-verde-700">
              <span className="text-[17px] font-bold leading-none">{String(d.getDate()).padStart(2, "0")}</span>
              <span className="mt-0.5 font-mono text-[10px] uppercase leading-none">{MESES[d.getMonth()]}</span>
            </div>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[15px] font-semibold text-tinta">{r.condo}</div>
              <div className="truncate text-[12px] text-tintaMuda">{r.servicos.slice(0, 2).join(" · ")}</div>
            </div>
            <span className={`flex-none rounded-full px-2.5 py-1 text-[11px] font-semibold ${tag.classe}`}>
              {tag.texto}
            </span>
          </Link>
        );
      })}
    </div>
  );
}
