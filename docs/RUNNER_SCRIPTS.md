# GoAccess Runner Scripts Guide

> GoAccess Docker 컨테이너를 실행하는 두 가지 방식: `run_simple.sh` vs `run_flowkat.sh`

**Last Updated**: 2026-01-21
**Version**: 1.0.0

---

## 📋 목차

1. [개요](#개요)
2. [run_simple.sh](#run_simplesh---간단한-커맨드-방식)
3. [run_flowkat.sh](#run_flowkatsh---인터랙티브-메뉴-방식)
4. [비교 및 선택 가이드](#비교-및-선택-가이드)
5. [로그 포맷](#로그-포맷)
6. [고급 사용](#고급-사용)

---

## 개요

### 🎯 두 스크립트의 목적

| 스크립트 | 방식 | 사용자 | 장점 |
|---------|------|--------|------|
| **run_simple.sh** | 커맨드 라인 | 자동화, 스크립팅 | 간단, 빠름, 자동화 용이 |
| **run_flowkat.sh** | 인터랙티브 메뉴 | 일반 사용자 | 사용 편의성, 선택 용이 |

### 📁 스크립트 위치

```
goaccess/
├── run_simple.sh       # ← 간단한 커맨드 방식
├── run_flowkat.sh      # ← 인터랙티브 메뉴 방식
└── docs/
    └── RUNNER_SCRIPTS.md (이 파일)
```

### ⚠️ 사전 요구사항

- ✅ Docker 설치 (최신 버전 권장)
- ✅ `goaccess-flowkat` Docker 이미지 빌드됨
- ✅ 로그 파일 준비 (.log 형식)

---

## run_simple.sh - 간단한 커맨드 방식

### 🎯 개요

**특징**: 커맨드 라인 인자 기반, 빠른 실행, 자동화 친화적

```bash
./run_simple.sh {tui|html|realtime|filter <keyword>}
```

### 📝 구성 요소

#### 변수 설정 (라인 9-15)

```bash
LOG_DIR="${LOG_DIR:-/data/flowkat-proxy/data/logs}"  # 로그 디렉토리
LOG_FILE="custom_vhost_access.log"                   # 로그 파일명
OUTPUT_DIR="${OUTPUT_DIR:-/data/flowkat-proxy}"      # 출력 디렉토리
IMAGE="goaccess-flowkat"                             # Docker 이미지명
LOG_PATH="/logs/$LOG_FILE"                           # 컨테이너 내부 경로
DATE_FORMAT="%d/%b/%Y"                               # 날짜 포맷
TIME_FORMAT="%H:%M:%S"                               # 시간 포맷
```

**수정 방법**:
```bash
# 환경 변수로 오버라이드
export LOG_DIR=/my/custom/logs
export OUTPUT_DIR=/my/custom/output
./run_simple.sh html
```

### 🚀 사용 방법

#### 1️⃣ TUI 모드 (대시보드)

```bash
./run_simple.sh tui
```

**기능**:
- 📊 인터랙티브 터미널 대시보드
- 🔄 실시간 업데이트 (자동 새로고침)
- ⌨️ 키보드 네비게이션 가능
- 📈 상단/하단 패널 전환 (`a`, `z` 키)

**예시 출력**:
```
 > Accessing the data...
   WebServer Statistics
 Date time Hits       Percent Bandwidth    Host method URL
 2026/01/20 12:34     500     15%    2.5 MB GET   http://example.com/api
 ...
```

#### 2️⃣ HTML 모드 (정적 리포트)

```bash
./run_simple.sh html
```

**기능**:
- 📄 HTML 파일로 리포트 생성
- 💾 로컬 저장 (`$OUTPUT_DIR/report.html`)
- 📱 반응형 디자인 (모바일/데스크톱)
- 🔗 공유 가능한 형식

**출력**:
```
✅ HTML report generated: /data/flowkat-proxy/report.html
```

**파일 구조**:
```
report.html (완전 독립형 HTML 파일)
├── CSS (임베드됨)
├── JavaScript (임베드됨)
└── 데이터 (JSON)
```

#### 3️⃣ Real-time 모드 (라이브 웹 대시보드)

```bash
./run_simple.sh realtime
```

**기능**:
- 🌐 웹 브라우저에서 접근 가능
- 🔄 실시간 업데이트 (WebSocket)
- 📡 포트 7890 사용
- 💡 로그 파일 변경 시 자동 반영

**접근**:
```
브라우저: http://localhost:7890
```

**특징**:
- HTML 리포트 생성 + 실시간 업데이트
- Ctrl+C로 종료

#### 4️⃣ Filter 모드 (키워드 필터링)

```bash
./run_simple.sh filter <keyword>
```

**기능**:
- 🔍 특정 키워드로 로그 필터링
- 📊 필터된 데이터 분석
- 📄 필터된 HTML 리포트 생성

**예시**:
```bash
# 특정 사용자 ID 필터
./run_simple.sh filter "20181601"

# 특정 IP 필터
./run_simple.sh filter "192.168.1.100"

# 특정 경로 필터
./run_simple.sh filter "/api/users"

# 출력
🔍 Filtered HTML report generated for keyword: 20181601
```

**필터링 로직** (라인 81-88):
```bash
grep "$KEYWORD" "$LOG_DIR/$LOG_FILE" |  # 로그에서 키워드 찾기
  docker run --rm -i \                  # stdin 파이프
    -v "$OUTPUT_DIR":/output \
    "$IMAGE" - \
    --log-format="VCOMBINED" \
    -o /output/report.html
```

---

## run_flowkat.sh - 인터랙티브 메뉴 방식

### 🎯 개요

**특징**: 단계별 메뉴 선택, 사용자 친화적, 다양한 옵션

```bash
./run_flowkat.sh          # 인터랙티브 모드
./run_flowkat.sh webmode  # 웹 모드 (기본값)
./run_flowkat.sh webmode 3000  # 웹 모드 (포트 3000)
```

### 📝 구성 요소

#### 색상 정의 (라인 6-11)

```bash
CYAN='\033[0;36m'    # 정보 메시지
GREEN='\033[0;32m'   # 성공 메시지
YELLOW='\033[1;33m'  # 경고/단계 표시
RED='\033[0;31m'     # 에러 메시지
NC='\033[0m'         # 색상 리셋
```

#### 배너 출력 (라인 14-20)

```bash
show_banner() {
    clear
    echo -e "${CYAN}"
    cat banner.txt 2>/dev/null || echo "FlowKat Monitoring Solution"
    echo -e "${NC}"
    echo -e "${GREEN}--- FlowKat Interactive Runner ---${NC}\n"
}
```

### 🚀 사용 방법

#### 기본 실행

```bash
./run_flowkat.sh
```

**진행 순서**:

1. **Step 1: 로그 파일 선택**
   ```
   [Step 1] Select Log File
   1) custom_vhost_access.log
   2) error.log

   Select a log file (or 0 to manual entry): 1
   ```

2. **Step 2: 로그 포맷 선택**
   ```
   [Step 2] Select Log Format
   1) Nginx/Apache VCombined (with Virtual Host) - Recommended
   2) Nginx/Apache Combined (Standard)
   3) Common Log Format (CLF)
   4) W3C (IIS)
   5) Amazon S3
   6) Google Cloud Storage

   Choose a format [1-6, default 1]: 1
   ```

3. **Step 3: 실행 모드 선택**
   ```
   [Step 3] Select Run Mode
   1) Terminal Dashboard (Interactive TUI)
   2) Static HTML Report (output to report.html)
   3) Real-time HTML Report (WebSocket on port 7890)
   4) FlowKat Native Analysis (Built-in user/cafe detection)
   5) Filter by ID/User (Keyword search)
   6) Custom Arguments

   Choose an option [1-6]: 3
   ```

### 🎯 6가지 실행 모드

#### 모드 1: Terminal Dashboard

```bash
# Step 3에서 1 선택
Choose an option [1-6]: 1
```

**실행 명령**:
```bash
docker run --rm -it \
  -v "$ABS_LOG_DIR":/logs \
  goaccess-flowkat "/logs/$LOG_FILE_NAME" \
  --log-format="$SELECTED_FORMAT" \
  --date-format='%d/%b/%Y' \
  --time-format='%H:%M:%S' \
  --no-progress --no-color
```

**특징**:
- 📊 인터랙티브 TUI
- ⌨️ 키보드 조작 가능
- 🔄 실시간 데이터 업데이트

#### 모드 2: Static HTML Report

```bash
# Step 3에서 2 선택
Choose an option [1-6]: 2
```

**실행 명령**:
```bash
docker run --rm \
  -v "$ABS_LOG_DIR":/logs \
  -v "$LOG_DIR":/output \
  goaccess-flowkat "/logs/$LOG_FILE_NAME" \
  --log-format="$SELECTED_FORMAT" \
  --date-format='%d/%b/%Y' \
  --time-format='%H:%M:%S' \
  -o /output/report.html
```

**출력**:
```
✔ Done! report.html has been created.
```

**생성 파일**: `./report.html`

#### 모드 3: Real-time HTML Report ⭐ 권장

```bash
# Step 3에서 3 선택
Choose an option [1-6]: 3
```

**동작 흐름**:

1. **웹 서버 시작 여부 확인**
   ```
   Start a web server to view the report? (y/n) [default y]: y
   ```

2. **포트 선택** (필요시)
   ```
   Enter web server port [default 8080]: 8080
   ```

3. **Nginx 웹 서버 실행** (백그라운드)
   ```
   Starting Nginx Web Server on port 8080...
   --------------------------------------------------
   ✔ Report URL: http://localhost:8080/report.html
   --------------------------------------------------
   ```

4. **GoAccess 실시간 서버 실행** (포그라운드)
   ```
   Starting GoAccess Real-time server (WS Port: 7890)...
   ```

**접근**:
```
1. 브라우저: http://localhost:8080/report.html
2. 실시간 데이터: WebSocket (포트 7890)
```

**포트 자동 조정**:
```
웹 포트 7890 사용 시 → WebSocket 포트 자동으로 7891로 변경
웹 포트 8080 사용 시 → WebSocket 포트 7890 유지
```

**정리**:
```bash
# Ctrl+C 눌러서 종료 시
Stopping web server...  # Nginx 자동 중지
docker stop flowkat-web # 정리
```

#### 모드 4: FlowKat Native Analysis

```bash
# Step 3에서 4 선택
Choose an option [1-6]: 4
```

**특징**:
- 🔍 GoAccess C 바이너리 기본 분석 기능
- 👤 사용자/카페 식별 분석
- 📊 주요 메트릭 추출

**출력**:
```
Running FlowKat Native Analysis...
Extracting Identities directly from C binary...
✔ Native Analysis Done! Check 'FlowKat Identities' panel in report.html.
```

**생성 파일**: `./report.html` (특수 데이터 포함)

#### 모드 5: Filter by ID/User

```bash
# Step 3에서 5 선택
Choose an option [1-6]: 5
Enter Keyword/ID to filter (e.g. 20181601): 20181601
```

**동작**:
```bash
grep "$KEYWORD" "$SELECTED_LOG" |  # 로그 필터링
  docker run --rm -i \             # stdin 파이프
    -v "$LOG_DIR":/output \
    goaccess-flowkat - \
    --log-format="$SELECTED_FORMAT" \
    -o /output/report.html
```

**출력**:
```
✔ Filtered Analysis Done! Check report.html.
```

**사용 예시**:
```bash
# 사용자 ID로 필터
Enter Keyword/ID to filter (e.g. 20181601): 20181601

# IP 주소로 필터
Enter Keyword/ID to filter (e.g. 20181601): 192.168.1.100

# 경로로 필터
Enter Keyword/ID to filter (e.g. 20181601): /api/users

# HTTP 상태로 필터
Enter Keyword/ID to filter (e.g. 20181601): 404
```

#### 모드 6: Custom Arguments

```bash
# Step 3에서 6 선택
Choose an option [1-6]: 6
Enter extra arguments: --help
```

**목적**: GoAccess 직접 옵션 지정

**예시**:
```bash
Enter extra arguments: --version
# GoAccess 버전 출력

Enter extra arguments: -o /output/custom.html -M
# HTML 출력 (모든 통계 포함)

Enter extra arguments: --help
# GoAccess 도움말 전체 출력
```

---

## 비교 및 선택 가이드

### 📊 기능 비교표

| 기능 | run_simple.sh | run_flowkat.sh |
|------|---------------|----------------|
| **사용 난이도** | ⭐ 낮음 | ⭐⭐ 중간 |
| **자동화 적합성** | ⭐⭐⭐ 매우 높음 | ⭐ 낮음 |
| **선택 옵션 수** | 4가지 | 6가지 |
| **웹 서버 자동 실행** | ✅ 아니오 | ✅ 예 (모드 3) |
| **포트 자동 조정** | ✅ 아니오 | ✅ 예 |
| **색상 출력** | ✅ 기본 | ✅ 향상됨 |
| **배너 표시** | ✅ 아니오 | ✅ 예 |
| **메뉴 가이드** | ✅ 아니오 | ✅ 예 |

### 🎯 선택 가이드

#### run_simple.sh 사용 시기

✅ **이런 경우 추천**:

1. **자동화 스크립트**
   ```bash
   # cron에서 자동 실행
   0 2 * * * /path/to/run_simple.sh html
   ```

2. **CI/CD 파이프라인**
   ```bash
   # Jenkins/GitHub Actions에서 사용
   ./run_simple.sh html && upload report.html
   ```

3. **빠른 실행**
   ```bash
   # 즉시 결과 필요
   ./run_simple.sh html
   ```

4. **필터링**
   ```bash
   # 특정 사용자만 분석
   ./run_simple.sh filter "user123"
   ```

#### run_flowkat.sh 사용 시기

✅ **이런 경우 추천**:

1. **첫 사용자**
   ```bash
   # 단계별 안내가 필요할 때
   ./run_flowkat.sh
   ```

2. **포트 선택 필요**
   ```bash
   # 기본값이 아닌 포트 사용
   ./run_flowkat.sh webmode 3000
   ```

3. **다양한 로그 포맷**
   ```bash
   # nginx, apache, IIS, S3 등 다양한 포맷
   # 메뉴에서 선택 가능
   ```

4. **실시간 모니터링**
   ```bash
   # 웹 서버 + 실시간 대시보드 자동 설정
   ./run_flowkat.sh
   # Step 3에서 3 선택
   ```

---

## 로그 포맷

### 📝 지원 포맷

#### 1️⃣ VCOMBINED (권장)

```
203.0.113.1 - - [21/Jan/2026:14:30:45 +0900] "GET /api HTTP/1.1" 200 1234 "-" "Mozilla/5.0" vhost1.example.com
```

**포함 정보**:
- IP 주소
- 시간
- HTTP 메서드 & 경로 & 프로토콜
- 상태 코드
- 바이트 수
- Referer
- User-Agent
- **Virtual Host (추가)**

**사용 환경**: Nginx/Apache (Virtual Host 지원)

#### 2️⃣ COMBINED

```
203.0.113.1 - - [21/Jan/2026:14:30:45 +0900] "GET /api HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
```

**포함 정보**:
- IP 주소
- 시간
- HTTP 메서드 & 경로 & 프로토콜
- 상태 코드
- 바이트 수
- Referer
- User-Agent

**사용 환경**: Nginx/Apache (기본 설정)

#### 3️⃣ COMMON

```
203.0.113.1 - - [21/Jan/2026:14:30:45 +0900] "GET /api HTTP/1.1" 200 1234
```

**포함 정보**:
- IP 주소
- 시간
- HTTP 메서드 & 경로 & 프로토콜
- 상태 코드
- 바이트 수

**사용 환경**: 기본 HTTP 서버

#### 4️⃣ W3C (IIS)

```
#Date: 2026-01-21 14:30:45
#Fields: date time s-ip cs-method cs-uri-stem sc-status
2026-01-21 14:30:45 203.0.113.1 GET /api 200
```

**포함 정보**:
- 날짜 & 시간
- 서버 IP
- HTTP 메서드
- URI
- 상태 코드

**사용 환경**: Windows IIS

#### 5️⃣ S3 (Amazon S3)

```
a4c206c373c5e2ad03da5fd5b1e1ae14cf61e1e72ffa3ae20f5c9fceff98f28 bucket [21/Jan/2026:14:30:45 +0000] 203.0.113.1 - - S3.GET.OBJECT key "GET /api HTTP/1.1" 200 1234 - "-" "-"
```

**포함 정보**: S3 액세스 로그 포맷

**사용 환경**: Amazon S3

#### 6️⃣ GCS (Google Cloud Storage)

```
203.0.113.1 - [21/Jan/2026:14:30:45 +0000] "GET /api HTTP/1.1" 200 1234 "-" "-"
```

**포함 정보**: GCS 액세스 로그 포맷

**사용 환경**: Google Cloud Storage

---

## 고급 사용

### 🔧 환경 변수 설정 (run_simple.sh)

```bash
# 로그 디렉토리 변경
export LOG_DIR=/var/log/nginx

# 출력 디렉토리 변경
export OUTPUT_DIR=/tmp/reports

# 실행
./run_simple.sh html
```

### 📌 cron 자동화 예제

#### 매일 자정에 HTML 리포트 생성

```bash
# crontab -e로 편집
0 0 * * * cd /path/to/goaccess && ./run_simple.sh html
```

#### 매 시간 필터된 리포트 생성

```bash
# crontab -e로 편집
0 * * * * cd /path/to/goaccess && ./run_simple.sh filter "api"
```

#### 특정 사용자별 리포트 (반복)

```bash
#!/bin/bash
for USER_ID in 20181601 20181602 20181603; do
  ./run_simple.sh filter "$USER_ID"
  mv report.html "report_${USER_ID}.html"
done
```

### 🔄 Docker 이미지 다시 빌드

```bash
# 이미지가 없거나 업데이트 필요한 경우
docker build -t goaccess-flowkat .

# 확인
docker images | grep goaccess-flowkat
```

### 🐳 Docker 문제 해결

#### 이미지를 찾을 수 없음

```bash
# 에러: Error: Docker image 'goaccess-flowkat' not found.

# 해결: Dockerfile이 있는 디렉토리에서
docker build -t goaccess-flowkat .

# 또는
docker pull flowkat/goaccess:latest
docker tag flowkat/goaccess:latest goaccess-flowkat
```

#### 포트 충돌

```bash
# 에러: port 7890 is already in use

# run_flowkat.sh 사용 시: 메뉴에서 다른 포트 선택
# run_simple.sh 사용 시: 환경변수로 포트 변경 (GoAccess 옵션 참고)
```

#### 로그 파일 권한

```bash
# 에러: permission denied reading log file

# 해결: 스크립트 실행 권한 확인
chmod +x run_simple.sh run_flowkat.sh

# 로그 파일 읽기 권한 확인
chmod +r /path/to/logfile
```

---

## 📚 참고

### 관련 파일

- **Jenkinsfile**: `./Jenkinsfile` - CI/CD 파이프라인
- **Dockerfile**: `./Dockerfile` - Docker 이미지 빌드
- **README**: `./docs/README.md` - 전체 가이드

### 외부 참고

- **GoAccess 공식**: https://goaccess.io
- **GoAccess 매뉴얼**: https://goaccess.io/man
- **Docker 레퍼런스**: https://docs.docker.com/

### 연락처

- **이메일**: kranian@example.com
- **이슈**: GitHub Issues
- **질문**: Slack/Mattermost

---

## ✅ 빠른 시작 체크리스트

### 설치 후 첫 실행

- [ ] Docker 설치 확인: `docker --version`
- [ ] 이미지 빌드: `docker build -t goaccess-flowkat .`
- [ ] 실행 권한: `chmod +x run_simple.sh run_flowkat.sh`
- [ ] 로그 파일 준비: `ls *.log` 또는 경로 확인
- [ ] 첫 실행: `./run_flowkat.sh` (메뉴 방식)

### 자동화 설정

- [ ] cron 등록: `crontab -e`
- [ ] 로그 로테이션 확인
- [ ] 디스크 공간 모니터링
- [ ] 리포트 백업 설정

---

**Last Updated**: 2026-01-21
**Maintained By**: kranian
**Status**: ✅ Production Ready
