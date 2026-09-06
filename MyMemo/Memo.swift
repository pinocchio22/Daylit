import Foundation
import SwiftUI
import WidgetKit

extension Color {
    // Color를 Hex String으로 변환
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#808080" // 기본 회색
        }

        let r = components[0]
        let g = components.count > 1 ? components[1] : components[0]
        let b = components.count > 2 ? components[2] : components[0]

        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }

    // Hex String을 Color로 변환
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct Category: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var color: String // Hex 색상 저장 (예: "#FF5733")

    static let defaultCategories = [
        Category(name: "업무", color: "#007AFF"),    // 파란색
        Category(name: "개인", color: "#34C759"),    // 초록색
        Category(name: "아이디어", color: "#AF52DE")  // 보라색
    ]

    var uiColor: Color {
        Color(hex: color)
    }
}

struct SearchHistory: Identifiable, Codable {
    var id = UUID()
    var query: String
    var searchedAt: Date

    init(query: String) {
        self.query = query
        self.searchedAt = Date()
    }
}

struct Memo: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date
    var category: Category

    init(title: String, content: String, category: Category, createdAt: Date = Date()) {
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.category = category
    }
}

class MemoStore: ObservableObject {
    @Published var memos: [Memo] = []
    @Published var categories: [Category] = []
    @Published var searchHistory: [SearchHistory] = []

    private let memosKey = "memos"
    private let categoriesKey = "categories"
    private let searchHistoryKey = "searchHistory"

    private let iCloudStore = NSUbiquitousKeyValueStore.default

    // iCloud 동기화 사용 여부
    private var useICloudSync: Bool {
        UserDefaults.standard.bool(forKey: "useICloudSync")
    }

    init() {
        loadCategories()
        loadMemos()
        loadSearchHistory()

        // iCloud 변경 사항 감지를 위한 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        // 설정 변경 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )

        // iCloud 동기화 시작 (설정이 켜져있을 때만)
        if useICloudSync {
            iCloudStore.synchronize()
        }

        // 위젯 초기 동기화 - 기존 메모를 위젯에 전달
        syncToWidget()
    }

    private func syncToWidget() {
        let widgetMemos = memos.map { memo in
            WidgetMemo(
                id: memo.id.uuidString,
                title: memo.title,
                createdAt: memo.createdAt,
                categoryName: memo.category.name,
                categoryColor: memo.category.color
            )
        }
        WidgetDataManager.shared.saveMemos(widgetMemos)
        WidgetCenter.shared.reloadAllTimelines()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func iCloudStoreDidChange(notification: Notification) {
        // iCloud가 활성화되어 있을 때만 변경 사항 반영
        if useICloudSync {
            DispatchQueue.main.async { [weak self] in
                self?.loadMemos()
                self?.loadCategories()
                self?.loadSearchHistory()
            }
        }
    }

    @objc private func settingsDidChange(notification: Notification) {
        // 설정이 변경되면 데이터 다시 로드
        DispatchQueue.main.async { [weak self] in
            self?.loadMemos()
            self?.loadCategories()
            self?.loadSearchHistory()
        }
    }

    func addMemo(title: String, content: String, category: Category, createdAt: Date = Date()) {
        let memo = Memo(title: title, content: content, category: category, createdAt: createdAt)
        memos.insert(memo, at: 0)
        saveMemos()
    }

    func deleteMemo(at offsets: IndexSet) {
        memos.remove(atOffsets: offsets)
        saveMemos()
    }

    func deleteMemo(_ memo: Memo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos.remove(at: index)
            saveMemos()
        }
    }

    func addCategory(_ category: Category) {
        if !categories.contains(where: { $0.name == category.name }) {
            categories.append(category)
            saveCategories()
        }
    }

    func addCategory(name: String, color: String) {
        let category = Category(name: name, color: color)
        addCategory(category)
    }

    private func saveMemos() {
        if let encoded = try? JSONEncoder().encode(memos) {
            if useICloudSync {
                iCloudStore.set(encoded, forKey: memosKey)
                iCloudStore.synchronize()
            } else {
                UserDefaults.standard.set(encoded, forKey: memosKey)
            }
        }

        // 위젯 동기화
        syncToWidget()
    }

    private func loadMemos() {
        let data: Data?
        if useICloudSync {
            data = iCloudStore.data(forKey: memosKey)
        } else {
            data = UserDefaults.standard.data(forKey: memosKey)
        }

        if let data = data,
           let decoded = try? JSONDecoder().decode([Memo].self, from: data) {
            memos = decoded
        }
    }

    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            if useICloudSync {
                iCloudStore.set(encoded, forKey: categoriesKey)
                iCloudStore.synchronize()
            } else {
                UserDefaults.standard.set(encoded, forKey: categoriesKey)
            }
        }
    }

    private func loadCategories() {
        let data: Data?
        if useICloudSync {
            data = iCloudStore.data(forKey: categoriesKey)
        } else {
            data = UserDefaults.standard.data(forKey: categoriesKey)
        }

        if let data = data,
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        } else {
            categories = Category.defaultCategories
            saveCategories()
        }
    }

    func addSearchHistory(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 중복 제거
        searchHistory.removeAll { $0.query == query }

        // 새로운 검색 기록 추가
        let history = SearchHistory(query: query)
        searchHistory.insert(history, at: 0)

        // 최대 10개까지만 저장
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }

        saveSearchHistory()
    }

    func deleteSearchHistory(_ history: SearchHistory) {
        if let index = searchHistory.firstIndex(where: { $0.id == history.id }) {
            searchHistory.remove(at: index)
            saveSearchHistory()
        }
    }

    func clearAllSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }

    private func saveSearchHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            if useICloudSync {
                iCloudStore.set(encoded, forKey: searchHistoryKey)
                iCloudStore.synchronize()
            } else {
                UserDefaults.standard.set(encoded, forKey: searchHistoryKey)
            }
        }
    }

    private func loadSearchHistory() {
        let data: Data?
        if useICloudSync {
            data = iCloudStore.data(forKey: searchHistoryKey)
        } else {
            data = UserDefaults.standard.data(forKey: searchHistoryKey)
        }

        if let data = data,
           let decoded = try? JSONDecoder().decode([SearchHistory].self, from: data) {
            searchHistory = decoded
        }
    }
}
