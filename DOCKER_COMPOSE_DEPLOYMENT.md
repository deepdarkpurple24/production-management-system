# Docker Compose PostgreSQL 배포 가이드

현재 docker-compose + Cloudflare Tunnel 환경에서 PostgreSQL로 전환하는 가이드입니다.

---

## 📋 변경 사항

✅ **Dockerfile 수정**: PostgreSQL 클라이언트 라이브러리 추가 (libpq5, libpq-dev)
✅ **두 가지 docker-compose.yml 옵션** 제공

---

## 🎯 배포 옵션 선택

### 옵션 1: Supabase PostgreSQL ⭐ (추천)

**장점**:
- ✅ 관리 불필요 (자동 백업, 모니터링)
- ✅ 무료 티어 500MB
- ✅ 고가용성
- ✅ 서버 리소스 절약

**단점**:
- ⚠️ 외부 서비스 의존성
- ⚠️ 네트워크 지연 (약간)

**사용 파일**: `docker-compose.supabase.yml`

---

### 옵션 2: 자체 PostgreSQL 컨테이너

**장점**:
- ✅ 완전한 제어
- ✅ 데이터가 서버에 저장
- ✅ 네트워크 지연 없음

**단점**:
- ⚠️ 서버 리소스 사용 (메모리, CPU)
- ⚠️ 백업 직접 관리 필요
- ⚠️ PostgreSQL 관리 필요

**사용 파일**: `docker-compose.selfhosted.yml`

---

## 🚀 배포 절차

### A. Supabase 사용 (옵션 1)

#### 1️⃣ Supabase 비밀번호 확인

