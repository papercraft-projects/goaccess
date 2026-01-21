# vhost:port 파싱 사용 가이드

## 개요

이 가이드는 GoAccess를 사용하여 가상 호스트(vhost) 기반의 웹 서버 로그에서 호스트명과 포트를 정확히 파싱하는 방법을 설명합니다.

### 대상 사용자

- 여러 가상 호스트를 운영하는 웹 관리자
- Nginx, Apache 등에서 vhost:port 포맷의 로그를 분석하는 개발자
- 가상 호스트별 트래픽 분석이 필요한 사람

---

## 빠른 시작

### 1단계: 로그 포맷 확인

로그 파일의 첫 줄을 확인하여 현재 포맷을 파악합니다:

```bash
head -1 /path/to/access.log
```

**VCOMBINED 포맷 예제:**
```
biz.hanbat.ac.kr:443 220.123.66.49 - - [21/Jan/2026:14:30:45 +0900] "GET / HTTP/1.1" 301 166 "-" "FlowKat/5.0.27"
```

**특징:**
- vhost와 포트가 함께 표시됨: `biz.hanbat.ac.kr:443`
- IP 주소가 별도로 표시됨: `220.123.66.49`

---

### 2단계: GoAccess 실행 (가장 간단한 방법)

```bash
# run_flowkat.sh 사용 (권장)
./run_flowkat.sh

# 메뉴에서 선택:
# 1) Nginx/Apache VCombined (with Virtual Host) - Recommended
# [Enter 선택]
```

---

### 3단계: 분석 결과 확인

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Virtual Hosts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
biz.hanbat.ac.kr       100 requests
lec.hanbat.ac.kr        50 requests
iace.hanbat.ac.kr       30 requests
inno.hanbat.ac.kr       20 requests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 상세 사용 방법

### 방법 1: run_flowkat.sh (권장 - 대화형)

가장 사용자 친화적인 방법입니다.

```bash
./run_flowkat.sh
```

**메뉴 선택:**
```
Select log format:
1) Nginx/Apache VCombined (with Virtual Host) - Recommended
2) Nginx/Apache Combined (Standard)
3) Apache Extended
4) IIS
5) CloudFront
6) Other

Enter choice [1-6]: 1
```

**결과:**
- 자동으로 VCOMBINED 포맷으로 분석
- 가상 호스트별 통계 생성
- TUI 또는 HTML 옵션 선택

---

### 방법 2: run_simple.sh (개발자용)

특정 모드로 직접 실행합니다.

#### TUI 모드 (실시간 모니터링)

```bash
./run_simple.sh tui
```

#### HTML 리포트 생성

```bash
./run_simple.sh html
# → report.html 생성
# → 웹 브라우저에서 열기
```

#### 실시간 모니터링

```bash
./run_simple.sh realtime
```

#### 필터링 모드

```bash
./run_simple.sh filter
```

---

### 방법 3: Docker 직접 실행 (고급)

최대 제어가 필요한 경우:

```bash
docker run --rm \
  -v /path/to/logs:/logs \
  goaccess-flowkat:latest \
  /logs/access.log \
  --log-format=VCOMBINED \
  --date-format="%d/%b/%Y" \
  --time-format="%H:%M:%S" \
  -a
```

---

## 실제 사용 시나리오

### 시나리오 1: 특정 vhost의 트래픽 분석

**목표:** biz.hanbat.ac.kr의 모든 요청 분석

```bash
# 필터링하여 실행
grep "^biz.hanbat.ac.kr" access.log > biz_only.log
./run_simple.sh tui < biz_only.log
```

**또는 GoAccess 필터 기능 사용:**

```bash
docker run --rm \
  -v /path/to/logs:/logs \
  goaccess-flowkat:latest \
  /logs/access.log \
  --log-format=VCOMBINED \
  --date-format="%d/%b/%Y" \
  --time-format="%H:%M:%S" \
  --ignore-pattern="^(?!biz\.hanbat)" \
  -a
```

---

### 시나리오 2: 오류 요청만 분석 (4xx, 5xx)

