# Postmortem: 위젯 데이터 표시 문제

## 문제 요약
위젯이 홈 화면에 추가되지만 `getTimeline()`이 호출되지 않고, 호출되더라도 App Group 데이터를 읽지 못해 빈 화면만 표시됨.

**총 소요 기간**: 며칠간 미해결 → 2026-09-03에 최종 해결

---

## 시행착오 타임라인

### 0단계: 이전 세션들의 잘못된 결론 (며칠간)

**알려진 잘못된 시도들**:

사용자가 명시적으로 거부한 이전 세션의 결론들:

1. **❌ "시뮬레이터는 위젯을 지원하지 않는다"**
   - **왜 틀렸나**: iOS 시뮬레이터는 위젯을 완전히 지원함
   - **왜 이런 결론이 나왔나**: 아마도 위젯이 작동하지 않아서 환경 문제로 오판
   - **실제 원인**: 시뮬레이터 문제가 아니라 AppIcon 리소스 누락
   - **영향**: 실제 디바이스에서 테스트하려는 시도로 시간 낭비

2. **❌ "무료 Apple ID로는 App Group을 사용할 수 없다"**
   - **왜 틀렸나**: 무료 개발자 계정도 App Group 생성 가능
   - **왜 이런 결론이 나왔나**: App Group이 작동하지 않아서 계정 제한으로 오판
   - **실제 원인**: CODE_SIGN_ENTITLEMENTS 설정 누락
   - **영향**: 유료 계정 등록 고려 등 불필요한 우회 시도

**이 단계의 특징**:
- 진짜 원인(리소스/설정 누락)을 찾지 못하고 환경/권한 문제로 오판
- 시스템 로그를 제대로 확인하지 않았을 가능성
- "왜 안 되는가"보다 "어떻게 우회하나"에 집중

---

### 1단계: 체계적 디버깅 시작 (2026-09-03 초반)

**증상**:
- 위젯을 홈 화면에 추가해도 `getTimeline()` 함수가 호출되지 않음
- App Group (`group.com.p2glet.Daylit`) 설정은 되어있음
- 메인 앱에서 데이터를 저장하면 plist 파일에 정상적으로 기록됨
- `WidgetCenter.shared.reloadAllTimelines()` 호출도 코드에 존재

**이전 세션의 잘못된 결론들** (사용자가 명시적으로 거부):
- ❌ "시뮬레이터는 위젯을 지원하지 않는다" → **틀림**. 시뮬레이터는 위젯을 정상 지원함
- ❌ "무료 Apple ID로는 App Group을 사용할 수 없다" → **틀림**. 무료 계정도 App Group 생성 가능

**사용자 요청사항**:
- NSExtensionPointIdentifier 확인
- Bundle ID 구조 확인
- Widget target 빌드 설정 확인
- Widget scheme 직접 실행

### 2단계: 기본 설정 확인 (14:00 ~ 14:30)

**확인한 것들**:
1. **project.pbxproj 분석**:
   - 메인 앱 Bundle ID: `com.p2glet.Daylit` ✅
   - 위젯 Bundle ID: `com.p2glet.Daylit.DaylitWidget` ✅ (올바른 계층구조)
   - 위젯 타겟 존재 확인: `DaylitWidgetExtension` ✅

2. **Info.plist 확인**:
   - NSExtensionPointIdentifier = "com.apple.widgetkit-extension" ✅

3. **pluginkit 확인**:
   ```bash
   pluginkit -m -p com.apple.widgetkit-extension
   ```
   - 결과: `com.p2glet.Daylit.DaylitWidget(1.0)` 등록됨 ✅

4. **바이너리 심볼 확인**:
   ```bash
   strings .../debug.dylib | grep -i widget
   nm .../debug.dylib | grep getTimeline
   ```
   - 위젯 코드가 컴파일되어 있음 확인 ✅

**이 시점의 결론**:
설정은 모두 정상인데 chronod가 위젯을 호출하지 않는 것으로 보임. **하지만 진짜 원인은 아직 발견 못함**.

### 3단계: 실시간 로그 모니터링 시작 (14:30 ~ 14:50)

**시도한 방법**:
```bash
# chronod 로그 모니터링
xcrun simctl spawn <UUID> log stream --process chronod --level debug

# 위젯 프로세스 로그
xcrun simctl spawn <UUID> log stream --predicate 'processImagePath CONTAINS "DaylitWidget"'
```

