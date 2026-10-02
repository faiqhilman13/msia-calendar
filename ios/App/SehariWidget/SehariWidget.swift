// Sehari Selembar widgets: today's sheet on the home screen, in the app's design, and on the lock screen.
// Reads the snapshot the app writes into the shared App Group (see WidgetBridgePlugin in AppDelegate.swift).
// The designs other than Tear-off are in SehariStyles.swift.
import SwiftUI
import WidgetKit

private let appGroup = "group.my.sehariselembar.app"

// MARK: - Data

struct DayEvent: Codable, Hashable {
    let time: String
    let title: String
}

/// One day from the app's snapshot. English leads; `day`, `month`, `holiday` and `maksud` are the Malay originals.
struct DayInfo: Codable {
    let date: String
    let d: Int
    let year: Int
    let weekday: Int
    let month: String
    let monthEn: String?
    let monthZh: String?
    let day: String
    let dayEn: String
    let dayZh: String?
    let red: Bool
    let holiday: String?
    let holidayEn: String?
    let peribahasa: String?
    let maksud: String?
    let maksudEn: String?
    let events: [DayEvent]?
}

extension DayInfo {
    /// 0-based month, read from the ISO date so it doesn't depend on the month's spelling.
    var monthIndex: Int { min(11, max(0, (Int(date.split(separator: "-").dropFirst().first ?? "") ?? 1) - 1)) }
    /// Snapshots from before the English switch have no monthEn.
    var monthName: String { monthEn ?? Sheet.monthsEn[monthIndex] }
    var holidayName: String? { [holidayEn, holiday].compactMap { $0 }.first { !$0.isEmpty } }
    var meaning: String? { [maksudEn, maksud].compactMap { $0 }.first { !$0.isEmpty } }
    var dayZhName: String { dayZh ?? Sheet.daysZh[min(6, max(0, weekday))] }
    var dayTa: String { Sheet.daysTa.indices.contains(weekday) ? Sheet.daysTa[weekday] : "" }
    var monthZhName: String { monthZh ?? Sheet.monthsZh[monthIndex] }
    /// Chinese, Malay and Tamil day names, as in the web sheet's translations row.
    var languages: String { [dayZhName, day, dayTa].filter { !$0.isEmpty }.joined(separator: "  ·  ") }
}

/// A public holiday's name in Malay and English.
struct Holiday: Codable {
    let ms: String?
    let en: String?
}

private struct Snapshot: Codable {
    let style: String?
    let days: [DayInfo]
    /// Public holidays by date, for a year from the 1st of the month. Snapshots from older versions have none.
    let holidays: [String: Holiday]?
}

