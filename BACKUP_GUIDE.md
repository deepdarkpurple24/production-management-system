# PostgreSQL + Supabase 백업 가이드

자체 PostgreSQL을 메인으로 사용하고, Supabase를 백업으로 활용하는 가이드입니다.

---

## 🎯 백업 전략

**Primary Database**: 로컬 PostgreSQL 컨테이너 (빠른 성능)
**Backup Database**: Supabase PostgreSQL (재해 복구)

**백업 주기**: 매일 자동 (cron)
**보관 기간**: 7일

---

## 📋 사전 준비

### 1. Supabase 비밀번호 확인

1. [Supabase 대시보드](https://supabase.com/dashboard) 로그인
2. 프로젝트 선택: `bwqnspwmsgonaurxqgie`
3. **Settings** → **Database** → **Connection string**
4. Password 확인 및 저장

### 2. PostgreSQL 클라이언트 설치 (서버)

백업 스크립트는 `psql`과 `pg_dump`를 사용합니다.

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y postgresql-client

# 설치 확인
psql --version
pg_dump --version
```

---

## 🚀 백업 시스템 설정

### 1단계: 스크립트 복사 및 권한 설정

**서버에서 실행**:

```bash
cd ~/Programs/production-management-system

# Git pull로 최신 스크립트 받기
git pull

# 실행 권한 부여
chmod +x scripts/backup_to_supabase.sh
chmod +x scripts/restore_from_supabase.sh

# 로그 디렉토리 생성
sudo mkdir -p /var/log
sudo chown $USER:$USER /var/log/pg_backup.log
sudo chown $USER:$USER /var/log/pg_restore.log
```

### 2단계: 환경 변수 설정

Supabase 비밀번호를 환경 변수로 설정:

```bash
# ~/.bashrc에 추가
nano ~/.bashrc

# 파일 끝에 추가:
export SUPABASE_PASSWORD="your-supabase-password-here"

# 적용
source ~/.bashrc

# 확인
echo $SUPABASE_PASSWORD
```

**보안 강화** (선택사항):

```bash
# 별도 환경 파일 생성
nano ~/Programs/production-management-system/.env.backup

# 내용:
SUPABASE_HOST=db.bwqnspwmsgonaurxqgie.supabase.co
SUPABASE_USER=postgres
SUPABASE_PASSWORD=your-supabase-password-here
SUPABASE_PORT=5432

# 권한 설정
chmod 600 ~/Programs/production-management-system/.env.backup

# 스크립트에서 사용:
# source ~/Programs/production-management-system/.env.backup 추가
```

### 3단계: 수동 백업 테스트

```bash
cd ~/Programs/production-management-system

# 백업 실행
./scripts/backup_to_supabase.sh

# 로그 확인
cat /var/log/pg_backup.log

# 백업 파일 확인
ls -lh /tmp/pg_backup/
```

**예상 출력**:
```
[2025-11-26 12:00:00] =========================================
[2025-11-26 12:00:00] PostgreSQL to Supabase 백업 시작
[2025-11-26 12:00:00] =========================================
[2025-11-26 12:00:01] 백업 중: production_management_system_production
[2025-11-26 12:00:01]   1/3: 로컬 PostgreSQL 덤프 생성...
[2025-11-26 12:00:02]   ✓ 덤프 생성 완료
[2025-11-26 12:00:02]   2/3: Supabase 데이터베이스 확인...
[2025-11-26 12:00:03]   3/3: Supabase로 복원 중...
[2025-11-26 12:00:05]   ✓ 복원 완료
...
```

### 4단계: Supabase 백업 확인

```bash
# Supabase에 접속해서 데이터 확인
PGPASSWORD="$SUPABASE_PASSWORD" psql \
  -h db.bwqnspwmsgonaurxqgie.supabase.co \
  -U postgres \
  -p 5432 \
  -d production_management_system_production

# psql 프롬프트에서:
\dt                           # 테이블 목록
SELECT count(*) FROM users;   # 데이터 확인
\q                            # 종료
```

---

## ⏰ 자동 백업 설정 (Cron)

### 매일 새벽 3시 자동 백업

```bash
# Cron 편집
crontab -e

# 다음 라인 추가:
0 3 * * * cd ~/Programs/production-management-system && ./scripts/backup_to_supabase.sh >> /var/log/pg_backup.log 2>&1

# Cron 확인
crontab -l
```

**Cron 설명**:
- `0 3 * * *`: 매일 오전 3시
- `cd ~/Programs/...`: 프로젝트 디렉토리로 이동
- `./scripts/backup_to_supabase.sh`: 백업 스크립트 실행
- `>> /var/log/pg_backup.log 2>&1`: 로그 기록

**다른 백업 주기 예시**:
```bash
# 매 6시간마다
0 */6 * * * cd ~/Programs/production-management-system && ./scripts/backup_to_supabase.sh

# 매주 일요일 새벽 2시
0 2 * * 0 cd ~/Programs/production-management-system && ./scripts/backup_to_supabase.sh

# 매시간
0 * * * * cd ~/Programs/production-management-system && ./scripts/backup_to_supabase.sh
```

---

## 🔄 복원 (재해 복구)

### 언제 복원이 필요한가?

- 서버 고장으로 데이터 손실
- 실수로 데이터 삭제
- Docker 볼륨 손상
- 새 서버로 마이그레이션

### 복원 절차

```bash
cd ~/Programs/production-management-system

# 1. 애플리케이션 중지
docker-compose down

# 2. Supabase에서 복원
./scripts/restore_from_supabase.sh

# 확인 메시지:
# ⚠️  경고: 로컬 PostgreSQL 데이터 복원 ⚠️
# 정말 진행하시겠습니까? (yes/no): yes

# 3. 애플리케이션 재시작
docker-compose up -d

# 4. 데이터 확인
docker-compose exec web bin/rails runner "puts User.count"
```

---

## 📊 백업 모니터링

### 백업 상태 확인

```bash
# 최근 백업 로그 확인
tail -50 /var/log/pg_backup.log

# 백업 파일 목록
ls -lh /tmp/pg_backup/

# 백업 크기 확인
du -sh /tmp/pg_backup/

# Cron 실행 여부 확인
grep CRON /var/log/syslog | grep backup_to_supabase
```

### 백업 알림 설정 (선택사항)

백업 실패 시 이메일 알림:

```bash
# Cron에서 MAILTO 설정
crontab -e

# 상단에 추가:
MAILTO=your-email@example.com

# 백업 실패 시 이메일 수신
```

또는 Slack 알림:

```bash
# backup_to_supabase.sh 끝에 추가
if [ $? -eq 0 ]; then
  curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"✅ PostgreSQL 백업 성공"}' \
    YOUR_SLACK_WEBHOOK_URL
