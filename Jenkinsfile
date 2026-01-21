// GoAccess Docker Build Pipeline
// Version: 2.0.0
// Description: GoAccess C Project - Docker Hub push with git-based versioning
// Target: flowkat/goaccess:latest (AMD64)

pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        // Docker Registry (GoAccess용)
        DOCKER_REGISTRY = 'flowkat/goaccess'
    }

    options {
        // 동시 빌드 방지
        disableConcurrentBuilds()
        // 빌드 타임아웃 30분
        timeout(time: 30, unit: 'MINUTES')
        // 빌드 기록 20개 보관
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        // ========================================
        // Stage 1: 브랜치 필터 (main/master만)
        // ========================================
        stage('Filter Branch') {
            steps {
                script {
                    def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'unknown'

                    // main 또는 master 브랜치만 빌드
                    if (!branchName.contains('main') && !branchName.contains('master')) {
                        echo "================================================"
                        echo "Branch: ${branchName}"
                        echo "Not main/master - Skipping build"
                        echo "================================================"
                        currentBuild.result = 'NOT_BUILT'
                        error("Branch ${branchName} is not eligible for build")
                    }
                }
            }
        }

        // ========================================
        // Stage 2: 버전 설정 (Git 커밋 해시)
        // ========================================
        stage('Setup Version') {
            steps {
                script {
                    // 커밋 해시 추출 (7자리)
                    env.COMMIT_HASH = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    // 버전 생성: git-{SHA}
                    env.BUILD_VERSION = "git-${env.COMMIT_HASH}"

                    // 빌드 타임스탬프
                    env.BUILD_DATE = sh(
                        script: "date -u +'%Y-%m-%dT%H:%M:%SZ'",
                        returnStdout: true
                    ).trim()

                    echo "================================================"
                    echo "Building GoAccess Docker Image"
                    echo "================================================"
                    echo "Commit Hash: ${env.COMMIT_HASH}"
                    echo "Build Version: ${env.BUILD_VERSION}"
                    echo "Build Date: ${env.BUILD_DATE}"
                    echo "Docker Registry: ${env.DOCKER_REGISTRY}"
                    echo "================================================"
                }
            }
        }

        // ========================================
        // Stage 3: Docker 이미지 빌드
        // ========================================
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        echo "Building Docker image..."
                        docker build \
                            -t ${env.DOCKER_REGISTRY}:${env.BUILD_VERSION} \
                            -t ${env.DOCKER_REGISTRY}:latest \
                            --build-arg BUILD_DATE=${env.BUILD_DATE} \
                            --build-arg VERSION=${env.BUILD_VERSION} \
                            -f Dockerfile .

                        echo "Docker image built successfully!"
                        docker images | grep ${env.DOCKER_REGISTRY}
                    """
                }
            }
        }

        // ========================================
        // Stage 4: Docker Hub 푸시
        // ========================================
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'DOCKER_HUB_CREDENTIALS',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "Logging in to Docker Hub..."
                            echo \${DOCKER_PASS} | docker login -u \${DOCKER_USER} --password-stdin

                            echo "Pushing versioned tag: ${env.BUILD_VERSION}"
                            docker push ${env.DOCKER_REGISTRY}:${env.BUILD_VERSION}

                            echo "Pushing latest tag"
                            docker push ${env.DOCKER_REGISTRY}:latest

                            echo "Logging out..."
                            docker logout

                            echo "Push complete!"
                        """
                    }
                }
            }
        }
    }

    // ========================================
    // Post Actions (Mattermost 알림)
    // ========================================
    post {
        success {
            script {
                def commitMsg = sh(
                    script: "git log -1 --pretty=%B",
                    returnStdout: true
                ).trim()

                def author = sh(
                    script: "git log -1 --pretty=%an",
                    returnStdout: true
                ).trim()

                def durationSeconds = ((System.currentTimeMillis() - currentBuild.startTimeInMillis) / 1000).toInteger()
                def minutes = durationSeconds.intdiv(60)
                def seconds = durationSeconds % 60

                mattermostSend(
                    color: 'good',
                    channel: '#deployments',
                    message: """**✅ GoAccess Docker 빌드 성공**: ${env.JOB_NAME} #${env.BUILD_NUMBER}
**버전**: ${env.BUILD_VERSION}
**이미지**: ${env.DOCKER_REGISTRY}:${env.BUILD_VERSION}
**태그**: ${env.DOCKER_REGISTRY}:latest
**작성자**: ${author}
**커밋**: ${commitMsg}
**소요 시간**: ${minutes}분 ${seconds}초
(<${env.BUILD_URL}|자세히 보기>)"""
                )
            }
        }

        failure {
            script {
                def author = sh(
                    script: "git log -1 --pretty=%an",
                    returnStdout: true
                ).trim()

                mattermostSend(
                    color: 'danger',
                    channel: '#deployments',
                    message: """**❌ GoAccess Docker 빌드 실패**: ${env.JOB_NAME} #${env.BUILD_NUMBER}
**버전**: ${env.BUILD_VERSION}
**작성자**: ${author}
(<${env.BUILD_URL}console|로그 보기>)"""
                )
            }
        }

        always {
            cleanWs()
        }
    }
}
