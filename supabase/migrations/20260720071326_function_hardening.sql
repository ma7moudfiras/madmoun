-- Tighten EXECUTE on functions: new functions default-grant EXECUTE to PUBLIC,
-- so revoke from PUBLIC and re-grant only to the roles that need each function.

-- Trigger functions are never called through the API.
revoke execute on function public.touch_updated_at() from public, anon, authenticated;
revoke execute on function public.set_device_public_id() from public, anon, authenticated;
revoke execute on function public.set_reservation_public_id() from public, anon, authenticated;
revoke execute on function public.enforce_device_transitions() from public, anon, authenticated;
revoke execute on function public.log_device_event() from public, anon, authenticated;
revoke execute on function public.enforce_reservation_transitions() from public, anon, authenticated;
revoke execute on function public.apply_reservation_effects() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.promote_to_seller() from public, anon, authenticated;
revoke execute on function public.gen_public_id(text) from public, anon, authenticated;

-- Signed-in-only RPCs.
revoke execute on function public.reserve_device(bigint, text, text, text) from public, anon;
revoke execute on function public.my_shop() from public, anon;
revoke execute on function public.admin_set_role(uuid, public.user_role) from public, anon;
revoke execute on function public.admin_shops(public.shop_status) from public, anon;
revoke execute on function public.admin_set_shop_status(bigint, public.shop_status, text) from public, anon;
revoke execute on function public.admin_review_device(bigint, boolean, text) from public, anon;
revoke execute on function public.admin_update_claim(bigint, text, text) from public, anon;
revoke execute on function public.admin_dashboard_stats() from public, anon;

-- Helpers referenced inside RLS policies must stay executable by both API
-- roles (policy expressions run as the querying role); impact_stats is the
-- public counter. All of these expose nothing beyond the caller's own scope.
revoke execute on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;
revoke execute on function public.my_shop_id() from public;
grant execute on function public.my_shop_id() to anon, authenticated;
revoke execute on function public.owns_device(bigint) from public;
grant execute on function public.owns_device(bigint) to anon, authenticated;
revoke execute on function public.has_reservation_on(bigint) from public;
grant execute on function public.has_reservation_on(bigint) to anon, authenticated;
revoke execute on function public.impact_stats() from public;
grant execute on function public.impact_stats() to anon, authenticated;

-- Public buckets serve objects by URL without a SELECT policy; dropping the
-- broad policy prevents anonymous listing of the whole bucket.
drop policy device_photos_public_read on storage.objects;
