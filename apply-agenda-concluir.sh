#!/usr/bin/env bash
# Plant Jardinagem — concluir agendamento + histórico por data
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando agenda: concluir + histórico..."

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0009_agendamento_concluido.sql" <<'__PLANT_EOF__'
-- Marcar agendamento como concluído (histórico)
alter table public.agendamentos
  add column if not exists concluido boolean not null default false;
__PLANT_EOF__
echo "  ok  supabase/migrations/0009_agendamento_concluido.sql"

mkdir -p "src/types"
cat > "src/types/index.ts" <<'__PLANT_EOF__'
export type Status = "Finalizado" | "Em andamento" | "Agendado" | "Atrasado";

export interface Report {
  id: string;
  condo: string;
  data: string;
  duracao: string;
  status: Status;
  servicos: string[];
  equipamentos: string[];
  epi: string[];
  observacoes: string;
  proximaVisita: string;
  fotosAntes: string[];
  fotosDepois: string[];
  arquivado?: boolean;
}

export interface Cliente {
  id: string;
  nome: string;
  sindico?: string;
  telefone?: string;
}

export interface Agendamento {
  id: string;
  clienteId?: string;
  condo: string;
  data: string;        // dd/mm/aaaa
  observacao: string;
  concluido: boolean;
}

export interface Proposta {
  id: string;
  clienteId?: string;
  condo: string;          // nome do cliente (texto livre)
  data: string;           // dd/mm/aaaa
  valorMensal: number;
  visitasMensais: number;
  equipe: number;
  servicos: string[];     // itens de manutenção selecionados
  execucao: string[];     // cláusulas de execução selecionadas (texto final)
  prazoMeses: number;
  validadeDias: number;
}

export type Papel = "admin" | "funcionario";
__PLANT_EOF__
echo "  ok  src/types/index.ts"

mkdir -p "src/lib"
cat > "src/lib/agendamentos.ts" <<'__PLANT_EOF__'
import { createClient } from "@/lib/supabase/client";
import type { Agendamento } from "@/types";
import { fmtData } from "@/lib/utils";

interface Row {
  id: string;
  cliente_id: string | null;
  condo: string;
  data: string;          // YYYY-MM-DD
  observacao: string | null;
  concluido: boolean;
}

function toAgendamento(r: Row): Agendamento {
  return {
    id: r.id,
    clienteId: r.cliente_id ?? undefined,
    condo: r.condo,
    data: fmtData(r.data),
    observacao: r.observacao ?? "",
    concluido: r.concluido ?? false,
  };
}

export async function listAgendamentos(): Promise<Agendamento[]> {
  const sb = createClient();
  const { data, error } = await sb.from("agendamentos").select("*").order("data");
  if (error) throw error;
  return (data as Row[]).map(toAgendamento);
}

export async function createAgendamento(a: {
  condo: string;
  clienteId?: string;
  dataISO: string;       // YYYY-MM-DD
  observacao?: string;
}): Promise<Agendamento> {
  const sb = createClient();
  const { data, error } = await sb
    .from("agendamentos")
    .insert({
      condo: a.condo,
      cliente_id: a.clienteId ?? null,
      data: a.dataISO,
      observacao: a.observacao ?? "",
    })
    .select("*")
    .single();
  if (error) throw error;
  return toAgendamento(data as Row);
}

export async function deleteAgendamento(id: string): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("agendamentos").delete().eq("id", id);
  if (error) throw error;
}

export async function setAgendamentoConcluido(id: string, concluido: boolean): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("agendamentos").update({ concluido }).eq("id", id);
  if (error) throw error;
}
__PLANT_EOF__
echo "  ok  src/lib/agendamentos.ts"

