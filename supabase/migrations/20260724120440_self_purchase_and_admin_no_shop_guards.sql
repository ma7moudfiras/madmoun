-- Rule: a user cannot buy a device from their own shop.
create or replace function public.reserve_device(
  p_device_id bigint,
  p_phone text,
  p_city text,
  p_note text default null,
  p_address text default null
)
returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_dev public.devices%rowtype;
  v_percent constant numeric(4,1) := 10.0;
  v_public_id text;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_phone is null or p_phone !~ '^\+[0-9]{8,15}$' then
    raise exception 'INVALID_PHONE';
  end if;
  if coalesce(trim(p_city), '') = '' then
    raise exception 'CITY_REQUIRED';
  end if;

  select * into v_dev from public.devices where id = p_device_id for update;
  if not found then
    raise exception 'DEVICE_NOT_FOUND';
  end if;
  if exists (select 1 from public.shops s
             where s.id = v_dev.shop_id and s.owner_id = v_uid) then
    raise exception 'OWN_DEVICE';
  end if;
  if v_dev.status <> 'listed' then
    raise exception 'DEVICE_NOT_AVAILABLE';
  end if;

  insert into public.reservations
    (device_id, buyer_id, buyer_phone_e164, delivery_city, delivery_note,
     delivery_address, price_minor, currency, commission_percent, commission_minor)
  values
    (p_device_id, v_uid, p_phone, trim(p_city),
     nullif(trim(coalesce(p_note, '')), ''),
     nullif(trim(coalesce(p_address, '')), ''),
     v_dev.price_minor, v_dev.currency, v_percent,
     round(v_dev.price_minor * v_percent / 100.0)::bigint)
  returning public_id into v_public_id;

  update public.devices set status = 'reserved' where id = p_device_id;

  return json_build_object('reservation_public_id', v_public_id);
end;
$$;

revoke execute on function public.reserve_device(bigint, text, text, text, text) from anon;

-- Rule: the platform admin is not a seller and cannot own a store.
drop policy shops_insert on public.shops;
create policy shops_insert on public.shops
  for insert to authenticated
  with check (owner_id = (select auth.uid()) and not (select public.is_admin()));