```bash
# 상태 코드 400-599만 필터
awk '$9 ~ /^[45][0-9]{2}$/' access.log > errors.log
./run_simple.sh tui < errors.log
```

---

### 시나리오 3: 특정 시간대 분석

```bash
# 14:00-15:00 의 요청만
grep "14:3[0-9]|15:0[0-9]" access.log > hourly.log
./run_simple.sh html < hourly.log
```

---

### 시나리오 4: vhost별 비교 분석

```bash
# 각 vhost 별도 분석
for host in biz lec iace inno; do
  echo "=== $host.hanbat.ac.kr ==="
  grep "^$host" access.log | ./run_simple.sh tui
done
```

---

## 분석 결과 해석

### 주요 지표

#### 1. Virtual Hosts (가상 호스트별 요청 수)

```
Virtual Hosts
├─ biz.hanbat.ac.kr      1,250 (50%)
├─ lec.hanbat.ac.kr        750 (30%)
├─ iace.hanbat.ac.kr       350 (14%)
└─ inno.hanbat.ac.kr       150 (6%)
```

**해석:**
- biz가 전체 트래픽의 50% 차지
- 시스템 자원 할당 시 우선 고려

---

#### 2. Status Codes (HTTP 상태 코드)

```
Status Codes
├─ 200 OK                 1,800 (72%)
├─ 301 Redirect             400 (16%)
├─ 404 Not Found            150 (6%)
├─ 500 Server Error          50 (2%)
└─ 503 Service Unavailable   50 (2%)
```

**해석:**
- 72%의 정상 요청 (2xx)
- 16%의 리다이렉션 (3xx)
- 8%의 오류 요청 (4xx, 5xx)

---

#### 3. Top Paths (인기 경로)

```
Top Paths
├─ /                    1,000 (40%)
├─ /api/users             300 (12%)
├─ /course               200 (8%)
├─ /admin                150 (6%)
└─ /images              100 (4%)
```

**해석:**
- 홈페이지가 가장 많은 트래픽
- API 엔드포인트 사용 빈번
- 관리자 페이지 접근량 낮음

---

#### 4. Top Referrers (유입 경로)

```
Top Referrers
├─ Direct Visit       1,200 (48%)
├─ Google Search        600 (24%)
├─ Internal Link        400 (16%)
└─ Social Media         100 (4%)
```

**해석:**
- 직접 방문이 가장 많음
- 검색 엔진 유입 24%
- SNS 트래픽 4%

---

#### 5. Top User-Agents (클라이언트 유형)

```
Top User-Agents
├─ Chrome              1,200 (48%)
├─ Firefox              500 (20%)
├─ Safari               300 (12%)
├─ Bot                  200 (8%)
└─ Mobile               100 (4%)
```

**해석:**
- Chrome 사용자가 절반
- 모바일 트래픽은 4%
- 봇 트래픽 모니터링 필요

---

## 문제 해결

### 문제 1: "Invalid log format" 오류

**증상:**
```
ERROR: Invalid log format specified
```

**원인:**
- 로그 포맷이 VCOMBINED가 아님
- 포맷 옵션 오류

**해결:**

```bash
# 1단계: 로그 포맷 확인
head -1 access.log

# 2단계: 포맷 선택
# VCOMBINED: vhost:port 포맷
# COMBINED:  일반 포맷
# 기타

# 3단계: 올바른 옵션으로 실행
./run_simple.sh tui  # 자동 선택
# 또는
./run_flowkat.sh     # 메뉴에서 선택
```

---

### 문제 2: vhost가 IP로 표시됨

**증상:**
```
Virtual Hosts
├─ 220.123.66.49
├─ 203.0.113.45
└─ ...
```

**원인:**
- COMBINED 포맷 사용 (VCOMBINED 아님)
- 포맷이 잘못 지정됨

**해결:**

```bash
# run_flowkat.sh 에서 올바른 옵션 선택
./run_flowkat.sh
# → 1) Nginx/Apache VCombined (with Virtual Host) 선택
```

---

