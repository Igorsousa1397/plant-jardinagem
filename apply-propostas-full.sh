#!/usr/bin/env bash
# Plant Jardinagem — módulo de Propostas COMPLETO (corrige build da Vercel)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Reaplicando módulo de propostas (completo)..."

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0004_propostas.sql" <<'__PLANT_EOF__'
-- Propostas comerciais

create table if not exists public.propostas (
  id              uuid primary key default gen_random_uuid(),
  cliente_id      uuid references public.clientes(id) on delete set null,
  condo           text not null,
  data            date not null,
  valor_mensal    numeric not null default 0,
  visitas_mensais int not null default 2,
  equipe          int not null default 7,
  prazo_meses     int not null default 24,
  validade_dias   int not null default 30,
  created_at      timestamptz not null default now()
);

create index if not exists propostas_created_idx on public.propostas (created_at desc);

alter table public.propostas enable row level security;
drop policy if exists propostas_auth_all on public.propostas;
create policy propostas_auth_all on public.propostas
  for all to authenticated using (true) with check (true);
__PLANT_EOF__
echo "  ok  supabase/migrations/0004_propostas.sql"

mkdir -p "src/lib"
cat > "src/lib/utils.ts" <<'__PLANT_EOF__'
export function cn(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}

/** ISO (aaaa-mm-dd) -> exibição dd/mm/aaaa */
export function fmtData(iso: string): string {
  if (!iso) return "";
  const [y, m, d] = iso.split("-");
  return `${d}/${m}/${y}`;
}

/** exibição dd/mm/aaaa -> ISO (aaaa-mm-dd) para inputs type=date */
export function toISO(display: string): string {
  if (!display) return "";
  const [d, m, y] = display.split("/");
  if (!d || !m || !y) return "";
  return `${y}-${m}-${d}`;
}

/** exibição dd/mm/aaaa -> Date (ou null) */
export function parseBR(display: string): Date | null {
  if (!display) return null;
  const [d, m, y] = display.split("/").map(Number);
  if (!d || !m || !y) return null;
  return new Date(y, m - 1, d);
}

/** mantém só dígitos (para links wa.me) */
export function soDigitos(s: string): string {
  return (s || "").replace(/\D/g, "");
}

/** número -> "R$ 3.200,00" */
export function fmtBRL(n: number): string {
  return (n || 0).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

const MESES_EXTENSO = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
];

/** dd/mm/aaaa -> "21 de julho de 2025" */
export function dataExtenso(display: string): string {
  const d = parseBR(display);
  if (!d) return display;
  return `${d.getDate()} de ${MESES_EXTENSO[d.getMonth()]} de ${d.getFullYear()}`;
}
__PLANT_EOF__
echo "  ok  src/lib/utils.ts"

mkdir -p "src/lib"
cat > "src/lib/constants.ts" <<'__PLANT_EOF__'
import type { Status } from "@/types";

export const SERVICOS = [
  "Corte e Poda",
  "Remoção de Folhas / Galhos",
  "Paisagismo",
  "Limpeza Geral do Jardim",
  "Adubação",
  "Controle de pragas",
];

export const EQUIPAMENTOS = [
  "Roçadeira",
  "Soprador",
  "Rastelo",
  "Tesoura de Poda",
  "Tesoura de Cerca Viva",
];

export const EPIS = ["Luvas", "Botas", "Óculos de Proteção"];

export const CONDOS = [
  "Alameda das Palmeiras",
  "San Denis",
  "Quinta do Moinho",
  "Quinta do Loureiro",
  "dos Girassóis",
];

// Classes literais para o JIT do Tailwind capturar
export const STATUS_STYLES: Record<Status, string> = {
  "Finalizado": "bg-sucessoBg text-sucesso",
  "Em andamento": "bg-atencaoBg text-atencao",
  "Agendado": "bg-infoBg text-info",
  "Atrasado": "bg-erroBg text-erro",
};

export const EMPRESA = {
  nome: "Plant Jardinagem e Paisagismo",
  prestador: "Plant Jardinagem - Manutenção e Paisagismo / Claiton",
  cnpj: "42.704.559/0001-42",
  telefone: "(11) 97179-2236",
  whatsapp: "5511971792236",
  email: "plantjardinagem@gmail.com",
  instagram: "@plantjardinagem",
  endereco: "Av. Benedito de Andrade, 358 - Pereira Barreto - São Paulo",
};
__PLANT_EOF__
echo "  ok  src/lib/constants.ts"

