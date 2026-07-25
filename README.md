# مضمون · Madmoun

A Palestinian intermediary marketplace for certified used electronics
(mobiles + laptops). No inventory: certified repair shops list devices after a
standardized technical inspection, every device carries a mandatory warranty,
buyers reserve and pay cash on delivery (COD), and the platform surfaces an
environmental-impact counter (devices saved from e-waste + estimated CO₂
avoided).

Single Flutter Web codebase, three role areas: public buyer marketplace,
seller portal (repair shops), admin panel (platform operators). Arabic-only,
RTL, via `slang` (structured so English can be added later as pure content).
Currency is per-listing ILS (₪) or USD ($) — no conversion anywhere.

## Tech stack

- **Flutter** (Web) · `flutter_riverpod` · `go_router` · `supabase_flutter`
  · `slang` · `flutter_image_compress`
- **Backend:** Supabase only (Postgres + Auth + Storage + RLS). No custom server.
- **Hosting:** Vercel (static `build/web`).

## Architecture principles

- **Money** is always `int` minor units + an adjacent `Currency` enum — never
  floats. See `lib/core/domain.dart`.
- **Single source of truth:** colors only in `lib/core/theme/app_theme.dart`;
  grading/commission/phone/id logic only in `lib/core/domain.dart` (unit
  tested); the Postgres state-machine trigger is the sole authority on device
  status transitions.
- **Feature-first** folders under `lib/features/`.
- `Supabase.instance` is touched in exactly one place
  (`lib/core/supabase_providers.dart`).

## Project layout

```
lib/
  core/            domain, theme, models, router, errors, shared widgets
  features/
    auth/          email/password (+ optional Google) login & register
    marketplace/   public home, device page, listing repository
    buyer/         reserve flow, طلباتي (orders), warranty claims
    seller/        shop onboarding, devices, photos, reservations, claims
    admin/         dashboard, shops queue, device review, templates, claims
    shell/         public chrome, not-found
  i18n/            slang Arabic catalog (ar.i18n.json) + generated strings
supabase/
  migrations/      versioned schema, RLS, state machine, storage, RPCs
  seed.sql         demo data (idempotent; not a migration)
```

## Database

Applied as versioned migrations in `supabase/migrations/`:

- Types, `shops`, `devices` (`MD-XXXXX` public ids, IMEI stored but only a
  generated `imei_last4` is ever readable), `device_photos`, `listing_events`,
  `checklist_templates` (Arabic labels, per category).
- `profiles`/roles with an auto-provisioning trigger on `auth.users`.
- Device **state machine** trigger: raises `INVALID_STATE_TRANSITION` on
  illegal moves, writes a `listing_events` audit row on legal ones, and gates
  `draft → under_inspection` on ≥4 photos + a complete checklist + grade.
- COD `reservations` (price/commission snapshots), `warranty_claims`.
- Full **RLS** + column-level grants: sellers see only their own rows, anon
  reads only `listed` devices via the `public_listings` view, and the raw IMEI
  is never granted for `SELECT`.
- `reserve_device(...)` — the only path buyers can reserve: a `security
  definer` RPC that locks the device row, verifies `listed`, snapshots
  price + commission, inserts the reservation and flips the device to
  `reserved` (race-safe).
- `impact_stats()` public counter; admin RPCs for shop/device review,
  warranty triage, and dashboard counts.
- Storage bucket `device-photos` (public read) with owner-scoped write/delete
  under the `shop_{shop_id}/device_{device_id}/…` path convention.

Supabase security & performance advisors were run after migrating; there are
no ERROR-level findings.

## Local development

```bash
flutter pub get
dart run slang                 # regenerate i18n after editing ar.i18n.json
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
flutter analyze
flutter test
```

Defaults for `SUPABASE_URL` / `SUPABASE_ANON_KEY` are baked in
`lib/core/supabase_providers.dart` (the anon key is public by design), so the
app also runs with no `--dart-define`.

## Seeding demo data

`supabase/seed.sql` is idempotent and creates: 1 admin, 2 approved shops (with
owners), 1 buyer, 8 devices across categories/currencies/grades, and demo
reservations (including delivered ones so the impact counter is non-zero). Run
it against the project once with `psql` (or paste it into the Supabase SQL
editor):

```bash
psql "$SUPABASE_DB_URL" -f supabase/seed.sql
```

Demo account credentials are written to `README-local.md` (gitignored).

## Deployment (Vercel)

`vercel.json` clones Flutter stable in the install step, builds the web bundle
with the Supabase env vars injected as `--dart-define`, outputs `build/web`,
and rewrites all routes to `/index.html` (SPA). Set `SUPABASE_URL` and
`SUPABASE_ANON_KEY` as Vercel environment variables, then deploy.

After the first deploy, add the Vercel URL to the Supabase Auth **Site URL** /
**Redirect URLs** so email links resolve correctly.

## CI

`.github/workflows/ci.yml` runs `flutter analyze` + `flutter test` (and checks
that the generated `slang` output is committed) on every push/PR to `main`.

## Auth

Email/password sign-in works out of the box. New sign-ups must confirm their
email through Supabase's built-in email service — the confirmation,
email-change, and password-reset links rely on the **Site URL / Redirect URLs**
(Authentication → URL Configuration) pointing at the deployed origin (set). The
built-in service is rate-limited to a few messages/hour; if you later outgrow
that, plug in custom SMTP under Authentication → Emails → SMTP.

`supabase/migrations/20260720185124_auto_confirm_emails.sql` (a pre-confirm
trigger) was superseded by
`20260721101620_enforce_email_confirmation.sql`, which drops it so real
confirmation applies. Existing/seed accounts stay confirmed.

## Manual steps

- **Google OAuth** ships behind the `ENABLE_GOOGLE_AUTH` compile-time flag. To
  enable it: configure a Google OAuth client in the Supabase dashboard
  (Authentication → Providers → Google), then build with
  `--dart-define=ENABLE_GOOGLE_AUTH=true`. Email/password auth works out of the
  box without it.
- Supabase Auth **Site URL** + **Redirect URLs** are set to the deployed origin;
  email confirmation uses the built-in service (custom SMTP optional later).
