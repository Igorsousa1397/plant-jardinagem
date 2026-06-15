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
