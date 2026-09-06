import SwiftUI

struct SettingsView: View {
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
