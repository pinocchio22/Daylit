# Git Workflow

Daylit 프로젝트의 Git 워크플로우입니다. 개인 개발 프로젝트로 단순한 브랜치 전략을 사용합니다.

## 브랜치 구조

### `main`
- 프로덕션 코드를 포함하는 메인 브랜치
- 모든 개발 작업은 main 브랜치에서 직접 수행
- 버전 릴리스는 Git 태그로 관리

## 워크플로우

### 일반적인 개발 프로세스

1. **개발 작업**: main 브랜치에서 직접 작업
2. **커밋**: 의미 있는 단위로 커밋 (Conventional Commits 규칙 준수)
3. **푸시**: 작업 완료 후 원격 저장소에 푸시

```bash
# 작업 후 커밋
git add .
git commit -m "feat: Add new feature"
git push origin main
```

### 릴리스 프로세스

버전 릴리스는 Git 태그를 사용하여 관리합니다:

```bash
# 태그 생성 (annotated tag 사용)
git tag -a v1.0.0 -m "Release v1.0.0"

# 태그를 원격 저장소에 푸시
git push origin v1.0.0

# 모든 태그 확인
git tag -l
```

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
```

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
# 현재 상태 확인
git status

# 변경 사항 확인
git diff

# 커밋 히스토리 확인
git log --oneline

# 특정 커밋으로 이동
git checkout <commit-hash>

# 변경 사항 되돌리기 (커밋 전)
git restore <file>

# 마지막 커밋 수정 (아직 push하지 않은 경우)
git commit --amend

# 태그 목록 확인
git tag -l

# 특정 태그로 이동
git checkout v1.0.0

# 원격 저장소 최신화
git pull origin main
```

## 참고 자료

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
