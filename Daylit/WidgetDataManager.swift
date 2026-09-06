import Foundation

// MARK: - Widget용 간단한 메모 데이터 구조
struct WidgetMemo: Codable {
    let id: String
    let title: String
    let createdAt: Date
    let categoryName: String
    let categoryColor: String

    init(id: String, title: String, createdAt: Date, categoryName: String, categoryColor: String) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.categoryName = categoryName
        self.categoryColor = categoryColor
    }
}

// MARK: - App Group을 통한 데이터 공유 관리자
class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupID = "group.com.p2glet.Daylit"
    private let memosKey = "widget_memos"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // 메모 저장
    func saveMemos(_ memos: [WidgetMemo]) {
        guard let encoded = try? JSONEncoder().encode(memos) else { return }
        userDefaults?.set(encoded, forKey: memosKey)
        userDefaults?.synchronize()
    }

    // 메모 로드
    func loadMemos() -> [WidgetMemo] {
        print("🔍 WidgetDataManager - Loading memos from App Group")
        guard let data = userDefaults?.data(forKey: memosKey) else {
            print("❌ No data found for key: \(memosKey)")
            return []
        }

        print("✅ Data found: \(data.count) bytes")

        guard let memos = try? JSONDecoder().decode([WidgetMemo].self, from: data) else {
            print("❌ Failed to decode memos")
            return []
        }

        print("✅ Loaded \(memos.count) memos:")
        for memo in memos {
            print("  - \(memo.title) at \(memo.createdAt)")
        }

        return memos
    }

    // 이번 주 메모를 날짜별로 그룹화
    func getThisWeekMemos() -> [(date: Date, memos: [WidgetMemo])] {
        print("📅 WidgetDataManager - Getting this week's memos")
        let allMemos = loadMemos()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        print("📅 Today: \(today)")
        print("📅 Total memos loaded: \(allMemos.count)")

        // 이번 주 월요일 찾기
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            print("❌ Failed to calculate Monday")
            return []
        }

        print("📅 Monday of this week: \(monday)")
        print("📅 Weekday: \(weekday), daysFromMonday: \(daysFromMonday)")

        // 월요일부터 일요일까지 7일 생성
        var weekData: [(date: Date, memos: [WidgetMemo])] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: monday) else { continue }

            // 실제 메모 필터링
            let memosForDate = allMemos.filter { memo in
                let isSameDay = calendar.isDate(memo.createdAt, inSameDayAs: date)
                if isSameDay {
                    print("  ✅ Memo '\(memo.title)' matches date \(date)")
                }
                return isSameDay
            }

            print("📅 Day \(i) (\(date)): \(memosForDate.count) memos")
            weekData.append((date: date, memos: memosForDate))
        }

        return weekData
    }
}
