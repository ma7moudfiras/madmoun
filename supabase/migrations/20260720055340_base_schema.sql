-- Madmoun base schema: types, shops, checklist templates, devices, photos, events.

create type public.currency_code as enum ('ILS', 'USD');
create type public.device_category as enum ('mobile', 'laptop');
create type public.condition_grade as enum ('excellent', 'very_good', 'good', 'fair');
create type public.shop_status as enum ('pending', 'approved', 'rejected');
create type public.device_status as enum (
  'draft', 'under_inspection', 'listed', 'reserved', 'sold',
  'warranty_active', 'warranty_closed', 'rejected', 'returned'
);

-- Public id generator: MD-XXXXX style, alphabet without ambiguous chars (no 0/O/1/I/L).
create or replace function public.gen_public_id(prefix text)
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  chars constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  result text := '';
  i int;
begin
  for i in 1..5 loop
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return prefix || '-' || result;
end;
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table public.shops (
  id bigint generated always as identity primary key,
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  city text not null check (char_length(city) between 2 and 80),
  phone_e164 text not null check (phone_e164 ~ '^\+[0-9]{8,15}$'),
  status public.shop_status not null default 'pending',
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index shops_status_idx on public.shops (status);

create trigger shops_touch_updated_at
  before update on public.shops
  for each row execute function public.touch_updated_at();

create table public.checklist_templates (
  id bigint generated always as identity primary key,
  category public.device_category not null,
  key text not null check (key ~ '^[a-z][a-z0-9_]*$'),
  label_ar text not null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (category, key)
);

create table public.devices (
  id bigint generated always as identity primary key,
  public_id text not null unique,
  shop_id bigint not null references public.shops(id) on delete cascade,
  category public.device_category not null,
  brand text not null check (char_length(brand) between 1 and 60),
  model text not null check (char_length(model) between 1 and 120),
  title text not null check (char_length(title) between 3 and 160),
  description text,
  price_minor bigint not null check (price_minor > 0),
  currency public.currency_code not null,
  grade public.condition_grade,
  warranty_days int not null default 90 check (warranty_days >= 30),
  imei text check (imei is null or imei ~ '^[0-9A-Za-z-]{4,32}$'),
  imei_last4 text generated always as (right(imei, 4)) stored,
  checklist jsonb not null default '[]'::jsonb check (jsonb_typeof(checklist) = 'array'),
  status public.device_status not null default 'draft',
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index devices_shop_id_idx on public.devices (shop_id);
create index devices_status_id_idx on public.devices (status, id desc);
create index devices_category_idx on public.devices (category);
create index devices_brand_idx on public.devices (brand);
create index devices_price_idx on public.devices (currency, price_minor);

create trigger devices_touch_updated_at
  before update on public.devices
  for each row execute function public.touch_updated_at();

create or replace function public.set_device_public_id()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.public_id is null then
    loop
      new.public_id := public.gen_public_id('MD');
      exit when not exists (select 1 from public.devices d where d.public_id = new.public_id);
    end loop;
  end if;
  return new;
end;
$$;

create trigger devices_set_public_id
  before insert on public.devices
  for each row execute function public.set_device_public_id();

create table public.device_photos (
  id bigint generated always as identity primary key,
  device_id bigint not null references public.devices(id) on delete cascade,
  storage_path text not null,
  sort_order int not null default 0,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now()
);

create index device_photos_device_idx on public.device_photos (device_id, sort_order);

create table public.listing_events (
  id bigint generated always as identity primary key,
  device_id bigint not null references public.devices(id) on delete cascade,
  from_status public.device_status,
  to_status public.device_status not null,
  actor uuid,
  note text,
  created_at timestamptz not null default now()
);

create index listing_events_device_idx on public.listing_events (device_id, id desc);
