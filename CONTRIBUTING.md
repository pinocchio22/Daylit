# Daylit 개발 가이드

이 문서는 Daylit 프로젝트의 개발 환경 설정과 코딩 규칙을 안내합니다.

## 목차

- [개발 환경 설정](#개발-환경-설정)
- [코드 스타일](#코드-스타일)
- [커밋 규칙](#커밋-규칙)

## 개발 환경 설정

### 필요한 도구

- **Xcode**: 15.0 이상
- **Swift**: 5.9 이상
- **iOS Deployment Target**: 17.0 이상
- **Git**: 최신 버전

### 프로젝트 열기

```bash
open Daylit.xcodeproj
```

### 의존성 확인

현재 프로젝트는 외부 의존성이 없으며, 표준 iOS SDK만 사용합니다.

### 빌드 및 실행

1. Xcode에서 Scheme을 `Daylit` 또는 `DaylitWidgetExtension`으로 선택
2. 대상 시뮬레이터 또는 실제 기기 선택
3. `Cmd + R`로 빌드 및 실행

## 코드 스타일

### Swift 스타일 가이드

[Swift Style Guide](https://google.github.io/swift/)를 기본으로 따르며, 다음을 추가로 준수합니다:

#### 네이밍

```swift
// 좋은 예
class MemoDetailView: View { }
func fetchMemos() -> [Memo] { }
let isLoading: Bool

// 나쁜 예
class memoView: View { }
func get_memos() -> [Memo] { }
let loading: Bool
```

#### 들여쓰기

- 4 스페이스 사용
- 탭 대신 스페이스 사용

#### 줄 길이

- 최대 120자 권장

#### 주석

```swift
// MARK: - Section Name

/// 메모를 저장합니다.
/// - Parameter memo: 저장할 메모 객체
/// - Returns: 저장 성공 여부
func saveMemo(_ memo: Memo) -> Bool {
    // 구현...
}
```

### SwiftUI 스타일

```swift
// 좋은 예: 간결하고 읽기 쉬운 구조
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Header()
            MemoList()
            Footer()
        }
        .padding()
    }
}

// 컴포넌트 분리
struct Header: View {
    var body: some View {
        Text("Daylit")
            .font(.largeTitle)
    }
}
```

## 커밋 규칙

### Conventional Commits 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅 (기능 변경 없음)
- `refactor`: 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드, 설정 등

### Scope (선택사항)

- `widget`: 위젯 관련
- `ui`: UI 변경
- `data`: 데이터 모델
- `sync`: iCloud 동기화

### 예시

```bash
feat(widget): Add weekly summary widget

이번 주 작성한 메모의 통계를 보여주는 위젯 추가
- 일별 메모 개수 표시
- 카테고리별 색상 표시
- 탭하여 앱 열기 기능
```

---

더 자세한 Git 워크플로우는 [docs/GIT_WORKFLOW.md](./docs/GIT_WORKFLOW.md)를 참고하세요.
