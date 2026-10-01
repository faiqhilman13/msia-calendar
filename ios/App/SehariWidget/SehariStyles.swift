// The widget in each of the app's designs. The Tear-off sheet itself is in SehariWidget.swift.
// Papers, inks, faces and frames follow design.css (each design's month screen) and styles.css (the daily leaf).
import SwiftUI
import UIKit
import WidgetKit

// MARK: - Designs

/// The app's designs, by the ids in STYLES (app.js) that the app writes into the widget snapshot.
enum SheetStyle: String, CaseIterable {
    case tearoff, kuda, kopitiam, runcit, batik, postcard, stamp, riso, midnight

    /// Unknown or missing ids get the design the app starts with: `applyStyle(saved || 'kuda')` in app.js.
    init(id: String?) { self = id.flatMap(SheetStyle.init(rawValue:)) ?? .kuda }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xff) / 255, green: Double(hex >> 8 & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255, opacity: opacity)
    }
}

/// The bundled faces (UIAppFonts in Info.plist), and Georgia from the system.
enum Face: String {
    case serif = "DMSerifDisplay-Regular"
    case georgia = "Georgia-Bold"
    case georgiaItalic = "Georgia-Italic"
    case semibold = "BarlowCondensed-SemiBold"
    case bold = "BarlowCondensed-Bold"
    case extraBold = "BarlowCondensed-ExtraBold"
    case black = "BarlowCondensed-Black"
    case ui = "IBMPlexSansCond-Medium"
    case uiBold = "IBMPlexSansCond-SemiBold"
    case mono = "IBMPlexMono-Regular"
}

/// Fixed sizes: the sheets lay themselves out from the widget's size, so Dynamic Type must not scale them.
func face(_ face: Face, _ size: CGFloat) -> Font { .custom(face.rawValue, fixedSize: size) }

/// A design's paper and inks: the custom properties on `.leaf[data-theme]` in styles.css.
struct Theme {
    let style: SheetStyle
    /// False when the system leaves the paper out (StandBy, tinted home screens): the paper's colour becomes
    /// the ink, on black, and the pictures are left out. Midnight is dark already and keeps its inks.
    var onPaper = true
    let paper: Color
    var ink: Color
    var accent: Color
    /// Sundays and holidays.
    var red: Color
    var line: Color
    var divider: Color
    /// `.leaf-card-head h3`
    var kicker: Color
    /// `.leaf-hol`
    var holiday: Color
    /// `--button-ink`: text on the accent.
    var buttonInk: Color

    static func paper(_ style: SheetStyle) -> Color {
        switch style {
        case .tearoff: return Color(hex: 0xf2e7d0)
        case .kuda: return Color(hex: 0xf4e8ce)
        case .kopitiam: return Color(hex: 0xe9e0c6)
        case .runcit: return Color(hex: 0xf4d866)
        case .batik: return Color(hex: 0xf2e7cf)
        case .postcard: return Color(hex: 0xf2e1bb)
        case .stamp: return Color(hex: 0xeee4ce)
        case .riso: return Color(hex: 0xf6ead3)
        case .midnight: return Color(hex: 0x25251f)
        }
    }

