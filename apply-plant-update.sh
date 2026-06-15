#!/usr/bin/env bash
# Atualização Plant Jardinagem — escreve os arquivos novos/alterados.
# Uso: coloque na raiz do projeto e rode  ->  bash apply-plant-update.sh
set -e

if [ ! -f package.json ]; then
  echo "Erro: rode este script na RAIZ do projeto (onde está o package.json)."; exit 1
fi
echo "Aplicando atualização (auth + Supabase)..."

mkdir -p "src/lib/supabase"
cat > "src/lib/supabase/middleware.ts" <<'__PLANT_EOF__'
import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

type CookieToSet = { name: string; value: string; options: CookieOptions };

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const precisaLogin = path.startsWith("/admin") || path.startsWith("/campo");

  if (!user && precisaLogin) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  if (user && path === "/login") {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return response;
}
__PLANT_EOF__
echo "  ok  src/lib/supabase/middleware.ts"

mkdir -p "src"
cat > "src/middleware.ts" <<'__PLANT_EOF__'
import { type NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

export async function middleware(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: [
    // tudo, menos estáticos e imagens
    "/((?!_next/static|_next/image|favicon.ico|manifest.webmanifest|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
__PLANT_EOF__
echo "  ok  src/middleware.ts"

mkdir -p "src/app/login"
cat > "src/app/login/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/Button";
import { Field, inputClass } from "@/components/ui/Field";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [erro, setErro] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const entrar = async () => {
    setLoading(true);
    setErro(null);
    const sb = createClient();
    const { error } = await sb.auth.signInWithPassword({ email, password: senha });
    if (error) {
      setErro("E-mail ou senha inválidos.");
      setLoading(false);
      return;
    }
    router.push("/");
    router.refresh();
  };

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center px-7">
      <div className="mb-8 text-center">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.png" alt="Plant Jardinagem" className="mx-auto mb-5 w-40" />
        <h1 className="font-display text-2xl font-semibold text-verde-900">Entrar</h1>
        <p className="mt-1 text-sm text-tintaMuda">Acesse o painel da Plant Jardinagem.</p>
      </div>

      <Field label="E-mail">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className={inputClass}
          autoComplete="email"
        />
      </Field>
      <Field label="Senha">
        <input
          type="password"
          value={senha}
          onChange={(e) => setSenha(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && entrar()}
          className={inputClass}
          autoComplete="current-password"
        />
      </Field>

      {erro && (
        <p className="mb-3 rounded-[10px] bg-erroBg px-3 py-2 text-sm font-medium text-erro">{erro}</p>
      )}

      <Button block disabled={loading} onClick={entrar}>
        {loading ? "Entrando…" : "Entrar"}
      </Button>
    </main>
  );
}
__PLANT_EOF__
echo "  ok  src/app/login/page.tsx"

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
__PLANT_EOF__
echo "  ok  src/lib/relatorios.ts"

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

export async function listClientes(): Promise<Cliente[]> {
  const sb = createClient();
  const { data, error } = await sb.from("clientes").select("*").order("nome");
  if (error) throw error;
  return (data as ClienteRow[]).map((c) => ({
    id: c.id,
    nome: c.nome,
    sindico: c.sindico ?? undefined,
    telefone: c.telefone ?? undefined,
  }));
}
__PLANT_EOF__
echo "  ok  src/lib/clientes.ts"

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
  const get: Ctx["get"] = (id) => all.find((x) => x.id === id);

  const reports = all.filter((x) => !x.arquivado);
  const arquivados = all.filter((x) => x.arquivado);

  return (
    <ReportsContext.Provider
      value={{ reports, arquivados, loading, error, add, update, archive, unarchive, get, refresh }}
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

mkdir -p "src/app/admin/home"
cat > "src/app/admin/home/page.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import { Agenda } from "@/components/relatorios/Agenda";

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
        {loading ? <Skeleton h={64} /> : <Agenda reports={reports} />}
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

mkdir -p "src/app/admin/perfil"
cat > "src/app/admin/perfil/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Cliente } from "@/types";
import { useReports } from "@/components/relatorios/store";
import { listClientes } from "@/lib/clientes";
import { createClient } from "@/lib/supabase/client";
import { EMPRESA } from "@/lib/constants";
import { soDigitos } from "@/lib/utils";

export default function PerfilPage() {
  const router = useRouter();
  const { arquivados } = useReports();
  const [clientes, setClientes] = useState<Cliente[]>([]);

  useEffect(() => {
    listClientes()
      .then(setClientes)
      .catch(() => setClientes([]));
  }, []);

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
          <div className="text-[12px] text-tintaMuda">Relatórios fora da lista principal</div>
        </div>
        <span className="rounded-full bg-verde-50 px-2.5 py-1 font-mono text-[12px] font-semibold text-verde-700">{arquivados.length}</span>
        <span className="text-tintaMuda">›</span>
      </Link>

      <h2 className="px-[18px] pb-2 pt-6 font-mono text-[11px] uppercase tracking-wider text-verde-600">Clientes</h2>
      <div className="mx-[18px] overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
        {clientes.length === 0 ? (
          <p className="p-4 text-sm text-tintaMuda">Nenhum cliente cadastrado.</p>
        ) : (
          clientes.map((c, i) => (
            <div key={c.id} className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}>
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
        <button
          onClick={sair}
          className="w-full rounded-[10px] border border-linha bg-surface px-5 py-3 text-[15px] font-semibold text-erro"
        >
          Sair
        </button>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/app/admin/perfil/page.tsx"

mkdir -p "src/app/admin/relatorios/[id]"
cat > "src/app/admin/relatorios/[id]/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useParams } from "next/navigation";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportPreview } from "@/components/relatorios/ReportPreview";

export default function RelatorioPreviewPage() {
  const { id } = useParams<{ id: string }>();
  const { get, loading } = useReports();
  const report = get(id);

  if (loading) {
    return <div className="grid min-h-screen place-items-center text-sm text-tintaMuda">Carregando…</div>;
  }
  if (!report) {
    return (
      <div className="grid min-h-screen place-items-center px-8 text-center">
        <div>
          <p className="font-display text-xl font-semibold text-verde-900">Relatório não encontrado</p>
          <Link href="/admin/home" className="mt-4 inline-block font-semibold text-verde-700">Voltar pra Home</Link>
        </div>
      </div>
    );
  }
  return <ReportPreview r={report} />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/relatorios/[id]/page.tsx"

mkdir -p "src/app/admin/relatorios/[id]/editar"
cat > "src/app/admin/relatorios/[id]/editar/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useParams } from "next/navigation";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportForm } from "@/components/relatorios/ReportForm";

export default function EditarRelatorioPage() {
  const { id } = useParams<{ id: string }>();
  const { get, loading } = useReports();
  const report = get(id);

  if (loading) {
    return <div className="grid min-h-screen place-items-center text-sm text-tintaMuda">Carregando…</div>;
  }
  if (!report) {
    return (
      <div className="grid min-h-screen place-items-center px-8 text-center">
        <div>
          <p className="font-display text-xl font-semibold text-verde-900">Relatório não encontrado</p>
          <Link href="/admin/home" className="mt-4 inline-block font-semibold text-verde-700">Voltar pra Home</Link>
        </div>
      </div>
    );
  }
  return <ReportForm report={report} />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/relatorios/[id]/editar/page.tsx"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportForm.tsx" <<'__PLANT_EOF__'
"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { Report, Status } from "@/types";
import { CONDOS, SERVICOS, EQUIPAMENTOS, EPIS, STATUS_STYLES } from "@/lib/constants";
import { fmtData, toISO } from "@/lib/utils";
import { useReports } from "./store";
import { Field, inputClass } from "@/components/ui/Field";
import { Chip } from "@/components/ui/Chip";
import { Button } from "@/components/ui/Button";

const STATUS_LIST = Object.keys(STATUS_STYLES) as Status[];

export function ReportForm({ report }: { report?: Report }) {
  const editing = Boolean(report);
  const router = useRouter();
  const { add, update } = useReports();
  const antesRef = useRef<HTMLInputElement>(null);
  const depoisRef = useRef<HTMLInputElement>(null);

  const [condo, setCondo] = useState(report?.condo ?? CONDOS[0]);
  const [data, setData] = useState(report ? toISO(report.data) : "2025-09-08");
  const [duracao, setDuracao] = useState(report?.duracao ?? "5 horas");
  const [servicos, setServicos] = useState<string[]>(report?.servicos ?? ["Corte e Poda", "Limpeza Geral do Jardim"]);
  const [equip, setEquip] = useState<string[]>(report?.equipamentos ?? ["Roçadeira", "Soprador"]);
  const [epi, setEpi] = useState<string[]>(report?.epi ?? ["Luvas", "Botas"]);
  const [obs, setObs] = useState(report?.observacoes ?? "");
  const [proxima, setProxima] = useState(report ? toISO(report.proximaVisita) : "2025-09-22");
  const [status, setStatus] = useState<Status>(report?.status ?? "Finalizado");
  const [fotosAntes, setFotosAntes] = useState<string[]>(report?.fotosAntes ?? []);
  const [fotosDepois, setFotosDepois] = useState<string[]>(report?.fotosDepois ?? []);

  const [saving, setSaving] = useState(false);

  const toggle = (list: string[], set: (v: string[]) => void, v: string) =>
    set(list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const addPhotos = (
    e: React.ChangeEvent<HTMLInputElement>,
    set: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    Array.from(e.target.files ?? []).forEach((f) => {
      const reader = new FileReader();
      reader.onload = () => set((prev) => [...prev, reader.result as string]);
      reader.readAsDataURL(f);
    });
  };

  const salvar = async () => {
    setSaving(true);
    const payload = {
      condo,
      data: fmtData(data),
      duracao,
      status,
      servicos,
      equipamentos: equip,
      epi,
      observacoes: obs,
      proximaVisita: fmtData(proxima),
      fotosAntes,
      fotosDepois,
    };
    try {
      if (report) {
        await update(report.id, payload);
        router.push(`/admin/relatorios/${report.id}`);
      } else {
        const novo = await add(payload);
        router.push(`/admin/relatorios/${novo.id}`);
      }
    } catch (e) {
      setSaving(false);
      alert("Não foi possível salvar: " + (e instanceof Error ? e.message : "erro desconhecido"));
    }
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">
          {editing ? "Editar relatório" : "Novo relatório"}
        </h1>
      </header>

      <div className="px-[18px] pt-1.5">
        <Field label="Condomínio">
          <select value={condo} onChange={(e) => setCondo(e.target.value)} className={inputClass}>
            {CONDOS.map((x) => <option key={x}>{x}</option>)}
          </select>
        </Field>

        <div className="flex gap-3">
          <div className="flex-1">
            <Field label="Data do serviço">
              <input type="date" value={data} onChange={(e) => setData(e.target.value)} className={inputClass} />
            </Field>
          </div>
          <div className="flex-1">
            <Field label="Duração">
              <input value={duracao} onChange={(e) => setDuracao(e.target.value)} placeholder="5 horas" className={inputClass} />
            </Field>
          </div>
        </div>

        <Field label="Fotos — antes" hint="Toque para adicionar do celular.">
          <PhotoRow list={fotosAntes} onAdd={() => antesRef.current?.click()} onRemove={(i) => setFotosAntes((p) => p.filter((_, x) => x !== i))} />
          <input ref={antesRef} type="file" accept="image/*" multiple hidden onChange={(e) => addPhotos(e, setFotosAntes)} />
        </Field>

        <Field label="Fotos — depois">
          <PhotoRow depois list={fotosDepois} onAdd={() => depoisRef.current?.click()} onRemove={(i) => setFotosDepois((p) => p.filter((_, x) => x !== i))} />
          <input ref={depoisRef} type="file" accept="image/*" multiple hidden onChange={(e) => addPhotos(e, setFotosDepois)} />
        </Field>

        <Field label="Serviços realizados">
          <div className="flex flex-wrap gap-2">
            {SERVICOS.map((s) => <Chip key={s} active={servicos.includes(s)} onClick={() => toggle(servicos, setServicos, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="Equipamentos">
          <div className="flex flex-wrap gap-2">
            {EQUIPAMENTOS.map((s) => <Chip key={s} active={equip.includes(s)} onClick={() => toggle(equip, setEquip, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="EPI utilizados">
          <div className="flex flex-wrap gap-2">
            {EPIS.map((s) => <Chip key={s} active={epi.includes(s)} onClick={() => toggle(epi, setEpi, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="Observações" hint="Ex: reforçar rega nas gramas novas.">
          <textarea rows={3} value={obs} onChange={(e) => setObs(e.target.value)} className={`${inputClass} resize-y`} />
        </Field>

        <Field label="Próxima visita">
          <input type="date" value={proxima} onChange={(e) => setProxima(e.target.value)} className={inputClass} />
        </Field>

        <Field label="Status">
          <div className="flex flex-wrap gap-2">
            {STATUS_LIST.map((s) => <Chip key={s} active={status === s} onClick={() => setStatus(s)}>{s}</Chip>)}
          </div>
        </Field>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] pb-4 pt-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>
          {saving ? "Salvando…" : editing ? "Salvar alterações" : "Salvar relatório"}
        </Button>
      </div>
    </div>
  );
}

function PhotoRow({
  list, onAdd, onRemove, depois,
}: { list: string[]; onAdd: () => void; onRemove: (i: number) => void; depois?: boolean }) {
  return (
    <div className="flex flex-wrap gap-2">
      {list.map((src, i) => (
        <div key={i} className="relative h-16 w-16 overflow-hidden rounded-[10px] shadow-s1">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={src} alt="" className="h-full w-full object-cover" />
          <button onClick={() => onRemove(i)} className="absolute right-0.5 top-0.5 grid h-[18px] w-[18px] place-items-center rounded-full bg-[rgba(28,38,32,.8)] text-[11px] leading-none text-white">×</button>
        </div>
      ))}
      <button
        onClick={onAdd}
        className={`grid h-16 w-16 place-items-center rounded-[10px] border-[1.5px] border-dashed text-[22px] text-verde-700 ${depois ? "border-verde-400 bg-verde-50" : "border-linha bg-surface2"}`}
      >+</button>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/ReportForm.tsx"

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0001_init.sql" <<'__PLANT_EOF__'
-- Plant Jardinagem — schema inicial
-- Rode no SQL Editor do Supabase (cole tudo e Run), ou via `supabase db push`.

create extension if not exists "pgcrypto";

-- Status do relatório (mesmos valores do app)
do $$ begin
  create type relatorio_status as enum ('Finalizado','Em andamento','Agendado','Atrasado');
exception when duplicate_object then null; end $$;

-- Clientes (condomínios)
create table if not exists public.clientes (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  sindico    text,
  telefone   text,
  created_at timestamptz not null default now()
);

-- Relatórios de serviço
create table if not exists public.relatorios (
  id             uuid primary key default gen_random_uuid(),
  condo          text not null,
  cliente_id     uuid references public.clientes(id) on delete set null,
  data           date not null,
  duracao        text not null default '',
  status         relatorio_status not null default 'Finalizado',
  servicos       text[] not null default '{}',
  equipamentos   text[] not null default '{}',
  epi            text[] not null default '{}',
  observacoes    text not null default '',
  proxima_visita date,
  fotos_antes    text[] not null default '{}',
  fotos_depois   text[] not null default '{}',
  arquivado      boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists relatorios_arquivado_idx      on public.relatorios (arquivado);
create index if not exists relatorios_proxima_visita_idx on public.relatorios (proxima_visita);
create index if not exists relatorios_cliente_idx        on public.relatorios (cliente_id);

-- updated_at automático
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists relatorios_set_updated_at on public.relatorios;
create trigger relatorios_set_updated_at
  before update on public.relatorios
  for each row execute function public.set_updated_at();

-- ===================== RLS =====================
alter table public.clientes   enable row level security;
alter table public.relatorios enable row level security;

-- Admin autenticado: acesso total (refine quando entrar o papel de funcionário)
drop policy if exists clientes_auth_all on public.clientes;
create policy clientes_auth_all on public.clientes
  for all to authenticated using (true) with check (true);

drop policy if exists relatorios_auth_all on public.relatorios;
create policy relatorios_auth_all on public.relatorios
  for all to authenticated using (true) with check (true);

-- ============= Storage: fotos antes/depois =============
insert into storage.buckets (id, name, public)
values ('relatorios','relatorios', true)
on conflict (id) do nothing;

drop policy if exists relatorios_fotos_read on storage.objects;
create policy relatorios_fotos_read on storage.objects
  for select using (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_insert on storage.objects;
create policy relatorios_fotos_insert on storage.objects
  for insert to authenticated with check (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_update on storage.objects;
create policy relatorios_fotos_update on storage.objects
  for update to authenticated using (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_delete on storage.objects;
create policy relatorios_fotos_delete on storage.objects
  for delete to authenticated using (bucket_id = 'relatorios');

-- ===================== DEV (opcional) =====================
-- Enquanto NÃO houver login, descomente para testar o app sem autenticação.
-- Remova antes de ir pra produção.
-- create policy dev_anon_clientes   on public.clientes   for all to anon using (true) with check (true);
-- create policy dev_anon_relatorios on public.relatorios for all to anon using (true) with check (true);
__PLANT_EOF__
echo "  ok  supabase/migrations/0001_init.sql"

mkdir -p "supabase"
cat > "supabase/seed.sql" <<'__PLANT_EOF__'
-- Dados de exemplo. Rode UMA vez após o 0001_init.sql.

insert into public.clientes (nome, sindico, telefone) values
  ('Alameda das Palmeiras', null, null),
  ('San Denis', null, null),
  ('Quinta do Moinho',   'Hélio Vidilino',   '(11) 94037-7744'),
  ('Quinta do Loureiro', 'Tiago Mello',      '(11) 96149-8089'),
  ('dos Girassóis',      'Thiago Maiellaro', '(11) 99694-4188')
on conflict do nothing;

insert into public.relatorios
  (condo, cliente_id, data, duracao, status, servicos, equipamentos, epi, observacoes, proxima_visita)
select 'Alameda das Palmeiras', c.id, date '2025-09-08', '5 horas', 'Finalizado',
  array['Corte e Poda','Remoção de Folhas / Galhos','Paisagismo','Limpeza Geral do Jardim'],
  array['Roçadeira','Soprador','Rastelo'],
  array['Luvas','Botas','Óculos de Proteção'],
  'Colocação de pedras brancas na caixa de palmeiras. Reforçar a rega, principalmente nas gramas recém-colocadas.',
  date '2025-09-22'
from public.clientes c where c.nome = 'Alameda das Palmeiras';

insert into public.relatorios
  (condo, cliente_id, data, duracao, status, servicos, equipamentos, epi, observacoes, proxima_visita)
select 'San Denis', c.id, date '2025-07-21', '4 horas', 'Agendado',
  array['Corte de grama','Poda de arbustos'],
  array['Roçadeira'],
  array['Luvas','Botas'],
  '',
  date '2025-08-04'
from public.clientes c where c.nome = 'San Denis';
__PLANT_EOF__
echo "  ok  supabase/seed.sql"

mkdir -p "supabase"
cat > "supabase/README.md" <<'__PLANT_EOF__'
# Banco (Supabase)

## Criar o schema
1. Abra o projeto no painel do Supabase → **SQL Editor** → **New query**.
2. Cole o conteúdo de `migrations/0001_init.sql` e clique **Run**.
   - Cria as tabelas `clientes` e `relatorios`, o enum de status, índices,
     trigger de `updated_at`, RLS e o bucket de Storage `relatorios` (fotos).
3. (Opcional) Cole `seed.sql` e **Run** uma vez para popular clientes + 2 relatórios.

## Conectar o app
Em **Project Settings → API**, copie *Project URL* e *anon public key* para `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

## RLS
As policies liberam acesso total para usuários **autenticados**. Como a tela de login
ainda não existe, para testar sem auth descomente o bloco **DEV** no final do
`0001_init.sql` (libera o papel `anon`) — e remova antes de produção.

## Via CLI (alternativa)
Com a Supabase CLI e o projeto linkado: `supabase db push`.

## Login (Supabase Auth)
O app agora exige login e a RLS libera só usuários **autenticados** —
então **não** use o bloco DEV/anon.

Crie seu usuário:
1. **Authentication → Users → Add user**.
2. Preencha e-mail e senha e marque **Auto Confirm User** (entra sem confirmar e-mail).
3. Use esse e-mail/senha na tela `/login` do app.

(Opcional) Para permitir cadastro pela tela: Authentication → Providers → Email,
e desligue "Confirm email" no ambiente de dev.
__PLANT_EOF__
echo "  ok  supabase/README.md"

echo ""
echo "Pronto! Próximos passos:"
echo "  1) cp .env.example .env.local  (preencha as chaves do Supabase)"
echo "  2) npm install"
echo "  3) npm run dev"
echo "  4) git add . && git commit -m \"feat: integração Supabase (auth + banco)\" && git push"
