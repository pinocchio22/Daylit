import SwiftUI

struct MemoDetailView: View {
    let memo: Memo
    @ObservedObject var memoStore: MemoStore
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(memo.title)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(memo.category.uiColor)
                            .frame(width: 10, height: 10)
                        Text(memo.category.name)
                            .font(.subheadline)
                            .foregroundColor(memo.category.uiColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(memo.category.uiColor.opacity(0.1))
                    .cornerRadius(12)

                    Text(memo.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Divider()

                Text(memo.content)
                    .font(.body)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("메모 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("메모 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                memoStore.deleteMemo(memo)
                dismiss()
            }
        } message: {
            Text("이 메모를 삭제하시겠습니까?")
        }
    }
}
