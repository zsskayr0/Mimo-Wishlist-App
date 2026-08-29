-- Mimo — 001_auth_trigger.sql
-- Wires Supabase Auth signups to a public.users profile row. The username
-- falls back to a short id-derived placeholder when signup doesn't supply
-- one — the app's onboarding ("Criar @usuário") is expected to prompt the
-- user to replace it right away.

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, username, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'username',
      'user_' || substr(new.id::text, 1, 8)
    ),
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email)
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
