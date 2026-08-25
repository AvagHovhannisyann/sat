/* Build step.
   Emits public/ — the app shell, pdf.js from node_modules, and the app icons
   rendered from a single small source. PNGs cannot live in git as text, so the
   source icon is stored base64 and decoded here. */
import { mkdir, writeFile, readFile, cp, rm } from 'node:fs/promises';
import sharp from 'sharp';

const OUT = 'public';
const PLATE = { r: 57, g: 116, b: 195, alpha: 1 };   // the logo's own blue

await rm(OUT, { recursive: true, force: true });
await mkdir(`${OUT}/icons`, { recursive: true });

const src = Buffer.from(await readFile('assets/icon.b64', 'utf8'), 'base64');

/* iOS masks the icon to a squircle and ignores transparency, so the artwork is
   scaled edge to edge over an opaque plate — no ring, no white corners.
   Android crops maskable icons to a circle, so that one gets a safe margin. */
async function icon(size, inset = 0) {
  const pad = Math.round(size * inset);
  const art = await sharp(src).resize(size - 2 * pad, size - 2 * pad).toBuffer();
  return sharp({ create: { width: size, height: size, channels: 4, background: PLATE } })
    .composite([{ input: art, top: pad, left: pad }])
    .png({ compressionLevel: 9 })
    .toBuffer();
}

for (const size of [180, 192, 512]) {
  await writeFile(`${OUT}/icons/icon-${size}.png`, await icon(size));
}
await writeFile(`${OUT}/icons/icon-512-maskable.png`, await icon(512, 0.16));

// Favicons keep their transparency so they sit well on light and dark chrome.
for (const size of [16, 32]) {
  await writeFile(`${OUT}/icons/favicon-${size}.png`,
    await sharp(src).resize(size, size).png().toBuffer());
}

for (const f of ['index.html', 'manifest.webmanifest', 'sw.js']) {
  await cp(f, `${OUT}/${f}`);
}

// pdf.js ships with the app so imports work offline and need no CDN.
await mkdir(`${OUT}/vendor`, { recursive: true });
for (const f of ['pdf.min.js', 'pdf.worker.min.js']) {
  await cp(`node_modules/pdfjs-dist/build/${f}`, `${OUT}/vendor/${f}`);
}

console.log(`built ${OUT}/ — app shell, 6 icons, pdf.js`);