**사용자 액션**: 위젯 삭제 → 재추가

**관찰된 현상**:
- chronod는 위젯 extension을 인식함
- 하지만 `getTimeline()` 호출 로그가 없음
- 위젯 프로세스 자체가 시작되지 않음

**새로운 가설**: 시스템이 위젯을 "유효하지 않은 extension"으로 취급하는 것 같음

### 4단계: 리소스 파일 확인 - 첫 번째 원인 발견 (14:50 ~ 15:00)

**사용자의 핵심 질문**:
> "Assets.xcassets 포함되어 있는지, AppIcon 존재하는지 확인해줘. WidgetKit은 최소한의 아이콘 리소스가 없으면 시스템이 조용히 무시함."

**확인 결과**:
```bash
ls DaylitWidget/Assets.xcassets/AppIcon.appiconset/
```
- `Contents.json` 존재 ✅
- **AppIcon.png 파일 없음** ❌

**Contents.json 내용**:
```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
      // "filename" 키 자체가 없음!
    }
  ]
}
```

### 🎯 **첫 번째 진짜 원인 발견: AppIcon 리소스 누락**

**이유**:
WidgetKit은 최소한의 AppIcon이 없으면 해당 extension을 유효하지 않은 것으로 간주하고 **조용히 무시**함. 에러 메시지도 없음.

**해결책**:
1. Swift로 1024x1024 파란색 placeholder 이미지 생성
2. `AppIcon.appiconset/AppIcon.png`로 저장
3. `Contents.json`에 `"filename": "AppIcon.png"` 추가

**재빌드 및 설치 후 결과**:
```
[Daylit.DaylitWidget-0D7AD1085F40] Session operation: 'getTimelines(1)' request.
reload: succeeded with 1 entries
```
✅ getTimeline()이 드디어 호출됨!

### 5단계: 데이터 표시 문제 발견 (15:00 ~ 15:10)

**새로운 증상**:
- 위젯이 화면에 표시됨
- chronod가 timeline을 성공적으로 로드
- **하지만 메모 데이터가 표시되지 않음** (빈 칸만 보임)

**가설**: Entry 구조체나 View 렌더링 문제?

**확인 작업**:
1. `DaylitWidget.swift` 읽기:
   - Entry 구조체: `weekData: [(date: Date, memos: [WidgetMemo])]` ✅
   - getTimeline()에서 `WidgetDataManager.shared.getThisWeekMemos()` 호출 ✅
   - View에서 `entry.weekData` 올바르게 참조 ✅

2. **위젯 프로세스 로그 확인**:
   ```
   found no value for key widget_memos in CFPrefsSearchListSource
   (Domain: group.com.p2glet.Daylit, Container: (null))
   ```

3. **App Group plist 직접 확인**:
   ```bash
   plutil -p .../Library/Preferences/group.com.p2glet.Daylit.plist
   ```
   결과:
   ```
   "widget_memos" => {length = 139, bytes = 0x5b7b2263...}
   ```
   **데이터는 plist에 존재함!** ✅

**모순 발견**:
- plist에는 데이터가 있음
- 위젯은 같은 App Group ID를 사용
- 하지만 UserDefaults로 읽으면 nil 반환

### 6단계: Entitlements 확인 - 두 번째 원인 발견 (15:10 ~ 15:20)

**의심점**: App Groups entitlement가 실제로 빌드된 바이너리에 포함되었는가?

**확인 방법**:
```bash
codesign -d --entitlements - /path/to/DaylitWidgetExtension.appex
```

**결과**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict></dict>  <!-- 비어있음! -->
</plist>
```

**메인 앱도 확인**:
```xml
<dict></dict>  <!-- 역시 비어있음! -->
```

**엔타이틀먼트 파일은 존재**:
```bash
ls -la DaylitWidget/
-rw-r--r--  DaylitWidget.entitlements  # 존재함!
```

**파일 내용**:
```xml
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.p2glet.Daylit</string>
    </array>
</dict>
```

### 🎯 **두 번째 진짜 원인 발견: CODE_SIGN_ENTITLEMENTS 설정 누락**

**project.pbxproj 확인**:
```
# 메인 앱 (Daylit target)
CODE_SIGN_ENTITLEMENTS = Daylit/Daylit.entitlements;  ✅

