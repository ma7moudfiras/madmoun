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

const root = process.cwd();
const outputDir = join(root, '.vercel', 'output');
const staticDir = join(outputDir, 'static');
const funcDir = join(outputDir, 'functions', 'api', 'og.func');

mkdirSync(staticDir, { recursive: true });
cpSync(join(root, 'build', 'web'), staticDir, { recursive: true });

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
