// Sehari Selembar widgets: the Tear-off sheet on the home screen and the lock screen.
// Reads the snapshot the app writes into the shared App Group (see WidgetBridgePlugin in AppDelegate.swift).
import SwiftUI
import WidgetKit

private let appGroup = "group.my.sehariselembar.app"

// MARK: - Data

struct DayEvent: Codable, Hashable {
    let time: String
    let title: String
}

struct DayInfo: Codable {
    let date: String
    let d: Int
    let year: Int
    let weekday: Int
    let month: String
    let monthZh: String?
    let day: String
    let dayEn: String
    let dayZh: String?
    let red: Bool
    let holiday: String?
    let peribahasa: String?
    let maksud: String?
    let events: [DayEvent]?
}

private struct Snapshot: Codable {
    let style: String?
    let days: [DayInfo]
}

enum Sheet {
    static let days = ["AHAD", "ISNIN", "SELASA", "RABU", "KHAMIS", "JUMAAT", "SABTU"]
    static let daysEn = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    static let daysZh = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
    static let months = ["JANUARI", "FEBRUARI", "MAC", "APRIL", "MEI", "JUN", "JULAI", "OGOS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DISEMBER"]
    static let monthsZh = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]

    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }

    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Today's sheet with no data from the app: the date is still right.
    static func plain(_ date: Date) -> DayInfo {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let w = (c.weekday ?? 1) - 1, m = (c.month ?? 1) - 1
        return DayInfo(date: key(date), d: c.day ?? 1, year: c.year ?? 2026, weekday: w, month: months[m], monthZh: monthsZh[m],
                       day: days[w], dayEn: daysEn[w], dayZh: daysZh[w], red: w == 0, holiday: nil,
                       peribahasa: nil, maksud: nil, events: nil)
    }

    static func load() -> [String: DayInfo] {
        guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "snapshot"),
              let data = json.data(using: .utf8),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return [:] }
        return Dictionary(snap.days.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
    }

    static func info(for date: Date, in days: [String: DayInfo]) -> DayInfo {
        days[key(date)] ?? plain(date)
    }

    static var sample: DayInfo {
        DayInfo(date: "2026-10-01", d: 1, year: 2026, weekday: 4, month: "OKTOBER", monthZh: "十月", day: "KHAMIS", dayEn: "THURSDAY",
                dayZh: "星期四", red: false, holiday: nil, peribahasa: "Bagai aur dengan tebing",
                maksud: "Hubungan yang rapat antara dua pihak yang saling membantu.",
                events: [DayEvent(time: "09:00", title: "Mesyuarat"), DayEvent(time: "18:30", title: "Makan keluarga")])
    }
}

// MARK: - Timeline: one entry per day, turning the page at midnight

struct SheetEntry: TimelineEntry {
    let date: Date
    let info: DayInfo
}

