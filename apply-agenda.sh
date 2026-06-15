#!/usr/bin/env bash
# Plant Jardinagem — agenda com calendário (agendamentos)
set -e

if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando agenda/calendário..."

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0003_agendamentos.sql" <<'__PLANT_EOF__'
-- Agendamentos (visitas planejadas) — independentes dos relatórios

create table if not exists public.agendamentos (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  uuid references public.clientes(id) on delete set null,
  condo       text not null,
  data        date not null,
  observacao  text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists agendamentos_data_idx on public.agendamentos (data);

alter table public.agendamentos enable row level security;

drop policy if exists agendamentos_auth_all on public.agendamentos;
create policy agendamentos_auth_all on public.agendamentos
  for all to authenticated using (true) with check (true);
__PLANT_EOF__
echo "  ok  supabase/migrations/0003_agendamentos.sql"

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
}

function toAgendamento(r: Row): Agendamento {
  return {
    id: r.id,
    clienteId: r.cliente_id ?? undefined,
    condo: r.condo,
    data: fmtData(r.data),
    observacao: r.observacao ?? "",
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
__PLANT_EOF__
echo "  ok  src/components/agenda/Calendario.tsx"

mkdir -p "src/components/agenda"
cat > "src/components/agenda/AgendaSection.tsx" <<'__PLANT_EOF__'
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
__PLANT_EOF__
echo "  ok  src/components/agenda/AgendaSection.tsx"

mkdir -p "src/app/admin/home"
cat > "src/app/admin/home/page.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import { AgendaSection } from "@/components/agenda/AgendaSection";

export default function HomePage() {
  const { reports, loading, error } = useReports();

  return (
    <div className="pb-28">
      <header className="flex items-start justify-between px-[18px] pb-2 pt-5">
        <div>
          <div className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Admin · Claiton</div>
          <h1 className="mt-0.5 font-display text-[28px] font-semibold tracking-tight text-verde-900">Home</h1>
        </div>
        <Link
          href="/admin/perfil"
          aria-label="Perfil"
          className="grid h-10 w-10 place-items-center rounded-full bg-verde-700 text-sm font-bold text-white shadow-s1"
        >
          CL
        </Link>
      </header>

      {error && (
        <p className="mx-[18px] rounded-[10px] bg-erroBg px-3 py-2 text-sm font-medium text-erro">{error}</p>
      )}

      <section className="px-[18px]">
        <h2 className="pb-2 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">
          Agenda · próximos clientes
        </h2>
        <AgendaSection />
      </section>

      <section className="px-[18px]">
        <h2 className="pb-2 pt-6 font-mono text-[11px] uppercase tracking-wider text-verde-600">Relatórios</h2>
        {loading ? (
          <div className="flex flex-col gap-3.5">
            <Skeleton h={180} />
            <Skeleton h={180} />
          </div>
        ) : reports.length === 0 ? (
          <p className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
            Nenhum relatório ainda. Toque no + para criar o primeiro.
          </p>
        ) : (
          <div className="flex flex-col gap-3.5">
            {reports.map((r) => <ReportCard key={r.id} r={r} />)}
          </div>
        )}
      </section>

      <div className="pointer-events-none fixed inset-x-0 bottom-[84px] z-30 mx-auto flex max-w-md justify-end px-[18px]">
        <Link
          href="/admin/relatorios/novo"
          aria-label="Novo relatório"
          className="pointer-events-auto grid h-14 w-14 place-items-center rounded-full bg-verde-700 text-[28px] text-white shadow-s3"
        >+</Link>
      </div>
    </div>
  );
}

function Skeleton({ h }: { h: number }) {
  return <div className="animate-pulse rounded-2xl border border-linha bg-surface2" style={{ height: h }} />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/home/page.tsx"

echo ""
echo "Falta: rodar supabase/migrations/0003_agendamentos.sql no Supabase"
echo "e (opcional) limpar os dados mockados. Depois reinicie o npm run dev."
