# Kalendar

Nine HTML calendar studies based on the generated Malaysian calendar design board. Open `index.html` for the comparison gallery, or open one of the individual pages.

[Download the complete HTML pack](malaysian-calendar-html.zip), including the local artwork and fonts.

| No. | Design | HTML page |
| --- | --- | --- |
| 1 | Tear-off | `tear-off.html` |
| 2 | Kalendar Kuda | `kalendar-kuda.html` |
| 3 | Kopitiam Ledger | `kopitiam-ledger.html` |
| 4 | Kedai Runcit | `kedai-runcit.html` |
| 5 | Batik Margin | `batik-margin.html` |
| 6 | Postcard Month | `postcard-month.html` |
| 7 | Rubber Stamp | `rubber-stamp.html` |
| 8 | Riso Pop | `riso-pop.html` |
| 9 | Midnight Almanac | `midnight-almanac.html` |

All pages share `styles.css` and `app.js`. No build step or package installation is needed. Artwork and fonts are included locally in `assets/`, so the screens do not depend on external font or image requests.

Select a date to see its appointments. Use **+ Acara** to add an appointment, and click an appointment to mark it complete. The screens with **Hari / Bulan** controls also have day and month views. The ledger and riso studies initially show the compact week layouts from the reference; selecting **Bulan** opens a full month. The stamp study has an editable note field.

Each design stores its appointments, selection and notes separately in browser localStorage. The gallery and individual pages share data when served from the same local address. Browser behavior for storage on directly opened `file:` pages varies; use the local preview for consistent persistence across pages.

The calendar starts at Thursday, 1 October 2026. The demo reset returns all nine designs to that date in the gallery, or resets only the current design on an individual page. A confirmation appears before added appointments and notes are cleared.

This is a local frontend prototype. There is no calendar account connection, server database or device sync.

## Local preview

The development preview uses a static HTTP server at `http://localhost:4173/`. With Python installed, run this command from the project folder:

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

The bundled Python runtime was used to start the preview in this session.

## Design source and assets

`references/design-board.png` contains the original nine-cell ImageGen board. `DESIGN.md` records the layout, palette and typography extracted from each cell.

The built-in ImageGen tool generated four implementation assets: `print-atlas.png` (six decorative print illustrations), `postcard-street.png`, `batik-strip.png` and `paper-grain.png`. `assets/image-prompts.md` records their prompts. The decorative atlas contains artwork only; calendar screens are rendered as HTML.

Fonts are Barlow Condensed, DM Serif Display, IBM Plex Mono and IBM Plex Sans Condensed, downloaded from Google Fonts and accompanied by their licenses. Chinese and Tamil text use system fonts. Gregorian month and weekday translations come from the browser's `Intl.DateTimeFormat` implementation. No lunar or Hijri dates are inferred.
