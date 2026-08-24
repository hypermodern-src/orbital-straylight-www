#!/usr/bin/env node
// Generate hero imagery for the ponce-speedway rebuild via fal.ai flux-pro v1.1

import fs from 'node:fs';
import path from 'node:path';

const FAL_KEY = process.env.FAL_KEY;
if (!FAL_KEY) { console.error('Missing FAL_KEY'); process.exit(1); }

const OUT = process.argv[2] || './images';
fs.mkdirSync(OUT, { recursive: true });

const BASE =
  'cinematic photograph, golden hour, Caribbean coast of southern Puerto Rico, ' +
  'lush green hills meeting turquoise sea, professional motorsport photography, ' +
  'shallow depth of field, no text, no watermark, no logos';

const images = [
  {
    name: 'hero',
    size: 'landscape_16_9',
    prompt: `Sweeping aerial view of a 1.5 mile seaside road racing circuit hugging the Caribbean coastline, asphalt ribbon with 12 curves through tropical greenery, ocean waves breaking beside the track, dramatic light. ${BASE}`,
  },
  {
    name: 'circuit',
    size: 'landscape_16_9',
    prompt: `Low trackside view down a racing circuit straightaway toward a rising corner, palm trees and the Caribbean sea behind the armco barrier, heat shimmer on fresh asphalt, red-and-white curbing. ${BASE}`,
  },
  {
    name: 'karting',
    size: 'landscape_16_9',
    prompt: `Racing karts mid-corner on a tight outdoor karting circuit, driver in full helmet and race suit leaning into the apex, motion blur on the background of tropical palms, vivid colors. ${BASE}`,
  },
  {
    name: 'events',
    size: 'landscape_16_9',
    prompt: `Grid of race cars lined up before the start of a race at a Caribbean seaside circuit, crews and flags, grandstand crowd, late afternoon sun flaring over the ocean. ${BASE}`,
  },
  {
    name: 'suites',
    size: 'landscape_16_9',
    prompt: `Luxurious private trackside garage suite, glass wall overlooking a racing circuit and the Caribbean sea, a classic sports car parked inside a warmly lit modern lounge with leather seating. ${BASE}`,
  },
  {
    name: 'sponsors',
    size: 'landscape_16_9',
    prompt: `Racing paddock at dusk at a Caribbean circuit, unbranded trackside banners and hospitality tents glowing, mechanics around a race car, ocean horizon in warm light. ${BASE}`,
  },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function submit(prompt, size) {
  const res = await fetch('https://queue.fal.run/fal-ai/flux-pro/v1.1', {
    method: 'POST',
    headers: { Authorization: `Key ${FAL_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt, image_size: size, safety_tolerance: '2' }),
  });
  if (!res.ok) throw new Error(`submit ${res.status}: ${await res.text()}`);
  return res.json();
}

async function poll(statusUrl, maxAttempts = 90) {
  for (let i = 0; i < maxAttempts; i++) {
    const res = await fetch(statusUrl, { headers: { Authorization: `Key ${FAL_KEY}` } });
    const data = await res.json();
    if (data.status === 'COMPLETED') {
      const resultRes = await fetch(statusUrl.replace('/status', ''), {
        headers: { Authorization: `Key ${FAL_KEY}` },
      });
      return resultRes.json();
    }
    if (data.status === 'FAILED') throw new Error(`failed: ${JSON.stringify(data)}`);
    await sleep(2000);
  }
  throw new Error('timeout');
}

async function main() {
  for (const img of images) {
    const dest = path.join(OUT, `${img.name}.jpg`);
    if (fs.existsSync(dest)) { console.log(`skip ${img.name}`); continue; }
    console.log(`generating ${img.name}...`);
    const job = await submit(img.prompt, img.size);
    const result = await poll(job.status_url);
    const url = result.images?.[0]?.url;
    if (!url) throw new Error(`no image url: ${JSON.stringify(result).slice(0, 400)}`);
    const buf = Buffer.from(await (await fetch(url)).arrayBuffer());
    fs.writeFileSync(dest, buf);
    console.log(`  saved ${dest} (${(buf.length / 1024).toFixed(0)} KB)`);
  }
  console.log('all done');
}

main().catch((e) => { console.error(e); process.exit(1); });
