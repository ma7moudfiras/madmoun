-- Managed/opaque intermediary: the buyer-facing listings view must not reveal
-- the shop's identity or contact. Drop shop_name and shop_phone (dropping view
-- columns needs DROP + CREATE, not CREATE OR REPLACE) and revoke the phone
-- column grant added earlier. Only the delivery city remains.
drop view if exists public.public_listings;

create view public.public_listings
with (security_invoker = on) as
select
  d.id, d.public_id, d.category, d.brand, d.model, d.title, d.description,
  d.price_minor, d.currency, d.grade, d.warranty_days, d.imei_last4,
  d.checklist, d.created_at,
  s.id as shop_id, s.city as shop_city
from public.devices d
join public.shops s on s.id = d.shop_id
where d.status = 'listed' and s.status = 'approved';

grant select on public.public_listings to anon, authenticated;

revoke select (phone_e164) on public.shops from anon, authenticated;
