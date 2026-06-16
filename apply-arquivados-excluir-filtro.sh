#!/usr/bin/env bash
# Plant Jardinagem — excluir relatório arquivado + filtro por mês
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando exclusão + filtro de mês nos arquivados..."

mkdir -p "src/lib"
cat > "src/lib/relatorios.ts" <<'__PLANT_EOF__'
import { createClient } from "@/lib/supabase/client";
import type { Report, Status } from "@/types";
import { fmtData, toISO } from "@/lib/utils";

interface RelatorioRow {
  id: string;
  condo: string;
  cliente_id: string | null;
  data: string;            // YYYY-MM-DD
  duracao: string;
  status: Status;
  servicos: string[];
  equipamentos: string[];
  epi: string[];
  observacoes: string | null;
  proxima_visita: string | null;
  fotos_antes: string[] | null;
  fotos_depois: string[] | null;
  arquivado: boolean;
}

function rowToReport(r: RelatorioRow): Report {
  return {
    id: r.id,
    condo: r.condo,
    data: fmtData(r.data),
    duracao: r.duracao,
    status: r.status,
    servicos: r.servicos ?? [],
    equipamentos: r.equipamentos ?? [],
    epi: r.epi ?? [],
    observacoes: r.observacoes ?? "",
    proximaVisita: r.proxima_visita ? fmtData(r.proxima_visita) : "",
    fotosAntes: r.fotos_antes ?? [],
    fotosDepois: r.fotos_depois ?? [],
    arquivado: r.arquivado,
  };
}

function reportToRow(r: Omit<Report, "id">) {
  return {
    condo: r.condo,
    data: toISO(r.data),
    duracao: r.duracao,
    status: r.status,
    servicos: r.servicos,
    equipamentos: r.equipamentos,
    epi: r.epi,
    observacoes: r.observacoes,
    proxima_visita: r.proximaVisita ? toISO(r.proximaVisita) : null,
    fotos_antes: r.fotosAntes,
    fotos_depois: r.fotosDepois,
    arquivado: r.arquivado ?? false,
  };
}

export async function listRelatorios(): Promise<Report[]> {
  const sb = createClient();
  const { data, error } = await sb
    .from("relatorios")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data as RelatorioRow[]).map(rowToReport);
}

export async function getRelatorio(id: string): Promise<Report | null> {
  const sb = createClient();
  const { data, error } = await sb.from("relatorios").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  return data ? rowToReport(data as RelatorioRow) : null;
}

export async function createRelatorio(r: Omit<Report, "id">): Promise<Report> {
  const sb = createClient();
  const { data, error } = await sb.from("relatorios").insert(reportToRow(r)).select("*").single();
  if (error) throw error;
  return rowToReport(data as RelatorioRow);
}

export async function updateRelatorio(id: string, patch: Partial<Omit<Report, "id">>): Promise<void> {
  const sb = createClient();
  // converte apenas os campos presentes
  const full = { ...patch } as Omit<Report, "id">;
  const row = reportToRow(full);
  const { error } = await sb.from("relatorios").update(row).eq("id", id);
  if (error) throw error;
}

export async function setArquivado(id: string, arquivado: boolean): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("relatorios").update({ arquivado }).eq("id", id);
  if (error) throw error;
}

export async function deleteRelatorio(id: string): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("relatorios").delete().eq("id", id);
  if (error) throw error;
}
__PLANT_EOF__
echo "  ok  src/lib/relatorios.ts"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/store.tsx" <<'__PLANT_EOF__'
"use client";
import { createContext, useCallback, useContext, useEffect, useState } from "react";
import type { Report } from "@/types";
import * as api from "@/lib/relatorios";

interface Ctx {
  reports: Report[];      // ativos
  arquivados: Report[];
  loading: boolean;
  error: string | null;
  add: (r: Omit<Report, "id">) => Promise<Report>;
  update: (id: string, patch: Omit<Report, "id">) => Promise<void>;
  archive: (id: string) => Promise<void>;
  unarchive: (id: string) => Promise<void>;
  remove: (id: string) => Promise<void>;
  get: (id: string) => Report | undefined;
  refresh: () => Promise<void>;
}

const ReportsContext = createContext<Ctx | null>(null);

