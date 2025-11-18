# 개발 로그

## 2025-11-18 (월) - 품목 카테고리 및 보관위치 관리 기능 추가

### 작업 내역

#### 1. 품목 카테고리 관리 시스템 (Item Category Management)

**목적**: 품목을 체계적으로 분류하여 관리 효율성 향상

**구현 내용**:
- `ItemCategory` 모델 생성
  - 카테고리명, 위치 기반 정렬 (position) 지원
  - uniqueness validation으로 중복 방지
  - default_scope로 자동 정렬
- 설정 페이지에 카테고리 관리 섹션 추가
  - 카테고리 추가/삭제 기능
  - Drag & Drop으로 순서 변경 (SortableJS)
  - AJAX 기반 위치 업데이트
- 품목 관리 폼에 카테고리 선택 드롭다운 추가
  - 설정에서 관리하는 카테고리 목록 표시
  - 빈 값 허용 (선택 사항)

**기본 카테고리**: 원재료, 부재료, 원포장재, 부포장재

#### 2. 보관위치 관리 시스템 (Storage Location Management)

**목적**: 품목별 보관 장소를 체계적으로 관리하여 재고 위치 추적

**구현 내용**:
- `StorageLocation` 모델 생성
  - 위치명, 위치 기반 정렬 지원
  - uniqueness validation
  - default_scope로 자동 정렬
- 설정 페이지에 보관위치 관리 섹션 추가
  - 위치 추가/삭제 기능
  - Drag & Drop으로 순서 변경
  - AJAX 기반 위치 업데이트
- 품목 관리 폼에 보관위치 선택 드롭다운 추가
  - 설정에서 관리하는 위치 목록 표시

**기본 보관위치**: 박스창고, 재료창고, 외부 쌀창고, 내부 쌀창고, 저온창고, 급냉창고, 냉동고A, 냉동고B

#### 3. 설정 페이지 탭 네비게이션 시스템 개선

**목적**: 설정 페이지의 사용성 향상 및 탭 상태 유지

**구현 내용**:
- Bootstrap 5 탭 시스템 구현
  - 생산관리, 재고관리, 레시피관리, 기기관리 탭 구성
  - 각 탭에 관련 설정 항목 그룹화
- URL 파라미터 기반 탭 상태 유지
  - `?tab=inventory` 형식으로 탭 지정
  - JavaScript로 URL 파라미터 읽어서 자동 탭 활성화
  - 모든 설정 CRUD 작업 redirect 시 탭 파라미터 포함
- SessionStorage 기반 스크롤 위치 유지
  - 폼 제출 시 스크롤 위치 저장
  - 페이지 로드 시 스크롤 위치 복원
  - 사용 후 자동 정리

**Tab Persistence Pattern**:
```ruby
# Example from SettingsController
redirect_to settings_system_path(tab: 'inventory'), notice: '...'
```

#### 4. 재료 관리 폼 개선

**구현 내용**:
- 단위 자동 변환 시스템 구현
  - Kg → g (×1000)
  - L → g (×1000, 물 밀도 기준)
  - mL → g (×1, 물 밀도 기준)
  - 모든 단위를 그램으로 통일하여 합계 계산
- UI 개선
  - 수량 입력 필드 오른쪽 정렬 (`.quantity-input`)
  - Bootstrap validation 표시 정리
  - 재료 선택 시 동적 행 생성 수정
- 이벤트 처리 개선
  - `input` 이벤트: 수량 변경 감지
  - `change` 이벤트: 단위 변경 감지
  - 실시간 합계 재계산

#### 5. 데이터베이스 마이그레이션

**생성된 마이그레이션**:
- `20251118031636_create_item_categories.rb`
  - id, name, position, timestamps
  - name에 unique index
- `20251118031946_create_storage_locations.rb`
  - id, name, position, timestamps
  - name에 unique index

**스키마 변경**:
- Item 모델에 `category`, `storage_location` 컬럼 추가
- position 기반 정렬을 위한 인덱스 추가

### 기술적 결정사항

1. **위치 기반 정렬 (Position-based Ordering)**
   - 사용자가 직접 순서를 지정할 수 있도록 position 컬럼 사용
   - SortableJS로 Drag & Drop 구현
   - AJAX로 위치 업데이트 (서버 왕복 최소화)

2. **단위 변환의 표준화**
   - 모든 중량/부피 단위를 그램(g)으로 통일
   - 혼합 단위 사용 시에도 정확한 합계 계산
   - 물 밀도 1g/mL 가정 (제빵/제과 일반적 근사)

3. **탭 상태 유지 전략**
   - URL 파라미터: 북마크 가능, 공유 가능
   - SessionStorage: 일시적 상태 (스크롤 위치)
   - 서버 리다이렉트 시 탭 파라미터 포함

