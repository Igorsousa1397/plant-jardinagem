-- Soft-delete de clientes (mantém em "arquivados")
alter table public.clientes
  add column if not exists arquivado boolean not null default false;
