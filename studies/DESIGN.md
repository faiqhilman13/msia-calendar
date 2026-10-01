# Malaysian calendar HTML studies

The generated nine-cell board in `references/design-board.png` is the visual source. The numbering and names follow the board from left to right, then top to bottom.

The screens use a 390 px wide mobile canvas. Paper grain, ink colors, thin printed rules and display typography carry the shared calendar language. Dates, headings, events and controls are HTML. Artwork is separate raster media. Calendar data starts on Thursday, 1 October 2026, with Monday as the first grid column.

| Screen | Composition | Typography | Palette and details |
| --- | --- | --- | --- |
| 1. Tear-off | Red binding strip; date dominates the upper half; weekday, miniature month and ruled agenda follow | Heavy serif numeral, slab-like uppercase weekday, serif month, compact sans agenda | Cream #f3e7ce, vermilion #bc2829, brown-black #29241b; torn binding edge and printed divider |
| 2. Kalendar Kuda | Double-rule masthead with horse; blue month heading; large ruled month grid; short agenda and bottom controls | Compressed red display masthead, blue condensed month, bold serif numbers | Warm ivory, red #c62926, cobalt #154c75; grid lines are red and Sundays red |
| 3. Kopitiam Ledger | Green sponsor-style coffee heading; narrow month navigator; dated ledger rows; controls below | Strong green serif heading, small sans utility text, serif dates | Milk cream #e9dfc3, green #1f5039, brown #403829; thin ledger rules and red circle around selected date |
| 4. Kedai Runcit | Yellow sponsor advertisement; goods illustration; oversized month; dense grid; receipt agenda | Heavy condensed red masthead, compact green condensed month, strong date numbers | Butter yellow #f3d862, red #c5272b, green #164c36; perforated receipt boundary |
| 5. Batik Margin | Large two-line month; open month grid; generous blank paper; ruled events; vertical batik strip at right | Editorial serif month and numerals, quiet compact sans agenda | Ecru #f4e8ce, indigo #18354f, turmeric #dda33e; filled ochre selected day |
| 6. Postcard Month | Vintage street illustration across upper third; large serif month; small ruled grid; illustrated footer | Heavy editorial serif month and dates, condensed sans agenda | Seafoam, peach #df8d74, ecru; postcard illustration in an offset-print treatment |
| 7. Rubber Stamp | Form metadata and weekday stamp; numeric date; vertical appointment timeline; ruled note space; tiny month and seal | Distressed-looking condensed numbers, monospace metadata, sober sans event text | Offwhite #efe4cd, burgundy #8e2935; squared controls, double printed border |
| 8. Riso Pop | Huge asymmetric OKT and year; hibiscus; compact week rows; selected day; skyline artwork beside agenda | Heavy compressed grotesk masthead, blue sans dates and labels | Ivory, coral #ed4a45, ultramarine #285cac; two-ink artwork and red rules |
| 9. Midnight Almanac | Dark month header; fine-ruled month; large selected-day block; short agenda and bottom controls | Cream editorial serif calendar, condensed sans weekday, crisp sans body | Charcoal #242420, warm cream #e7d3a7, vermilion #ce3e29, brass #b58c48; thin gold engraved motifs |

Interaction scope: select a date, switch day/month where shown, navigate months or weeks, add an appointment, mark it complete, and write a note in the stamp study. Each study saves its own sample data in browser localStorage. The gallery links to nine individual HTML pages. No backend or external accounts.

Keep the reference layout as the default. Any expanded day view or added event can increase screen height so text remains readable.
