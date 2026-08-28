import Foundation
import SwiftUI

struct Category: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var color: String

    static let defaultCategories = [
        Category(name: "업무", color: "blue"),
        Category(name: "개인", color: "green"),
        Category(name: "아이디어", color: "purple")
    ]

    var uiColor: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .gray
        }
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

    init() {
        loadCategories()
        loadMemos()
        loadSearchHistory()
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
            UserDefaults.standard.set(encoded, forKey: memosKey)
        }
    }

    private func loadMemos() {
        if let data = UserDefaults.standard.data(forKey: memosKey),
           let decoded = try? JSONDecoder().decode([Memo].self, from: data) {
            memos = decoded
        }
    }

    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }

    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
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
            UserDefaults.standard.set(encoded, forKey: searchHistoryKey)
        }
    }

    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: searchHistoryKey),
           let decoded = try? JSONDecoder().decode([SearchHistory].self, from: data) {
            searchHistory = decoded
        }
    }
}
