#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 파일
LOG_FILE="/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"

echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}🚀 자동 배포 시작: $(date)${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"

# 프로젝트 디렉토리로 이동
cd /home/alche0124/Programs/production-management-system || exit 1

# 변경 전 커밋 해시 저장
BEFORE_COMMIT=$(git rev-parse HEAD)
echo -e "${YELLOW}📌 현재 커밋: $BEFORE_COMMIT${NC}" | tee -a "$LOG_FILE"

# Git pull
echo -e "${BLUE}📥 Git pull 실행...${NC}" | tee -a "$LOG_FILE"
git pull origin main 2>&1 | tee -a "$LOG_FILE"

# 변경 후 커밋 해시
AFTER_COMMIT=$(git rev-parse HEAD)
echo -e "${YELLOW}📌 새 커밋: $AFTER_COMMIT${NC}" | tee -a "$LOG_FILE"

# 변경사항 없으면 종료
if [ "$BEFORE_COMMIT" = "$AFTER_COMMIT" ]; then
    echo -e "${GREEN}✅ 변경사항 없음. 배포 종료.${NC}" | tee -a "$LOG_FILE"
    exit 0
fi

# 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only $BEFORE_COMMIT $AFTER_COMMIT)
echo -e "${YELLOW}📝 변경된 파일:${NC}" | tee -a "$LOG_FILE"
echo "$CHANGED_FILES" | tee -a "$LOG_FILE"

# 배포 전략 결정
NEED_NOCACHE=false
NEED_REBUILD=true  # 기본적으로 리빌드
NEED_MIGRATION=false

# Dockerfile 또는 docker-compose.yml 변경 시 no-cache 빌드
if echo "$CHANGED_FILES" | grep -qE "Dockerfile|docker-compose.yml|\.dockerignore"; then
    echo -e "${RED}🔥 Docker 설정 변경 감지: no-cache 빌드 필요${NC}" | tee -a "$LOG_FILE"
    NEED_NOCACHE=true
fi

# Gemfile, package.json 변경 시 리빌드 필요
if echo "$CHANGED_FILES" | grep -qE "Gemfile|Gemfile.lock|package.json|yarn.lock"; then
    echo -e "${YELLOW}📦 의존성 변경 감지: 리빌드 필요${NC}" | tee -a "$LOG_FILE"
    NEED_REBUILD=true
fi

# 마이그레이션 파일 변경 시
if echo "$CHANGED_FILES" | grep -q "db/migrate/"; then
    echo -e "${YELLOW}🗄️  마이그레이션 파일 변경 감지${NC}" | tee -a "$LOG_FILE"
    NEED_MIGRATION=true
fi

# db/schema.rb 변경 시 (다른 환경에서 마이그레이션 실행된 경우)
if echo "$CHANGED_FILES" | grep -q "db/schema.rb"; then
    echo -e "${YELLOW}🗄️  Schema 변경 감지: 마이그레이션 필요${NC}" | tee -a "$LOG_FILE"
    NEED_MIGRATION=true
fi

# SCSS 파일만 변경된 경우 리빌드 필요 (CSS 컴파일)
if echo "$CHANGED_FILES" | grep -qE "\.scss$|\.sass$" && ! echo "$CHANGED_FILES" | grep -qvE "\.scss$|\.sass$|\.css$"; then
    echo -e "${BLUE}🎨 CSS 파일만 변경: 리빌드 필요${NC}" | tee -a "$LOG_FILE"
    NEED_REBUILD=true
fi

# 배포 실행
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}🚢 배포 전략:${NC}" | tee -a "$LOG_FILE"
echo -e "  - No-cache 빌드: $NEED_NOCACHE" | tee -a "$LOG_FILE"
echo -e "  - 리빌드: $NEED_REBUILD" | tee -a "$LOG_FILE"
echo -e "  - 마이그레이션: $NEED_MIGRATION" | tee -a "$LOG_FILE"
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"

# Docker 컨테이너 중지
echo -e "${YELLOW}⏸️  컨테이너 중지 중...${NC}" | tee -a "$LOG_FILE"
docker-compose down 2>&1 | tee -a "$LOG_FILE"

# 빌드 실행
if [ "$NEED_NOCACHE" = true ]; then
    echo -e "${RED}🔨 No-cache 빌드 실행 중...${NC}" | tee -a "$LOG_FILE"
    docker-compose build --no-cache 2>&1 | tee -a "$LOG_FILE"
elif [ "$NEED_REBUILD" = true ]; then
    echo -e "${BLUE}🔨 일반 빌드 실행 중...${NC}" | tee -a "$LOG_FILE"
    docker-compose build 2>&1 | tee -a "$LOG_FILE"
else
    echo -e "${GREEN}⏭️  빌드 스킵 (코드만 변경됨)${NC}" | tee -a "$LOG_FILE"
fi

# 컨테이너 시작
echo -e "${BLUE}▶️  컨테이너 시작 중...${NC}" | tee -a "$LOG_FILE"
docker-compose up -d 2>&1 | tee -a "$LOG_FILE"

# 컨테이너 상태 확인 (30초 대기)
echo -e "${YELLOW}⏳ 컨테이너 시작 대기 중 (30초)...${NC}" | tee -a "$LOG_FILE"
sleep 30

# 마이그레이션 실행
if [ "$NEED_MIGRATION" = true ]; then
    echo -e "${YELLOW}🗄️  마이그레이션 실행 중...${NC}" | tee -a "$LOG_FILE"
    docker-compose exec -T web bin/rails db:migrate 2>&1 | tee -a "$LOG_FILE"

    # 마이그레이션 상태 확인
    echo -e "${BLUE}📊 마이그레이션 상태:${NC}" | tee -a "$LOG_FILE"
    docker-compose exec -T web bin/rails db:migrate:status 2>&1 | tail -20 | tee -a "$LOG_FILE"
fi

# 배포 완료 확인
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}📋 컨테이너 상태:${NC}" | tee -a "$LOG_FILE"
docker-compose ps 2>&1 | tee -a "$LOG_FILE"

# 로그 확인 (마지막 20줄)
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}📜 애플리케이션 로그 (최근 20줄):${NC}" | tee -a "$LOG_FILE"
docker-compose logs --tail=20 web 2>&1 | tee -a "$LOG_FILE"

echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ 배포 완료: $(date)${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}=====================================${NC}" | tee -a "$LOG_FILE"
echo -e "${YELLOW}📁 로그 파일: $LOG_FILE${NC}" | tee -a "$LOG_FILE"

exit 0
