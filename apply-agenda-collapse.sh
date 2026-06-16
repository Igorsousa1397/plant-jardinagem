#!/usr/bin/env bash
# Plant Jardinagem — calendário recolhível (faixa com hoje + próxima visita)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Atualizando agenda..."

cat > "src/components/agenda/AgendaSection.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useMemo, useState } from "react";
import { Trash2, ChevronDown, ChevronUp } from "lucide-react";
import type { Agendamento, Cliente } from "@/types";
import { listAgendamentos, createAgendamento, deleteAgendamento } from "@/lib/agendamentos";
import { listClientes } from "@/lib/clientes";
import { toISO, parseBR } from "@/lib/utils";
import { Calendario } from "./Calendario";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const MES_CURTO = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];
const MES_FULL = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
];
const pad = (n: number) => String(n).padStart(2, "0");

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

export function AgendaSection() {
  const [ags, setAgs] = useState<Agendamento[]>([]);
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [loading, setLoading] = useState(true);

  const [calAberto, setCalAberto] = useState(false);
  const [formAberto, setFormAberto] = useState(false);
  const [dataISO, setDataISO] = useState("");
  const [condo, setCondo] = useState("");
  const [obs, setObs] = useState("");
  const [salvando, setSalvando] = useState(false);

  const carregar = async () => {
    setLoading(true);
    try {
      const [a, c] = await Promise.all([listAgendamentos(), listClientes()]);
      setAgs(a);
      setClientes(c);
      setCondo((atual) => atual || c[0]?.nome || "");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    carregar();
  }, []);

  const marcados = useMemo(() => new Set(ags.map((a) => toISO(a.data))), [ags]);

  const abrirEm = (d: Date) => {
    setDataISO(`${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`);
    setCondo((atual) => atual || clientes[0]?.nome || "");
    setFormAberto(true);
  };

  const salvar = async () => {
    if (!dataISO || !condo) return;
    setSalvando(true);
    try {
      const cli = clientes.find((c) => c.nome === condo);
      await createAgendamento({ condo, clienteId: cli?.id, dataISO, observacao: obs });
      setObs("");
      setFormAberto(false);
      await carregar();
    } finally {
      setSalvando(false);
    }
  };

  const remover = async (id: string) => {
    await deleteAgendamento(id);
    setAgs((prev) => prev.filter((a) => a.id !== id));
  };

  const ordenados = [...ags]
    .map((a) => ({ a, d: parseBR(a.data) }))
    .filter((x): x is { a: Agendamento; d: Date } => x.d !== null)
    .sort((x, y) => x.d.getTime() - y.d.getTime());

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const proxima = ordenados.find((x) => x.d.getTime() >= hoje.getTime()) ?? null;

  return (
    <div className="flex flex-col gap-3">
      {/* Faixa-resumo: hoje + próxima visita. Toque para abrir o calendário. */}
      <button
        onClick={() => setCalAberto((o) => !o)}
        className="flex items-center gap-3 rounded-2xl border border-linha bg-surface p-3.5 text-left shadow-s1"
      >
        <div className="flex h-11 w-11 flex-none flex-col items-center justify-center rounded-[12px] bg-verde-700 text-white">
          <span className="text-[16px] font-bold leading-none">{pad(hoje.getDate())}</span>
          <span className="mt-0.5 font-mono text-[9px] uppercase leading-none">{MES_CURTO[hoje.getMonth()]}</span>
        </div>
        <div className="min-w-0 flex-1">
          <div className="text-[14px] font-semibold text-tinta">
            Hoje · {hoje.getDate()} de {MES_FULL[hoje.getMonth()]}
          </div>
          <div className="truncate text-[12px] text-tintaMuda">
            {proxima
              ? `Próxima: ${proxima.a.condo} · ${pad(proxima.d.getDate())} ${MES_CURTO[proxima.d.getMonth()]}`
              : "Nenhuma visita agendada"}
          </div>
        </div>
        {calAberto ? (
          <ChevronUp size={18} className="flex-none text-tintaMuda" />
        ) : (
          <ChevronDown size={18} className="flex-none text-tintaMuda" />
        )}
      </button>

      {calAberto && (
        <Calendario marcados={marcados} selecionado={formAberto ? dataISO : undefined} onPick={abrirEm} />
      )}

      {formAberto && (
        <div className="rounded-2xl border border-linha bg-surface p-4 shadow-s1">
          <div className="mb-3 font-display text-[16px] font-semibold text-verde-900">Agendar visita</div>
          <Field label="Cliente">
            <select value={condo} onChange={(e) => setCondo(e.target.value)} className={inputClass}>
              {clientes.map((c) => (
                <option key={c.id}>{c.nome}</option>
              ))}
            </select>
          </Field>
          <Field label="Data">
            <input type="date" value={dataISO} onChange={(e) => setDataISO(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Observação (opcional)">
            <input
              value={obs}
              onChange={(e) => setObs(e.target.value)}
              className={inputClass}
              placeholder="Ex: levar equipe completa"
            />
          </Field>
          <div className="flex gap-2">
            <Button variant="ghost" onClick={() => setFormAberto(false)}>Cancelar</Button>
            <Button block disabled={salvando} onClick={salvar}>
              {salvando ? "Salvando…" : "Agendar"}
            </Button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="animate-pulse rounded-2xl border border-linha bg-surface2" style={{ height: 64 }} />
      ) : ordenados.length === 0 ? (
        <div className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
          Nenhuma visita agendada. Abra o calendário acima e toque num dia para agendar.
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
          {ordenados.map(({ a, d }, i) => {
            const tag = rotulo(d);
            return (
              <div key={a.id} className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}>
                <div className="flex h-12 w-12 flex-none flex-col items-center justify-center rounded-[12px] bg-verde-50 text-verde-700">
                  <span className="text-[17px] font-bold leading-none">{pad(d.getDate())}</span>
                  <span className="mt-0.5 font-mono text-[10px] uppercase leading-none">{MES_CURTO[d.getMonth()]}</span>
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[15px] font-semibold text-tinta">{a.condo}</div>
                  <div className="truncate text-[12px] text-tintaMuda">{a.observacao || "Visita agendada"}</div>
                </div>
                <span className={`flex-none rounded-full px-2.5 py-1 text-[11px] font-semibold ${tag.classe}`}>
                  {tag.texto}
                </span>
                <button
                  onClick={() => remover(a.id)}
                  aria-label="Excluir agendamento"
                  className="grid h-8 w-8 flex-none place-items-center rounded-full text-tintaMuda hover:bg-erroBg hover:text-erro"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/agenda/AgendaSection.tsx"
echo ""
echo "Feito. Reinicie o npm run dev (ou commit + push)."
