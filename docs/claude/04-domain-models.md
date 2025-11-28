# Domain Models

## 1. Inventory (재고 관리)

### Item (품목)
- 자동 생성 코드: ITEM-0001, ITEM-0002...
- 바코드 지원
- 재고 계산: `current_stock = total_receipts - total_shipments`
- 공급업체: JSON 배열
- 카테고리/보관위치: 설정에서 관리

### Receipt (입고)
- 수량, 단가, 제조일, 유통기한
- 개당 중량 (unit_weight, unit_weight_unit)

### Shipment (출고)
- 출고 목적/요청자: 설정에서 관리 (position 기반 정렬)

### OpenedItem (개봉품)
- FIFO 기반 재고 차감
- `remaining_weight` 추적
- Scopes: `available`, `by_expiration`

### CheckedIngredient (체크된 재료)
- 생산일지에서 재료 사용 기록
- 유통기한, 사용량 추적

## 2. Recipe (레시피 관리)

### Recipe
- 재료 (RecipeIngredient) - Items 또는 Ingredients 참조 가능
- 장비 (RecipeEquipment)
- **자동 버전 추적**: 수정 시 JSON 스냅샷 저장

### RecipeVersion
- 완전한 레시피 스냅샷 (JSON)
- 변경 요약, 버전 번호

### RecipeIngredient
- `row_type`: 'ingredient' | 'subtotal'
- `source_type`: 'item' | 'ingredient'
- position 기반 정렬

## 3. Ingredient (재료 구성)

### Ingredient
- 생산량, 단위, 조리 시간
- 장비 유형/모드 연결

### IngredientItem
- 품목 또는 다른 재료 참조 (재귀적)
- **자동 단위 변환**: Kg×1000, L×1000 → g

## 4. FinishedProduct (완제품)

### FinishedProduct
- 여러 레시피 조합
- 총 중량 계산

### FinishedProductRecipe
- 레시피당 수량
- position 기반 정렬

## 5. Production (생산 관리)

### ProductionPlan
- 생산일, 수량 (decimal)
- 완제품 연결

### ProductionLog (반죽일지)
- 온도 추적 (반죽, 밀가루, 물, 죽)
- 재료량 (막걸리, 이스트, 설탕, 소금 등)
- 반죽 개수 (dough_count)
- **생산계획 자동 동기화**: dough_count 변경 시 plan.quantity 업데이트

## 6. Equipment (장비)

### Equipment
- 상태: 정상, 점검중, 고장, 폐기
- 제조사, 모델, 용량

### EquipmentType / EquipmentMode
- position 기반 정렬
- 설정에서 관리

## 7. Authentication (인증)

### User
- Devise 기반
- admin 플래그
- 첫 사용자 자동 admin

### AuthorizedDevice
- 브라우저 fingerprint (SHA-256)
- 관리자가 승인/해제

### LoginHistory
- 모든 로그인 시도 기록
- 성공/실패 사유
