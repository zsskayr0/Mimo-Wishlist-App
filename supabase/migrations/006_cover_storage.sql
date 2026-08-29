-- Mimo — 006_cover_storage.sql
-- Storage bucket for mimo cover images (the AI-crop target from the
-- blueprint — for now, a manually picked-and-cropped 1:1 image). Public
-- read so Image.network can load covers without sending an auth header;
-- write/update/delete restricted to files under the uploader's own
-- "{user_id}/..." path prefix.

insert into storage.buckets (id, name, public)
values ('mimo-covers', 'mimo-covers', true)
on conflict (id) do nothing;

drop policy if exists "mimo_covers_public_read" on storage.objects;
create policy "mimo_covers_public_read"
  on storage.objects for select
  using (bucket_id = 'mimo-covers');

drop policy if exists "mimo_covers_owner_insert" on storage.objects;
create policy "mimo_covers_owner_insert"
  on storage.objects for insert
  with check (bucket_id = 'mimo-covers' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "mimo_covers_owner_update" on storage.objects;
create policy "mimo_covers_owner_update"
  on storage.objects for update
  using (bucket_id = 'mimo-covers' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "mimo_covers_owner_delete" on storage.objects;
create policy "mimo_covers_owner_delete"
  on storage.objects for delete
  using (bucket_id = 'mimo-covers' and (storage.foldername(name))[1] = auth.uid()::text);
