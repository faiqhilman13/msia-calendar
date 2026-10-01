// Fetches a public iCalendar feed for Sehari Selembar's "subscribe by link" import.
// Browsers can't read most calendar hosts (Google, iCloud, Outlook) directly because of CORS.
// Only public http(s) hosts are allowed, redirects are re-checked, and responses must be iCal.
import { lookup } from 'node:dns/promises';
import net from 'node:net';

const MAX_BYTES = 6 * 1024 * 1024;
const TIMEOUT_MS = 12000;

function privateAddress(ip) {
  if (net.isIPv4(ip)) {
    const [a, b] = ip.split('.').map(Number);
    return a === 10 || a === 127 || a === 0 || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127) || a >= 224;
  }
  const v = ip.toLowerCase();
  return v === '::1' || v === '::' || v.startsWith('fc') || v.startsWith('fd') || v.startsWith('fe80') || v.startsWith('::ffff:') && privateAddress(v.slice(7));
}

async function assertPublic(url) {
  if (!['http:', 'https:'].includes(url.protocol)) throw new Error('Only http and https links are supported.');
  if (url.username || url.password) throw new Error('Links with credentials are not supported.');
  const host = url.hostname.replace(/^\[|\]$/g, '');
  if (/^(localhost|.*\.local|.*\.internal)$/i.test(host)) throw new Error('That host is not allowed.');
  const addrs = net.isIP(host) ? [{ address: host }] : await lookup(host, { all: true });
  if (!addrs.length || addrs.some(a => privateAddress(a.address))) throw new Error('That host is not allowed.');
}

const reply = (status, body, type = 'text/plain; charset=utf-8') =>
  new Response(body, { status, headers: { 'content-type': type, 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' } });

export default async (req) => {
  const raw = new URL(req.url).searchParams.get('url') || '';
  let target;
  try { target = new URL(raw.replace(/^webcals?:\/\//i, 'https://')); } catch { return reply(400, 'Invalid link.'); }
  try {
    let res;
    for (let hop = 0; hop < 4; hop++) {
      await assertPublic(target);
      res = await fetch(target, { redirect: 'manual', signal: AbortSignal.timeout(TIMEOUT_MS), headers: { accept: 'text/calendar, text/plain;q=0.8, */*;q=0.1', 'user-agent': 'SehariSelembar/1.0 (+calendar import)' } });
      if (res.status >= 300 && res.status < 400 && res.headers.get('location')) { target = new URL(res.headers.get('location'), target); continue; }
      break;
    }
    if (!res.ok) return reply(502, `The calendar host answered HTTP ${res.status}.`);
    const reader = res.body.getReader();
    const chunks = [];
    let size = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > MAX_BYTES) { reader.cancel(); return reply(413, 'That calendar is too large.'); }
      chunks.push(value);
    }
    const text = new TextDecoder().decode(Buffer.concat(chunks));
    if (!/BEGIN:VCALENDAR/i.test(text)) return reply(422, 'That link did not return an iCal calendar.');
    return reply(200, text, 'text/calendar; charset=utf-8');
  } catch (err) {
    return reply(400, err.name === 'TimeoutError' ? 'The calendar host took too long to answer.' : err.message || 'Could not load that link.');
  }
};

export const config = { path: '/api/ics' };
