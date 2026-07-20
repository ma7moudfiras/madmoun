-- COD reservations, warranty claims, atomic reserve_device RPC.

create type public.reservation_status as enum ('pending', 'confirmed', 'delivered', 'cancelled');

create table public.reservations (
  id bigint generated always as identity primary key,
  public_id text not null unique,
  device_id bigint not null references public.devices(id),
  buyer_id uuid not null references auth.users(id),
  buyer_phone_e164 text not null check (buyer_phone_e164 ~ '^\+[0-9]{8,15}$'),
  delivery_city text not null check (char_length(delivery_city) between 2 and 80),
  delivery_note text,
  price_minor bigint not null,
  currency public.currency_code not null,
  commission_percent numeric(4,1) not null default 10.0,
  commission_minor bigint not null,
  status public.reservation_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index reservations_device_idx on public.reservations (device_id);
create index reservations_buyer_idx on public.reservations (buyer_id, id desc);
create index reservations_status_idx on public.reservations (status);

create trigger reservations_touch_updated_at
  before update on public.reservations
  for each row execute function public.touch_updated_at();

create or replace function public.set_reservation_public_id()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.public_id is null then
    loop
      new.public_id := public.gen_public_id('RS');
      exit when not exists (select 1 from public.reservations r where r.public_id = new.public_id);
    end loop;
  end if;
  return new;
end;
$$;

create trigger reservations_set_public_id
  before insert on public.reservations
  for each row execute function public.set_reservation_public_id();

create or replace function public.enforce_reservation_transitions()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_legal boolean;
begin
  if old.status = new.status then
    return new;
  end if;
  v_legal := case old.status
    when 'pending' then new.status in ('confirmed', 'cancelled')
    when 'confirmed' then new.status in ('delivered', 'cancelled')
    else false
  end;
  if not v_legal then
    raise exception 'INVALID_STATE_TRANSITION'
      using detail = format('%s -> %s is not allowed', old.status, new.status);
  end if;
  return new;
end;
$$;

create trigger reservations_enforce_transitions
  before update of status on public.reservations
  for each row execute function public.enforce_reservation_transitions();

-- Delivered reservation moves its device reserved -> sold -> warranty_active;
-- cancelled reservation rolls the device back to listed.
create or replace function public.apply_reservation_effects()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status is distinct from new.status then
    if new.status = 'delivered' then
      update public.devices set status = 'sold' where id = new.device_id and status = 'reserved';
      update public.devices set status = 'warranty_active' where id = new.device_id and status = 'sold';
    elsif new.status = 'cancelled' then
      update public.devices set status = 'listed' where id = new.device_id and status = 'reserved';
    end if;
  end if;
  return new;
end;
$$;

create trigger reservations_apply_effects
  after update on public.reservations
  for each row execute function public.apply_reservation_effects();

-- The only path for buyers to create a reservation: locks the device row,
-- verifies it is listed, snapshots price + commission, flips the device.
create or replace function public.reserve_device(
  p_device_id bigint,
  p_phone text,
  p_city text,
  p_note text default null
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
  if v_dev.status <> 'listed' then
    raise exception 'DEVICE_NOT_AVAILABLE';
  end if;

  insert into public.reservations
    (device_id, buyer_id, buyer_phone_e164, delivery_city, delivery_note,
     price_minor, currency, commission_percent, commission_minor)
  values
    (p_device_id, v_uid, p_phone, trim(p_city), nullif(trim(coalesce(p_note, '')), ''),
     v_dev.price_minor, v_dev.currency, v_percent,
     round(v_dev.price_minor * v_percent / 100.0)::bigint)
  returning public_id into v_public_id;

  update public.devices set status = 'reserved' where id = p_device_id;

  return json_build_object('reservation_public_id', v_public_id);
end;
$$;

revoke execute on function public.reserve_device(bigint, text, text, text) from anon;

create table public.warranty_claims (
  id bigint generated always as identity primary key,
  device_id bigint not null references public.devices(id),
  reservation_id bigint not null references public.reservations(id),
  opened_by uuid not null references auth.users(id),
  description text not null check (char_length(description) between 5 and 2000),
  status text not null default 'open' check (status in ('open', 'in_review', 'resolved', 'rejected')),
  resolution_note text,
  shop_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index warranty_claims_device_idx on public.warranty_claims (device_id);
create index warranty_claims_reservation_idx on public.warranty_claims (reservation_id);
create index warranty_claims_opened_by_idx on public.warranty_claims (opened_by);
create index warranty_claims_status_idx on public.warranty_claims (status);

create trigger warranty_claims_touch_updated_at
  before update on public.warranty_claims
  for each row execute function public.touch_updated_at();
