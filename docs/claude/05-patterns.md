# Critical Patterns & Conventions

## 1. Nested Attributes
```ruby
# Recipe, FinishedProduct 등에서 사용
accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true
```

## 2. Position-based Ordering
```ruby
# 연관관계 정의
has_many :recipe_ingredients, -> { order(position: :asc) }

# AJAX로 위치 업데이트
params[:positions].each_with_index do |id, index|
  Model.find(id).update_column(:position, index + 1)
end
```

## 3. Recipe Version Tracking
```ruby
before_update :create_version_snapshot
# 기본 속성, 중첩 재료/장비 변경 감지
# RecipeVersion에 JSON 스냅샷 저장
```

## 4. Row Type Pattern
```ruby
# RecipeIngredient, IngredientItem에서 사용
row_type: 'ingredient' | 'subtotal'
source_type: 'item' | 'ingredient'
```

## 5. Unit Conversion (프론트엔드)
```javascript
function convertToGrams(quantity, unit) {
  switch(unit) {
    case 'Kg': return qty * 1000;
    case 'L': return qty * 1000;
    case 'g': case 'mL': return qty;
    default: return qty;
  }
}
```

## 6. FIFO Inventory (IngredientInventoryService)
1. RecipeIngredient에서 Item 찾기
2. `expiration_date ASC` 순으로 Receipt 선택
3. OpenedItem 찾기/생성
4. `deduct_weight()` 호출
5. CheckedIngredient 생성
6. 소진 시 자동 Shipment 생성

## 7. Device Authentication
```javascript
// 모든 Devise 폼에 필수
const deviseForms = document.querySelectorAll(
  'form[action*="sign_in"], form[action="/users"], form[action*="/admin/users"]'
);
// 자동으로 fingerprint, browser, os, device_name 주입
```

## 8. Settings Tab Persistence
```ruby
# CRUD 후 탭 유지
redirect_to settings_system_path(tab: 'inventory')
```

## 9. Bootstrap Validation Icons 비활성화
```scss
.form-select { background-image: none !important; }
```

## 10. Form Button Order
```erb
<!-- 항상 이 순서: 등록/수정 → 취소 -->
<%= f.submit "등록", class: "btn-modern btn-modern-primary" %>
<%= link_to "취소", back_path, class: "btn-modern btn-modern-outline" %>
```

## 11. Cascade Delete
```ruby
# 레시피 관련 테이블은 CASCADE
add_foreign_key :table, :recipes, on_delete: :cascade

# 품목은 제한 (입고/출고 있으면 삭제 불가)
has_many :receipts, dependent: :restrict_with_error
```

## 12. Auto-generated Codes
```ruby
before_validation :generate_item_code, on: :create
# ITEM-0001, ITEM-0002...
```

## 13. Production Plan Auto-sync
```ruby
# ProductionLog 저장 시
production_plan.update(quantity: production_log.dough_count)
```

## 14. Time Zone
```ruby
config.time_zone = "Seoul"
# 모든 시간은 KST
```
