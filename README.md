# Production Management System

제빵/제과 생산관리 시스템

## Quick Start

### 첫 설정 (한 번만)
```bash
# 1. Clone repository
git clone <repository-url>
cd production-management-system

# 2. 자동 설정 실행 (모든 설정이 한 번에!)
bin/setup
```

**bin/setup이 자동으로 처리:**
- ✅ Ruby/Node 의존성 설치
- ✅ 데이터베이스 생성 및 마이그레이션
- ✅ CSS 빌드
- ✅ Git hooks 설치 (git pull 자동 동기화)
- ✅ 개발 서버 시작

### 이후 작업 (완전 자동!)
```bash
git pull  # ← 자동으로 마이그레이션, 의존성, CSS 빌드!
bin/dev   # ← 서버 재시작만!
```

**git pull이 자동으로 처리:**
- ✅ 대기 중인 마이그레이션 확인 및 실행
- ✅ Gemfile/package.json 변경 시 의존성 업데이트
- ✅ SCSS 파일 변경 시 CSS 재빌드
- ✅ 환경 상태 요약 및 서버 재시작 안내

---

### 수동 명령어 (필요시)
```bash
bin/rails db:migrate    # 마이그레이션만
yarn build:css          # CSS 빌드만
bin/setup-after-pull    # git pull 후 동기화만
```

상세한 문서는 [CLAUDE.md](CLAUDE.md)를 참고하세요.