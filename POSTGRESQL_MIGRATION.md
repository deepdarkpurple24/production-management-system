# PostgreSQL 마이그레이션 가이드

SQLite에서 PostgreSQL로의 프로덕션 데이터베이스 전환 가이드입니다.

## 📋 변경 사항 요약

### 완료된 코드 변경
✅ **Gemfile**: `pg` gem 추가, `sqlite3`를 development/test 그룹으로 이동
✅ **database.yml**: Production 환경을 PostgreSQL로 설정
✅ **deploy.yml**: PostgreSQL accessory 서비스 추가
✅ **.kamal/secrets**: POSTGRES_PASSWORD 환경 변수 추가

### 환경별 데이터베이스
- **Development/Test**: SQLite (빠르고 간편한 로컬 개발)
- **Production**: PostgreSQL (고성능, 동시성 처리)

---

## 🚀 배포 단계별 가이드

### 1단계: 로컬 환경 설정

```bash
# 1. PostgreSQL gem 설치
bundle install

# 2. 로컬 테스트 (여전히 SQLite 사용)
bin/rails test

# 3. Git 커밋
git add .
git commit -m "feat: PostgreSQL 프로덕션 데이터베이스 전환"
git push
```

### 2단계: 우분투 서버 준비

서버(192.168.0.1)에 SSH 접속 후:

```bash
# Docker 설치 확인
docker --version

# Docker가 없으면 설치
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 docker 사용)
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인하여 적용
```

### 3단계: PostgreSQL 비밀번호 설정

**로컬 개발 환경**에서 배포 전:

```bash
# 강력한 비밀번호 생성 (예시)
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"

# 또는 직접 설정
export POSTGRES_PASSWORD="your-secure-password-here"

# 비밀번호 확인
echo $POSTGRES_PASSWORD

# ⚠️ 이 비밀번호를 안전한 곳에 저장하세요!
```

### 4단계: Kamal을 통한 PostgreSQL 배포

```bash
# PostgreSQL 컨테이너 배포
bin/kamal accessory boot db

# 상태 확인
bin/kamal accessory details db

# 로그 확인
bin/kamal accessory logs db
```

### 5단계: 데이터베이스 생성 및 마이그레이션

```bash
# 애플리케이션 배포 (데이터베이스 마이그레이션 포함)
bin/kamal deploy

# 또는 수동으로 데이터베이스 설정
bin/kamal app exec -i "bin/rails db:create"
bin/kamal app exec -i "bin/rails db:migrate"
```

---

## 🔄 기존 SQLite 데이터 마이그레이션

기존 SQLite 데이터를 PostgreSQL로 옮기려면:

### 옵션 1: YAML 덤프 방식 (간단, 작은 데이터셋)

```bash
# 1. 로컬에서 SQLite 데이터를 YAML로 추출
RAILS_ENV=production bin/rails db:fixtures:extract

# 2. 서버에서 PostgreSQL에 로드
bin/kamal app exec -i "bin/rails db:fixtures:load"
```

### 옵션 2: pgloader 사용 (복잡, 큰 데이터셋)

**서버에서 실행:**

```bash
# 1. pgloader 설치
sudo apt install -y pgloader

# 2. SQLite 파일을 서버로 복사
scp storage/production.sqlite3 user@192.168.0.1:/tmp/

# 3. pgloader 설정 파일 생성
cat > /tmp/migrate.load <<EOF
LOAD DATABASE
  FROM sqlite:///tmp/production.sqlite3
  INTO postgresql://postgres:${POSTGRES_PASSWORD}@localhost/production_management_system_production

  WITH include drop, create tables, create indexes, reset sequences

  SET work_mem to '16MB', maintenance_work_mem to '512 MB';
EOF

# 4. 마이그레이션 실행
pgloader /tmp/migrate.load
```

### 옵션 3: 커스텀 Ruby 스크립트 (추천)

```ruby
# lib/tasks/migrate_to_postgresql.rake
namespace :db do
  desc "Migrate data from SQLite to PostgreSQL"
  task migrate_to_postgres: :environment do
    # 각 모델의 데이터를 복사
    models = [User, Item, Receipt, Shipment, Recipe, FinishedProduct, ProductionPlan, ProductionLog]

    models.each do |model|
      puts "Migrating #{model.name}..."
      model.find_each do |record|
        record.save!
      end
      puts "✓ #{model.count} records migrated"
    end
  end
end
```

실행:
```bash
bin/kamal app exec -i "bin/rails db:migrate_to_postgres"
```

---

## 🔍 배포 후 확인사항

