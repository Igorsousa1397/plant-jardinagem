import { createClient } from "@/lib/supabase/server";

export type Papel = "admin" | "funcionario";

// Retorna o papel do usuário logado. null = não autenticado.
// Logado sem perfil cai em "funcionario" (padrão seguro).
export async function getPapel(): Promise<Papel | null> {
  const sb = createClient();
  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return null;

  const { data } = await sb.from("profiles").select("papel").eq("id", user.id).maybeSingle();
  return (data?.papel as Papel) ?? "funcionario";
}
