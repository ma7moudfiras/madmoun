-- Row level security, column grants, public views, and reader/admin RPCs.

-- --------------------------------------------------------------------------
-- Security definer helpers (break RLS recursion between tables).
-- --------------------------------------------------------------------------

create or replace function public.my_shop_id()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select s.id from public.shops s where s.owner_id = (select auth.uid());
$$;

create or replace function public.owns_device(p_device_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.devices d
    join public.shops s on s.id = d.shop_id
    where d.id = p_device_id and s.owner_id = (select auth.uid())
  );
$$;

create or replace function public.has_reservation_on(p_device_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.reservations r
    where r.device_id = p_device_id and r.buyer_id = (select auth.uid())
  );
$$;

-- --------------------------------------------------------------------------
-- Column grants. The raw IMEI is write-only for clients: it is never granted
-- for SELECT; only the generated imei_last4 column is readable.
-- Shop phone numbers and rejection reasons are private (owner via my_shop(),
-- admins via admin_shops()).
-- --------------------------------------------------------------------------

revoke all on public.shops from anon, authenticated;
grant select (id, name, city, status, created_at) on public.shops to anon, authenticated;
grant insert (name, city, phone_e164) on public.shops to authenticated;
grant update (name, city, phone_e164) on public.shops to authenticated;

revoke all on public.devices from anon, authenticated;
grant select (id, public_id, shop_id, category, brand, model, title, description,
              price_minor, currency, grade, warranty_days, imei_last4, checklist,
              status, rejection_reason, created_at, updated_at)
  on public.devices to anon, authenticated;
grant insert (shop_id, category, brand, model, title, description, price_minor,
              currency, grade, warranty_days, imei, checklist)
  on public.devices to authenticated;
grant update (category, brand, model, title, description, price_minor, currency,
              grade, warranty_days, imei, checklist, status)
  on public.devices to authenticated;
grant delete on public.devices to authenticated;

revoke all on public.device_photos from anon, authenticated;
grant select on public.device_photos to anon, authenticated;
grant insert (device_id, storage_path, sort_order) on public.device_photos to authenticated;
grant update (sort_order, is_deleted) on public.device_photos to authenticated;

revoke all on public.listing_events from anon, authenticated;
grant select on public.listing_events to authenticated;

revoke all on public.profiles from anon, authenticated;
grant select (id, role, full_name, phone_e164, created_at) on public.profiles to authenticated;
grant update (full_name, phone_e164) on public.profiles to authenticated;

revoke all on public.reservations from anon, authenticated;
grant select on public.reservations to authenticated;
-- No insert grant: reserve_device() is the only way to create a reservation.
grant update (status) on public.reservations to authenticated;

revoke all on public.warranty_claims from anon, authenticated;
grant select on public.warranty_claims to authenticated;
grant insert (device_id, reservation_id, opened_by, description) on public.warranty_claims to authenticated;
-- Sellers may only write their response; admins change status via admin_update_claim().
grant update (shop_response) on public.warranty_claims to authenticated;

revoke all on public.checklist_templates from anon, authenticated;
grant select on public.checklist_templates to anon, authenticated;
grant insert, update, delete on public.checklist_templates to authenticated;

-- --------------------------------------------------------------------------
-- Row level security.
-- --------------------------------------------------------------------------

alter table public.shops enable row level security;
alter table public.checklist_templates enable row level security;
alter table public.devices enable row level security;
alter table public.device_photos enable row level security;
alter table public.listing_events enable row level security;
alter table public.profiles enable row level security;
alter table public.reservations enable row level security;
alter table public.warranty_claims enable row level security;

create policy shops_select on public.shops
  for select to anon, authenticated
  using (status = 'approved' or owner_id = (select auth.uid()) or (select public.is_admin()));

create policy shops_insert on public.shops
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy shops_update on public.shops
  for update to authenticated
  using (owner_id = (select auth.uid()) or (select public.is_admin()))
  with check (owner_id = (select auth.uid()) or (select public.is_admin()));

create policy checklist_templates_select on public.checklist_templates
  for select to anon, authenticated
  using (is_active or (select public.is_admin()));

create policy checklist_templates_insert on public.checklist_templates
  for insert to authenticated
  with check ((select public.is_admin()));

create policy checklist_templates_update on public.checklist_templates
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy checklist_templates_delete on public.checklist_templates
  for delete to authenticated
  using ((select public.is_admin()));

create policy devices_select on public.devices
  for select to anon, authenticated
  using (
    status = 'listed'
    or public.owns_device(id)
    or (select public.is_admin())
    or public.has_reservation_on(id)
  );

create policy devices_insert on public.devices
  for insert to authenticated
  with check (
    exists (
      select 1 from public.shops s
      where s.id = shop_id
        and s.id = (select public.my_shop_id())
        and s.status = 'approved'
    )
  );

create policy devices_update on public.devices
  for update to authenticated
  using (public.owns_device(id) or (select public.is_admin()))
  with check (public.owns_device(id) or (select public.is_admin()));

create policy devices_delete on public.devices
  for delete to authenticated
  using (public.owns_device(id) and status = 'draft');

create policy device_photos_select on public.device_photos
  for select to anon, authenticated
  using (
    not is_deleted
    and (
      exists (select 1 from public.devices d where d.id = device_id and d.status = 'listed')
      or public.owns_device(device_id)
      or (select public.is_admin())
      or public.has_reservation_on(device_id)
    )
  );

create policy device_photos_insert on public.device_photos
  for insert to authenticated
  with check (public.owns_device(device_id));

