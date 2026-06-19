-- Bucket público + políticas para upload de fotos dos relatórios
insert into storage.buckets (id, name, public)
  values ('relatorios', 'relatorios', true)
  on conflict (id) do update set public = true;

drop policy if exists "relatorios_read" on storage.objects;
create policy "relatorios_read" on storage.objects
  for select using (bucket_id = 'relatorios');

drop policy if exists "relatorios_insert" on storage.objects;
create policy "relatorios_insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'relatorios');

drop policy if exists "relatorios_delete" on storage.objects;
create policy "relatorios_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'relatorios');
