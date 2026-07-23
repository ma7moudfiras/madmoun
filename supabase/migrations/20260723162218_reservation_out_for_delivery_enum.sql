-- New managed-delivery state between the shop's availability confirmation and
-- the buyer's receipt confirmation. Added in its own migration so the value is
-- committed before later migrations/functions reference it.
alter type public.reservation_status add value if not exists 'out_for_delivery' after 'confirmed';