    static func of(_ style: SheetStyle, onPaper: Bool) -> Theme {
        let p = paper(style), cream = Color(hex: 0xfff4df)
        var t: Theme
        switch style {
        case .tearoff:
            let red = Color(hex: 0xbf292a)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x28251e), accent: red, red: red, line: Color(hex: 0x817862),
                      divider: Color(hex: 0xaaa18a), kicker: red, holiday: red, buttonInk: p)
        case .kuda:
            let red = Color(hex: 0xc4312b)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x14486f), accent: red, red: red, line: Color(hex: 0xcc5543),
                      divider: Color(hex: 0xcc5543), kicker: red, holiday: red, buttonInk: cream)
        case .kopitiam:
            let green = Color(hex: 0x24553c)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x234d37), accent: green, red: Color(hex: 0xb52c2f),
                      line: Color(hex: 0x8a987a), divider: Color(hex: 0x8a987a), kicker: Color(hex: 0xad302d), holiday: green,
                      buttonInk: cream)
        case .runcit:
            let red = Color(hex: 0xc92d31)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x134d37), accent: red, red: red, line: Color(hex: 0xb48032),
                      divider: Color(hex: 0xb48032), kicker: red, holiday: red, buttonInk: Color(hex: 0xffebc6))
        case .batik:
            let navy = Color(hex: 0x17364d)
            t = Theme(style: style, paper: p, ink: navy, accent: Color(hex: 0xd9a03b), red: Color(hex: 0xb6382f),
                      line: Color(hex: 0xa19372), divider: Color(hex: 0xa19372), kicker: navy, holiday: navy,
                      buttonInk: Color(hex: 0xfff6e4))
        case .postcard:
            let coral = Color(hex: 0xdd8875), red = Color(hex: 0xb5322c)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x17384c), accent: coral, red: red, line: Color(hex: 0xb79e79),
                      divider: Color(hex: 0xb79e79), kicker: red, holiday: coral, buttonInk: cream)
        case .stamp:
            let maroon = Color(hex: 0x943340)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x853340), accent: maroon, red: maroon, line: Color(hex: 0xa87069),
                      divider: Color(hex: 0xa87069), kicker: maroon, holiday: maroon, buttonInk: cream)
        case .riso:
            let coral = Color(hex: 0xe94a47)
            t = Theme(style: style, paper: p, ink: Color(hex: 0x285db0), accent: coral, red: coral, line: Color(hex: 0xe76560),
                      divider: Color(hex: 0xe76560), kicker: coral, holiday: coral, buttonInk: cream)
        case .midnight:
            let red = Color(hex: 0xd6412b), copper = Color(hex: 0xa58147)
            t = Theme(style: style, paper: p, ink: Color(hex: 0xead4a7), accent: red, red: red, line: copper, divider: copper,
                      kicker: Color(hex: 0xc9a35d), holiday: red, buttonInk: Color(hex: 0xfff0d4))
        }
        guard !onPaper else { return t }
        t.onPaper = false
        if style != .midnight {
            let night: Color
            switch style {
            case .batik: night = Color(hex: 0xe2ad4f)
            case .postcard: night = Color(hex: 0xeb9a86)
            case .stamp: night = Color(hex: 0xe07d8a)
            case .tearoff: night = Color(red: 0.95, green: 0.45, blue: 0.4)
            default: night = Color(hex: 0xef6a5f)
            }
            t.ink = p; t.accent = night; t.red = night; t.kicker = night; t.holiday = night
            t.line = p.opacity(0.5); t.divider = p.opacity(0.35)
            t.buttonInk = style == .tearoff ? p : .black
        }
        return t
    }

    /// The heading face (`--head`), which the daily leaf also sets the peribahasa in.
    func head(_ size: CGFloat) -> Font {
        switch style {
        case .tearoff, .kopitiam: return face(.georgia, size)
        case .kuda: return face(.extraBold, size)
        case .runcit, .riso: return face(.black, size)
        case .stamp: return face(.bold, size)
        case .batik, .postcard, .midnight: return face(.serif, size)
        }
    }

    /// `--head-track`, in em.
    var headTrack: CGFloat {
        switch style {
        case .tearoff: return 0.02
        case .kuda, .runcit: return -0.02
        case .kopitiam, .stamp, .riso: return -0.03
        case .batik, .postcard: return -0.05
        case .midnight: return -0.035
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.of(.tearoff, onPaper: true)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// What a design needs to draw one sheet.
struct SheetContext {
    let info: DayInfo
    let days: [String: DayInfo]
    let family: WidgetFamily
    let size: CGSize
    let theme: Theme

    /// The designs are drawn at an iPhone 17's widget sizes (small 164, medium 348 × 164, large 348 × 364); k scales them.
    var k: CGFloat {
        switch family {
        case .systemSmall: return min(size.width, size.height) / 164
        case .systemMedium: return min(size.width / 348, size.height / 164)
        default: return min(size.width / 348, size.height / 364)
        }
    }

    /// Pictures only on paper: tinted and vibrant renderings would flatten them into blocks.
    var art: Bool { theme.onPaper }
}

/// The home-screen sheet in whichever design the app is set to.
struct StyledSheet: View {
    let ctx: SheetContext

    var body: some View {
        switch ctx.theme.style {
        case .tearoff: TearOffSheet(ctx: ctx)
        case .kuda: KudaSheet(ctx: ctx)
        case .kopitiam: KopitiamSheet(ctx: ctx)
        case .runcit: RuncitSheet(ctx: ctx)
        case .batik: BatikSheet(ctx: ctx)
        case .postcard: PostcardSheet(ctx: ctx)
        case .stamp: StampSheet(ctx: ctx)
        case .riso: RisoSheet(ctx: ctx)
        case .midnight: MidnightSheet(ctx: ctx)
        }
    }
}

// MARK: - Calendar

/// A day in a month grid, week ledger or two-week strip.
struct CalDay {
    let d: Int
    /// 0 is Sunday, as in the snapshot.
    let weekday: Int
    let inMonth: Bool
    let today: Bool
    let red: Bool
    /// The app's data for the day, when the snapshot has it (today and the next 20 days).
    let info: DayInfo?
}

extension Sheet {
    static let monthsTa: [String] = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ta_MY")
        return f.standaloneMonthSymbols ?? []
    }()

    static func date(of info: DayInfo) -> Date {
        calendar.date(from: DateComponents(year: info.year, month: info.monthIndex + 1, day: info.d)) ?? Date()
    }

    /// `count` weeks, Monday first, from the week that holds `start`. Days in other months than `info`'s are marked.
    static func weeks(from start: Date, count: Int, info: DayInfo, days: [String: DayInfo]) -> [[CalDay]] {
        let cal = calendar
        let today = date(of: info)
        let back = (cal.component(.weekday, from: start) + 5) % 7
        let monday = cal.date(byAdding: .day, value: -back, to: cal.startOfDay(for: start)) ?? start
        return (0..<count).map { w in
            (0..<7).map { i in
                let date = cal.date(byAdding: .day, value: w * 7 + i, to: monday) ?? monday
                let c = cal.dateComponents([.month, .day, .weekday], from: date)
                let weekday = (c.weekday ?? 1) - 1
                let isToday = cal.isDate(date, inSameDayAs: today)
                let known = isToday ? info : days[key(date)]
                return CalDay(d: c.day ?? 1, weekday: weekday, inMonth: c.month == info.monthIndex + 1, today: isToday,
                              red: known?.red ?? (weekday == 0), info: known)
            }
        }
    }

    /// The weeks of the month that holds `info`.
    static func monthWeeks(_ info: DayInfo, days: [String: DayInfo]) -> [[CalDay]] {
        let cal = calendar
        let first = cal.date(from: DateComponents(year: info.year, month: info.monthIndex + 1, day: 1)) ?? date(of: info)
        let lead = (cal.component(.weekday, from: first) + 5) % 7
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        return weeks(from: first, count: (lead + count + 6) / 7, info: info, days: days)
    }
}

extension DayInfo {
    var monthTa: String { Sheet.monthsTa.indices.contains(monthIndex) ? Sheet.monthsTa[monthIndex] : "" }
    var monthYear: String { "\(monthName) \(year)" }
    /// "FRIDAY, 2 OCTOBER 2026": the day's caption under the month screens (`.date-caption`).
    var caption: String { "\(dayEn), \(d) \(monthName) \(year)" }
    /// The month in Chinese, Malay and Tamil, as under each design's month heading.
    var monthLanguages: [String] { [monthZhName, month, monthTa].filter { !$0.isEmpty } }
}

// MARK: - Shared pieces

/// Text trimmed to its capitals: the frame runs from the baseline to the cap height, so big type sits tight.
struct CapText: View {
    let text: String
    let face: Face
    let size: CGFloat
    let color: Color
    /// In em, like CSS letter-spacing.
    var tracking: CGFloat = 0
    /// How far the text may shrink to fit its width; 1 keeps it at its size.
    var shrink: CGFloat = 1

    var body: some View {
        let m = UIFont(name: face.rawValue, size: size) ?? .systemFont(ofSize: size)
        Text(text).font(.custom(face.rawValue, fixedSize: size)).tracking(tracking * size)
            .foregroundColor(color)
            .lineLimit(1).minimumScaleFactor(shrink)
            .fixedSize(horizontal: shrink >= 1, vertical: true)
            .frame(height: m.capHeight)
            .offset(y: (m.capHeight - m.ascender - m.descender) / 2)
    }
}

/// One of the print atlas's drawings, left out when there's no paper under it.
struct Art: View {
    let name: String
    let width: CGFloat
    var shown = true

    var body: some View {
        if shown {
            Image(name).resizable().scaledToFit().frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A border with an outline inside it, in the same ink (`border` plus `outline` with a negative `outline-offset`).
struct DoubleFrame: View {
    let color: Color
    var outer: CGFloat = 1
    var inner: CGFloat = 1
    var inset: CGFloat = 3
    var gap: CGFloat = 4

    var body: some View {
        ZStack {
            ContainerRelativeShape().inset(by: inset).strokeBorder(color, lineWidth: outer)
            ContainerRelativeShape().inset(by: inset + outer + gap).strokeBorder(color, lineWidth: inner)
        }
    }
}

struct Rule: View {
    let color: Color
    var weight: CGFloat = 1

    var body: some View { Rectangle().fill(color).frame(height: weight) }
}

/// The month in Chinese, Malay and Tamil.
struct MonthLanguages: View {
    @Environment(\.theme) private var theme
    let info: DayInfo
    let size: CGFloat
    var tracking: CGFloat = 0.04
    var spacing: CGFloat = 1

    var body: some View {
        HStack(spacing: size * spacing) {
            ForEach(info.monthLanguages, id: \.self) { Text($0) }
        }
        .font(face(.uiBold, size)).tracking(size * tracking)
        .foregroundColor(theme.ink)
        .lineLimit(1).minimumScaleFactor(0.7)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The peribahasa as on the daily leaf (`.leaf-proverb`): the heading face, its quote marks in the accent.
struct Proverb: View {
    @Environment(\.theme) private var theme
    let text: String
    let size: CGFloat
    var lines = 2

    var body: some View {
        let open = Text("“").foregroundColor(theme.accent)
        let close = Text("”").foregroundColor(theme.accent)
        (open + Text(text).foregroundColor(theme.ink) + close)
            .font(theme.head(size)).tracking(theme.headTrack * size)
            .lineLimit(lines)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct EventLine: View {
    @Environment(\.theme) private var theme
    let event: DayEvent
    let size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.6) {
            Text(event.time.isEmpty ? "All day" : event.time).font(face(.uiBold, size).monospacedDigit())
            Text(event.title).font(face(.ui, size))
        }
        .foregroundColor(theme.ink)
        .lineLimit(1)
    }
}

/// The daily leaf cut to fit: the holiday, the peribahasa and its meaning, then the next events.
struct LeafNotes: View {
    @Environment(\.theme) private var theme
    let info: DayInfo
    let quoteSize: CGFloat
    let bodySize: CGFloat
    var events = 1
    var spacing: CGFloat = 4

    var body: some View {
        ViewThatFits(in: .vertical) {
            notes(2, 3, events)
            notes(2, 2, events)
            notes(2, 1, events)
            notes(1, 1, events)
            notes(2, 0, events)
            notes(1, 0, events)
            notes(1, 0, min(events, 1))
            notes(1, 0, 0)
        }
    }

    private func notes(_ quote: Int, _ meaning: Int, _ rows: Int) -> some View {
        let list = Array((info.events ?? []).prefix(rows))
        return VStack(alignment: .leading, spacing: spacing) {
            if let h = info.holidayName { HolidayTag(name: h, size: bodySize) }
            if let p = info.peribahasa, !p.isEmpty {
                Proverb(text: p, size: quoteSize, lines: quote)
                if meaning > 0, let m = info.meaning {
                    Text(m).font(face(.ui, bodySize)).foregroundColor(theme.ink.opacity(0.75))
                        .lineLimit(meaning).fixedSize(horizontal: false, vertical: true)
                }
            }
            ForEach(Array(list.enumerated()), id: \.offset) { _, e in EventLine(event: e, size: bodySize) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// How a design marks today in its month grid.
enum TodayMark {
    /// Kuda: a red square around the cell.
    case square(Color)
    /// Runcit: an ink square behind the figure.
    case block(Color, text: Color)
    /// Batik, stamp, riso and midnight: a disc.
    case disc(Color, text: Color)
    /// Postcard: the whole cell filled.
    case cell(Color, text: Color)
}

struct GridLook {
    var head: Font
    var headColor: Color
    var headSunday: Color
    /// Runcit's weekday heads sit on a band of the accent.
    var headBand: Color? = nil
    var headRules: Color? = nil
    var day: Font
    var dayColor: Color
    var sunday: Color
    /// Days from the months either side, greyed out; nil leaves their cells empty.
    var outside: Color? = nil
    /// Rules round every cell.
    var lines: Color? = nil
    /// A rule above every week.
    var rowLines: Color? = nil
    var mark: TodayMark
    var headHeight: CGFloat
    var rowHeight: CGFloat
    /// How far the weeks may grow past `rowHeight` to take up spare height.
    var stretch: CGFloat = 1
}

/// A Monday-first month grid in a design's look.
struct MonthGrid: View {
    let weeks: [[CalDay]]
    let look: GridLook
    private static let heads = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(Self.heads[i]).font(look.head)
                        .foregroundColor(i == 6 ? look.headSunday : look.headColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .trailing) {
                            if let c = look.headRules, i < 6 { Rectangle().fill(c).frame(width: 1) }
                        }
                }
            }
            .frame(height: look.headHeight)
            .background(Rectangle().fill(look.headBand ?? .clear))
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in cell(day) }
                }
                .frame(minHeight: look.rowHeight, maxHeight: look.rowHeight * look.stretch)
                .overlay(alignment: .top) {
                    if let c = look.rowLines { Rectangle().fill(c).frame(height: 1) }
                }
            }
        }
        .overlay {
            if let c = look.lines {
                GridLines(rows: weeks.count, headHeight: look.headHeight, skipHead: look.headBand != nil)
                    .stroke(c, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func cell(_ day: CalDay) -> some View {
        let shown = day.inMonth || look.outside != nil
        let color = !day.inMonth ? (look.outside ?? .clear) : day.red ? look.sunday : look.dayColor
        ZStack {
            if day.today {
                switch look.mark {
                case .square(let c): Rectangle().strokeBorder(c, lineWidth: 2).padding(1)
                case .block(let c, _): Rectangle().fill(c).aspectRatio(1, contentMode: .fit).padding(look.rowHeight * 0.05)
                case .disc(let c, _): Circle().fill(c).padding(look.rowHeight * 0.05)
                case .cell(let c, _): Rectangle().fill(c).padding(0.5)
                }
            }
            if shown {
                Text("\(day.d)").font(look.day).foregroundColor(day.today ? markText ?? color : color)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var markText: Color? {
        switch look.mark {
        case .square: return nil
        case .block(_, let t), .disc(_, let t), .cell(_, let t): return t
        }
    }
}

/// The rules of a grid with a row of weekday heads on top.
struct GridLines: Shape {
    let rows: Int
    let headHeight: CGFloat
    var skipHead = false

    func path(in r: CGRect) -> Path {
        var p = Path()
        let rowHeight = (r.height - headHeight) / CGFloat(max(rows, 1))
        let top = r.minY + (skipHead ? headHeight : 0)
        for i in 0...7 {
            let x = r.minX + r.width * CGFloat(i) / 7
            p.move(to: CGPoint(x: x, y: top))
            p.addLine(to: CGPoint(x: x, y: r.maxY))
        }
        var ys = [top]
        if !skipHead { ys.append(r.minY + headHeight) }
        for i in 1...max(rows, 1) { ys.append(r.minY + headHeight + rowHeight * CGFloat(i)) }
        for y in ys {
            p.move(to: CGPoint(x: r.minX, y: y))
            p.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        return p
    }
}

/// Evenly spaced rules across a rect, about `pitch` apart, leaving its edges to the frame around it.
struct RowRules: Shape {
    let pitch: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = max(1, Int((r.height / pitch).rounded()))
        for i in 1..<n {
            let y = r.minY + r.height * CGFloat(i) / CGFloat(n)
            p.move(to: CGPoint(x: r.minX, y: y))
            p.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        return p
    }
}

/// The day's first event, or the peribahasa when there's none.
struct NextLine: View {
    @Environment(\.theme) private var theme
    let info: DayInfo
    let size: CGFloat
    var quoteSize: CGFloat? = nil
    /// How many of the day's events to list.
    var rows = 1

    var body: some View {
        if let events = info.events, !events.isEmpty {
            VStack(alignment: .leading, spacing: size * 0.4) {
                ForEach(Array(events.prefix(rows).enumerated()), id: \.offset) { _, e in EventLine(event: e, size: size) }
            }
        } else if let p = info.peribahasa, !p.isEmpty {
            Proverb(text: p, size: quoteSize ?? size * 1.2, lines: 1)
        } else {
            Text("No events. Room for new plans.").font(face(.ui, size)).foregroundColor(theme.ink.opacity(0.7))
        }
    }
}

// MARK: - Kalendar Kuda (.horse): red double frame, KALENDAR masthead with the horse, blue DM Serif figures

struct KudaSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }

    var body: some View {
        ZStack {
            DoubleFrame(color: t.accent, outer: 2, inner: 1, inset: 3, gap: 4)
            Group {
                switch ctx.family {
                case .systemSmall: small
                case .systemMedium: medium
                default: large
                }
            }
            .padding(.horizontal, 15 * k).padding(.vertical, 14 * k)
        }
    }

    private func wordmark(_ size: CGFloat) -> some View {
        CapText(text: "KALENDAR", face: .bold, size: size, color: t.accent, tracking: -0.065)
            .scaleEffect(x: 0.85, y: 1, anchor: .leading)
    }

    private func chinese(_ lines: [String], _ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: size * 0.2) {
            ForEach(lines, id: \.self) { Text($0) }
        }
        .font(.system(size: size, weight: .heavy)).foregroundColor(t.ink)
    }

    /// Today's figure in the red square that marks the selected day in the month grid.
    private func dayBox(_ n: CGFloat) -> some View {
        CapText(text: "\(info.d)", face: .serif, size: n, color: info.red ? t.red : t.ink, tracking: -0.04)
            .frame(width: n * 1.3, height: n * 1.1)
            .overlay(Rectangle().strokeBorder(t.accent, lineWidth: 2))
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                wordmark(28 * k)
                Spacer(minLength: 0)
                Art(name: "ArtHorse", width: 40 * k, shown: ctx.art)
            }
            Rule(color: t.accent, weight: 2).padding(.top, 3 * k)
            Spacer(minLength: 0)
            HStack(spacing: 9 * k) {
                dayBox(44 * k)
                VStack(alignment: .leading, spacing: 6 * k) {
                    CapText(text: info.dayEn, face: .extraBold, size: 15 * k, color: info.red ? t.red : t.ink, shrink: 0.6)
                    CapText(text: info.monthName, face: .semibold, size: 12 * k, color: t.ink, shrink: 0.6)
                    CapText(text: String(info.year), face: .semibold, size: 12 * k, color: t.ink)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 10 * k) {
                chinese(["萬用 實用", "天天進步"], 9 * k)
                wordmark(32 * k)
                Spacer(minLength: 0)
                Art(name: "ArtHorse", width: 50 * k, shown: ctx.art)
            }
            Rule(color: t.accent, weight: 2).padding(.top, 3 * k)
            HStack(alignment: .top, spacing: 12 * k) {
                dayBox(46 * k)
                VStack(alignment: .leading, spacing: 6 * k) {
                    CapText(text: info.caption, face: .bold, size: 12 * k, color: t.ink, shrink: 0.7)
                    LeafNotes(info: info, quoteSize: 15 * k, bodySize: 10.5 * k, events: 1, spacing: 3 * k)
                }
            }
            .padding(.top, 9 * k)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        let row = (weeks.count > 5 ? 21 : 25) * k
        return VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .top, spacing: 14 * k) {
                    VStack(alignment: .leading, spacing: 3 * k) {
                        chinese(["萬用", "實用", "天天進步"], 11 * k)
                        Text("KALENDAR KUDA").font(face(.bold, 7.5 * k))
                        Text("馬牌日曆").font(.system(size: 7 * k, weight: .bold))
                    }
                    .foregroundColor(t.ink)
                    wordmark(46 * k)
                    Spacer(minLength: 0)
                }
                Art(name: "ArtHorse", width: 72 * k, shown: ctx.art)
            }
            Rule(color: t.accent, weight: 2).padding(.top, 3 * k)
            CapText(text: info.monthYear, face: .extraBold, size: 23 * k, color: t.ink, tracking: -0.02).padding(.top, 9 * k)
            MonthLanguages(info: info, size: 8.5 * k).padding(.top, 6 * k)
            MonthGrid(weeks: weeks, look: GridLook(
                head: face(.semibold, 10 * k), headColor: t.ink, headSunday: t.red,
                day: face(.serif, 15.5 * k), dayColor: t.ink, sunday: t.red, lines: t.line,
                mark: .square(t.accent), headHeight: 15 * k, rowHeight: row, stretch: 1.5))
                .padding(.top, 7 * k)
                .layoutPriority(1)
            Spacer(minLength: 4 * k)
            Rule(color: t.accent, weight: 2)
            HStack(alignment: .firstTextBaseline, spacing: 10 * k) {
                Text(info.caption).font(face(.bold, 11 * k)).foregroundColor(t.ink).fixedSize()
                NextLine(info: info, size: 10 * k)
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .padding(.top, 6 * k)
        }
    }
}

// MARK: - Kopitiam (.ledger): thin green double frame, SINAR PAGI masthead, the week as a ledger

struct KopitiamSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }
    private var frame: Color { t.onPaper ? Color(hex: 0x31583e) : t.line }
    private var zh: Color { t.onPaper ? Color(hex: 0xad302d) : t.accent }
    private var ring: Color { t.onPaper ? Color(hex: 0xb02b2c) : t.accent }
    private var shade: Color { t.onPaper ? Color(hex: 0x798d67, opacity: 0.19) : t.ink.opacity(0.12) }

    var body: some View {
        ZStack {
            DoubleFrame(color: frame, outer: 1, inner: 1, inset: 3, gap: 4)
            Group {
                switch ctx.family {
                case .systemSmall: small
                case .systemMedium: medium
                default: large
                }
            }
            .padding(.horizontal, 13 * k).padding(.vertical, 13 * k)
        }
    }

    private func name(_ kedai: CGFloat, _ sinar: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: kedai * 0.45) {
            CapText(text: "KEDAI KOPI", face: .georgia, size: kedai, color: t.ink, tracking: -0.03)
            CapText(text: "SINAR PAGI", face: .georgia, size: sinar, color: t.ink, tracking: -0.03)
        }
    }

    private func chinese(_ size: CGFloat) -> some View {
        Text("新早晨咖啡店").font(.system(size: size, weight: .semibold)).tracking(size * 0.15).foregroundColor(zh)
    }

    /// The figure circled in red, as the ledger marks the selected day.
    private func circled(_ size: CGFloat) -> some View {
        Text("\(info.d)").font(face(.georgia, size)).foregroundColor(info.red ? t.red : t.ink)
            .fixedSize()
            .frame(width: size * 1.2, height: size * 1.3)
            .overlay(Ellipse().stroke(ring, lineWidth: 1.5).rotationEffect(.degrees(-9)))
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 5 * k) {
                    name(9 * k, 15 * k)
                    chinese(8.5 * k)
                }
                Spacer(minLength: 0)
                Art(name: "ArtCoffee", width: 42 * k, shown: ctx.art).offset(y: -3 * k)
            }
            Rule(color: t.ink, weight: 2).padding(.top, 5 * k)
            HStack(spacing: 0) {
                circled(34 * k).frame(width: 52 * k)
                Rectangle().fill(t.line).frame(width: 1)
                VStack(alignment: .leading, spacing: 6 * k) {
                    Text(info.dayEn.capitalized).font(face(.uiBold, 15 * k)).foregroundColor(info.red ? t.red : t.ink)
                    Text(info.monthYear).font(face(.mono, 8 * k)).foregroundColor(t.ink)
                }
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.leading, 8 * k)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity)
            .background(Rectangle().fill(shade))
            .overlay(alignment: .bottom) { Rule(color: t.line) }
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                HStack(alignment: .center, spacing: 12 * k) {
                    name(9 * k, 17 * k)
                    chinese(10 * k)
                }
                Spacer(minLength: 0)
                Art(name: "ArtCoffee", width: 34 * k, shown: ctx.art)
            }
            Rule(color: t.ink, weight: 2).padding(.top, 5 * k)
            HStack(spacing: 0) {
                circled(36 * k).frame(width: 56 * k)
                Rectangle().fill(t.line).frame(width: 1)
                VStack(alignment: .leading, spacing: 6 * k) {
                    Text(info.dayEn.capitalized).font(face(.uiBold, 14 * k)).foregroundColor(info.red ? t.red : t.ink)
                    Text(info.monthYear).font(face(.mono, 7.5 * k)).foregroundColor(t.ink)
                }
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(width: 74 * k, alignment: .leading)
                .padding(.leading, 8 * k)
                Rectangle().fill(t.line).frame(width: 1)
                LeafNotes(info: info, quoteSize: 13 * k, bodySize: 9.5 * k, events: 2, spacing: 3 * k)
                    .padding(.horizontal, 9 * k).padding(.vertical, 7 * k)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity)
            .background(Rectangle().fill(shade))
            .overlay(alignment: .bottom) { Rule(color: t.line) }
        }
    }

    private var large: some View {
        let today = Sheet.date(of: info)
        let week = Sheet.weeks(from: today, count: 1, info: info, days: ctx.days).first ?? []
        let cols: (CGFloat, CGFloat) = (44 * k, 62 * k)
        return VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 6 * k) {
                    name(13 * k, 22 * k)
                    chinese(13 * k)
                    Text("KOPI · ROTI · KAWAN · JADUAL HIDUP").font(face(.mono, 7 * k)).tracking(0.5 * k).foregroundColor(t.ink)
                }
                .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .topTrailing) { Art(name: "ArtCoffee", width: 58 * k, shown: ctx.art).offset(y: -2 * k) }
            Rule(color: t.ink, weight: 2).padding(.top, 8 * k)
            CapText(text: info.monthYear, face: .georgia, size: 14 * k, color: t.ink, tracking: 0.04).padding(.vertical, 8 * k)
            VStack(spacing: 0) {
                Text("EVENTS").font(face(.mono, 7 * k)).foregroundColor(t.ink)
                    .frame(maxWidth: .infinity).padding(.leading, cols.0 + cols.1)
                    .frame(height: 14 * k)
                    .overlay(alignment: .bottom) { Rule(color: t.line) }
                ForEach(Array(week.enumerated()), id: \.offset) { _, day in ledgerRow(day, cols: cols) }
                // The page runs on in blank ruled rows below Sunday.
                RowRules(pitch: 17 * k).stroke(t.line, lineWidth: 1).frame(maxHeight: .infinity)
            }
            .overlay(alignment: .leading) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: cols.0)
                    Rectangle().fill(t.line).frame(width: 1)
                    Color.clear.frame(width: cols.1 - 1)
                    Rectangle().fill(t.line).frame(width: 1)
                }
            }
            .overlay { Rectangle().strokeBorder(t.line, lineWidth: 1) }
        }
    }

    private func ledgerRow(_ day: CalDay, cols: (CGFloat, CGFloat)) -> some View {
        let color = day.red ? t.red : t.ink
        let events = day.info?.events ?? []
        return HStack(spacing: 0) {
            Group {
                if day.today { circled(24 * k) } else { Text("\(day.d)").font(face(.georgia, 12 * k)).foregroundColor(color) }
            }
            .frame(width: cols.0)
            Text(day.today ? Sheet.daysEn[day.weekday].capitalized : String(Sheet.daysEn[day.weekday].prefix(3)))
                .font(face(.uiBold, (day.today ? 12 : 10.5) * k)).foregroundColor(color)
                .minimumScaleFactor(0.7)
                .frame(width: cols.1 - 8 * k, alignment: .leading).padding(.leading, 8 * k)
            Group {
                if let e = events.first {
                    EventLine(event: e, size: 9.5 * k)
                } else if day.today, let p = info.peribahasa {
                    Proverb(text: p, size: 11 * k, lines: 1)
                }
            }
            .padding(.horizontal, 7 * k)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: (day.today ? 34 : 25) * k)
        .background(Rectangle().fill(day.today ? shade : .clear))
        .overlay(alignment: .bottom) { Rule(color: t.line) }
    }
}

