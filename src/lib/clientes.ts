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