struct SheetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SheetEntry {
        SheetEntry(date: Date(), info: Sheet.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SheetEntry) -> Void) {
        let days = Sheet.load()
        completion(SheetEntry(date: Date(), info: context.isPreview && days.isEmpty ? Sheet.sample : Sheet.info(for: Date(), in: days)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SheetEntry>) -> Void) {
        let days = Sheet.load()
        let cal = Sheet.calendar
        let start = cal.startOfDay(for: Date())
        var entries = [SheetEntry(date: Date(), info: Sheet.info(for: Date(), in: days))]
        for i in 1...7 {
            if let day = cal.date(byAdding: .day, value: i, to: start) {
                entries.append(SheetEntry(date: day, info: Sheet.info(for: day, in: days)))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Look: cream paper, red binding, DM Serif numeral (the Tear-off design)

private enum Ink {
    static let paper = Color(red: 0.949, green: 0.906, blue: 0.816)       // #f2e7d0
    static let red = Color(red: 0.749, green: 0.161, blue: 0.165)         // #bf292a
    static let binding = Color(red: 0.706, green: 0.169, blue: 0.169)     // #b42b2b
    static let ink = Color(red: 0.157, green: 0.145, blue: 0.118)         // #28251e
    static let rule = Color(red: 0.506, green: 0.471, blue: 0.384)        // #817862
    static let hole = Color(red: 0.247, green: 0.2, blue: 0.133)          // #3f3322
    static let stub = Color(red: 0.937, green: 0.89, blue: 0.8)           // #efe3cc
}

private func serifNumber(_ size: CGFloat) -> Font { .custom("DMSerifDisplay-Regular", size: size) }
private func georgia(_ size: CGFloat) -> Font { .custom("Georgia-Bold", size: size) }

/// The torn paper stubs under the binding.
struct TornEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let teeth = 34
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        for i in stride(from: teeth, through: 0, by: -1) {
            let x = rect.width * CGFloat(i) / CGFloat(teeth)
            let y = rect.height * CGFloat([0.35, 0.9, 0.5, 1.0, 0.25, 0.7][i % 6])
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.closeSubpath()
        return p
    }
}

struct BindingStrip: View {
    var height: CGFloat = 20
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Ink.binding
                HStack {
                    Circle().fill(Ink.hole).frame(width: height * 0.42, height: height * 0.42)
                    Spacer()
                    Circle().fill(Ink.hole).frame(width: height * 0.42, height: height * 0.42)
                }
                .padding(.horizontal, height * 1.3)
            }
            .frame(height: height)
            TornEdge().fill(Ink.stub).frame(height: 5)
        }
    }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Ink.paper
            Image("PaperGrain").resizable().scaledToFill().opacity(0.25).blendMode(.multiply)
        }
    }
}

struct DateBlock: View {
    let info: DayInfo
    let numberSize: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            Text("\(info.month) \(String(info.year))")
                .font(georgia(11)).tracking(0.5).foregroundColor(Ink.ink)
            Text("\(info.d)")
                .font(serifNumber(numberSize)).tracking(-numberSize * 0.06)
                .foregroundColor(info.red ? Ink.red : Ink.ink)
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(info.day)
                .font(georgia(numberSize * 0.21)).tracking(numberSize * 0.03)
                .foregroundColor(info.red ? Ink.red : Ink.ink)
                .minimumScaleFactor(0.6).lineLimit(1)
        }
    }
}

struct SmallSheet: View {
    let info: DayInfo
    var body: some View {
        VStack(spacing: 0) {
            BindingStrip()
            Spacer(minLength: 2)
            DateBlock(info: info, numberSize: 74)
            Spacer(minLength: 6)
        }
    }
}

struct PeribahasaBlock: View {
    let info: DayInfo
    var lines: Int = 2
    var body: some View {
        if let p = info.peribahasa, !p.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("“\(p)”").font(serifNumber(16)).foregroundColor(Ink.ink).lineLimit(lines)
                if let m = info.maksud { Text(m).font(.system(size: 11)).foregroundColor(Ink.ink.opacity(0.72)).lineLimit(lines) }
            }
        }
    }
}

struct EventLines: View {
    let info: DayInfo
    let max: Int
    var body: some View {
        let list = Array((info.events ?? []).prefix(max))
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(list, id: \.self) { e in
                    HStack(spacing: 0) {
                        Text(e.time.isEmpty ? "Hari" : e.time)
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .frame(width: 44, alignment: .leading)
                        Rectangle().fill(Ink.rule).frame(width: 1)
                        Text(e.title).font(.system(size: 12, weight: .semibold)).lineLimit(1).padding(.leading, 7)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 21)
                    .overlay(Rectangle().fill(Ink.rule.opacity(0.6)).frame(height: 0.5), alignment: .bottom)
                }
            }
            .foregroundColor(Ink.ink)
            .overlay(Rectangle().fill(Ink.rule.opacity(0.6)).frame(height: 0.5), alignment: .top)
        }
    }
}

