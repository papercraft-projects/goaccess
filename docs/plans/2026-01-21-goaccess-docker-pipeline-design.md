# GoAccess Docker Pipeline Design

**Date**: 2026-01-21
**Version**: 1.0.0
**Status**: ✅ Approved & Implemented

---

## 📋 Executive Summary

GoAccess C 프로젝트를 위한 Docker 빌드 & 배포 파이프라인을 설계했습니다. 이 파이프라인은:

- ✅ **main/master 브랜치만** 자동 빌드
- ✅ **Git 커밋 해시** 기반 버전 관리 (`git-{SHA}`)
- ✅ **AMD64 아키텍처** 최적화
- ✅ **Docker Hub 자동 푸시** (`flowkat/goaccess:latest`)
- ✅ **Mattermost 자동 알림**

---

## 🎯 Design Goals

| Goal | Implementation | Rationale |
|------|----------------|-----------|
| 안정성 | main/master만 빌드 | 의도된 릴리스만 배포 |
| 추적성 | Git 커밋 해시 태그 | 정확한 소스 코드 특정 |
| 단순성 | AMD64만 지원 | 빠른 빌드 (∼10-15분) |
| 자동화 | Docker Hub 자동 푸시 | 수동 개입 최소화 |
| 가시성 | Mattermost 알림 | 팀 전체 실시간 인지 |

---

## 🏗️ Architecture

### Pipeline Flow

```
Git Push (main/master)
    ↓
Trigger Check (브랜치 필터)
    ↓
Setup Version (커밋 해시 추출)
    ↓
Build Docker Image (AMD64)
    ↓
Push to Docker Hub (latest + git-{SHA})
    ↓
Notify Mattermost
```

### Stage Breakdown

#### Stage 1: Filter Branch
- **목적**: main 또는 master 브랜치만 빌드
- **실패 시**: 빌드 스킵 (NOT_BUILT)
- **이유**: 의도되지 않은 브랜치에서의 불필요한 빌드 방지

#### Stage 2: Setup Version
- **목표**: Git 커밋 정보 수집
- **출력**:
  - `COMMIT_HASH`: 7자리 커밋 해시
  - `BUILD_VERSION`: `git-{COMMIT_HASH}` 형식
  - `BUILD_DATE`: ISO 8601 타임스탬프
- **이유**: 각 빌드를 정확하게 추적 및 식별

#### Stage 3: Build Docker Image
- **빌드 아규먼트**:
  - `BUILD_DATE`: Dockerfile의 LABEL 설정
  - `VERSION`: Dockerfile의 LABEL 설정
- **태그**:
  - `flowkat/goaccess:git-{SHA}` (버전 태그)
  - `flowkat/goaccess:latest` (최신 태그)
- **기반**: Alpine 3.20 멀티스테이지 빌드 (기존 Dockerfile)

#### Stage 4: Push to Docker Hub
- **인증**: Jenkins Credentials (DOCKER_HUB_CREDENTIALS)
- **푸시 태그**:
  1. 버전 태그 (`git-{SHA}`)
  2. latest 태그
- **보안**: 로그인 후 로그아웃으로 크레덴셜 보호

### Post Actions

#### Success
- 성공 알림 포함:
  - 빌드 버전
  - Docker 이미지명
  - 커밋 메시지
  - 작성자
  - 소요 시간
  - 빌드 로그 링크

#### Failure
- 실패 알림 포함:
  - 빌드 실패 표시
  - 버전
  - 작성자
  - 로그 링크

#### Always
- 워크스페이스 정리 (`cleanWs()`)

---

## 📊 Key Features

### Version Management
```
Commit: a1b2c3d
↓
Build Version: git-a1b2c3d
↓
Docker Tags:
  - flowkat/goaccess:git-a1b2c3d
  - flowkat/goaccess:latest
```

### Credentials
```
Jenkins Credentials:
- DOCKER_HUB_CREDENTIALS
  └── Username: DOCKER_USER
  └── Password: DOCKER_PASS
```

### Options
- ✅ **Disable Concurrent Builds**: 동시 빌드 방지
- ✅ **Timeout**: 30분 (C 프로젝트 컴파일 시간 고려)
- ✅ **Build History**: 최대 20개 보관

---

## 🔧 Configuration

### Jenkins Credentials Required
1. **DOCKER_HUB_CREDENTIALS**
   - Type: Username with password
   - Value: Docker Hub 계정 정보

### Mattermost Setup (Optional)
- 채널: `#deployments`
- 성공/실패 알림 자동 전송

---

## 📈 Performance

| Aspect | Value | Notes |
|--------|-------|-------|
| Timeout | 30분 | C 프로젝트 컴파일 시간 |
| Build History | 20개 | 적절한 히스토리 보관 |
| Architecture | AMD64 | 빠른 빌드 |
| Concurrent Builds | 비활성 | 안정성 우선 |

---

## 🚀 Deployment Path

1. **Local Testing**
   ```bash
   docker build -t flowkat/goaccess:local .
   docker run flowkat/goaccess:local --help
   ```

2. **Jenkins Push**
   ```bash
   git commit -m "Add Docker pipeline"
   git push origin main
   ```

3. **Automatic Build & Push**
   - Jenkins 자동 트리거
   - Docker Hub에 `latest` 태그 배포

4. **Pull & Use**
   ```bash
   docker pull flowkat/goaccess:latest
   docker run flowkat/goaccess:latest [options]
   ```

---

## 📝 Dockerfile Integration

### Current Dockerfile (Alpine 3.20)
- ✅ 멀티스테이지 빌드 (효율적)
- ✅ 최소 런타임 이미지
- ✅ 필수 라이브러리만 포함

### Build Args
```dockerfile
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${VERSION}"
```

---

## 🔍 Monitoring & Maintenance

### Build Monitoring
- Jenkins 콘솔 로그
- Mattermost 채널 알림
- Docker Hub 이미지 태그

### Maintenance Tasks
- **Weekly**: Docker Hub 이미지 정리 (oldest 5개 제거)
- **Monthly**: Jenkins 빌드 히스토리 확인

---

## 🎁 Benefits

1. **자동화**: 수동 Docker 푸시 제거
2. **추적성**: 각 이미지의 정확한 소스 코드 버전 파악
3. **안정성**: main/master 브랜치만 배포
4. **가시성**: 팀 전체 실시간 알림
5. **효율성**: Alpine 기반 작은 이미지 (~15-20MB)

---

## 📌 Future Enhancements

- [ ] Multi-architecture support (ARM64 추가)
- [ ] Signed images (Docker Content Trust)
- [ ] Security scanning (Trivy integration)
- [ ] GitHub Releases 연동
- [ ] Automated rollback 메커니즘

---

## ✅ Implementation Checklist

- [x] Jenkinsfile 작성 (GoAccess 맞춤형)
- [x] 브랜치 필터링 로직
- [x] Git 버전 관리 시스템
- [x] Docker Hub 푸시 로직
- [x] Mattermost 알림 설정
- [x] 에러 처리 & 정리 로직

---

**Design Approved By**: kranian
**Implementation Date**: 2026-01-21
**Next Review**: 2026-02-21
