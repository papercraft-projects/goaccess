# VCOMBINED 로그 포맷 상세 가이드

## 개요

**VCOMBINED (Virtual Host Combined)** 포맷은 가상 호스트 기반 웹 서버의 액세스 로그에서 가상 호스트명과 포트를 정확히 파싱하기 위해 설계된 포맷입니다.

### 왜 VCOMBINED인가?

표준 **Combined** 포맷에서는 클라이언트 IP 필드가 "hostname:port" 형식으로 기록되어, GoAccess의 IP 검증 규칙과 충돌합니다. VCOMBINED는 이를 명시적으로 분리합니다.

---

## 포맷 분석

### 포맷 문자열

```
%v:%^ %h %^[%d:%t %^] "%r" %s %b "%R" "%u"
```

### 필드별 상세 분석

#### 1. Virtual Host와 Port (vhost:port)

```
%v:%^
```

**설명:**
- `%v` = Virtual Host 이름
- `:` = 리터럴 콜론 (구분자)
- `%^` = 다음 필드 스킵 (포트 번호)

**예제:**
```
biz.hanbat.ac.kr:443
lec.hanbat.ac.kr:443
iace.hanbat.ac.kr:80
inno.hanbat.ac.kr:443
```

**파싱 결과 (GoAccess):**
```
Virtual Host: biz.hanbat.ac.kr
Port (skipped): 443
```

---

#### 2. Remote IP Address (클라이언트 IP)

```
%h
```

**설명:**
- 이제 `%h`는 순수 IP 주소만 받음 (hostname:port가 제거됨)
- IPv4, IPv6 모두 지원
- GoAccess IP 검증 규칙 만족

**예제:**
```
220.123.66.49
192.168.1.1
::1 (IPv6 localhost)
2001:db8::1 (IPv6)
```

**이전 문제 (COMBINED 포맷):**
```
❌ 잘못된 형식
biz.hanbat.ac.kr:443 <- IP 필드에 호스트명:포트
```

**현재 해결책 (VCOMBINED 포맷):**
```
✅ 올바른 형식
%v:%^ %h
biz.hanbat.ac.kr:443 220.123.66.49  <- 명시적 분리
```

---

#### 3. 요청 시간 (Date & Time)

```
%d:%t
```

**필드:**
- `%d` = 날짜 (포맷: %d/%b/%Y 기본값)
- `:` = 리터럴 콜론
- `%t` = 시간 (포맷: %H:%M:%S 기본값)

**예제:**
```
21/Jan/2026:14:30:45
01/Feb/2026:23:59:59
```

**날짜 파싱:**
- 기본 포맷: `%d/%b/%Y` (예: 21/Jan/2026)
- 대체 가능: `%Y-%m-%d`, `%m/%d/%Y` 등
- 명시적 지정: `--date-format="%d/%b/%Y"`

**시간 파싱:**
- 기본 포맷: `%H:%M:%S` (예: 14:30:45)
- 24시간 형식: %H (00-23)
- 명시적 지정: `--time-format="%H:%M:%S"`

---

#### 4. 타임존 (Time Zone - 스킵됨)

```
%^
```

**설명:**
- `%^` = 다음 필드 스킵
- 타임존 정보 (예: +0900, -0800) 는 무시됨
- GoAccess는 시간:분:초만 필요

**예제:**
```
[21/Jan/2026:14:30:45 +0900]
                      ^^^^^^ 이 부분이 %^ 로 스킵됨
```

---

#### 5. HTTP 요청 라인

```
"%r"
```

**포함 사항:**
- HTTP 메서드 (GET, POST, PUT, DELETE, HEAD, OPTIONS 등)
- 요청 URI (경로, 쿼리 파라미터)
- HTTP 프로토콜 버전 (HTTP/1.0, HTTP/1.1, HTTP/2.0 등)

**예제:**
```
"GET / HTTP/1.1"
"POST /api/users HTTP/1.1"
"HEAD /image.png HTTP/1.0"
"OPTIONS * HTTP/1.1"
```

**파싱 결과:**
```
Method: GET
Request Path: /
Protocol: HTTP/1.1
```

---

#### 6. HTTP 응답 상태 코드

```
%s
```

**범위:** 100-599

