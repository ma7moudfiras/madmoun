-- Admin user management: list users (profile + auth email / timestamps) and
-- aggregate stats. Both are admin-gated security-definer functions so the
-- admin panel can read auth.users without exposing it to clients directly.

create or replace function public.admin_list_users(
  p_search text default null,
  p_limit int default 100
)
returns table (
  id uuid,
  email text,
  full_name text,
  role public.user_role,
  phone_e164 text,
  created_at timestamptz,
  last_sign_in_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  return query
    select p.id, u.email::text, p.full_name, p.role, p.phone_e164,
           p.created_at, u.last_sign_in_at
    from public.profiles p
    join auth.users u on u.id = p.id
    where p_search is null
       or p.full_name ilike '%' || p_search || '%'
       or u.email ilike '%' || p_search || '%'
    order by p.created_at desc
    limit greatest(1, least(p_limit, 200));
end;
$$;

revoke execute on function public.admin_list_users(text, int) from anon;

create or replace function public.admin_user_stats()
returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v json;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  select json_build_object(
    'total', count(*),
    'buyers', count(*) filter (where role = 'buyer'),
    'sellers', count(*) filter (where role = 'seller'),
    'admins', count(*) filter (where role = 'admin'),
    'new_last_7d', count(*) filter (where created_at >= now() - interval '7 days')
  ) into v
  from public.profiles;
  return v;
end;
$$;

revoke execute on function public.admin_user_stats() from anon;
