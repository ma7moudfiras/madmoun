-- owner_id is not client-writable (no column grant); default it to the
-- caller so shop onboarding inserts satisfy the RLS with-check.
alter table public.shops alter column owner_id set default auth.uid();
