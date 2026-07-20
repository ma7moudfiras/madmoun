-- Device status state machine: the sole authority on status transitions.
-- Raises INVALID_STATE_TRANSITION on illegal moves, writes listing_events on legal ones.

create or replace function public.enforce_device_transitions()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_legal boolean;
  v_missing int;
  v_photos int;
begin
  if old.status = new.status then
    return new;
  end if;

  v_legal := case old.status
    when 'draft' then new.status in ('under_inspection', 'listed')
    when 'under_inspection' then new.status in ('listed', 'rejected', 'draft')
    when 'listed' then new.status in ('reserved', 'draft')
    when 'reserved' then new.status in ('sold', 'listed')
    when 'sold' then new.status in ('warranty_active', 'returned')
    when 'warranty_active' then new.status in ('warranty_closed', 'returned')
    when 'rejected' then new.status = 'draft'
    when 'returned' then new.status = 'draft'
    else false
  end;

  if not v_legal then
    raise exception 'INVALID_STATE_TRANSITION'
      using detail = format('%s -> %s is not allowed', old.status, new.status);
  end if;

  -- Review decisions and direct re-listing are reserved to platform admins.
  if ((old.status = 'under_inspection' and new.status in ('listed', 'rejected'))
      or (old.status = 'draft' and new.status = 'listed'))
     and not public.is_admin() then
    raise exception 'ADMIN_ONLY_TRANSITION'
      using detail = format('%s -> %s requires an admin', old.status, new.status);
  end if;

  -- A device may only leave draft for inspection when its dossier is complete.
  if old.status = 'draft' and new.status = 'under_inspection' then
    select count(*) into v_missing
    from public.checklist_templates t
    where t.category = new.category
      and t.is_active
      and not exists (
        select 1 from jsonb_array_elements(new.checklist) e
        where e ->> 'key' = t.key
          and e ->> 'result' in ('pass', 'minorIssue', 'fail')
      );
    if v_missing > 0 then
      raise exception 'CHECKLIST_INCOMPLETE'
        using detail = format('%s checklist items missing', v_missing);
    end if;

    select count(*) into v_photos
    from public.device_photos p
    where p.device_id = new.id and not p.is_deleted;
    if v_photos < 4 then
      raise exception 'INSUFFICIENT_PHOTOS'
        using detail = format('%s photos, minimum is 4', v_photos);
    end if;

    if new.category = 'mobile' and new.imei is null then
      raise exception 'IMEI_REQUIRED';
    end if;

    if new.grade is null then
      raise exception 'GRADE_REQUIRED';
    end if;
  end if;

  if old.status = 'under_inspection' and new.status = 'rejected'
     and coalesce(trim(new.rejection_reason), '') = '' then
    raise exception 'REJECTION_REASON_REQUIRED';
  end if;

  return new;
end;
$$;

create trigger devices_enforce_transitions
  before update of status on public.devices
  for each row execute function public.enforce_device_transitions();

create or replace function public.log_device_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.listing_events (device_id, from_status, to_status, actor)
    values (new.id, null, new.status, auth.uid());
  elsif old.status is distinct from new.status then
    insert into public.listing_events (device_id, from_status, to_status, actor, note)
    values (new.id, old.status, new.status, auth.uid(),
            case when new.status = 'rejected' then new.rejection_reason end);
  end if;
  return new;
end;
$$;

create trigger devices_log_event
  after insert or update on public.devices
  for each row execute function public.log_device_event();