### 1. PostgreSQL 연결 확인

```bash
# Rails 콘솔 접속
bin/kamal app exec -i "bin/rails console"

# 콘솔에서 실행:
ActiveRecord::Base.connection.adapter_name
# => "PostgreSQL" 이어야 함

User.count
# => 데이터가 정상적으로 조회되어야 함
```

### 2. 데이터베이스 목록 확인

```bash
# PostgreSQL 컨테이너에 직접 접속
docker exec -it production_management_system-db psql -U postgres

# psql 프롬프트에서:
\l                                                    # 데이터베이스 목록
\c production_management_system_production            # 데이터베이스 연결
\dt                                                   # 테이블 목록
\q                                                    # 종료
```

### 3. 애플리케이션 동작 확인

브라우저에서 애플리케이션 접속하여:
- ✅ 로그인 가능
- ✅ 품목 조회/추가
- ✅ 레시피 조회/수정
- ✅ 생산 계획 생성

---

## 🛠️ 문제 해결

### PostgreSQL 컨테이너가 시작되지 않음

```bash
# 로그 확인
bin/kamal accessory logs db --lines 100

# 컨테이너 재시작
bin/kamal accessory reboot db
```

### 데이터베이스 연결 오류

```bash
# 환경 변수 확인
bin/kamal app exec "env | grep POSTGRES"

# 비밀번호가 설정되지 않았으면:
export POSTGRES_PASSWORD="your-password"
bin/kamal redeploy
```

### 마이그레이션 실패

```bash
# 데이터베이스 삭제 후 재생성
bin/kamal app exec -i "bin/rails db:drop db:create db:migrate"
```

### 포트 충돌 (5432 already in use)

```bash
# 우분투에 PostgreSQL이 이미 설치되어 있는 경우
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 또는 deploy.yml에서 다른 포트 사용:
# port: "127.0.0.1:5433:5432"
```

---

## 📊 성능 비교

### SQLite
- ✅ 간단한 설정
- ✅ 파일 기반, 백업 용이
- ❌ 동시 쓰기 제한 (잠금 발생)
- ❌ 대용량 데이터 처리 느림
- ❌ 프로덕션 권장 안 함

### PostgreSQL
- ✅ 동시성 우수 (MVCC)
- ✅ 대용량 데이터 처리
- ✅ 고급 기능 (트랜잭션, 인덱스, 파티셔닝)
- ✅ 프로덕션 환경 표준
- ⚠️ 설정 복잡도 증가
- ⚠️ 별도 서버 필요

---

## 🔐 보안 권장사항

1. **비밀번호 관리**
   ```bash
   # 비밀번호를 환경 변수로 관리하거나
   export POSTGRES_PASSWORD="..."

   # 1Password 등 비밀번호 관리자 사용
   # kamal secrets fetch --adapter 1password ...
   ```

2. **네트워크 보안**
   - PostgreSQL은 127.0.0.1(로컬)에서만 접근 가능하도록 설정됨
   - 외부 접근이 필요하면 방화벽 규칙 추가

3. **정기 백업**
   ```bash
   # PostgreSQL 백업
   docker exec production_management_system-db \
     pg_dump -U postgres production_management_system_production > backup.sql

   # 복원
   docker exec -i production_management_system-db \
     psql -U postgres production_management_system_production < backup.sql
   ```

---

## 📝 롤백 (SQLite로 복귀)

만약 PostgreSQL 전환이 문제가 있다면:

```bash
# 1. Git에서 이전 버전으로 복원
git revert HEAD
git push

# 2. SQLite로 재배포
bin/kamal deploy
```

---

## ✅ 체크리스트

배포 전:
- [ ] `bundle install` 완료
- [ ] 로컬 테스트 통과
- [ ] Git 커밋 및 푸시
- [ ] `POSTGRES_PASSWORD` 환경 변수 설정

배포 중:
- [ ] `bin/kamal accessory boot db` 성공
- [ ] PostgreSQL 컨테이너 실행 중
- [ ] `bin/kamal deploy` 성공
- [ ] 데이터베이스 마이그레이션 완료

배포 후:
- [ ] PostgreSQL 연결 확인
- [ ] 애플리케이션 정상 동작
- [ ] 데이터 마이그레이션 완료 (해당되는 경우)
- [ ] 백업 설정

---

## 📚 참고 자료

- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [Kamal 배포 가이드](https://kamal-deploy.org)
- [Rails 다중 데이터베이스](https://guides.rubyonrails.org/active_record_multiple_databases.html)

---

**작성일**: 2025-11-26
**작성자**: Claude Code
