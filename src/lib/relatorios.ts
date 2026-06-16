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