enum Sheet {
    static let days = ["AHAD", "ISNIN", "SELASA", "RABU", "KHAMIS", "JUMAAT", "SABTU"]
    static let daysEn = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    static let daysZh = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
    static let months = ["JANUARI", "FEBRUARI", "MAC", "APRIL", "MEI", "JUN", "JULAI", "OGOS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DISEMBER"]
    static let monthsEn = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    static let monthsZh = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
    /// Tamil day names from the system's locale data, as the web app takes them from Intl ('ta-MY').
    static let daysTa: [String] = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ta_MY")
        return f.standaloneWeekdaySymbols ?? []
    }()

    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }

    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The date a "yyyy-MM-dd" key names.
    static func date(key: String) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }

    /// A sheet with no data from the app: the date is still right, and so is a holiday the app listed.
    static func plain(_ date: Date, holiday: Holiday? = nil) -> DayInfo {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let w = (c.weekday ?? 1) - 1, m = (c.month ?? 1) - 1
        return DayInfo(date: key(date), d: c.day ?? 1, year: c.year ?? 2026, weekday: w, month: months[m], monthEn: monthsEn[m],
                       monthZh: monthsZh[m], day: days[w], dayEn: daysEn[w], dayZh: daysZh[w], red: w == 0 || holiday != nil,
                       holiday: holiday?.ms, holidayEn: holiday?.en, peribahasa: nil, maksud: nil, maksudEn: nil, events: nil)
    }

    /// The app's design and its days, by date. Before the app has written anything: the Tear-off sheet and no days.
    static func load() -> (style: SheetStyle, days: [String: DayInfo]) {
        guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "snapshot"),
              let data = json.data(using: .utf8),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return (SheetStyle(id: nil), [:]) }
        var days = Dictionary(snap.days.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        // The snapshot's days run from today for 21 days. Holidays outside them still print red in the month
        // grids, and still head their sheet when the app hasn't been opened for a while.
        for (k, h) in snap.holidays ?? [:] where days[k] == nil {
            if let date = date(key: k) { days[k] = plain(date, holiday: h) }
        }
        return (SheetStyle(id: snap.style), days)
    }

    static func info(for date: Date, in days: [String: DayInfo]) -> DayInfo {
        days[key(date)] ?? plain(date)
    }

    static var sample: DayInfo {
        DayInfo(date: "2026-10-01", d: 1, year: 2026, weekday: 4, month: "OKTOBER", monthEn: "OCTOBER", monthZh: "十月",
                day: "KHAMIS", dayEn: "THURSDAY", dayZh: "星期四", red: false, holiday: nil, holidayEn: nil,
                peribahasa: "Bagai aur dengan tebing",
                maksud: "Hubungan yang rapat antara dua pihak yang saling membantu.",
                maksudEn: "Said of two people or groups who depend on and help each other.",
                events: [DayEvent(time: "09:00", title: "Meeting"), DayEvent(time: "18:30", title: "Family dinner")])
    }
}

// MARK: - Timeline: one entry per day, turning the page at midnight

struct SheetEntry: TimelineEntry {
    let date: Date
    let info: DayInfo
    /// The design the app is set to. Changing it writes a new snapshot and reloads the widgets.
    var style: SheetStyle = SheetStyle(id: nil)
    /// Every day the snapshot has, for the designs that show the week or the month.
    var days: [String: DayInfo] = [:]
}

