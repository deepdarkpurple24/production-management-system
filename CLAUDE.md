# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Production Management System** - 제조/생산 관리 시스템 (제빵/제과)

| 항목 | 내용 |
|------|------|
| Framework | Ruby on Rails 8.1.1 / Ruby 3.4.7 |
| Database | PostgreSQL 17 (prod), SQLite3 (dev) |
| Frontend | Bootstrap 5 + Hotwire + Import Maps |
| Language | Korean (한국어) |

## ⚠️ Deployment (중요)

**이 폴더는 개발용입니다. 프로덕션 서버는 별도의 Ubuntu 컴퓨터입니다.**

- **Production**: Ubuntu + Docker + Cloudflare Tunnel
- **Development**: Windows (현재 PC)
- **Workflow**: 로컬 수정 → `git push` → 서버에서 `git pull` & `docker-compose up -d --build`

## Quick Commands

```bash
# 개발 시작
bin/dev                       # 서버 + CSS watch

# CSS 빌드 (커밋 전 필수)
yarn build:css

# 데이터베이스
bin/rails db:migrate
bin/rails console

# 테스트
bin/rails test
```

## Documentation Index

상세 문서는 `docs/claude/` 폴더에 있습니다:

| 파일 | 내용 |
|------|------|
| [01-deployment.md](docs/claude/01-deployment.md) | 배포 환경, 서버 명령어, 백업 |
| [02-commands.md](docs/claude/02-commands.md) | 개발 명령어, 테스트, 인증 관리 |
| [03-architecture.md](docs/claude/03-architecture.md) | 기술 스택, 디렉토리 구조, 라우트 |
| [04-domain-models.md](docs/claude/04-domain-models.md) | 도메인 모델 (재고, 레시피, 생산 등) |
| [05-patterns.md](docs/claude/05-patterns.md) | 중요 패턴 (버전 추적, FIFO, 인증 등) |
| [06-security.md](docs/claude/06-security.md) | 보안 기능, Rate Limiting |

## Key Patterns (요약)

1. **Recipe Version Tracking**: 레시피 수정 시 자동 JSON 스냅샷
2. **FIFO Inventory**: 유통기한 순서로 재고 차감 (`IngredientInventoryService`)
3. **Device Authentication**: 브라우저 fingerprint 기반 디바이스 승인
4. **Position Ordering**: drag & drop용 `position` 컬럼
5. **Nested Attributes**: `accepts_nested_attributes_for`로 복합 폼 처리
6. **Unit Conversion**: 모든 중량을 g으로 변환하여 계산

## Common Paths

```
/                       # 대시보드
/inventory/items        # 품목 관리
/inventory/receipts     # 입고
/inventory/shipments    # 출고
/recipes                # 레시피
/production/plans       # 생산 계획
/production/logs        # 반죽일지
/settings               # 설정
/admin/users            # 사용자 관리 (admin)
```

## Important Files

```
config/routes.rb                    # 라우트 정의
app/services/                       # 비즈니스 로직
app/javascript/interactions.js      # 전역 JS 유틸리티
app/javascript/barcode_scanner.js   # 바코드 스캐너
app/assets/stylesheets/             # SCSS 소스
```

---

**Version**: 2.0 | **Updated**: 2025-11-28
