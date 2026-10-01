# Sehari Selembar

A nostalgic Malaysian calendar app with nine styles. Every day has a **Did You Know?** fact about Malaysia and a **peribahasa** (Malay proverb) with its English meaning, the Malay maksud and an example sentence. You can keep your own appointments or import them from Google Calendar, Apple Calendar, Outlook or Notion.

The app is in English. Dates also give the day in Malay, Chinese and Tamil, and peribahasa stay in Malay. The Malay shop-sign lettering in the artwork is part of the designs and stays as it is.

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

On first launch you pick a style from a gallery of live previews. The **Style** button reopens it.

## What the app adds around each screen

- **The daily leaf.** A second page set in the chosen design's paper, ink and type. It holds:
  - the date, Hijri and Chinese lunar dates, and any public holiday
  - the fact and peribahasa, with a reroll button for each
  - notes, and a **Manage events** list to edit or delete your events
- **Animations.** Moving months lifts the page with a curl. Moving days on a day page (Tear-off, or any Day view) tears the sheet off.
- **Holidays.** Sundays and public holidays print in the design's red.
- **One shared agenda.** Events are shared across all nine styles. Tap an event row to mark it done.

## Import

**Import** accepts:

- **Files:** `.ics`, Google Calendar's export `.zip` (no need to unzip) and Notion CSV exports. These come from:
  - Google Calendar: Settings → Import & export → Export
  - Apple Calendar: File → Export
  - Outlook: File → Save Calendar
  - Notion: Export → Markdown & CSV
- **Subscription links:** `https://` or `webcal://` iCal links, such as Google's secret iCal address, iCloud public calendars and Outlook published calendars. Each one re-syncs when the app opens, at most every 3 hours.

The parser, `import.js`, handles:
- timezones, including Outlook's Windows zone names
- recurring events: daily, weekly, monthly and yearly, with COUNT/UNTIL/INTERVAL/BYDAY/BYMONTHDAY, EXDATE and RECURRENCE-ID
- multi-day all-day events and cancelled events
- Notion date formats such as `October 1, 2026 9:00 AM (GMT+8)` and `A → B` ranges

Imported calendars are stored separately from your own events, so a re-sync never overwrites them. Removing a calendar removes its events.

Subscription links are fetched by `netlify/functions/ics-proxy.mjs` at `/api/ics`, because most calendar hosts don't allow browsers to fetch them directly. It accepts only public http(s) hosts, re-checks every redirect, caps size and time, and returns only iCal.

## iPhone and Android app, with widgets

The same web app is packaged with [Capacitor](https://capacitorjs.com) as a native app for the App Store and Play Store. The native apps add home screen and lock screen widgets, which a web app can't offer.

**The "Tear-off Calendar" widget** shows today's Tear-off sheet: a red binding, a DM Serif numeral and the day in English. Sundays and public holidays print in red. The bigger sizes add the day in Chinese, Malay and Tamil, the peribahasa with its English meaning, and the day's events. The large size also has the month at a glance.
- **iPhone:**
  - home screen: small, medium and large sizes
  - lock screen: inline, circular and rectangular slots
  - StandBy mode
- **Android:** a resizable home screen widget, which can also go on the lock screen where the phone supports it.

### How the widgets get their data

The app writes a snapshot of the next 21 days through the `WidgetBridge` plugin:
- the date in every language, red days and holidays
- the peribahasa and fact
- the next events
- the chosen style

Saves are batched and also run when the app goes to the background. The widgets turn the page at midnight from that snapshot. With no snapshot yet, they still show the correct date.

| Platform | Files |
|---|---|
| iOS | `ios/App/App/AppDelegate.swift` holds `WidgetBridgePlugin` and `MainViewController`. `ios/App/SehariWidget/` is the SwiftUI widget extension. |
| Android | `android/app/src/main/java/my/sehariselembar/app/` holds `WidgetBridgePlugin`, `WidgetData` and `TearOffWidget`. Layouts are in `res/layout/widget_tearoff_*.xml`. |

Subscription links in the native app are fetched natively (`CapacitorHttp`), so they don't need the `/api/ics` proxy.

### Build

```sh
npm install
npm run sync        # copies the web app into www/ and syncs it into ios/ and android/
npm run android     # opens Android Studio: Run, or Build > Generate Signed Bundle for the Play Store
npm run ios         # opens Xcode (on a Mac)
```

**iOS, one-time setup:**
1. Put your Apple Developer team ID in `ios/App/Signing.local.xcconfig`, a git-ignored file next to `Signing.xcconfig`:
   ```
   DEVELOPMENT_TEAM = ABCDE12345
   ```
   Both targets read it through `ios/App/Signing.xcconfig`, so your ID never lands in `project.pbxproj`. Leave Team unset in Xcode's Signing & Capabilities tab, because picking one there writes it into the project. Simulator builds don't need a team.
2. Sign in to Xcode with the same Apple ID (Xcode → Settings → Accounts) so it can make the provisioning profiles.
3. **App Groups** already lists `group.my.sehariselembar.app` on both targets, through `App/App.entitlements` and `SehariWidget/SehariWidget.entitlements`. Xcode registers it with your team the first time you build for a phone.
4. Run the app once on a phone so the widgets get their first snapshot. Then long-press the home screen → **Edit** → **Add Widget**, or the lock screen → **Customize**, and pick Sehari Selembar.

A free Apple ID (Personal Team) can put the app and widgets on your own phone. Its profiles expire after 7 days, and it can register only 10 App IDs a week. TestFlight and the App Store need a paid Apple Developer Program membership.

The widget target was added by `scripts/add-ios-widget.rb` (uses the `xcodeproj` gem). It is safe to re-run. The widget needs iOS 16 for the lock screen, while the app supports iOS 15. The widget's deployment target lives in `ios/App/SehariWidget/SehariWidget.xcconfig`, not in `project.pbxproj`, because `npx cap sync` copies the first deployment target it finds there into `CapApp-SPM/Package.swift`.

**Before you publish:**
- The bundle id `my.sehariselembar.app` is set in `capacitor.config.json`. Change it there and in the two native projects before the first upload if you want a different one.
- App icons and splash screens are still Capacitor's placeholders. `npx @capacitor/assets generate` can make them from `icons/`.

## Files

| File | What it holds |
|---|---|
| `index.html`, `styles.css`, `app.js` | app shell, leaf, dialogs, onboarding |
| `design.css`, `assets/` | the nine designs, fonts and artwork, ported 1:1 |
| `import.js` | ICS / zip / CSV import |
| `data/facts.js`, `data/peribahasa.js`, `data/holidays.js` | daily content and gazetted holidays for 2025–2027 |
| `sw.js`, `manifest.webmanifest`, `icons/` | offline support and install on a phone |
| `netlify/functions/ics-proxy.mjs`, `netlify.toml` | the `/api/ics` proxy for subscription links |
| `package.json`, `capacitor.config.json`, `scripts/`, `ios/`, `android/` | native app packaging and widgets |
| `studies/` | the original nine HTML design studies, design notes and reference board |

## Run locally

```sh
npx http-server -p 8080 .   # then open http://localhost:8080/ (studies at /studies/)
```

Subscription links only work under `netlify dev` or when deployed, because they need the proxy function. File imports work anywhere.
