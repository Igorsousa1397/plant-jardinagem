"use client";
import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

const SEMANA = ["D", "S", "T", "Q", "Q", "S", "S"];
const MESES = [
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
];

function iso(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

export function Calendario({
  marcados,
  selecionado,
  onPick,
}: {
  marcados: Set<string>;
  selecionado?: string;
  onPick: (d: Date) => void;
}) {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const [mes, setMes] = useState(() => new Date(hoje.getFullYear(), hoje.getMonth(), 1));

  const primeiroDiaSemana = mes.getDay();
  const diasNoMes = new Date(mes.getFullYear(), mes.getMonth() + 1, 0).getDate();

  const celulas: (Date | null)[] = [];
  for (let i = 0; i < primeiroDiaSemana; i++) celulas.push(null);
  for (let d = 1; d <= diasNoMes; d++) celulas.push(new Date(mes.getFullYear(), mes.getMonth(), d));

  const isoHoje = iso(hoje);

  return (
    <div className="rounded-2xl border border-linha bg-surface p-3 shadow-s1">
      <div className="mb-2 flex items-center justify-between px-1">
        <button
          onClick={() => setMes(new Date(mes.getFullYear(), mes.getMonth() - 1, 1))}
          aria-label="Mês anterior"
          className="grid h-8 w-8 place-items-center rounded-full text-verde-700 hover:bg-verde-50"
        >
          <ChevronLeft size={18} />
        </button>
        <span className="font-display text-[15px] font-semibold text-verde-900">
          {MESES[mes.getMonth()]} {mes.getFullYear()}
        </span>
        <button
          onClick={() => setMes(new Date(mes.getFullYear(), mes.getMonth() + 1, 1))}
          aria-label="Próximo mês"
          className="grid h-8 w-8 place-items-center rounded-full text-verde-700 hover:bg-verde-50"
        >
          <ChevronRight size={18} />
        </button>
      </div>

      <div className="grid grid-cols-7 gap-1 text-center">
        {SEMANA.map((s, i) => (
          <div key={i} className="py-1 font-mono text-[10px] font-semibold uppercase text-tintaMuda">
            {s}
          </div>
        ))}
        {celulas.map((d, i) => {
          if (!d) return <div key={i} />;
          const di = iso(d);
          const temAg = marcados.has(di);
          const ehHoje = di === isoHoje;
          const sel = di === selecionado;
          return (
            <button
              key={i}
              onClick={() => onPick(d)}
              className={cn(
                "relative mx-auto grid h-9 w-9 place-items-center rounded-full text-[13px] font-semibold",
                sel
                  ? "bg-verde-700 text-white"
                  : ehHoje
                    ? "bg-verde-50 text-verde-700 ring-1 ring-verde-300"
                    : "text-tinta hover:bg-verde-50"
              )}
            >
              {d.getDate()}
              {temAg && !sel && <span className="absolute bottom-1 h-1 w-1 rounded-full bg-dourado" />}
            </button>
          );
        })}
      </div>
    </div>
  );
}
