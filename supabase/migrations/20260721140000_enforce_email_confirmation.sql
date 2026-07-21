-- Enforce real email confirmation for new sign-ups. The earlier MVP trigger
-- pre-confirmed every account; removing it hands confirmation back to
-- Supabase Auth (email confirmation is enabled by default). Existing accounts
-- (including the seed users) keep their already-confirmed status; only new
-- sign-ups must confirm their address before they can sign in.
--
-- Requires the Site URL + Redirect URLs to be configured in the Supabase
-- dashboard (Authentication → URL Configuration) so the confirmation link
-- lands back on the app.

drop trigger if exists on_auth_user_precreate on auth.users;
drop function if exists public.auto_confirm_email();