struct MediumSheet: View {
    let info: DayInfo
    var body: some View {
        VStack(spacing: 0) {
            BindingStrip()
            HStack(alignment: .top, spacing: 12) {
                DateBlock(info: info, numberSize: 70).frame(width: 112)
                Rectangle().fill(Ink.rule).frame(width: 1).padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(info.dayZh ?? "")  ·  \(info.dayEn)").font(georgia(10)).foregroundColor(Ink.ink)
                    if let h = info.holiday, !h.isEmpty {
                        Text(h).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1).background(Ink.red)
                    }
                    PeribahasaBlock(info: info)
                    Spacer(minLength: 0)
                    EventLines(info: info, max: 1)
                }
            }
            .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 12)
        }
    }
}

struct MiniMonth: View {
    let info: DayInfo
    var body: some View {
        let cal = Sheet.calendar
        let first = cal.date(from: DateComponents(year: info.year, month: monthIndex + 1, day: 1)) ?? Date()
        let offset = (cal.component(.weekday, from: first) + 5) % 7
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let cells = Array(repeating: 0, count: offset) + Array(1...count)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        LazyVGrid(columns: cols, spacing: 2) {
            ForEach(Array(["I", "S", "R", "K", "J", "S", "A"].enumerated()), id: \.offset) { i, l in
                Text(l).font(georgia(9)).foregroundColor(i == 6 ? Ink.red : Ink.ink)
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { i, n in
                Text(n == 0 ? "" : "\(n)")
                    .font(.custom("Georgia", size: 10).weight(n == info.d ? .bold : .regular))
                    .foregroundColor(i % 7 == 6 || n == info.d ? Ink.red : Ink.ink)
                    .underline(n == info.d, color: Ink.red)
            }
        }
    }
    private var monthIndex: Int { Sheet.months.firstIndex(of: info.month) ?? 0 }
}

struct LargeSheet: View {
    let info: DayInfo
    var body: some View {
        VStack(spacing: 0) {
            BindingStrip(height: 24)
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    DateBlock(info: info, numberSize: 96).frame(width: 140)
                    Rectangle().fill(Ink.rule).frame(width: 1)
                    MiniMonth(info: info)
                }
                .frame(height: 150)
                Rectangle().fill(Ink.rule).frame(height: 1)
                Text("\(info.dayZh ?? "")   \(info.dayEn)").font(georgia(12)).foregroundColor(Ink.ink)
                if let h = info.holiday, !h.isEmpty {
                    Text(h).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Ink.red)
                }
                PeribahasaBlock(info: info, lines: 3).frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                EventLines(info: info, max: 3)
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 14)
        }
    }
}

// MARK: - Lock screen

struct LockInline: View {
    let info: DayInfo
    var body: some View {
        Text("\(info.day.capitalized) \(info.d) · \(info.peribahasa ?? info.month.capitalized)")
    }
}

struct LockCircular: View {
    let info: DayInfo
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(String(info.day.prefix(3))).font(.system(size: 10, weight: .semibold))
                Text("\(info.d)").font(serifNumber(26))
            }
        }
    }
}

struct LockRectangular: View {
    let info: DayInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(info.day) \(info.d) \(String(info.month.prefix(3)))").font(.system(size: 13, weight: .bold)).widgetAccentable()
            if let e = info.events?.first {
                Text("\(e.time.isEmpty ? "Hari ini" : e.time)  \(e.title)").font(.system(size: 12)).lineLimit(1)
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
    let entry: SheetEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            LockInline(info: entry.info).widgetBackground { Color.clear }
        case .accessoryCircular:
            LockCircular(info: entry.info).widgetBackground { Color.clear }
        case .accessoryRectangular:
            LockRectangular(info: entry.info).widgetBackground { Color.clear }
        case .systemMedium:
            MediumSheet(info: entry.info).widgetBackground { PaperBackground() }
        case .systemLarge, .systemExtraLarge:
            LargeSheet(info: entry.info).widgetBackground { PaperBackground() }
        default:
            SmallSheet(info: entry.info).widgetBackground { PaperBackground() }
        }
    }
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
    let kind = "SehariTearOff"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SheetProvider()) { entry in
            SehariWidgetView(entry: entry)
        }
        .configurationDisplayName("Kalendar Koyak")
        .description("Helaian hari ini: tarikh, peribahasa dan acara seterusnya.")
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
