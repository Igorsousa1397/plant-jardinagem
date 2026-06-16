-- Propostas comerciais

create table if not exists public.propostas (
  id              uuid primary key default gen_random_uuid(),
  cliente_id      uuid references public.clientes(id) on delete set null,
  condo           text not null,
  data            date not null,
  valor_mensal    numeric not null default 0,
  visitas_mensais int not null default 2,
  equipe          int not null default 7,
  prazo_meses     int not null default 24,
  validade_dias   int not null default 30,
  created_at      timestamptz not null default now()
);

create index if not exists propostas_created_idx on public.propostas (created_at desc);

alter table public.propostas enable row level security;
drop policy if exists propostas_auth_all on public.propostas;
create policy propostas_auth_all on public.propostas
  for all to authenticated using (true) with check (true);
