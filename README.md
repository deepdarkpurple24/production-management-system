# Production Management System

제빵/제과 생산관리 시스템

## Quick Start

### Initial Setup
```bash
# 1. Clone repository
git clone <repository-url>
cd production-management-system

# 2. Install dependencies
bundle install
yarn install

# 3. Setup database
bin/rails db:create db:migrate db:seed

# 4. Install Git hooks (recommended for auto-sync)
bin/install-hooks

# 5. Start development server
bin/dev
```

### After Git Pull
Git hooks가 설치되어 있으면 자동으로 환경 동기화가 실행됩니다:
```bash
git pull  # 자동으로 마이그레이션, 의존성, CSS 빌드 처리
bin/dev   # 서버 재시작만 하면 됨
```

상세한 문서는 [CLAUDE.md](CLAUDE.md)를 참고하세요.