# Contributing to Daylit

Daylit에 기여해주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

## 목차

- [행동 강령](#행동-강령)
- [시작하기](#시작하기)
- [개발 환경 설정](#개발-환경-설정)
- [기여 프로세스](#기여-프로세스)
- [코드 스타일](#코드-스타일)
- [커밋 규칙](#커밋-규칙)
- [Pull Request 가이드](#pull-request-가이드)
- [이슈 리포팅](#이슈-리포팅)

## 행동 강령

이 프로젝트는 모든 참여자가 존중받는 환경을 유지하기 위해 노력합니다. 기여하기 전에 다음을 준수해주세요:

- 건설적이고 존중하는 태도 유지
- 다양한 의견과 경험 존중
- 건설적인 비판 수용
- 커뮤니티 최선을 위한 행동

## 시작하기

### 필요한 도구

- **Xcode**: 15.0 이상
- **Swift**: 5.9 이상
- **iOS Deployment Target**: 17.0 이상
- **Git**: 최신 버전
- **GitHub CLI** (선택사항): PR 생성을 위해 권장

### 저장소 Fork 및 Clone

```bash
# 1. GitHub에서 저장소 Fork

# 2. 로컬에 Clone
git clone https://github.com/YOUR_USERNAME/Daylit.git
cd Daylit

# 3. Upstream 저장소 추가
git remote add upstream https://github.com/pinocchio22/Daylit.git
```

## 개발 환경 설정

### 1. 프로젝트 열기

```bash
open Daylit.xcodeproj
```

### 2. 의존성 확인

현재 프로젝트는 외부 의존성이 없으며, 표준 iOS SDK만 사용합니다.

### 3. 빌드 및 실행

1. Xcode에서 Scheme을 `Daylit` 또는 `DaylitWidgetExtension`으로 선택
2. 대상 시뮬레이터 또는 실제 기기 선택
3. `Cmd + R`로 빌드 및 실행

## 기여 프로세스

### 1. 이슈 확인 또는 생성

- 기존 이슈를 확인하여 중복 방지
- 새로운 기능이나 버그 수정은 이슈 생성 권장
- 이슈 템플릿 활용

### 2. 브랜치 생성

[Git Workflow](./docs/GIT_WORKFLOW.md)를 따라 적절한 브랜치 생성:

```bash
# Dev 브랜치에서 시작
git checkout dev
git pull upstream dev

# Feature 브랜치 생성
git checkout -b feature/your-feature-name

# 또는 Bugfix 브랜치
git checkout -b bugfix/bug-description
```

### 3. 코드 작성

- 기존 코드 스타일 준수
- 의미 있는 변수명 및 함수명 사용
- 필요한 경우 주석 추가
- 테스트 가능한 코드 작성

### 4. 커밋

[Conventional Commits](https://www.conventionalcommits.org/) 규칙 준수:

```bash
git add .
git commit -m "feat(widget): Add refresh button to widget"
```

### 5. Push 및 Pull Request 생성

```bash
# 원격 저장소에 푸시
git push origin feature/your-feature-name

# GitHub에서 Pull Request 생성
# 또는 GitHub CLI 사용
gh pr create --base dev --head feature/your-feature-name
```

### 6. 코드 리뷰

- 리뷰어의 피드백에 적극적으로 응답
- 요청된 변경사항 반영
- CI 체크 통과 확인

### 7. 병합

- 승인 후 Squash Merge 권장
- 브랜치 자동 삭제 확인

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

Closes #45
```

## Pull Request 가이드

### PR 제목

- 커밋 메시지 형식과 동일
- 명확하고 간결하게

### PR 설명 템플릿

```markdown
## Summary
변경사항을 간단히 설명합니다.

## Changes
- 변경사항 1
- 변경사항 2

## Screenshots (UI 변경 시)
[스크린샷 첨부]

## Test Plan
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2

## Related Issues
Closes #123
```

### PR 체크리스트

- [ ] 코드가 빌드되고 실행됨
- [ ] 코드 스타일 가이드 준수
- [ ] 커밋 메시지 규칙 준수
- [ ] 문서 업데이트 (필요한 경우)
- [ ] 관련 이슈 링크

## 이슈 리포팅

### 버그 리포트

버그를 발견하면 다음 정보를 포함하여 이슈를 생성해주세요:

```markdown
**버그 설명**
버그에 대한 명확한 설명

**재현 방법**
1. '...'로 이동
2. '...'를 클릭
3. 스크롤 다운
4. 에러 발생

**예상 동작**
예상했던 동작 설명

**실제 동작**
실제로 발생한 동작 설명

**스크린샷**
가능하면 스크린샷 첨부

**환경**
- Device: [예: iPhone 15 Pro]
- OS: [예: iOS 17.0]
- 앱 버전: [예: v1.0.0]
```

### 기능 제안

새로운 기능을 제안하려면:

```markdown
**기능 설명**
제안하는 기능에 대한 명확한 설명

**동기**
이 기능이 필요한 이유

**제안 사항**
기능이 어떻게 동작해야 하는지 설명

**대안**
고려한 다른 대안들
```

## 질문이나 도움이 필요한가요?

- GitHub Issues에서 질문 올리기
- 기존 이슈와 PR 확인하기

## 라이선스

프로젝트에 기여함으로써, 귀하의 기여가 프로젝트와 동일한 라이선스 하에 있음에 동의합니다.

---

다시 한번 기여해주셔서 감사합니다! 🎉
