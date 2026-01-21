// FlowKat Education Platform Jenkins Pipeline
// Version: 1.0.0
// Description: Docusaurus build + Docker Hub push with bitnami/nginx

pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        // Docker Registry
        DOCKER_REGISTRY = 'flowkat/education-platform'
        // Version (package.json에서 읽기)
        BASE_VERSION = ''
        BUILD_VERSION = ''
        NODE_VERSION = '20'
        // Outline API Configuration
        OUTLINE_URL = 'https://outline.papercraft.dev'
        // Giscus Configuration (public values only)
        GISCUS_REPO = 'papercraft-projects/flowkat-tutorial'
        GISCUS_CATEGORY = 'General'
        GISCUS_LANG = 'ko'
        // Open Graph (OG) Configuration
        SITE_URL = 'https://edu.papercraft.dev'
        BASE_URL = '/'
        SITE_TITLE = 'FlowKat Tutorial'
        SITE_DESCRIPTION = 'FlowKat APM 사용 가이드'
        OG_IMAGE = 'img/flowkat_og.png'
    }

    options {
        // 동시 빌드 방지
        disableConcurrentBuilds()
        // 빌드 타임아웃 1시간
        timeout(time: 1, unit: 'HOURS')
        // 빌드 기록 30개 보관
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {
        // ========================================
        // Stage 1: 버전 설정
        // ========================================
        stage('Setup Version') {
            steps {
                script {
                    // package.json에서 버전 읽기
                    def packageJson = readJSON file: 'package.json'
                    env.BASE_VERSION = packageJson.version
                    env.BUILD_VERSION = "${env.BASE_VERSION}-${env.BUILD_NUMBER}"

                    echo "================================================"
                    echo "Building FlowKat Education Platform"
                    echo "================================================"
                    echo "Base Version: ${env.BASE_VERSION}"
                    echo "Build Version: ${env.BUILD_VERSION}"
                    echo "Docker Registry: ${env.DOCKER_REGISTRY}"
                    echo "================================================"
                }
            }
        }

        // ========================================
        // Stage 2: Docusaurus 빌드
        // ========================================
        stage('Build Docusaurus') {
            agent {
                docker {
                    image "node:${env.NODE_VERSION}"
                    reuseNode true
                }
            }
            environment {
                // Outline API Token from Jenkins Credentials (Secret text)
                OUTLINE_API_TOKEN = credentials('OUTLINE_API_TOKEN_CREDENTIALS')
                // Giscus IDs from Jenkins Credentials (Secret text)
                GISCUS_REPO_ID = credentials('GISCUS_REPO_ID_CREDENTIALS')
                GISCUS_CATEGORY_ID = credentials('GISCUS_CATEGORY_ID_CREDENTIALS')
            }
            steps {
                sh '''
                    # 환경변수 설정
                    export OUTLINE_API_TOKEN=$OUTLINE_API_TOKEN
                    export OUTLINE_URL=$OUTLINE_URL

                    # Giscus 환경변수 설정
                    export GISCUS_REPO=$GISCUS_REPO
                    export GISCUS_REPO_ID=$GISCUS_REPO_ID
                    export GISCUS_CATEGORY=$GISCUS_CATEGORY
                    export GISCUS_CATEGORY_ID=$GISCUS_CATEGORY_ID
                    export GISCUS_LANG=$GISCUS_LANG

                    # Open Graph (OG) 환경변수 설정
                    export SITE_URL=$SITE_URL
                    export BASE_URL=$BASE_URL
                    export SITE_TITLE=$SITE_TITLE
                    export SITE_DESCRIPTION=$SITE_DESCRIPTION
                    export OG_IMAGE=$OG_IMAGE

                    echo "Installing dependencies..."
                    npm ci
                    echo "Building Docusaurus..."
                    npm run docs:build

                    echo "Build complete!"
                    ls -la build/
                '''
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
                            --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
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
                def authorId = sh(script: 'git show -s --pretty=%an', returnStdout: true).trim()
                def authorName = sh(script: 'git show -s --pretty=%ae', returnStdout: true).trim()
                def commitMsg = sh(script: 'git show -s --pretty=%s', returnStdout: true).trim()
                def durationMillis = System.currentTimeMillis() - currentBuild.startTimeInMillis
                def durationSeconds = (durationMillis / 1000).toInteger()
                def minutes = durationSeconds.intdiv(60)
                def seconds = durationSeconds % 60

                mattermostSend(
                    color: 'good',
                    channel: '#deployments',
                    message: """**빌드 성공**: ${env.JOB_NAME} #${env.BUILD_NUMBER}
**버전**: ${env.BUILD_VERSION}
**작성자**: ${authorId} (${authorName})
**소요 시간**: ${minutes}분 ${seconds}초
**커밋**: ${commitMsg}
**Docker Image**: ${env.DOCKER_REGISTRY}:${env.BUILD_VERSION}
(<${env.BUILD_URL}|자세히 보기>)"""
                )
            }
        }
        failure {
            script {
                def authorId = sh(script: 'git show -s --pretty=%an', returnStdout: true).trim()

                mattermostSend(
                    color: 'danger',
                    channel: '#deployments',
                    message: """**빌드 실패**: ${env.JOB_NAME} #${env.BUILD_NUMBER}
**작성자**: ${authorId}
(<${env.BUILD_URL}|자세히 보기>)"""
                )
            }
        }
    }
}