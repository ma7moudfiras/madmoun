-- Objective, admin-only shop reputation: derived purely from real platform
-- transactions (deliveries, cancellations, warranty claims, device review
-- outcomes) rather than free-text ratings any party could fabricate. Never
-- exposed to buyers or sellers — an internal quality signal for ops only.
create or replace function public.admin_shop_reputation()
returns table (
  shop_id bigint,
  shop_name text,
  shop_city text,
  shop_status public.shop_status,
  completed_orders bigint,
  cancelled_orders bigint,
  active_orders bigint,
  claims bigint,
  devices_submitted bigint,
  devices_rejected bigint,
  cancellation_rate numeric,
  claim_rate numeric,
  rejection_rate numeric,
  trust_score numeric,
  tier text
)
language sql
stable
security definer
set search_path = ''
as $$
  with order_stats as (
    select
      d.shop_id,
      count(*) filter (where r.status = 'delivered') as completed_orders,
      count(*) filter (where r.status = 'cancelled') as cancelled_orders,
      count(*) filter (where r.status in ('pending', 'confirmed', 'out_for_delivery'))
        as active_orders
    from public.reservations r
    join public.devices d on d.id = r.device_id
    group by d.shop_id
  ),
  claim_stats as (
    select d.shop_id, count(*) as claims
    from public.warranty_claims w
    join public.devices d on d.id = w.device_id
    group by d.shop_id
  ),
  device_stats as (
    select
      shop_id,
      count(*) filter (where status <> 'draft') as devices_submitted,
      count(*) filter (where status = 'rejected') as devices_rejected
    from public.devices
    group by shop_id
  ),
  stats as (
    select
      s.id as shop_id,
      s.name as shop_name,
      s.city as shop_city,
      s.status as shop_status,
      coalesce(o.completed_orders, 0) as completed_orders,
      coalesce(o.cancelled_orders, 0) as cancelled_orders,
      coalesce(o.active_orders, 0) as active_orders,
      coalesce(c.claims, 0) as claims,
      coalesce(ds.devices_submitted, 0) as devices_submitted,
      coalesce(ds.devices_rejected, 0) as devices_rejected
    from public.shops s
    left join order_stats o on o.shop_id = s.id
    left join claim_stats c on c.shop_id = s.id
    left join device_stats ds on ds.shop_id = s.id
  ),
  scored as (
    select
      *,
      coalesce(cancelled_orders::numeric / nullif(completed_orders + cancelled_orders, 0), 0)
        as cancel_ratio,
      coalesce(claims::numeric / nullif(completed_orders, 0), 0) as claim_ratio,
      coalesce(devices_rejected::numeric / nullif(devices_submitted, 0), 0) as reject_ratio
    from stats
  ),
  final as (
    select
      *,
      round(greatest(0, least(100,
        100 - 50 * cancel_ratio - 30 * claim_ratio - 20 * reject_ratio
      )), 0) as trust_score
    from scored
  )
  select
    shop_id, shop_name, shop_city, shop_status,
    completed_orders, cancelled_orders, active_orders, claims,
    devices_submitted, devices_rejected,
    round(cancel_ratio, 3) as cancellation_rate,
    round(claim_ratio, 3) as claim_rate,
    round(reject_ratio, 3) as rejection_rate,
    trust_score,
    case
      when completed_orders < 5 then 'new'
      when trust_score >= 85 then 'excellent'
      when trust_score >= 65 then 'good'
      when trust_score >= 40 then 'watch'
      else 'critical'
    end as tier
  from final
  where (select public.is_admin())
  order by (case when completed_orders < 5 then 1 else 0 end), trust_score asc, shop_name;
$$;

revoke execute on function public.admin_shop_reputation() from anon;
