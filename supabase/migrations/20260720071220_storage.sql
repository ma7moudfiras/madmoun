-- Storage bucket for device photos: public read, owner-scoped writes under
-- the path convention shop_{shop_id}/device_{device_id}/{file}.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('device-photos', 'device-photos', true, 2097152,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy device_photos_public_read on storage.objects
  for select
  using (bucket_id = 'device-photos');

create policy device_photos_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'device-photos'
    and (storage.foldername(name))[1] = 'shop_' || (select public.my_shop_id())::text
    and exists (
      select 1 from public.devices d
      where 'device_' || d.id::text = (storage.foldername(name))[2]
        and d.shop_id = (select public.my_shop_id())
    )
  );

create policy device_photos_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'device-photos'
    and (storage.foldername(name))[1] = 'shop_' || (select public.my_shop_id())::text
  )
  with check (
    bucket_id = 'device-photos'
    and (storage.foldername(name))[1] = 'shop_' || (select public.my_shop_id())::text
  );

create policy device_photos_owner_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'device-photos'
    and (storage.foldername(name))[1] = 'shop_' || (select public.my_shop_id())::text
  );
