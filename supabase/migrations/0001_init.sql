-- Plant Jardinagem — schema inicial
-- Rode no SQL Editor do Supabase (cole tudo e Run), ou via `supabase db push`.

create extension if not exists "pgcrypto";

-- Status do relatório (mesmos valores do app)
do $$ begin
  create type relatorio_status as enum ('Finalizado','Em andamento','Agendado','Atrasado');
exception when duplicate_object then null; end $$;

-- Clientes (condomínios)
create table if not exists public.clientes (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  sindico    text,
  telefone   text,
  created_at timestamptz not null default now()
);

-- Relatórios de serviço
create table if not exists public.relatorios (
  id             uuid primary key default gen_random_uuid(),
  condo          text not null,
  cliente_id     uuid references public.clientes(id) on delete set null,
  data           date not null,
  duracao        text not null default '',
  status         relatorio_status not null default 'Finalizado',
  servicos       text[] not null default '{}',
  equipamentos   text[] not null default '{}',
  epi            text[] not null default '{}',
  observacoes    text not null default '',
  proxima_visita date,
  fotos_antes    text[] not null default '{}',
  fotos_depois   text[] not null default '{}',
  arquivado      boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists relatorios_arquivado_idx      on public.relatorios (arquivado);
create index if not exists relatorios_proxima_visita_idx on public.relatorios (proxima_visita);
create index if not exists relatorios_cliente_idx        on public.relatorios (cliente_id);

-- updated_at automático
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists relatorios_set_updated_at on public.relatorios;
create trigger relatorios_set_updated_at
  before update on public.relatorios
  for each row execute function public.set_updated_at();

-- ===================== RLS =====================
alter table public.clientes   enable row level security;
alter table public.relatorios enable row level security;

-- Admin autenticado: acesso total (refine quando entrar o papel de funcionário)
drop policy if exists clientes_auth_all on public.clientes;
create policy clientes_auth_all on public.clientes
  for all to authenticated using (true) with check (true);

drop policy if exists relatorios_auth_all on public.relatorios;
create policy relatorios_auth_all on public.relatorios
  for all to authenticated using (true) with check (true);

-- ============= Storage: fotos antes/depois =============
insert into storage.buckets (id, name, public)
values ('relatorios','relatorios', true)
on conflict (id) do nothing;

drop policy if exists relatorios_fotos_read on storage.objects;
create policy relatorios_fotos_read on storage.objects
  for select using (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_insert on storage.objects;
create policy relatorios_fotos_insert on storage.objects
  for insert to authenticated with check (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_update on storage.objects;
create policy relatorios_fotos_update on storage.objects
  for update to authenticated using (bucket_id = 'relatorios');

drop policy if exists relatorios_fotos_delete on storage.objects;
create policy relatorios_fotos_delete on storage.objects
  for delete to authenticated using (bucket_id = 'relatorios');

-- ===================== DEV (opcional) =====================
-- Enquanto NÃO houver login, descomente para testar o app sem autenticação.
-- Remova antes de ir pra produção.
-- create policy dev_anon_clientes   on public.clientes   for all to anon using (true) with check (true);
-- create policy dev_anon_relatorios on public.relatorios for all to anon using (true) with check (true);
