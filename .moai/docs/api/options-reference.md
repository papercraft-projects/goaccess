# GoAccess CLI 옵션 참조 - vhost:port 파싱

## 개요

vhost:port 파싱 기능을 지원하는 새로운 GoAccess 실행 옵션들입니다. 이 문서는 SPEC-VHOST-001 구현의 핵심 옵션을 참조용으로 제공합니다.

---

## 새로운 로그 포맷: VCOMBINED

### 문법

```bash
--log-format=VCOMBINED
```

### 설명

**VCOMBINED** (Virtual Host Combined) 포맷은 표준 Combined 포맷의 확장으로, 가상 호스트 정보를 포함합니다.

### 포맷 문자열

```
%v:%^ %h %^[%d:%t %^] "%r" %s %b "%R" "%u"
```

### 필드 설명

| 필드 | 지정자 | 설명 | 예제 |
|------|--------|------|------|
| Virtual Host (vhost) | %v | 가상 호스트 이름 | biz.hanbat.ac.kr |
| Port (skip) | %^ | 포트 번호 (스킵) | 443 |
| Remote IP | %h | 클라이언트 IP 주소 | 220.123.66.49 |
| 날짜:시간 | %d:%t | 요청 날짜와 시간 | 21/Jan/2026:14:30:45 |
| 시간대 (skip) | %^ | 타임존 정보 (스킵) | +0900 |
| 요청 라인 | %r | HTTP 메서드, 경로, 프로토콜 | GET / HTTP/1.1 |
| 상태 코드 | %s | HTTP 응답 상태 | 301 |
| 응답 바이트 | %b | 응답 본문 크기 (바이트) | 166 |
| Referer | %R | HTTP Referer 헤더 | "-" |
| User-Agent | %u | HTTP User-Agent 헤더 | "FlowKat/5.0.27" |

### 예제 로그 라인

```
biz.hanbat.ac.kr:443 220.123.66.49 - - [21/Jan/2026:14:30:45 +0900] "GET / HTTP/1.1" 301 166 "-" "FlowKat/5.0.27"
```

### 파싱 결과

GoAccess가 위 라인을 파싱할 때:
- **Virtual Host**: biz.hanbat.ac.kr
- **Remote IP**: 220.123.66.49
- **요청 시간**: 21/Jan/2026 14:30:45
- **요청**: GET / HTTP/1.1
- **상태**: 301 Redirect
- **크기**: 166 bytes

### 사용 상황

vhost:port 로그 포맷을 사용하는 웹 서버:
- Nginx (with virtual hosts)
- Apache (with virtual hosts)
- IIS (with host headers)
- CloudFlare
- WAF 솔루션

---

## 날짜 포맷 옵션: --date-format

### 문법

```bash
--date-format="%d/%b/%Y"
```

### 설명

로그 파일의 날짜 필드를 파싱할 때 사용되는 포맷을 지정합니다.

### 지원되는 포맷

| 포맷 지정자 | 설명 | 예제 |
|------------|------|------|
| %d | 일 (01-31) | 21 |
| %m | 월 (01-12) | 01 |
| %b | 월 (약칭) | Jan, Feb, Mar, ... |
| %B | 월 (전체) | January, February, ... |
| %Y | 연도 (4자리) | 2026 |
| %y | 연도 (2자리) | 26 |
| %j | 연중 일수 (001-366) | 021 |

### 자주 사용되는 포맷 조합

| 포맷 | 예제 출력 | 사용처 |
|------|----------|--------|
| %d/%b/%Y | 21/Jan/2026 | Nginx 기본값 |
| %Y-%m-%d | 2026-01-21 | ISO 8601 형식 |
| %m/%d/%Y | 01/21/2026 | 미국 형식 |
| %d-%m-%Y | 21-01-2026 | 유럽 형식 |
| %d/%b/%y | 21/Jan/26 | 약식 |

### 사용 예제

```bash
# Nginx 기본 포맷
--date-format="%d/%b/%Y"

# ISO 8601 포맷
--date-format="%Y-%m-%d"

# 사용자 정의 포맷
--date-format="%d-%b-%Y"
```

---

## 시간 포맷 옵션: --time-format

### 문법

```bash
--time-format="%H:%M:%S"
```

### 설명

로그 파일의 시간 필드를 파싱할 때 사용되는 포맷을 지정합니다.

### 지원되는 포맷

| 포맷 지정자 | 설명 | 범위 |
|------------|------|------|
| %H | 시간 (00-23) | 00-23 |
| %I | 시간 (01-12) | 01-12 |
| %M | 분 (00-59) | 00-59 |
| %S | 초 (00-59) | 00-59 |
| %p | AM/PM | AM, PM |

### 자주 사용되는 포맷 조합

