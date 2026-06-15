#!/usr/bin/env bash
# Plant Jardinagem — papéis (admin/funcionario) + redirect por perfil
# Uso: na raiz do projeto ->  bash apply-roles.sh
set -e

if [ ! -f package.json ]; then
  echo "Erro: rode na RAIZ do projeto (onde está o package.json)."; exit 1
fi
echo "Aplicando papéis/perfil..."

mkdir -p "supabase/migrations"
cat > "supabase/migrations/0002_profiles.sql" <<'__PLANT_EOF__'
-- Perfis e papéis (admin / funcionario)

do $$ begin
  create type papel as enum ('admin','funcionario');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nome       text,
  papel      papel not null default 'funcionario',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- cada usuário lê o próprio perfil
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());

-- cria o perfil automaticamente quando um usuário é criado (default: funcionario)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome, papel)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), 'funcionario')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- backfill: cria perfil para usuários que já existiam (todos como funcionario)
insert into public.profiles (id, nome, papel)
select id, email, 'funcionario' from auth.users
on conflict (id) do nothing;

-- ===== PROMOVA O ADMIN =====
-- Troque o e-mail pelo seu/do Claiton e rode:
-- update public.profiles set papel = 'admin'
-- where id = (select id from auth.users where email = 'seu-email@exemplo.com');
__PLANT_EOF__
echo "  ok  supabase/migrations/0002_profiles.sql"

mkdir -p "src/lib/supabase"
cat > "src/lib/supabase/profile.ts" <<'__PLANT_EOF__'
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
__PLANT_EOF__
echo "  ok  src/lib/supabase/profile.ts"

mkdir -p "src/app"
cat > "src/app/page.tsx" <<'__PLANT_EOF__'
import { redirect } from "next/navigation";
import { getPapel } from "@/lib/supabase/profile";

export default async function Home() {
  const papel = await getPapel();
  if (!papel) redirect("/login");
  redirect(papel === "admin" ? "/admin/home" : "/campo/ponto");
}
__PLANT_EOF__
echo "  ok  src/app/page.tsx"

mkdir -p "src/app/admin"
cat > "src/app/admin/layout.tsx" <<'__PLANT_EOF__'
import { redirect } from "next/navigation";
import { getPapel } from "@/lib/supabase/profile";
import { ReportsProvider } from "@/components/relatorios/store";
import { BottomNav } from "@/components/ui/BottomNav";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const papel = await getPapel();
  if (!papel) redirect("/login");
  if (papel !== "admin") redirect("/campo/ponto");

  return (
    <ReportsProvider>
      <div className="mx-auto min-h-screen max-w-md bg-papel">
        {children}
        <BottomNav />
      </div>
    </ReportsProvider>
  );
}
__PLANT_EOF__
echo "  ok  src/app/admin/layout.tsx"

echo ""
echo "Falta rodar o SQL no Supabase (supabase/migrations/0002_profiles.sql)"
echo "e promover seu usuário a admin. Depois: reinicie o npm run dev."