4. **설정 항목의 확장성**
   - 데이터베이스 기반 관리 (하드코딩 제거)
   - 사용자가 직접 항목 추가/삭제 가능
   - Position 기반으로 표시 순서 제어

### 커밋 정보
**커밋 해시**: 2449e06
**커밋 메시지**: 품목 카테고리 및 보관위치 관리 기능 추가
**푸시 상태**: ✅ origin/main에 푸시 완료

### 파일 변경 내역
- 19개 파일 변경 (1149 추가, 418 삭제)
- 신규 모델: 2개
- 신규 마이그레이션: 2개
- 신규 테스트: 4개
- 컨트롤러 수정: 2개
- 뷰 수정: 6개

### 테스트 결과
✅ ItemCategory CRUD 동작 확인
✅ StorageLocation CRUD 동작 확인
✅ Item 생성 시 카테고리/보관위치 저장 확인
✅ 설정 페이지 탭 네비게이션 동작 확인
✅ 품목 폼 드롭다운에 카테고리/보관위치 표시 확인

### 상태
- Git: origin/main과 동기화 완료
- 마이그레이션: 모두 실행됨 (up)
- 서버: 실행 중 (port 3000)
- Working tree: clean (백업 파일만 untracked)

---

## 2025-11-16 (토) - 개발 로그 정리 및 세션 컨텍스트 관리

### 작업 내역
- CHANGELOG.md 파일 생성 및 작업 내역 문서화
- 2025-11-15 작업 내용 상세 정리
  - 레시피 버전 관리 시스템 구현 내역
  - 완제품 관리 기능 개선 내역
  - 트러블슈팅 과정 문서화
- Git 커밋 및 리모트 푸시 완료
- Claude Code 세션 컨텍스트 영구 보존
  - `.claude/session_context.md` - 프로젝트 전체 상태 (201줄)
  - `.claude/technical_patterns.md` - 아키텍처 패턴 (358줄)
  - `.claude/recovery_guide.md` - 세션 복구 가이드 (273줄)
  - `.claude/session_manifest.json` - 세션 메타데이터
  - 컨텍스트 보존율: 95%+

### 커밋 정보
**커밋 해시**: 507eb54
**커밋 메시지**: 개발 로그 추가
**푸시 상태**: ✅ origin/main에 푸시 완료

### 상태
- Git: origin/main과 동기화 완료
- 세션 컨텍스트: 영구 보존 완료 (.claude/ 디렉토리)
- Working tree: CHANGELOG.md 업데이트 대기 중

---

## 2025-11-15 (금) - 레시피 버전 관리 및 완제품 관리 기능 구현

### 주요 구현 내역

#### 1. 레시피 버전 관리 시스템 (Recipe Version Tracking)

**목적**: 레시피 수정 시 모든 변경 이력을 자동으로 추적하고 비교할 수 있는 시스템

**구현 내용**:
- `RecipeVersion` 모델 생성
  - 버전 번호, 변경 일시, 변경자, 변경 요약 저장
  - JSON 형식으로 전체 레시피 데이터 스냅샷 보관
- Recipe 모델에 `before_update` 콜백 추가
  - 레시피명, 설명, 비고 변경 감지
  - 재료 구성 변경 감지 (추가, 수정, 삭제)
  - 장비 구성 변경 감지 (추가, 수정, 삭제)
- 버전 히스토리 페이지 구현
  - 현재 버전과 모든 이전 버전 표시
  - 클릭 시 상세 내용 확장 (재료, 장비, 설명, 비고)
  - 변경사항 요약 표시
- 레시피 목록에 수정내역 아이콘 추가
  - 버전 개수 배지 표시

**파일 위치**:
- 모델: `app/models/recipe_version.rb`
- 컨트롤러: `app/controllers/recipe_versions_controller.rb`
- 뷰: `app/views/recipe_versions/index.html.erb`
- 마이그레이션: `db/migrate/20251115153454_create_recipe_versions.rb`

#### 2. 완제품 관리 기능 개선

**목적**: 완제품을 여러 레시피를 조합하여 등록하고, 중량을 자동 계산

**구현 내용**:
- 완제품 등록 폼 개선
  - 수량 → 중량(g) 입력으로 변경
  - 단위 선택 필드 제거 (자동으로 'g' 고정)
  - 레시피별 중량 입력
  - JavaScript로 총 중량 자동 계산
  - SortableJS로 레시피 순서 드래그앤드롭
- 완제품 상세 페이지
  - 구성 레시피 목록 및 중량 표시
  - 총 중량 자동 합산

**파일 위치**:
- 뷰: `app/views/finished_products/_form.html.erb`
- 뷰: `app/views/finished_products/show.html.erb`

#### 3. 레시피 삭제 검증 기능

**목적**: 완제품에서 사용 중인 레시피의 삭제를 방지하고 경고 표시

