/* Sehari Selembar: calendar import.
   Reads iCalendar (.ics) from Google Calendar, Apple Calendar, Outlook and Notion Calendar,
   Google's export .zip, and Notion database CSV exports. Everything runs in the browser;
   subscription links are fetched directly or through the site's /api/ics proxy. */
(() => {
  'use strict';

  const pad2 = n => String(n).padStart(2, '0');
  const isoOf = d => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
  const hhmm = d => `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
  const DAY = 864e5;
  const MAX_PER_EVENT = 1500;

  /* ------------------------------------------------------------- iCalendar */
  // A few Windows zone names that Outlook writes instead of IANA ids.
  const WIN_ZONES = {
    'Singapore Standard Time': 'Asia/Singapore', 'Malay Peninsula Standard Time': 'Asia/Kuala_Lumpur',
    'China Standard Time': 'Asia/Shanghai', 'Tokyo Standard Time': 'Asia/Tokyo', 'India Standard Time': 'Asia/Kolkata',
    'SE Asia Standard Time': 'Asia/Bangkok', 'W. Australia Standard Time': 'Australia/Perth', 'AUS Eastern Standard Time': 'Australia/Sydney',
    'GMT Standard Time': 'Europe/London', 'W. Europe Standard Time': 'Europe/Berlin', 'Romance Standard Time': 'Europe/Paris',
    'Eastern Standard Time': 'America/New_York', 'Central Standard Time': 'America/Chicago', 'Mountain Standard Time': 'America/Denver',
    'Pacific Standard Time': 'America/Los_Angeles', 'UTC': 'UTC', 'Coordinated Universal Time': 'UTC', 'Arabian Standard Time': 'Asia/Dubai',
  };
  const zoneOk = tz => { try { new Intl.DateTimeFormat('en-US', { timeZone: tz }); return true; } catch { return false; } };
  // Offset (ms) of a time zone at a UTC instant.
  function zoneOffset(tz, utcMs) {
    const f = new Intl.DateTimeFormat('en-US', { timeZone: tz, hourCycle: 'h23', year: 'numeric', month: 'numeric', day: 'numeric', hour: 'numeric', minute: 'numeric', second: 'numeric' });
    const p = Object.fromEntries(f.formatToParts(new Date(utcMs)).map(x => [x.type, x.value]));
    return Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour % 24, +p.minute, +p.second) - utcMs;
  }
  // Wall-clock time in a zone -> Date.
  function zonedDate(y, mo, d, h, mi, s, tz) {
    let guess = Date.UTC(y, mo, d, h, mi, s);
    for (let i = 0; i < 2; i++) guess = Date.UTC(y, mo, d, h, mi, s) - zoneOffset(tz, guess);
    return new Date(guess);
  }

  function unfold(text) {
    return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').replace(/\n[ \t]/g, '').split('\n');
  }
  function parseLine(line) {
    // NAME;PARAM=VAL;PARAM="V:AL":value. A colon inside quotes does not end the name.
    let i = 0, quoted = false;
    for (; i < line.length; i++) {
      const c = line[i];
      if (c === '"') quoted = !quoted;
      else if (c === ':' && !quoted) break;
    }
    const head = line.slice(0, i), value = line.slice(i + 1);
    const parts = head.split(';');
    const params = {};
    parts.slice(1).forEach(p => { const eq = p.indexOf('='); if (eq > 0) params[p.slice(0, eq).toUpperCase()] = p.slice(eq + 1).replace(/^"|"$/g, ''); });
    return { name: parts[0].toUpperCase(), params, value };
  }
  const unescapeText = v => v.replace(/\\n/gi, '\n').replace(/\\([,;\\])/g, '$1').trim();

  // Returns { date: Date, allDay: bool } or null.
  function parseDate(value, params, calZone) {
    const v = value.trim();
    const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec(v);
    if (!m) return null;
    const [, Y, Mo, D, H, Mi, Sec, Z] = m;
    if (!H || params.VALUE === 'DATE') return { date: new Date(+Y, +Mo - 1, +D, 12), allDay: true };
    const args = [+Y, +Mo - 1, +D, +H, +Mi, +(Sec || 0)];
    if (Z) return { date: new Date(Date.UTC(...args)), allDay: false };
    let tz = params.TZID ? params.TZID.replace(/^\//, '') : calZone;
    if (tz && !zoneOk(tz)) tz = WIN_ZONES[tz] || (zoneOk(WIN_ZONES[tz] || '') ? WIN_ZONES[tz] : null);
    if (tz && zoneOk(tz)) return { date: zonedDate(...args, tz), allDay: false, tz };
    return { date: new Date(...args), allDay: false }; // floating time: device-local
  }
  function parseDuration(v) {
    const m = /^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec((v || '').trim());
    if (!m) return 0;
    const sign = m[1] === '-' ? -1 : 1;
    return sign * ((+m[2] || 0) * 7 * DAY + (+m[3] || 0) * DAY + (+m[4] || 0) * 36e5 + (+m[5] || 0) * 6e4 + (+m[6] || 0) * 1e3);
  }

  const WD = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 };
  function parseRRule(v) {
    const r = {};
    v.split(';').forEach(kv => { const [k, val] = kv.split('='); if (k && val) r[k.toUpperCase()] = val; });
    return r;
  }
  // Expand a recurring start date into occurrence Dates within [from, to].
  function expand(start, rule, from, to, calZone, tz) {
    const out = [];
    const freq = rule.FREQ, interval = Math.max(1, +rule.INTERVAL || 1);
    const count = rule.COUNT ? +rule.COUNT : Infinity;
    const until = rule.UNTIL ? (parseDate(rule.UNTIL, {}, calZone) || {}).date : null;
    const byday = rule.BYDAY ? rule.BYDAY.split(',').map(s => { const m = /^([+-]?\d+)?(MO|TU|WE|TH|FR|SA|SU)$/.exec(s.trim()); return m ? { n: m[1] ? +m[1] : 0, wd: WD[m[2]] } : null; }).filter(Boolean) : null;
    const bymd = rule.BYMONTHDAY ? rule.BYMONTHDAY.split(',').map(Number) : null;
    const bymonth = rule.BYMONTH ? rule.BYMONTH.split(',').map(n => +n - 1) : null;
    // Work in the event's wall clock so 9:00 stays 9:00 across DST changes.
    const wall = tz ? new Date(start.getTime() + zoneOffset(tz, start.getTime())) : null;
    const base = wall ? { y: wall.getUTCFullYear(), m: wall.getUTCMonth(), d: wall.getUTCDate(), h: wall.getUTCHours(), mi: wall.getUTCMinutes(), s: wall.getUTCSeconds() }
      : { y: start.getFullYear(), m: start.getMonth(), d: start.getDate(), h: start.getHours(), mi: start.getMinutes(), s: start.getSeconds() };
    const make = (y, m, d) => tz ? zonedDate(y, m, d, base.h, base.mi, base.s, tz) : new Date(y, m, d, base.h, base.mi, base.s);
    const dow = (y, m, d) => new Date(Date.UTC(y, m, d)).getUTCDay();
    const dim = (y, m) => new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
    let n = 0;
    const push = dt => {
      if (dt < start) return true;
      if (until && dt > until) return false;
      if (n >= count) return false;
      n++;
      if (dt >= from && dt <= to) out.push(dt);
      return out.length < MAX_PER_EVENT && dt <= to;
    };
    const nthWeekday = (y, m, wd, nth) => {
      const days = [];
      for (let d = 1, last = dim(y, m); d <= last; d++) if (dow(y, m, d) === wd) days.push(d);
      return nth > 0 ? days[nth - 1] : days[days.length + nth];
    };
    // Skip ahead to just before the window when there is no COUNT to honour.
    let step0 = 0;
    if (count === Infinity && from > start) {
      const per = { DAILY: 1, WEEKLY: 7, MONTHLY: 31, YEARLY: 366 }[freq] * interval * DAY;
      if (per) step0 = Math.max(0, Math.floor((from - start) / per) - 2);
    }
    for (let step = step0; step < step0 + 5000; step++) {
      let cands = [];
      if (freq === 'DAILY') {
        const t = new Date(Date.UTC(base.y, base.m, base.d + step * interval));
        cands = [[t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate()]];
        if (bymonth && !bymonth.includes(cands[0][1])) cands = [];
      } else if (freq === 'WEEKLY') {
        const weekStart = new Date(Date.UTC(base.y, base.m, base.d - ((dow(base.y, base.m, base.d) + 6) % 7) + step * 7 * interval));
        const wds = byday ? byday.map(b => b.wd) : [dow(base.y, base.m, base.d)];
        cands = wds.map(wd => { const t = new Date(weekStart.getTime() + ((wd + 6) % 7) * DAY); return [t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate()]; })
          .sort((a, b) => Date.UTC(...a) - Date.UTC(...b));
      } else if (freq === 'MONTHLY') {
        const t = new Date(Date.UTC(base.y, base.m + step * interval, 1));
        const y = t.getUTCFullYear(), m = t.getUTCMonth();
        if (byday) cands = byday.map(b => [y, m, b.n ? nthWeekday(y, m, b.wd, b.n) : null]).filter(c => c[2]);
        else cands = (bymd || [base.d]).map(d => [y, m, d < 0 ? dim(y, m) + d + 1 : d]).filter(c => c[2] >= 1 && c[2] <= dim(y, m));
        cands.sort((a, b) => a[2] - b[2]);
      } else if (freq === 'YEARLY') {
        const y = base.y + step * interval;
        const months = bymonth || [base.m];
        months.forEach(m => {
          if (byday) byday.forEach(b => { const d = b.n ? nthWeekday(y, m, b.wd, b.n) : null; if (d) cands.push([y, m, d]); });
          else (bymd || [base.d]).forEach(d => { if (d <= dim(y, m)) cands.push([y, m, d]); });
        });
      } else break;
      let keep = true;
      for (const c of cands) { if (!push(make(...c))) { keep = false; break; } }
      if (!keep) break;
    }
    return out;
  }

  /* Parse an .ics text into flat day items:
     { uid, date: 'YYYY-MM-DD', time: 'HH:MM' | '', title, place, allDay } */
  function parseICS(text, { from, to } = {}) {
    const lines = unfold(text);
    if (!lines.some(l => /^BEGIN:VCALENDAR/i.test(l))) throw new Error('This file is not an iCal (.ics) calendar.');
    from = from || new Date(Date.now() - 400 * DAY);
    to = to || new Date(Date.now() + 760 * DAY);
    let calName = '', calZone = '';
    const vevents = [];
    let cur = null, depth = 0;
    for (const raw of lines) {
      if (!raw) continue;
      const { name, params, value } = parseLine(raw);
      if (name === 'BEGIN') {
        if (value.toUpperCase() === 'VEVENT' && !cur) { cur = { ex: [] }; depth = 0; continue; }
        if (cur) depth++;
        continue;
      }
      if (name === 'END') {
        if (cur && depth > 0) { depth--; continue; }
        if (cur && value.toUpperCase() === 'VEVENT') { vevents.push(cur); cur = null; }
        continue;
      }
      if (!cur) {
        if (name === 'X-WR-CALNAME') calName = unescapeText(value);
        if (name === 'X-WR-TIMEZONE') calZone = value.trim();
        continue;
      }
      if (depth > 0) continue; // inside VALARM
      if (name === 'EXDATE') { value.split(',').forEach(v => { const d = parseDate(v, params, calZone); if (d) cur.ex.push(d); }); continue; }
      cur[name] = { params, value };
    }
    if (calZone && !zoneOk(calZone)) calZone = WIN_ZONES[calZone] || '';

    const overrides = new Map(); // uid -> Set of recurrence-id ms
    vevents.forEach(v => {
      if (v['RECURRENCE-ID'] && v.UID) {
        const r = parseDate(v['RECURRENCE-ID'].value, v['RECURRENCE-ID'].params, calZone);
        if (r) { if (!overrides.has(v.UID.value)) overrides.set(v.UID.value, new Set()); overrides.get(v.UID.value).add(r.allDay ? isoOf(r.date) : r.date.getTime()); }
      }
    });

    const items = [];
    vevents.forEach((v, idx) => {
      if (!v.DTSTART) return;
      if (v.STATUS && /CANCELLED/i.test(v.STATUS.value)) return;
      const s = parseDate(v.DTSTART.value, v.DTSTART.params, calZone);
      if (!s) return;
      const title = v.SUMMARY ? unescapeText(v.SUMMARY.value) : '(Untitled)';
      const place = v.LOCATION ? unescapeText(v.LOCATION.value).split('\n')[0] : '';
      const uid = v.UID ? v.UID.value : `ev${idx}`;
      let span = 0; // extra all-day days
      if (s.allDay) {
        const e = v.DTEND ? parseDate(v.DTEND.value, v.DTEND.params, calZone) : null;
        const days = e ? Math.round((Date.UTC(e.date.getFullYear(), e.date.getMonth(), e.date.getDate()) - Date.UTC(s.date.getFullYear(), s.date.getMonth(), s.date.getDate())) / DAY) : (v.DURATION ? Math.round(parseDuration(v.DURATION.value) / DAY) : 1);
        span = Math.min(60, Math.max(1, days)) - 1;
      }
      let starts;
      if (v.RRULE && !v['RECURRENCE-ID']) {
        starts = expand(s.date, parseRRule(v.RRULE.value), new Date(from.getTime() - span * DAY), to, calZone, s.tz);
        const ex = new Set(v.ex.map(e => (e.allDay ? isoOf(e.date) : e.date.getTime())));
        const ov = overrides.get(uid) || new Set();
        starts = starts.filter(dt => !ex.has(s.allDay ? isoOf(dt) : dt.getTime()) && !ex.has(isoOf(dt)) && !ov.has(s.allDay ? isoOf(dt) : dt.getTime()));
      } else {
        starts = [s.date];
      }
      starts.forEach(dt => {
        for (let k = 0; k <= span; k++) {
          const day = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate() + k, 12);
          if (day < new Date(from.getFullYear(), from.getMonth(), from.getDate()) || day > to) continue;
          items.push({ uid: `${uid}@${isoOf(day)}${s.allDay ? '' : '@' + hhmm(dt)}`, date: isoOf(day), time: s.allDay ? '' : hhmm(dt), title, place, allDay: s.allDay });
        }
      });
    });
    return { name: calName, items };
  }

  /* ------------------------------------------------------------- Notion CSV */
  function parseCSVRows(text) {
    const rows = [];
    let row = [], field = '', q = false;
    text = text.replace(/^﻿/, '');
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (q) {
        if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else q = false; }
        else field += c;
      } else if (c === '"') q = true;
      else if (c === ',') { row.push(field); field = ''; }
      else if (c === '\n' || c === '\r') {
        if (c === '\r' && text[i + 1] === '\n') i++;
        row.push(field); field = '';
        if (row.some(x => x.trim())) rows.push(row);
        row = [];
      } else field += c;
    }
    row.push(field);
    if (row.some(x => x.trim())) rows.push(row);
    return rows;
  }
  // Notion writes dates like "October 1, 2026 9:00 AM (GMT+8)" or "October 1, 2026 → October 3, 2026".
  function parseNotionDate(s) {
    s = (s || '').trim();
    if (!s) return null;
    const first = s.split('→')[0].trim();
    let offsetMin = null;
    const gm = /\(GMT([+-]\d{1,2})(?::?(\d{2}))?\)/i.exec(first) || /\bUTC([+-]\d{1,2})(?::?(\d{2}))?/i.exec(first);
    if (gm) offsetMin = (+gm[1]) * 60 + Math.sign(+gm[1] || 1) * (+gm[2] || 0);
    const clean = first.replace(/\((GMT|UTC)[^)]*\)/i, '').replace(/\s+/g, ' ').trim();
    let d = null, hasTime = /\d{1,2}:\d{2}/.test(clean);
    const isoM = /^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[ T](\d{1,2}):(\d{2}))?/.exec(clean);
    if (isoM) d = new Date(+isoM[1], +isoM[2] - 1, +isoM[3], +(isoM[4] || 12), +(isoM[5] || 0));
    else { const t = Date.parse(clean); if (!Number.isNaN(t)) d = new Date(t); }
    if (!d) {
      const dm = /^(\d{1,2})[/.](\d{1,2})[/.](\d{4})/.exec(clean); // 01/10/2026 (day first, Malaysian style)
      if (dm) d = new Date(+dm[3], +dm[2] - 1, +dm[1], 12);
    }
    if (!d) return null;
    if (hasTime && offsetMin != null) {
      const utc = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes()) - offsetMin * 6e4;
      d = new Date(utc);
    }
    let span = 0;
    const second = s.split('→')[1];
    if (second && !hasTime) { const e = parseNotionDate(second); if (e) span = Math.min(60, Math.max(0, Math.round((new Date(e.date + 'T12:00') - new Date(isoOf(d) + 'T12:00')) / DAY))); }
    return { date: isoOf(d), time: hasTime ? hhmm(d) : '', span };
  }
  function parseCSV(text) {
    const rows = parseCSVRows(text);
    if (rows.length < 2) throw new Error('The CSV file is empty.');
    const head = rows[0].map(h => h.trim());
    const find = re => head.findIndex(h => re.test(h));
    let ti = find(/^(name|title|nama|tajuk|event|acara|task|tugas)$/i);
    if (ti < 0) ti = 0;
    const di = find(/date|tarikh|when|due|start|mula|masa/i);
    if (di < 0) throw new Error('No date column found. Make sure the Notion database has a "Date" column.');
    const li = find(/location|place|tempat|lokasi|venue/i);
    const items = [];
    rows.slice(1).forEach((r, idx) => {
      const p = parseNotionDate(r[di]);
      if (!p) return;
      const title = (r[ti] || '').trim() || '(Untitled)';
      for (let k = 0; k <= p.span; k++) {
        const day = new Date(p.date + 'T12:00'); day.setDate(day.getDate() + k);
        items.push({ uid: `row${idx}@${isoOf(day)}`, date: isoOf(day), time: p.time, title, place: li >= 0 ? (r[li] || '').trim() : '', allDay: !p.time });
      }
    });
    return { name: '', items };
  }

  /* ------------------------------------------------- zip (Google's export) */
  async function inflateRaw(bytes) {
    if (typeof DecompressionStream === 'undefined') throw new Error("This browser can't open .zip files. Unzip it first, then choose the .ics file.");
    const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
    return new Uint8Array(await new Response(stream).arrayBuffer());
  }
  async function readZip(buf) {
    const u8 = new Uint8Array(buf), dv = new DataView(buf);
    let eocd = -1;
    for (let i = u8.length - 22; i >= Math.max(0, u8.length - 66000); i--) if (dv.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
    if (eocd < 0) throw new Error('The .zip file is damaged.');
    const entries = dv.getUint16(eocd + 10, true);
    let p = dv.getUint32(eocd + 16, true);
    const files = [];
    for (let e = 0; e < entries; e++) {
      if (dv.getUint32(p, true) !== 0x02014b50) break;
      const method = dv.getUint16(p + 10, true), csize = dv.getUint32(p + 20, true);
      const nlen = dv.getUint16(p + 28, true), xlen = dv.getUint16(p + 30, true), clen = dv.getUint16(p + 32, true);
      const local = dv.getUint32(p + 42, true);
      const name = new TextDecoder().decode(u8.subarray(p + 46, p + 46 + nlen));
      p += 46 + nlen + xlen + clen;
      if (!/\.(ics|ical|ifb|csv)$/i.test(name)) continue;
      const lnlen = dv.getUint16(local + 26, true), lxlen = dv.getUint16(local + 28, true);
      const data = u8.subarray(local + 30 + lnlen + lxlen, local + 30 + lnlen + lxlen + csize);
      const raw = method === 0 ? data : method === 8 ? await inflateRaw(data) : null;
      if (raw) files.push({ name, text: new TextDecoder().decode(raw) });
    }
    return files;
  }

  /* Read any supported File into calendars: [{ name, items }] */
  async function readFile(file) {
    const base = file.name.replace(/\.[^.]+$/, '');
    if (/\.zip$/i.test(file.name)) {
      const files = await readZip(await file.arrayBuffer());
      if (!files.length) throw new Error('There are no .ics files in this .zip.');
      return files.map(f => {
        const cal = /\.csv$/i.test(f.name) ? parseCSV(f.text) : parseICS(f.text);
        return { name: cal.name || f.name.replace(/^.*\//, '').replace(/\.[^.]+$/, '').replace(/_[a-z0-9.]+@.*$/i, ''), items: cal.items };
      });
    }
    const text = await file.text();
    const cal = /\.csv$/i.test(file.name) || (!/BEGIN:VCALENDAR/i.test(text) && text.includes(',')) ? parseCSV(text) : parseICS(text);
    return [{ name: cal.name || base, items: cal.items }];
  }

  /* Fetch a subscription link (webcal/https). Tries direct first, then the /api/ics proxy. */
  async function fetchFeed(url) {
    let u = url.trim().replace(/^webcals?:\/\//i, 'https://');
    if (!/^https?:\/\//i.test(u)) throw new Error('The link must start with https:// or webcal://');
    const tryText = async res => { if (!res.ok) throw new Error(`HTTP ${res.status}`); const t = await res.text(); if (!/BEGIN:VCALENDAR/i.test(t)) throw new Error("This link didn't return an iCal calendar."); return t; };
    try { return await tryText(await fetch(u, { cache: 'no-store' })); } catch (direct) {
      try { return await tryText(await fetch('/api/ics?url=' + encodeURIComponent(u), { cache: 'no-store' })); } catch (proxied) {
        throw new Error(/HTTP 4|iCal/.test(proxied.message) ? proxied.message : "Couldn't load the link. Check it, or download the .ics file and import that instead.");
      }
    }
  }

  window.SehariImport = { parseICS, parseCSV, readFile, fetchFeed, readZip };
})();
