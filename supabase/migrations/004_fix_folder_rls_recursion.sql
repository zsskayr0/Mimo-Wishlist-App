-- Mimo — 004_fix_folder_rls_recursion.sql
-- folders and folder_members each looked the other up inside their own RLS
-- policy (folders checks membership; folder_members checks folder
-- ownership), and Postgres correctly flagged that as infinite recursion
-- (42P17) the moment a shared folder was involved.
--
-- Fix: resolve the folder_members side through a SECURITY DEFINER function
-- instead of a policy subquery. Such a function runs as its owner (the
-- migration role, which owns these tables), so — same as any table owner —
-- its queries bypass RLS rather than re-entering it. That breaks the cycle
-- without changing who can actually see what.

create or replace function public.is_folder_member(p_folder_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.folder_members
    where folder_id = p_folder_id and user_id = p_user_id
  );
$$;

create or replace function public.is_folder_editor(p_folder_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.folder_members
    where folder_id = p_folder_id and user_id = p_user_id and role = 'editor'
  );
$$;

drop policy if exists "folders_select_owner_or_member" on public.folders;
create policy "folders_select_owner_or_member"
  on public.folders for select
  using (auth.uid() = owner_id or public.is_folder_member(id, auth.uid()));

drop policy if exists "folders_update_owner_or_editor" on public.folders;
create policy "folders_update_owner_or_editor"
  on public.folders for update
  using (auth.uid() = owner_id or public.is_folder_editor(id, auth.uid()));