// MARK: - Kedai Runcit (.runcit): yellow paper, HARI HARI masthead, ink squares and a receipt

struct RuncitSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }
    private var receipt: Color { t.onPaper ? Color(hex: 0xf8edd6) : t.ink.opacity(0.12) }
    private var receiptInk: Color { t.onPaper ? Color(hex: 0x24251e) : t.ink }

    var body: some View {
        Group {
            switch ctx.family {
            case .systemSmall: small
            case .systemMedium: medium
            default: large
            }
        }
        .padding(.horizontal, 14 * k).padding(.vertical, 13 * k)
    }

    private func masthead(_ hari: CGFloat, _ kedai: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: kedai * 0.35) {
            CapText(text: "HARI HARI", face: .black, size: hari, color: t.accent, tracking: -0.02)
            CapText(text: "KEDAI RUNCIT", face: .extraBold, size: kedai, color: t.ink, tracking: -0.01)
        }
    }

    /// Today in the grid's ink square, with the weekday on the red band of the grid's heads.
    private func today(_ n: CGFloat) -> some View {
        HStack(spacing: n * 0.18) {
            CapText(text: "\(info.d)", face: .bold, size: n * 0.68, color: t.buttonInk, tracking: -0.02)
                .frame(width: n * 1.05, height: n)
                .background(Rectangle().fill(t.ink))
            VStack(alignment: .leading, spacing: n * 0.11) {
                Text(info.dayEn).font(face(.semibold, n * 0.24)).tracking(n * 0.01).foregroundColor(t.buttonInk)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, n * 0.08).padding(.vertical, n * 0.02)
                    .background(Rectangle().fill(info.red ? t.red : t.accent))
                CapText(text: info.monthName, face: .extraBold, size: n * 0.27, color: t.accent, shrink: 0.6)
                CapText(text: String(info.year), face: .extraBold, size: n * 0.27, color: t.ink)
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            masthead(36 * k, 15 * k)
            Rule(color: t.ink, weight: 2).padding(.top, 7 * k)
            Spacer(minLength: 0)
            today(52 * k)
            Spacer(minLength: 0)
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 12 * k) {
            VStack(alignment: .leading, spacing: 0) {
                masthead(32 * k, 13.5 * k)
                Rule(color: t.ink, weight: 2).padding(.top, 6 * k)
                Spacer(minLength: 0)
                today(50 * k)
            }
            .frame(width: 128 * k)
            Receipt(fill: receipt, tooth: 9 * k) {
                VStack(alignment: .leading, spacing: 5 * k) {
                    Text(info.caption).font(face(.bold, 11 * k)).foregroundColor(t.onPaper ? Color(hex: 0x194630) : t.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    DottedRule(color: t.onPaper ? Color(hex: 0x9c8d72) : t.line)
                    LeafNotes(info: info, quoteSize: 14 * k, bodySize: 9.5 * k, events: 1, spacing: 3 * k)
                        .environment(\.theme, receiptTheme)
                }
                .padding(.horizontal, 10 * k).padding(.top, 8 * k).padding(.bottom, 6 * k)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    /// The receipt is printed on white stock in near-black (`.leaf[data-theme="runcit"] .leaf-card`).
    private var receiptTheme: Theme {
        var r = t
        r.ink = receiptInk
        return r
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        let row = (weeks.count > 5 ? 19 : 22) * k
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 6 * k) {
                    masthead(46 * k, 19 * k)
                    Text("BERAS · GULA · MINYAK MASAK").font(face(.bold, 8 * k)).foregroundColor(t.ink)
                }
                Spacer(minLength: 0)
                Art(name: "ArtGoods", width: 128 * k, shown: ctx.art)
            }
            Rule(color: t.ink, weight: 2).padding(.top, 6 * k)
            HStack(spacing: 6 * k) {
                CapText(text: info.monthName, face: .extraBold, size: 22 * k, color: t.accent, tracking: -0.03)
                CapText(text: String(info.year), face: .extraBold, size: 22 * k, color: t.ink, tracking: -0.03)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8 * k)
            MonthLanguages(info: info, size: 8.5 * k).frame(maxWidth: .infinity).padding(.top, 5 * k)
            MonthGrid(weeks: weeks, look: GridLook(
                head: face(.semibold, 10 * k), headColor: t.buttonInk, headSunday: t.buttonInk, headBand: t.accent,
                headRules: t.onPaper ? Color(hex: 0xf3d98f) : nil,
                day: face(.bold, 14 * k), dayColor: t.ink, sunday: t.red, lines: t.line,
                mark: .block(t.ink, text: t.buttonInk), headHeight: 15 * k, rowHeight: row, stretch: 1.5))
                .padding(.top, 6 * k)
                .layoutPriority(1)
            Spacer(minLength: 6 * k)
            Receipt(fill: receipt, tooth: 9 * k) {
                VStack(alignment: .leading, spacing: 4 * k) {
                    Text(info.caption).font(face(.bold, 10.5 * k)).foregroundColor(t.onPaper ? Color(hex: 0x194630) : t.ink)
                    DottedRule(color: t.onPaper ? Color(hex: 0x9c8d72) : t.line)
                    NextLine(info: info, size: 9.5 * k, quoteSize: 12 * k).environment(\.theme, receiptTheme)
                }
                .lineLimit(1)
                .padding(.horizontal, 10 * k).padding(.top, 7 * k).padding(.bottom, 6 * k)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A receipt: white stock with a torn, zigzag top (`.leaf-card::before` in the runcit leaf).
struct Receipt<Content: View>: View {
    let fill: Color
    let tooth: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Zigzag(tooth: tooth).fill(fill).frame(height: tooth * 0.6)
            content().frame(maxWidth: .infinity, alignment: .leading).background(Rectangle().fill(fill))
        }
    }
}

struct Zigzag: Shape {
    let tooth: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        var x = r.minX
        while x < r.maxX {
            p.addLine(to: CGPoint(x: min(x + tooth / 2, r.maxX), y: r.minY))
            p.addLine(to: CGPoint(x: min(x + tooth, r.maxX), y: r.maxY))
            x += tooth
        }
        p.closeSubpath()
        return p
    }
}

struct DottedRule: View {
    let color: Color

    var body: some View {
        Line().stroke(color, style: StrokeStyle(lineWidth: 1, dash: [1.5, 2])).frame(height: 1)
    }

    private struct Line: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            return p
        }
    }
}

