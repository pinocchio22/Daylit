import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - 권한 요청
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ 알림 권한 요청 실패: \(error)")
                completion(false)
                return
            }
            print(granted ? "✅ 알림 권한 허용됨" : "❌ 알림 권한 거부됨")
            completion(granted)
        }
    }

    // MARK: - 알림 상태 확인
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }

    // MARK: - 모든 알림 갱신
    func refreshAllNotifications(memos: [Memo], categories: [Category]) {
        print("🔔 알림 전체 갱신 시작")

        // 기존 알림 모두 제거
        notificationCenter.removeAllPendingNotificationRequests()

        // 카테고리별로 알림이 활성화된 메모만 필터링
        let enabledCategoryIds = Set(categories.filter { $0.notificationEnabled }.map { $0.id })
        let notifiableMemos = memos.filter { memo in
            enabledCategoryIds.contains(memo.category.id)
        }

        print("📝 알림 대상 메모: \(notifiableMemos.count)개 (전체: \(memos.count)개)")

        // 날짜별로 메모 그룹화
        let calendar = Calendar.current
        var memosByDate: [Date: [Memo]] = [:]

        for memo in notifiableMemos {
            let dateOnly = calendar.startOfDay(for: memo.createdAt)
            memosByDate[dateOnly, default: []].append(memo)
        }

        print("📅 알림 설정할 날짜: \(memosByDate.keys.count)개")

        // 각 날짜에 대해 아침 8시 알림 스케줄링
        for (date, memosForDate) in memosByDate {
            scheduleNotification(for: date, memos: memosForDate)
        }

        // 예약된 알림 확인
        notificationCenter.getPendingNotificationRequests { requests in
            print("✅ 예약된 알림: \(requests.count)개")
            for request in requests {
                print("  - \(request.identifier): \(request.content.title)")
            }
        }
    }

    // MARK: - 특정 날짜에 대한 알림 스케줄링
    private func scheduleNotification(for date: Date, memos: [Memo]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)

        // 과거 날짜는 스케줄링하지 않음
        guard targetDate >= today else {
            print("⏭️  과거 날짜 스킵: \(date)")
            return
        }

        // 알림 내용 구성
        let titles = memos.map { $0.title }
        let body = titles.joined(separator: ", ")

        let content = UNMutableNotificationContent()
        content.title = "오늘의 메모"
        content.body = body
        content.sound = .default

        // 해당 날짜 아침 8시로 설정
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // 고유 ID: 날짜를 문자열로 사용
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let identifier = "memo-\(dateFormatter.string(from: targetDate))"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 알림 스케줄링 실패 (\(identifier)): \(error)")
            } else {
                print("✅ 알림 스케줄링 성공: \(identifier) - \(body)")
                if let triggerDate = calendar.date(from: dateComponents) {
                    print("   예정 시각: \(triggerDate)")
                }
            }
        }
    }

    // MARK: - 테스트용 즉시 알림 (1분 후)
    func scheduleTestNotification(memos: [Memo]) {
        let titles = memos.prefix(3).map { $0.title }
        let body = titles.joined(separator: ", ")

        let content = UNMutableNotificationContent()
        content.title = "테스트: 오늘의 메모"
        content.body = body
        content.sound = .default

        // 1분 후 알림
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 테스트 알림 실패: \(error)")
            } else {
                print("✅ 테스트 알림 스케줄링 성공 (1분 후)")
            }
        }
    }
}