# 위젯 타겟 (DaylitWidgetExtension)
# CODE_SIGN_ENTITLEMENTS 설정이 아예 없음!  ❌
```

**해결책**:
`project.pbxproj`의 위젯 타겟 Debug/Release 설정에 추가:
```
CODE_SIGN_ENTITLEMENTS = DaylitWidget/DaylitWidget.entitlements;
```
(라인 454, 486)

**중간 빌드 파일 확인으로 검증**:
```bash
cat .../DaylitWidgetExtension.build/.../DaylitWidgetExtension.appex-Simulated.xcent
```
```xml
<dict>
    <key>application-identifier</key>
    <string>USP329MK32.com.p2glet.Daylit.DaylitWidget</string>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.p2glet.Daylit</string>
    </array>
</dict>
```
✅ 이제 entitlements가 빌드에 포함됨!

**재빌드 및 설치 후**:
✅ **위젯에 데이터가 정상적으로 표시됨!**

### 7단계: 부수적 문제 해결 (15:20 ~ 15:30)

**Xcode 빌드 에러**:
```
DaylitWidgetLiveActivity.swift:33:13 Generic parameter 'Expanded' could not be inferred
DaylitWidgetLiveActivity.swift:33:27 Result builder 'DynamicIslandExpandedContentBuilder' does not implement...
```

**원인**: iOS 18+ API를 deployment target iOS 16.0에서 사용

**해결**: availability 체크 추가
```swift
if #available(iOS 18.0, *) {
    // iOS 18+ 코드
} else {
    // fallback
}

@available(iOS 18.0, *)
#Preview(...) { ... }
```

---

## 진짜 원인 (최종 정리)

### 1. AppIcon 리소스 누락 ⭐⭐⭐
- **위치**: `DaylitWidget/Assets.xcassets/AppIcon.appiconset/`
- **문제**: `AppIcon.png` 파일 자체가 존재하지 않음
- **증상**: WidgetKit이 extension을 유효하지 않은 것으로 간주하고 chronod가 getTimeline()을 호출하지 않음
- **특징**: 에러 메시지가 전혀 없음. 시스템이 조용히 무시함
- **발견 방법**: 사용자의 경험 기반 제안
- **영향도**: 완전한 기능 불능 (위젯 프로세스 자체가 시작 안 됨)

### 2. CODE_SIGN_ENTITLEMENTS 빌드 설정 누락 ⭐⭐⭐
- **위치**: `Daylit.xcodeproj/project.pbxproj`
- **문제**: 위젯 타겟의 Debug/Release 빌드 설정에 `CODE_SIGN_ENTITLEMENTS` 키가 없음
- **증상**:
  - getTimeline()은 호출됨
  - App Group entitlements 파일은 존재
  - 하지만 실제 바이너리에 entitlements가 포함되지 않음
  - 결과적으로 UserDefaults(suiteName:)가 공유 데이터에 접근 불가
- **발견 방법**: `codesign -d --entitlements` 명령으로 실제 바이너리 확인
- **영향도**: 데이터 읽기 완전 실패

### 3. Live Activity iOS 18 API 호환성 (부수적)
- **위치**: `DaylitWidgetLiveActivity.swift`
- **문제**: iOS 18+ API를 iOS 16.0 deployment target에서 사용
- **해결**: `@available` 추가
- **영향도**: 빌드 에러 (위젯 기능과 무관)

---

## 효과 있었던 진단 방법

### 1. 실시간 chronod 로그 스트리밍 ⭐⭐⭐
```bash
xcrun simctl spawn <UUID> log stream --process chronod --level debug
```
- **효과**: 위젯 추가/삭제 시 chronod의 반응을 즉시 확인
- **발견 사항**: AppIcon 추가 전에는 아무런 로그도 없었고, 추가 후에는 `getTimelines(1) request` 로그가 나타남
- **핵심**: 문제의 전환점을 명확히 포착

### 2. pluginkit으로 등록 상태 확인 ⭐⭐
```bash
pluginkit -m -p com.apple.widgetkit-extension
```
- **효과**: 시스템이 위젯 extension을 인식하는지 확인
- **한계**: 등록되어 있어도 실제로 작동하지 않을 수 있음 (AppIcon 문제 등)

### 3. codesign으로 실제 entitlements 확인 ⭐⭐⭐
```bash
codesign -d --entitlements - <binary_path>
```
- **효과**: 빌드 설정과 실제 바이너리의 차이를 명확히 발견
- **발견 사항**: 엔타이틀먼트 파일은 존재하지만 빌드에 포함되지 않음
- **핵심**: "파일이 있다 ≠ 빌드에 포함된다"

### 4. 중간 빌드 파일 확인 ⭐⭐
```bash
cat .../DaylitWidgetExtension.build/.../DaylitWidgetExtension.appex-Simulated.xcent
```
- **효과**: Xcode가 entitlements를 어떻게 처리하는지 확인
- **발견 사항**: CODE_SIGN_ENTITLEMENTS 추가 후 이 파일에 App Groups가 나타남

### 5. App Group plist 직접 확인 ⭐⭐
```bash
plutil -p ~/Library/Developer/CoreSimulator/.../Library/Preferences/group.*.plist
```
- **효과**: 데이터가 실제로 저장되었는지 확인
- **발견 사항**: 데이터는 존재하는데 위젯이 못 읽는 것 → entitlements 문제로 범위 좁힘

### 6. 바이너리 심볼 확인 ⭐
```bash
strings debug.dylib | grep Widget
nm debug.dylib | grep getTimeline
```
- **효과**: 코드가 실제로 컴파일되었는지 확인
- **한계**: 컴파일되어도 리소스 문제로 실행 안 될 수 있음

### 7. 위젯 프로세스 로그 필터링 ⭐⭐
```bash
xcrun simctl spawn <UUID> log stream \
  --predicate 'processImagePath CONTAINS "DaylitWidget"' \
  --level debug