**상태 분류:**
- 1xx: 정보 (100 Continue)
- 2xx: 성공 (200 OK, 201 Created)
- 3xx: 리다이렉션 (301 Moved Permanently, 302 Found)
- 4xx: 클라이언트 오류 (400 Bad Request, 404 Not Found)
- 5xx: 서버 오류 (500 Internal Server Error, 503 Service Unavailable)

**예제:**
```
200 (성공)
301 (영구 이동)
404 (찾을 수 없음)
500 (서버 오류)
```

---

#### 7. 응답 바이트 크기

```
%b
```

**설명:**
- 응답 본문의 크기 (바이트 단위)
- 헤더 크기는 제외
- HTTP 304 Not Modified 같은 경우 0 가능

**예제:**
```
166 (bytes)
1024 (1KB)
1048576 (1MB)
0 (캐시 히트, 304 Not Modified)
- (크기 정보 없음, 연결 끊김)
```

---

#### 8. HTTP Referer 헤더

```
"%R"
```

**설명:**
- 사용자가 이전에 방문한 페이지 URL
- 외부 링크를 통한 방문 추적에 사용
- "-" = Referer 없음 (직접 방문, 북마크, 검색 엔진 등)

**예제:**
```
"-" (Referer 없음)
"https://www.google.com/search?q=example"
"https://example.com/page1"
"https://example.com/"
```

---

#### 9. HTTP User-Agent 헤더

```
"%u"
```

**설명:**
- 클라이언트 브라우저 및 OS 정보
- 봇, 크롤러 탐지에 사용
- "-" = User-Agent 없음

**예제:**
```
"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"
"curl/7.64.1"
"FlowKat/5.0.27" (커스텀 에이전트)
"-" (User-Agent 없음)
```

---

## 실제 로그 라인 분석

### 전체 예제

```
biz.hanbat.ac.kr:443 220.123.66.49 - - [21/Jan/2026:14:30:45 +0900] "GET / HTTP/1.1" 301 166 "-" "FlowKat/5.0.27"
```

### 필드별 매핑

```
biz.hanbat.ac.kr:443         ← %v:%^  (Virtual Host:port 스킵)
220.123.66.49                 ← %h     (Remote IP)
-                             ← (사용자명 - 무시됨)
-                             ← (인증 사용자 - 무시됨)
[21/Jan/2026:14:30:45 +0900] ← [%d:%t %^] (날짜, 시간, 타임존 스킵)
"GET / HTTP/1.1"             ← "%r" (요청 라인)
301                           ← %s  (상태 코드)
166                           ← %b  (응답 크기)
"-"                           ← "%R" (Referer)
"FlowKat/5.0.27"             ← "%u" (User-Agent)
```

### 파싱 결과 (GoAccess에서)

```
Virtual Host: biz.hanbat.ac.kr
Remote IP: 220.123.66.49
Date: 21/Jan/2026
Time: 14:30:45
Method: GET
Path: /
Protocol: HTTP/1.1
Status: 301 (Permanent Redirect)
Size: 166 bytes
Referer: Direct (no referer)
User-Agent: FlowKat/5.0.27
```

---

## 실제 로그 샘플

### 다양한 Virtual Host와 요청

```
biz.hanbat.ac.kr:443 220.123.66.49 - - [21/Jan/2026:14:30:45 +0900] "GET / HTTP/1.1" 301 166 "-" "FlowKat/5.0.27"
lec.hanbat.ac.kr:443 203.0.113.45 - - [21/Jan/2026:14:31:12 +0900] "GET /course HTTP/1.1" 200 5234 "https://www.google.com" "Mozilla/5.0"
iace.hanbat.ac.kr:80 198.51.100.89 - - [21/Jan/2026:14:32:00 +0900] "POST /api/login HTTP/1.1" 200 234 "-" "curl/7.64.1"
biz.hanbat.ac.kr:443 192.0.2.1 - - [21/Jan/2026:14:32:45 +0900] "GET /admin/dashboard HTTP/1.1" 404 612 "-" "Mozilla/5.0"
inno.hanbat.ac.kr:443 198.51.100.200 - - [21/Jan/2026:14:33:10 +0900] "OPTIONS * HTTP/1.1" 200 0 "-" "Java-http-client/11.0.8"
```

### 통계 분석 결과 (GoAccess에서)

