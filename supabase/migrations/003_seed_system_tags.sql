-- Mimo — 003_seed_system_tags.sql
-- Predefined tags every user starts with (tags.owner_id = null). Users can
-- still create their own on top of these.

insert into public.tags (owner_id, name, color, is_system) values
  (null, 'Casa', '#A6791F', true),
  (null, 'Tech', '#7A5AE0', true),
  (null, 'Roupas', '#8B4F9E', true),
  (null, 'Beleza', '#C2517B', true),
  (null, 'Livros', '#3F7A5C', true),
  (null, 'Esporte', '#2E7DB0', true),
  (null, 'Games', '#B6552C', true)
on conflict do nothing;
