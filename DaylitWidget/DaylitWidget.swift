import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct MemoEntry: TimelineEntry {
    let date: Date
    let weekData: [(date: Date, memos: [WidgetMemo])]
}

// MARK: - Timeline Provider
struct MemoTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoEntry {
        MemoEntry(date: Date(), weekData: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoEntry) -> Void) {
        let weekData = WidgetDataManager.shared.getThisWeekMemos()
        let entry = MemoEntry(date: Date(), weekData: weekData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoEntry>) -> Void) {
        print("🔥🔥🔥 getTimeline() CALLED 🔥🔥🔥")
        let currentDate = Date()

        // 먼저 전체 메모 로드 확인
        let allMemos = WidgetDataManager.shared.loadMemos()
        print("🔥 [getTimeline] 전체 메모 개수: \(allMemos.count)")

        let weekData = WidgetDataManager.shared.getThisWeekMemos()
        print("🔥 [getTimeline] weekData count: \(weekData.count)")

        for (index, dayData) in weekData.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d (E)"
            dateFormatter.locale = Locale(identifier: "ko_KR")
            let dateStr = dateFormatter.string(from: dayData.date)

            print("🔥 [getTimeline] Day \(index) [\(dateStr)]: \(dayData.memos.count) memos")
            for (memoIdx, memo) in dayData.memos.enumerated() {
                print("🔥 [getTimeline]   [\(memoIdx)] '\(memo.title)' (\(memo.categoryName))")
            }
        }

        let entry = MemoEntry(date: currentDate, weekData: weekData)
        print("🔥 [getTimeline] ✅ Entry 생성 완료. entry.weekData.count = \(entry.weekData.count)")

        // 1시간마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct DaylitWidgetView: View {
    let entry: MemoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("이번 주 메모")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                ForEach(entry.weekData, id: \.date) { dayData in
                    DayColumn(date: dayData.date, memos: dayData.memos)
                    if dayData.date != entry.weekData.last?.date {
                        Divider()
                    }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Day Column
struct DayColumn: View {
    let date: Date
    let memos: [WidgetMemo]

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "d"
        return formatter
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter
    }

    var body: some View {
        VStack(spacing: 4) {
            // 날짜
            Text(dayFormatter.string(from: date))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            // 요일
            Text(weekdayFormatter.string(from: date))
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            Spacer()

            // 메모 표시
            if memos.isEmpty {
                Text("-")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.5))
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    let displayMemos = Array(memos.prefix(2))
                    ForEach(displayMemos, id: \.id) { memo in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color(hex: memo.categoryColor) ?? .gray)
                                .frame(width: 4, height: 4)
                            Text(memo.title)
                                .font(.system(size: 8))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }
                    }

                    if memos.count > 2 {
                        Text("외 \(memos.count - 2)개")
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration
struct DaylitWidget: Widget {
    let kind: String = "DaylitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                DaylitWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DaylitWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("이번 주 메모")
        .description("이번 주 작성한 메모를 확인하세요")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    DaylitWidget()
} timeline: {
    MemoEntry(date: Date(), weekData: [])
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