struct SheetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SheetEntry {
        SheetEntry(date: Date(), info: Sheet.sample, style: Sheet.load().style)
    }

    func getSnapshot(in context: Context, completion: @escaping (SheetEntry) -> Void) {
        let (style, days) = Sheet.load()
        let info = context.isPreview && days.isEmpty ? Sheet.sample : Sheet.info(for: Date(), in: days)
        completion(SheetEntry(date: Date(), info: info, style: style, days: days))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SheetEntry>) -> Void) {
        let (style, days) = Sheet.load()
        let cal = Sheet.calendar
        let start = cal.startOfDay(for: Date())
        var entries = [SheetEntry(date: Date(), info: Sheet.info(for: Date(), in: days), style: style, days: days)]
        for i in 1...7 {
            if let day = cal.date(byAdding: .day, value: i, to: start) {
                entries.append(SheetEntry(date: day, info: Sheet.info(for: day, in: days), style: style, days: days))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Look: cream paper, red binding, DM Serif numeral (the Tear-off design in design.css)

private enum Ink {
    static let paper = Color(red: 0.949, green: 0.906, blue: 0.816)       // #f2e7d0
    static let red = Color(red: 0.749, green: 0.161, blue: 0.165)         // #bf292a
    static let binding = Color(red: 0.706, green: 0.169, blue: 0.169)     // #b42b2b
    static let ink = Color(red: 0.157, green: 0.145, blue: 0.118)         // #28251e
    static let rule = Color(red: 0.506, green: 0.471, blue: 0.384)        // #817862
    static let divider = Color(red: 0.667, green: 0.631, blue: 0.541)     // #aaa18a
    static let hole = Color(red: 0.247, green: 0.2, blue: 0.133)          // #3f3322
    static let holeShade = Color(red: 0.078, green: 0.047, blue: 0.031)   // #140c08
    static let holeEdge = Color(red: 0.898, green: 0.714, blue: 0.475)    // #e5b679
    static let stub = Color(red: 0.937, green: 0.89, blue: 0.8)           // #efe3cc
    static let shadow = Color(red: 0.22, green: 0.161, blue: 0.11)        // #38291c
}

/// The colours the sheet's text and rules are drawn in.
struct Palette {
    let ink: Color
    let red: Color
    let rule: Color
    let divider: Color

    static let paper = Palette(ink: Ink.ink, red: Ink.red, rule: Ink.rule, divider: Ink.divider)
    /// Without its paper (StandBy, the iPad lock screen, tinted home screens) the sheet is light ink on black.
    static let night = Palette(ink: Ink.paper, red: Color(red: 0.95, green: 0.45, blue: 0.4),
                               rule: Ink.paper.opacity(0.5), divider: Ink.paper.opacity(0.35))
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.paper
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// Fixed sizes: the sheets work out their layout from the widget's size, so Dynamic Type must not scale these.
private func serif(_ size: CGFloat) -> Font { .custom("DMSerifDisplay-Regular", fixedSize: size) }
private func georgia(_ size: CGFloat) -> Font { .custom("Georgia-Bold", fixedSize: size) }
/// IBM Plex Sans Condensed, the web sheet's text face.
private func condensed(_ size: CGFloat) -> Font { face(.ui, size) }

/// 20pt on most iPhones, 18pt on the SE.
private func bindingHeight(_ size: CGSize) -> CGFloat { min(22, max(16, min(size.width, size.height) * 0.122)) }

/// The torn stubs of earlier pages: the clip-path polygon of `.binding:after` in design.css.
struct TornEdge: Shape {
    private static let teeth: [(x: CGFloat, y: CGFloat)] = [
        (0, 0), (0.03, 0.5), (0.06, 0), (0.09, 0.8), (0.12, 0.3), (0.15, 0.6), (0.18, 0.2), (0.21, 1), (0.24, 0.2),
        (0.27, 0.7), (0.30, 0.35), (0.33, 0.75), (0.36, 0), (0.39, 0.5), (0.42, 0.3), (0.45, 0.8), (0.48, 0.15),
        (0.51, 0.4), (0.54, 0.2), (0.57, 1), (0.60, 0.2), (0.63, 0.8), (0.66, 0.05), (0.69, 0.6), (0.72, 0.25),
        (0.75, 0.8), (0.78, 0), (0.81, 0.55), (0.84, 0.2), (0.87, 0.8), (0.90, 0), (0.93, 0.75), (0.96, 0.3), (1, 0.8),
    ]

    func path(in rect: CGRect) -> Path {
        // The web sheet's teeth are about as wide as the strip is tall; wide widgets repeat the pattern to keep that.
        let repeats = max(1, (rect.width * 0.03 / max(rect.height, 1)).rounded())
        var p = Path()
        p.move(to: rect.origin)
        for r in 0..<Int(repeats) {
            for t in Self.teeth.dropFirst() {
                p.addLine(to: CGPoint(x: rect.minX + (CGFloat(r) + t.x) / repeats * rect.width, y: rect.minY + t.y * rect.height))
            }
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

/// The red binding with its two punched holes and the torn stubs hanging below it (`.binding` in design.css).
struct BindingStrip: View {
    let height: CGFloat
    private var stub: CGFloat { height * 0.3 }
    private var hole: CGFloat { height * 0.4 }

    var body: some View {
        Rectangle().fill(Ink.binding)
            .frame(height: height)
            .shadow(color: Ink.shadow.opacity(0.17), radius: 1.5, y: 1.5)
            .overlay(GeometryReader { g in
                ForEach([CGFloat(0.17), 0.83], id: \.self) { x in
                    Circle()
                        .fill(Ink.hole.shadow(.inner(color: Ink.holeShade.opacity(0.6), radius: hole * 0.12, x: hole * 0.06, y: hole * 0.18)))
                        .background(Circle().fill(Ink.holeEdge).offset(y: max(0.5, hole * 0.06)))
                        .frame(width: hole, height: hole)
                        // left: 17% and right: 17% place the holes' outer edges, not their centres.
                        .position(x: g.size.width * x + (x < 0.5 ? hole : -hole) / 2, y: (height - stub * 0.4) / 2)
                }
            })
            .overlay(TornEdge().fill(Ink.stub).frame(height: stub).offset(y: stub * 0.6), alignment: .bottom)
            .padding(.bottom, stub * 0.6)
    }
}

/// The design's paper with the grain pressed into it. Midnight's dark stock gets a faint light grain instead.
struct PaperBackground: View {
    var style: SheetStyle = .tearoff

    var body: some View {
        ZStack {
            Theme.paper(style)
            if style == .midnight {
                Image("PaperGrain").resizable().scaledToFill().opacity(0.08).blendMode(.screen)
            } else {
                Image("PaperGrain").resizable().scaledToFill().opacity(0.25).blendMode(.multiply)
            }
        }
    }
}

/// The DM Serif numeral. The font's line box is 1.37em tall but the digits only 0.65em, so the frame hugs the digits.
struct Numeral: View {
    let day: Int
    let size: CGFloat
    let color: Color

    var body: some View {
        Text("\(day)")
            .font(serif(size)).tracking(-size * 0.06)
            .lineLimit(1).minimumScaleFactor(0.5)
            .foregroundColor(color)
            .padding(.trailing, size * 0.06)   // tracking also pulls in the last digit; padding-right in design.css
            .fixedSize(horizontal: false, vertical: true)
            .offset(y: -size * 0.026)
            .frame(height: size * 0.74)
    }
}

/// Month, numeral and weekday, sized to fill the space the sheet gives them.
struct DateBlock: View {
    @Environment(\.palette) private var palette
    let info: DayInfo

    var body: some View {
        GeometryReader { g in
            // Label (0.12n), numeral (0.74n) and weekday (0.17n) stack to about 1.03n; leave some air for the spacers.
            // Two digits are about 1n wide.
            let n = min(max(g.size.height - 4, 0) / 1.03 * 0.92, g.size.width / 1.02)
            let label = min(13, max(9, n * 0.105))
            VStack(spacing: 0) {
                Text("\(info.monthName) \(String(info.year))")
                    .font(georgia(label)).tracking(label * 0.035)
                    .foregroundColor(palette.ink)
                Spacer(minLength: 2)
                Numeral(day: info.d, size: n, color: info.red ? palette.red : palette.ink)
                Spacer(minLength: 2)
                Text(info.dayEn)
                    .font(georgia(n * 0.15)).tracking(n * 0.024)
                    .padding(.leading, n * 0.024)   // balances the tracking after the last letter
                    .foregroundColor(info.red ? palette.red : palette.ink)
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct SmallSheet: View {
    let info: DayInfo
    let size: CGSize
    let paper: Bool

    var body: some View {
        VStack(spacing: 0) {
            if paper { BindingStrip(height: bindingHeight(size)) }
            DateBlock(info: info)
                .padding(.horizontal, 9).padding(.top, paper ? 5 : 12).padding(.bottom, paper ? 10 : 12)
        }
    }
}

/// The holiday's name on a band of the design's holiday colour (`.leaf-hol` in styles.css).
struct HolidayTag: View {
    @Environment(\.theme) private var theme
    let name: String
    var size: CGFloat = 11

    var body: some View {
        Text(name).font(face(.uiBold, size)).foregroundColor(theme.buttonInk)
            .lineLimit(1).minimumScaleFactor(0.8)
            .padding(.horizontal, size * 0.45).padding(.vertical, size * 0.1)
            .background(Rectangle().fill(theme.holiday))
    }
}

/// The peribahasa in Malay, then its meaning (in English when the app has one).
struct PeribahasaBlock: View {
    @Environment(\.palette) private var palette
    let info: DayInfo
    let quoteLines: Int
    let meaningLines: Int
    var quoteSize: CGFloat = 15
    var meaningSize: CGFloat = 11

    var body: some View {
        if let p = info.peribahasa, !p.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("“\(p)”").font(serif(quoteSize)).foregroundColor(palette.ink).lineLimit(quoteLines)
                if meaningLines > 0, let m = info.meaning {
                    Text(m).font(.system(size: meaningSize)).foregroundColor(palette.ink.opacity(0.72)).lineLimit(meaningLines)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The day's events as ruled rows (`.tearoff .agenda` and `.event-row` in design.css).
/// With `fill`, blank ruled rows carry on below the events to the bottom of the sheet, like a planner page.
struct Agenda: View {
    @Environment(\.palette) private var palette
    let events: [DayEvent]
    let rows: Int
    var fill = false

    var body: some View {
        let list = Array(events.prefix(rows))
        VStack(spacing: 0) {
            if list.isEmpty {
                ruled(Text("No events. Room for new plans.").font(condensed(12)).opacity(0.65)
                    .padding(.leading, 7)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading), below: fill)
            }
            ForEach(Array(list.enumerated()), id: \.offset) { i, e in
                ruled(HStack(spacing: 0) {
                    Text(e.time.isEmpty ? "All day" : e.time)
                        .font(condensed(12).monospacedDigit())
                        .frame(width: 38, alignment: .leading)
                        .padding(.leading, 6)
                    Rectangle().fill(palette.rule).frame(width: 1)
                    Text(e.title).font(condensed(12)).padding(.leading, 8)
                    Spacer(minLength: 4)
                }
                .frame(height: 21), below: fill || i < list.count - 1)
            }
            if fill { BlankRows() }
        }
        .lineLimit(1).minimumScaleFactor(0.8)
        .foregroundColor(palette.ink)
        .overlay(Rectangle().fill(palette.rule).frame(height: 1), alignment: .top)
    }

    /// A rule down the left of each row, and a fainter one under it when another row follows.
    private func ruled(_ row: some View, below: Bool) -> some View {
        row
            .overlay(Rectangle().fill(palette.rule).frame(width: 1), alignment: .leading)
            .overlay(Rectangle().fill(palette.rule.opacity(below ? 0.55 : 0)).frame(height: 1), alignment: .bottom)
    }
}

/// Empty agenda rows, with the time column carried down. Only whole rows, so no rule hangs below the last one.
private struct BlankRows: View {
    @Environment(\.palette) private var palette

    var body: some View {
        // No ideal height: ViewThatFits measures the sheet without these rows, then they take what's left.
        Color.clear
            .frame(minHeight: 0, idealHeight: 0, maxHeight: .infinity)
            .overlay(alignment: .top) {
                GeometryReader { g in
                    VStack(spacing: 0) {
                        ForEach(0..<Int(g.size.height / 21), id: \.self) { _ in
                            HStack(spacing: 0) {
                                Rectangle().fill(palette.rule).frame(width: 1)
                                Spacer(minLength: 0).frame(width: 43)
                                Rectangle().fill(palette.rule).frame(width: 1)
                                Spacer(minLength: 0)
                            }
                            .frame(height: 21)
                            .overlay(Rectangle().fill(palette.rule.opacity(0.55)).frame(height: 1), alignment: .bottom)
                        }
                    }
                }
            }
    }
}

struct MediumSheet: View {
    @Environment(\.palette) private var palette
    let info: DayInfo
    let size: CGSize
    let paper: Bool

    var body: some View {
        VStack(spacing: 0) {
            if paper { BindingStrip(height: bindingHeight(size)) }
            HStack(alignment: .top, spacing: 12) {
                DateBlock(info: info).frame(width: size.width * 0.34)
                Rectangle().fill(palette.divider).frame(width: 1)
                // As much of the peribahasa and its meaning as fits above the next event.
                ViewThatFits(in: .vertical) {
                    notes(quote: 2, meaning: 3)
                    notes(quote: 2, meaning: 2)
                    notes(quote: 2, meaning: 1)
                    notes(quote: 1, meaning: 1)
                    notes(quote: 1, meaning: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 14).padding(.top, paper ? 6 : 12).padding(.bottom, 12)
        }
    }

    private func notes(quote: Int, meaning: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(info.languages).font(condensed(11)).foregroundColor(palette.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
            if let h = info.holidayName { HolidayTag(name: h) }
            PeribahasaBlock(info: info, quoteLines: quote, meaningLines: meaning)
            Spacer(minLength: 0)
            if let e = info.events, !e.isEmpty { Agenda(events: e, rows: 1) }
        }
    }
}

/// Chinese, Malay and Tamil day names between two rules (`.tear-translations` in design.css).
struct LanguageRow: View {
    @Environment(\.palette) private var palette
    let info: DayInfo

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array([info.dayZhName, info.day, info.dayTa].enumerated()), id: \.offset) { _, name in
                // A spacer each side spreads the names like justify-content: space-around.
                Spacer(minLength: 4)
                Text(name)
                Spacer(minLength: 4)
            }
        }
        .font(condensed(12)).foregroundColor(palette.ink)
        .lineLimit(1).minimumScaleFactor(0.8)
        .padding(.vertical, 4)
        .overlay(Rectangle().fill(palette.rule).frame(height: 2), alignment: .top)
        .overlay(Rectangle().fill(palette.rule).frame(height: 1), alignment: .bottom)
    }
}

/// The month at a glance, Monday first, with Sundays and public holidays in red and today underlined.
struct MiniMonth: View {
    @Environment(\.palette) private var palette
    let info: DayInfo
    let days: [String: DayInfo]
    let rowHeight: CGFloat
    private static let heads = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let cal = Sheet.calendar
        let first = cal.date(from: DateComponents(year: info.year, month: info.monthIndex + 1, day: 1)) ?? Date()
        let offset = (cal.component(.weekday, from: first) + 5) % 7
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let cells = Array(repeating: 0, count: offset) + Array(1...count)
        let holidays = Set((1...count).filter { days[String(format: "%04d-%02d-%02d", info.year, info.monthIndex + 1, $0)]?.red == true })
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        let size = min(11, rowHeight * 0.72)
        LazyVGrid(columns: cols, spacing: 0) {
            // One ForEach so every cell has its own id: LazyVGrid leaves cells with repeated ids blank.
            ForEach(0..<(7 + cells.count), id: \.self) { i in
                let n = i < 7 ? 0 : cells[i - 7]
                Text(i < 7 ? Self.heads[i] : n == 0 ? " " : "\(n)")
                    .font(serif(i < 7 ? size - 2 : size))
                    .foregroundColor(i % 7 == 6 || n == info.d || holidays.contains(n) ? palette.red : palette.ink)
                    .underline(n == info.d, color: palette.red)
                    .fixedSize()
                    .frame(height: rowHeight)
            }
        }
    }
}

struct LargeSheet: View {
    @Environment(\.palette) private var palette
    let info: DayInfo
    let days: [String: DayInfo]
    let size: CGSize
    let paper: Bool

    var body: some View {
        let top = size.height * 0.36
        VStack(spacing: 0) {
            if paper { BindingStrip(height: bindingHeight(size)) }
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    DateBlock(info: info).frame(width: size.width * 0.4)
                    Rectangle().fill(palette.divider).frame(width: 1)
                    VStack(spacing: 4) {
                        MiniMonth(info: info, days: days, rowHeight: min(16, (top - 18) / 7))
                        Text("\(info.month)  ·  \(info.monthZhName)")
                            .font(georgia(10)).tracking(0.5).foregroundColor(palette.ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
                .frame(height: top)
                LanguageRow(info: info)
                // As much of the peribahasa and its meaning as fits above the day's events.
                ViewThatFits(in: .vertical) {
                    notes(2, 3, 3)
                    notes(2, 2, 3)
                    notes(2, 2, 2)
                    notes(2, 1, 2)
                    notes(2, 2, 1)
                    notes(2, 1, 1)
                    notes(1, 1, 1)
                    notes(1, 0, 1)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, 16).padding(.top, paper ? 6 : 14).padding(.bottom, 14)
        }
    }

    private func notes(_ quote: Int, _ meaning: Int, _ events: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let h = info.holidayName { HolidayTag(name: h) }
            // A little larger on taller sheets.
            PeribahasaBlock(info: info, quoteLines: quote, meaningLines: meaning,
                            quoteSize: min(19, max(15, size.height * 0.052)),
                            meaningSize: min(12.5, max(11, size.height * 0.034)))
            Agenda(events: info.events ?? [], rows: events, fill: true)
        }
    }
}

/// The Tear-off design: binding strip, numeral, peribahasa and agenda.
struct TearOffSheet: View {
    let ctx: SheetContext

    var body: some View {
        let paper = ctx.theme.onPaper
        Group {
            switch ctx.family {
            case .systemMedium: MediumSheet(info: ctx.info, size: ctx.size, paper: paper)
            case .systemLarge, .systemExtraLarge: LargeSheet(info: ctx.info, days: ctx.days, size: ctx.size, paper: paper)
            default: SmallSheet(info: ctx.info, size: ctx.size, paper: paper)
            }
        }
        .environment(\.palette, paper ? .paper : .night)
    }
}

// MARK: - Lock screen

/// Sits after the system's own date ("Thu 1") above the lock-screen clock, so it leaves the date out.
struct LockInline: View {
    let info: DayInfo
    var body: some View {
        Text(info.holidayName ?? info.peribahasa ?? info.monthName.capitalized)
    }
}

struct LockCircular: View {
    let info: DayInfo
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(String(info.dayEn.prefix(3))).font(.system(size: 10, weight: .semibold))
                Text("\(info.d)").font(serif(26))
            }
        }
    }
}

struct LockRectangular: View {
    let info: DayInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(info.dayEn) \(info.d) \(String(info.monthName.prefix(3)))").font(.system(size: 13, weight: .bold)).widgetAccentable()
            if let e = info.events?.first {
                Text("\(e.time.isEmpty ? "All day" : e.time)  \(e.title)").font(.system(size: 12)).lineLimit(1)
            }
            if let p = info.peribahasa {
                Text(p).font(.system(size: 12)).lineLimit(info.events?.isEmpty == false ? 1 : 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct SehariWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: SheetEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            LockInline(info: entry.info).widgetBackground { Color.clear }
        case .accessoryCircular:
            LockCircular(info: entry.info).widgetBackground { Color.clear }
        case .accessoryRectangular:
            LockRectangular(info: entry.info).widgetBackground { Color.clear }
        default:
            PaperCheck { shown in
                let theme = Theme.of(entry.style, onPaper: shown && renderingMode == .fullColor)
                GeometryReader { g in
                    StyledSheet(ctx: SheetContext(info: entry.info, days: entry.days, family: family, size: g.size, theme: theme))
                        .frame(width: g.size.width, height: g.size.height, alignment: .top)
                }
                .environment(\.theme, theme)
            }
            .widgetBackground { PaperBackground(style: entry.style) }
        }
    }
}

/// Tells its content whether the system draws the widget's paper. StandBy and the iPad lock screen leave it out (iOS 17+).
struct PaperCheck<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            ContainerBackgroundCheck(content: content)
        } else {
            content(true)
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct ContainerBackgroundCheck<Content: View>: View {
    @Environment(\.showsWidgetContainerBackground) private var shown
    let content: (Bool) -> Content

    var body: some View { content(shown) }
}

extension View {
    /// iOS 17 wants the background declared as the widget's container background.
    @ViewBuilder
    func widgetBackground<B: View>(@ViewBuilder _ background: () -> B) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget, content: background)
        } else {
            self.background(background())
        }
    }
}

extension WidgetConfiguration {
    /// Let the paper and binding run to the widget's edges on iOS 17+.
    func fullBleed() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return contentMarginsDisabled()
        } else {
            return self
        }
    }
}

struct SehariTearOffWidget: Widget {
    /// The first version only drew the Tear-off design. The kind keeps that name so placed widgets stay put.
    let kind = "SehariTearOff"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SheetProvider()) { entry in
            SehariWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Sheet")
        .description("Today's page in the style you picked in the app: the date, a peribahasa and your next event.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        .fullBleed()
    }
}

@main
struct SehariWidgets: WidgetBundle {
    var body: some Widget {
        SehariTearOffWidget()
    }
}
