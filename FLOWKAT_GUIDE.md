# FlowKat GoAccess 가이드 북

FlowKat은 실시간 웹 로그 분석기인 GoAccess를 기반으로, FlowKat만의 브랜딩과 강력한 사용자/카페 분석 기능을 내장한 커스텀 솔루션입니다.

---

## 1. 개요
FlowKat은 기존 GoAccess에 다음과 같은 기능을 추가했습니다.
- **커스텀 브랜딩**: 터미널 실행 시 전용 배너 출력 및 HTML 리포트 내 로고 임베딩.
- **Native Identity Analysis**: 로그의 URI 패턴(`~user`, `/cafe/ID`)을 시스템 수준에서 분석하여 전용 패널에 집계.
- **Docker 기반 워크플로우**: 복잡한 사양 설정 없이 컨테이너 환경에서 즉시 실행 가능.

---

## 2. 빌드 방법 (Docker)
모든 소스 코드와 브랜딩 자산(배너, 로고)을 포함하여 Docker 이미지를 생성합니다.

```bash
# 브랜딩 자산 준비 및 이미지 빌드
./build_docker.sh
```
*이 과정에서 `banner.txt`와 `180x180.png`가 바이너리 내부로 컴파일되어 포함됩니다.*

---

## 3. 실행 방법 (Runner Script)
대화형 스크립트를 통해 로그 파일과 분석 모드를 간편하게 선택할 수 있습니다.

```bash
# 대화형 러너 실행
./run_flowkat.sh
```

### 실행 옵션 안내:
1. **Interactive TUI**: 터미널 전용 대시보드를 실행합니다 (실시간 분석).
2. **Static HTML**: `report.html` 정적 파일을 생성합니다 (모든 분석 패널 포함).
3. **Real-time HTML**: WebSocket 서버를 활성화하여 브라우저에서 실시간으로 갱신되는 화면을 제공합니다.
4. **FlowKat Native Analysis**: 고속 C 파싱 엔진을 통해 사용자/카페 ID를 별도 패널로 합산하여 리포트를 생성합니다.
5. **Filter by ID/User**: 특정 카페 ID나 유저명이 포함된 로그만 필터링하여 분석합니다.

---

## 4. 특화 기능: FlowKat Identities
FlowKat은 로그의 URI(요청 주소)에서 자동으로 다음 패턴을 찾아 분석합니다.

- **유저 패턴**: `domain.com/~username/path` -> `~username` 단위 집계
- **카페 패턴**: `domain.com/cafe/20181601/view` -> `cafe/20181601` 단위 집계

분석 결과는 HTML 리포트의 **"FlowKat Identities (Users/Cafes)"** 패널에서 히트수, 방문자수, 데이터 전송량과 함께 확인할 수 있습니다.

---

## 5. 자산 커스터마이징
브랜딩 자산을 변경하고 싶다면 다음 파일을 수정한 후 다시 빌드하십시오.

- **터미널 배너**: `/home/kranian/project/goaccess/banner.txt` (ASCII Art)
- **리포트 로고**: `/home/kranian/project/goaccess/180x180.png` (PNG 이미지)

---

## 6. 문제 해결 (FAQ)
- **로그 파일이 안 보여요**: `.log` 확장자를 가진 파일이 현재 폴더에 있어야 자동으로 인식됩니다. 다른 경로에 있다면 수동 경로 입력을 이용하세요.
- **Docker 권한 오류**: `docker` 명령어를 실행할 수 있는 권한이 필요합니다. (`sudo` 권한 확인)
- **포트 충돌**: Real-time 모드 사용 시 `7890` 포트가 열려있어야 합니다.

---
**FlowKat과 함께 더 깊이 있는 로그 데이터 분석을 시작하세요!**