// MARK: - Batik (.batik): a batik strip down the right edge, navy DM Serif, a gold disc for today

struct BatikSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                switch ctx.family {
                case .systemSmall: small
                case .systemMedium: medium
                default: large
                }
            }
            .padding(.leading, 15 * k).padding(.trailing, 13 * k).padding(.vertical, 14 * k)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if ctx.art {
                BatikStrip(width: (ctx.family == .systemSmall ? 26 : 34) * k, height: ctx.size.height)
            }
        }
    }

    private func heading(_ size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: size * 0.22) {
            CapText(text: info.monthName, face: .serif, size: size, color: t.ink, tracking: -0.05, shrink: 0.6)
            CapText(text: String(info.year), face: .serif, size: size, color: t.ink, tracking: -0.05)
        }
    }

    private func disc(_ d: CGFloat) -> some View {
        CapText(text: "\(info.d)", face: .serif, size: d * 0.56, color: t.buttonInk, tracking: -0.04)
            .frame(width: d, height: d)
            .background(Circle().fill(info.red ? t.red : t.accent))
    }

    private func weekday(_ size: CGFloat) -> some View {
        CapText(text: info.dayEn, face: .georgia, size: size, color: info.red ? t.red : t.ink, tracking: 0.04, shrink: 0.6)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(19 * k)
            MonthLanguages(info: info, size: 7 * k, spacing: 0.6).padding(.top, 6 * k)
            Spacer(minLength: 0)
            HStack(spacing: 9 * k) {
                disc(48 * k)
                weekday(10 * k)
            }
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 13 * k) {
            VStack(alignment: .leading, spacing: 0) {
                heading(19 * k)
                Spacer(minLength: 0)
                disc(50 * k)
                weekday(10 * k).padding(.top, 8 * k)
            }
            .frame(width: 92 * k, alignment: .leading)
            Rectangle().fill(t.line).frame(width: 1)
            LeafNotes(info: info, quoteSize: 15 * k, bodySize: 10 * k, events: 1, spacing: 4 * k)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        let row = (weeks.count > 5 ? 21 : 25) * k
        return VStack(alignment: .leading, spacing: 0) {
            heading(31 * k)
            MonthLanguages(info: info, size: 8.5 * k).padding(.top, 9 * k)
            Rule(color: t.line).padding(.top, 9 * k)
            MonthGrid(weeks: weeks, look: GridLook(
                head: face(.serif, 9.5 * k), headColor: t.ink, headSunday: t.red,
                day: face(.serif, 16 * k), dayColor: t.ink, sunday: t.red,
                mark: .disc(t.accent, text: t.buttonInk), headHeight: 17 * k, rowHeight: row, stretch: 1.5))
                .padding(.top, 4 * k)
                .layoutPriority(1)
            Spacer(minLength: 4 * k)
            Rule(color: t.line)
            Text(info.caption).font(face(.georgia, 11 * k)).tracking(0.3 * k).foregroundColor(t.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8 * k)
            NextLine(info: info, size: 10 * k, quoteSize: 13 * k).padding(.top, 5 * k)
        }
    }
}