```
Virtual Hosts:
  biz.hanbat.ac.kr    (2 requests)
  lec.hanbat.ac.kr    (1 request)
  iace.hanbat.ac.kr   (1 request)
  inno.hanbat.ac.kr   (1 request)

Status Codes:
  2xx: 3 (성공)
  3xx: 1 (리다이렉션)
  4xx: 1 (클라이언트 오류)

Top Paths:
  /             (1 request)
  /course       (1 request)
  /api/login    (1 request)
  /admin/dashboard (1 request)

Top Referrers:
  Direct        (3 requests)
  Google        (1 request)

Top User-Agents:
  Mozilla/5.0   (1 request)
  FlowKat/5.0   (1 request)
  curl          (1 request)
  Java-http    (1 request)
```

---

## GoAccess 포맷 지정자 참조

### 지원되는 모든 지정자

| 지정자 | 설명 | 예제 |
|--------|------|------|
| %a | 원격 IP 주소 (별칭) | 220.123.66.49 |
| %h | 호스트명 또는 IP | 220.123.66.49 |
| %l | RFC 1413 Identity | - |
| %u | 사용자명 (인증) | kranian |
| %t | 시간 (포맷 변경 필요) | [21/Jan/2026:14:30:45 +0900] |
| %d | 날짜 (포맷 변경 필요) | 21/Jan/2026 |
| %r | 요청 라인 | GET / HTTP/1.1 |
| %m | 요청 메서드 | GET |
| %U | 요청 URI | / |
| %q | 쿼리 문자열 | ?param=value |
| %s | 상태 코드 | 200 |
| %b | 응답 바이트 크기 | 1234 |
| %R | Referer | https://... |
| %u | User-Agent | Mozilla/5.0 |
| %v | Virtual Host | example.com |
| %^ | 필드 스킵 | (생략) |
| %T | 응답 시간 (초) | 0.123 |
| %>s | 마지막 상태 코드 | 200 |

---

## 자주 하는 실수

### ❌ 실수 1: VCOMBINED 자체 혼동

```bash
# 잘못된 방법
--log-format="VCOMBINED" --date-format="%d/%b/%Y %H:%M:%S"

# 올바른 방법
--log-format="VCOMBINED" --date-format="%d/%b/%Y" --time-format="%H:%M:%S"
```

**이유:** date-format과 time-format은 별도로 지정해야 합니다.

---

### ❌ 실수 2: 포트 건너뛰기 깜빡함

```bash
# 잘못된 포맷
%v %h [%d:%t] ...       # 포트 정보가 %h 로 흘러옴

# 올바른 포맷
%v:%^ %h [%d:%t] ...    # %^ 로 포트 건너뜀
```

---

### ❌ 실수 3: 타임존 처리 안 함

```bash
# 잘못된 포맷
%v:%^ %h [%d:%t] "%r" %s %b

# 올바른 포맷
%v:%^ %h [%d:%t %^] "%r" %s %b  # %^ 로 타임존 건너뜀
```

---

## 테스트 및 검증

### 포맷 검증 명령어

```bash
# 작은 샘플로 검증
head -10 /path/to/access.log | \
docker run -i goaccess-flowkat \
  --log-format VCOMBINED \
  --date-format "%d/%b/%Y" \
  --time-format "%H:%M:%S" \
  -a
```

### 성공 기준

✅ 오류 없음
✅ vhost가 정확히 분리됨
✅ IP 주소 오류 없음
✅ 시간 정보 파싱됨
✅ 상태 코드별 집계 정상

---

## 성능 특성

### 테스트 결과 (GoAccess 1.9.4)

| 로그 라인 수 | 처리 시간 | 메모리 | 상태 |
|------------|---------|--------|------|
| 100줄 | ~0.1s | ~20MB | ✅ 성공 |
| 1,000줄 | ~0.5s | ~50MB | ✅ 성공 |
| 2,000줄 | ~1s | ~100MB | ✅ 성공 |
| 2,600줄 | ~2s | ~150MB | ✅ 성공 |
| 2,800줄+ | Seg Fault | - | ❌ GoAccess 버그 |

### 제약사항

- **2,600줄 이상:** GoAccess 1.9.4 메모리 관리 버그
- **워라운드:** 파일 분할 또는 GoAccess 업그레이드

---

## 참고 자료

- SPEC-VHOST-001 구현 사양서
- GoAccess 공식 문서: https://goaccess.io/man
- Phase 2 테스트 결과 보고서

---

**마지막 업데이트:** 2026-01-21
**상태:** ✅ 완성
**언어:** 한국어 (Korean)
