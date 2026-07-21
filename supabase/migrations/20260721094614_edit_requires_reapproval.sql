-- Allow a seller to edit an already-listed device and resubmit it for review:
-- listed -> under_inspection becomes legal, and the completeness gate (photos,
-- checklist, grade, IMEI) now applies to any transition INTO under_inspection,
-- not just from draft. The device leaves the public marketplace until an admin
-- re-approves it.

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
    when 'listed' then new.status in ('reserved', 'draft', 'under_inspection')
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

  -- A device may only enter inspection when its dossier is complete.
  if new.status = 'under_inspection' then
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
