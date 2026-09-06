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
    }

    // 메모 로드
    func loadMemos() -> [WidgetMemo] {
        print("🔥 [WidgetDataManager] loadMemos() 시작")
        print("🔥 [WidgetDataManager] appGroupID: \(appGroupID)")
        print("🔥 [WidgetDataManager] userDefaults 존재 여부: \(userDefaults != nil)")

        guard let data = userDefaults?.data(forKey: memosKey) else {
            print("🔥 [WidgetDataManager] ❌ UserDefaults에서 '\(memosKey)' 키로 데이터를 찾을 수 없음")
            print("🔥 [WidgetDataManager] UserDefaults 전체 키 목록: \(userDefaults?.dictionaryRepresentation().keys.sorted() ?? [])")
            return []
        }

        print("🔥 [WidgetDataManager] ✅ 데이터 로드 성공. 크기: \(data.count) bytes")

        guard let memos = try? JSONDecoder().decode([WidgetMemo].self, from: data) else {
            print("🔥 [WidgetDataManager] ❌ JSON 디코딩 실패")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔥 [WidgetDataManager] Raw JSON: \(jsonString)")
            }
            return []
        }

        print("🔥 [WidgetDataManager] ✅ 디코딩 성공. 메모 개수: \(memos.count)")
        for (idx, memo) in memos.enumerated() {
            print("🔥 [WidgetDataManager]   [\(idx)] id=\(memo.id), title='\(memo.title)', category=\(memo.categoryName)")
        }

        return memos
    }

    // 이번 주 메모를 날짜별로 그룹화
    func getThisWeekMemos() -> [(date: Date, memos: [WidgetMemo])] {
        let allMemos = loadMemos()
        let calendar = Calendar.current
        let today = Date()

        // 이번 주 시작일 찾기 (월요일)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }

        // 월요일부터 일요일까지 7일 생성
        var weekDates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                weekDates.append(calendar.startOfDay(for: date))
            }
        }

        // 각 날짜별로 메모 그룹화
        return weekDates.map { date in
            let memosForDate = allMemos.filter { memo in
                calendar.isDate(memo.createdAt, inSameDayAs: date)
            }
            return (date: date, memos: memosForDate)
        }
    }
}