mkdir -p "src/lib"
cat > "src/lib/proposta-conteudo.ts" <<'__PLANT_EOF__'
export const PROPOSTA = {
  intro:
    "Nossa proposta tem como objetivo não apenas atender a demanda de jardinagem e paisagismo, limpeza e conservação, mas criar uma parceria com o cliente e agregar qualidade de vida aos moradores. Atuamos no mercado tendo realizado projetos personalizados que buscam atender os conceitos de conforto, funcionalidade e estética de acordo com as características e necessidades de cada cliente. Trabalhamos com projetos paisagísticos, reformas e manutenção de jardins, podas de árvores e arbustos, projetos ornamentais, entre outros. Acreditamos e confiamos em nosso desempenho, e por isso ofertamos garantia total e satisfação completa.",

  referencias: [
    { condo: "Condomínio Residencial Quinta do Moinho", sindico: "Síndico Hélio Vidilino — (11) 94037-7744" },
    { condo: "Condomínio Residencial Quinta do Loureiro", sindico: "Síndico Tiago Mello — (11) 96149-8089" },
    { condo: "Condomínio dos Girassóis", sindico: "Síndico Thiago Maiellaro — (11) 99694-4188" },
  ],

  manutencao: [
    "Roçagem de gramas no padrão de 3 a 5 cm de altura, para que a raiz da grama não seja atingida pelo nylon; dessa forma ajuda na forração da grama e não deixa buracos que deem espaço para a erva daninha crescer;",
    "Poda de arbustos seguindo formato;",
    "Poda de pequenas árvores (poda de limpeza);",
    "Corte de grama dos taludes e área externa;",
    "Mão de obra para plantar mudas de árvores e plantas, ou substituição caso seja necessário;",
    "Coroamento e descompactação do solo onde há plantas;",
    "Mão de obra para criação de novas áreas paisagísticas;",
    "Mão de obra para controle de pragas com produto herbicida seletivo, aplicado com bomba de pulverizar (produto fornecido pelo cliente);",
    "Mão de obra para adubação, tanto com terra via solo quanto via foliar com pulverizador;",
    "Limpeza e remoção dos resíduos (saco de lixo por conta do cliente).",
  ],

  supervisao:
    "Auxílio do supervisor para a orientação dos serviços a serem realizados e para acompanhar os serviços que estão em andamento.",

  condicoesPagamento:
    "O pagamento será efetivado sempre 5 (cinco) dias após o serviço realizado, mediante a apresentação de nota fiscal.",

  agradecimento: "Aguardamos seu breve retorno e agradecemos a atenção.",
};

/** Linhas da seção "II. Execução do serviço", com os campos variáveis. */
export function execucaoLinhas(visitas: number, equipe: number): string[] {
  return [
    `${visitas} visitas mensais com equipe de ${equipe} pessoas, dividida em duas partes: 1ª visita — parte de cima: corte de grama, poda de arbustos e limpeza; 2ª visita — parte de baixo e externa do condomínio: poda de arbustos, corte de grama e limpeza.`,
    "2 visitas mensais de 1 jardineiro para limpeza de canteiros e supervisão geral. Essa visita é agendada (segunda a sexta-feira); na semana da visita individual não haverá visita da equipe.",
  ];
}
__PLANT_EOF__
echo "  ok  src/lib/proposta-conteudo.ts"

mkdir -p "src/lib"
cat > "src/lib/propostas.ts" <<'__PLANT_EOF__'
import { createClient } from "@/lib/supabase/client";
import type { Proposta } from "@/types";
import { fmtData, toISO } from "@/lib/utils";

interface Row {
  id: string;
  cliente_id: string | null;
  condo: string;
  data: string;
  valor_mensal: number | string;
  visitas_mensais: number;
  equipe: number;
  prazo_meses: number;
  validade_dias: number;
}

function toProposta(r: Row): Proposta {
  return {
    id: r.id,
    clienteId: r.cliente_id ?? undefined,
    condo: r.condo,
    data: fmtData(r.data),
    valorMensal: Number(r.valor_mensal),
    visitasMensais: r.visitas_mensais,
    equipe: r.equipe,
    prazoMeses: r.prazo_meses,
    validadeDias: r.validade_dias,
  };
}

