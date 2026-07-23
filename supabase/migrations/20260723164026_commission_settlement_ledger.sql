-- Commission settlement ledger. Every delivered order owes the platform its
-- commission; the founder reconciles the courier's COD remittance and marks
-- the order settled. Currencies never mix, so all reporting groups by currency.
alter table public.reservations
  add column settlement_status text not null default 'pending'
    check (settlement_status in ('pending', 'settled')),
  add column settled_at timestamptz;

-- Per-currency commission summary over completed (delivered) orders.
create or replace function public.admin_commission_summary()
returns table (
  currency text,
  orders bigint,
  gross_minor bigint,
  commission_minor bigint,
  settled_minor bigint,
  pending_minor bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.currency::text,
    count(*),
    coalesce(sum(r.price_minor), 0),
    coalesce(sum(r.commission_minor), 0),
    coalesce(sum(r.commission_minor) filter (where r.settlement_status = 'settled'), 0),
    coalesce(sum(r.commission_minor) filter (where r.settlement_status = 'pending'), 0)
  from public.reservations r
  where r.status = 'delivered' and (select public.is_admin())
  group by r.currency;
$$;

revoke execute on function public.admin_commission_summary() from anon;

-- Mark a delivered order's commission as settled (courier COD reconciled +
-- shop paid its net). Admin-only.
create or replace function public.admin_settle_reservation(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select public.is_admin()) then
    raise exception 'ADMIN_ONLY';
  end if;
  update public.reservations
    set settlement_status = 'settled', settled_at = now()
    where id = p_id and status = 'delivered';
end;
$$;

revoke execute on function public.admin_settle_reservation(bigint) from anon;
