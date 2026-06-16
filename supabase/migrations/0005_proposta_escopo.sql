-- Modelo de escopo selecionável na proposta
alter table public.propostas
  add column if not exists escopo text not null default 'completo';
