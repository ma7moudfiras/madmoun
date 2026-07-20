-- MVP: confirm emails at signup time so buyers can reserve immediately.
-- (The hosted project's "Confirm email" toggle is left as-is; this trigger
-- pre-confirms the row. Remove this migration when real email confirmation
-- is wanted in production.)

create or replace function public.auto_confirm_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.email_confirmed_at := coalesce(new.email_confirmed_at, now());
  return new;
end;
$$;

revoke execute on function public.auto_confirm_email() from public, anon, authenticated;

create trigger on_auth_user_precreate
  before insert on auth.users
  for each row execute function public.auto_confirm_email();
