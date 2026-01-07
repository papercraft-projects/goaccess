# FlowKat 프로젝트 작업 완료 보고서

본 문서는 GoAccess 기반의 커스텀 로그 분석 솔루션인 **FlowKat**의 구현 내용과 최종 결과를 정리한 보고서입니다.

---

## 1. 프로젝트 목적
- **브랜딩**: GoAccess에 FlowKat 전용 비주얼 아이텐티티(배너, 로고) 적용.
- **분석 특화**: 사용자별(`~user`) 및 카페별(`/cafe/ID`) 분석 기능을 시스템 엔진에 직접 내장.
- **편의성**: Docker 기반의 자동 빌드 및 실행 워크플로우 구축.

---

## 2. 주요 작업 내용

### 2.1 커스텀 브랜딩 적용 (Core C 수정)
- **터미널 배너**: ASCII Art(`banner.txt`)를 C 헤더(`banner.h`)로 변환하여 컴파일 시 바이너리에 내장. 터미널 대시보드 실행 시 스플래시 화면으로 출력.
- **리포트 로고**: PNG 로고(`180x180.png`)를 Base64 데이터 URI로 변환하여 HTML 헤더에 고정 노출되도록 수정.
- **라벨링**: 모든 리포트 및 터미널 타이틀을 "GoAccess"에서 "FlowKat"으로 전면 교체 (`labels.h` 수정).

### 2.2 Native Identity Analysis 엔진 구현 (Parser & Storage)
기존의 단순 로그 분석을 넘어, FlowKat만의 고유 비즈니스 로직을 C 엔진에 직접 이식했습니다.
- **Identity 추출 로직**: `src/parser.c` 내에 URI 패턴 분석기(`extract_flowkat_id`) 구현.
    - `/~([username])` 패턴 추출
    - `/cafe/([ID])` 패턴 추출
- **데이터 아키텍처 확장**: 새로운 분석 패널인 `FLOWKAT_ID` 모듈을 정의하고, 전용 해시 테이블 자료구조를 할당 (`commons.h`, `gstorage.c` 수정).
- **멀티 출력 지원**: 추출된 데이터는 TUI(터미널), 정적 HTML 리포트, 실시간 WebSocket 리포트, JSON 데이터에 모두 반영되도록 파이프라인 연결.

### 2.3 인프라 및 자동화 구축
- **Docker 워크플로우**: Alpine Linux 기반의 Multi-stage 빌드 프로세스 구축 (`Dockerfile`).
- **빌드 스크립트**: 자산 변환 및 이미지 생성을 자동화하는 `build_docker.sh` 제작.
- **대화형 러너**: 로그 선택, 포맷 지정, 분석 모드 선택을 지원하는 대화형 엔진 `run_flowkat.sh` 제작.

---

## 3. 작업 결과물

| 분류 | 파일명 | 설명 |
| :--- | :--- | :--- |
| **바이너리 자산** | `banner.txt`, `180x180.png` | 브랜딩 소스 자산 |
| **자동화 스크립트** | `build_docker.sh`, `run_flowkat.sh` | 빌드 및 대화형 실행 도구 |
| **가이드 문서** | `FLOWKAT_GUIDE.md` | 사용자 매뉴얼 (KOR) |
| **핵심 수정 소스** | `src/parser.c`, `src/gstorage.c` | 사용자/카페 분석 로직 포함 |

---

## 4. 최종 결과 요약

1. **성능**: 쉘 전처리 스크립트 방식에서 **C Native 엔진 방식**으로 전환하여 대용량 로그 처리 성능 극대화.
2. **분석**: 도메인/파일 통계와 분리된 **독립적인 FlowKat Identity 패널** 확보.
3. **사용자 경험**: 전용 배너와 로고를 통해 FlowKat 솔루션으로서의 정체성 확립.
4. **배포**: Docker 이미지 하나로 모든 환경에서 동일한 분석 환경 즉시 가동 가능.

---
**보고자: Antigravity (Advanced Agentic Coding AI)**
**작업 완료일: 2026-01-08**
