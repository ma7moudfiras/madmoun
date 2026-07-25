#!/usr/bin/env node
// Assembles the Vercel Build Output API v3 structure (.vercel/output) after
// the Flutter web build.
//
// Why this exists: the project has a custom buildCommand + outputDirectory
// (Flutter isn't a Vercel-recognized framework), and that combination turns
// out to silently skip Vercel's automatic /api function detection entirely
// — confirmed by hitting a made-up /api/* path in production and getting the
// static app shell back instead of a 404. The Build Output API sidesteps
// that ambiguity: we assemble the static site AND the api/og link-preview
// function ourselves, so routing is fully explicit.
import { cpSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://dutmsyjwrueyyrdeccol.supabase.co';
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dG1zeWp3cnVleXlyZGVjY29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0Nzk4NDAsImV4cCI6MjEwMDA1NTg0MH0.wk_Y_1ZXcOKCj_09PNNn5uqDFQ5_hzbFqjUdlhrlXXA';
const SITE_ORIGIN = 'https://madmoun-five.vercel.app';

const root = process.cwd();
const outputDir = join(root, '.vercel', 'output');
const staticDir = join(outputDir, 'static');
const funcDir = join(outputDir, 'functions', 'api', 'og.func');

mkdirSync(staticDir, { recursive: true });
cpSync(join(root, 'build', 'web'), staticDir, { recursive: true });

// A dynamic sitemap: static pages plus every currently listed device, so new
// listings get discovered without a fresh manual sitemap on every deploy.
async function buildSitemap() {
  const staticPaths = ['/', '/how-it-works', '/faq', '/terms', '/privacy'];
  let devices = [];
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/public_listings?select=public_id,created_at&order=id.desc&limit=5000`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      },
    );
    if (res.ok) devices = await res.json();
  } catch (err) {
    console.warn('sitemap: could not fetch listings, shipping static pages only', err);
  }

  const urlEntries = [
    ...staticPaths.map((p) => `  <url><loc>${SITE_ORIGIN}${p}</loc></url>`),
    ...devices.map(
      (d) =>
        `  <url><loc>${SITE_ORIGIN}/d/${d.public_id}</loc><lastmod>${new Date(d.created_at).toISOString().slice(0, 10)}</lastmod></url>`,
    ),
  ];

  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urlEntries.join('\n')}\n</urlset>\n`;
  writeFileSync(join(staticDir, 'sitemap.xml'), xml);
  console.log(`sitemap.xml: ${staticPaths.length} static pages + ${devices.length} devices`);
}

await buildSitemap();

mkdirSync(funcDir, { recursive: true });
cpSync(join(root, 'api', 'og', '[id].js'), join(funcDir, 'index.js'));
writeFileSync(
  join(funcDir, '.vc-config.json'),
  JSON.stringify(
    {
      runtime: 'nodejs22.x',
      handler: 'index.js',
      launcherType: 'Nodejs',
      shouldAddHelpers: true,
    },
    null,
    2,
  ),
);

// Real UA strings sent by link-preview crawlers — see api/og/[id].js for why
// only these get the prerendered page instead of the normal SPA shell.
const botUserAgents =
  '(facebookexternalhit|Facebot|WhatsApp|Twitterbot|LinkedInBot|TelegramBot|Slackbot|Discordbot|Googlebot|bingbot|Applebot|Pinterest|redditbot|vkShare|SkypeUriPreview|W3C_Validator|Embedly|Iframely|Outbrain)';

const config = {
  version: 3,
  routes: [
    {
      src: '^/canvaskit/(.*)$',
      headers: { 'cache-control': 'public, max-age=31536000, immutable' },
      continue: true,
    },
    {
      src: '^/assets/assets/fonts/(.*)$',
      headers: { 'cache-control': 'public, max-age=31536000, immutable' },
      continue: true,
    },
    {
      src: '^/d/([^/]+)$',
      has: [{ type: 'header', key: 'user-agent', value: { re: botUserAgents } }],
      dest: '/api/og?id=$1',
    },
    { src: '^/api/og/([^/]+)$', dest: '/api/og?id=$1' },
    { handle: 'filesystem' },
    { src: '^/(.*)$', dest: '/index.html' },
  ],
};

writeFileSync(join(outputDir, 'config.json'), JSON.stringify(config, null, 2));

console.log('Build Output API assembled at .vercel/output');
