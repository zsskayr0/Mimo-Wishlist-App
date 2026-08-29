-- Mimo — 002_rls_policies.sql
-- Row Level Security for every table. The rule of thumb throughout: the
-- owner can always read/write their own rows; a folder's members can
-- read (and, if "editor", write) whatever is scoped to that folder.

alter table public.users enable row level security;
alter table public.folders enable row level security;
alter table public.folder_members enable row level security;
alter table public.tags enable row level security;
alter table public.mimos enable row level security;
alter table public.mimo_images enable row level security;
alter table public.mimo_tags enable row level security;
alter table public.friendships enable row level security;

-- ---------------------------------------------------------------------------
-- users — profiles are publicly readable (needed for @search and friend
-- profiles); only the owner can update their own.
-- ---------------------------------------------------------------------------

create policy "users_select_all"
  on public.users for select
  using (true);

create policy "users_update_self"
  on public.users for update
  using (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- folders
-- ---------------------------------------------------------------------------

create policy "folders_select_owner_or_member"
  on public.folders for select
  using (
    auth.uid() = owner_id
    or exists (
      select 1 from public.folder_members fm
      where fm.folder_id = folders.id and fm.user_id = auth.uid()
    )
  );

create policy "folders_insert_owner"
  on public.folders for insert
  with check (auth.uid() = owner_id);

create policy "folders_update_owner_or_editor"
  on public.folders for update
  using (
    auth.uid() = owner_id
    or exists (
      select 1 from public.folder_members fm
      where fm.folder_id = folders.id
        and fm.user_id = auth.uid()
        and fm.role = 'editor'
    )
  );

create policy "folders_delete_owner"
  on public.folders for delete
  using (auth.uid() = owner_id);

-- folder_members — visible to the folder's owner and to the member
-- themself; only the owner manages who's on the list.
create policy "folder_members_select"
  on public.folder_members for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.folders f
      where f.id = folder_members.folder_id and f.owner_id = auth.uid()
    )
  );

create policy "folder_members_manage_owner"
  on public.folder_members for all
  using (
    exists (
      select 1 from public.folders f
      where f.id = folder_members.folder_id and f.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.folders f
      where f.id = folder_members.folder_id and f.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- tags — system tags readable by everyone; custom tags only by their owner.
-- ---------------------------------------------------------------------------

create policy "tags_select"
  on public.tags for select
  using (is_system = true or owner_id = auth.uid());

create policy "tags_insert_own"
  on public.tags for insert
  with check (owner_id = auth.uid());

create policy "tags_update_own"
  on public.tags for update
  using (owner_id = auth.uid());

create policy "tags_delete_own"
  on public.tags for delete
  using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- mimos — owner always; folder members inherit visibility (and, if
-- "editor", write access) through the mimo's folder_id.
-- ---------------------------------------------------------------------------

create policy "mimos_select"
  on public.mimos for select
  using (
    auth.uid() = owner_id
    or (
      folder_id is not null
      and exists (
        select 1 from public.folder_members fm
        where fm.folder_id = mimos.folder_id and fm.user_id = auth.uid()
      )
    )
  );

create policy "mimos_insert_owner"
  on public.mimos for insert
  with check (auth.uid() = owner_id);

create policy "mimos_update"
  on public.mimos for update
  using (
    auth.uid() = owner_id
    or (
      folder_id is not null
      and exists (
        select 1 from public.folder_members fm
        where fm.folder_id = mimos.folder_id
          and fm.user_id = auth.uid()
          and fm.role = 'editor'
      )
    )
  );

create policy "mimos_delete_owner"
  on public.mimos for delete
  using (auth.uid() = owner_id);

-- mimo_images — follows the parent mimo's read visibility; only the mimo's
-- owner manages the gallery.
create policy "mimo_images_select"
  on public.mimo_images for select
  using (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_images.mimo_id
        and (
          m.owner_id = auth.uid()
          or (
            m.folder_id is not null
            and exists (
              select 1 from public.folder_members fm
              where fm.folder_id = m.folder_id and fm.user_id = auth.uid()
            )
          )
        )
    )
  );

create policy "mimo_images_manage_owner"
  on public.mimo_images for all
  using (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_images.mimo_id and m.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_images.mimo_id and m.owner_id = auth.uid()
    )
  );

-- mimo_tags — same visibility as the mimo; only the mimo's owner tags it.
create policy "mimo_tags_select"
  on public.mimo_tags for select
  using (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_tags.mimo_id
        and (
          m.owner_id = auth.uid()
          or (
            m.folder_id is not null
            and exists (
              select 1 from public.folder_members fm
              where fm.folder_id = m.folder_id and fm.user_id = auth.uid()
            )
          )
        )
    )
  );

create policy "mimo_tags_manage_owner"
  on public.mimo_tags for all
  using (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_tags.mimo_id and m.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.mimos m
      where m.id = mimo_tags.mimo_id and m.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- friendships — visible to and manageable by either side of the pair.
-- ---------------------------------------------------------------------------

create policy "friendships_select"
  on public.friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friendships_insert"
  on public.friendships for insert
  with check (auth.uid() = requester_id);

create policy "friendships_update"
  on public.friendships for update
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friendships_delete"
  on public.friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);