### 문제 3: 날짜/시간이 파싱되지 않음

**증상:**
```
ERROR: Date/time parsing error
```

**원인:**
- date-format 또는 time-format 불일치

**해결:**

```bash
# 로그 파일 날짜 형식 확인
head -1 access.log | grep -oP '\[\K[^\]]+'
# → 출력: 21/Jan/2026:14:30:45 +0900

# 맞는 포맷 지정
./run_simple.sh tui \
  --date-format="%d/%b/%Y" \
  --time-format="%H:%M:%S"
```

---

### 문제 4: 큰 파일 처리 (2,600줄 이상)

**증상:**
```
Segmentation fault (core dumped)
```

**원인:**
- GoAccess 1.9.4 메모리 버그 (2,800줄+)

**해결:**

**옵션 1: 파일 분할**
```bash
# 파일을 2,000줄 단위로 분할
split -l 2000 access.log chunk_
# → chunk_aa, chunk_ab, chunk_ac ...

# 각각 처리
for f in chunk_*; do
  ./run_simple.sh html < "$f" > "${f}.html"
done
```

**옵션 2: 최신 GoAccess 사용**
```bash
# GoAccess 1.9.5+ 으로 업그레이드
# (메모리 버그 수정됨)
```

**옵션 3: 필터링**
```bash
# 필요한 기간만 추출
grep "21/Jan/2026" access.log | \
  ./run_simple.sh tui
```

---

## 성능 팁

### 팁 1: 정기적 분석 자동화

```bash
# crontab 설정 (매일 자정)
0 0 * * * /home/user/scripts/analyze_logs.sh

# 스크립트 내용:
#!/bin/bash
YESTERDAY=$(date -d "yesterday" +"%d/%b/%Y")
LOG_DIR="/var/log/nginx"

grep "$YESTERDAY" "$LOG_DIR/access.log" | \
  docker run -i goaccess-flowkat \
    --log-format=VCOMBINED \
    --date-format="%d/%b/%Y" \
    --time-format="%H:%M:%S" \
    -o html > "/tmp/report_${YESTERDAY}.html"
```

---

### 팁 2: 고속 필터링 (grep 활용)

```bash
# 특정 vhost 추출 (10배 빠름)
grep "^biz\." access.log | \
  ./run_simple.sh tui

# 특정 경로 추출
grep " /api/" access.log | \
  ./run_simple.sh tui

# 오류만 추출
grep " [45][0-9][0-9] " access.log | \
  ./run_simple.sh tui
```

---

### 팁 3: 병렬 처리

```bash
# 여러 vhost 동시 분석 (멀티코어 활용)
for host in biz lec iace inno; do
  (
    grep "^$host" access.log | \
      ./run_simple.sh html > "/tmp/${host}.html"
  ) &
done
wait
```

---

## 모범 사례

### ✅ 해야 할 일

1. **정기적 분석**
   - 매일 또는 매주 정기 분석
   - 추세 변화 감지

2. **다중 vhost 비교**
   - vhost별 성능 모니터링
   - 리소스 할당 최적화

3. **오류 추적**
   - 4xx, 5xx 오류 모니터링
   - 즉시 대응

4. **용량 계획**
   - 트래픽 증감 추적
   - 인프라 확장 계획

---

### ❌ 하지 말아야 할 일

1. **잘못된 포맷 사용**
   - COMBINED 대신 VCOMBINED 필수

2. **너무 큰 파일 처리**
   - 2,600줄 이상은 분할 처리

3. **오래된 로그 축적**
   - 정기적 삭제/보관

4. **자동화 없는 수작업**
   - 반복 작업 자동화 필수

---

## 참고 자료

- **API 옵션 참조**: `.moai/docs/api/options-reference.md`
- **포맷 상세 가이드**: `.moai/docs/api/vcombined-format.md`
- **Phase 2 테스트 결과**: `.moai/specs/SPEC-VHOST-001/phase2_results.md`

---

**마지막 업데이트:** 2026-01-21
**상태:** ✅ 완성
**언어:** 한국어 (Korean)