**구현 내용**:
- Recipe 모델에 완제품과의 관계 추가
  ```ruby
  has_many :finished_product_recipes, dependent: :destroy
  has_many :finished_products, through: :finished_product_recipes
  ```
- RecipesController의 destroy 액션에 검증 로직 추가
  - 완제품에서 사용 중인지 확인
  - 사용 중이면 완제품 이름과 함께 경고 메시지 표시
  - 사용하지 않으면 정상 삭제

**파일 위치**:
- 컨트롤러: `app/controllers/recipes_controller.rb` (destroy 액션)
- 모델: `app/models/recipe.rb`

#### 4. 데이터베이스 제약 조건 개선

**목적**: 레시피 삭제 시 관련 데이터 자동 삭제로 데이터 무결성 보장

**구현 내용**:
- 모든 레시피 외래키에 ON DELETE CASCADE 적용
  - `recipe_versions` → `recipes`
  - `recipe_equipments` → `recipes`
  - `recipe_ingredients` → `recipes`
  - `finished_product_recipes` → `recipes`
- 두 개의 마이그레이션 생성
  1. recipe_versions 외래키에 cascade 추가
  2. 나머지 모든 레시피 관련 외래키에 cascade 추가

**파일 위치**:
- `db/migrate/20251115154426_add_on_delete_cascade_to_recipe_versions.rb`
- `db/migrate/20251115154725_add_cascade_delete_to_all_recipe_foreign_keys.rb`

#### 5. 출고 관리 기능 추가

**구현 내용**:
- 출고 목적 및 요청자 설정 관리
- 출고 내역 등록 및 조회
- 재고 현황 페이지

**파일 위치**:
- 컨트롤러: `app/controllers/inventory/shipments_controller.rb`
- 모델: `app/models/shipment.rb`, `app/models/shipment_purpose.rb`, `app/models/shipment_requester.rb`

#### 6. 재료 및 장비 관리 시스템

**구현 내용**:
- 재료 구성 관리 (Ingredient)
- 장비 유형 및 모드 설정 (EquipmentType, EquipmentMode)
- 레시피별 재료 및 장비 연결 (RecipeIngredient, RecipeEquipment)
- 공정별 장비 그룹화 (RecipeProcess)

**파일 위치**:
- 컨트롤러: `app/controllers/ingredients_controller.rb`, `app/controllers/equipments_controller.rb`
- 모델: `app/models/ingredient.rb`, `app/models/equipment.rb` 등

### 트러블슈팅

#### 문제 1: Foreign Key Constraint Error
**증상**: 레시피 삭제 시 "FOREIGN KEY constraint failed" 에러 발생

**원인**:
- recipe_versions, recipe_ingredients, recipe_equipments, finished_product_recipes 테이블이 모두 recipes 테이블을 참조
- 외래키에 ON DELETE CASCADE가 설정되지 않아 삭제 불가

**해결**:
- 모든 레시피 관련 외래키에 ON DELETE CASCADE 추가
- 마이그레이션으로 기존 제약 조건 제거 후 재생성

#### 문제 2: 버전 추적이 작동하지 않음
**증상**: 레시피 수정 후 버전 히스토리에 아무것도 표시되지 않음

**원인**:
- before_update 콜백의 조건이 너무 제한적
- 중첩 속성(nested attributes) 변경 감지 못함

**해결**:
- 변경 감지 로직 개선
  ```ruby
  has_changes = changed? ||
                recipe_ingredients.any? { |ri| ri.changed? || ri.marked_for_destruction? || ri.new_record? } ||
                recipe_equipments.any? { |re| re.changed? || re.marked_for_destruction? || re.new_record? }
  ```

### 다음 작업 예정 사항

- [ ] 생산 계획 관리 기능
- [ ] 재고 자동 차감 기능
- [ ] 레시피 원가 계산 기능
- [ ] 장비 가동률 통계
- [ ] 대시보드 개선

### 기술 스택

- Ruby on Rails 8.1.1
- Ruby 3.4.7
- SQLite3
- Bootstrap 5
- SortableJS
- Turbo

### 데이터베이스 구조

주요 테이블:
- `recipes`: 레시피 기본 정보
- `recipe_versions`: 레시피 버전 히스토리
- `recipe_ingredients`: 레시피별 재료 구성
- `recipe_equipments`: 레시피별 장비 구성
- `finished_products`: 완제품 정보
- `finished_product_recipes`: 완제품-레시피 연결
- `items`: 품목 정보
- `receipts`: 입고 내역
- `shipments`: 출고 내역
- `equipment`: 장비 정보
- `ingredients`: 재료 정보

### 커밋 정보

**커밋 해시**: f3ff97d
**커밋 메시지**: 레시피 버전 관리 및 완제품 관리 기능 추가
**변경 파일**: 160개 파일, 7184줄 추가, 54줄 삭제
