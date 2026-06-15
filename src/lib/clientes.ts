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
