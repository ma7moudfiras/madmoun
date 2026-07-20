-- Inspection checklist item definitions per category (Arabic labels).

insert into public.checklist_templates (category, key, label_ar, sort_order) values
  ('mobile', 'battery_health', 'صحة البطارية', 1),
  ('mobile', 'screen', 'الشاشة واللمس', 2),
  ('mobile', 'ports', 'منافذ الشحن والسماعات', 3),
  ('mobile', 'cameras', 'الكاميرات الأمامية والخلفية', 4),
  ('mobile', 'imei_clean', 'رقم IMEI نظيف وغير محظور', 5),
  ('mobile', 'network', 'الشبكة والاتصال (Wi-Fi / شريحة)', 6),
  ('laptop', 'battery_cycles', 'دورات شحن البطارية', 1),
  ('laptop', 'keyboard', 'لوحة المفاتيح ولوحة اللمس', 2),
  ('laptop', 'hinges', 'المفصلات وهيكل الجهاز', 3),
  ('laptop', 'screen', 'الشاشة والعرض', 4),
  ('laptop', 'ports', 'المنافذ (USB / HDMI / الشحن)', 5),
  ('laptop', 'storage_health', 'صحة وحدة التخزين', 6);
