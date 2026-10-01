/* Sehari Selembar: a Malaysian calendar with a fact and a peribahasa for every day, in nine nostalgic styles. */
(() => {
  'use strict';

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
  const mod = (n, m) => ((n % m) + m) % m;
  const pad2 = n => String(n).padStart(2, '0');
  const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const wide = matchMedia('(min-width: 960px)');

  /* ------------------------------------------------------------------ names */
  const MS_MONTH = ['Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun', 'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember'];
  const EN_MONTH = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const TA_MONTH = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
  const MS_DAY = ['Ahad', 'Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu'];
  const EN_DAY = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const TA_DAY = ['ஞாயிறு', 'திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி'];
  const ZH_NUM = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  const ZH_DAY = ['日', '一', '二', '三', '四', '五', '六'];
  const ZH_LUNAR_MONTH = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'];
  const HIJRI_MONTH = ['Muharam', 'Safar', 'Rabiulawal', 'Rabiulakhir', 'Jamadilawal', 'Jamadilakhir', 'Rejab', 'Syaaban', 'Ramadan', 'Syawal', 'Zulkaedah', 'Zulhijah'];
  const CAT_EN = { Sejarah: 'History', Alam: 'Nature', Makanan: 'Food', Budaya: 'Culture', Geografi: 'Geography', Bahasa: 'Language', Sukan: 'Sport', Tempat: 'Places' };
  const JENIS_EN = { Perumpamaan: 'Simile', 'Simpulan Bahasa': 'Idiom', Bidalan: 'Adage', Pepatah: 'Proverb', Perbilangan: 'Adat saying' };
  const zhMonth = m => (m <= 10 ? ZH_NUM[m] : '十' + ZH_NUM[m - 10]) + '月';

  /* ------------------------------------------------------------- date maths */
  const iso = (y, m, d) => `${y}-${pad2(m + 1)}-${pad2(d)}`;
  const parseIso = s => { const [y, m, d] = s.split('-').map(Number); return { y, m: m - 1, d }; };
  const daysIn = (y, m) => new Date(y, m + 1, 0).getDate();
  const weekday = (y, m, d) => new Date(y, m, d, 12).getDay();
  const dayNum = (y, m, d) => Math.round(Date.UTC(y, m, d) / 864e5);
  const addDays = (p, n) => { const t = new Date(p.y, p.m, p.d + n, 12); return { y: t.getFullYear(), m: t.getMonth(), d: t.getDate() }; };
  const shiftMonth = (y, m, n) => { const t = new Date(y, m + n, 1, 12); return { y: t.getFullYear(), m: t.getMonth() }; };
  const today = () => { const t = new Date(); return { y: t.getFullYear(), m: t.getMonth(), d: t.getDate() }; };
  const same = (a, b) => a.y === b.y && a.m === b.m && a.d === b.d;
  const cmpDate = (a, b) => dayNum(a.y, a.m, a.d) - dayNum(b.y, b.m, b.d);

  /* Chinese lunar date via Intl (falls back to nothing on engines without it) */
  const lunarFmt = (() => {
    try {
      const f = new Intl.DateTimeFormat('en-u-ca-chinese', { year: 'numeric', month: 'numeric', day: 'numeric' });
      return f.resolvedOptions().calendar === 'chinese' ? f : null;
    } catch { return null; }
  })();
  const lunarYearFmt = (() => {
    try { return new Intl.DateTimeFormat('zh-u-ca-chinese', { year: 'numeric' }); } catch { return null; }
  })();
  function lunar(y, m, d) {
    if (!lunarFmt) return null;
    const parts = lunarFmt.formatToParts(new Date(y, m, d, 12));
    const mon = (parts.find(p => p.type === 'month') || {}).value || '';
    const day = parseInt((parts.find(p => p.type === 'day') || {}).value, 10);
    const month = parseInt(mon, 10);
    if (!month || !day) return null;
    return { month, day, leap: /bis/i.test(mon) };
  }
  const lunarDayZh = d => d === 10 ? '初十' : d < 10 ? '初' + ZH_NUM[d] : d < 20 ? '十' + ZH_NUM[d - 10] : d === 20 ? '二十' : d < 30 ? '廿' + ZH_NUM[d - 20] : '三十';
  const lunarMonthZh = l => (l.leap ? '闰' : '') + ZH_LUNAR_MONTH[l.month - 1] + '月';
  function lunarYearName(y, m, d) {
    if (!lunarYearFmt) return '';
    const p = lunarYearFmt.formatToParts(new Date(y, m, d, 12)).find(x => x.type === 'yearName');
    return p ? p.value + '年' : '';
  }

  /* Hijri date via Intl (Umm al-Qura); Malaysia's own sighting can differ by a day */
  const hijriFmt = (() => {
    for (const cal of ['islamic-umalqura', 'islamic', 'islamic-civil']) {
      try {
        const f = new Intl.DateTimeFormat('en-u-ca-' + cal, { year: 'numeric', month: 'numeric', day: 'numeric' });
        if (f.resolvedOptions().calendar === cal) return f;
      } catch { /* try the next one */ }
    }
    return null;
  })();
  function hijriUQ(y, m, d) {
    if (!hijriFmt) return null;
    const parts = hijriFmt.formatToParts(new Date(y, m, d, 12));
    const get = t => parseInt((parts.find(p => p.type === t) || {}).value, 10);
    const r = { day: get('day'), month: get('month'), year: get('year') };
    return r.day && r.month ? r : null;
  }

  /* Malaysia starts Hijri months by its own moon sighting, often a day off Umm al-Qura.
     The gazetted Islamic holidays pin down when Malaysia's month began, so each one
     becomes a correction for its whole month. */
  const HIJRI_ANCHORS = [
    [/^Awal Muharam$/, 1, 1], [/^Maulidur Rasul$/, 3, 12], [/^Nuzul Al-Quran$/, 9, 17],
    [/^Hari Raya Aidilfitri$/, 10, 1], [/^Hari Raya Aidiladha$/, 12, 10],
  ];
  const hijriFixes = [];
  Object.entries(window.KALENDAR_HOLIDAYS || {}).forEach(([k, h]) => {
    String(h.ms).split(' / ').forEach(name => {
      const a = HIJRI_ANCHORS.find(([re]) => re.test(name.trim()));
      if (!a) return;
      const { y, m, d } = parseIso(k);
      for (const delta of [0, 1, -1, 2, -2]) {
        const t = new Date(y, m, d - delta, 12);
        const u = hijriUQ(t.getFullYear(), t.getMonth(), t.getDate());
        if (u && u.month === a[1] && u.day === a[2]) {
          if (delta) hijriFixes.push({ year: u.year, month: u.month, delta, at: dayNum(y, m, d) });
          return;
        }
      }
    });
  });
  function hijri(y, m, d) {
    const uq = hijriUQ(y, m, d);
    if (!uq || !hijriFixes.length) return uq;
    const n = dayNum(y, m, d);
    const near = hijriFixes.filter(f => Math.abs(n - f.at) < 45);
    for (const f of near) {
      const t = new Date(y, m, d - f.delta, 12);
      const u = hijriUQ(t.getFullYear(), t.getMonth(), t.getDate());
      if (u && u.year === f.year && u.month === f.month) return u;
    }
    // the extra day before a month that Malaysia started late is the 30th of the month before
    const late = near.find(f => f.delta > 0 && uq.year === f.year && uq.month === f.month);
    if (late) {
      const t = new Date(y, m, d - late.delta, 12);
      const u = hijriUQ(t.getFullYear(), t.getMonth(), t.getDate());
      if (u) return { year: u.year, month: u.month, day: u.day + late.delta };
    }
    return uq;
  }

  /* ---------------------------------------------------------------- holidays */
  const HOLIDAYS = window.KALENDAR_HOLIDAYS || {};
  const holidayYears = {};
  function holidaysFor(y) {
    if (holidayYears[y]) return holidayYears[y];
    const out = {};
    const prefix = y + '-';
    const keys = Object.keys(HOLIDAYS).filter(k => k.startsWith(prefix));
    if (keys.length) {
      keys.forEach(k => { out[k] = HOLIDAYS[k]; });
    } else {
      // Outside the gazetted table: fixed dates plus lunar/Hijri estimates, all flagged.
      const add = (k, ms, en, scope = 'national', approx = true) => {
        out[k] = out[k]
          ? { ms: out[k].ms + ' / ' + ms, en: out[k].en + ' / ' + en, scope: out[k].scope, approx: out[k].approx || approx }
          : { ms, en, scope, approx };
      };
      add(`${y}-01-01`, 'Tahun Baru', "New Year's Day", 'some', false);
      add(`${y}-05-01`, 'Hari Pekerja', 'Labour Day', 'national', false);
      add(`${y}-08-31`, 'Hari Kebangsaan', 'National Day', 'national', false);
      add(`${y}-09-16`, 'Hari Malaysia', 'Malaysia Day', 'national', false);
      add(`${y}-12-25`, 'Hari Krismas', 'Christmas Day', 'national', false);
      for (let d = 1; d <= 7; d++) if (weekday(y, 5, d) === 1) { add(iso(y, 5, d), 'Hari Keputeraan YDP Agong', "Agong's Birthday"); break; }
      for (let n = 0, p = { y, m: 0, d: 1 }; n < 366 && p.y === y; n++, p = addDays(p, 1)) {
        const k = iso(p.y, p.m, p.d);
        const l = lunar(p.y, p.m, p.d);
        if (l && !l.leap) {
          if (l.month === 1 && l.day === 1) add(k, 'Tahun Baru Cina', 'Chinese New Year');
          if (l.month === 1 && l.day === 2) add(k, 'Tahun Baru Cina (Hari Kedua)', 'Chinese New Year (Day 2)');
          if (l.month === 4 && l.day === 15) add(k, 'Hari Wesak', 'Wesak Day');
        }
        const h = hijri(p.y, p.m, p.d);
        if (h) {
          if (h.month === 1 && h.day === 1) add(k, 'Awal Muharam', 'Awal Muharram');
          if (h.month === 3 && h.day === 12) add(k, 'Maulidur Rasul', "Prophet Muhammad's Birthday");
          if (h.month === 9 && h.day === 17) add(k, 'Nuzul Al-Quran', 'Nuzul Al-Quran', 'some');
          if (h.month === 10 && h.day === 1) add(k, 'Hari Raya Aidilfitri', 'Hari Raya Aidilfitri');
          if (h.month === 10 && h.day === 2) add(k, 'Hari Raya Aidilfitri (Hari Kedua)', 'Hari Raya Aidilfitri (Day 2)');
          if (h.month === 12 && h.day === 10) add(k, 'Hari Raya Aidiladha', 'Hari Raya Haji');
        }
      }
    }
    return (holidayYears[y] = out);
  }
  const holiday = (y, m, d) => holidaysFor(y)[iso(y, m, d)] || null;
  /* ------------------------------------------------------- daily content */
  const FACTS = Array.isArray(window.KALENDAR_FACTS) && window.KALENDAR_FACTS.length
    ? window.KALENDAR_FACTS
    : [{ cat: 'Bahasa', t: 'The word "kalendar" came into Malay from Dutch and English; the older Malay word for an almanac is "takwim", from Arabic.' }];
  const PERI = Array.isArray(window.KALENDAR_PERIBAHASA) && window.KALENDAR_PERIBAHASA.length
    ? window.KALENDAR_PERIBAHASA
    : [{ p: 'Sehari selembar benang, lama-lama menjadi kain', jenis: 'Pepatah', maksud: 'Usaha yang sedikit demi sedikit, lama-kelamaan akan berhasil.', en: 'A thread a day, and in time it becomes cloth: small, steady effort adds up to something whole.', contoh: 'Sehari selembar benang, lama-lama menjadi kain; Aminah menabung seringgit setiap hari.' }];

  function mulberry32(a) {
    return () => {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function shuffled(n, seed) {
    const r = mulberry32(seed), a = Array.from({ length: n }, (_, i) => i);
    for (let i = n - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
  }
  const pinnedFact = {};
  const factPool = [];
  FACTS.forEach((f, i) => { if (f.on && pinnedFact[f.on] == null) pinnedFact[f.on] = i; else factPool.push(i); });
  if (!factPool.length) factPool.push(0);
  const factOrder = shuffled(factPool.length, 31081957);
  const periOrder = shuffled(PERI.length, 16091963);
  const rerolls = { fact: {}, peri: {} };

  function factFor(p) {
    const k = iso(p.y, p.m, p.d), shift = rerolls.fact[k] || 0;
    const pin = pinnedFact[pad2(p.m + 1) + '-' + pad2(p.d)];
    if (pin != null && !shift) return FACTS[pin];
    return FACTS[factPool[factOrder[mod(dayNum(p.y, p.m, p.d) + shift * 89, factPool.length)]]];
  }
  function periFor(p) {
    const shift = rerolls.peri[iso(p.y, p.m, p.d)] || 0;
    return PERI[periOrder[mod(dayNum(p.y, p.m, p.d) + shift * 97, PERI.length)]];
  }

  /* ------------------------------------------------------------ storage */
  const store = {
    get(k, fallback) { try { const v = localStorage.getItem('sehari:' + k); return v == null ? fallback : JSON.parse(v); } catch { return fallback; } },
    set(k, v) { try { localStorage.setItem('sehari:' + k, JSON.stringify(v)); } catch { /* private mode: fine */ } },
  };
  const notes = store.get('notes', {}) || {};

  /* ----------------------------------------------------------------- sound */
  const Sound = (() => {
    let ctx = null, noise = null, on = store.get('sound', true) !== false;
    function ac() {
      if (!on) return null;
      if (!ctx) { const C = window.AudioContext || window.webkitAudioContext; if (!C) return null; ctx = new C(); }
      if (ctx.state === 'suspended') ctx.resume();
      return ctx;
    }
    function noiseBuf(c) {
      if (noise) return noise;
      const len = Math.floor(c.sampleRate * 1.5), b = c.createBuffer(1, len, c.sampleRate), d = b.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      return (noise = b);
    }
    function burst(c, t0, dur, { type = 'bandpass', f0 = 1800, f1 = 3200, q = 0.8, gain = 0.12 } = {}) {
      const src = c.createBufferSource(); src.buffer = noiseBuf(c);
      const flt = c.createBiquadFilter(); flt.type = type; flt.Q.value = q;
      flt.frequency.setValueAtTime(f0, t0); flt.frequency.exponentialRampToValueAtTime(f1, t0 + dur);
      const g = c.createGain();
      g.gain.setValueAtTime(0.0001, t0);
      g.gain.exponentialRampToValueAtTime(gain, t0 + Math.min(0.03, dur * 0.25));
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
      src.connect(flt).connect(g).connect(c.destination);
      src.start(t0, Math.random() * 0.6, dur + 0.05);
    }
    return {
      get on() { return on; },
      toggle() { on = !on; store.set('sound', on); return on; },
      rustle(len = 0.6) {
        const c = ac(); if (!c) return;
        const t = c.currentTime;
        burst(c, t, len, { f0: 700, f1: 2400, q: 0.6, gain: 0.08 });
        for (let i = 0; i < 6; i++) burst(c, t + Math.random() * len * 0.8, 0.04 + Math.random() * 0.06, { type: 'highpass', f0: 2600, f1: 4200, q: 0.4, gain: 0.04 });
      },
      rip() {
        const c = ac(); if (!c) return;
        const t = c.currentTime;
        for (let i = 0; i < 18; i++) {
          burst(c, t + 0.1 + i * 0.02 + Math.random() * 0.012, 0.025 + Math.random() * 0.03,
            { f0: 1300 + Math.random() * 1500, f1: 2800 + Math.random() * 1600, q: 1.3, gain: 0.06 + Math.random() * 0.06 });
        }
        burst(c, t + 0.45, 0.5, { f0: 800, f1: 2000, q: 0.6, gain: 0.04 });
      },
      chirp() {
        const c = ac(); if (!c) return;
        const t = c.currentTime;
        for (let i = 0; i < 7; i++) {
          const o = c.createOscillator(), g = c.createGain(), tt = t + i * 0.105;
          o.type = 'square';
          o.frequency.setValueAtTime(3200 - i * 50, tt);
          o.frequency.exponentialRampToValueAtTime(2100, tt + 0.035);
          g.gain.setValueAtTime(0.0001, tt);
          g.gain.exponentialRampToValueAtTime(0.035, tt + 0.004);
          g.gain.exponentialRampToValueAtTime(0.0001, tt + 0.045);
          o.connect(g).connect(c.destination);
          o.start(tt); o.stop(tt + 0.06);
        }
      },
    };
  })();

  const ICONS = {
    Sejarah: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 3c2.2 2.4-1.8 4.2 0 6.6s-1.8 4.2 0 6.6-1.8 3.6 0 5.4"/><path d="M10 22h12"/><path d="M14.5 22v3.5c0 1.5 3 1.5 3 0V22"/><path d="M14 28.5c1.4 1 2.6 1 4 0"/></svg>',
    Alam: '<svg viewBox="0 0 32 32"><g fill="currentColor">' + [0, 72, 144, 216, 288].map(r => `<ellipse cx="16" cy="9" rx="5.2" ry="7" transform="rotate(${r} 16 16)"/>`).join('') + '</g><circle cx="16" cy="16" r="3" fill="#fdebd2"/><path d="M16 16 L23 6" stroke="#fdebd2" stroke-width="1.6" stroke-linecap="round"/><circle cx="23.5" cy="5.5" r="1.6" fill="#f2c94c"/></svg>',
    Makanan: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M16 8 L26 18 L16 28 L6 18Z" fill="currentColor" fill-opacity=".18"/><path d="M11 13l10 10M13.5 10.5l10 10M8.5 15.5l10 10M21 13L11 23M18.5 10.5l-10 10M23.5 15.5l-10 10"/><path d="M16 8c-1-3 0-5 2-6M16 8c2-2 4-2 6-1" stroke-linecap="round"/></svg>',
    Budaya: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M16 3l4.5 6.5c3.5.6 7 2.3 9 5.5-3.6-.9-6.8-.6-9 .8L16 22l-4.5-6.2c-2.2-1.4-5.4-1.7-9-.8 2-3.2 5.5-4.9 9-5.5Z" fill="currentColor" fill-opacity=".18"/><path d="M9 25c2.5 3 11.5 3 14 0-2.5 1.2-11.5 1.2-14 0Z" fill="currentColor"/><path d="M16 22v4"/></svg>',
    Geografi: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M2 27 11 11l4 6 5-10 10 20Z" fill="currentColor" fill-opacity=".18"/><path d="M17.5 12l2.5-5 2.6 5.3-2 1.2-1.2-1.4z" fill="currentColor"/><path d="M2 27h28"/></svg>',
    Bahasa: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M3 8c4.5-1.8 9-1.5 13 1.5 4-3 8.5-3.3 13-1.5v17c-4.5-1.8-9-1.5-13 1.5-4-3-8.5-3.3-13-1.5Z" fill="currentColor" fill-opacity=".12"/><path d="M16 9.5V26"/><path d="M7 13c2-.6 4-.5 6 .4M7 17c2-.6 4-.5 6 .4M19 13.4c2-.9 4-1 6-.4M19 17.4c2-.9 4-1 6-.4" stroke-linecap="round"/></svg>',
    Sukan: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M11 21h10l4-17H7Z" fill="currentColor" fill-opacity=".12"/><path d="M13 21 12 4M19 21l1-17M16 21V4M8.5 10h15M9.8 15.5h12.4"/><path d="M11 21h10v2a5 5 0 0 1-10 0Z" fill="currentColor"/></svg>',
    Tempat: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M3 14 16 5l13 9" fill="currentColor" fill-opacity=".18"/><path d="M6 13v9h20v-9"/><path d="M9 22v6M23 22v6M14 22v6h4v-6"/><path d="M9.5 15.5h4v3.5h-4zM18.5 15.5h4v3.5h-4z"/></svg>',
  };
  const REDRAW_ICON = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M13 8a5 5 0 1 1-1.6-3.7M13.2 1.8v3.6H9.6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const NOW = today();

  /* ------------------------------------------------- page curl (the flip)
     The page is cut into horizontal strips, each nested inside the one above
     and hinged on its top edge. Rotating every strip a little more than its
     parent bends the paper; letting the bottom strips lead makes it curl up
     from the bottom edge, the way you lift a wall-calendar page. */
  function buildFlipper(html, H) {
    const N = H > 520 ? 16 : 12;
    const h = H / N;
    const root = document.createElement('div');
    root.className = 'flipper';
    root.setAttribute('aria-hidden', 'true');
    root.inert = true;
    const strips = [];
    let parent = root;
    for (let i = 0; i < N; i++) {
      const el = document.createElement('div');
      el.className = 'strip';
      el.style.height = h + 'px';
      el.style.top = i === 0 ? '0' : '100%';
      const front = document.createElement('div');
      front.className = 'face front';
      const inner = document.createElement('div');
      inner.className = 'face-inner';
      inner.style.transform = `translateY(${-i * h}px)`;
      inner.innerHTML = html;
      const shade = document.createElement('div');
      shade.className = 'shade';
      front.append(inner, shade);
      const back = document.createElement('div');
      back.className = 'face back';
      const bshade = document.createElement('div');
      bshade.className = 'shade';
      back.append(bshade);
      el.append(front, back);
      parent.appendChild(el);
      strips.push({ el, front, back, shade, bshade });
      parent = el;
    }
    return { root, strips };
  }
  const easeInOut = u => 0.5 - Math.cos(Math.PI * u) / 2;
  function setCurl(s, t) {
    s.t = t;
    const strips = s.f.strips, N = strips.length, K = 0.7, MAX = 172;
    const A = new Array(N);
    for (let i = 0; i < N; i++) A[i] = MAX * easeInOut(clamp(t * (1 + K) - (1 - i / (N - 1)) * K, 0, 1));
    const rad = a => a * Math.PI / 180;
    const fs = A.map(a => 0.5 * Math.sin(rad(Math.min(a, 90))));
    const bs = A.map(a => (a > 90 ? 0.04 + 0.16 * (1 - Math.sin(rad(a))) : 0.2));
    const fade = t > 0.7 ? clamp(1 - (t - 0.7) / 0.26, 0, 1) : 1;
    for (let i = 0; i < N; i++) {
      const st = strips[i];
      st.el.style.transform = `rotateX(${(A[i] - (i ? A[i - 1] : 0)).toFixed(3)}deg)`;
      const ft = (fs[i] + fs[Math.max(0, i - 1)]) / 2, fb = (fs[i] + fs[Math.min(N - 1, i + 1)]) / 2;
      st.shade.style.background = `linear-gradient(rgba(40,25,0,${ft.toFixed(3)}),rgba(40,25,0,${fb.toFixed(3)}))`;
      const bt = (bs[i] + bs[Math.max(0, i - 1)]) / 2, bb = (bs[i] + bs[Math.min(N - 1, i + 1)]) / 2;
      st.bshade.style.background = `linear-gradient(rgba(40,25,0,${bb.toFixed(3)}),rgba(40,25,0,${bt.toFixed(3)}))`;
      st.front.style.opacity = st.back.style.opacity = fade;
    }
    flipShade.style.opacity = t > 0 && t < 1 ? (0.5 * Math.pow(1 - t, 1.4)).toFixed(3) : 0;
  }
  function tween(from, to, ms, fn, ease = easeInOut) {
    return new Promise(resolve => {
      const t0 = performance.now();
      const step = now => {
        const u = clamp((now - t0) / ms, 0, 1);
        fn(from + (to - from) * ease(u));
        if (u < 1) requestAnimationFrame(step); else resolve();
      };
      requestAnimationFrame(step);
    });
  }
  /* ===================================================================
     STYLES: the nine designs, ported 1:1 from the msia-calendar studies
     (markup below mirrors its renderScreen(); CSS lives in design.css).
     =================================================================== */
  const STYLES = [
    { id: 'tearoff', no: 1, cls: 'tearoff', name: 'Tear-off', start: 'month', color: '#b42b2b', desc: 'One day, red ink. A sheet you tear off tomorrow morning.' },
    { id: 'kuda', no: 2, cls: 'horse', name: 'Kalendar Kuda', start: 'month', color: '#c4312b', desc: 'A horse, red rules, blue dates. The classic wall calendar.' },
    { id: 'kopitiam', no: 3, cls: 'ledger', name: 'Kopitiam Ledger', start: 'month', color: '#24553c', desc: "A week of plans between the lines of a coffee shop's account book." },
    { id: 'runcit', no: 4, cls: 'runcit', name: 'Kedai Runcit', start: 'month', color: '#c92d31', desc: 'Butter-yellow paper and the calendar from the corner shop.' },
    { id: 'batik', no: 5, cls: 'batik', name: 'Batik Margin', start: 'month', color: '#17364d', desc: 'A roomy month with indigo batik down the side.' },
    { id: 'postcard', no: 6, cls: 'postcard', name: 'Postcard Month', start: 'month', color: '#dd8875', desc: 'A street of shophouses above the month. A little postcard on the wall.' },
    { id: 'stamp', no: 7, cls: 'stamp', name: 'Rubber Stamp', start: 'day', color: '#943340', desc: 'A daily form for appointments and notes, stamped in red.' },
    { id: 'riso', no: 8, cls: 'riso', name: 'Riso Pop', start: 'month', color: '#e94a47', desc: 'Coral red and cobalt blue, a big month and a city bus.' },
    { id: 'midnight', no: 9, cls: 'midnight', name: 'Midnight Almanac', start: 'month', color: '#25251f', desc: 'Cream dates and copper rules on dark ink paper.' },
  ];
  const DAYS = EN_DAY.map(d => d.toUpperCase());
  const SHORT_DAYS = DAYS.map(d => d.slice(0, 3));
  const DAY_INITIALS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const MONTHS = EN_MONTH.map(m => m.toUpperCase());
  const dateFromISO = v => { const [y, m, d] = v.split('-').map(Number); return new Date(y, m - 1, d, 12); };
  const isoFromDate = d => iso(d.getFullYear(), d.getMonth(), d.getDate());
  const monthName = d => MONTHS[d.getMonth()];
  const fullLabel = d => `${DAYS[d.getDay()]}, ${d.getDate()} ${monthName(d)} ${d.getFullYear()}`;
  function translated(date, locale, part) {
    if (locale.startsWith('ta')) return part === 'month' ? TA_MONTH[date.getMonth()] : TA_DAY[date.getDay()];
    try { return new Intl.DateTimeFormat(locale, { [part]: 'long' }).format(date); } catch { return part === 'month' ? EN_MONTH[date.getMonth()] : EN_DAY[date.getDay()]; }
  }
  const announce = t => { const el = $('#announcement'); if (el) el.textContent = t; };
  const TODAY = iso(NOW.y, NOW.m, NOW.d);

  /* ------------------------------------------------------------- events
     Own events: { [iso]: [{ id, time, title, place, done }] }.
     Imported calendars live separately so a re-sync never clobbers them:
     { [sourceId]: { name, kind: 'file'|'url', url?, synced, items: [{ uid, date, time, title, place, allDay }] } } */
  const events = store.get('events', {}) || {};
  const sources = store.get('sources', {}) || {};
  const importDone = store.get('importDone', {}) || {};
  const saveEvents = () => store.set('events', events);
  const saveSources = () => { try { localStorage.setItem('sehari:sources', JSON.stringify(sources)); } catch { announce('Browser storage is full. Some imported events may not be saved.'); } };
  let importIndex = null; // date -> imported items, rebuilt when sources change
  function rebuildImportIndex() {
    importIndex = new Map();
    Object.entries(sources).forEach(([sid, src]) => (src.items || []).forEach(it => {
      const row = { id: `imp:${sid}:${it.uid}`, date: it.date, time: it.time || '', title: it.title, place: it.place, allDay: it.allDay || !it.time, src: src.name, imported: true };
      row.done = !!importDone[row.id];
      if (!importIndex.has(it.date)) importIndex.set(it.date, []);
      importIndex.get(it.date).push(row);
    }));
  }
  function eventsFor(isoDate) {
    if (!importIndex) rebuildImportIndex();
    const own = (events[isoDate] || []).map(e => ({ ...e, date: isoDate }));
    const imp = (importIndex.get(isoDate) || []).map(e => ({ ...e, done: !!importDone[e.id] }));
    return own.concat(imp).sort((a, b) => (a.time || '').localeCompare(b.time || '') || a.title.localeCompare(b.title));
  }

  /* ------------------------------------------------- screen markup (1:1) */
  const state = { selected: TODAY, view: 'month', risoCompact: true, ledgerCompact: true };
  let style = STYLES[1];

  function art(kind, extra = '') { return `<span class="print-art art-${kind} ${extra}" aria-hidden="true"></span>`; }
  function multilingual(date) {
    return `<div class="multilingual"><span lang="zh">${esc(translated(date, 'zh-CN', 'month'))}</span><span lang="ms">${MS_MONTH[date.getMonth()].toUpperCase()}</span><span lang="ta">${esc(translated(date, 'ta-MY', 'month'))}</span></div>`;
  }
  function monthHeading(date, { split = false, compact = false } = {}) {
    return `<div class="month-title-wrap"><div class="month-nav"><button class="nav-arrow" data-action="month-prev" aria-label="Previous month">‹</button><h3 class="month-heading${split ? ' split' : ''}"><span class="month-word">${monthName(date)}</span>${split ? '' : ' '}<span class="year">${date.getFullYear()}</span></h3><button class="nav-arrow" data-action="month-next" aria-label="Next month">›</button></div>${compact ? '' : multilingual(date)}</div>`;
  }
  function calendar(st, { mini = false, week = false } = {}) {
    const selected = dateFromISO(st.selected);
    const start = new Date(selected.getFullYear(), selected.getMonth(), 1, 12);
    const offset = (start.getDay() + 6) % 7;
    const dim = new Date(selected.getFullYear(), selected.getMonth() + 1, 0, 12).getDate();
    let length = Math.ceil((offset + dim) / 7) * 7;
    if (week) { start.setDate(selected.getDate() - (selected.getDay() + 6) % 7); length = 14; }
    const weekdays = DAY_INITIALS.map((day, i) => `<span class="weekday${i === 6 ? ' sunday' : ''}" aria-label="${DAYS[(i + 1) % 7]}">${day}</span>`).join('');
    let dates = '';
    for (let i = 0; i < length; i++) {
      const date = new Date(start);
      date.setDate(week ? start.getDate() + i : i - offset + 1);
      const k = isoFromDate(date);
      const outside = date.getMonth() !== selected.getMonth();
      if (!week && outside) { dates += '<span class="date-cell blank" aria-hidden="true"></span>'; continue; }
      const sel = k === st.selected;
      const hol = holiday(date.getFullYear(), date.getMonth(), date.getDate());
      const has = eventsFor(k).length > 0;
      const red = date.getDay() === 0 || hol;
      dates += `<button type="button" class="date-cell${sel ? ' selected' : ''}${red ? ' sunday' : ''}${hol ? ' holiday' : ''}${outside ? ' outside' : ''}${has ? ' has-events' : ''}" data-date="${k}" aria-label="${esc(fullLabel(date))}${hol ? ', ' + esc(hol.en) : ''}${has ? ', has events' : ''}" aria-pressed="${sel}"${k === TODAY ? ' aria-current="date"' : ''}><span class="date-number">${date.getDate()}</span></button>`;
    }
    return `<div class="calendar${mini ? ' mini-calendar' : ''}${week ? ' week-calendar' : ''}" aria-label="${week ? 'Two weeks' : monthName(selected) + ' ' + selected.getFullYear()}">${weekdays}${dates}</div>`;
  }
  function eventLabel(e) { return `${e.done ? 'Mark as not done' : 'Mark as done'}: ${e.title}, ${e.time || 'all day'}${e.src ? ' (' + e.src + ')' : ''}`; }
  function eventRows(st, { places = false } = {}) {
    const rows = eventsFor(st.selected);
    if (!rows.length) return '<p class="empty-events">No events. Room for new plans.</p>';
    return rows.map(e => `<button type="button" class="event-row${e.done ? ' completed' : ''}${e.imported ? ' imported' : ''}" data-event="${esc(e.id)}" aria-pressed="${!!e.done}" aria-label="${esc(eventLabel(e))}"><time${e.time ? '' : ' class="all-day"'} datetime="${e.date}${e.time ? 'T' + e.time : ''}">${e.time || 'All day'}</time><span class="event-title">${esc(e.title)}${places && (e.place || e.src) ? `<span class="event-place">${esc(e.place || e.src)}</span>` : ''}</span><span class="check" aria-hidden="true">${e.done ? '✓' : ''}</span></button>`).join('');
  }
  function caption(st) { const d = dateFromISO(st.selected); return `<p class="date-caption"><span class="caption-weekday">${DAYS[d.getDay()]}, </span>${d.getDate()} ${monthName(d)} ${d.getFullYear()}</p>`; }
  function agenda(st, { showCaption = true, places = false } = {}) { return `<section class="agenda" aria-label="Events for ${esc(fullLabel(dateFromISO(st.selected)))}">${showCaption ? caption(st) : ''}${eventRows(st, { places })}</section>`; }
  const addButton = () => '<button type="button" class="add-event" data-action="add">+ Event</button>';
  function controls(st, { toggle = true, add = true } = {}) {
    return `<div class="controls">${toggle ? `<div class="view-switch" aria-label="Calendar view"><button type="button" data-action="day" aria-pressed="${st.view === 'day'}">Day</button><button type="button" data-action="month" aria-pressed="${st.view === 'month'}">Month</button></div>` : ''}${add ? addButton() : ''}</div>`;
  }
  function selectedDay(st, { expanded = false, motif = false } = {}) {
    const d = dateFromISO(st.selected);
    return `<div class="selected-day${expanded ? ' day-expanded' : ''}"><span class="selected-number">${d.getDate()}</span><div class="selected-day-copy"><h3>${DAYS[d.getDay()]}</h3><p lang="ms">${MS_DAY[d.getDay()]}</p><p lang="zh">${esc(translated(d, 'zh-CN', 'weekday'))}</p></div>${motif ? art('moon') : ''}</div>`;
  }
  function weekRows(st) {
    const date = dateFromISO(st.selected);
    const monday = new Date(date); monday.setDate(date.getDate() - (date.getDay() + 6) % 7);
    let rows = '<div class="ledger-columns" aria-hidden="true"><span></span><span></span><span>EVENTS</span></div>';
    for (let n = 0; n < 7; n++) {
      const day = new Date(monday); day.setDate(monday.getDate() + n);
      const k = isoFromDate(day), sel = k === st.selected;
      const red = day.getDay() === 0 || holiday(day.getFullYear(), day.getMonth(), day.getDate());
      const list = eventsFor(k);
      rows += `<div class="ledger-row${sel ? ' is-selected' : ''}"><div class="ledger-day"><button class="ledger-num${red ? ' sunday' : ''}" data-date="${k}" aria-label="${esc(fullLabel(day))}" aria-pressed="${sel}">${day.getDate()}</button><button class="${red ? 'sunday' : ''}" data-date="${k}" aria-label="${esc(fullLabel(day))}" aria-pressed="${sel}">${sel ? DAYS[day.getDay()].charAt(0) + DAYS[day.getDay()].slice(1).toLowerCase() : SHORT_DAYS[day.getDay()]}</button></div><div class="ledger-events">${list.map(e => `<button class="ledger-event${e.done ? ' completed' : ''}" data-event="${esc(e.id)}" aria-label="${esc(eventLabel(e))}" aria-pressed="${!!e.done}">${e.time || 'All day'}&nbsp; ${esc(e.title)}</button>`).join('')}</div></div>`;
    }
    return `<section class="ledger-table" aria-label="Weekly agenda">${rows}<div class="ledger-tail" aria-hidden="true"><span></span><span></span><span></span></div></section>`;
  }
  function screenHTML(s, st, { preview = false } = {}) {
    const date = dateFromISO(st.selected), d = date.getDate();
    switch (s.no) {
      case 1: return `<div class="binding" aria-hidden="true"><i></i><i></i></div>${monthHeading(date, { compact: true })}<div class="tear-date${d >= 10 ? ' two-digit' : ''}">${d}</div><h3 class="tear-weekday${DAYS[date.getDay()].length > 8 ? ' long' : ''}">${DAYS[date.getDay()]}</h3><div class="tear-translations"><span lang="zh">${esc(translated(date, 'zh-CN', 'weekday'))}</span><span lang="ms">${MS_DAY[date.getDay()].toUpperCase()}</span><span lang="ta">${esc(translated(date, 'ta-MY', 'weekday'))}</span></div><div class="tear-month">${calendar(st, { mini: true })}<div class="tear-month-label">${monthName(date)}<br><span lang="ms">${MS_MONTH[date.getMonth()]}</span><br><span lang="zh">${esc(translated(date, 'zh-CN', 'month'))}</span></div></div>${agenda(st, { showCaption: false })}${controls(st, { toggle: false })}`;
      case 2: return `<header class="horse-masthead" lang="ms"><h3>KALENDAR</h3><div class="horse-copy" lang="zh">萬用<br>實用<br>天天進步<small>KALENDAR KUDA<br>馬牌日曆</small></div>${art('horse')}</header>${monthHeading(date)}${calendar(st)}${selectedDay(st, { expanded: true })}${agenda(st)}${controls(st)}`;
      case 3: return `<header class="coffee-masthead" lang="ms"><h3><small>KEDAI KOPI</small>SINAR PAGI</h3><p class="chinese" lang="zh">新早晨咖啡店</p>${art('coffee')}<p class="strapline">KOPI · ROTI · KAWAN · JADUAL HIDUP</p></header>${monthHeading(date, { compact: true })}${st.view === 'day' ? `${selectedDay(st)}${agenda(st, { showCaption: false, places: true })}` : st.ledgerCompact ? weekRows(st) : `${calendar(st)}${agenda(st)}`}${controls(st)}`;
      case 4: return `<header class="shop-masthead" lang="ms"><h3>HARI HARI</h3><h4>KEDAI RUNCIT</h4>${art('goods')}<p>BERAS · GULA · MINYAK MASAK<br>TEPUNG · MINUMAN · BARANG HARIAN</p></header>${monthHeading(date)}${calendar(st)}<div class="receipt">${agenda(st)}${controls(st, { toggle: false })}</div>`;
      case 5: return `<div class="batik-strip" aria-hidden="true"></div>${monthHeading(date, { split: true })}${calendar(st)}${selectedDay(st, { expanded: true })}${agenda(st)}${controls(st)}`;
      case 6: return `<div class="postcard-picture"><img src="assets/postcard-street.webp" alt="Vintage illustration of shophouses and coconut trees"><span class="postcard-greeting" lang="ms">Selamat Datang<br>ke<strong>MALAYSIA</strong></span></div>${monthHeading(date)}${calendar(st)}${selectedDay(st, { expanded: true })}<div class="postcard-bottom">${art('flower')}${agenda(st)}</div>${controls(st)}`;
      case 7: return `<header class="stamp-header"><p lang="ms">PELAN<br>JADUAL<br>HARIAN</p><p class="serial">No. ${pad2(date.getMonth() + 1)}${pad2(d)}28</p><div class="weekday-stamp">${DAYS[date.getDay()]}</div></header><h3 class="stamp-date">${pad2(d)} / ${pad2(date.getMonth() + 1)} / ${date.getFullYear()}</h3>${monthHeading(date, { compact: true })}${st.view === 'month' ? calendar(st) : ''}${agenda(st, { showCaption: false, places: true })}<label class="stamp-notes"${preview ? '' : ' for="notes-7"'}>NOTES<textarea${preview ? '' : ' id="notes-7"'} data-notes="${st.selected}" aria-label="Notes for ${esc(fullLabel(date))}" maxlength="500" spellcheck="false">${esc(notes[st.selected] || '')}</textarea></label><div class="stamp-footer"><div><p class="stamp-mini-title">${monthName(date)} ${date.getFullYear()}</p>${calendar(st, { mini: true })}</div><div class="print-seal" aria-hidden="true"><span>JADUAL</span><strong>★</strong><span>HARIAN</span></div></div>${controls(st)}`;
      case 8: return `<header class="riso-masthead"><h3>${monthName(date).slice(0, 3)}</h3><p class="riso-year">${date.getFullYear()}</p>${art('flower')}<div class="riso-languages"><span><span lang="zh">${esc(translated(date, 'zh-CN', 'month'))}</span>&nbsp; <span lang="ms">${MS_MONTH[date.getMonth()].toUpperCase()}</span></span><span lang="ta">${esc(translated(date, 'ta-MY', 'month'))}</span></div></header>${calendar(st, { week: st.risoCompact })}${st.view === 'month' && st.risoCompact ? '<div class="week-navigation"><button data-action="week-prev" aria-label="Previous week">‹</button><span>TWO WEEKS</span><button data-action="week-next" aria-label="Next week">›</button></div>' : ''}${selectedDay(st, { expanded: true })}<div class="riso-bottom">${art('bus')}<section class="agenda" aria-label="Events for this day">${caption(st)}${eventRows(st)}${addButton()}</section></div>${controls(st, { add: false })}`;
      case 9: return `${art('moon')}${monthHeading(date)}${calendar(st)}${selectedDay(st, { motif: true })}${agenda(st, { showCaption: false })}${controls(st)}`;
      default: return '';
    }
  }
  function screenElementHTML(s, st, opts = {}) {
    return `<section class="screen ${s.cls}" data-study="${s.no}" data-view="${st.view}" aria-label="${esc(s.name)}" lang="en"${opts.preview ? ' inert' : ''}>${screenHTML(s, st, opts)}</section>`;
  }

  /* --------------------------------------------- the daily leaf (our page)
     Fact, peribahasa, notes, and holiday/Hijri/lunar details, set in the
     chosen design's paper, ink and type so it reads as the next page. */
  function leafHTML(st) {
    const p = parseIso(st.selected);
    const d = dateFromISO(st.selected);
    const h = holiday(p.y, p.m, p.d), l = lunar(p.y, p.m, p.d), hj = hijri(p.y, p.m, p.d);
    const doy = dayNum(p.y, p.m, p.d) - dayNum(p.y, 0, 1) + 1, left = dayNum(p.y, 11, 31) - dayNum(p.y, p.m, p.d);
    const f = factFor(p), r = periFor(p);
    const cat = CAT_EN[f.cat] ? f.cat : 'Tempat';
    const mine = (events[st.selected] || []);
    const imported = eventsFor(st.selected).filter(e => e.imported);
    const meta = [hj ? `${hj.day} ${HIJRI_MONTH[hj.month - 1]} ${hj.year} AH` : '', l ? `<span lang="zh">${lunarYearName(p.y, p.m, p.d)}${lunarMonthZh(l)}${lunarDayZh(l.day)}</span>` : ''].filter(Boolean).join('<i aria-hidden="true">·</i>');
    return `
      <header class="leaf-head">
        <p class="leaf-kicker">Daily sheet · <span>Day ${doy}, ${left} ${left === 1 ? 'day' : 'days'} left</span></p>
        <h2 class="leaf-date">${fullLabel(d)}</h2>
        <p class="leaf-meta">${meta}</p>
        ${h ? `<p class="leaf-hol">${esc(h.en)}${h.approx ? '*' : ''}${h.ms !== h.en ? ` <span lang="ms">${esc(h.ms)}</span>` : ''}${h.scope === 'some' ? `<span>${h.ms !== h.en ? ' · ' : ' '}some states</span>` : ''}</p>` : ''}
      </header>
      <article class="leaf-card leaf-fact">
        <div class="leaf-card-head"><h3>Did You Know?</h3><span><b>${CAT_EN[cat]}</b><b lang="ms">${esc(cat)}</b></span></div>
        <div class="leaf-fact-body"><span class="leaf-icon" aria-hidden="true">${ICONS[cat]}</span><p>${esc(f.t)}</p></div>
        <button type="button" class="leaf-redraw" data-kind="fact">Another fact ${REDRAW_ICON}</button>
      </article>
      <article class="leaf-card leaf-peri">
        <div class="leaf-card-head"><h3>Peribahasa</h3>${r.jenis ? `<span>${JENIS_EN[r.jenis] ? `<b>${JENIS_EN[r.jenis]}</b>` : ''}<b lang="ms">${esc(r.jenis)}</b></span>` : ''}</div>
        <p class="leaf-proverb" lang="ms">${esc(r.p)}</p>
        <dl>
          ${r.en ? `<dt>Meaning</dt><dd>${esc(r.en)}</dd>` : ''}
          <dt>In Malay</dt><dd lang="ms">${esc(r.maksud)}</dd>
          ${r.contoh ? `<dt>Example</dt><dd class="leaf-example" lang="ms">${esc(r.contoh)}</dd>` : ''}
        </dl>
        <button type="button" class="leaf-redraw" data-kind="peri">Another peribahasa ${REDRAW_ICON}</button>
      </article>
      ${style.no === 7 ? '' : `<label class="leaf-note">Notes<textarea data-notes="${st.selected}" maxlength="500" spellcheck="false" placeholder="e.g. pay the water bill, Mak Long's kenduri…">${esc(notes[st.selected] || '')}</textarea></label>`}
      ${mine.length || imported.length ? `<section class="leaf-manage" aria-label="Manage events"><h3>Manage events</h3><ul>${mine.slice().sort((a, b) => a.time.localeCompare(b.time)).map(e => `<li><span><b>${esc(e.time)}</b> ${esc(e.title)}</span><button type="button" data-edit="${esc(e.id)}">Edit</button></li>`).join('')}${imported.map(e => `<li class="leaf-imported"><span><b>${e.time || 'All day'}</b> ${esc(e.title)}</span><small>${esc(e.src)}</small></li>`).join('')}</ul></section>` : ''}
      <nav class="leaf-nav" aria-label="Change day"><button type="button" data-step="-1">‹ Yesterday</button><button type="button" data-step="0">Today</button><button type="button" data-step="1">Tomorrow ›</button></nav>`;
  }

  /* ----------------------------------------------------------- rendering */
  const stage = $('#stage');
  const leaf = $('#leaf');
  const flipShade = $('#flipShade');
  let screen = null;

  function render() {
    const keep = document.activeElement && stage.contains(document.activeElement) ? document.activeElement : null;
    const sel = keep ? (keep.dataset.date ? `[data-date="${keep.dataset.date}"]` : keep.dataset.action ? `[data-action="${keep.dataset.action}"]` : keep.dataset.event ? `[data-event="${CSS.escape(keep.dataset.event)}"]` : keep.matches('textarea') ? 'textarea' : null) : null;
    stage.querySelectorAll('.screen').forEach(n => n.remove());
    stage.insertAdjacentHTML('afterbegin', screenElementHTML(style, state));
    screen = stage.querySelector('.screen');
    if (sel) { const n = screen.querySelector(sel); if (n) n.focus({ preventScroll: true }); }
    renderLeaf();
    pushWidget();
  }
  function renderLeaf() {
    leaf.dataset.theme = style.id;
    leaf.innerHTML = leafHTML(state);
  }

  /* -------------------------------------------------- page curl & tear */
  // buildFlipper / setCurl / tween come from the shared engine above.
  let flip = null;
  async function curlTo(apply, dir) {
    if (flip || reducedMotion.matches || !screen) { apply(); render(); return; }
    const H = screen.offsetHeight;
    const oldHTML = screen.outerHTML;
    const s = { dir, t: dir > 0 ? 0 : 1 };
    if (dir > 0) { s.f = buildFlipper(oldHTML, H); apply(); render(); }
    else { const before = { ...state }; apply(); const nextHTML = screenElementHTML(style, state); Object.assign(state, before); s.f = buildFlipper(nextHTML, H); s.next = apply; }
    stage.appendChild(s.f.root);
    flip = s;
    setCurl(s, s.t);
    Sound.rustle();
    await tween(s.t, dir > 0 ? 1 : 0, 950, t => setCurl(s, t));
    if (dir < 0) { s.next(); render(); }
    s.f.root.remove();
    flipShade.style.opacity = 0;
    flip = null;
  }
  function tearTo(apply) {
    if (reducedMotion.matches || !screen) { apply(); render(); return; }
    const old = screen.cloneNode(true);
    old.inert = true;
    old.classList.add('tearing');
    old.style.cssText = `position:absolute;left:0;top:0;width:${screen.offsetWidth}px;z-index:20;margin:0`;
    apply();
    render();
    stage.appendChild(old);
    Sound.rip();
    old.animate([
      { transform: 'translate(0,0) rotate(0deg)', offset: 0 },
      { transform: 'translate(0, 2px) rotate(1.6deg)', offset: 0.16 },
      { transform: 'translate(3px, 9px) rotate(5deg)', offset: 0.34 },
      { transform: 'translate(-24px, 46px) rotate(10deg)', offset: 0.52 },
      { transform: 'translate(-120px, 115vh) rotate(-22deg)', offset: 1 },
    ], { duration: 1000, easing: 'cubic-bezier(.4,.05,.6,1)', fill: 'forwards' }).finished.then(() => old.remove(), () => old.remove());
  }

  const isDayPage = () => style.no === 1 || state.view === 'day';
  function selectDate(k, { animate = true } = {}) {
    if (k === state.selected) return;
    const forward = k > state.selected;
    const sameMonth = k.slice(0, 7) === state.selected.slice(0, 7);
    const apply = () => { state.selected = k; };
    if (!animate) { apply(); render(); }
    else if (isDayPage()) {
      if (forward) tearTo(apply);
      else { apply(); render(); if (!reducedMotion.matches) screen.animate([{ transform: 'translateY(-30px) rotate(-2deg)', opacity: 0 }, { transform: 'none', opacity: 1 }], { duration: 480, easing: 'cubic-bezier(.3,.7,.4,1)' }); Sound.rustle(0.3); }
    } else if (!sameMonth) curlTo(apply, forward ? 1 : -1);
    else { apply(); render(); }
    announce(fullLabel(dateFromISO(k)));
  }
  function shiftDate({ months = 0, days = 0 }) {
    const date = dateFromISO(state.selected);
    if (months) { const day = date.getDate(); date.setDate(1); date.setMonth(date.getMonth() + months); date.setDate(Math.min(day, new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate())); }
    if (days) date.setDate(date.getDate() + days);
    const k = isoFromDate(date);
    if (months) { curlTo(() => { state.selected = k; }, months > 0 ? 1 : -1); announce(fullLabel(date)); }
    else selectDate(k);
  }

  /* ------------------------------------------------------- interaction */
  let swipe = null;
  stage.addEventListener('pointerdown', e => {
    if (e.button !== 0 || flip || e.target.closest('textarea, input')) return;
    swipe = { id: e.pointerId, x: e.clientX, y: e.clientY };
  });
  stage.addEventListener('pointerup', e => {
    if (!swipe || e.pointerId !== swipe.id) return;
    const dx = e.clientX - swipe.x, dy = e.clientY - swipe.y;
    swipe = null;
    if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy) * 1.5) return;
    suppressClick = performance.now() + 350;
    if (isDayPage()) shiftDate({ days: dx < 0 ? 1 : -1 });
    else shiftDate({ months: dx < 0 ? 1 : -1 });
  });
  stage.addEventListener('pointercancel', () => { swipe = null; });
  let suppressClick = 0;

  stage.addEventListener('click', e => {
    if (performance.now() < suppressClick) { e.preventDefault(); e.stopPropagation(); return; }
    const t = e.target.closest('button');
    if (!t || !screen || !screen.contains(t)) return;
    if (t.dataset.date) { selectDate(t.dataset.date); const n = screen && screen.querySelector(`[data-date="${state.selected}"]`); if (n) n.focus({ preventScroll: true }); return; }
    if (t.dataset.event) { toggleDone(t.dataset.event); return; }
    switch (t.dataset.action) {
      case 'add': openEventDialog(null, t); break;
      case 'day': state.view = 'day'; render(); break;
      case 'month': state.view = 'month'; if (style.no === 8) state.risoCompact = false; if (style.no === 3) state.ledgerCompact = false; render(); break;
      case 'month-prev': shiftDate({ months: -1 }); break;
      case 'month-next': shiftDate({ months: 1 }); break;
      case 'week-prev': shiftDate({ days: -7 }); break;
      case 'week-next': shiftDate({ days: 7 }); break;
    }
  });

  leaf.addEventListener('click', e => {
    const t = e.target.closest('button');
    if (!t) return;
    if (t.dataset.step != null) { const n = +t.dataset.step; if (n === 0) { selectDate(TODAY); } else shiftDate({ days: n }); return; }
    if (t.dataset.edit) { openEventDialog(t.dataset.edit, t); return; }
    if (t.dataset.kind) {
      const p = parseIso(state.selected);
      rerolls[t.dataset.kind][state.selected] = (rerolls[t.dataset.kind][state.selected] || 0) + 1;
      Sound.rustle(0.25);
      const card = t.closest('.leaf-card');
      const swap = () => { renderLeaf(); const b = leaf.querySelector(`[data-kind="${t.dataset.kind}"]`); if (b) b.focus({ preventScroll: true }); };
      if (reducedMotion.matches || !card) { swap(); return; }
      card.animate([{ opacity: 1 }, { opacity: 0, transform: 'translateY(-6px)' }], { duration: 160, fill: 'forwards' }).finished.then(swap);
      void p;
    }
  });

  let noteTimer = 0;
  document.addEventListener('input', e => {
    const ta = e.target.closest('textarea[data-notes]');
    if (!ta) return;
    clearTimeout(noteTimer);
    noteTimer = setTimeout(() => {
      const k = ta.dataset.notes;
      if (ta.value.trim()) notes[k] = ta.value; else delete notes[k];
      store.set('notes', notes);
    }, 250);
  });

  function toggleDone(id) {
    if (id.startsWith('imp:')) { if (importDone[id]) delete importDone[id]; else importDone[id] = true; store.set('importDone', importDone); }
    else {
      const list = events[state.selected] || Object.values(events).find(l => l.some(x => x.id === id)) || [];
      const ev = list.find(x => x.id === id) || Object.values(events).flat().find(x => x.id === id);
      if (!ev) return;
      ev.done = !ev.done;
      saveEvents();
    }
    render();
    const n = screen.querySelector(`[data-event="${CSS.escape(id)}"]`);
    if (n) n.focus({ preventScroll: true });
    const ev = eventsFor(state.selected).find(x => x.id === id);
    if (ev) announce(`${ev.title}: ${ev.done ? 'done' : 'not done'}`);
  }

  /* ------------------------------------------------------ event dialog */
  const dlg = $('#eventDialog');
  const form = $('#eventForm');
  let editing = null, returnFocus = null;
  function themeDialog(el) {
    const cs = screen ? getComputedStyle(screen) : null;
    el.style.setProperty('--modal-paper', style.no === 9 ? '#f2e7cf' : (cs ? cs.getPropertyValue('--paper') : '#f6efdf'));
    el.style.setProperty('--modal-ink', style.no === 9 ? '#272822' : (cs ? cs.getPropertyValue('--ink') : '#263327'));
    el.style.setProperty('--modal-accent', cs ? cs.getPropertyValue('--accent') : '#b62d2b');
  }
  function findOwn(id) {
    for (const [k, list] of Object.entries(events)) { const ev = list.find(x => x.id === id); if (ev) return { k, ev }; }
    return null;
  }
  function openEventDialog(id, from) {
    returnFocus = from || null;
    const found = id ? findOwn(id) : null;
    editing = found;
    form.reset();
    $('#eventTitle').textContent = found ? 'Edit event' : 'Add event';
    form.elements.title.value = found ? found.ev.title : '';
    form.elements.date.value = found ? found.k : state.selected;
    form.elements.time.value = found ? found.ev.time : '09:00';
    form.elements.place.value = found ? found.ev.place || '' : '';
    $('#deleteEvent').hidden = !found;
    themeDialog(dlg);
    dlg.showModal();
    form.elements.title.focus();
  }
  function closeEventDialog() { dlg.close(); if (returnFocus && returnFocus.isConnected) returnFocus.focus(); }
  form.addEventListener('submit', e => {
    e.preventDefault();
    const title = form.elements.title.value.trim(), date = form.elements.date.value, time = form.elements.time.value;
    if (!title) { form.elements.title.setCustomValidity('Enter a name for the event.'); form.elements.title.reportValidity(); return; }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return;
    const place = form.elements.place.value.trim();
    if (editing) {
      events[editing.k] = events[editing.k].filter(x => x !== editing.ev);
      if (!events[editing.k].length) delete events[editing.k];
      (events[date] = events[date] || []).push({ ...editing.ev, title, time, place });
    } else {
      (events[date] = events[date] || []).push({ id: (crypto.randomUUID ? crypto.randomUUID() : Date.now().toString(36) + Math.random().toString(36).slice(2)), time, title, place, done: false });
    }
    saveEvents();
    state.selected = date;
    render();
    closeEventDialog();
    Sound.rustle(0.2);
    announce(`Saved ${title} for ${fullLabel(dateFromISO(date))}.`);
  });
  form.elements.title.addEventListener('input', () => form.elements.title.setCustomValidity(''));
  $('#deleteEvent').addEventListener('click', () => {
    if (!editing) return;
    events[editing.k] = events[editing.k].filter(x => x !== editing.ev);
    if (!events[editing.k].length) delete events[editing.k];
    saveEvents();
    render();
    closeEventDialog();
    announce('Event deleted.');
  });
  dlg.querySelector('.close-dialog').addEventListener('click', closeEventDialog);
  dlg.addEventListener('click', e => { if (e.target === dlg) closeEventDialog(); });

  /* ------------------------------------------------------ import dialog */
  const imp = $('#importDialog');
  const impStatus = $('#importStatus');
  function sourceListHTML() {
    const list = Object.entries(sources);
    if (!list.length) return '<p class="imp-empty">No calendars imported yet.</p>';
    return `<ul class="imp-sources">${list.map(([sid, s]) => {
      const n = (s.items || []).length;
      const when = s.synced ? new Date(s.synced).toLocaleString('en-MY', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '';
      return `<li><div><b>${esc(s.name)}</b><small>${n} ${n === 1 ? 'event' : 'events'} · ${s.kind === 'url' ? 'subscription' : 'file'}${when ? ' · ' + when : ''}</small></div><span>${s.kind === 'url' ? `<button type="button" data-sync="${sid}">Sync</button>` : ''}<button type="button" data-remove="${sid}">Remove</button></span></li>`;
    }).join('')}</ul>`;
  }
  function paintSources() { $('#importSources').innerHTML = sourceListHTML(); }
  function status(msg, bad) { impStatus.textContent = msg; impStatus.classList.toggle('bad', !!bad); }
  function addSource(name, kind, items, url) {
    const sid = (kind === 'url' ? 'u' : 'f') + Date.now().toString(36) + Math.random().toString(36).slice(2, 5);
    sources[sid] = { name: name || 'Calendar', kind, url: url || '', synced: Date.now(), items };
    saveSources(); rebuildImportIndex();
    return sid;
  }
  function summarise(items) {
    if (!items.length) return 'No events in the two-year range';
    const ds = items.map(i => i.date).sort();
    const f = d => { const p = parseIso(d); return `${p.d} ${EN_MONTH[p.m].slice(0, 3)} ${p.y}`; };
    return `${items.length} ${items.length === 1 ? 'event' : 'events'} (${f(ds[0])} – ${f(ds[ds.length - 1])})`;
  }
  function openImport(from) {
    returnFocus = from || null;
    themeDialog(imp);
    paintSources();
    status('');
    imp.showModal();
  }
  $('#importFile').addEventListener('change', async e => {
    const files = [...e.target.files];
    e.target.value = '';
    if (!files.length) return;
    status('Reading files…');
    const done = [];
    for (const file of files) {
      try {
        const cals = await window.SehariImport.readFile(file);
        cals.forEach(c => { addSource(c.name, 'file', c.items); done.push(`${c.name}: ${summarise(c.items)}`); });
      } catch (err) { status(`${file.name}: ${err.message}`, true); paintSources(); return; }
    }
    status('Imported. ' + done.join('; ') + '.');
    paintSources(); render();
  });
  $('#importUrlForm').addEventListener('submit', async e => {
    e.preventDefault();
    const url = e.target.elements.url.value.trim();
    const name = e.target.elements.name.value.trim();
    if (!url) return;
    status('Loading link…');
    try {
      const text = await window.SehariImport.fetchFeed(url);
      const cal = window.SehariImport.parseICS(text);
      addSource(name || cal.name || new URL(url.replace(/^webcals?:/i, 'https:')).hostname, 'url', cal.items, url);
      e.target.reset();
      status(`Subscribed. ${summarise(cal.items)}. It syncs again when the app opens.`);
      paintSources(); render();
    } catch (err) { status(err.message, true); }
  });
  async function syncSource(sid, quiet) {
    const s = sources[sid];
    if (!s || s.kind !== 'url') return;
    try {
      const cal = window.SehariImport.parseICS(await window.SehariImport.fetchFeed(s.url));
      s.items = cal.items; s.synced = Date.now();
      saveSources(); rebuildImportIndex();
      if (!quiet) status(`${s.name} synced: ${summarise(cal.items)}.`);
    } catch (err) { if (!quiet) status(`${s.name}: ${err.message}`, true); }
  }
  $('#importSources').addEventListener('click', async e => {
    const t = e.target.closest('button');
    if (!t) return;
    if (t.dataset.remove) {
      const sid = t.dataset.remove;
      Object.keys(importDone).filter(k => k.startsWith(`imp:${sid}:`)).forEach(k => delete importDone[k]);
      store.set('importDone', importDone);
      delete sources[sid]; saveSources(); rebuildImportIndex();
      status('Calendar removed.'); paintSources(); render();
    }
    if (t.dataset.sync) { status('Syncing…'); await syncSource(t.dataset.sync); paintSources(); render(); }
  });
  imp.querySelector('.close-dialog').addEventListener('click', () => { imp.close(); if (returnFocus && returnFocus.isConnected) returnFocus.focus(); });
  imp.addEventListener('click', e => { if (e.target === imp) imp.close(); });
  // Re-sync subscriptions quietly when the app opens (at most every 3 hours).
  setTimeout(async () => {
    const due = Object.entries(sources).filter(([, s]) => s.kind === 'url' && Date.now() - (s.synced || 0) > 3 * 36e5);
    for (const [sid] of due) await syncSource(sid, true);
    if (due.length) render();
  }, 1500);

  /* --------------------------------------------------------- onboarding */
  const onboard = $('#onboard');
  const obGrid = $('#obGrid');
  let obChoice = null;
  function previewState(s) { return { selected: state.selected, view: s.start, risoCompact: true, ledgerCompact: true }; }
  const fitPreviews = () => obGrid.querySelectorAll('.ob-prev').forEach(el => el.style.setProperty('--s', (el.clientWidth / 390).toFixed(4)));
  function openOnboarding(first) {
    obChoice = style.id;
    obGrid.innerHTML = STYLES.map(s => `<div class="ob-tile" role="radio" tabindex="${s.id === obChoice ? 0 : -1}" aria-checked="${s.id === obChoice}" aria-label="${s.no}. ${esc(s.name)}: ${esc(s.desc)}" data-id="${s.id}">
      <span class="ob-prev"><span class="ob-scale">${screenElementHTML(s, previewState(s), { preview: true })}</span></span>
      <span class="ob-name" aria-hidden="true"><b>${pad2(s.no)}</b> ${esc(s.name)}</span><span class="ob-desc" aria-hidden="true">${esc(s.desc)}</span></div>`).join('');
    $('#obClose').hidden = first;
    onboard.hidden = false;
    document.body.classList.add('ob-open');
    $('#app').inert = true;
    requestAnimationFrame(fitPreviews);
    paintChoice();
    setTimeout(() => (obGrid.querySelector('[aria-checked="true"]') || obGrid.firstElementChild).focus({ preventScroll: true }), 50);
  }
  function paintChoice() {
    obGrid.querySelectorAll('.ob-tile').forEach(b => { const on = b.dataset.id === obChoice; b.setAttribute('aria-checked', String(on)); b.tabIndex = on ? 0 : -1; });
    const s = STYLES.find(x => x.id === obChoice);
    $('#obPicked').textContent = s ? `Selected: ${s.name}` : '';
  }
  function closeOnboarding() { onboard.hidden = true; document.body.classList.remove('ob-open'); $('#app').inert = false; obGrid.innerHTML = ''; }
  obGrid.addEventListener('click', e => { const t = e.target.closest('.ob-tile'); if (!t) return; obChoice = t.dataset.id; paintChoice(); Sound.rustle(0.2); });
  obGrid.addEventListener('dblclick', e => { if (e.target.closest('.ob-tile')) $('#obGo').click(); });
  obGrid.addEventListener('keydown', e => {
    if (e.key === 'Enter' || e.key === ' ') { const t = e.target.closest('.ob-tile'); if (t) { e.preventDefault(); obChoice = t.dataset.id; paintChoice(); if (e.key === 'Enter') $('#obGo').click(); } return; }
    const keys = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: 3, ArrowUp: -3 };
    if (!(e.key in keys)) return;
    e.preventDefault();
    const i = clamp(STYLES.findIndex(s => s.id === obChoice) + keys[e.key], 0, STYLES.length - 1);
    obChoice = STYLES[i].id; paintChoice(); obGrid.children[i].focus();
  });
  $('#obGo').addEventListener('click', () => {
    store.set('theme', obChoice);
    closeOnboarding();
    applyStyle(obChoice);
    if (!reducedMotion.matches) $('#app').animate([{ opacity: 0, transform: 'translateY(14px)' }, { opacity: 1, transform: 'none' }], { duration: 420, easing: 'cubic-bezier(.3,1.2,.5,1)' });
    $('#themeBtn').focus({ preventScroll: true });
  });
  $('#obClose').addEventListener('click', () => { closeOnboarding(); $('#themeBtn').focus(); });
  window.addEventListener('resize', () => { if (!onboard.hidden) fitPreviews(); });

  function applyStyle(id) {
    style = STYLES.find(s => s.id === id) || STYLES[1];
    state.view = style.start; state.risoCompact = true; state.ledgerCompact = true;
    document.body.dataset.style = style.id;
    const meta = $('meta[name="theme-color"]');
    if (meta) meta.content = style.color;
    render();
  }

  /* ------------------------------------------------------------ controls */
  $('#themeBtn').addEventListener('click', () => openOnboarding(false));
  $('#importBtn').addEventListener('click', e => openImport(e.currentTarget));
  $('#todayBtn').addEventListener('click', () => { const k = TODAY; if (k.slice(0, 7) !== state.selected.slice(0, 7)) curlTo(() => { state.selected = k; }, k > state.selected ? 1 : -1); else selectDate(k); });
  const soundBtn = $('#soundBtn');
  const paintSound = () => { soundBtn.setAttribute('aria-pressed', String(Sound.on)); soundBtn.textContent = Sound.on ? 'Sound: On' : 'Sound: Off'; };
  soundBtn.addEventListener('click', () => { Sound.toggle(); paintSound(); Sound.rustle(0.25); });
  paintSound();
  document.addEventListener('keydown', e => {
    if (e.target.closest && e.target.closest('textarea, input, dialog')) return;
    if (e.key === 'Escape' && !onboard.hidden && !$('#obClose').hidden) { closeOnboarding(); return; }
    if (!onboard.hidden || (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') || e.altKey || e.ctrlKey || e.metaKey) return;
    e.preventDefault();
    const dir = e.key === 'ArrowRight' ? 1 : -1;
    if (e.shiftKey) shiftDate({ months: dir }); else shiftDate({ days: dir });
  });

  /* ---------------------------------------------------------- installable */
  let installEvt = null;
  window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); installEvt = e; $('#installBtn').hidden = false; });
  $('#installBtn').addEventListener('click', async () => { if (!installEvt) return; installEvt.prompt(); try { await installEvt.userChoice; } catch { /* dismissed */ } installEvt = null; $('#installBtn').hidden = true; });
  if ('serviceWorker' in navigator && /^https?:$/.test(location.protocol) && !/^(localhost|127\.0\.0\.1)$/.test(location.hostname)) {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }

  /* ----------------------------------------------------- native widgets
     In the iOS and Android app (Capacitor), the home and lock screen widgets read
     a snapshot of the next 21 days that the app writes through the native
     WidgetBridge plugin. In a browser this does nothing. */
  const cap = window.Capacitor;
  // Without @capacitor/core bundled, the injected native bridge has nativePromise() but no registerPlugin().
  const WidgetBridge = !(cap && cap.isNativePlatform && cap.isNativePlatform()) ? null
    : cap.registerPlugin ? cap.registerPlugin('WidgetBridge')
    : cap.nativePromise ? { setData: options => cap.nativePromise('WidgetBridge', 'setData', options) } : null;
  let widgetTimer = 0;
  function pushWidget() {
    if (!WidgetBridge) return;
    clearTimeout(widgetTimer);
    widgetTimer = setTimeout(() => {
      const days = [];
      for (let i = 0; i < 21; i++) {
        const p = addDays(today(), i);
        const k = iso(p.y, p.m, p.d), w = weekday(p.y, p.m, p.d), h = holiday(p.y, p.m, p.d), hj = hijri(p.y, p.m, p.d);
        const date = new Date(p.y, p.m, p.d, 12);
        const r = periFor(p), f = factFor(p);
        days.push({
          date: k, d: p.d, m: p.m + 1, year: p.y, weekday: w,
          month: MS_MONTH[p.m].toUpperCase(), monthEn: MONTHS[p.m], monthZh: translated(date, 'zh-CN', 'month'),
          day: MS_DAY[w].toUpperCase(), dayEn: DAYS[w], dayZh: translated(date, 'zh-CN', 'weekday'),
          red: w === 0 || !!h, holiday: h ? h.ms : '',
          hijri: hj ? `${hj.day} ${HIJRI_MONTH[hj.month - 1]} ${hj.year}H` : '',
          peribahasa: r.p, maksud: r.maksud, fact: f.t,
          events: eventsFor(k).filter(e => !e.done).slice(0, 4).map(e => ({ time: e.time || '', title: e.title })),
        });
      }
      WidgetBridge.setData({ json: JSON.stringify({ style: style.id, updated: Date.now(), days }) }).catch(() => {});
    }, 400);
  }
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'hidden') pushWidget(); });

  /* --------------------------------------------------------------- start */
  const saved = store.get('theme', null);
  applyStyle(saved || 'kuda');
  if (!saved || !STYLES.some(s => s.id === saved)) openOnboarding(true);

  window.__sehari = { applyStyle, selectDate, shiftDate, state, get style() { return style; }, openOnboarding, openImport, sources, rebuildImportIndex, render };
})();
