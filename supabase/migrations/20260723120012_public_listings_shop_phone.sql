-- Expose the approved shop's business phone on the public listings view so
-- buyers can contact the shop directly (WhatsApp / call). Adding the column at
-- the end keeps CREATE OR REPLACE valid.
create or replace view public.public_listings
with (security_invoker = on) as
select
  d.id, d.public_id, d.category, d.brand, d.model, d.title, d.description,
  d.price_minor, d.currency, d.grade, d.warranty_days, d.imei_last4,
  d.checklist, d.created_at,
  s.id as shop_id, s.name as shop_name, s.city as shop_city,
  s.phone_e164 as shop_phone
from public.devices d
join public.shops s on s.id = d.shop_id
where d.status = 'listed' and s.status = 'approved';

grant select on public.public_listings to anon, authenticated;

-- The view is security_invoker, so the caller needs column-level SELECT on the
-- shop phone. RLS (shops_select) still limits anon to approved shops, so this
-- only exposes the approved shop's public business contact.
grant select (phone_e164) on public.shops to anon, authenticated;