| 포맷 | 예제 출력 | 사용처 |
|------|----------|--------|
| %H:%M:%S | 14:30:45 | 24시간 형식 (ISO) |
| %I:%M:%S %p | 02:30:45 PM | 12시간 형식 (AM/PM) |
| %H:%M | 14:30 | 분 단위 정밀도 |

### 사용 예제

```bash
# ISO 8601 형식 (권장)
--time-format="%H:%M:%S"

# 12시간 형식
--time-format="%I:%M:%S %p"

# 분 단위만
--time-format="%H:%M"
```

---

## 통합 사용 예제

### 기본 실행 (docker)

```bash
docker run --rm \
  -v /path/to/logs:/logs \
  goaccess-flowkat:latest \
  /logs/access.log \
  --log-format=VCOMBINED \
  --date-format="%d/%b/%Y" \
  --time-format="%H:%M:%S"
```

### run_simple.sh를 통한 실행

```bash
# TUI 모드
./run_simple.sh tui

# HTML 리포트 생성
./run_simple.sh html

# 실시간 모니터링
./run_simple.sh realtime

# 필터링 모드
./run_simple.sh filter
```

### run_flowkat.sh를 통한 대화형 실행

```bash
./run_flowkat.sh
# 메뉴 선택:
# 1) Nginx/Apache VCombined (with Virtual Host) - Recommended
# 2) Nginx/Apache Combined (Standard)
# ... 다른 포맷 옵션들
```

---

## 호환성 매트릭스

### 로그 서버별 기본 포맷

| 웹 서버 | vhost 지원 | 권장 포맷 | date-format | time-format |
|--------|-----------|-----------|-------------|------------|
| **Nginx + vhost** | ✅ YES | VCOMBINED | %d/%b/%Y | %H:%M:%S |
| **Apache vhost** | ✅ YES | VCOMBINED | %d/%b/%Y | %H:%M:%S |
| **IIS** | ✅ YES | VCOMBINED | %Y-%m-%d | %H:%M:%S |
| **Nginx (표준)** | ❌ NO | COMBINED | %d/%b/%Y | %H:%M:%S |
| **Apache (표준)** | ❌ NO | COMBINED | %d/%b/%Y | %H:%M:%S |

### GoAccess 버전 호환성

| GoAccess 버전 | VCOMBINED 지원 | 상태 |
|-------------|--------------|------|
| 1.9.4 | ✅ YES | 테스트됨 (2,600줄까지 안정적) |
| 1.9.5+ | ✅ YES | 예상 (추천) |
| 1.8.x | ⚠️ 미확인 | 테스트 필요 |
| < 1.8 | ❌ NO | 미지원 |

---

## 제약사항 및 알려진 문제

### GoAccess 1.9.4 메모리 제약

**상황:**
- 2,600줄 이상의 로그 파일 처리 시 메모리 관리 문제 발생 가능
- 약 2,800줄 이상에서 Seg Fault (SIGSEGV) 발생 보고됨

**영향:**
- 포맷 파싱: ✅ 정상 (포맷은 완벽함)
- 메모리 사용: ⚠️ GoAccess 내부 버그

**워라운드:**
1. 로그 파일 분할: 파일을 2,000줄 단위로 분할하여 처리
2. GoAccess 업그레이드: 최신 버전(1.9.5+)으로 업그레이드
3. 파일 크기 제한: 2,600줄 이하 파일만 처리

### 문자 인코딩

- 입력: UTF-8 권장
- 출력: UTF-8 기본값
- 다른 인코딩: 로그 파일 사전 변환 필요

---

## 문제 해결

### Q: "Invalid log format" 오류가 발생합니다

**A:** 다음을 확인하세요:
1. `--log-format` 값 확인: VCOMBINED (대소문자 구분)
2. 로그 파일의 실제 포맷 확인: 샘플 라인을 보고 포맷 재확인
3. 구분자 확인: 탭 vs 공백 일치 확인

### Q: 날짜/시간이 파싱되지 않습니다

**A:** 다음을 확인하세요:
1. `--date-format` 값과 로그 파일 날짜 형식 일치 확인
2. `--time-format` 값과 로그 파일 시간 형식 일치 확인
3. 예제: 로그가 "21/Jan/2026:14:30:45"인 경우
   - date-format: `%d/%b/%Y`
   - time-format: `%H:%M:%S`

### Q: vhost가 IP 주소로 표시됩니다

**A:** 다음을 확인하세요:
1. 로그 포맷이 VCOMBINED인지 확인
2. 로그 파일에 실제로 호스트명이 포함되어 있는지 확인
3. Reverse DNS 설정 확인 (필요시)

---

## 참고 자료

- **SPEC-VHOST-001**: vhost:port 파싱 구현 사양서
- **Phase 2 Results**: 테스트 결과 및 검증 보고서
- **GoAccess 공식 문서**: https://goaccess.io/

---

**마지막 업데이트:** 2026-01-21
**상태:** ✅ 완성
**언어:** 한국어 (Korean)
