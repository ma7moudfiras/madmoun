-- Madmoun demo seed. Idempotent: safe to re-run. Not a migration.
--
-- Creates: 1 admin, 2 approved shops (with owners), 1 buyer,
--          8 devices across categories/currencies/grades, demo reservations
--          (incl. delivered ones so the impact counter is non-zero).
--
-- Auth users use fixed UUIDs so the script is deterministic. Passwords are
-- the demo credentials printed to README-local.md (gitignored).
--
-- Photos reference hosted placeholder URLs; the app renders absolute URLs
-- directly and bucket paths via getPublicUrl, so no binary upload is needed.

begin;

-- ---------------------------------------------------------------------------
-- Auth users (admin, two shop owners, one buyer).
-- ---------------------------------------------------------------------------

create or replace function pg_temp.seed_user(
  p_id uuid, p_email text, p_password text, p_name text
) returns void language plpgsql as $$
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000', p_id, 'authenticated',
    'authenticated', p_email, crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', p_name),
    '', '', '', ''
  ) on conflict (id) do update
    set encrypted_password = excluded.encrypted_password,
        email_confirmed_at = excluded.email_confirmed_at;

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), p_id, p_id::text,
    jsonb_build_object('sub', p_id::text, 'email', p_email, 'email_verified', true),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do nothing;
end;
$$;

select pg_temp.seed_user(
  '11111111-1111-1111-1111-111111111111',
  'admin@madmoun.ps', 'Admin#Madmoun2026', 'مشرف المنصة');
select pg_temp.seed_user(
  '22222222-2222-2222-2222-222222222222',
  'mahalna@madmoun.ps', 'Seller#Madmoun2026', 'محلنا للموبايل');
select pg_temp.seed_user(
  '33333333-3333-3333-3333-333333333333',
  'technosafe@madmoun.ps', 'Seller#Madmoun2026', 'تكنو سيف');
select pg_temp.seed_user(
  '44444444-4444-4444-4444-444444444444',
  'buyer@madmoun.ps', 'Buyer#Madmoun2026', 'زبون تجريبي');

-- Attaches four hosted placeholder photos to a device (rendered as absolute
-- URLs by the client). Deterministic per tag so images are stable.
create or replace function pg_temp.seed_photos(p_device_id bigint, p_tag text)
returns void language plpgsql as $$
begin
  insert into public.device_photos (device_id, storage_path, sort_order)
  select p_device_id,
         format('https://picsum.photos/seed/madmoun-%s-%s/900/675', p_tag, g),
         g - 1
  from generate_series(1, 4) as g;
end;
$$;

-- Roles (profiles auto-created by the handle_new_user trigger).
update public.profiles
  set role = 'admin', full_name = 'مشرف المنصة', phone_e164 = '+970599000000'
  where id = '11111111-1111-1111-1111-111111111111';
update public.profiles set phone_e164 = '+970598111111'
  where id = '44444444-4444-4444-4444-444444444444';

-- ---------------------------------------------------------------------------
-- Shops, devices, photos, reservations.
-- ---------------------------------------------------------------------------

do $$
declare
  v_shop1 bigint;
  v_shop2 bigint;
  v_buyer uuid := '44444444-4444-4444-4444-444444444444';
  v_dev bigint;
