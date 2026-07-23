-- In-app notifications, generated server-side by reservation triggers so each
-- party is told about its own next step. No external provider involved.
create table public.notifications (
  id bigint generated always as identity primary key,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  reservation_id bigint references public.reservations(id) on delete cascade,
  ref text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_recipient_idx on public.notifications (recipient_id, id desc);
create index notifications_unread_idx on public.notifications (recipient_id) where not is_read;

alter table public.notifications enable row level security;
revoke all on public.notifications from anon, authenticated;
grant select, update (is_read) on public.notifications to authenticated;

create policy notifications_select on public.notifications
  for select to authenticated
  using (recipient_id = (select auth.uid()));

create policy notifications_update on public.notifications
  for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()));

-- Insert helper (no-op when recipient is null); rows are only ever created by
-- the security-definer trigger, never directly by users.
create or replace function public.notify_order(
  p_recipient uuid, p_kind text, p_reservation bigint, p_ref text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications (recipient_id, kind, reservation_id, ref)
  select p_recipient, p_kind, p_reservation, p_ref
  where p_recipient is not null;
$$;

create or replace function public.reservation_notifications()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_shop_owner uuid;
  v_admin uuid;
begin
  select s.owner_id into v_shop_owner
  from public.devices d
  join public.shops s on s.id = d.shop_id
  where d.id = new.device_id;

  if tg_op = 'INSERT' then
    perform public.notify_order(v_shop_owner, 'new_order_shop', new.id, new.public_id);
    return new;
  end if;

  if old.status is distinct from new.status then
    if new.status = 'confirmed' then
      perform public.notify_order(new.buyer_id, 'order_confirmed_buyer', new.id, new.public_id);
      for v_admin in select id from public.profiles where role = 'admin' loop
        perform public.notify_order(v_admin, 'order_confirmed_admin', new.id, new.public_id);
      end loop;
    elsif new.status = 'out_for_delivery' then
      perform public.notify_order(new.buyer_id, 'out_for_delivery_buyer', new.id, new.public_id);
    elsif new.status = 'delivered' then
      perform public.notify_order(v_shop_owner, 'delivered_shop', new.id, new.public_id);
      for v_admin in select id from public.profiles where role = 'admin' loop
        perform public.notify_order(v_admin, 'delivered_admin', new.id, new.public_id);
      end loop;
    elsif new.status = 'cancelled' then
      perform public.notify_order(new.buyer_id, 'cancelled_buyer', new.id, new.public_id);
      perform public.notify_order(v_shop_owner, 'cancelled_shop', new.id, new.public_id);
    end if;
  end if;
  return new;
end;
$$;

create trigger reservations_notify_insert
  after insert on public.reservations
  for each row execute function public.reservation_notifications();

create trigger reservations_notify_update
  after update of status on public.reservations
  for each row execute function public.reservation_notifications();
