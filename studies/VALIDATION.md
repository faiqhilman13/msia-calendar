# Verification

Completed on 1 October 2026.

- Gallery and all nine HTML pages return HTTP 200 from the local static server.
- JavaScript syntax checked with Node.
- CSS asset paths exist, and fonts are local files with accompanying licenses.
- Selected 2 October and added a 19:15 appointment in all nine designs through browser controls. Every appointment appeared in its own agenda.
- Reloaded the gallery and verified all nine appointments persisted.
- Toggled appointment completion in Kalendar Kuda and verified the completed state.
- Entered a note in Rubber Stamp and verified it after reload.
- Switched the seven designs with view controls between day and month. Each full October month view has 31 selectable dates.
- Selected 31 October in Kalendar Kuda, advanced one month, and verified Monday, 30 November 2026. The selected day clamps to the shorter month's last day.
- Checked all nine individual pages at a 390 × 844 browser viewport. No horizontal page or screen overflow was reported.
- Compared the complete desktop gallery with the original board. Adjusted the artwork placement, ledger height, batik alignment, Sunday ink colors and dark-paper treatment.
- Replaced the original native reset confirmation with an HTML dialog after it stalled the in-app browser. Tested the replacement in Chrome: it opened, reset the demo, closed, restored all nine selected dates to 1 October, and removed the test appointment.

The calendar is a frontend prototype with local browser storage. There are no live calendar providers or account credentials to test. The final clean gallery was reviewed in Chrome. Mobile screenshots from the earlier interaction check show temporary test appointments; `screenshots/gallery-desktop.jpg` is the clean default gallery.
