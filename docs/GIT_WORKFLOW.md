# Git Workflow

Daylit 프로젝트는 Git Flow를 기반으로 한 브랜치 전략을 사용합니다.

## 브랜치 구조

### 메인 브랜치

#### `main`
- 프로덕션 준비가 완료된 안정적인 코드만 포함
- 직접 커밋 금지 (PR을 통해서만 병합)
- 모든 커밋은 배포 가능한 상태
- 태그를 통해 버전 관리 (v1.0.0, v1.1.0 등)

#### `dev`
- 다음 릴리스를 위한 개발 브랜치
- 기능 브랜치들이 병합되는 통합 브랜치
- 개발 중인 최신 코드 포함
- 직접 커밋 금지 (PR을 통해서만 병합)

### 지원 브랜치

#### Feature 브랜치 (`feature/*`)
- **목적**: 새로운 기능 개발
- **시작점**: `dev`
- **병합 대상**: `dev`
- **네이밍**: `feature/{기능명}` (예: `feature/user-profile`, `feature/dark-mode`)
- **생명주기**: 기능 개발 완료 후 삭제

```bash
# Feature 브랜치 생성
git checkout dev
git pull origin dev
git checkout -b feature/new-feature

# 작업 후 dev로 PR 생성
git push -u origin feature/new-feature
gh pr create --base dev --head feature/new-feature
```

#### Bugfix 브랜치 (`bugfix/*`)
- **목적**: dev 브랜치의 버그 수정
- **시작점**: `dev`
- **병합 대상**: `dev`
- **네이밍**: `bugfix/{버그명}` (예: `bugfix/login-error`)

#### Release 브랜치 (`release/*`)
- **목적**: 릴리스 준비 (버전 번호 업데이트, 문서 정리 등)
- **시작점**: `dev`
- **병합 대상**: `main` 그리고 `dev`
- **네이밍**: `release/v{버전}` (예: `release/v1.0.0`)

```bash
# Release 브랜치 생성
git checkout dev
git checkout -b release/v1.1.0

# 버전 번호 업데이트 및 릴리스 준비 작업
# ...

# main으로 PR 생성
git push -u origin release/v1.1.0
gh pr create --base main --head release/v1.1.0

# 병합 후 태그 생성
git checkout main
git pull origin main
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0

# dev로도 병합 (변경사항 반영)
git checkout dev
git merge release/v1.1.0
git push origin dev
```

#### Hotfix 브랜치 (`hotfix/*`)
- **목적**: 프로덕션 긴급 버그 수정
- **시작점**: `main`
- **병합 대상**: `main` 그리고 `dev`
- **네이밍**: `hotfix/v{버전}` (예: `hotfix/v1.0.1`)

```bash
# Hotfix 브랜치 생성
git checkout main
git checkout -b hotfix/v1.0.1

# 버그 수정 작업
# ...

# main으로 PR 생성
git push -u origin hotfix/v1.0.1
gh pr create --base main --head hotfix/v1.0.1

# 병합 후 태그 및 dev 반영
git checkout main
git pull origin main
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push origin v1.0.1

git checkout dev
git merge hotfix/v1.0.1
git push origin dev
```

## 워크플로우

### 일반적인 기능 개발 프로세스

1. **이슈 생성**: GitHub Issues에서 작업 내용 정의
2. **브랜치 생성**: `dev`에서 `feature/*` 브랜치 생성
3. **개발 작업**: 기능 구현 및 테스트
4. **커밋**: 의미 있는 단위로 커밋 (Conventional Commits 규칙 준수)
5. **PR 생성**: `dev`를 대상으로 Pull Request 생성
6. **코드 리뷰**: 팀원의 리뷰 및 피드백 반영
7. **병합**: 승인 후 `dev`에 병합
8. **브랜치 삭제**: Feature 브랜치 삭제

### 릴리스 프로세스

1. **Release 브랜치 생성**: `dev`에서 `release/v*` 생성
2. **릴리스 준비**:
   - 버전 번호 업데이트
   - CHANGELOG.md 작성
   - 문서 업데이트
   - 최종 테스트
3. **PR 생성**: `main`을 대상으로 PR 생성
4. **병합 및 태그**: `main`에 병합 후 버전 태그 생성
5. **Dev 반영**: Release 브랜치를 `dev`에도 병합

## 커밋 메시지 규칙

[Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
- `refactor`: 코드 리팩토링 (기능 변경 없음)
- `test`: 테스트 추가 또는 수정
- `chore`: 빌드 작업, 패키지 매니저 설정 등

### 예시
```
feat(widget): Add weekly memo widget

이번 주에 작성한 메모를 표시하는 홈 화면 위젯 추가

Closes #123
```

## PR 규칙

### PR 제목
- 커밋 메시지와 동일한 형식 사용
- 명확하고 간결하게 작성

### PR 설명
- **Summary**: 변경 사항 요약
- **Changes**: 주요 변경 내용 나열
- **Test Plan**: 테스트 방법 설명
- **Screenshots**: UI 변경 시 스크린샷 첨부
- **Related Issues**: 관련 이슈 번호 (#123)

### 리뷰 요구사항
- 최소 1명의 승인 필요
- 모든 CI 체크 통과
- 충돌 해결 완료

## 브랜치 보호 규칙

### `main` 브랜치
- 직접 푸시 금지
- PR을 통한 병합만 허용
- 최소 1명의 리뷰 승인 필요
- CI/CD 체크 통과 필수
- Linear history 유지 (Squash merge 권장)

### `dev` 브랜치
- 직접 푸시 금지
- PR을 통한 병합만 허용
- CI 체크 통과 필수

## 버전 관리

[Semantic Versioning](https://semver.org/) 사용:

```
MAJOR.MINOR.PATCH

- MAJOR: 호환되지 않는 API 변경
- MINOR: 하위 호환성을 유지하는 기능 추가
- PATCH: 하위 호환성을 유지하는 버그 수정
```

### 예시
- `v1.0.0`: 첫 안정 버전
- `v1.1.0`: 새로운 기능 추가
- `v1.1.1`: 버그 수정
- `v2.0.0`: Breaking changes

## 유용한 Git 명령어

```bash
# 현재 브랜치 확인
git branch

# 원격 브랜치 목록 확인
git branch -r

# 로컬 브랜치 삭제
git branch -d feature/branch-name

# 원격 브랜치 삭제
git push origin --delete feature/branch-name

# Dev 브랜치 최신화
git checkout dev
git pull origin dev

# Feature 브랜치 rebase
git checkout feature/my-feature
git rebase dev

# Commit 수정 (아직 push하지 않은 경우)
git commit --amend

# 여러 커밋을 하나로 합치기
git rebase -i HEAD~3
```

## 참고 자료

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
