#!/usr/bin/env bash
# Plant Jardinagem — edição de proposta (salva por cima)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando edição de proposta..."

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
  servicos: string[] | null;
  execucao: string[] | null;
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
    servicos: r.servicos ?? [],
    execucao: r.execucao ?? [],
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
      servicos: p.servicos,
      execucao: p.execucao,
      prazo_meses: p.prazoMeses,
      validade_dias: p.validadeDias,
    })
    .select("*")
    .single();
  if (error) throw error;
  return toProposta(data as Row);
}

export async function updateProposta(id: string, p: Omit<Proposta, "id">): Promise<Proposta> {
  const sb = createClient();
  const { data, error } = await sb
    .from("propostas")
    .update({
      cliente_id: p.clienteId ?? null,
      condo: p.condo,
      data: toISO(p.data),
      valor_mensal: p.valorMensal,
      visitas_mensais: p.visitasMensais,
      equipe: p.equipe,
      servicos: p.servicos,
      execucao: p.execucao,
      prazo_meses: p.prazoMeses,
      validade_dias: p.validadeDias,
    })
    .eq("id", id)
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

mkdir -p "src/components/propostas"
cat > "src/components/propostas/PropostaForm.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Cliente, Proposta } from "@/types";
import { listClientes } from "@/lib/clientes";
import { createProposta, updateProposta } from "@/lib/propostas";
import { fmtData, toISO } from "@/lib/utils";
import { MANUTENCAO_OPCOES, EXECUCAO_OPCOES, EXECUCAO_PADRAO, interpola } from "@/lib/proposta-conteudo";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const hojeISO = () => {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
};

function Check({ checked, onChange, children }: { checked: boolean; onChange: () => void; children: React.ReactNode }) {
  return (
    <label className="flex cursor-pointer items-start gap-2.5 py-1.5">
      <input type="checkbox" checked={checked} onChange={onChange} className="mt-0.5 h-4 w-4 flex-none accent-verde-700" />
      <span className="text-[13px] leading-snug text-tinta">{children}</span>
    </label>
  );
}

export function PropostaForm({ inicial }: { inicial?: Proposta }) {
  const router = useRouter();
  const edicao = !!inicial;

  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [cliente, setCliente] = useState(inicial?.condo ?? "");
  const [dataISO, setDataISO] = useState(inicial ? toISO(inicial.data) : hojeISO());
  const [valor, setValor] = useState(inicial ? String(inicial.valorMensal) : "3200");
  const [visitas, setVisitas] = useState(inicial ? String(inicial.visitasMensais) : "2");
  const [equipe, setEquipe] = useState(inicial ? String(inicial.equipe) : "7");
  const [prazo, setPrazo] = useState(inicial ? String(inicial.prazoMeses) : "24");
  const [validade, setValidade] = useState(inicial ? String(inicial.validadeDias) : "30");
  const [execSel, setExecSel] = useState<string[]>(() => {
    if (!inicial) return EXECUCAO_PADRAO;
    return EXECUCAO_OPCOES.filter((o) =>
      inicial.execucao.includes(interpola(o.texto, inicial.visitasMensais, inicial.equipe))
    ).map((o) => o.id);
  });
  const [manutSel, setManutSel] = useState<number[]>(() => {
    if (!inicial) return MANUTENCAO_OPCOES.map((_, i) => i);
    return MANUTENCAO_OPCOES.map((m, i) => ({ m, i }))
      .filter(({ m }) => inicial.servicos.includes(m))
      .map(({ i }) => i);
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    listClientes().then(setClientes);
  }, []);

  const nV = Number(visitas) || 0;
  const nE = Number(equipe) || 0;

  const toggleExec = (id: string) =>
    setExecSel((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]));
  const toggleManut = (i: number) =>
    setManutSel((s) => (s.includes(i) ? s.filter((x) => x !== i) : [...s, i]));

  const salvar = async () => {
    if (!cliente.trim()) return;
    setSaving(true);
    try {
      const cli = clientes.find((c) => c.nome.toLowerCase() === cliente.trim().toLowerCase());
      const execucao = EXECUCAO_OPCOES.filter((o) => execSel.includes(o.id)).map((o) => interpola(o.texto, nV, nE));
      const servicos = MANUTENCAO_OPCOES.filter((_, i) => manutSel.includes(i));
      const dados = {
        condo: cliente.trim(),
        clienteId: cli?.id,
        data: fmtData(dataISO),
        valorMensal: Number(valor) || 0,
        visitasMensais: nV,
        equipe: nE,
        servicos,
        execucao,
        prazoMeses: Number(prazo) || 0,
        validadeDias: Number(validade) || 0,
      };
      if (inicial) {
        await updateProposta(inicial.id, dados);
        router.push(`/admin/propostas/${inicial.id}`);
      } else {
        const nova = await createProposta(dados);
        router.push(`/admin/propostas/${nova.id}`);
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">{edicao ? "Editar proposta" : "Nova proposta"}</span>
      </header>

      <div className="flex flex-col gap-1 px-[18px] pt-2">
        <Field label="Cliente">
          <input
            list="clientes-list"
            value={cliente}
            onChange={(e) => setCliente(e.target.value)}
            className={inputClass}
            placeholder="Nome do cliente / condomínio"
          />
          <datalist id="clientes-list">
            {clientes.map((c) => (
              <option key={c.id} value={c.nome} />
            ))}
          </datalist>
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Visitas / mês">
            <input type="number" value={visitas} onChange={(e) => setVisitas(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Equipe (pessoas)">
            <input type="number" value={equipe} onChange={(e) => setEquipe(e.target.value)} className={inputClass} />
          </Field>
        </div>

        <Field label="Valor mensal (R$)">
          <input type="number" inputMode="decimal" value={valor} onChange={(e) => setValor(e.target.value)} className={inputClass} />
        </Field>
        <Field label="Data da proposta">
          <input type="date" value={dataISO} onChange={(e) => setDataISO(e.target.value)} className={inputClass} />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Prazo (meses)">
            <input type="number" value={prazo} onChange={(e) => setPrazo(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Validade (dias)">
            <input type="number" value={validade} onChange={(e) => setValidade(e.target.value)} className={inputClass} />
          </Field>
        </div>

        <div className="mt-2">
          <h2 className="pb-1 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">Execução do serviço</h2>
          <div className="rounded-2xl border border-linha bg-surface px-3.5 py-1">
            {EXECUCAO_OPCOES.map((o) => (
              <Check key={o.id} checked={execSel.includes(o.id)} onChange={() => toggleExec(o.id)}>
                {interpola(o.texto, nV, nE)}
              </Check>
            ))}
          </div>
        </div>

        <div className="mt-1">
          <h2 className="pb-1 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">Serviços de manutenção</h2>
          <div className="rounded-2xl border border-linha bg-surface px-3.5 py-1">
            {MANUTENCAO_OPCOES.map((m, i) => (
              <Check key={i} checked={manutSel.includes(i)} onChange={() => toggleManut(i)}>
                {m}
              </Check>
            ))}
          </div>
        </div>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] py-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>
          {saving ? "Salvando…" : edicao ? "Salvar alterações" : "Gerar proposta"}
        </Button>
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/propostas/PropostaForm.tsx"

mkdir -p "src/components/propostas"
cat > "src/components/propostas/PropostaPreview.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Trash2, Pencil } from "lucide-react";
import type { Proposta } from "@/types";
import { getProposta, deleteProposta } from "@/lib/propostas";
import { fmtBRL, dataExtenso } from "@/lib/utils";
import { PROPOSTA } from "@/lib/proposta-conteudo";
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
        <button onClick={() => router.push(`/admin/propostas/${p.id}/editar`)} aria-label="Editar" className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-verde-800 hover:bg-verde-50">
          <Pencil size={15} />
        </button>
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

          {p.execucao.length > 0 && (
            <div>
              <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Execução do serviço</h3>
              <ul className="mt-1 list-disc space-y-1.5 pl-5 text-[13px] leading-relaxed text-tinta">
                {p.execucao.map((l, i) => <li key={i}>{l}</li>)}
              </ul>
            </div>
          )}

          {p.servicos.length > 0 && (
            <div>
              <h3 className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Serviços de manutenção ({p.servicos.length})</h3>
              <ul className="mt-1 list-disc space-y-1.5 pl-5 text-[13px] leading-relaxed text-tinta">
                {p.servicos.map((m, i) => <li key={i}>{m}</li>)}
              </ul>
            </div>
          )}

          <div className="border-t border-linha pt-3 text-[12px] text-tintaMuda">
            Prazo do contrato: {p.prazoMeses} meses · Validade: {p.validadeDias} dias
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

mkdir -p "src/app/admin/propostas/[id]/editar"
cat > "src/app/admin/propostas/[id]/editar/page.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import type { Proposta } from "@/types";
import { getProposta } from "@/lib/propostas";
import { PropostaForm } from "@/components/propostas/PropostaForm";

export default function EditarPropostaPage({ params }: { params: { id: string } }) {
  const [p, setP] = useState<Proposta | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProposta(params.id).then(setP).finally(() => setLoading(false));
  }, [params.id]);

  if (loading) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Carregando…</div>;
  if (!p) return <div className="px-[18px] py-10 text-sm text-tintaMuda">Proposta não encontrada.</div>;
  return <PropostaForm inicial={p} />;
}
__PLANT_EOF__
echo "  ok  src/app/admin/propostas/[id]/editar/page.tsx"

echo ""
echo "Feito (sem mudança no banco). Reinicie o npm run dev ou git add -A && commit && push."
