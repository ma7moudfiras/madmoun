-- Buyer wishlist: bookmark a device to compare/decide later. Purely
-- personal state — a buyer only ever sees/manages their own rows.
create table public.favorites (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id bigint not null references public.devices(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, device_id)
);

create index favorites_user_idx on public.favorites (user_id, id desc);

alter table public.favorites enable row level security;

create policy favorites_select on public.favorites
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy favorites_insert on public.favorites
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy favorites_delete on public.favorites
  for delete to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, delete on public.favorites to authenticated;
