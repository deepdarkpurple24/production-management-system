#!/bin/bash

# PostgreSQL to Supabase 백업 스크립트
# 로컬 PostgreSQL의 모든 데이터베이스를 Supabase로 백업합니다.

set -e  # 오류 발생 시 스크립트 중단

# 설정
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/pg_backup"
LOG_FILE="/var/log/pg_backup.log"

# Supabase 연결 정보 (환경 변수로 설정하거나 여기에 직접 입력)
SUPABASE_HOST="${SUPABASE_HOST:-db.bwqnspwmsgonaurxqgie.supabase.co}"
SUPABASE_USER="${SUPABASE_USER:-postgres}"
SUPABASE_PASSWORD="${SUPABASE_PASSWORD}"  # 환경 변수로 설정 필수!
SUPABASE_PORT="${SUPABASE_PORT:-5432}"

# 데이터베이스 목록
DATABASES=(
  "production_management_system_production"
  "production_management_system_cache"
  "production_management_system_queue"
  "production_management_system_cable"
)

# 로그 함수
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

log "========================================="
log "PostgreSQL to Supabase 백업 시작"
log "========================================="

# 각 데이터베이스 백업
for DB in "${DATABASES[@]}"; do
  log "백업 중: $DB"

  DUMP_FILE="$BACKUP_DIR/${DB}_${TIMESTAMP}.sql"

  # 1. 로컬 PostgreSQL에서 덤프 생성
  log "  1/3: 로컬 PostgreSQL 덤프 생성..."
  docker-compose exec -T db pg_dump -U postgres -d "$DB" \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    > "$DUMP_FILE" 2>> "$LOG_FILE"

  if [ $? -eq 0 ]; then
    log "  ✓ 덤프 생성 완료: $DUMP_FILE"
  else
    log "  ✗ 덤프 생성 실패: $DB"
    continue
  fi

  # 2. Supabase에 데이터베이스 존재 확인 및 생성
  log "  2/3: Supabase 데이터베이스 확인..."
  PGPASSWORD="$SUPABASE_PASSWORD" psql \
    -h "$SUPABASE_HOST" \
    -U "$SUPABASE_USER" \
    -p "$SUPABASE_PORT" \
    -d postgres \
    -tc "SELECT 1 FROM pg_database WHERE datname = '$DB'" \
    | grep -q 1 || \
  PGPASSWORD="$SUPABASE_PASSWORD" psql \
    -h "$SUPABASE_HOST" \
    -U "$SUPABASE_USER" \
    -p "$SUPABASE_PORT" \
    -d postgres \
    -c "CREATE DATABASE \"$DB\"" \
    2>> "$LOG_FILE"

  # 3. Supabase로 복원
  log "  3/3: Supabase로 복원 중..."
  PGPASSWORD="$SUPABASE_PASSWORD" psql \
    -h "$SUPABASE_HOST" \
    -U "$SUPABASE_USER" \
    -p "$SUPABASE_PORT" \
    -d "$DB" \
    < "$DUMP_FILE" \
    2>> "$LOG_FILE"

  if [ $? -eq 0 ]; then
    log "  ✓ 복원 완료: $DB"
  else
    log "  ✗ 복원 실패: $DB (로그 확인: $LOG_FILE)"
  fi

  # 덤프 파일 압축 (선택사항)
  gzip "$DUMP_FILE"
  log "  ✓ 덤프 파일 압축: ${DUMP_FILE}.gz"
done

# 오래된 백업 파일 삭제 (7일 이상)
log "오래된 백업 파일 정리 중..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
log "✓ 7일 이상 된 백업 파일 삭제 완료"

log "========================================="
log "백업 완료!"
log "========================================="

# 백업 요약 출력
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "총 백업 크기: $TOTAL_SIZE"
log "백업 위치: $BACKUP_DIR"
log "로그 파일: $LOG_FILE"

exit 0