begin
  -- Fresh demo data each run (leave auth users intact).
  delete from public.warranty_claims;
  delete from public.reservations;
  delete from public.listing_events;
  delete from public.device_photos;
  delete from public.devices;
  delete from public.shops;

  insert into public.shops (owner_id, name, city, phone_e164, status)
  values ('22222222-2222-2222-2222-222222222222', 'محلنا للموبايل',
          'رام الله', '+970599123456', 'approved')
  returning id into v_shop1;

  insert into public.shops (owner_id, name, city, phone_e164, status)
  values ('33333333-3333-3333-3333-333333333333', 'تكنو سيف',
          'نابلس', '+970598654321', 'approved')
  returning id into v_shop2;

  -- Device 1: iPhone 13 Pro — mobile, ILS, excellent, listed.
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop1, 'mobile', 'Apple', 'iPhone 13 Pro',
    'iPhone 13 Pro 256GB أزرق سييرا — حالة ممتازة',
    'تم فحص الجهاز بالكامل واستبدال البطارية بأخرى جديدة. لا توجد أي خدوش.',
    380000, 'ILS', 'excellent', 180, '356789012345671', 'listed',
    '[{"key":"battery_health","result":"pass"},{"key":"screen","result":"pass"},
      {"key":"ports","result":"pass"},{"key":"cameras","result":"pass"},
      {"key":"imei_clean","result":"pass"},{"key":"network","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'phone-a');

  -- Device 2: Samsung Galaxy S21 — mobile, ILS, very_good, listed.
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop1, 'mobile', 'Samsung', 'Galaxy S21',
    'Samsung Galaxy S21 128GB رمادي — جيد جدًا',
    'الجهاز بحالة جيدة جدًا مع خدش بسيط جدًا على الإطار لا يؤثر على الاستخدام.',
    195000, 'ILS', 'very_good', 90, '356789012345672', 'listed',
    '[{"key":"battery_health","result":"minorIssue","note":"صحة البطارية 88%"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"pass"},
      {"key":"cameras","result":"pass"},{"key":"imei_clean","result":"pass"},
      {"key":"network","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'phone-b');

  -- Device 3: iPhone 12 — mobile, USD, good, listed.
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop2, 'mobile', 'Apple', 'iPhone 12',
    'iPhone 12 128GB أسود — حالة جيدة',
    'جهاز عملي بسعر مناسب. علامات استخدام خفيفة على الإطار.',
    32000, 'USD', 'good', 90, '356789012345673', 'listed',
    '[{"key":"battery_health","result":"minorIssue","note":"صحة البطارية 82%"},
      {"key":"screen","result":"minorIssue","note":"خدش شعري بسيط"},
      {"key":"ports","result":"pass"},{"key":"cameras","result":"pass"},
      {"key":"imei_clean","result":"pass"},{"key":"network","result":"minorIssue"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'phone-c');

  -- Device 4: MacBook Air M1 — laptop, USD, excellent, listed.
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop2, 'laptop', 'Apple', 'MacBook Air M1',
    'MacBook Air M1 2020 8GB/256GB — ممتاز',
    'أداء ممتاز وبطارية شبه جديدة. مثالي للطلاب والعمل المكتبي.',
    75000, 'USD', 'excellent', 180, 'C02XY123ABCD', 'listed',
    '[{"key":"battery_cycles","result":"pass","note":"عدد الدورات 120"},
      {"key":"keyboard","result":"pass"},{"key":"hinges","result":"pass"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"pass"},
      {"key":"storage_health","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'laptop-a');

  -- Device 5: Lenovo ThinkPad T14 — laptop, ILS, very_good, listed.
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop1, 'laptop', 'Lenovo', 'ThinkPad T14',
    'Lenovo ThinkPad T14 i5/16GB/512GB — جيد جدًا',
    'لابتوب أعمال متين. لوحة مفاتيح ممتازة وشاشة نظيفة.',
    290000, 'ILS', 'very_good', 120, 'PF1ABCDE', 'listed',
    '[{"key":"battery_cycles","result":"minorIssue","note":"عدد الدورات 340"},
      {"key":"keyboard","result":"pass"},{"key":"hinges","result":"pass"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"pass"},
      {"key":"storage_health","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'laptop-b');

  -- Device 6: Dell XPS 13 — laptop, USD, good, RESERVED (pending reservation).
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop2, 'laptop', 'Dell', 'XPS 13',
    'Dell XPS 13 i7/16GB/512GB — حالة جيدة',
    'شاشة عالية الدقة وتصميم نحيف. علامات استخدام خفيفة.',
    62000, 'USD', 'good', 90, 'DXPS13XYZ', 'reserved',
    '[{"key":"battery_cycles","result":"minorIssue","note":"عدد الدورات 480"},
      {"key":"keyboard","result":"minorIssue"},{"key":"hinges","result":"pass"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"minorIssue"},
      {"key":"storage_health","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'laptop-c');
  insert into public.reservations (device_id, buyer_id, buyer_phone_e164,
    delivery_city, delivery_note, price_minor, currency, commission_percent,
    commission_minor, status)
  values (v_dev, v_buyer, '+970598111111', 'رام الله',
    'يفضل التسليم مساءً', 62000, 'USD', 10.0, 6200, 'pending');

  -- Device 7: iPhone 11 — mobile, ILS, good, WARRANTY_ACTIVE (delivered).
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop1, 'mobile', 'Apple', 'iPhone 11',
    'iPhone 11 64GB أبيض — حالة جيدة',
    'خيار اقتصادي ممتاز مع ضمان فعّال.',
    150000, 'ILS', 'good', 90, '356789012345677', 'warranty_active',
    '[{"key":"battery_health","result":"minorIssue","note":"صحة البطارية 79%"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"minorIssue"},
      {"key":"cameras","result":"minorIssue"},{"key":"imei_clean","result":"pass"},
      {"key":"network","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'phone-d');
  insert into public.reservations (device_id, buyer_id, buyer_phone_e164,
    delivery_city, price_minor, currency, commission_percent,
    commission_minor, status)
  values (v_dev, v_buyer, '+970598111111', 'رام الله',
    150000, 'ILS', 10.0, 15000, 'delivered');

  -- Device 8: HP EliteBook 840 — laptop, ILS, fair, WARRANTY_ACTIVE (delivered).
  insert into public.devices (shop_id, category, brand, model, title,
    description, price_minor, currency, grade, warranty_days, imei, status, checklist)
  values (v_shop2, 'laptop', 'HP', 'EliteBook 840',
    'HP EliteBook 840 G5 i5/8GB/256GB — مقبول',
    'يعمل بكفاءة للاستخدام اليومي. علامات استخدام واضحة على الهيكل.',
    170000, 'ILS', 'fair', 90, 'HPEB840G5', 'warranty_active',
    '[{"key":"battery_cycles","result":"fail","note":"تحتاج البطارية للاستبدال قريبًا"},
      {"key":"keyboard","result":"pass"},{"key":"hinges","result":"minorIssue"},
      {"key":"screen","result":"pass"},{"key":"ports","result":"pass"},
      {"key":"storage_health","result":"pass"}]'::jsonb)
  returning id into v_dev;
  perform pg_temp.seed_photos(v_dev, 'laptop-d');
  insert into public.reservations (device_id, buyer_id, buyer_phone_e164,
    delivery_city, price_minor, currency, commission_percent,
    commission_minor, status)
  values (v_dev, v_buyer, '+970598111111', 'نابلس',
    170000, 'ILS', 10.0, 17000, 'delivered');
end;
$$;

commit;
