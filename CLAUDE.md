# Claude 작업 규칙

이 프로젝트에서 Claude가 작업할 때 따라야 하는 규칙들입니다.

---

### R1 · 위젯/익스텐션 타겟을 추가할 때는 AppIcon과 entitlements 빌드 연결부터 확인한다

2026-09-03, 위젯 데이터 표시 문제로 상당한 시간을 소모했다. 원인은 두 가지였다: (1) AppIcon.appiconset에 실제 이미지 파일이 없어 WidgetKit이 익스텐션을 조용히 무시함, (2) 위젯 타겟의 빌드 설정에 CODE_SIGN_ENTITLEMENTS가 연결되지 않아 entitlements 파일이 존재해도 실제 바이너리에는 포함되지 않음. 둘 다 에러 메시지 없이 조용히 실패했다.

새 익스텐션(위젯, 앱클립 등) 타겟을 만들 때는:
1. Assets.xcassets에 실제 AppIcon 이미지 파일이 있는지 확인 (Contents.json에 filename 키 존재 여부까지)
2. codesign -d --entitlements - <바이너리경로>로 entitlements가 실제로 바이너리에 포함됐는지 직접 확인 (빌드 설정에 파일이 연결만 되어있다고 가정하지 않는다)

---