/// The batik strip and its gold rule (`.batik .screen::before`): one repeat of the cloth, tiled down the edge.
struct BatikStrip: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let w = width - 2
        HStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0xd7ae68)).frame(width: 2)
            VStack(spacing: 0) {
                ForEach(0..<max(1, Int((height / (w * 2)).rounded(.up))), id: \.self) { _ in
                    Image("BatikStrip").resizable().frame(width: w, height: w * 2)
                }
            }
            .frame(width: w, height: height, alignment: .top)
            .clipped()
            .background(Rectangle().fill(Color(hex: 0x163751)))
        }
        .frame(height: height)
    }
}

// MARK: - Postcard (.postcard): the street scene, navy DM Serif, a coral cell for today

struct PostcardSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }
    private var edge: Color { t.onPaper ? Color(hex: 0xb9a382) : t.line }

    var body: some View {
        switch ctx.family {
        case .systemSmall: small
        case .systemMedium: medium
        default: large
        }
    }

    private func picture(_ name: String, height: CGFloat, alignment: Alignment = .center) -> some View {
        Color.clear.frame(height: height)
            .overlay(alignment: alignment) { Image(name).resizable().scaledToFill() }
            .clipped()
            .overlay(alignment: .bottom) { Rule(color: edge, weight: 2) }
    }

    /// Today as the grid shows it: a cell filled with the coral.
    private func cell(_ n: CGFloat) -> some View {
        CapText(text: "\(info.d)", face: .serif, size: n * 0.62, color: t.buttonInk, tracking: -0.04)
            .frame(width: n, height: n)
            .background(Rectangle().fill(info.red ? t.red : t.accent))
    }

    private func dateLine(_ n: CGFloat) -> some View {
        HStack(spacing: n * 0.22) {
            cell(n)
            VStack(alignment: .leading, spacing: n * 0.16) {
                CapText(text: info.dayEn, face: .bold, size: n * 0.3, color: info.red ? t.red : t.ink, tracking: 0.04, shrink: 0.6)
                CapText(text: info.monthYear, face: .serif, size: n * 0.3, color: t.ink, tracking: -0.03, shrink: 0.6)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .trailing, spacing: 1 * k) {
            Text("Selamat Datang").font(face(.georgiaItalic, 10 * k))
            Text("ke").font(face(.georgiaItalic, 10 * k))
            Text("MALAYSIA").font(face(.bold, 12.5 * k)).tracking(12.5 * k * 0.16)
        }
        .foregroundColor(Color(hex: 0x254756))
        .shadow(color: Color(hex: 0xfff2d7), radius: 1.5 * k, y: 1 * k)
        .shadow(color: Color(hex: 0xfff2d7).opacity(0.8), radius: 3 * k)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            if ctx.art { picture("PostcardBand", height: 74 * k) }
            Spacer(minLength: 0)
            dateLine(44 * k).padding(.horizontal, 14 * k)
            Spacer(minLength: 0)
        }
    }

    private var medium: some View {
        HStack(spacing: 0) {
            if ctx.art {
                Color.clear.frame(width: 118 * k)
                    .overlay { Image("PostcardPanel").resizable().scaledToFill() }
                    .clipped()
                    .overlay(alignment: .trailing) { Rectangle().fill(edge).frame(width: 2) }
            }
            VStack(alignment: .leading, spacing: 8 * k) {
                dateLine(40 * k)
                Rule(color: t.line)
                LeafNotes(info: info, quoteSize: 14 * k, bodySize: 9.5 * k, events: 1, spacing: 3 * k)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, 13 * k).padding(.vertical, 13 * k)
        }
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        let row = (weeks.count > 5 ? 19 : 22) * k
        return VStack(spacing: 0) {
            if ctx.art {
                picture("PostcardBand", height: 104 * k, alignment: .top)
                    .overlay(alignment: .topTrailing) { greeting.padding(.top, 9 * k).padding(.trailing, 12 * k) }
            }
            VStack(spacing: 0) {
                CapText(text: info.monthYear, face: .serif, size: 23 * k, color: t.ink, tracking: -0.05).padding(.top, 10 * k)
                MonthLanguages(info: info, size: 8.5 * k).padding(.top, 6 * k)
                MonthGrid(weeks: weeks, look: GridLook(
                    head: face(.serif, 9 * k), headColor: t.ink, headSunday: t.red,
                    day: face(.serif, 14.5 * k), dayColor: t.ink, sunday: t.red, lines: t.line,
                    // Without the picture band the weeks take up its height too.
                    mark: .cell(t.accent, text: t.buttonInk), headHeight: 14 * k, rowHeight: row, stretch: ctx.art ? 1.5 : 2.3))
                    .padding(.top, 7 * k)
                    .layoutPriority(1)
                Spacer(minLength: 4 * k)
                HStack(alignment: .center, spacing: 10 * k) {
                    if ctx.art { Art(name: "ArtFlower", width: 34 * k).saturation(0.55) }
                    VStack(alignment: .leading, spacing: 4 * k) {
                        Text(info.caption).font(face(.bold, 10.5 * k)).foregroundColor(t.ink)
                        NextLine(info: info, size: 9.5 * k, quoteSize: 12 * k)
                    }
                    .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 15 * k).padding(.bottom, 11 * k)
        }
    }
}