1. [Supabase 대시보드](https://supabase.com/dashboard) 로그인
2. 프로젝트 선택: `bwqnspwmsgonaurxqgie`
3. **Settings** → **Database** → **Connection string**
4. "Connection pooling" 아래 **Password** 확인

또는:

```bash
# Supabase CLI로 확인
supabase projects list
```

#### 2️⃣ docker-compose.yml 수정

**서버에서 실행**:

```bash
# 로컬에서 수정한 파일을 서버로 복사
cd ~/Programs/production-management-system

# 기존 파일 백업
cp docker-compose.yml docker-compose.yml.backup

# Supabase 버전 복사
cp docker-compose.supabase.yml docker-compose.yml

# POSTGRES_PASSWORD 수정 (nano 또는 vim 사용)
nano docker-compose.yml
# POSTGRES_PASSWORD=YOUR_SUPABASE_PASSWORD_HERE 부분을 실제 비밀번호로 변경
```

#### 3️⃣ Git 업데이트 및 재배포

```bash
# Git pull (로컬에서 푸시한 변경사항)
git pull

# 기존 컨테이너 중지 및 삭제
docker-compose down

# 새 이미지 빌드 (PostgreSQL 라이브러리 포함)
docker-compose build --no-cache

# 컨테이너 시작
docker-compose up -d

# 데이터베이스 생성 및 마이그레이션
docker-compose exec web bin/rails db:create
docker-compose exec web bin/rails db:migrate

# 로그 확인
docker-compose logs -f web
```

#### 4️⃣ Supabase에 추가 데이터베이스 생성

Supabase 기본 데이터베이스는 `postgres`입니다. 추가 데이터베이스를 생성해야 합니다:

```bash
# Supabase 대시보드 → SQL Editor에서 실행
CREATE DATABASE production_management_system_cache;
CREATE DATABASE production_management_system_queue;
CREATE DATABASE production_management_system_cable;
```

또는 Rails 콘솔에서:

```bash
docker-compose exec web bin/rails runner "
  ActiveRecord::Base.establish_connection(:cache).connection.execute('SELECT 1')
rescue ActiveRecord::NoDatabaseError
  ActiveRecord::Base.establish_connection(:cache).create_database('production_management_system_cache')
"
```

---

### B. 자체 PostgreSQL 컨테이너 (옵션 2)

#### 1️⃣ docker-compose.yml 수정

**서버에서 실행**:

```bash
cd ~/Programs/production-management-system

# 기존 파일 백업
cp docker-compose.yml docker-compose.yml.backup

# Self-hosted 버전 복사
cp docker-compose.selfhosted.yml docker-compose.yml

# 강력한 비밀번호 설정
nano docker-compose.yml
# your-secure-password-here 부분을 강력한 비밀번호로 변경 (2곳)
```

#### 2️⃣ Git 업데이트 및 재배포

```bash
# Git pull
git pull

# 기존 컨테이너 중지
docker-compose down

# 새 이미지 빌드
docker-compose build --no-cache

# PostgreSQL 포함 전체 스택 시작
docker-compose up -d

# PostgreSQL 준비 대기 (자동 healthcheck)
docker-compose logs -f db

# 데이터베이스 생성 및 마이그레이션
docker-compose exec web bin/rails db:create
docker-compose exec web bin/rails db:migrate

# 로그 확인
docker-compose logs -f web
```

#### 3️⃣ 추가 데이터베이스 생성

```bash
# PostgreSQL 컨테이너에 접속
docker-compose exec db psql -U postgres

# SQL 실행:
CREATE DATABASE production_management_system_cache;
CREATE DATABASE production_management_system_queue;
CREATE DATABASE production_management_system_cable;
\q

# 마이그레이션 실행
docker-compose exec web bin/rails db:migrate:cache
docker-compose exec web bin/rails db:migrate:queue
docker-compose exec web bin/rails db:migrate:cable
```

---

## 🔄 기존 SQLite 데이터 마이그레이션

### 방법 1: Rails 콘솔 스크립트 (추천)

```bash
# 1. SQLite 데이터 추출 (로컬에서)
RAILS_ENV=production bin/rails runner '
  models = [User, AuthorizedDevice, LoginHistory, Item, Receipt, Shipment,
            Recipe, RecipeIngredient, Ingredient, FinishedProduct,
            ProductionPlan, ProductionLog, Equipment]

  data = {}
  models.each do |model|
    data[model.name] = model.all.as_json
  end

  File.write("data_export.json", JSON.pretty_generate(data))
  puts "Exported #{data.values.sum(&:count)} records"
'

# 2. 서버로 파일 복사
scp data_export.json alche0124@alcheserver:~/Programs/production-management-system/

# 3. PostgreSQL에 데이터 임포트 (서버에서)
docker-compose exec -T web bin/rails runner '
  data = JSON.parse(File.read("data_export.json"))

  data.each do |model_name, records|
    model = model_name.constantize
    records.each do |attrs|
      model.create!(attrs.except("id"))
    end
    puts "Imported #{records.count} #{model_name} records"
  end
'
```

### 방법 2: YAML Fixtures

```bash
# 로컬에서
RAILS_ENV=production bin/rails db:fixtures:extract

# 서버로 복사
scp -r test/fixtures/* alche0124@alcheserver:~/Programs/production-management-system/test/fixtures/

# 서버에서
docker-compose exec web bin/rails db:fixtures:load
```

---

## ✅ 배포 후 확인

### 1. PostgreSQL 연결 확인

```bash
docker-compose exec web bin/rails runner '
  puts "Adapter: #{ActiveRecord::Base.connection.adapter_name}"
  puts "Database: #{ActiveRecord::Base.connection.current_database}"
  puts "User count: #{User.count}"
'
```

### 2. 웹 접속 확인

Cloudflare Tunnel을 통해 접속:
- 로그인 테스트
- 데이터 조회 테스트

### 3. 로그 확인

```bash
# 애플리케이션 로그
docker-compose logs -f web

# PostgreSQL 로그 (옵션 2만 해당)
docker-compose logs -f db
```

---

## 🛠️ 문제 해결

### "could not connect to server" 오류

**Supabase**:
```bash
# 네트워크 연결 테스트
docker-compose exec web ping -c 3 db.bwqnspwmsgonaurxqgie.supabase.co

# 비밀번호 확인
docker-compose exec web printenv POSTGRES_PASSWORD
```

**Self-hosted**:
```bash
# DB 컨테이너 상태 확인
docker-compose ps db

# DB 준비 상태 확인
docker-compose exec db pg_isready -U postgres
```

### "database does not exist" 오류

```bash
# 데이터베이스 생성
docker-compose exec web bin/rails db:create
```

### "PG::ConnectionBad" 오류

비밀번호나 호스트 설정 확인:
```bash
docker-compose exec web printenv | grep POSTGRES
docker-compose exec web printenv | grep DB_HOST
```

---

## 🔙 롤백 (SQLite로 복귀)

문제가 발생하면:

```bash
# 1. 백업한 docker-compose.yml 복원
cp docker-compose.yml.backup docker-compose.yml

# 2. 이전 Git 커밋으로 복원
git checkout HEAD~1 Dockerfile Gemfile Gemfile.lock config/database.yml

# 3. 재빌드 및 재시작
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## 📊 성능 모니터링

### PostgreSQL 성능 확인 (Self-hosted)

```bash
# 활성 연결 수
docker-compose exec db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# 데이터베이스 크기
docker-compose exec db psql -U postgres -c "\l+"

# 테이블 크기
docker-compose exec db psql -U postgres -d production_management_system_production -c "\dt+"
```

---

## 🔐 보안 권장사항

1. **비밀번호 관리**
   - 강력한 비밀번호 사용 (20자 이상, 대소문자+숫자+특수문자)
   - docker-compose.yml은 .gitignore에 추가 (민감정보 포함)

2. **정기 백업** (Self-hosted)
   ```bash
   # 백업 스크립트 (cron 등록 권장)
   docker-compose exec db pg_dump -U postgres production_management_system_production > backup_$(date +%Y%m%d).sql
   ```

3. **Supabase 보안**
   - Row Level Security (RLS) 설정
   - API 키 관리 철저히

---

## 📝 체크리스트

배포 전:
- [ ] Dockerfile 수정 완료 (libpq 추가)
- [ ] 배포 옵션 선택 (Supabase vs Self-hosted)
- [ ] docker-compose.yml 준비
- [ ] 비밀번호 설정 완료
- [ ] 기존 docker-compose.yml 백업

배포 중:
- [ ] Git pull 완료
- [ ] `docker-compose build --no-cache` 성공
- [ ] `docker-compose up -d` 성공
- [ ] `db:create` 성공
- [ ] `db:migrate` 성공

배포 후:
- [ ] PostgreSQL 연결 확인
- [ ] 웹 접속 확인
- [ ] 데이터 마이그레이션 완료 (필요시)
- [ ] 로그 정상
- [ ] 백업 설정 (Self-hosted)

---

**작성일**: 2025-11-26
**작성자**: Claude Code
