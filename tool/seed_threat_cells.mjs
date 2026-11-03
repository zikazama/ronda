// Mengisi koleksi Firestore `threat_cells` dengan titik panas contoh (Jakarta)
// agar peta tidak kosong saat demo/beta. Data ini SINTETIS, bukan laporan nyata.
//
//   cd tool && npm install
//   node seed_threat_cells.mjs --dry-run   # lihat apa yang akan ditulis
//   node seed_threat_cells.mjs             # tulis ke Firestore
//   node seed_threat_cells.mjs --remove    # hapus seed (yang belum tersentuh laporan nyata)
//
// Memakai token gcloud akun fauzi.fadman@gmail.com (akses admin; melewati
// firestore.rules). Setiap dokumen seed diberi lastSuspectKey = "seed-demo".
// Skema HARUS persis 5 field ini agar laporan nyata berikutnya tetap lolos rules.
import { execFileSync } from 'node:child_process';
import { latLngToCell, gridDisk } from 'h3-js';

const PROJECT = 'ronda-kch-2026';
const ACCOUNT = 'fauzi.fadman@gmail.com';
const RES = 8; // sama dengan GeoIndex di aplikasi
const SEED_KEY = 'seed-demo';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/threat_cells`;

// Sama dengan MockHeatmapData._seeds di aplikasi.
const HOTSPOTS = [
  [-6.1860, 106.8110, 18, 'APK_SCAM'], // Tanah Abang
  [-6.1754, 106.8272, 14, 'FINANCIAL_PHISHING'], // Monas
  [-6.2297, 106.8300, 16, 'IMPERSONATION'], // Kuningan
  [-6.1352, 106.8133, 11, 'APK_SCAM'], // Kota Tua
  [-6.2441, 106.7993, 9, 'FINANCIAL_PHISHING'], // Blok M
  [-6.2420, 106.8680, 12, 'APK_SCAM'], // Cawang
];

function plan(now = Date.now()) {
  const byDoc = new Map();
  for (const [lat, lng, peak, kind] of HOTSPOTS) {
    const origin = latLngToCell(lat, lng, RES);
    const ring = gridDisk(origin, 1);
    ring.forEach((cell, i) => {
      const reports =
        cell === origin
          ? peak
          : Math.min(peak, Math.max(1, Math.round(peak * (0.25 + 0.1 * (i % 4)))));
      const id = `${cell}_${kind}`;
      const prev = byDoc.get(id);
      if (prev && prev.reports >= reports) return;
      byDoc.set(id, {
        id, cell, kind, reports,
        lastReportAt: new Date(now - (7 + i * 23) * 60_000).toISOString(),
      });
    });
  }
  return [...byDoc.values()];
}

const token = () =>
  execFileSync('gcloud', ['auth', 'print-access-token', `--account=${ACCOUNT}`], {
    encoding: 'utf8', shell: process.platform === 'win32',
  }).trim();

async function call(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token()}`,
      'x-goog-user-project': PROJECT,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status} ${await res.text()}`);
  return res.status === 204 ? {} : res.json();
}

const fields = (d) => ({
  fields: {
    cell: { stringValue: d.cell },
    kind: { stringValue: d.kind },
    reports: { integerValue: String(d.reports) },
    lastReportAt: { timestampValue: d.lastReportAt },
    lastSuspectKey: { stringValue: SEED_KEY },
  },
});

const isSeed = (doc) => doc?.fields?.lastSuspectKey?.stringValue === SEED_KEY;

const args = new Set(process.argv.slice(2));
const docs = plan();
console.log(`${docs.length} dokumen threat_cells (${args.has('--remove') ? 'hapus' : 'tulis'})`);

let done = 0, skipped = 0;
for (const d of docs) {
  const url = `${BASE}/${d.id}`;
  if (args.has('--dry-run')) { console.log(d.id, d.reports); continue; }
  const existing = await call('GET', url);
  if (args.has('--remove')) {
    if (existing && isSeed(existing)) { await call('DELETE', url); done++; } else skipped++;
  } else if (existing && !isSeed(existing)) {
    skipped++; // sudah berisi laporan nyata; jangan ditimpa
  } else {
    await call('PATCH', url, fields(d)); done++;
  }
}
if (!args.has('--dry-run')) console.log(`selesai: ${done} diproses, ${skipped} dilewati`);
