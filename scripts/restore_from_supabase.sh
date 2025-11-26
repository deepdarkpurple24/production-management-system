#!/bin/bash

# Supabase에서 로컬 PostgreSQL로 복원 스크립트
# 재해 발생 시 Supabase 백업에서 데이터 복원

set -e

# 설정
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESTORE_DIR="/tmp/pg_restore"
LOG_FILE="/var/log/pg_restore.log"

# Supabase 연결 정보
SUPABASE_HOST="${SUPABASE_HOST:-db.bwqnspwmsgonaurxqgie.supabase.co}"
SUPABASE_USER="${SUPABASE_USER:-postgres}"
SUPABASE_PASSWORD="${SUPABASE_PASSWORD}"
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

# 경고 표시
echo "========================================="
echo "⚠️  경고: 로컬 PostgreSQL 데이터 복원 ⚠️"
echo "========================================="
echo "이 작업은 현재 로컬 데이터베이스를 Supabase 백업으로 덮어씁니다."
echo ""
read -p "정말 진행하시겠습니까? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "복원 취소됨"
  exit 0
fi

mkdir -p "$RESTORE_DIR"

log "========================================="
log "Supabase에서 로컬 PostgreSQL로 복원 시작"
log "========================================="

# 각 데이터베이스 복원
for DB in "${DATABASES[@]}"; do
  log "복원 중: $DB"

  DUMP_FILE="$RESTORE_DIR/${DB}_${TIMESTAMP}.sql"

  # 1. Supabase에서 덤프 생성
  log "  1/3: Supabase에서 덤프 생성..."
  PGPASSWORD="$SUPABASE_PASSWORD" pg_dump \
    -h "$SUPABASE_HOST" \
    -U "$SUPABASE_USER" \
    -p "$SUPABASE_PORT" \
    -d "$DB" \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    > "$DUMP_FILE" 2>> "$LOG_FILE"

  if [ $? -eq 0 ]; then
    log "  ✓ Supabase 덤프 생성 완료"
  else
    log "  ✗ Supabase 덤프 실패: $DB"
    continue
  fi

  # 2. 로컬 데이터베이스 드롭 및 재생성
  log "  2/3: 로컬 데이터베이스 재생성..."
  docker-compose exec -T db psql -U postgres -c "DROP DATABASE IF EXISTS \"$DB\"" 2>> "$LOG_FILE"
  docker-compose exec -T db psql -U postgres -c "CREATE DATABASE \"$DB\"" 2>> "$LOG_FILE"

  # 3. 로컬 PostgreSQL로 복원
  log "  3/3: 로컬 PostgreSQL로 복원..."
  docker-compose exec -T db psql -U postgres -d "$DB" < "$DUMP_FILE" 2>> "$LOG_FILE"

  if [ $? -eq 0 ]; then
    log "  ✓ 복원 완료: $DB"
  else
    log "  ✗ 복원 실패: $DB (로그 확인: $LOG_FILE)"
  fi
done

log "========================================="
log "복원 완료!"
log "========================================="
log "애플리케이션을 재시작하세요: docker-compose restart web"

exit 0