export function ReportsProvider({ children }: { children: React.ReactNode }) {
  const [all, setAll] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      setAll(await api.listRelatorios());
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao carregar relatórios.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const add: Ctx["add"] = async (r) => {
    const novo = await api.createRelatorio(r);
    setAll((prev) => [novo, ...prev]);
    return novo;
  };
  const update: Ctx["update"] = async (id, patch) => {
    await api.updateRelatorio(id, patch);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, ...patch, id } : x)));
  };
  const archive: Ctx["archive"] = async (id) => {
    await api.setArquivado(id, true);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, arquivado: true } : x)));
  };
  const unarchive: Ctx["unarchive"] = async (id) => {
    await api.setArquivado(id, false);
    setAll((prev) => prev.map((x) => (x.id === id ? { ...x, arquivado: false } : x)));
  };
  const remove: Ctx["remove"] = async (id) => {
    await api.deleteRelatorio(id);
    setAll((prev) => prev.filter((x) => x.id !== id));
  };
  const get: Ctx["get"] = (id) => all.find((x) => x.id === id);

  const reports = all.filter((x) => !x.arquivado);
  const arquivados = all.filter((x) => x.arquivado);

  return (
    <ReportsContext.Provider
      value={{ reports, arquivados, loading, error, add, update, archive, unarchive, remove, get, refresh }}
    >
      {children}
    </ReportsContext.Provider>
  );
}

export function useReports() {
  const ctx = useContext(ReportsContext);
  if (!ctx) throw new Error("useReports precisa estar dentro de <ReportsProvider>");
  return ctx;
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/store.tsx"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportCard.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { Badge } from "@/components/ui/Badge";
import { KebabMenu, type MenuItem } from "@/components/ui/KebabMenu";
import { GardenSVG } from "./GardenSVG";
import { useReports } from "./store";

export function ReportCard({ r, archived }: { r: Report; archived?: boolean }) {
  const router = useRouter();
  const { archive, unarchive, remove } = useReports();

  const excluir = () => {
    if (confirm(`Excluir o relatório de ${r.condo}? Esta ação não pode ser desfeita.`)) remove(r.id);
  };

  const menu: MenuItem[] = archived
    ? [
        { label: "Editar", onSelect: () => router.push(`/admin/relatorios/${r.id}/editar`) },
        { label: "Desarquivar", onSelect: () => unarchive(r.id) },
        { label: "Excluir", onSelect: excluir, danger: true },
      ]
    : [
        { label: "Editar", onSelect: () => router.push(`/admin/relatorios/${r.id}/editar`) },
        { label: "Arquivar", onSelect: () => archive(r.id), danger: true },
      ];

  return (
    <div className="relative rounded-2xl border border-linha bg-surface shadow-s2">
      {/* Link "esticado" cobre o card sem aninhar botões dentro de <a>. */}
      <Link
        href={`/admin/relatorios/${r.id}`}
        aria-label={`Abrir ${r.condo}`}
        className="absolute inset-0 z-0 rounded-2xl"
      />

      <div className="pointer-events-none">
        <div className="grid grid-cols-2 gap-0.5 overflow-hidden rounded-t-2xl bg-linha">
          <Thumb url={r.fotosAntes[0]} label="ANTES" />
          <Thumb url={r.fotosDepois[0]} label="DEPOIS" depois />
        </div>
        <div className="p-3.5">
          <div className="flex items-start justify-between gap-2.5">
            <h3 className="font-display text-[17px] font-semibold text-verde-900">{r.condo}</h3>
            <Badge status={r.status} small />
          </div>
          <p className="mt-0.5 text-[13px] text-tintaMuda">
            {r.servicos.slice(0, 2).join(" · ")} · {r.duracao}
          </p>
          <p className="mt-2.5 flex items-center gap-1.5 text-[13px] font-semibold text-verde-700">
            <CalIcon /> Próxima visita {r.proximaVisita || "—"}
          </p>
        </div>
      </div>

      {/* Menu fica acima do link esticado. */}
      <div className="absolute right-2 top-2 z-10">
        <KebabMenu items={menu} />
      </div>
    </div>
  );
}

function Thumb({ url, label, depois }: { url?: string; label: string; depois?: boolean }) {
  return (
    <div className="relative h-24 overflow-hidden">
      {url ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt="" className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <GardenSVG depois={depois} />
      )}
      <span className="absolute left-1.5 top-1.5 rounded-full bg-[rgba(28,38,32,.72)] px-1.5 py-[3px] font-mono text-[9px] font-semibold tracking-wider text-white">
        {label}
      </span>
    </div>
  );
}

function CalIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M3 9h18M8 2v4M16 2v4" />
    </svg>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/ReportCard.tsx"

mkdir -p "src/app/admin/perfil/arquivados"
cat > "src/app/admin/perfil/arquivados/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import type { Cliente } from "@/types";
import { listClientesArquivados, restoreCliente } from "@/lib/clientes";
import { parseBR } from "@/lib/utils";

const MES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

function chaveMes(data: string): string | null {
  const d = parseBR(data);
  if (!d) return null;
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

export default function ArquivadosPage() {
  const router = useRouter();
  const { arquivados } = useReports();
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [mes, setMes] = useState("todos");

  useEffect(() => {
    listClientesArquivados().then(setClientes).catch(() => setClientes([]));
  }, []);

  const meses = useMemo(() => {
    const m = new Map<string, string>();
    for (const r of arquivados) {
      const k = chaveMes(r.data);
      if (!k) continue;
      const d = parseBR(r.data)!;
      m.set(k, `${MES[d.getMonth()]}/${d.getFullYear()}`);
    }
    return [...m.entries()].sort((a, b) => b[0].localeCompare(a[0]));
  }, [arquivados]);

  const relatorios = mes === "todos" ? arquivados : arquivados.filter((r) => chaveMes(r.data) === mes);

  const restaurar = async (id: string) => {
    await restoreCliente(id);
    setClientes((prev) => prev.filter((c) => c.id !== id));
  };

  const vazio = arquivados.length === 0 && clientes.length === 0;

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">Arquivados</h1>
      </header>

      {vazio ? (
        <div className="px-8 py-16 text-center">
          <p className="font-display text-lg font-semibold text-verde-900">Nada arquivado</p>
          <p className="mt-1 text-sm text-tintaMuda">Relatórios e clientes que você arquivar aparecem aqui.</p>
        </div>
      ) : (
        <>
          {arquivados.length > 0 && (
            <>
              <div className="flex items-center justify-between gap-3 px-[18px] pb-2 pt-2">
                <h2 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Relatórios</h2>
                {meses.length > 0 && (
                  <select
                    value={mes}
                    onChange={(e) => setMes(e.target.value)}
                    className="rounded-full border border-linha bg-surface px-3 py-1 text-[12px] font-semibold text-verde-800"
                  >
                    <option value="todos">Todos os meses</option>
                    {meses.map(([k, label]) => (
                      <option key={k} value={k}>{label}</option>
                    ))}
                  </select>
                )}
              </div>

              {relatorios.length === 0 ? (
                <p className="mx-[18px] rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
                  Nenhum relatório arquivado neste mês.
                </p>
              ) : (
                <div className="flex flex-col gap-3.5 px-[18px]">
                  {relatorios.map((r) => <ReportCard key={r.id} r={r} archived />)}
                </div>
              )}
            </>
          )}

          {clientes.length > 0 && (
            <>
              <h2 className="px-[18px] pb-2 pt-6 font-mono text-[11px] uppercase tracking-wider text-verde-600">Clientes</h2>
              <div className="mx-[18px] overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
                {clientes.map((c, i) => (
                  <div key={c.id} className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}>
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-[15px] font-semibold text-tinta">{c.nome}</div>
                      <div className="truncate text-[12px] text-tintaMuda">
                        {c.sindico ? `Síndico ${c.sindico}` : "Síndico não cadastrado"}
                        {c.telefone ? ` · ${c.telefone}` : ""}
                      </div>
                    </div>
                    <button onClick={() => restaurar(c.id)} className="flex-none rounded-full bg-verde-50 px-3 py-1.5 text-[12px] font-semibold text-verde-700">
                      Restaurar
                    </button>
                  </div>
                ))}
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/app/admin/perfil/arquivados/page.tsx"

echo ""
echo "Feito (sem mudança no banco). Reinicie o npm run dev ou git add -A && commit && push."