else
  curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"❌ PostgreSQL 백업 실패!"}' \
    YOUR_SLACK_WEBHOOK_URL
fi
```

---

## 🔐 보안 권장사항

### 1. 백업 파일 암호화

```bash
# GPG로 백업 파일 암호화
gpg --symmetric --cipher-algo AES256 /tmp/pg_backup/backup.sql

# 복호화
gpg --decrypt backup.sql.gpg > backup.sql
```

### 2. 환경 변수 보안

```bash
# .env.backup 파일 권한 확인
ls -l ~/Programs/production-management-system/.env.backup
# -rw------- (600) 이어야 함

# Git에 제외
echo ".env.backup" >> .gitignore
```

### 3. Supabase 접근 제한

Supabase 대시보드에서:
1. **Settings** → **Database** → **Connection pooling**
2. **Allowed IP addresses** 설정 (서버 IP만 허용)

---

## 🛠️ 문제 해결

### "psql: command not found"

```bash
sudo apt install -y postgresql-client
```

### "FATAL: password authentication failed"

```bash
# Supabase 비밀번호 확인
echo $SUPABASE_PASSWORD

# 환경 변수 재설정
export SUPABASE_PASSWORD="correct-password"
source ~/.bashrc
```

### "could not connect to server"

```bash
# 네트워크 연결 테스트
ping -c 3 db.bwqnspwmsgonaurxqgie.supabase.co

# 포트 확인
nc -zv db.bwqnspwmsgonaurxqgie.supabase.co 5432
```

### "permission denied"

```bash
# 스크립트 권한 확인
ls -l scripts/backup_to_supabase.sh

# 권한 부여
chmod +x scripts/backup_to_supabase.sh
```

### 백업이 Cron에서 실행되지 않음

```bash
# Cron 로그 확인
grep CRON /var/log/syslog | tail -20

# 수동 실행으로 테스트
cd ~/Programs/production-management-system && ./scripts/backup_to_supabase.sh

# 경로 문제인 경우, Cron에서 절대 경로 사용:
0 3 * * * /home/alche0124/Programs/production-management-system/scripts/backup_to_supabase.sh
```

---

## 📈 백업 최적화

### 증분 백업 (선택사항)

완전 백업 대신 증분 백업으로 시간 절약:

```bash
# WAL (Write-Ahead Logging) 아카이빙 설정
# docker-compose.yml의 db 서비스에 추가:
command: postgres -c wal_level=replica -c archive_mode=on -c archive_command='cp %p /backup/wal/%f'
```

### 압축 최적화

```bash
# 더 나은 압축률
gzip -9 backup.sql  # 최대 압축

# 더 빠른 압축
pigz backup.sql     # 병렬 gzip (멀티코어 활용)
```

### 백업 용량 관리

```bash
# 오래된 백업 자동 삭제 (스크립트에 이미 포함됨)
find /tmp/pg_backup -name "*.sql.gz" -mtime +7 -delete

# 보관 기간 변경 (14일)
find /tmp/pg_backup -name "*.sql.gz" -mtime +14 -delete
```

---

## ✅ 체크리스트

설정 완료:
- [ ] PostgreSQL 클라이언트 설치
- [ ] Supabase 비밀번호 확인
- [ ] 환경 변수 설정
- [ ] 스크립트 권한 부여
- [ ] 수동 백업 테스트 성공
- [ ] Supabase에서 백업 확인
- [ ] Cron 자동 백업 설정
- [ ] 복원 스크립트 테스트

정기 점검:
- [ ] 주간: 백업 로그 확인
- [ ] 월간: 백업 파일 크기 확인
- [ ] 분기: 복원 테스트 수행

---

## 📚 참고 자료

- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/current/backup.html)
- [Supabase Database Backups](https://supabase.com/docs/guides/platform/backups)
- [Cron 가이드](https://crontab.guru/)

---

**작성일**: 2025-11-26
**작성자**: Claude Code
