-- Marcar agendamento como concluído (histórico)
alter table public.agendamentos
  add column if not exists concluido boolean not null default false;
