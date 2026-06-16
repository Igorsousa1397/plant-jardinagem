#!/usr/bin/env bash
# Plant Jardinagem — CRUD de clientes (cadastrar/editar/arquivar) com bottom sheet
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando CRUD de clientes..."

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0007_cliente_arquivado.sql" <<'__PLANT_EOF__'
-- Soft-delete de clientes (mantém em "arquivados")
alter table public.clientes
  add column if not exists arquivado boolean not null default false;
__PLANT_EOF__
echo "  ok  supabase/migrations/0007_cliente_arquivado.sql"

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
__PLANT_EOF__
echo "  ok  src/lib/clientes.ts"

mkdir -p "src/components/clientes"
cat > "src/components/clientes/ClienteSheet.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import type { Cliente } from "@/types";
import { createCliente, updateCliente, archiveCliente } from "@/lib/clientes";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

export type SheetAlvo = "novo" | Cliente | null;

export function ClienteSheet({ alvo, onClose, onSaved }: { alvo: SheetAlvo; onClose: () => void; onSaved: () => void }) {
  const editando = alvo && alvo !== "novo" ? alvo : null;
  const [nome, setNome] = useState("");
  const [sindico, setSindico] = useState("");
  const [telefone, setTelefone] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (alvo && alvo !== "novo") {
      setNome(alvo.nome);
      setSindico(alvo.sindico ?? "");
      setTelefone(alvo.telefone ?? "");
    } else if (alvo === "novo") {
      setNome("");
      setSindico("");
      setTelefone("");
    }
  }, [alvo]);

  if (alvo === null) return null;

  const salvar = async () => {
    if (!nome.trim()) return;
    setSaving(true);
    try {
      const dados = { nome: nome.trim(), sindico: sindico.trim() || undefined, telefone: telefone.trim() || undefined };
      if (editando) await updateCliente(editando.id, dados);
      else await createCliente(dados);
      onSaved();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const excluir = async () => {
    if (!editando) return;
    if (!confirm("Excluir este cliente? Ele vai para os arquivados (os registros ligados a ele são mantidos).")) return;
    setSaving(true);
    try {
      await archiveCliente(editando.id);
      onSaved();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-tinta/40" onClick={onClose} />
      <div className="relative z-10 w-full max-w-md rounded-t-[22px] border border-linha bg-surface p-5 pb-8 shadow-s3">
        <div className="mx-auto mb-4 h-1.5 w-10 rounded-full bg-linha" />
        <h2 className="mb-3 font-display text-[18px] font-semibold text-verde-900">{editando ? "Editar cliente" : "Novo cliente"}</h2>
        <Field label="Nome">
          <input value={nome} onChange={(e) => setNome(e.target.value)} className={inputClass} placeholder="Ex: Condomínio Alameda das Palmeiras" />
        </Field>
        <Field label="Síndico (opcional)">
          <input value={sindico} onChange={(e) => setSindico(e.target.value)} className={inputClass} placeholder="Nome do síndico" />
        </Field>
        <Field label="Telefone (opcional)">
          <input value={telefone} onChange={(e) => setTelefone(e.target.value)} className={inputClass} inputMode="tel" placeholder="(11) 90000-0000" />
        </Field>
        <div className="mt-2 flex gap-2">
          {editando && (
            <button onClick={excluir} disabled={saving} className="flex-none rounded-[10px] border border-linha bg-surface px-4 py-3 text-[15px] font-semibold text-erro disabled:opacity-50">
              Excluir
            </button>
          )}
          <Button block onClick={salvar} disabled={saving}>{saving ? "Salvando…" : "Salvar"}</Button>
        </div>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/clientes/ClienteSheet.tsx"

mkdir -p "src/app/admin/perfil"
cat > "src/app/admin/perfil/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Plus } from "lucide-react";
import type { Cliente } from "@/types";
import { useReports } from "@/components/relatorios/store";
import { listClientes } from "@/lib/clientes";
import { createClient } from "@/lib/supabase/client";
import { EMPRESA } from "@/lib/constants";
import { soDigitos } from "@/lib/utils";
import { ClienteSheet, type SheetAlvo } from "@/components/clientes/ClienteSheet";

export default function PerfilPage() {
  const router = useRouter();
  const { arquivados } = useReports();
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [sheet, setSheet] = useState<SheetAlvo>(null);

  const recarregar = useCallback(() => {
    listClientes()
      .then(setClientes)
      .catch(() => setClientes([]));
  }, []);

  useEffect(() => {
    recarregar();
  }, [recarregar]);

  const sair = async () => {
    const sb = createClient();
    await sb.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">Perfil</h1>
      </header>

      <div className="mx-[18px] mt-1.5 flex items-center gap-3.5 rounded-2xl border border-linha bg-surface p-4 shadow-s2">
        <div className="grid h-14 w-14 flex-none place-items-center rounded-full bg-verde-700 text-lg font-bold text-white">CL</div>
        <div className="min-w-0">
          <div className="font-display text-[17px] font-semibold text-verde-900">Claiton</div>
          <div className="truncate text-[13px] text-tintaMuda">{EMPRESA.nome}</div>
          <div className="font-mono text-[11px] text-tintaMuda">CNPJ {EMPRESA.cnpj}</div>
        </div>
      </div>

      <Link
        href="/admin/perfil/arquivados"
        className="mx-[18px] mt-3 flex items-center gap-3 rounded-2xl border border-linha bg-surface p-4 shadow-s1"
      >
        <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-salviaSurface text-verde-700">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 7h18v4H3z M5 11v9h14v-9 M9 15h6" /></svg>
        </div>
        <div className="flex-1">
          <div className="text-[15px] font-semibold text-tinta">Arquivados</div>
          <div className="text-[12px] text-tintaMuda">Relatórios e clientes fora da lista</div>
        </div>
        <span className="rounded-full bg-verde-50 px-2.5 py-1 font-mono text-[12px] font-semibold text-verde-700">{arquivados.length}</span>
        <span className="text-tintaMuda">›</span>
      </Link>

      <div className="flex items-center justify-between px-[18px] pb-2 pt-6">
        <h2 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Clientes</h2>
        <button
          onClick={() => setSheet("novo")}
          aria-label="Novo cliente"
          className="grid h-8 w-8 place-items-center rounded-full bg-verde-700 text-white shadow-s1"
        >
          <Plus size={18} />
        </button>
      </div>

      <div className="mx-[18px] overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
        {clientes.length === 0 ? (
          <p className="p-4 text-sm text-tintaMuda">Nenhum cliente cadastrado. Toque no + para adicionar.</p>
        ) : (
          clientes.map((c, i) => (
            <div
              key={c.id}
              onClick={() => setSheet(c)}
              className={`flex cursor-pointer items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}
            >
              <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-salviaSurface text-[13px] font-bold text-verde-700">
                {c.nome.replace(/^(dos |da |de )/i, "").slice(0, 2).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate text-[15px] font-semibold text-tinta">{c.nome}</div>
                <div className="truncate text-[12px] text-tintaMuda">
                  {c.sindico ? `Síndico ${c.sindico}` : "Síndico não cadastrado"}
                  {c.telefone ? ` · ${c.telefone}` : ""}
                </div>
              </div>
              {c.telefone && (
                <a
                  href={`https://wa.me/55${soDigitos(c.telefone)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={`WhatsApp de ${c.nome}`}
                  onClick={(e) => e.stopPropagation()}
                  className="grid h-9 w-9 flex-none place-items-center rounded-full bg-verde-50 text-verde-700"
                >
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 16v3a2 2 0 01-2 2 19 19 0 01-8-3 19 19 0 01-6-6 19 19 0 01-3-8 2 2 0 012-2h3a2 2 0 012 2c0 1 .2 2 .5 3a2 2 0 01-.5 2L9 11a16 16 0 006 6l1-1a2 2 0 012-.5c1 .3 2 .5 3 .5a2 2 0 012 2z" /></svg>
                </a>
              )}
            </div>
          ))
        )}
      </div>

      <div className="px-[18px] pt-6">
        <button onClick={sair} className="w-full rounded-[10px] border border-linha bg-surface px-5 py-3 text-[15px] font-semibold text-erro">
          Sair
        </button>
      </div>

      <ClienteSheet alvo={sheet} onClose={() => setSheet(null)} onSaved={recarregar} />
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/app/admin/perfil/page.tsx"

mkdir -p "src/app/admin/perfil/arquivados"
cat > "src/app/admin/perfil/arquivados/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import type { Cliente } from "@/types";
import { listClientesArquivados, restoreCliente } from "@/lib/clientes";

export default function ArquivadosPage() {
  const router = useRouter();
  const { arquivados } = useReports();
  const [clientes, setClientes] = useState<Cliente[]>([]);

  const recarregar = () => {
    listClientesArquivados().then(setClientes).catch(() => setClientes([]));
  };
  useEffect(() => {
    recarregar();
  }, []);

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
              <h2 className="px-[18px] pb-2 pt-2 font-mono text-[11px] uppercase tracking-wider text-verde-600">Relatórios</h2>
              <div className="flex flex-col gap-3.5 px-[18px]">
                {arquivados.map((r) => <ReportCard key={r.id} r={r} archived />)}
              </div>
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
echo "Rode no Supabase: alter table public.clientes add column if not exists arquivado boolean not null default false;"
echo "Depois: git add -A && git commit -m \"feat: CRUD de clientes\" && git push"
