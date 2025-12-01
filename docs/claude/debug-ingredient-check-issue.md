# 재료 체크 기능 디버깅 - 2025-12-01

## 문제 상황

1. **증상**: 이스트를 더블클릭했는데 "멥쌀의 입고 내역이 없습니다"라는 에러가 표시됨
2. **추가 증상**: 모든 재료가 입고 처리되어 있는데도 입고 내역이 없다고 나옴

## 의심되는 원인

### 1. Position 불일치 가능성
- 뷰에서 `data-ingredient-index="<%= ri.position %>"`으로 position을 전달
- 컨트롤러에서 `recipe.recipe_ingredients.find_by(position: ingredient_index)`로 재료 검색
- **position이 연속적이지 않거나 재정렬 후 누락된 position이 있을 수 있음**

### 2. Referenced Ingredient 처리
- 레시피 재료가 `referenced_ingredient`를 참조하는 경우
- `expand_ingredient_to_items`로 내부 품목들을 펼침
- 첫 번째 품목(예: 멥쌀)에서 에러 발생 시 해당 에러 메시지가 표시됨

## 서버에서 확인해야 할 사항

```ruby
# Rails 콘솔에서 실행

# 1. 문제가 되는 레시피의 재료와 position 확인
Recipe.find(문제가_되는_레시피_ID).recipe_ingredients.order(:position).each do |ri|
  puts "Position: #{ri.position}, ID: #{ri.id}, Item: #{ri.item&.name || ri.referenced_ingredient&.name}, row_type: #{ri.row_type}"
end

# 2. 특정 Item의 입고 내역 확인
Item.find_by(name: "멥쌀")&.receipts&.count
Item.find_by(name: "이스트")&.receipts&.count

# 3. 모든 품목의 입고 내역 유무 확인
Item.all.each do |item|
  receipt_count = item.receipts.where("expiration_date IS NOT NULL").count
  puts "#{item.name}: #{receipt_count}개 입고 (유통기한 있음)" if receipt_count == 0
end

# 4. 레시피 재료가 Referenced Ingredient를 사용하는지 확인
RecipeIngredient.where.not(referenced_ingredient_id: nil).includes(:referenced_ingredient).each do |ri|
  puts "레시피 #{ri.recipe_id}: #{ri.referenced_ingredient.name} (Position: #{ri.position})"
end
```

## 관련 파일

1. **컨트롤러**: `app/controllers/production/logs_controller.rb`
   - `update_ingredient_check` 메서드 (라인 249-341)

2. **서비스**: `app/services/ingredient_inventory_service.rb`
   - `check_ingredient` 메서드
   - `process_item_deduction` 메서드 (라인 185-252)
   - `process_referenced_ingredient` 메서드 (라인 80-121)

3. **뷰**: `app/views/production/logs/edit.html.erb`
   - 재료 행의 data 속성 (라인 227-232)

## 정상 작동했던 커밋

```bash
git show 21026f8  # 반죽일지 재료 체크 기능 개선
```

이 커밋에서 재료 체크 기능이 정상 작동했음.

## 최근 변경 사항

1. 더블클릭 방식으로 변경 (이전: 싱글클릭)
2. UI 먼저 변경 후 서버 API 호출 (optimistic update)
3. 에러 발생 시 UI 원복 및 alert 표시

## 다음 단계

1. 서버에서 Rails 콘솔로 실제 데이터 확인
2. 문제가 되는 레시피의 position 값 검증
3. Referenced Ingredient 사용 여부 확인
4. 입고 데이터의 expiration_date NULL 여부 확인
