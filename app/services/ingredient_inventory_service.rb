# 재료 체크 시 재고 관리 서비스
# FIFO 방식으로 입고품을 선택하고, 개봉품을 관리하며, 필요 시 출고 처리
class IngredientInventoryService
  # 재료 체크 시 재고 처리
  # @param production_log [ProductionLog] 반죽일지
  # @param recipe_ingredient [RecipeIngredient] 레시피 재료
  # @param batch_index [Integer] 배치 인덱스
  # @param used_weight [Float] 사용한 중량 (그램)
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.check_ingredient(production_log, recipe_ingredient, batch_index, used_weight)
    result = { success: false, checked_ingredient: nil, errors: [] }

    Rails.logger.info "=== IngredientInventoryService.check_ingredient 시작 ==="
    Rails.logger.info "RecipeIngredient ID: #{recipe_ingredient.id}, Position: #{recipe_ingredient.position}"
    Rails.logger.info "Batch Index: #{batch_index}, Used Weight: #{used_weight}g"

    # RecipeIngredient가 Ingredient를 참조하는지 확인
    if recipe_ingredient.referenced_ingredient.present?
      Rails.logger.info "Referenced Ingredient 감지: #{recipe_ingredient.referenced_ingredient.name}"
      return process_referenced_ingredient(production_log, recipe_ingredient, batch_index, used_weight)
    end

    # 기존 로직: Item 직접 사용
    item = recipe_ingredient.item
    Rails.logger.info "Item 조회: #{item.present? ? "#{item.name} (ID: #{item.id})" : "없음"}"

    unless item
      error_msg = "재료에 연결된 품목이 없습니다. (RecipeIngredient ID: #{recipe_ingredient.id})"
      Rails.logger.error error_msg
      result[:errors] << error_msg
      return result
    end

    # process_item_deduction 호출
    result = process_item_deduction(production_log, recipe_ingredient, item, used_weight, batch_index)

    if result[:success]
      Rails.logger.info "=== IngredientInventoryService.check_ingredient 완료 (성공) ==="
    end

    result
  rescue => e
    error_msg = "예외 발생: #{e.class.name} - #{e.message}"
    Rails.logger.error error_msg
    Rails.logger.error e.backtrace.first(5).join("\n")
    result[:errors] << error_msg
    result
  end

  # 재료 체크 해제 시 개봉품 복원
  # @param checked_ingredient [CheckedIngredient] 체크된 재료
  # @return [Hash] { success: true/false, errors: [] }
  def self.uncheck_ingredient(checked_ingredient)
    result = { success: false, errors: [] }

    ActiveRecord::Base.transaction do
      # 개봉품이 있으면 중량 복원
      if checked_ingredient.opened_item && checked_ingredient.used_weight
        checked_ingredient.opened_item.restore_weight(checked_ingredient.used_weight)
      end

      # CheckedIngredient 삭제
      checked_ingredient.destroy!

      result[:success] = true
    end

    result
  rescue => e
    result[:errors] << "예외 발생: #{e.message}"
    result
  end

  # Referenced Ingredient 처리 (재료 구성 기반 재고 차감)
  # @param production_log [ProductionLog] 반죽일지
  # @param recipe_ingredient [RecipeIngredient] 레시피 재료
  # @param batch_index [Integer] 배치 인덱스
  # @param used_weight [Float] 사용한 중량 (그램)
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.process_referenced_ingredient(production_log, recipe_ingredient, batch_index, used_weight)
    result = { success: false, checked_ingredient: nil, errors: [] }
    ingredient = recipe_ingredient.referenced_ingredient

    Rails.logger.info "=== Referenced Ingredient 처리: #{ingredient.name} ==="
    Rails.logger.info "필요량: #{used_weight}g"

    # Ingredient를 재귀적으로 펼쳐서 최종 Item 리스트와 사용량 얻기
    item_usages = expand_ingredient_to_items(ingredient, used_weight)

    Rails.logger.info "펼쳐진 품목 수: #{item_usages.size}"

    ActiveRecord::Base.transaction do
      # 각 품목에 대해 재고 차감
      item_usages.each do |item, actual_used_weight|
        Rails.logger.info "  품목: #{item.name}"
        Rails.logger.info "    실제 사용량: #{actual_used_weight.round(2)}g"

        # 해당 품목에 대해 재고 차감
        item_result = process_item_deduction(production_log, recipe_ingredient, item, actual_used_weight, batch_index)

        unless item_result[:success]
          result[:errors].concat(item_result[:errors])
          raise ActiveRecord::Rollback
        end

        # 첫 번째 품목의 CheckedIngredient를 대표로 저장
        result[:checked_ingredient] ||= item_result[:checked_ingredient]
      end

      result[:success] = true
      Rails.logger.info "=== Referenced Ingredient 처리 완료 ==="
    end

    result
  rescue => e
    error_msg = "Referenced Ingredient 처리 중 예외 발생: #{e.class.name} - #{e.message}"
    Rails.logger.error error_msg
    Rails.logger.error e.backtrace.first(5).join("\n")
    result[:errors] << error_msg
    result
  end

  # Ingredient를 재귀적으로 펼쳐서 최종 Item 리스트와 사용량 반환
  # @param ingredient [Ingredient] 펼칠 재료
  # @param required_weight [Float] 필요한 중량 (그램)
  # @param depth [Integer] 재귀 깊이 (무한 루프 방지)
  # @return [Hash<Item, Float>] { Item => 사용량(g) }
  def self.expand_ingredient_to_items(ingredient, required_weight, depth = 0)
    return {} if depth > 10 # 무한 재귀 방지

    Rails.logger.info "#{'  ' * depth}> Ingredient 펼치기: #{ingredient.name} (필요량: #{required_weight.round(2)}g)"

    # 생산량을 그램으로 환산
    production_quantity_g = convert_to_grams(ingredient.production_quantity, ingredient.production_unit)
    Rails.logger.info "#{'  ' * depth}  생산량: #{production_quantity_g}g"

    # 배율 계산
    multiplier = required_weight / production_quantity_g
    Rails.logger.info "#{'  ' * depth}  배율: #{multiplier.round(4)}"

    result = {}

    # ingredient_items 순회
    ingredient.ingredient_items.each do |ingredient_item|
      # 구성 재료의 양을 그램으로 환산
      item_quantity_g = convert_to_grams(ingredient_item.quantity, ingredient_item.unit)
      scaled_quantity = item_quantity_g * multiplier

      Rails.logger.info "#{'  ' * depth}  - #{ingredient_item.source_type}: #{item_quantity_g}g × #{multiplier.round(4)} = #{scaled_quantity.round(2)}g"

      if ingredient_item.source_type == "item" && ingredient_item.item
        # Item인 경우: 결과에 추가 (같은 item이면 합산)
        item = ingredient_item.item
        result[item] ||= 0
        result[item] += scaled_quantity
        Rails.logger.info "#{'  ' * depth}    → Item: #{item.name} (누적: #{result[item].round(2)}g)"

      elsif ingredient_item.source_type == "ingredient" && ingredient_item.referenced_ingredient
        # Ingredient인 경우: 재귀적으로 펼치기
        sub_ingredient = ingredient_item.referenced_ingredient
        Rails.logger.info "#{'  ' * depth}    → 하위 Ingredient: #{sub_ingredient.name} 재귀 처리"

        # 재귀 호출
        sub_results = expand_ingredient_to_items(sub_ingredient, scaled_quantity, depth + 1)

        # 하위 결과를 현재 결과에 병합 (같은 item이면 합산)
        sub_results.each do |item, weight|
          result[item] ||= 0
          result[item] += weight
        end
      end
    end

    Rails.logger.info "#{'  ' * depth}< 펼치기 완료: #{result.size}개 품목"
    result
  end

  # 품목 재고 차감 (공통 로직)
  # @param production_log [ProductionLog] 반죽일지
  # @param recipe_ingredient [RecipeIngredient] 레시피 재료
  # @param item [Item] 품목
  # @param used_weight [Float] 사용한 중량 (그램)
  # @param batch_index [Integer] 배치 인덱스
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.process_item_deduction(production_log, recipe_ingredient, item, used_weight, batch_index)
    result = { success: false, checked_ingredient: nil, errors: [] }

    # FIFO: 유통기한이 짧은 입고품부터 찾기
    available_receipts = item.receipts
      .where("expiration_date IS NOT NULL")
      .order(expiration_date: :asc, receipt_date: :asc)

    Rails.logger.info "    사용 가능한 입고품 수: #{available_receipts.count}"

    if available_receipts.empty?
      error_msg = "#{item.name}의 입고 내역이 없습니다."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # 개봉품 찾기 또는 생성
    opened_item = find_or_create_opened_item(item, available_receipts.first, used_weight)

    unless opened_item
      error_msg = "#{item.name}의 개봉품을 생성할 수 없습니다."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    Rails.logger.info "    개봉품: ID=#{opened_item.id}, 남은 중량=#{opened_item.remaining_weight}g"

    # 개봉품에서 중량 차감
    if opened_item.remaining_weight < used_weight
      error_msg = "#{item.name} 개봉품의 남은 중량(#{opened_item.remaining_weight}g)이 사용량(#{used_weight}g)보다 적습니다."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    Rails.logger.info "    개봉품에서 #{used_weight}g 차감 중..."
    opened_item.deduct_weight(used_weight)

    # CheckedIngredient 생성
    Rails.logger.info "    CheckedIngredient 생성 중..."
    checked_ingredient = production_log.checked_ingredients.create!(
      recipe_id: recipe_ingredient.recipe_id,
      ingredient_index: recipe_ingredient.position,
      batch_index: batch_index,
      used_weight: used_weight,
      expiration_date: opened_item.expiration_date,
      receipt_id: opened_item.receipt_id,
      opened_item_id: opened_item.id
    )
    Rails.logger.info "    CheckedIngredient 생성 완료: ID=#{checked_ingredient.id}"

    # 개봉품이 소진되었으면 출고 처리
    if opened_item.depleted?
      Rails.logger.info "    개봉품 소진됨. 출고 처리 중..."
      create_shipment(item, opened_item.receipt, production_log)
    end

    result[:success] = true
    result[:checked_ingredient] = checked_ingredient
    result
  rescue => e
    error_msg = "#{item.name} 재고 차감 중 예외 발생: #{e.class.name} - #{e.message}"
    Rails.logger.error "    #{error_msg}"
    result[:errors] << error_msg
    result
  end

  private

  # 개봉품 찾기 또는 생성
  # @param item [Item] 품목
  # @param receipt [Receipt] 입고품
  # @param required_weight [Float] 필요한 중량
  # @return [OpenedItem, nil]
  def self.find_or_create_opened_item(item, receipt, required_weight)
    Rails.logger.info "  > find_or_create_opened_item: 필요 중량=#{required_weight}g"

    # 1. 기존 개봉품이 있으면 사용 (유통기한 순으로 정렬)
    existing_opened_item = item.opened_items
      .available
      .by_expiration
      .where("remaining_weight >= ?", required_weight)
      .first

    if existing_opened_item
      Rails.logger.info "  > 기존 개봉품 사용: ID=#{existing_opened_item.id}, 남은중량=#{existing_opened_item.remaining_weight}g"
      return existing_opened_item
    end

    # 2. 기존 개봉품으로 부족하면, 부족한 만큼만 새로 개봉
    existing_total = item.opened_items.available.sum(:remaining_weight)
    Rails.logger.info "  > 기존 개봉품 총 중량: #{existing_total}g"

    if existing_total >= required_weight
      # 여러 개봉품을 조합해서 사용해야 하는 경우
      # 일단 첫 번째 개봉품 반환 (추후 개선 필요)
      first_item = item.opened_items.available.by_expiration.first
      Rails.logger.info "  > 기존 개봉품 조합 사용 (첫번째): ID=#{first_item.id}"
      return first_item
    end

    # 3. 새 입고품 개봉
    # 품목의 단위 중량 (unit_weight)을 그램으로 환산
    unit_weight_g = convert_to_grams(receipt.unit_weight, receipt.unit_weight_unit)
    Rails.logger.info "  > 새 입고품 개봉: Receipt ID=#{receipt.id}, 단위중량=#{unit_weight_g}g"

    OpenedItem.create!(
      item: item,
      receipt: receipt,
      remaining_weight: unit_weight_g,
      expiration_date: receipt.expiration_date,
      opened_at: Time.current
    )
  rescue => e
    Rails.logger.error "  > OpenedItem 생성 실패: #{e.class.name} - #{e.message}"
    nil
  end

  # 출고 처리
  # @param item [Item] 품목
  # @param receipt [Receipt] 입고품
  # @param production_log [ProductionLog] 반죽일지
  def self.create_shipment(item, receipt, production_log)
    # 생산 사용 목적 찾기 또는 생성
    purpose = ShipmentPurpose.find_or_create_by!(name: "생산 사용") do |p|
      p.position = ShipmentPurpose.maximum(:position).to_i + 1
    end

    Shipment.create!(
      item: item,
      quantity: 1, # 1개 출고
      shipment_date: Date.today,
      purpose: purpose,
      requester: nil, # 추후 로그인 사용자로 설정
      notes: "반죽일지 ##{production_log.id} - 자동 출고"
    )
  end

  # 단위를 그램으로 변환
  # @param weight [Float] 중량
  # @param unit [String] 단위 (Kg, g, L, mL, 개)
  # @return [Float] 그램 단위 중량
  def self.convert_to_grams(weight, unit)
    return 15000.0 unless weight # 기본값 15kg

    case unit
    when "Kg"
      weight * 1000
    when "g"
      weight
    when "L"
      weight * 1000 # 물 기준 밀도
    when "mL"
      weight
    else
      weight * 1000 # 기본값: Kg로 간주
    end
  end
end
