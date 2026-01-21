# GoAccess Docker Pipeline Documentation

> GoAccess C 프로젝트의 자동 Docker 빌드 및 배포 파이프라인 완전 가이드

**Last Updated**: 2026-01-21
**Version**: 2.0.0

---

## 📋 목차

1. [개요](#개요)
2. [빠른 시작](#빠른-시작)
3. [파이프라인 구조](#파이프라인-구조)
4. [Jenkins 설정](#jenkins-설정)
5. [빌드 프로세스](#빌드-프로세스)
6. [Docker 이미지 사용](#docker-이미지-사용)
7. [문제 해결](#문제-해결)
8. [참고 자료](#참고-자료)

---

## 개요

### 🎯 목표

GoAccess 프로젝트의 C 소스 코드를 자동으로 빌드하여 Docker 이미지로 변환하고, Docker Hub에 배포하는 완전 자동화 CI/CD 파이프라인입니다.

### ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| **자동 빌드** | `main`/`master` 브랜치 푸시 시 자동 트리거 |
| **버전 관리** | Git 커밋 해시 기반 태깅 (`git-{SHA}`) |
| **Docker Hub 배포** | 자동 이미지 푸시 (`flowkat/goaccess:latest`) |
| **실시간 알림** | Mattermost #deployments 채널 알림 |
| **작은 이미지** | Alpine 3.20 기반 최적화 (~15-20MB) |

### 🔍 파이프라인 흐름

```
┌─────────────────────────────────┐
│   Git Push (main/master)        │
└────────────┬────────────────────┘
             ↓
      ┌──────────────────┐
      │ Stage 1: Filter  │ ← main/master만 빌드
      └────────┬─────────┘
               ↓
      ┌──────────────────────┐
      │ Stage 2: Version     │ ← git-{SHA} 추출
      └────────┬─────────────┘
               ↓
      ┌──────────────────────────┐
      │ Stage 3: Build Image     │ ← Docker 빌드
      └────────┬─────────────────┘
               ↓
      ┌──────────────────────────┐
      │ Stage 4: Push Hub        │ ← Docker Hub 푸시
      └────────┬─────────────────┘
               ↓
    ┌─────────────────────────┐
    │ Notify Mattermost       │ ← 팀 알림
    └─────────────────────────┘
```

---

## 빠른 시작

### 1️⃣ Jenkins 설정 (초기 구성)

#### 📌 Credentials 생성

```
Jenkins > Credentials > System > Global credentials > Add Credentials
```

**Type**: Username with password
**ID**: `DOCKER_HUB_CREDENTIALS`
**Username**: {Docker Hub 사용자명}
**Password**: {Docker Hub Personal Access Token}

#### 📌 Multibranch Pipeline 생성

```
Jenkins > New Job > Multibranch Pipeline
```

**Configuration**:
- **Repository**: goaccess 저장소 URL
- **Branch Source**: GitHub/GitLab (원격 저장소)
- **Branch Discoverer**: All branches
- **Jenkinsfile location**: `Jenkinsfile` (리포지토리 루트)

#### 📌 Build Trigger 설정

```
Configure > Build triggers >
  ☑ Scan Multibranch Pipeline Triggers
  Period: 1h (또는 webhook 연결)
```

### 2️⃣ 첫 빌드 테스트

```bash
# 로컬에서 작은 변경 커밋
git commit --allow-empty -m "test: first docker pipeline build"

# main/master 브랜치에 푸시
git push origin main

# Jenkins 자동 빌드 시작 (1-2분 대기)
# Jenkins 콘솔 확인: https://jenkins.example.com/job/goaccess/main/
```

### 3️⃣ Docker Hub에서 이미지 확인

```bash
# Docker Hub 웹사이트
https://hub.docker.com/r/flowkat/goaccess

# 또는 CLI에서 확인
docker search flowkat/goaccess
docker pull flowkat/goaccess:latest
docker run flowkat/goaccess:latest --help
```

---

## 파이프라인 구조

### 📁 파일 구성

```
goaccess/
├── Jenkinsfile                    # ← CI/CD 파이프라인 정의
├── Dockerfile                     # ← Docker 빌드 정의
└── docs/
    ├── README.md                  # ← 이 파일
    ├── plans/
    │   └── 2026-01-21-*.md       # ← 디자인 문서
    └── ... (기타 문서)
```

### 🔧 Jenkinsfile 상세 분석

#### Stage 1: Filter Branch

```groovy
// main 또는 master 브랜치만 빌드
if (!branchName.contains('main') && !branchName.contains('master')) {
    currentBuild.result = 'NOT_BUILT'
    error("Branch ${branchName} is not eligible for build")
}
```

**목적**: 의도되지 않은 브랜치에서의 불필요한 빌드 방지
**실패 시**: 빌드 스킵 (NO_CHANGE로 표시)

#### Stage 2: Setup Version

```groovy
env.COMMIT_HASH = sh(script: "git rev-parse --short HEAD", ...).trim()
env.BUILD_VERSION = "git-${env.COMMIT_HASH}"
env.BUILD_DATE = sh(script: "date -u +'%Y-%m-%dT%H:%M:%SZ'", ...).trim()
```

**출력**:
- `COMMIT_HASH`: 7자리 커밋 해시 (e.g., `a1b2c3d`)
- `BUILD_VERSION`: 최종 버전 (e.g., `git-a1b2c3d`)
- `BUILD_DATE`: ISO 8601 타임스탬프

#### Stage 3: Build Docker Image

```groovy
docker build \
    -t flowkat/goaccess:git-${COMMIT_HASH} \
    -t flowkat/goaccess:latest \
    --build-arg BUILD_DATE=${BUILD_DATE} \
    --build-arg VERSION=${BUILD_VERSION} \
    -f Dockerfile .
```

**결과**:
- 두 개의 태그로 동일한 이미지 생성
- 버전 태그: 정확한 소스 코드 추적
- latest 태그: 최신 버전 편의

#### Stage 4: Push to Docker Hub

```groovy
docker push flowkat/goaccess:git-${COMMIT_HASH}
docker push flowkat/goaccess:latest
```

**보안**:
1. Docker Hub 크레덴셜 로드
2. 이미지 푸시
3. 로그아웃 (크레덴셜 정리)

### 📢 Post Actions

#### ✅ Success Notification

```
✅ GoAccess Docker 빌드 성공: goaccess #123
버전: git-a1b2c3d
이미지: flowkat/goaccess:git-a1b2c3d
태그: flowkat/goaccess:latest
작성자: john.doe
커밋: Fix parser bug
소요 시간: 15분 32초
자세히 보기: https://jenkins.../logs
```

**배송처**: Mattermost #deployments

#### ❌ Failure Notification

```
❌ GoAccess Docker 빌드 실패: goaccess #124
버전: git-b2c3d4e
작성자: jane.smith
로그 보기: https://jenkins.../console
```

**배송처**: Mattermost #deployments

---

## Jenkins 설정

### 🔐 Credentials 상세 설정

#### Docker Hub Token 생성 (Personal Access Token)

1. Docker Hub 로그인: https://hub.docker.com
2. **Settings > Security > Personal Access Tokens**
3. **New Access Token** 클릭
4. Token name: `Jenkins GoAccess Pipeline`
5. Permissions: ☑ Read, Write
6. 생성된 토큰 복사

#### Jenkins에 Credentials 추가

```
Jenkins > Manage Jenkins > Credentials > System > Global credentials
```

**상세 설정**:
```
Kind: Username with password
Username: {Docker Hub 사용자명}
Password: {생성한 Personal Access Token}
ID: DOCKER_HUB_CREDENTIALS
Description: Docker Hub credentials for flowkat/goaccess
```

### 🌳 Multibranch Pipeline 설정

#### 기본 구성

```
Job Name: goaccess
Type: Multibranch Pipeline
```

#### Repository 설정

```
Branch Sources > Add source > GitHub
  - Repository HTTPS URL: https://github.com/user/goaccess
  - Credentials: {GitHub 크레덴셜 또는 Public}
```

#### Branch Discovery

```
Branch Discoverer:
  ☑ All branches
  ☑ Tags
```

#### Build Configuration

```
Jenkinsfile location: Jenkinsfile
```

#### Scan Timing

```
Scan Multibranch Pipeline Triggers:
  ☑ Periodically if not otherwise run
  Interval: 1 hour (또는 webhook 사용)
```

### 🔔 Mattermost 알림 설정 (선택사항)

#### Mattermost Webhook URL

1. Mattermost 서버 로그인
2. **Settings > Integrations > Incoming Webhooks**
3. **Add Incoming Webhook**
   - Channel: `#deployments`
   - Display Name: `GoAccess Docker Pipeline`
   - 생성된 URL 복사

#### Jenkins 설정

```groovy
mattermostSend(
    color: 'good',
    channel: '#deployments',
    message: "..."
)
```

> **주의**: `mattermostSend`는 Mattermost plugin이 필요합니다.
> **설치**: Jenkins > Manage Plugins > Search "Mattermost" > Install

---

## 빌드 프로세스

### 📊 전체 프로세스 타임라인

```
시간 0초     → Git push
시간 30초    → Jenkins 트리거 (webhook 또는 scan)
시간 1분     → 빌드 시작
시간 2분     → Filter Branch + Version 설정
시간 3분     → Docker 빌드 시작
시간 15분    → Docker 빌드 완료
시간 16분    → Docker Hub 푸시
시간 18분    → 완료 (Mattermost 알림)
```

### 🏗️ Docker 빌드 단계

#### Stage 1: Build Stage

```dockerfile
FROM alpine:3.20 AS builds

RUN apk add --no-cache \
    autoconf automake build-base clang \
    gettext-dev libmaxminddb-dev openssl-dev \
    linux-headers ncurses-dev pkgconf tzdata

COPY . /goaccess
WORKDIR /goaccess

RUN autoreconf -fiv
RUN CC="clang" CFLAGS="-O3" ./configure \
    --prefix=/usr --enable-utf8 --with-openssl \
    --enable-geoip=mmdb

RUN make -j$(nproc) && make DESTDIR=/dist install
```

**목적**: GoAccess 바이너리 컴파일
**결과 크기**: ~200-300MB (컴파일 도구 포함)

#### Stage 2: Runtime Stage

```dockerfile
FROM alpine:3.20

RUN apk add --no-cache \
    gettext-libs libmaxminddb ncurses-libs \
    openssl tzdata

COPY --from=builds /dist/usr/bin/goaccess /usr/bin/goaccess
COPY --from=builds /dist/usr/share /usr/share

VOLUME /var/www/goaccess
EXPOSE 7890

ENTRYPOINT ["/usr/bin/goaccess"]
CMD ["--help"]
```

**목적**: 최종 런타임 이미지
**최종 크기**: ~15-20MB (최소화됨)

### 📈 빌드 성능

| 단계 | 시간 | 노트 |
|------|------|------|
| Docker build stage 1 | ~8-10분 | C 컴파일 (클러스터 CPU에 따라 다름) |
| Docker build stage 2 | ~1-2분 | 바이너리 복사 |
| Docker push | ~1-2분 | Docker Hub 업로드 |
| **전체** | **~15-20분** | 네트워크에 따라 변동 |

---

## Docker 이미지 사용

### 🐳 기본 사용법

```bash
# 최신 이미지 다운로드
docker pull flowkat/goaccess:latest

# 또는 특정 버전 다운로드
docker pull flowkat/goaccess:git-a1b2c3d

# 실행
docker run flowkat/goaccess:latest --help
```

### 📝 일반적인 사용 예제

#### 1️⃣ 로그 분석 (HTML 리포트 생성)

```bash
docker run \
    -v /path/to/logs:/var/www/goaccess/logs:ro \
    -v /path/to/output:/var/www/goaccess/reports \
    flowkat/goaccess:latest \
    -f /var/www/goaccess/logs/access.log \
    -o /var/www/goaccess/reports/index.html
```

#### 2️⃣ 실시간 대시보드 (포트 7890)

```bash
docker run \
    -v /var/log/nginx/access.log:/var/www/goaccess/logs/access.log:ro \
    -p 7890:7890 \
    flowkat/goaccess:latest \
    -f /var/www/goaccess/logs/access.log \
    --real-time-html
```

#### 3️⃣ Docker Compose 예제

```yaml
version: '3.8'

services:
  goaccess:
    image: flowkat/goaccess:latest
    container_name: goaccess
    volumes:
      - /var/log/nginx:/var/www/goaccess/logs:ro
      - ./reports:/var/www/goaccess/reports
    ports:
      - "7890:7890"
    command:
      - "-f"
      - "/var/www/goaccess/logs/access.log"
      - "-o"
      - "/var/www/goaccess/reports/index.html"
```

### 🔍 이미지 정보 확인

```bash
# 이미지 메타데이터 확인
docker inspect flowkat/goaccess:latest | grep -A 20 "Labels"

# 빌드 정보
docker inspect flowkat/goaccess:latest \
  --format='{{index .ContainerConfig.Labels "org.opencontainers.image.version"}}'
```

---

## 문제 해결

### ❌ 빌드 실패

#### 증상: "Stage 1: Filter Branch" 실패

```
Branch develop is not eligible for build
Error: Branch develop is not eligible for build
```

**원인**: main/master 이외의 브랜치에서 푸시
**해결**:
```bash
git checkout main
git merge develop  # 변경사항 병합
git push origin main
```

#### 증상: "Docker Hub 푸시 실패"

```
denied: requested access to the resource is denied
```

**원인**: 잘못된 Docker Hub 크레덴셜
**해결**:
1. Jenkins > Credentials 확인
2. Docker Hub Personal Access Token 재생성
3. `DOCKER_HUB_CREDENTIALS` 업데이트

#### 증상: "권한 거부" 또는 "인증 실패"

```
Error: permission denied while trying to connect to Docker daemon
```

**원인**: Jenkins 사용자가 Docker 권한 없음
**해결**:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### ⚠️ 느린 빌드

#### 증상: 빌드가 20분 이상

**원인**:
- 느린 네트워크
- Alpine 패키지 다운로드 지연
- 클러스터 CPU 부하

**개선**:
1. Docker layer caching 활용 확인
2. Docker daemon 리소스 증설
3. Nexus 등의 로컬 패키지 캐시 구성

### 📋 로그 확인

#### Jenkins 콘솔 로그

```
Jenkins > Job > Build #123 > Console Output
```

#### Docker 빌드 로그

```bash
# 마지막 빌드 로그 확인
docker buildx build --progress=plain .
```

---

## 참고 자료

### 📚 관련 문서

| 문서 | 설명 |
|------|------|
| **Jenkinsfile** | CI/CD 파이프라인 정의 (Groovy DSL) |
| **Dockerfile** | Docker 이미지 빌드 정의 |
| **디자인 문서** | `docs/plans/2026-01-21-goaccess-docker-pipeline-design.md` |

### 🔗 외부 참고

- **GoAccess 공식**: https://goaccess.io
- **Docker Hub**: https://hub.docker.com/r/flowkat/goaccess
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Dockerfile Reference**: https://docs.docker.com/engine/reference/builder/
- **Alpine Linux**: https://alpinelinux.org/

### 👥 연락처

- **이메일**: kranian@example.com
- **Slack**: #deployments 채널
- **Mattermost**: #deployments 채널

---

## 📅 변경 이력

| 버전 | 날짜 | 변경 사항 |
|------|------|---------|
| 2.0.0 | 2026-01-21 | GoAccess 맞춤형 파이프라인 완성 |
| 1.0.0 | 2026-01-20 | 초기 파이프라인 구성 |

---

## ✅ 체크리스트

### 초기 설정
- [ ] Docker Hub 계정 생성
- [ ] Personal Access Token 생성
- [ ] Jenkins Credentials 추가
- [ ] Multibranch Pipeline 생성
- [ ] GitHub/GitLab webhook 설정

### 첫 빌드
- [ ] 테스트 커밋 생성
- [ ] main 브랜치에 푸시
- [ ] Jenkins 자동 빌드 확인
- [ ] Docker Hub에 이미지 확인
- [ ] Mattermost 알림 확인

### 운영
- [ ] 월별 빌드 로그 검토
- [ ] Docker Hub 스토리지 모니터링
- [ ] Jenkins 업그레이드 (연 2회)
- [ ] 보안 업데이트 적용

---

**Last Updated**: 2026-01-21
**Maintained By**: kranian
**Status**: ✅ Production Ready
