-- Dados de exemplo. Rode UMA vez após o 0001_init.sql.

insert into public.clientes (nome, sindico, telefone) values
  ('Alameda das Palmeiras', null, null),
  ('San Denis', null, null),
  ('Quinta do Moinho',   'Hélio Vidilino',   '(11) 94037-7744'),
  ('Quinta do Loureiro', 'Tiago Mello',      '(11) 96149-8089'),
  ('dos Girassóis',      'Thiago Maiellaro', '(11) 99694-4188')
on conflict do nothing;

insert into public.relatorios
  (condo, cliente_id, data, duracao, status, servicos, equipamentos, epi, observacoes, proxima_visita)
select 'Alameda das Palmeiras', c.id, date '2025-09-08', '5 horas', 'Finalizado',
  array['Corte e Poda','Remoção de Folhas / Galhos','Paisagismo','Limpeza Geral do Jardim'],
  array['Roçadeira','Soprador','Rastelo'],
  array['Luvas','Botas','Óculos de Proteção'],
  'Colocação de pedras brancas na caixa de palmeiras. Reforçar a rega, principalmente nas gramas recém-colocadas.',
  date '2025-09-22'
from public.clientes c where c.nome = 'Alameda das Palmeiras';

insert into public.relatorios
  (condo, cliente_id, data, duracao, status, servicos, equipamentos, epi, observacoes, proxima_visita)
select 'San Denis', c.id, date '2025-07-21', '4 horas', 'Agendado',
  array['Corte de grama','Poda de arbustos'],
  array['Roçadeira'],
  array['Luvas','Botas'],
  '',
  date '2025-08-04'
from public.clientes c where c.nome = 'San Denis';
