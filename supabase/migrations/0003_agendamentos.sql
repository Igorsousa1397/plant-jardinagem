-- Agendamentos (visitas planejadas) — independentes dos relatórios

create table if not exists public.agendamentos (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  uuid references public.clientes(id) on delete set null,
  condo       text not null,
  data        date not null,
  observacao  text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists agendamentos_data_idx on public.agendamentos (data);

alter table public.agendamentos enable row level security;

drop policy if exists agendamentos_auth_all on public.agendamentos;
create policy agendamentos_auth_all on public.agendamentos
  for all to authenticated using (true) with check (true);
