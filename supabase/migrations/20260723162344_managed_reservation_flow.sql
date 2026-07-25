-- Managed, opaque order flow:
--   pending --(shop confirms availability)--> confirmed
--   confirmed --(platform dispatches)--> out_for_delivery
--   out_for_delivery --(buyer confirms receipt)--> delivered
-- Any active state may be cancelled by an authorized party.
-- Actor rules live in the transition trigger (runs as the caller), so a single
-- BEFORE UPDATE enforces both which transitions are legal and who may make them.
create or replace function public.enforce_reservation_transitions()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_legal boolean;
  v_uid uuid := (select auth.uid());
  v_is_admin boolean := (select public.is_admin());
  v_owns boolean := public.owns_device(new.device_id);
  v_is_buyer boolean := (old.buyer_id = v_uid);
begin
  if old.status = new.status then
    return new;
  end if;

  v_legal := case old.status
    when 'pending' then new.status in ('confirmed', 'cancelled')
    when 'confirmed' then new.status in ('out_for_delivery', 'cancelled')
    when 'out_for_delivery' then new.status in ('delivered', 'cancelled')
    else false
  end;
  if not v_legal then
    raise exception 'INVALID_STATE_TRANSITION'
      using detail = format('%s -> %s is not allowed', old.status, new.status);
  end if;

  if new.status = 'confirmed' then
    if not (v_owns or v_is_admin) then
      raise exception 'SELLER_ONLY_TRANSITION';
    end if;
  elsif new.status = 'out_for_delivery' then
    if not v_is_admin then
      raise exception 'ADMIN_ONLY_TRANSITION';
    end if;
  elsif new.status = 'delivered' then
    if not (v_is_buyer or v_is_admin) then
      raise exception 'BUYER_ONLY_TRANSITION';
    end if;
  elsif new.status = 'cancelled' then
    if not (v_is_buyer or v_owns or v_is_admin) then
      raise exception 'CANCEL_FORBIDDEN';
    end if;
  end if;

  return new;
end;
$$;

-- Buyers may now update their own reservation (to confirm receipt or cancel);
-- the trigger constrains exactly which transitions each actor can perform.
drop policy reservations_update on public.reservations;
create policy reservations_update on public.reservations
  for update to authenticated
  using (
    public.owns_device(device_id)
    or (select public.is_admin())
    or buyer_id = (select auth.uid())
  )
  with check (
    public.owns_device(device_id)
    or (select public.is_admin())
    or buyer_id = (select auth.uid())
  );
