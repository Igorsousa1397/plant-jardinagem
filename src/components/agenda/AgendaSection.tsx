"use client";
import { useEffect, useMemo, useState } from "react";
import { Trash2 } from "lucide-react";
import type { Agendamento, Cliente } from "@/types";
import { listAgendamentos, createAgendamento, deleteAgendamento } from "@/lib/agendamentos";
import { listClientes } from "@/lib/clientes";
import { toISO, parseBR } from "@/lib/utils";
import { Calendario } from "./Calendario";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const MES_CURTO = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];
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

  const [aberto, setAberto] = useState(false);
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
    setAberto(true);
  };

  const salvar = async () => {
    if (!dataISO || !condo) return;
    setSalvando(true);
    try {
      const cli = clientes.find((c) => c.nome === condo);
      await createAgendamento({ condo, clienteId: cli?.id, dataISO, observacao: obs });
      setObs("");
      setAberto(false);
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

  return (
    <div className="flex flex-col gap-3">
      <Calendario marcados={marcados} selecionado={aberto ? dataISO : undefined} onPick={abrirEm} />

      {aberto && (
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
            <Button variant="ghost" onClick={() => setAberto(false)}>Cancelar</Button>
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
          Nenhuma visita agendada. Toque num dia do calendário para agendar.
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
