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
