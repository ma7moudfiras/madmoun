-- Arabic-aware search: buyers routinely mix orthographic variants that a
-- plain ILIKE treats as different words (إيفون vs أيفون vs ايفون, تاء
-- مربوطة vs هاء, alef maksura vs ya, and diacritics). normalize_ar() strips
-- diacritics/tatweel and collapses those variants so a search for one form
-- matches the others. Unicode code points are referenced via U&'...'
-- escapes rather than embedding literal combining characters, so the
-- pattern stays unambiguous in source control.
create extension if not exists pg_trgm;

create or replace function public.normalize_ar(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            lower(coalesce(p_text, '')),
            U&'[\064B\064C\064D\064E\064F\0650\0651\0652\0670\0640]', '', 'g'
          ),
          U&'[\0623\0622\0625\0671]', U&'\0627', 'g'
        ),
        U&'\0649', U&'\064A', 'g'
      ),
      U&'\0629', U&'\0647', 'g'
    ),
    '\s+', ' ', 'g'
  );
$$;

alter table public.devices
  add column search_text text generated always as (
    public.normalize_ar(title || ' ' || coalesce(brand, '') || ' ' || coalesce(model, ''))
  ) stored;

create index devices_search_text_trgm_idx
  on public.devices using gin (search_text gin_trgm_ops);

-- Appending a column to the end keeps this a plain CREATE OR REPLACE (no
-- column was removed or reordered).
create or replace view public.public_listings
with (security_invoker = on) as
select
  d.id, d.public_id, d.category, d.brand, d.model, d.title, d.description,
  d.price_minor, d.currency, d.grade, d.warranty_days, d.imei_last4,
  d.checklist, d.created_at,
  s.id as shop_id, s.city as shop_city,
  d.search_text
from public.devices d
join public.shops s on s.id = d.shop_id
where d.status = 'listed' and s.status = 'approved';

grant select on public.public_listings to anon, authenticated;
