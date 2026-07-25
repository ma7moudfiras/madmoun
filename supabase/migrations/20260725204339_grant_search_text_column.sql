-- public_listings uses security_invoker, so the querying role needs its own
-- column-level grant on every column the view selects — new columns don't
-- inherit that automatically. Adding search_text without this broke the
-- whole view for anon/authenticated (permission denied on devices).
grant select (search_text) on public.devices to anon, authenticated;