export async function listPropostas(): Promise<Proposta[]> {
  const sb = createClient();
  const { data, error } = await sb.from("propostas").select("*").order("created_at", { ascending: false });
  if (error) throw error;
  return (data as Row[]).map(toProposta);
}

export async function getProposta(id: string): Promise<Proposta | null> {
  const sb = createClient();
  const { data, error } = await sb.from("propostas").select("*").eq("id", id).maybeSingle();
  if (error) throw error;
  return data ? toProposta(data as Row) : null;
}

export async function createProposta(p: Omit<Proposta, "id">): Promise<Proposta> {
  const sb = createClient();
  const { data, error } = await sb
    .from("propostas")
    .insert({
      cliente_id: p.clienteId ?? null,
      condo: p.condo,
      data: toISO(p.data),
      valor_mensal: p.valorMensal,
      visitas_mensais: p.visitasMensais,
      equipe: p.equipe,
      prazo_meses: p.prazoMeses,
      validade_dias: p.validadeDias,
    })
    .select("*")
    .single();
  if (error) throw error;
  return toProposta(data as Row);
}

export async function deleteProposta(id: string): Promise<void> {
  const sb = createClient();
  const { error } = await sb.from("propostas").delete().eq("id", id);
  if (error) throw error;
}
__PLANT_EOF__
echo "  ok  src/lib/propostas.ts"

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

export interface Proposta {
  id: string;
  clienteId?: string;
  condo: string;
  data: string;          // dd/mm/aaaa
  valorMensal: number;   // ex.: 3200
  visitasMensais: number;
  equipe: number;
  prazoMeses: number;
  validadeDias: number;
}

export type Papel = "admin" | "funcionario";
__PLANT_EOF__
echo "  ok  src/types/index.ts"

mkdir -p "src/components/ui"
cat > "src/components/ui/BottomNav.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, FileText, Wallet, Clock, type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

const items: { href: string; label: string; Icon: LucideIcon }[] = [
  { href: "/admin/home", label: "Home", Icon: Home },
  { href: "/admin/propostas", label: "Propostas", Icon: FileText },
  { href: "/admin/financeiro", label: "Financeiro", Icon: Wallet },
  { href: "/admin/ponto", label: "Ponto", Icon: Clock },
];