// MARK: - Stamp (.stamp): maroon double rule, a rubber-stamped weekday, the date as DD / MM / YYYY

struct StampSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }

    var body: some View {
        ZStack {
            DoubleFrame(color: t.line, outer: 1, inner: 1, inset: 3, gap: 6)
            Group {
                switch ctx.family {
                case .systemSmall: small
                case .systemMedium: medium
                default: large
                }
            }
            .padding(.horizontal, 17 * k).padding(.top, 15 * k).padding(.bottom, 18 * k)
        }
    }

    private var mm: String { String(format: "%02d", info.monthIndex + 1) }
    private var dd: String { String(format: "%02d", info.d) }
    /// The form's serial number, `No. MMDD28` in app.js.
    private var serial: String { "No. \(mm)\(dd)28" }

    private func header(_ size: CGFloat, stacked: Bool) -> some View {
        HStack(alignment: .top) {
            Text(stacked ? "PELAN\nJADUAL\nHARIAN" : "JADUAL HARIAN").font(face(.mono, size)).lineSpacing(0)
            Spacer(minLength: 0)
            Text(serial).font(face(.mono, size * 1.1))
        }
        .foregroundColor(t.ink)
    }

    private func monthBar(_ size: CGFloat) -> some View {
        Text(info.monthYear).font(face(.mono, size)).foregroundColor(t.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, size * 0.45)
            .overlay(alignment: .top) { Rule(color: t.ink, weight: 2) }
            .overlay(alignment: .bottom) { Rule(color: t.ink) }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(6.5 * k, stacked: false)
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                StampBox(text: info.dayEn, size: 13 * k, color: t.accent)
            }
            CapText(text: "\(dd) / \(mm)", face: .bold, size: 44 * k, color: t.ink, tracking: -0.055).padding(.top, 9 * k)
            Spacer(minLength: 0)
            monthBar(8 * k)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(7 * k, stacked: false)
            HStack(alignment: .center, spacing: 8 * k) {
                CapText(text: "\(dd) / \(mm) / \(info.year)", face: .bold, size: 40 * k, color: t.ink, tracking: -0.055, shrink: 0.7)
                Spacer(minLength: 0)
                StampBox(text: info.dayEn, size: 14 * k, color: t.accent)
            }
            .frame(maxHeight: .infinity)
            monthBar(8.5 * k)
            StampTimeline(info: info, rows: 1, size: 9.5 * k).padding(.top, 7 * k)
        }
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        return VStack(alignment: .leading, spacing: 0) {
            header(7.5 * k, stacked: true)
                .overlay(alignment: .bottomTrailing) {
                    StampBox(text: info.dayEn, size: 15 * k, color: t.accent).offset(y: 20 * k)
                }
            CapText(text: "\(dd) / \(mm) / \(info.year)", face: .bold, size: 46 * k, color: t.ink, tracking: -0.055, shrink: 0.7)
                .frame(maxWidth: .infinity)
                .padding(.top, 30 * k)
            monthBar(9 * k).padding(.top, 10 * k)
            StampTimeline(info: info, rows: 2, size: 9.5 * k).padding(.top, 8 * k)
            // `.stamp-notes`: a label on a rule, then the textarea's ruled lines.
            VStack(alignment: .leading, spacing: 0) {
                Text("NOTES").font(face(.mono, 7 * k)).tracking(7 * k * 0.03).foregroundColor(t.ink)
                    .padding(.top, 4 * k)
                RowRules(pitch: 19 * k).stroke(Color(hex: 0xad9a7e).opacity(0.56), lineWidth: 1)
                    .frame(minHeight: 19 * k, maxHeight: .infinity)
            }
            .overlay(alignment: .top) { Rule(color: t.line) }
            .padding(.top, 10 * k)
            HStack(alignment: .center, spacing: 12 * k) {
                VStack(alignment: .leading, spacing: 3 * k) {
                    Text(info.monthYear).font(face(.semibold, 8.5 * k)).foregroundColor(t.ink)
                    MonthGrid(weeks: weeks, look: GridLook(
                        head: face(.mono, 6 * k), headColor: t.ink, headSunday: t.ink,
                        day: face(.semibold, 8 * k), dayColor: t.ink, sunday: t.ink,
                        // Off the paper the ink turns paper-coloured, so the figure needs the dark button ink.
                        mark: .disc(t.ink, text: t.onPaper ? t.paper : t.buttonInk), headHeight: 10 * k, rowHeight: 11.5 * k))
                }
                .frame(width: 150 * k)
                Spacer(minLength: 0)
                Seal(diameter: 74 * k, color: t.accent)
            }
            .padding(.top, 8 * k)
            .overlay(alignment: .top) { Rule(color: t.line) }
        }
    }
}

