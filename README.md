# Sehari Selembar

A nostalgic Malaysian calendar app with nine styles. Every day has a **Tahukah Anda?** fact about Malaysia and a **peribahasa** with its maksud, an English explanation and an example sentence. You can keep your own appointments or import them from Google Calendar, Apple Calendar, Outlook or Notion.

It is static HTML, CSS and JS with no build step, published from the repository root. The only server code is the small iCal proxy for subscription links.

The nine original design studies this app is built from live in [`studies/`](studies/) (open `studies/index.html` for the gallery).

## The nine styles

The screens are a 1:1 port of the design studies in `studies/`. That covers their markup, `design.css`, local fonts, and the print atlas, postcard, batik and paper-grain artwork, re-encoded from PNG to WebP (12 MB down to 2.4 MB). A pixel diff against the original pages differs by at most 0.6% of pixels, all of it text anti-aliasing.

1. Tear-off
2. Kalendar Kuda
3. Kopitiam Ledger
4. Kedai Runcit
5. Batik Margin
6. Postcard Month
7. Rubber Stamp
8. Riso Pop
9. Midnight Almanac

On first launch you pick a style from a gallery of live previews. The **Gaya** button reopens it.

## What the app adds around each screen

- **The daily leaf.** A second page set in the chosen design's paper, ink and type. It holds:
  - the date, Hijri and Chinese lunar dates, and any public holiday
  - the fact and peribahasa, with a reroll button for each
  - notes, and an "Urus acara" list to edit or delete your events
- **Animations.** Moving months lifts the page with a curl. Moving days on a day page (Tear-off, or any Hari view) tears the sheet off.
- **Holidays.** Sundays and public holidays print in the design's red.
- **One shared agenda.** Events are shared across all nine styles. Tap an event row to mark it done.

## Import

**Import** accepts:

- **Files:** `.ics`, Google Calendar's export `.zip` (no need to unzip) and Notion CSV exports. These come from:
  - Google Calendar: Tetapan → Import & eksport → Eksport
  - Apple Calendar: Fail → Eksport
  - Outlook: Simpan Kalendar
  - Notion: Export → CSV
- **Subscription links:** `https://` or `webcal://` iCal links, such as Google's secret iCal address, iCloud public calendars and Outlook published calendars. Each one re-syncs when the app opens, at most every 3 hours.

The parser, `import.js`, handles:
- timezones, including Outlook's Windows zone names
- recurring events: daily, weekly, monthly and yearly, with COUNT/UNTIL/INTERVAL/BYDAY/BYMONTHDAY, EXDATE and RECURRENCE-ID
- multi-day all-day events and cancelled events
- Notion date formats such as `October 1, 2026 9:00 AM (GMT+8)` and `A → B` ranges

Imported calendars are stored separately from your own events, so a re-sync never overwrites them. Removing a calendar removes its events.

Subscription links are fetched by `netlify/functions/ics-proxy.mjs` at `/api/ics`, because most calendar hosts don't allow browsers to fetch them directly. It accepts only public http(s) hosts, re-checks every redirect, caps size and time, and returns only iCal.

## Files

| File | What it holds |
|---|---|
| `index.html`, `styles.css`, `app.js` | app shell, leaf, dialogs, onboarding |
| `design.css`, `assets/` | the nine designs, fonts and artwork, ported 1:1 |
| `import.js` | ICS / zip / CSV import |
| `data/facts.js`, `data/peribahasa.js`, `data/holidays.js` | daily content and gazetted holidays for 2025–2027 |
| `sw.js`, `manifest.webmanifest`, `icons/` | offline support and install on a phone |
| `netlify/functions/ics-proxy.mjs`, `netlify.toml` | the `/api/ics` proxy for subscription links |
| `studies/` | the original nine HTML design studies, design notes and reference board |

## Run locally

```sh
npx http-server -p 8080 .   # then open http://localhost:8080/ (studies at /studies/)
```

Subscription links only work under `netlify dev` or when deployed, because they need the proxy function. File imports work anywhere.
