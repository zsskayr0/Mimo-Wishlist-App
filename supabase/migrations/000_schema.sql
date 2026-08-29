-- Mimo — 000_schema.sql
-- Core tables, enums and indexes. No RLS here (see 002_rls_policies.sql) so
-- this file can be reasoned about as pure structure.

create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type mimo_priority as enum ('baixa', 'media', 'alta');
create type mimo_purchase_status as enum ('desejado', 'comprado', 'arquivado');
create type mimo_source as enum ('manual', 'share_intent', 'screenshot');
create type folder_role as enum ('editor', 'visualizador');
create type friendship_status as enum ('pendente', 'aceita', 'bloqueada');

-- ---------------------------------------------------------------------------
-- updated_at helper, reused by every table below that has one
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ---------------------------------------------------------------------------
-- users — public profile, 1:1 with auth.users (see 001_auth_trigger.sql for
-- how rows here get created on signup). Deliberately holds no email/PII:
-- that stays in auth.users, out of reach of the public-read policy below.
-- ---------------------------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text,
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_username_format check (username ~ '^[a-z0-9_]{3,20}$')
);

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

comment on table public.users is 'Public profile. auth.users holds the login/email side.';

-- ---------------------------------------------------------------------------
-- folders — a mimo belongs to at most one; sharing is layered on via
-- folder_members rather than a second folder-ish table.
-- ---------------------------------------------------------------------------

create table public.folders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  name text not null,
  color text not null default '#A6791F',
  is_shared boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index folders_owner_id_idx on public.folders (owner_id);

create trigger folders_set_updated_at
  before update on public.folders
  for each row execute function public.set_updated_at();

-- folder_members — editor/visualizador only. The owner is folders.owner_id
-- and never gets a row here.
create table public.folder_members (
  folder_id uuid not null references public.folders (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  role folder_role not null default 'visualizador',
  joined_at timestamptz not null default now(),
  primary key (folder_id, user_id)
);

create index folder_members_user_id_idx on public.folder_members (user_id);

-- ---------------------------------------------------------------------------
-- tags — owner_id null marks a predefined system tag (seeded in
-- 003_seed_system_tags.sql), shared by every user. Case-insensitive unique
-- per owner (system tags share the null "owner").
-- ---------------------------------------------------------------------------

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.users (id) on delete cascade,
  name text not null,
  color text not null default '#8B4F9E',
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index tags_owner_name_key
  on public.tags (coalesce(owner_id::text, ''), lower(name));

-- ---------------------------------------------------------------------------
-- mimos — the core item. folder_id is nullable and set null (not cascaded)
-- when its folder is deleted, so a mimo never disappears with its folder;
-- it just falls back to "Desorganizado".
-- ---------------------------------------------------------------------------

create table public.mimos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  folder_id uuid references public.folders (id) on delete set null,
  title text not null,
  notes text,
  cover_image_url text,
  original_url text,
  store_domain text,
  price numeric(12, 2),
  priority mimo_priority not null default 'media',
  purchase_status mimo_purchase_status not null default 'desejado',
  source mimo_source not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index mimos_owner_id_idx on public.mimos (owner_id);
create index mimos_folder_id_idx on public.mimos (folder_id);

create trigger mimos_set_updated_at
  before update on public.mimos
  for each row execute function public.set_updated_at();

comment on column public.mimos.folder_id is
  'Null = shows as "Desorganizado" in the Feed. A mimo has at most one folder; duplicate the row to put it in a second one.';

-- mimo_images — gallery beyond the cover (the cover is the AI 1:1 crop,
-- stored directly on mimos.cover_image_url).
create table public.mimo_images (
  id uuid primary key default gen_random_uuid(),
  mimo_id uuid not null references public.mimos (id) on delete cascade,
  url text not null,
  position smallint not null default 0
);

create index mimo_images_mimo_id_idx on public.mimo_images (mimo_id);

-- mimo_tags — the N:N that lets a mimo carry several tags at once.
create table public.mimo_tags (
  mimo_id uuid not null references public.mimos (id) on delete cascade,
  tag_id uuid not null references public.tags (id) on delete cascade,
  primary key (mimo_id, tag_id)
);

create index mimo_tags_tag_id_idx on public.mimo_tags (tag_id);

-- ---------------------------------------------------------------------------
-- friendships — one row per request, status tracks the pair. The app layer
-- is responsible for checking both directions before creating a new request;
-- keeping that out of the schema is a deliberate simplicity trade-off.
-- ---------------------------------------------------------------------------

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.users (id) on delete cascade,
  addressee_id uuid not null references public.users (id) on delete cascade,
  status friendship_status not null default 'pendente',
  created_at timestamptz not null default now(),
  constraint friendships_no_self check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (requester_id, addressee_id)
);

create index friendships_addressee_id_idx on public.friendships (addressee_id);