/// A rubber stamp in a 3px double border, a little crooked (`.stamp .day-stamp`).
struct StampBox: View {
    let text: String
    let size: CGFloat
    let color: Color
    var angle: Double = -5

    var body: some View {
        CapText(text: text, face: .extraBold, size: size, color: color, tracking: 0.01)
            .padding(.horizontal, size * 0.3).padding(.vertical, size * 0.24)
            .overlay(Rectangle().strokeBorder(color, lineWidth: 1))
            .padding(size * 0.09)
            .overlay(Rectangle().strokeBorder(color, lineWidth: 1))
            .rotationEffect(.degrees(angle))
    }
}

/// The day's events on a line of dots, or a note that there are none (`.stamp .timeline`).
struct StampTimeline: View {
    @Environment(\.theme) private var theme
    let info: DayInfo
    let rows: Int
    let size: CGFloat

    var body: some View {
        let list = Array((info.events ?? []).prefix(rows))
        VStack(alignment: .leading, spacing: size * 0.55) {
            if list.isEmpty {
                if let p = info.peribahasa, !p.isEmpty {
                    Proverb(text: p, size: size * 1.35, lines: rows > 1 ? 2 : 1)
                } else {
                    Text("No events. Room for new plans.").font(face(.ui, size)).foregroundColor(theme.ink.opacity(0.75))
                }
            }
            ForEach(Array(list.enumerated()), id: \.offset) { _, e in
                HStack(spacing: size * 0.7) {
                    Circle().fill(theme.accent).frame(width: size * 0.6, height: size * 0.6)
                    Text(e.time.isEmpty ? "All day" : e.time).font(face(.mono, size * 0.95))
                    Text(e.title).font(face(.ui, size))
                }
                .foregroundColor(theme.ink).lineLimit(1)
            }
        }
        .padding(.leading, size * 0.6)
        .overlay(alignment: .leading) { Rectangle().fill(theme.accent).frame(width: 1) }
    }
}

/// The round seal by the mini calendar (`.print-seal`): JADUAL ★ HARIAN in a 4px double ring, turned 15°.
struct Seal: View {
    let diameter: CGFloat
    let color: Color

