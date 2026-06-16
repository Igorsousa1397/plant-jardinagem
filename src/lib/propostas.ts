import { createClient } from "@/lib/supabase/client";
import type { Proposta } from "@/types";
import { fmtData, toISO } from "@/lib/utils";
import { ESCOPO_PADRAO } from "@/lib/proposta-conteudo";

interface Row {
  id: string;
  cliente_id: string | null;
  condo: string;
  data: string;
  valor_mensal: number | string;
  escopo: string | null;
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
    escopo: r.escopo ?? ESCOPO_PADRAO,
    prazoMeses: r.prazo_meses,
    validadeDias: r.validade_dias,
    visitasMensais: r.visitas_mensais,
    equipe: r.equipe,
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
      escopo: p.escopo,
      prazo_meses: p.prazoMeses,
      validade_dias: p.validadeDias,
      visitas_mensais: p.visitasMensais ?? 2,
      equipe: p.equipe ?? 7,
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