mkdir -p "src/components/agenda"
cat > "src/components/agenda/Calendario.tsx" <<'__PLANT_EOF__'
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
  concluidos,
  selecionado,
  onPick,
}: {
  marcados: Set<string>;
  concluidos?: Set<string>;
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
          const temConcluido = concluidos?.has(di) ?? false;
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
              {(temAg || temConcluido) && !sel && (
                <span className={cn("absolute bottom-1 h-1 w-1 rounded-full", temAg ? "bg-dourado" : "bg-verde-600")} />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/agenda/Calendario.tsx"

mkdir -p "src/components/agenda"
cat > "src/components/agenda/AgendaSection.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useMemo, useState } from "react";
import { Trash2, ChevronDown, ChevronUp, CheckCircle2, Circle, Plus } from "lucide-react";
import type { Agendamento, Cliente } from "@/types";
import { listAgendamentos, createAgendamento, deleteAgendamento, setAgendamentoConcluido } from "@/lib/agendamentos";
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
const isoDe = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

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

function rotuloDia(isoStr: string): string {
  const [y, m, d] = isoStr.split("-").map(Number);
  return `${d} de ${MES_FULL[m - 1]} de ${y}`;
}

export function AgendaSection() {
  const [ags, setAgs] = useState<Agendamento[]>([]);
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [loading, setLoading] = useState(true);

  const [calAberto, setCalAberto] = useState(false);
  const [diaSel, setDiaSel] = useState("");
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

  const marcadosPend = useMemo(() => new Set(ags.filter((a) => !a.concluido).map((a) => toISO(a.data))), [ags]);
  const concluidos = useMemo(() => new Set(ags.filter((a) => a.concluido).map((a) => toISO(a.data))), [ags]);

  const pickDia = (d: Date) => {
    setDiaSel(isoDe(d));
    setFormAberto(false);
  };

  const agendarNoDia = () => {
    setDataISO(diaSel);
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

  const alternarConcluido = async (a: Agendamento) => {
    await setAgendamentoConcluido(a.id, !a.concluido);
    setAgs((prev) => prev.map((x) => (x.id === a.id ? { ...x, concluido: !a.concluido } : x)));
  };

  // Próximas visitas (pendentes, ordenadas)
  const proximos = [...ags]
    .filter((a) => !a.concluido)
    .map((a) => ({ a, d: parseBR(a.data) }))
    .filter((x): x is { a: Agendamento; d: Date } => x.d !== null)
    .sort((x, y) => x.d.getTime() - y.d.getTime());

  // Agendamentos do dia selecionado (pendentes + concluídos)
  const doDia = diaSel
    ? ags
        .filter((a) => toISO(a.data) === diaSel)
        .sort((x, y) => Number(x.concluido) - Number(y.concluido))
    : [];

  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const proxima = proximos.find((x) => x.d.getTime() >= hoje.getTime()) ?? null;

  return (
    <div className="flex flex-col gap-3">
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
        <Calendario marcados={marcadosPend} concluidos={concluidos} selecionado={diaSel || undefined} onPick={pickDia} />
      )}

      {/* Painel do dia selecionado */}
      {calAberto && diaSel && !formAberto && (
        <div className="rounded-2xl border border-linha bg-surface p-4 shadow-s1">
          <div className="mb-2 flex items-center justify-between">
            <div className="font-display text-[15px] font-semibold text-verde-900">{rotuloDia(diaSel)}</div>
            <button onClick={() => setDiaSel("")} className="text-[12px] font-semibold text-tintaMuda">Fechar</button>
          </div>

          {doDia.length === 0 ? (
            <p className="py-2 text-[13px] text-tintaMuda">Nenhuma visita neste dia.</p>
          ) : (
            <div className="flex flex-col gap-1.5">
              {doDia.map((a) => (
                <div key={a.id} className="flex items-center gap-2.5 rounded-xl bg-surface2 px-3 py-2.5">
                  <button
                    onClick={() => alternarConcluido(a)}
                    aria-label={a.concluido ? "Marcar como pendente" : "Marcar como concluída"}
                    className={a.concluido ? "text-verde-600" : "text-tintaMuda hover:text-verde-700"}
                  >
                    {a.concluido ? <CheckCircle2 size={20} /> : <Circle size={20} />}
                  </button>
                  <div className="min-w-0 flex-1">
                    <div className={`truncate text-[14px] font-semibold ${a.concluido ? "text-tintaMuda line-through" : "text-tinta"}`}>
                      {a.condo}
                    </div>
                    <div className="truncate text-[12px] text-tintaMuda">{a.observacao || "Visita agendada"}</div>
                  </div>
                  {a.concluido && (
                    <span className="flex-none rounded-full bg-verde-50 px-2 py-0.5 text-[10px] font-semibold text-verde-700">Concluída</span>
                  )}
                  <button
                    onClick={() => remover(a.id)}
                    aria-label="Excluir"
                    className="grid h-7 w-7 flex-none place-items-center rounded-full text-tintaMuda hover:bg-erroBg hover:text-erro"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              ))}
            </div>
          )}

          <button
            onClick={agendarNoDia}
            className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-[10px] border border-dashed border-verde-400 bg-verde-50 py-2.5 text-[13px] font-semibold text-verde-700"
          >
            <Plus size={16} /> Agendar visita neste dia
          </button>
        </div>
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
      ) : proximos.length === 0 ? (
        <div className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
          Nenhuma visita agendada. Abra o calendário acima e toque num dia para agendar.
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
          {proximos.map(({ a, d }, i) => {
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
                  onClick={() => alternarConcluido(a)}
                  aria-label="Marcar como concluída"
                  className="grid h-8 w-8 flex-none place-items-center rounded-full text-tintaMuda hover:bg-verde-50 hover:text-verde-700"
                >
                  <CheckCircle2 size={18} />
                </button>
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
echo "Rode no Supabase: alter table public.agendamentos add column if not exists concluido boolean not null default false;"
echo "Depois: git add -A && git commit -m \"feat: concluir agendamento e histórico por data\" && git push"
