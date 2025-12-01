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

**이 폴더가 개발용인지 프로덕션 서버인지 확인하세요.**

- **Production Server**: Ubuntu + Docker + Cloudflare Tunnel
- **Development**: Windows
- **Workflow**:
  - 개발용: 로컬 수정 → `git push` → 서버에서 `git pull` & `docker-compose up -d --build`
  - 서버용: 직접 수정 후 `docker-compose up -d --build`

## 🤖 Claude Code 작업 규칙

**코드 작업 완료 시 자동으로 git commit & push 실행**
- 기능 구현, 버그 수정 등 코드 변경이 완료되면 자동으로 커밋하고 push
- 서버에서 변경사항을 pull 받아 배포할 수 있도록 함

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
bin/rails test                              # 전체 테스트
bin/rails test test/models/user_test.rb    # 단일 파일 테스트
bin/rails test test/models/user_test.rb:10 # 특정 라인 테스트
```

## Docker Commands (서버)

```bash
# 배포
docker-compose up -d --build

# ContainerConfig 오류 발생 시
docker ps -a | grep web | awk '{print $1}' | xargs -r docker rm -f
docker-compose up -d

# 로그 확인
docker logs -f production-management-system_web_1
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
7. **Batch Completion**: 반죽일지에서 모든 배치 완료 시 자동 `completed` 상태 변경
8. **Gijeongddeok (기정떡) Special Logic**: split_count/split_unit으로 배치 분할 계산
9. **Referenced Ingredient**: 재료 구성을 재귀적으로 펼쳐서 최종 Item으로 역산

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
config/routes.rb                              # 라우트 정의
app/services/ingredient_inventory_service.rb  # 재고 처리 핵심 로직 (FIFO, 개봉품, 출고)
app/controllers/production/logs_controller.rb # 반죽일지 (기정떡 배율 계산)
app/javascript/interactions.js                # 전역 JS 유틸리티
app/javascript/barcode_scanner.js             # 바코드 스캐너
app/assets/stylesheets/                       # SCSS 소스
```

## IngredientInventoryService 핵심 로직

```ruby
# 재료 체크 시 처리 흐름
1. source_type == "ingredient" → Referenced Ingredient로 처리 (재귀 역산)
2. source_type == "item" → 직접 품목으로 처리
3. FIFO로 입고품 선택 (유통기한 ASC, NULL은 마지막)
4. 개봉품 찾기/생성 → 새 개봉 시 출고(Shipment) 자동 생성
5. 개봉품에서 중량 차감 → CheckedIngredient 생성
6. 체크 해제 시 before_destroy 콜백에서 중량 복원
```

## 기정떡 배율 계산

```ruby
# split_unit = 0.5 (반통) or 1.0 (1통)
scaled_weight = recipe_ingredient.weight * split_unit
# 예: 레시피 44000g × 0.5 = 22000g (반통)
```

## 반죽일지 날짜 구분

- **dough_date**: 반죽일 (1차 반죽) - 소계 이전 재료
- **production_date**: 생산일 (2차 반죽) - 소계 이후 재료
- 목록 페이지에서 선택 날짜 기준으로 1차/2차 섹션 분리 표시
  - 🔵 1차 반죽: 반죽일 = 선택 날짜 (오늘 반죽 → 내일 생산)
  - 🟠 2차 반죽: 생산일 = 선택 날짜 (어제 반죽 → 오늘 생산)

---

**Version**: 2.4 | **Updated**: 2025-12-01
