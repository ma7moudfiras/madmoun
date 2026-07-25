-- Business decision: ILS is the sole stored currency from here on. Sellers
-- no longer choose a currency when listing (the client form always sends
-- 'ils'), and this migration converts existing USD-priced devices/
-- reservations to ILS once, using the live ILS/USD rate at migration time
-- (1 ILS ~= 0.326955 USD, i.e. 1 USD ~= 3.0586 ILS) so the data is
-- consistent with the new single-currency model instead of frozen in a
-- currency nothing can generate anymore.
--
-- Buyer-facing USD display (a toggle on the marketplace) is a separate,
-- live-converted, non-stored presentation layer — see
-- lib/core/currency_display.dart — and never touches these stored amounts.
update public.devices
set price_minor = round(price_minor / 0.326955)::bigint,
    currency = 'ILS'
where currency = 'USD';

update public.reservations
set price_minor = round(price_minor / 0.326955)::bigint,
    commission_minor =
      round(round(price_minor / 0.326955)::bigint * commission_percent / 100.0)::bigint,
    currency = 'ILS'
where currency = 'USD';

alter table public.devices
  add constraint devices_currency_ils_only check (currency = 'ILS');

alter table public.reservations
  add constraint reservations_currency_ils_only check (currency = 'ILS');
