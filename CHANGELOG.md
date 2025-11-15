# 개발 로그

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
