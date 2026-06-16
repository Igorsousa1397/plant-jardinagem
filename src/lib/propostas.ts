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
