#!/bin/bash

# PostgreSQL to Supabase 백업 스크립트 (단순 버전)
# 로컬 PostgreSQL의 production 데이터베이스를 Supabase의 기본 postgres DB로 백업

set -e

# 설정
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/pg_backup"
LOG_FILE="/var/log/pg_backup.log"

# Supabase 연결 정보
SUPABASE_HOST="${SUPABASE_HOST:-db.bwqnspwmsgonaurxqgie.supabase.co}"
SUPABASE_USER="${SUPABASE_USER:-postgres}"
SUPABASE_PASSWORD="${SUPABASE_PASSWORD}"
SUPABASE_PORT="${SUPABASE_PORT:-5432}"

# 로컬 데이터베이스
LOCAL_DB="production_management_system_production"

# 로그 함수
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

log "========================================="
log "PostgreSQL to Supabase 백업 시작 (Simple Mode)"
log "========================================="

DUMP_FILE="$BACKUP_DIR/${LOCAL_DB}_${TIMESTAMP}.sql"

# 1. 로컬 PostgreSQL에서 덤프 생성
log "1/2: 로컬 PostgreSQL 덤프 생성..."
docker-compose exec -T db pg_dump -U postgres -d "$LOCAL_DB" \
  --no-owner \
  --no-privileges \
  > "$DUMP_FILE" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
  log "  ✓ 덤프 생성 완료: $DUMP_FILE"
else
  log "  ✗ 덤프 생성 실패"
  exit 1
fi

# 2. Supabase의 기본 postgres DB로 복원
log "2/2: Supabase postgres 데이터베이스로 복원 중..."
PGPASSWORD="$SUPABASE_PASSWORD" psql \
  -h "$SUPABASE_HOST" \
  -U "$SUPABASE_USER" \
  -p "$SUPABASE_PORT" \
  -d postgres \
  < "$DUMP_FILE" \
  2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
  log "  ✓ 복원 완료: postgres database"
else
  log "  ✗ 복원 실패 (로그 확인: $LOG_FILE)"
  exit 1
fi

# 덤프 파일 압축
gzip "$DUMP_FILE"
log "✓ 덤프 파일 압축: ${DUMP_FILE}.gz"

# 오래된 백업 파일 삭제 (7일 이상)
log "오래된 백업 파일 정리 중..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
log "✓ 7일 이상 된 백업 파일 삭제 완료"

log "========================================="
log "백업 완료!"
log "========================================="

# 백업 요약
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "총 백업 크기: $TOTAL_SIZE"
log "백업 위치: $BACKUP_DIR"
log "로그 파일: $LOG_FILE"

exit 0
