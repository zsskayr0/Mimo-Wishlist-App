-- Mimo — 008_folder_cover_and_ownership.sql

-- Folder cover photo (customização da pasta). Reuses the existing
-- "mimo-covers" storage bucket/policies from 006 — they only check the
-- uploader's own "{user_id}/..." path prefix, not what kind of image it
-- is, so no new bucket/policy is needed.
alter table public.folders add column if not exists cover_image_url text;

-- Ownership transfer ("dar a pasta pra outra pessoa"). A plain
-- `update folders set owner_id = ...` is rejected by RLS: the
-- "folders_update_owner_or_editor" policy declares only a USING clause,
-- and Postgres reuses USING as the implicit WITH CHECK for UPDATE when
-- none is given — after the update owner_id is the *new* owner, so
-- `auth.uid() = owner_id` is false for the acting (old) owner, and
-- they're not a folder_members row either. A SECURITY DEFINER function
-- does the ownership check itself and bypasses that gap.
create or replace function public.transfer_folder_ownership(
  p_folder_id uuid,
  p_new_owner_id uuid
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.folders
    where id = p_folder_id and owner_id = auth.uid()
  ) then
    raise exception 'only the current owner can transfer this folder';
  end if;

  if not exists (
    select 1 from public.folder_members
    where folder_id = p_folder_id and user_id = p_new_owner_id
  ) then
    raise exception 'new owner must already be a member of the folder';
  end if;

  update public.folders set owner_id = p_new_owner_id where id = p_folder_id;

  -- Keep folder_members consistent: the new owner isn't tracked there
  -- (owner is folders.owner_id, never a member row — see 000_schema.sql),
  -- and the ex-owner becomes an editor member so they keep full access.
  delete from public.folder_members where folder_id = p_folder_id and user_id = p_new_owner_id;
  insert into public.folder_members (folder_id, user_id, role)
  values (p_folder_id, auth.uid(), 'editor')
  on conflict (folder_id, user_id) do nothing;
end;
$$;

grant execute on function public.transfer_folder_ownership(uuid, uuid) to authenticated;
