-- Roles, profiles, admin helpers, seller promotion.

create type public.user_role as enum ('buyer', 'seller', 'admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'buyer',
  full_name text,
  phone_e164 text check (phone_e164 is null or phone_e164 ~ '^\+[0-9]{8,15}$'),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, nullif(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

-- Role changes are admin-only and go through this RPC (profiles.role has no update grant).
create or replace function public.admin_set_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  update public.profiles set role = p_role where id = p_user_id;
end;
$$;

revoke execute on function public.admin_set_role(uuid, public.user_role) from anon;

-- Creating a shop makes a buyer a seller; admins keep their role.
create or replace function public.promote_to_seller()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles set role = 'seller'
  where id = new.owner_id and role = 'buyer';
  return new;
end;
$$;

create trigger shops_promote_seller
  after insert on public.shops
  for each row execute function public.promote_to_seller();
