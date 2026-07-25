// Vercel serverless function: prerendered Open Graph / Twitter Card meta tags
// for a single device listing. Flutter Web is a client-rendered SPA, so link
// crawlers (WhatsApp, Facebook, Twitter, …) never run the JS that would show
// the real title/price/photo — they only see whatever is in the raw HTML.
// vercel.json rewrites /d/:id to this function ONLY for known crawler user
// agents (see the `has` header condition), so real visitors still get the
// normal app; only the link-preview bot sees this prerendered page.
const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://dutmsyjwrueyyrdeccol.supabase.co';
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dG1zeWp3cnVleXlyZGVjY29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0Nzk4NDAsImV4cCI6MjEwMDA1NTg0MH0.wk_Y_1ZXcOKCj_09PNNn5uqDFQ5_hzbFqjUdlhrlXXA';

const CURRENCY_SYMBOLS = { ILS: '₪', USD: '$' };
const GRADE_LABELS = {
  excellent: 'ممتاز',
  very_good: 'جيد جدًا',
  good: 'جيد',
  fair: 'مقبول',
};

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function supabaseGet(path) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: {
      apikey: SUPABASE_ANON_KEY,
      authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
  });
  if (!res.ok) return [];
  return res.json();
}

function renderHtml({ title, description, image, pageUrl }) {
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>${escapeHtml(title)}</title>
<meta property="og:type" content="product">
<meta property="og:site_name" content="مضمون">
<meta property="og:title" content="${escapeHtml(title)}">
<meta property="og:description" content="${escapeHtml(description)}">
<meta property="og:image" content="${escapeHtml(image)}">
<meta property="og:url" content="${escapeHtml(pageUrl)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${escapeHtml(title)}">
<meta name="twitter:description" content="${escapeHtml(description)}">
<meta name="twitter:image" content="${escapeHtml(image)}">
<meta http-equiv="refresh" content="0; url=${escapeHtml(pageUrl)}">
</head>
<body></body>
</html>`;
}

module.exports = async (req, res) => {
  const publicId = req.query.id;
  const origin = `https://${req.headers.host}`;
  const pageUrl = `${origin}/d/${encodeURIComponent(publicId || '')}`;
  const fallbackImage = `${origin}/icons/Icon-512.png`;
  const fallback = {
    title: 'مضمون',
    description: 'سوق فلسطيني للأجهزة الإلكترونية المستعملة الموثوقة.',
    image: fallbackImage,
    pageUrl,
  };

  res.setHeader('content-type', 'text/html; charset=utf-8');
  res.setHeader('cache-control', 'public, max-age=300, s-maxage=300');

  if (!publicId) {
    res.status(200).send(renderHtml(fallback));
    return;
  }

  try {
    const listings = await supabaseGet(
      `public_listings?public_id=eq.${encodeURIComponent(publicId)}&select=id,title,price_minor,currency,grade,shop_city`,
    );
    const listing = listings[0];
    if (!listing) {
      res.status(200).send(
        renderHtml({
          ...fallback,
          title: 'جهاز غير متاح | مضمون',
          description: 'هذا الجهاز لم يعد متاحًا على مضمون.',
        }),
      );
      return;
    }

    const photos = await supabaseGet(
      `device_photos?device_id=eq.${listing.id}&is_deleted=eq.false&order=sort_order.asc&limit=1&select=storage_path`,
    );
    const storagePath = photos[0] && photos[0].storage_path;
    const image = storagePath
      ? `${SUPABASE_URL}/storage/v1/object/public/device-photos/${storagePath}`
      : fallbackImage;

    const symbol = CURRENCY_SYMBOLS[listing.currency] || listing.currency;
    const major = Math.floor(listing.price_minor / 100);
    const price = `${symbol} ${major.toLocaleString('en-US')}`;
    const grade = GRADE_LABELS[listing.grade] || '';
    const title = `${listing.title} | مضمون`;
    const description = [price, grade, listing.shop_city, 'مضمون بضمان — الدفع عند الاستلام']
      .filter(Boolean)
      .join(' · ');

    res.status(200).send(renderHtml({ title, description, image, pageUrl }));
  } catch (err) {
    res.status(200).send(renderHtml(fallback));
  }
};
