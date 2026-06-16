-- Itens selecionáveis (manutenção e execução) da proposta
alter table public.propostas
  add column if not exists servicos text[] not null default '{}',
  add column if not exists execucao text[] not null default '{}';