export function BottomNav() {
  const pathname = usePathname();
  // Formulários têm barra de ação própria — escondem a navegação.
  if (pathname.endsWith("/novo") || pathname.endsWith("/nova") || pathname.endsWith("/editar")) return null;

  return (
    <nav className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md border-t border-linha bg-surface px-2 pb-3 pt-2">
      {items.map(({ href, label, Icon }) => {
        const on =
          pathname.startsWith(href) ||
          (href === "/admin/home" && pathname.startsWith("/admin/relatorios"));
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex flex-1 flex-col items-center gap-1 rounded-[10px] px-1 py-[7px] text-[11px] font-semibold",
              on ? "bg-verde-50 text-verde-700" : "text-tintaMuda"
            )}
          >
            <Icon size={22} strokeWidth={on ? 2.4 : 2} />
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
__PLANT_EOF__
echo "  ok  src/components/ui/BottomNav.tsx"

mkdir -p "src/components/propostas"
cat > "src/components/propostas/PropostaForm.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Cliente } from "@/types";
import { listClientes } from "@/lib/clientes";
import { createProposta } from "@/lib/propostas";
import { fmtData } from "@/lib/utils";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const hojeISO = () => {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
};

export function PropostaForm() {
  const router = useRouter();
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [condo, setCondo] = useState("");
  const [dataISO, setDataISO] = useState(hojeISO());
  const [valor, setValor] = useState("3200");
  const [visitas, setVisitas] = useState("2");
  const [equipe, setEquipe] = useState("7");
  const [prazo, setPrazo] = useState("24");
  const [validade, setValidade] = useState("30");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    listClientes().then((c) => {
      setClientes(c);
      setCondo((atual) => atual || c[0]?.nome || "");
    });
  }, []);

  const salvar = async () => {
    if (!condo) return;
    setSaving(true);
    try {
      const cli = clientes.find((c) => c.nome === condo);
      const nova = await createProposta({
        condo,
        clienteId: cli?.id,
        data: fmtData(dataISO),
        valorMensal: Number(valor) || 0,
        visitasMensais: Number(visitas) || 0,
        equipe: Number(equipe) || 0,
        prazoMeses: Number(prazo) || 0,
        validadeDias: Number(validade) || 0,
      });
      router.push(`/admin/propostas/${nova.id}`);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Nova proposta</span>
      </header>

      <div className="flex flex-col gap-1 px-[18px] pt-2">
        <Field label="Condomínio">
          <select value={condo} onChange={(e) => setCondo(e.target.value)} className={inputClass}>
            {clientes.map((c) => (
              <option key={c.id}>{c.nome}</option>
            ))}
          </select>
        </Field>
        <Field label="Valor mensal (R$)">
          <input type="number" inputMode="decimal" value={valor} onChange={(e) => setValor(e.target.value)} className={inputClass} />
        </Field>
        <Field label="Data da proposta">
          <input type="date" value={dataISO} onChange={(e) => setDataISO(e.target.value)} className={inputClass} />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Visitas / mês">
            <input type="number" value={visitas} onChange={(e) => setVisitas(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Equipe (pessoas)">
            <input type="number" value={equipe} onChange={(e) => setEquipe(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Prazo (meses)">
            <input type="number" value={prazo} onChange={(e) => setPrazo(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Validade (dias)">
            <input type="number" value={validade} onChange={(e) => setValidade(e.target.value)} className={inputClass} />
          </Field>
        </div>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] py-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>{saving ? "Salvando…" : "Gerar proposta"}</Button>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/propostas/PropostaForm.tsx"

mkdir -p "src/components/propostas"
cat > "src/components/propostas/PropostaCard.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import type { Proposta } from "@/types";
import { fmtBRL } from "@/lib/utils";

export function PropostaCard({ p }: { p: Proposta }) {
  return (
    <Link href={`/admin/propostas/${p.id}`} className="block rounded-2xl border border-linha bg-surface p-4 shadow-s1">
      <div className="flex items-start justify-between gap-2">
        <div className="font-display text-[16px] font-semibold text-verde-900">{p.condo}</div>
        <div className="flex-none font-mono text-[11px] text-tintaMuda">{p.data}</div>
      </div>
      <div className="mt-1 text-[13px] text-tintaMuda">
        Manutenção · {p.visitasMensais} visitas/mês · equipe de {p.equipe}
      </div>
      <div className="mt-2 text-[18px] font-bold text-verde-700">
        {fmtBRL(p.valorMensal)}
        <span className="text-[12px] font-medium text-tintaMuda"> / mês</span>
      </div>
    </Link>
  );
}
__PLANT_EOF__
echo "  ok  src/components/propostas/PropostaCard.tsx"

mkdir -p "src/components/propostas"
cat > "src/components/propostas/PropostaPreview.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Trash2 } from "lucide-react";
import type { Proposta } from "@/types";
import { getProposta, deleteProposta } from "@/lib/propostas";
import { fmtBRL, dataExtenso } from "@/lib/utils";
import { PROPOSTA, execucaoLinhas } from "@/lib/proposta-conteudo";
import { Button } from "@/components/ui/Button";

export function PropostaPreview({ id }: { id: string }) {
  const router = useRouter();
  const [p, setP] = useState<Proposta | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProposta(id).then(setP).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Carregando…</div>;
  if (!p) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Proposta não encontrada.</div>;

  const remover = async () => {
    await deleteProposta(p.id);
    router.push("/admin/propostas");
  };
  const enviar = () => {
    const txt = encodeURIComponent(
      `Olá! Segue a proposta comercial da Plant Jardinagem para o ${p.condo}. Investimento: ${fmtBRL(p.valorMensal)} / mês.`
    );
    window.open(`https://wa.me/?text=${txt}`, "_blank");
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.push("/admin/propostas")} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="flex-1 font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Proposta</span>
        <button onClick={remover} aria-label="Excluir" className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-tintaMuda hover:bg-erroBg hover:text-erro">
          <Trash2 size={16} />
        </button>
      </header>

      <article className="mx-3.5 mt-1.5 overflow-hidden rounded-[18px] border border-linha bg-surface shadow-s2">
        <div className="bg-salvia px-5 py-6 text-white">
          <div className="font-display text-[26px] font-semibold leading-tight">Proposta Comercial</div>
          <div className="mt-0.5 text-[15px] opacity-95">{p.condo}</div>
          <div className="mt-1 font-mono text-[11px] opacity-80">São Paulo, {dataExtenso(p.data)}.</div>
        </div>

        <div className="space-y-4 p-5">
          <p className="text-[13px] leading-relaxed text-tintaMuda">{PROPOSTA.intro}</p>

          <div>
            <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Investimento</h3>
            <div className="mt-1 text-[24px] font-bold text-verde-700">
              {fmtBRL(p.valorMensal)}
              <span className="text-[13px] font-medium text-tintaMuda"> / mês</span>
            </div>
          </div>

          <div>
            <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Execução do serviço</h3>
            <ul className="mt-1 list-disc space-y-1.5 pl-5 text-[13px] leading-relaxed text-tinta">
              {execucaoLinhas(p.visitasMensais, p.equipe).map((l, i) => (
                <li key={i}>{l}</li>
              ))}
            </ul>
          </div>

          <div className="border-t border-linha pt-3 text-[12px] text-tintaMuda">
            Prazo do contrato: {p.prazoMeses} meses · Validade da proposta: {p.validadeDias} dias
          </div>
        </div>
      </article>

      <div className="flex gap-3 px-[18px] py-2">
        <Button variant="gold" block onClick={() => window.open(`/api/propostas/${p.id}/pdf`, "_blank")}>Gerar PDF</Button>
        <Button block onClick={enviar}>Enviar</Button>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/propostas/PropostaPreview.tsx"

mkdir -p "src/components/pdf"
cat > "src/components/pdf/PropostaPDF.tsx" <<'__PLANT_EOF__'
import { Document, Page, View, Text, Image, StyleSheet } from "@react-pdf/renderer";
import type { Proposta } from "@/types";
import { EMPRESA } from "@/lib/constants";
import { PROPOSTA, execucaoLinhas } from "@/lib/proposta-conteudo";
import { fmtBRL, dataExtenso } from "@/lib/utils";

const C = {
  sage: "#8A9A76",
  escuro: "#1A3022",
  titulo: "#13251A",
  claro: "#E9EEDD",
  linha: "#6B4A2E",
};

const s = StyleSheet.create({
  page: { backgroundColor: C.sage, paddingTop: 54, paddingBottom: 96, paddingHorizontal: 54, fontSize: 11, color: C.escuro, fontFamily: "Helvetica", lineHeight: 1.5 },
  frame: { position: "absolute", top: 22, left: 22, right: 22, bottom: 22, borderWidth: 1, borderColor: C.linha, borderRadius: 2 },
  logo: { position: "absolute", bottom: 30, right: 34, width: 60, height: 60, objectFit: "contain" },

  titulo: { fontSize: 38, fontFamily: "Helvetica-Bold", color: C.titulo, lineHeight: 1.05 },
  subtitulo: { fontSize: 14, color: C.escuro, marginTop: 2 },
  local: { fontSize: 11, color: C.claro, textAlign: "right", marginTop: 26, marginBottom: 22 },
  paragrafo: { fontSize: 11.5, color: C.escuro, marginBottom: 14 },

  refTitulo: { fontSize: 12, fontFamily: "Helvetica-Bold", color: C.escuro, marginBottom: 8 },
  refCondo: { fontSize: 11, color: C.claro },
  refSindico: { fontSize: 11, color: C.claro, marginBottom: 10 },

  h1: { fontSize: 24, fontFamily: "Helvetica-Bold", color: C.titulo, marginBottom: 18 },
  h2: { fontSize: 13, fontFamily: "Helvetica-Bold", color: C.escuro, marginTop: 14, marginBottom: 8 },
  texto: { fontSize: 11.5, color: C.escuro, marginBottom: 10 },
  investimento: { fontSize: 18, fontFamily: "Helvetica-Bold", color: C.titulo, marginBottom: 6 },

  bulletRow: { flexDirection: "row", marginBottom: 8 },
  bulletDot: { width: 14, fontSize: 11.5, color: C.escuro },
  bulletText: { flex: 1, fontSize: 11.5, color: C.escuro },

  claro: { fontSize: 11, color: C.claro, marginBottom: 8 },
  contatoBox: { marginTop: 22, alignItems: "flex-end" },
  contato: { fontSize: 11, color: C.claro },
  footer: { marginTop: 24, alignItems: "center" },
  footerTxt: { fontSize: 9.5, color: C.claro, textAlign: "center" },
});

function Bullet({ children }: { children: string }) {
  return (
    <View style={s.bulletRow}>
      <Text style={s.bulletDot}>•</Text>
      <Text style={s.bulletText}>{children}</Text>
    </View>
  );
}

export function PropostaPDF({ proposta, logoSrc }: { proposta: Proposta; logoSrc?: string }) {
  const p = proposta;
  return (
    <Document title={`Proposta - ${p.condo}`}>
      <Page size="A4" style={s.page}>
        <View style={s.frame} fixed />
        {logoSrc ? <Image src={logoSrc} style={s.logo} fixed /> : null}

        {/* Página 1 */}
        <Text style={s.titulo}>Proposta Comercial</Text>
        <Text style={s.subtitulo}>{p.condo}</Text>
        <Text style={s.local}>São Paulo, {dataExtenso(p.data)}.</Text>
        <Text style={s.paragrafo}>{PROPOSTA.intro}</Text>

        <Text style={s.refTitulo}>Referências:</Text>
        {PROPOSTA.referencias.map((r, i) => (
          <View key={i}>
            <Text style={s.refCondo}>{r.condo}</Text>
            <Text style={s.refSindico}>{r.sindico}</Text>
          </View>
        ))}

        {/* Página 2 */}
        <Text style={s.h1} break>Escopo da Proposta</Text>
        <Text style={s.h2}>I. MANUTENÇÃO</Text>
        <Text style={s.texto}>Serviços a serem executados:</Text>
        {PROPOSTA.manutencao.map((m, i) => (
          <Bullet key={i}>{m}</Bullet>
        ))}

        {/* Página 3 */}
        <Text style={s.h2} break>II. EXECUÇÃO DO SERVIÇO</Text>
        {execucaoLinhas(p.visitasMensais, p.equipe).map((l, i) => (
          <Bullet key={i}>{l}</Bullet>
        ))}
        <Text style={s.texto}>{PROPOSTA.supervisao}</Text>

        <Text style={s.h2}>III. INVESTIMENTO</Text>
        <Text style={s.investimento}>{fmtBRL(p.valorMensal)} / Mês</Text>

        <Text style={s.h2}>IV. CONDIÇÕES GERAIS DE PAGAMENTO</Text>
        <Text style={s.texto}>{PROPOSTA.condicoesPagamento}</Text>

        <Text style={s.h2}>V. PRAZO DE EXECUÇÃO DA PRESTAÇÃO DOS SERVIÇOS</Text>
        <Text style={s.texto}>
          O início e a execução da prestação dos serviços se darão após a assinatura de contrato, sendo certo que a
          referida prestação dos serviços será pelo prazo de {p.prazoMeses} meses, podendo ser prorrogado.
        </Text>

        <Text style={s.claro}>
          PRAZO DE VALIDADE DESTA PROPOSTA COMERCIAL: {p.validadeDias} dias contados da data de sua apresentação.
        </Text>
        <Text style={s.claro}>{PROPOSTA.agradecimento}</Text>

        <View style={s.contatoBox}>
          <Text style={s.contato}>Comercial</Text>
          <Text style={s.contato}>{EMPRESA.email}</Text>
          <Text style={s.contato}>contato: {EMPRESA.telefone}</Text>
          <Text style={s.contato}>{EMPRESA.instagram}</Text>
        </View>

        <View style={s.footer}>
          <Text style={s.footerTxt}>PLANT JARDINAGEM E PAISAGISMO</Text>
          <Text style={s.footerTxt}>CNPJ {EMPRESA.cnpj}</Text>
          <Text style={s.footerTxt}>{EMPRESA.endereco}</Text>
        </View>
      </Page>
    </Document>
  );
}
__PLANT_EOF__
echo "  ok  src/components/pdf/PropostaPDF.tsx"

mkdir -p "src/app/admin/propostas"
cat > "src/app/admin/propostas/page.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import type { Proposta } from "@/types";
import { listPropostas } from "@/lib/propostas";
import { PropostaCard } from "@/components/propostas/PropostaCard";

export default function PropostasPage() {
  const [propostas, setPropostas] = useState<Proposta[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listPropostas().then(setPropostas).finally(() => setLoading(false));
  }, []);

  return (
    <div className="pb-28">
      <header className="px-[18px] pb-2 pt-5">
        <div className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Admin · Claiton</div>
        <h1 className="mt-0.5 font-display text-[28px] font-semibold tracking-tight text-verde-900">Propostas</h1>
      </header>

      <section className="px-[18px]">
        {loading ? (
          <div className="flex flex-col gap-3.5">
            <div className="h-24 animate-pulse rounded-2xl border border-linha bg-surface2" />
            <div className="h-24 animate-pulse rounded-2xl border border-linha bg-surface2" />
          </div>
        ) : propostas.length === 0 ? (
          <p className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
            Nenhuma proposta ainda. Toque no + para criar a primeira.
          </p>
        ) : (
          <div className="flex flex-col gap-3.5">
            {propostas.map((p) => <PropostaCard key={p.id} p={p} />)}
          </div>
        )}
      </section>

      <div className="pointer-events-none fixed inset-x-0 bottom-[84px] z-30 mx-auto flex max-w-md justify-end px-[18px]">
        <Link href="/admin/propostas/nova" aria-label="Nova proposta" className="pointer-events-auto grid h-14 w-14 place-items-center rounded-full bg-verde-700 text-[28px] text-white shadow-s3">+</Link>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/app/admin/propostas/page.tsx"

mkdir -p "src/app/admin/propostas/nova"
cat > "src/app/admin/propostas/nova/page.tsx" <<'__PLANT_EOF__'
import { PropostaForm } from "@/components/propostas/PropostaForm";
export default function NovaPropostaPage() {
  return <PropostaForm />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/propostas/nova/page.tsx"

mkdir -p "src/app/admin/propostas/[id]"
cat > "src/app/admin/propostas/[id]/page.tsx" <<'__PLANT_EOF__'
import { PropostaPreview } from "@/components/propostas/PropostaPreview";
export default function PropostaPage({ params }: { params: { id: string } }) {
  return <PropostaPreview id={params.id} />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/propostas/[id]/page.tsx"

mkdir -p "src/app/api/propostas/[id]/pdf"
cat > "src/app/api/propostas/[id]/pdf/route.ts" <<'__PLANT_EOF__'
import { NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { createClient } from "@/lib/supabase/server";
import { PropostaPDF } from "@/components/pdf/PropostaPDF";
import type { Proposta } from "@/types";
import { fmtData } from "@/lib/utils";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

interface Row {
  id: string;
  cliente_id: string | null;
  condo: string;
  data: string;
  valor_mensal: number | string;
  visitas_mensais: number;
  equipe: number;
  prazo_meses: number;
  validade_dias: number;
}

async function carregarLogo(origin: string): Promise<string | undefined> {
  try {
    const res = await fetch(`${origin}/logo.png`);
    if (!res.ok) return undefined;
    const buf = Buffer.from(await res.arrayBuffer());
    return `data:image/png;base64,${buf.toString("base64")}`;
  } catch {
    return undefined;
  }
}

export async function GET(req: Request, { params }: { params: { id: string } }) {
  const sb = createClient();
  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return new NextResponse("Não autorizado", { status: 401 });

  const { data, error } = await sb.from("propostas").select("*").eq("id", params.id).maybeSingle();
  if (error || !data) return new NextResponse("Proposta não encontrada", { status: 404 });

  const r = data as Row;
  const proposta: Proposta = {
    id: r.id,
    clienteId: r.cliente_id ?? undefined,
    condo: r.condo,
    data: fmtData(r.data),
    valorMensal: Number(r.valor_mensal),
    visitasMensais: r.visitas_mensais,
    equipe: r.equipe,
    prazoMeses: r.prazo_meses,
    validadeDias: r.validade_dias,
  };

  const logoSrc = await carregarLogo(new URL(req.url).origin);
  const buffer = await renderToBuffer(PropostaPDF({ proposta, logoSrc }));
  const slug = proposta.condo.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

  return new NextResponse(new Uint8Array(buffer), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="proposta-${slug}.pdf"`,
    },
  });
}
__PLANT_EOF__
echo "  ok  src/app/api/propostas/[id]/pdf/route.ts"

echo ""
echo "IMPORTANTE: commite TUDO ->  git add -A && git commit -m \"fix: módulo de propostas completo\" && git push"
