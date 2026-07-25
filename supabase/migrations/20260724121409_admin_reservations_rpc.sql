-- The admin is the hub and needs the shop's pickup contact (phone/address) to
-- brief a courier, but those columns are deliberately not granted to
-- authenticated (opacity). A security-definer, admin-gated RPC returns the full
-- picture without exposing shop contact to ordinary users.
create or replace function public.admin_reservations()
returns table (
  id bigint,
  public_id text,
  device_id bigint,
  buyer_id uuid,
  buyer_phone_e164 text,
  delivery_city text,
  delivery_note text,
  delivery_address text,
  price_minor bigint,
  currency public.currency_code,
  commission_percent numeric,
  commission_minor bigint,
  status public.reservation_status,
  settlement_status text,
  created_at timestamptz,
  device_title text,
  device_public_id text,
  shop_name text,
  shop_city text,
  shop_address text,
  shop_phone text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.id, r.public_id, r.device_id, r.buyer_id, r.buyer_phone_e164,
    r.delivery_city, r.delivery_note, r.delivery_address, r.price_minor,
    r.currency, r.commission_percent, r.commission_minor, r.status,
    r.settlement_status, r.created_at,
    d.title, d.public_id, s.name, s.city, s.address, s.phone_e164
  from public.reservations r
  join public.devices d on d.id = r.device_id
  join public.shops s on s.id = d.shop_id
  where (select public.is_admin())
  order by r.id desc
  limit 200;
$$;

revoke execute on function public.admin_reservations() from anon;