    var body: some View {
        let u = diameter / 115
        ZStack {
            Circle().strokeBorder(color, lineWidth: 4 * u / 3)
            Circle().inset(by: 8 * u / 3).strokeBorder(color, lineWidth: 4 * u / 3)
            VStack(spacing: 4 * u) {
                Text("JADUAL")
                Text("★").font(face(.georgia, 29 * u))
                Text("HARIAN")
            }
            .font(face(.semibold, 19 * u)).tracking(19 * u * 0.12)
            .foregroundColor(color)
            .rotationEffect(.degrees(15))
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Riso (.riso): coral and cobalt overprint, the month as OCT, a two-week strip

struct RisoSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }
    private var month3: String { String(info.monthName.prefix(3)) }

    var body: some View {
        Group {
            switch ctx.family {
            case .systemSmall: small
            case .systemMedium: medium
            default: large
            }
        }
        .padding(.horizontal, 15 * k).padding(.vertical, 14 * k)
    }

    private func disc(_ d: CGFloat) -> some View {
        CapText(text: "\(info.d)", face: .semibold, size: d * 0.6, color: t.buttonInk)
            .frame(width: d, height: d)
            .background(Circle().fill(t.accent))
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            CapText(text: month3, face: .black, size: 58 * k, color: t.accent, tracking: -0.03)
            CapText(text: String(info.year), face: .extraBold, size: 22 * k, color: t.accent, tracking: -0.02).padding(.top, 6 * k)
            Spacer(minLength: 0)
            HStack(spacing: 8 * k) {
                disc(38 * k)
                VStack(alignment: .leading, spacing: 5 * k) {
                    CapText(text: info.dayEn, face: .bold, size: 14 * k, color: info.red ? t.red : t.ink, tracking: 0.04, shrink: 0.6)
                    MonthLanguages(info: info, size: 7 * k, spacing: 0.6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            Art(name: "ArtFlower", width: 78 * k, shown: ctx.art).offset(x: 8 * k, y: -4 * k)
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14 * k) {
            VStack(alignment: .leading, spacing: 0) {
                CapText(text: month3, face: .black, size: 66 * k, color: t.accent, tracking: -0.03)
                CapText(text: String(info.year), face: .extraBold, size: 25 * k, color: t.accent, tracking: -0.02).padding(.top, 7 * k)
                Spacer(minLength: 0)
                HStack(spacing: 7 * k) {
                    disc(32 * k)
                    CapText(text: info.dayEn, face: .bold, size: 13 * k, color: info.red ? t.red : t.ink, tracking: 0.04, shrink: 0.6)
                }
            }
            .frame(width: 112 * k, alignment: .leading)
            VStack(alignment: .leading, spacing: 6 * k) {
                Rule(color: t.accent, weight: 3)
                if ctx.art {
                    // The flower takes the corner only while the notes leave it room; a long day drops it.
                    ViewThatFits(in: .vertical) {
                        VStack(alignment: .leading, spacing: 4 * k) {
                            LeafNotes(info: info, quoteSize: 15 * k, bodySize: 9.5 * k, events: 0, spacing: 4 * k)
                            Spacer(minLength: 0)
                            HStack(alignment: .bottom, spacing: 6 * k) {
                                if let e = info.events?.first { EventLine(event: e, size: 9.5 * k) }
                                Spacer(minLength: 0)
                                Art(name: "ArtFlower", width: 60 * k).opacity(0.9).offset(x: 6 * k, y: 6 * k)
                            }
                        }
                        notes
                    }
                } else {
                    notes
                }
            }
        }
    }

    private var notes: some View {
        LeafNotes(info: info, quoteSize: 15 * k, bodySize: 9.5 * k, events: 1, spacing: 4 * k)
            .frame(maxHeight: .infinity, alignment: .top)
    }

    private var large: some View {
        let weeks = Sheet.weeks(from: Sheet.date(of: info), count: 2, info: info, days: ctx.days)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                CapText(text: month3, face: .black, size: 100 * k, color: t.accent, tracking: -0.03)
                CapText(text: String(info.year), face: .extraBold, size: 38 * k, color: t.accent, tracking: -0.02).padding(.top, 9 * k)
                VStack(alignment: .leading, spacing: 3 * k) {
                    Text("\(info.monthZhName)  \(info.month)")
                    Text(info.monthTa)
                }
                .font(face(.uiBold, 10 * k)).foregroundColor(t.ink)
                .padding(.top, 8 * k)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topTrailing) {
                Art(name: "ArtFlower", width: 128 * k, shown: ctx.art).offset(x: 6 * k, y: 28 * k)
            }
            MonthGrid(weeks: weeks, look: GridLook(
                head: face(.semibold, 11 * k), headColor: t.ink, headSunday: t.red,
                day: face(.semibold, 17 * k), dayColor: t.ink, sunday: t.red, outside: t.ink.opacity(0.35),
                rowLines: t.onPaper ? Color(hex: 0xbaab92) : t.line,
                mark: .disc(t.accent, text: t.buttonInk), headHeight: 19 * k, rowHeight: 29 * k))
                .overlay(alignment: .top) { Rule(color: t.accent, weight: 3) }
                .overlay(alignment: .bottom) { Rule(color: t.accent, weight: 3) }
                .padding(.top, 10 * k)
            HStack(alignment: .top, spacing: 12 * k) {
                Art(name: "ArtBus", width: 112 * k, shown: ctx.art)
                VStack(alignment: .leading, spacing: 4 * k) {
                    Group {
                        Text("\(info.dayEn),")
                        Text(verbatim: "\(info.d) \(info.monthName) \(info.year)")
                    }
                    .font(face(.bold, 13 * k)).tracking(13 * k * 0.06).foregroundColor(t.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    VStack(alignment: .leading, spacing: 4 * k) {
                        if let h = info.holidayName { HolidayTag(name: h, size: 9 * k) }
                        NextLine(info: info, size: 9.5 * k, quoteSize: 13 * k, rows: 2)
                    }
                    .padding(.top, 4 * k)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 10 * k)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Midnight (.midnight): dark paper, cream DM Serif, copper rules, a red figure, the moon

struct MidnightSheet: View {
    let ctx: SheetContext
    private var t: Theme { ctx.theme }
    private var k: CGFloat { ctx.k }
    private var info: DayInfo { ctx.info }

    var body: some View {
        Group {
            switch ctx.family {
            case .systemSmall: small
            case .systemMedium: medium
            default: large
            }
        }
        .padding(.horizontal, 16 * k).padding(.vertical, 15 * k)
    }

    private func moon(_ width: CGFloat, _ opacity: Double) -> some View {
        Art(name: "ArtMoon", width: width, shown: ctx.art).opacity(opacity)
    }

    /// The selected day's block: the figure in red, a copper rule, then the weekday in three languages.
    private func dayBlock(_ n: CGFloat) -> some View {
        HStack(spacing: n * 0.2) {
            CapText(text: "\(info.d)", face: .serif, size: n, color: t.accent, tracking: -0.05)
            Rectangle().fill(t.line).frame(width: 1, height: n * 0.85)
            VStack(alignment: .leading, spacing: n * 0.1) {
                CapText(text: info.dayEn, face: .bold, size: n * 0.24, color: t.ink, tracking: 0.01, shrink: 0.6)
                Text(info.day).font(face(.ui, n * 0.12)).tracking(n * 0.12 * 0.2)
                Text(info.dayZhName).font(.system(size: n * 0.12)).tracking(n * 0.12 * 0.2)
            }
            .foregroundColor(t.ink)
            .lineLimit(1)
        }
    }

    /// The month in DM Serif over its other languages, the moon beside it; a long month gives way to the moon.
    private func heading(moon width: CGFloat, opacity: Double) -> some View {
        HStack(alignment: .top, spacing: 4 * k) {
            VStack(alignment: .leading, spacing: 5 * k) {
                CapText(text: info.monthYear, face: .serif, size: 15 * k, color: t.ink, tracking: -0.035, shrink: 0.7)
                MonthLanguages(info: info, size: 6.5 * k, tracking: 0.1, spacing: 0.8)
            }
            Spacer(minLength: 0)
            moon(width, opacity).offset(x: 6 * k, y: -6 * k)
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(moon: 40 * k, opacity: 0.8)
            Spacer(minLength: 0)
            dayBlock(60 * k)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14 * k) {
            VStack(alignment: .leading, spacing: 0) {
                heading(moon: 36 * k, opacity: 0.8)
                Spacer(minLength: 0)
                dayBlock(64 * k)
                Spacer(minLength: 0)
            }
            .frame(width: 150 * k, alignment: .leading)
            Rectangle().fill(t.line).frame(width: 1)
            LeafNotes(info: info, quoteSize: 15 * k, bodySize: 9.5 * k, events: 1, spacing: 4 * k)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var large: some View {
        let weeks = Sheet.monthWeeks(info, days: ctx.days)
        let row = (weeks.count > 5 ? 20 : 23) * k
        return VStack(alignment: .leading, spacing: 0) {
            CapText(text: info.monthYear, face: .serif, size: 27 * k, color: t.ink, tracking: -0.035)
            MonthLanguages(info: info, size: 8 * k, tracking: 0.1, spacing: 1).padding(.top, 8 * k)
            Rule(color: t.line).padding(.top, 10 * k)
            MonthGrid(weeks: weeks, look: GridLook(
                head: face(.serif, 9.5 * k), headColor: t.ink, headSunday: t.red,
                day: face(.serif, 15 * k), dayColor: t.ink, sunday: t.red,
                mark: .disc(t.accent, text: t.buttonInk), headHeight: 16 * k, rowHeight: row))
                .padding(.top, 3 * k)
            Rule(color: t.line).padding(.top, 5 * k)
            Spacer(minLength: 0)
            HStack(alignment: .center) {
                dayBlock(62 * k)
                Spacer(minLength: 0)
                moon(54 * k, 0.55)
            }
            Spacer(minLength: 0)
            Rule(color: t.line)
            NextLine(info: info, size: 10 * k, quoteSize: 13 * k, rows: 2).padding(.top, 8 * k)
        }
        .background(alignment: .topTrailing) { moon(46 * k, 0.8).offset(x: 4 * k, y: -6 * k) }
    }
}
