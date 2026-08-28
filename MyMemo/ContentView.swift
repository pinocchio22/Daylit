import SwiftUI

struct ContentView: View {
    @StateObject private var memoStore = MemoStore()
    @State private var showingAddMemo = false
    @State private var showingSearchHistory = false
    @State private var selectedFilter: Category?
    @State private var searchText = ""
    @State private var searchQuery = ""
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.editMode) var editMode

    var filteredMemos: [Memo] {
        var memos = memoStore.memos

        // 카테고리 필터링
        if let filter = selectedFilter {
            memos = memos.filter { $0.category.id == filter.id }
        }

        // 검색어 필터링 - searchQuery 사용 (버튼 클릭 시에만 업데이트됨)
        if !searchQuery.isEmpty {
            memos = memos.filter { memo in
                memo.title.localizedCaseInsensitiveContains(searchQuery) ||
                memo.content.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return memos
    }

    func performSearch() {
        if !searchText.isEmpty {
            searchQuery = searchText
            memoStore.addSearchHistory(query: searchText)
            isSearchFieldFocused = false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 바: 편집 + 검색창 + 추가 버튼
                HStack(spacing: 12) {
                    Button(editMode?.wrappedValue.isEditing == true ? "완료" : "편집") {
                        withAnimation {
                            if editMode?.wrappedValue.isEditing == true {
                                editMode?.wrappedValue = .inactive
                            } else {
                                editMode?.wrappedValue = .active
                            }
                        }
                    }
                    .foregroundColor(.blue)

                    // 검색창
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        TextField("메모 검색", text: $searchText)
                            .focused($isSearchFieldFocused)
                            .onSubmit {
                                performSearch()
                            }
                            .onChange(of: isSearchFieldFocused) { isFocused in
                                if isFocused && searchText.isEmpty {
                                    showingSearchHistory = true
                                } else {
                                    showingSearchHistory = false
                                }
                            }
                            .font(.system(size: 15))

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchQuery = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }

                            Button(action: {
                                performSearch()
                            }) {
                                Text("검색")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)

                    Button(action: {
                        showingAddMemo = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemBackground))

                // 카테고리 필터 + 메모 리스트 + 검색 기록 오버레이
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        // 카테고리 필터
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "전체",
                                    isSelected: selectedFilter == nil,
                                    color: .gray
                                ) {
                                    selectedFilter = nil
                                }
                                ForEach(memoStore.categories) { category in
                                    FilterChip(
                                        title: category.name,
                                        isSelected: selectedFilter?.id == category.id,
                                        color: category.uiColor
                                    ) {
                                        selectedFilter = category
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .background(Color(uiColor: .systemBackground))

                        // 메모 리스트
                        List {
                            if filteredMemos.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: searchQuery.isEmpty ? "note.text" : "magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text(searchQuery.isEmpty ? "메모가 없습니다" : "검색 결과가 없습니다")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else {
                                ForEach(filteredMemos) { memo in
                                    NavigationLink(destination: MemoDetailView(memo: memo, memoStore: memoStore)) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Text(memo.title)
                                                    .font(.headline)
                                                Spacer()
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(memo.category.uiColor)
                                                        .frame(width: 8, height: 8)
                                                    Text(memo.category.name)
                                                        .font(.caption)
                                                        .foregroundColor(memo.category.uiColor)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(memo.category.uiColor.opacity(0.1))
                                                .cornerRadius(8)
                                            }
                                            Text(memo.content)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                            Text(memo.createdAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 5)
                                    }
                                }
                                .onDelete { indexSet in
                                    let memosToDelete = indexSet.map { filteredMemos[$0] }
                                    for memo in memosToDelete {
                                        memoStore.deleteMemo(memo)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }

                    // 검색 기록 오버레이 (검색창 바로 아래, 화면 위에 떠있음)
                    if showingSearchHistory && !memoStore.searchHistory.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(memoStore.searchHistory) { history in
                                Button(action: {
                                    searchText = history.query
                                    searchQuery = history.query
                                    isSearchFieldFocused = false
                                    showingSearchHistory = false
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                        Text(history.query)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 15))
                                        Spacer()
                                        Button(action: {
                                            memoStore.deleteSearchHistory(history)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if history.id != memoStore.searchHistory.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(uiColor: .systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)  // 약간의 간격
                    }
                }
            }
            .sheet(isPresented: $showingAddMemo) {
                AddMemoView(memoStore: memoStore)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if title != "전체" {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : Color(uiColor: .systemGray6))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(16)
        }
    }
}

struct AddMemoView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var memoStore: MemoStore
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate = Date()
    @State private var showingCalendar = false
    @State private var showingTimePicker = false
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = "blue"

    let availableColors = ["blue", "green", "purple", "red", "orange", "yellow"]

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"
        return formatter
    }

    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("제목")) {
                    TextField("제목을 입력하세요", text: $title)
                }
                Section(header: Text("카테고리")) {
                    Picker("카테고리 선택", selection: $selectedCategory) {
                        ForEach(memoStore.categories) { category in
                            HStack {
                                Circle()
                                    .fill(category.uiColor)
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(Optional(category))
                        }
                    }
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("새 카테고리 추가")
                        }
                    }
                }
                Section(header: Text("내용")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                Section(header: Text("날짜")) {
                    Button(action: {
                        withAnimation {
                            showingCalendar.toggle()
                        }
                    }) {
                        HStack {
                            Text("날짜")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(dateFormatter.string(from: selectedDate))
                                .foregroundColor(.secondary)
                            Image(systemName: showingCalendar ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }

                    if showingCalendar {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .labelsHidden()
                    }
                }
                Section(header: Text("시간")) {
                    Button(action: {
                        withAnimation {
                            showingTimePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("시간")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(timeFormatter.string(from: selectedDate))
                                .foregroundColor(.secondary)
                            Image(systemName: showingTimePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }

                    if showingTimePicker {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle("새 메모")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if !title.isEmpty, let category = selectedCategory {
                            memoStore.addMemo(title: title, content: content, category: category, createdAt: selectedDate)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || selectedCategory == nil)
                }
            }
            .onAppear {
                if selectedCategory == nil, !memoStore.categories.isEmpty {
                    selectedCategory = memoStore.categories[0]
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                NavigationStack {
                    Form {
                        Section(header: Text("카테고리 이름")) {
                            TextField("이름을 입력하세요", text: $newCategoryName)
                        }
                        Section(header: Text("색상")) {
                            Picker("색상 선택", selection: $newCategoryColor) {
                                ForEach(availableColors, id: \.self) { color in
                                    HStack {
                                        Circle()
                                            .fill(Category(name: "", color: color).uiColor)
                                            .frame(width: 20, height: 20)
                                        Text(color)
                                    }
                                    .tag(color)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .navigationTitle("새 카테고리")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("취소") {
                                showingAddCategory = false
                                newCategoryName = ""
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("추가") {
                                if !newCategoryName.isEmpty {
                                    memoStore.addCategory(name: newCategoryName, color: newCategoryColor)
                                    selectedCategory = memoStore.categories.last
                                    showingAddCategory = false
                                    newCategoryName = ""
                                }
                            }
                            .disabled(newCategoryName.isEmpty)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