```
- **효과**: 위젯 extension 내부의 UserDefaults 접근 실패 로그 확인
- **발견 사항**: `found no value for key widget_memos` → entitlements 의심

---

## 효과 없었던 것들

### 0. 이전 세션들의 접근 방법 전체 ❌❌❌
- **기간**: 며칠
- **시도**: 시뮬레이터 의심, 계정 권한 의심, 반복적인 클린 빌드 등
- **결과**: 전혀 진전 없음
- **근본 문제**: 시스템 로그를 보지 않고, 실제 바이너리를 검증하지 않음
- **비용**: 며칠간의 시간 + 좌절감
- **교훈**: **"뭔가 안 된다" ≠ "왜 안 되는지 모른다". 항상 로그부터 확인**

### 1. Xcode 프로젝트 파일 분석만으로 문제 발견 시도 ❌
- **시도**: `project.pbxproj`에서 Sources build phase 확인
- **결과**: PBXFileSystemSynchronizedRootGroup 때문에 파일이 명시적으로 나열되지 않음
- **함정**: 파일이 리스트에 없어도 컴파일될 수 있음

### 2. Widget scheme 직접 실행 (미시도) ❌
- **사용자 요청**: "widget scheme 직접 실행"
- **실제 효과**: 시도하지 않음
- **이유**: chronod 로그만으로 충분히 진단 가능했음
- **교훈**: 실시간 로그가 더 직접적

### 3. Info.plist 재확인 ❌
- **시도**: NSExtensionPointIdentifier 여러 번 확인
- **결과**: 처음부터 올바르게 설정되어 있었음

### 4. Bundle ID 구조 재검증 ❌
- **시도**: 여러 번 Bundle ID hierarchy 확인
- **결과**: 처음부터 올바름

### 5. 바이너리에서 심볼 검색 (부분적으로만 유용) △
- **시도**: strings/nm으로 getTimeline 심볼 찾기
- **발견**: 코드는 컴파일됨
- **한계**: 리소스 문제는 발견 못함
- **결론**: 필요하긴 했지만 충분하지 않음

---

## 교훈

### 0. 체계적 디버깅의 중요성 🎯
**이전 세션들이 실패한 이유**:
- 증상만 보고 근본 원인을 찾지 않음
- 시스템 로그를 제대로 확인하지 않음
- 커뮤니티 통념("시뮬레이터 안 됨", "무료 계정 제한")을 맹신
- "왜 안 되는가"보다 "어떻게 우회하나"에 집중

**오늘 세션이 성공한 이유**:
- 실시간 시스템 로그 모니터링 (chronod, 위젯 프로세스)
- 실제 바이너리 검증 (codesign, 빌드 산출물)
- 증상이 아닌 원인을 찾는 체계적 접근
- 가설 수립 → 검증 → 수정의 반복

**결론**: **며칠 동안 못 푼 문제를 오늘 세션에서 해결한 이유는 접근 방법의 차이**

### 1. WidgetKit의 "조용한 실패" 특성 ⚠️
WidgetKit은 많은 경우 에러를 표시하지 않고 조용히 실패함:
- AppIcon 없음 → 아무 에러 없이 무시
- Entitlements 없음 → UserDefaults가 nil 반환 (크래시 없음)
- **대응**: 시스템 로그(chronod, 위젯 프로세스)를 필수적으로 모니터링해야 함

### 2. "파일이 있다 ≠ 빌드에 포함된다" 🔍
- Entitlements 파일이 프로젝트에 있어도 빌드 설정에 연결되지 않으면 무용지물
- **반드시** `codesign -d --entitlements`로 실제 바이너리 확인 필요

### 3. 리소스 파일 필수성 📦
- iOS 위젯은 최소한의 AppIcon이 **필수**
- Xcode가 경고하지 않아도 런타임에 필수일 수 있음
- **대응**: Assets.xcassets의 모든 요구사항 체크리스트 작성

### 4. 시뮬레이터 관련 잘못된 통념 주의 ⚡
- "시뮬레이터는 위젯 지원 안 함" → **틀림** (이전 세션에서 며칠 낭비)
- "무료 계정은 App Groups 안 됨" → **틀림** (이전 세션에서 며칠 낭비)
- **교훈**: 커뮤니티 통념을 맹신하지 말고 직접 확인
- **비용**: 이 두 가지 잘못된 믿음 때문에 며칠간 엉뚱한 곳에서 해결책을 찾음

### 5. 효과적인 디버깅 순서 📋
1. 시스템 로그 실시간 모니터링 시작
2. 사용자 액션 (위젯 추가/삭제)
3. 로그에서 비정상 패턴 찾기
4. 가설 수립
5. 바이너리/빌드 산출물로 가설 검증
6. 수정 후 다시 1번부터

---

## 타임라인 요약

| 시간 | 단계 | 핵심 활동 | 결과 |
|------|------|-----------|------|
| 14:00-14:30 | 기본 확인 | Bundle ID, Info.plist, pluginkit | 모두 정상, 원인 불명 |
| 14:30-14:50 | 로그 모니터링 | chronod, 위젯 프로세스 로그 | getTimeline() 호출 안 됨 확인 |
| 14:50-15:00 | 리소스 확인 | Assets.xcassets 점검 | ⭐ AppIcon 누락 발견 |
| 15:00-15:10 | 데이터 문제 | 위젯 표시되나 데이터 없음 | UserDefaults nil 확인 |
| 15:10-15:20 | Entitlements | codesign 확인 | ⭐ CODE_SIGN_ENTITLEMENTS 누락 발견 |
| 15:20-15:30 | 최종 수정 | Live Activity 에러 수정 | 모든 문제 해결 ✅ |

**전체 소요 기간**: 며칠 + 오늘 세션
**핵심 발견 2개**: AppIcon 누락, CODE_SIGN_ENTITLEMENTS 누락
**틀렸던 가설들**:
- 시뮬레이터 미지원 (이전 세션)
- 무료 계정 App Groups 불가 (이전 세션)
- 파일 빌드 미포함 (오늘 세션)

---

## 재발 방지 체크리스트

위젯 추가 시 반드시 확인할 것:

- [ ] `Assets.xcassets/AppIcon.appiconset/` 에 실제 이미지 파일 존재
- [ ] `Contents.json`에 `"filename"` 키 포함
- [ ] `project.pbxproj`의 위젯 타겟에 `CODE_SIGN_ENTITLEMENTS` 설정 존재
- [ ] `codesign -d --entitlements`로 실제 바이너리에 entitlements 포함 확인
- [ ] chronod 로그에서 `getTimelines()` 호출 확인
- [ ] 위젯 프로세스 로그에서 `found no value` 에러 없음 확인
- [ ] plutil로 App Group plist에 데이터 존재 확인

---

**작성일**: 2026-09-03
**작성자**: Claude (Sonnet 4.5)
**관련 파일**:
- `Daylit.xcodeproj/project.pbxproj` (라인 454, 486)
- `DaylitWidget/Assets.xcassets/AppIcon.appiconset/`
- `DaylitWidget/DaylitWidget.entitlements`
- `DaylitWidget/DaylitWidgetLiveActivity.swift` (라인 33, 95)