create policy device_photos_update on public.device_photos
  for update to authenticated
  using (public.owns_device(device_id))
  with check (public.owns_device(device_id));

create policy listing_events_select on public.listing_events
  for select to authenticated
  using (public.owns_device(device_id) or (select public.is_admin()));

create policy profiles_select on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));

create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy reservations_select on public.reservations
  for select to authenticated
  using (
    buyer_id = (select auth.uid())
    or public.owns_device(device_id)
    or (select public.is_admin())
  );

create policy reservations_update on public.reservations
  for update to authenticated
  using (public.owns_device(device_id) or (select public.is_admin()))
  with check (public.owns_device(device_id) or (select public.is_admin()));

create policy warranty_claims_select on public.warranty_claims
  for select to authenticated
  using (
    opened_by = (select auth.uid())
    or public.owns_device(device_id)
    or (select public.is_admin())
  );

create policy warranty_claims_insert on public.warranty_claims
  for insert to authenticated
  with check (
    opened_by = (select auth.uid())
    and exists (
      select 1 from public.reservations r
      where r.id = reservation_id
        and r.buyer_id = (select auth.uid())
        and r.device_id = warranty_claims.device_id
        and r.status = 'delivered'
    )
  );

create policy warranty_claims_update on public.warranty_claims
  for update to authenticated
  using (public.owns_device(device_id) or (select public.is_admin()))
  with check (public.owns_device(device_id) or (select public.is_admin()));

-- --------------------------------------------------------------------------
-- Public marketplace view (invoker rights: anon RLS + column grants apply).
-- Exposes only safe columns; IMEI is surfaced as the server-computed last 4.
-- --------------------------------------------------------------------------

create view public.public_listings
with (security_invoker = on) as
select
  d.id, d.public_id, d.category, d.brand, d.model, d.title, d.description,
  d.price_minor, d.currency, d.grade, d.warranty_days, d.imei_last4,
  d.checklist, d.created_at,
  s.id as shop_id, s.name as shop_name, s.city as shop_city
from public.devices d
join public.shops s on s.id = d.shop_id
where d.status = 'listed' and s.status = 'approved';

grant select on public.public_listings to anon, authenticated;

-- --------------------------------------------------------------------------
-- Environmental impact counter (public).
-- --------------------------------------------------------------------------

create or replace function public.impact_stats()
returns table (devices_saved bigint, est_co2_kg bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select
    count(*) filter (where status in ('sold', 'warranty_active', 'warranty_closed')),
    coalesce(sum(
      case when status in ('sold', 'warranty_active', 'warranty_closed')
        then case category when 'mobile' then 60 else 250 end
      end), 0)::bigint
  from public.devices;
$$;

-- --------------------------------------------------------------------------
-- Owner / admin readers for private columns.
-- --------------------------------------------------------------------------

create or replace function public.my_shop()
returns setof public.shops
language sql
stable
security definer
set search_path = ''
as $$
  select * from public.shops where owner_id = (select auth.uid());
$$;

revoke execute on function public.my_shop() from anon;

create or replace function public.admin_shops(p_status public.shop_status default null)
returns setof public.shops
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
    select * from public.shops s
    where p_status is null or s.status = p_status
    order by s.id desc;
end;
$$;

revoke execute on function public.admin_shops(public.shop_status) from anon;

create or replace function public.admin_set_shop_status(
  p_shop_id bigint,
  p_status public.shop_status,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_status = 'rejected' and coalesce(trim(p_reason), '') = '' then
    raise exception 'REJECTION_REASON_REQUIRED';
  end if;
  update public.shops
  set status = p_status,
      rejection_reason = case when p_status = 'rejected' then p_reason else null end
  where id = p_shop_id;
end;
$$;

revoke execute on function public.admin_set_shop_status(bigint, public.shop_status, text) from anon;

create or replace function public.admin_review_device(
  p_device_id bigint,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_approve then
    update public.devices set status = 'listed', rejection_reason = null
    where id = p_device_id;
  else
    if coalesce(trim(p_reason), '') = '' then
      raise exception 'REJECTION_REASON_REQUIRED';
    end if;
    update public.devices set status = 'rejected', rejection_reason = p_reason
    where id = p_device_id;
  end if;
end;
$$;

revoke execute on function public.admin_review_device(bigint, boolean, text) from anon;

create or replace function public.admin_update_claim(
  p_claim_id bigint,
  p_status text,
  p_resolution_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_status not in ('in_review', 'resolved', 'rejected') then
    raise exception 'INVALID_CLAIM_STATUS';
  end if;
  update public.warranty_claims
  set status = p_status,
      resolution_note = coalesce(p_resolution_note, resolution_note)
  where id = p_claim_id;
end;
$$;

revoke execute on function public.admin_update_claim(bigint, text, text) from anon;

create or replace function public.admin_dashboard_stats()
returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result json;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  select json_build_object(
    'pending_shops', (select count(*) from public.shops where status = 'pending'),
    'devices_in_review', (select count(*) from public.devices where status = 'under_inspection'),
    'active_reservations', (select count(*) from public.reservations where status in ('pending', 'confirmed')),
    'open_claims', (select count(*) from public.warranty_claims where status in ('open', 'in_review')),
    'devices_saved', s.devices_saved,
    'est_co2_kg', s.est_co2_kg
  ) into v_result
  from public.impact_stats() s;
  return v_result;
end;
$$;

revoke execute on function public.admin_dashboard_stats() from anon;
