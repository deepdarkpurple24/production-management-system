# Development Commands

## 빠른 시작
```bash
bin/setup          # 전체 설정 (의존성, DB, CSS, 서버 시작)
bin/dev            # 개발 서버 시작 (Rails + CSS watch)
```

## 일상 개발
```bash
# 서버
bin/rails server              # Rails 서버만 (port 3000)
yarn watch:css                # CSS 변경 감시

# CSS
yarn build:css                # CSS 빌드 (커밋 전 필수)

# 데이터베이스
bin/rails db:migrate          # 마이그레이션 실행
bin/rails db:rollback         # 마지막 마이그레이션 롤백
bin/rails db:migrate:status   # 마이그레이션 상태 확인

# 콘솔
bin/rails console             # Rails 콘솔
```

## 테스트
```bash
bin/rails test                # 전체 테스트
bin/rails test test/models    # 모델 테스트만
bin/rails test:system         # 시스템 테스트 (브라우저)
```

## 코드 품질
```bash
bin/rubocop                   # Ruby 스타일 검사
bin/brakeman                  # 보안 취약점 스캔
bin/bundler-audit             # 의존성 보안 검사
```

## Git Pull 후 동기화
```bash
# 자동 (Git hook 설치 시)
bin/install-hooks             # 한 번만 실행
git pull                      # 이후 자동 동기화

# 수동
bin/rails db:migrate          # 마이그레이션 확인
yarn build:css                # CSS 재빌드
```

## 인증 관리 (콘솔)
```ruby
User.first                                    # 첫 번째 사용자 확인
user = User.find_by(email: 'user@example.com')
user.update(admin: true)                      # 관리자 권한 부여
user.authorized_devices                       # 승인된 디바이스 목록
user.authorize_device(fingerprint, info)      # 디바이스 승인
user.revoke_device(fingerprint)               # 디바이스 해제
LoginHistory.recent.limit(10)                 # 최근 로그인 시도
```
