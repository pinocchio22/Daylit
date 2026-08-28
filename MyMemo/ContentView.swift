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
    @State private var selectedMemos = Set<UUID>()
    @State private var showingDeleteAlert = false

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
                                selectedMemos.removeAll()
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

                    if editMode?.wrappedValue.isEditing == true {
                        Button(action: {
                            if !selectedMemos.isEmpty {
                                showingDeleteAlert = true
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: selectedMemos.isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [Color.red, Color.red.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: selectedMemos.isEmpty ? Color.gray.opacity(0.3) : Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(selectedMemos.isEmpty)
                    } else {
                        Button(action: {
                            showingAddMemo = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
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
                                    let isEditing = editMode?.wrappedValue.isEditing == true
                                    let isSelected = selectedMemos.contains(memo.id)

                                    if isEditing {
                                        HStack(spacing: 12) {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(isSelected ? .blue : .gray.opacity(0.3))

                                            NavigationLink(destination: MemoDetailView(memo: memo, memoStore: memoStore)) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Text(memo.title)
                                                            .font(.headline)
                                                            .fontWeight(.semibold)
                                                        Spacer()
                                                        HStack(spacing: 4) {
                                                            Circle()
                                                                .fill(memo.category.uiColor)
                                                                .frame(width: 8, height: 8)
                                                            Text(memo.category.name)
                                                                .font(.caption)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(memo.category.uiColor)
                                                        }
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(
                                                            memo.category.uiColor.opacity(0.15)
                                                        )
                                                        .cornerRadius(12)
                                                    }
                                                    Text(memo.content)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                    HStack {
                                                        Image(systemName: "calendar")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.gray)
                                                        Text(memo.createdAt, style: .date)
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 4)
                                            }
                                            .disabled(true)
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if isSelected {
                                                    selectedMemos.remove(memo.id)
                                                } else {
                                                    selectedMemos.insert(memo.id)
                                                }
                                            }
                                        }
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isSelected ? Color.blue.opacity(0.05) : Color(uiColor: .systemBackground))
                                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                                .padding(.vertical, 4)
                                        )
                                        .listRowSeparator(.hidden)
                                    } else {
                                        NavigationLink(destination: MemoDetailView(memo: memo, memoStore: memoStore)) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Text(memo.title)
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(memo.category.uiColor)
                                                            .frame(width: 8, height: 8)
                                                        Text(memo.category.name)
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(memo.category.uiColor)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(
                                                        memo.category.uiColor.opacity(0.15)
                                                    )
                                                    .cornerRadius(12)
                                                }
                                                Text(memo.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                HStack {
                                                    Image(systemName: "calendar")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.gray)
                                                    Text(memo.createdAt, style: .date)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 4)
                                        }
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(uiColor: .systemBackground))
                                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                                .padding(.vertical, 4)
                                        )
                                        .listRowSeparator(.hidden)
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
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        searchText = history.query
                                        searchQuery = history.query
                                        isSearchFieldFocused = false
                                        showingSearchHistory = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.blue.opacity(0.7))
                                            .font(.system(size: 15))
                                        Text(history.query)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 15))
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                memoStore.deleteSearchHistory(history)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .font(.system(size: 16))
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(uiColor: .systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())

                                if history.id != memoStore.searchHistory.last?.id {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                    }
                }
            }
            .sheet(isPresented: $showingAddMemo) {
                AddMemoView(memoStore: memoStore)
            }
            .alert("메모 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        for memoId in selectedMemos {
                            if let memo = memoStore.memos.first(where: { $0.id == memoId }) {
                                memoStore.deleteMemo(memo)
                            }
                        }
                        selectedMemos.removeAll()
                        editMode?.wrappedValue = .inactive
                    }
                }
            } message: {
                Text("\(selectedMemos.count)개의 메모를 삭제하시겠습니까?")
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 6) {
                if title != "전체" {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                            )
                    } else {
                        Capsule()
                            .fill(Color(uiColor: .systemGray6))
                    }
                }
            )
            .foregroundColor(isSelected ? color : .primary)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
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
    @State private var newCategoryColor = Color.blue

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
                    Menu {
                        ForEach(memoStore.categories) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack {
                                    Circle()
                                        .fill(category.uiColor)
                                        .frame(width: 12, height: 12)
                                    Text(category.name)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let category = selectedCategory {
                                Circle()
                                    .fill(category.uiColor)
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text("카테고리 선택")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
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
                            ColorPicker("색상 선택", selection: $newCategoryColor)
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
                                    memoStore.addCategory(name: newCategoryName, color: newCategoryColor.toHex())
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

// Custom Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
