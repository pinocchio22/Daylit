import SwiftUI

struct SettingsView: View {
    @ObservedObject var memoStore: MemoStore
    @AppStorage("useICloudSync") private var useICloudSync = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("iCloud 동기화", isOn: $useICloudSync)
                } header: {
                    Text("동기화")
                } footer: {
                    if useICloudSync {
                        Text("iCloud를 통해 여러 기기 간 메모를 동기화합니다. (개발자 계정 필요)")
                    } else {
                        Text("이 기기에만 메모를 저장합니다.")
                    }
                }

                Section {
                    ForEach(memoStore.categories.indices, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(memoStore.categories[index].uiColor)
                                .frame(width: 12, height: 12)
                            Text(memoStore.categories[index].name)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { memoStore.categories[index].notificationEnabled },
                                set: { newValue in
                                    memoStore.updateCategoryNotification(at: index, enabled: newValue)
                                }
                            ))
                        }
                    }
                } header: {
                    Text("카테고리별 알림")
                } footer: {
                    Text("알림이 켜진 카테고리의 메모만 아침 8시에 알림을 받습니다.")
                }

                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("앱 정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
