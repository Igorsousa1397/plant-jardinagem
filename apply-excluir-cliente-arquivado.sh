#!/usr/bin/env bash
# Plant Jardinagem — excluir cliente arquivado (bloqueia se houver vínculos)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando exclusão de cliente arquivado..."

mkdir -p "src/lib"
cat > "src/lib/clientes.ts" <<'__PLANT_EOF__'
import { createClient } from "@/lib/supabase/client";
import type { Cliente } from "@/types";

interface ClienteRow {
  id: string;
  nome: string;
  sindico: string | null;
  telefone: string | null;
}

function toCliente(c: ClienteRow): Cliente {
  return { id: c.id, nome: c.nome, sindico: c.sindico ?? undefined, telefone: c.telefone ?? undefined };
}

export async function listClientes(): Promise<Cliente[]> {
  const sb = createClient();
  const { data, error } = await sb.from("clientes").select("*").eq("arquivado", false).order("nome");
  if (error) throw error;
  return (data as ClienteRow[]).map(toCliente);
}

export async function listClientesArquivados(): Promise<Cliente[]> {
  const sb = createClient();
  const { data, error } = await sb.from("clientes").select("*").eq("arquivado", true).order("nome");
  if (error) throw error;
  return (data as ClienteRow[]).map(toCliente);
}

export async function createCliente(c: { nome: string; sindico?: string; telefone?: string }): Promise<Cliente> {
  const sb = createClient();
  const { data, error } = await sb
    .from("clientes")
    .insert({ nome: c.nome, sindico: c.sindico ?? null, telefone: c.telefone ?? null })
    .select("*")
    .single();
  if (error) throw error;
  return toCliente(data as ClienteRow);
}

export async function updateCliente(id: string, c: { nome: string; sindico?: string; telefone?: string }): Promise<Cliente> {
  const sb = createClient();
  const { data, error } = await sb
    .from("clientes")
    .update({ nome: c.nome, sindico: c.sindico ?? null, telefone: c.telefone ?? null })
    .eq("id", id)
    .select("*")
    .single();
  if (error) throw error;
  return toCliente(data as ClienteRow);
}

export async function archiveCliente(id: string): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("clientes").update({ arquivado: true }).eq("id", id);
  if (error) throw error;
}

export async function restoreCliente(id: string): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("clientes").update({ arquivado: false }).eq("id", id);
  if (error) throw error;
}

/** Conta registros (relatórios, propostas, agendamentos) ligados ao cliente pelo nome. */
export async function contarVinculos(nome: string): Promise<number> {
  const sb = createClient();
  let total = 0;
  for (const tabela of ["relatorios", "propostas", "agendamentos"] as const) {
    const { count, error } = await sb.from(tabela).select("id", { count: "exact", head: true }).eq("condo", nome);
    if (error) throw error;
    total += count ?? 0;
  }
  return total;
}

/** Exclui de vez. Bloqueia se houver registros vinculados. */
export async function deleteCliente(id: string, nome: string): Promise<void> {
  const vinculos = await contarVinculos(nome);
  if (vinculos > 0) {
    throw new Error(
      `Este cliente tem ${vinculos} registro(s) vinculado(s) (relatórios, propostas ou agendamentos). Exclua ou desvincule esses registros antes de remover o cliente.`
    );
  }
  const sb = createClient();
  const { error } = await sb.from("clientes").delete().eq("id", id);
  if (error) throw error;
}
__PLANT_EOF__
echo "  ok  src/lib/clientes.ts"

mkdir -p "src/app/admin/perfil/arquivados"
cat > "src/app/admin/perfil/arquivados/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import type { Cliente } from "@/types";
import { listClientesArquivados, restoreCliente, deleteCliente } from "@/lib/clientes";
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

  const excluir = async (c: Cliente) => {
    if (!confirm(`Excluir definitivamente "${c.nome}"? Esta ação não pode ser desfeita.`)) return;
    try {
      await deleteCliente(c.id, c.nome);
      setClientes((prev) => prev.filter((x) => x.id !== c.id));
    } catch (e) {
      alert(e instanceof Error ? e.message : "Não foi possível excluir o cliente.");
    }
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
                    <button onClick={() => excluir(c)} className="flex-none rounded-full bg-erroBg px-3 py-1.5 text-[12px] font-semibold text-erro">
                      Excluir
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
