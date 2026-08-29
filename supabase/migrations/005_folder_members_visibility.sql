-- Mimo — 005_folder_members_visibility.sql
-- folder_members_select only let a member see their OWN row (or the
-- owner see everyone's) — fine for permission checks, wrong for the
-- "who's in this shared folder" list the invite UI needs. Any member
-- should be able to see the full roster, same as any shared album.
--
-- Safe to use is_folder_member() for this (see 004): it's SECURITY
-- DEFINER, so it doesn't re-enter folder_members' own RLS.

drop policy if exists "folder_members_select" on public.folder_members;
create policy "folder_members_select"
  on public.folder_members for select
  using (
    public.is_folder_member(folder_id, auth.uid())
    or exists (
      select 1 from public.folders f
      where f.id = folder_members.folder_id and f.owner_id = auth.uid()
    )
  );
