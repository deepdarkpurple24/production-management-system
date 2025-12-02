# 재료 체크 시 재고 관리 서비스
# FIFO 방식으로 입고품을 선택하고, 개봉품을 관리하며, 필요 시 출고 처리
class IngredientInventoryService
  # 재료 체크 시 재고 처리
  # @param production_log [ProductionLog] 반죽일지
  # @param recipe_ingredient [RecipeIngredient] 레시피 재료
  # @param batch_index [Integer] 배치 인덱스
  # @param used_weight [Float] 사용한 중량 (그램)
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.check_ingredient(production_log, recipe_ingredient, batch_index, used_weight, current_user = nil)
    result = { success: false, checked_ingredient: nil, errors: [] }

    Rails.logger.info "=== IngredientInventoryService.check_ingredient 시작 ==="
    Rails.logger.info "RecipeIngredient ID: #{recipe_ingredient.id}, Position: #{recipe_ingredient.position}"
    Rails.logger.info "source_type: #{recipe_ingredient.source_type}"
    Rails.logger.info "Batch Index: #{batch_index}, Used Weight: #{used_weight}g"

    # source_type을 기준으로 처리 방식 결정
    # source_type == "ingredient"이고 referenced_ingredient가 있는 경우에만 Referenced Ingredient 처리
    if recipe_ingredient.source_type == "ingredient" && recipe_ingredient.referenced_ingredient.present?
      Rails.logger.info "Referenced Ingredient 감지: #{recipe_ingredient.referenced_ingredient.name}"
      return process_referenced_ingredient(production_log, recipe_ingredient, batch_index, used_weight, current_user)
    end

    # source_type == "item" 또는 source_type이 없는 경우: Item 직접 사용
    item = recipe_ingredient.item
    Rails.logger.info "Item 조회: #{item.present? ? "#{item.name} (ID: #{item.id})" : "없음"}"

    unless item
      error_msg = "재료에 연결된 품목이 없습니다. (RecipeIngredient ID: #{recipe_ingredient.id})"
      Rails.logger.error error_msg
      result[:errors] << error_msg
      return result
    end

    # process_item_deduction 호출
    result = process_item_deduction(production_log, recipe_ingredient, item, used_weight, batch_index, current_user)

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
      # CheckedIngredient 삭제 (before_destroy 콜백에서 개봉품 중량 복원됨)
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
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.process_referenced_ingredient(production_log, recipe_ingredient, batch_index, used_weight, current_user = nil)
    result = { success: false, checked_ingredient: nil, errors: [] }
    ingredient = recipe_ingredient.referenced_ingredient

    Rails.logger.info "=== Referenced Ingredient 처리: #{ingredient.name} ==="
    Rails.logger.info "필요량: #{used_weight}g"

    # Ingredient를 재귀적으로 펼쳐서 최종 Item 리스트와 사용량 얻기
    item_usages = expand_ingredient_to_items(ingredient, used_weight)

    Rails.logger.info "펼쳐진 품목 수: #{item_usages.size}"

    # 품목이 없으면 (모두 other 타입인 경우) 바로 성공 처리
    if item_usages.empty?
      Rails.logger.info "재고 관리 대상 품목 없음 - CheckedIngredient만 생성"
      checked_ingredient = production_log.checked_ingredients.create!(
        recipe_id: recipe_ingredient.recipe_id,
        ingredient_index: recipe_ingredient.position,
        batch_index: batch_index,
        used_weight: used_weight
      )
      result[:success] = true
      result[:checked_ingredient] = checked_ingredient
      return result
    end

    ActiveRecord::Base.transaction do
      first_opened_item = nil

      # 각 품목에 대해 재고 차감 (CheckedIngredient 생성 없이)
      item_usages.each do |item, actual_used_weight|
        Rails.logger.info "  품목: #{item.name}"
        Rails.logger.info "    실제 사용량: #{actual_used_weight.round(2)}g"

        # 해당 품목에 대해 재고 차감 (CheckedIngredient 생성하지 않음, 출고 처리 포함)
        item_result = process_item_deduction_only(item, actual_used_weight, production_log, current_user)

        unless item_result[:success]
          result[:errors].concat(item_result[:errors])
          raise ActiveRecord::Rollback
        end

        # 첫 번째 품목의 개봉품 정보 저장
        first_opened_item ||= item_result[:opened_item]
      end

      # CheckedIngredient는 한 번만 생성 (첫 번째 품목의 개봉품 정보 사용)
      Rails.logger.info "  CheckedIngredient 생성 중..."
      checked_ingredient = production_log.checked_ingredients.create!(
        recipe_id: recipe_ingredient.recipe_id,
        ingredient_index: recipe_ingredient.position,
        batch_index: batch_index,
        used_weight: used_weight,
        expiration_date: first_opened_item&.expiration_date,
        receipt_id: first_opened_item&.receipt_id,
        opened_item_id: first_opened_item&.id
      )
      Rails.logger.info "  CheckedIngredient 생성 완료: ID=#{checked_ingredient.id}"

      result[:checked_ingredient] = checked_ingredient
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

  # 재고 차감만 수행 (CheckedIngredient 생성 없음) - Referenced Ingredient용
  # @param item [Item] 품목
  # @param used_weight [Float] 사용한 중량 (그램)
  # @param production_log [ProductionLog] 반죽일지 (출고 처리용)
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  # @return [Hash] { success: true/false, opened_item: OpenedItem, errors: [] }
  def self.process_item_deduction_only(item, used_weight, production_log, current_user = nil)
    result = { success: false, opened_item: nil, errors: [] }

    # FIFO: 유통기한이 있는 입고품은 유통기한 순, 없는 입고품은 입고일 순
    available_receipts = item.receipts
      .order(Arel.sql("CASE WHEN expiration_date IS NULL THEN 1 ELSE 0 END"), :expiration_date, :receipt_date)

    Rails.logger.info "    사용 가능한 입고품 수: #{available_receipts.count}"

    if available_receipts.empty?
      error_msg = "#{item.name}의 입고 내역이 없습니다. 품목 입고를 먼저 진행해주세요."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # 기존 개봉품 총 재고 + 모든 입고품 재고 확인
    existing_opened_total = item.opened_items.available.sum(:remaining_weight)
    all_receipts_total_g = available_receipts.sum { |r| convert_to_grams(r.unit_weight.to_f, r.unit_weight_unit) }

    total_available = existing_opened_total + all_receipts_total_g
    Rails.logger.info "    총 가용 재고: 개봉품 #{existing_opened_total.round(2)}g + 입고품 #{all_receipts_total_g.round(2)}g = #{total_available.round(2)}g"

    if total_available < used_weight
      error_msg = "#{item.name}의 재고가 부족합니다. (필요: #{used_weight.round(2)}g, 가용: #{total_available.round(2)}g)"
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # 개봉품에서 중량 차감 (기존 개봉품 우선 소진, 부족 시 FIFO로 입고품 순차 개봉)
    Rails.logger.info "    개봉품에서 #{used_weight}g 차감 중... (기존 개봉품 우선 소진)"
    last_opened_item = deduct_from_opened_items(item, available_receipts, used_weight, production_log, current_user)

    unless last_opened_item
      error_msg = "#{item.name}의 개봉품에서 차감할 수 없습니다."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    result[:success] = true
    result[:opened_item] = last_opened_item
    result
  rescue => e
    error_msg = "#{item.name} 재고 차감 중 예외 발생: #{e.class.name} - #{e.message}"
    Rails.logger.error "    #{error_msg}"
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

      if ingredient_item.source_type == "other"
        # 기타(other)인 경우: 재고 관리 제외 (물 등)
        Rails.logger.info "#{'  ' * depth}    → 기타(other): #{ingredient_item.custom_name} - 재고 관리 제외"
        next

      elsif ingredient_item.source_type == "item" && ingredient_item.item
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
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  # @return [Hash] { success: true/false, checked_ingredient: CheckedIngredient, errors: [] }
  def self.process_item_deduction(production_log, recipe_ingredient, item, used_weight, batch_index, current_user = nil)
    result = { success: false, checked_ingredient: nil, errors: [] }

    # FIFO: 유통기한이 있는 입고품은 유통기한 순, 없는 입고품은 입고일 순
    available_receipts = item.receipts
      .order(Arel.sql("CASE WHEN expiration_date IS NULL THEN 1 ELSE 0 END"), :expiration_date, :receipt_date)

    Rails.logger.info "    사용 가능한 입고품 수: #{available_receipts.count}"

    if available_receipts.empty?
      error_msg = "#{item.name}의 입고 내역이 없습니다. 품목 입고를 먼저 진행해주세요."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # 기존 개봉품 총 재고 + 모든 입고품 재고 확인
    existing_opened_total = item.opened_items.available.sum(:remaining_weight)
    all_receipts_total_g = available_receipts.sum { |r| convert_to_grams(r.unit_weight.to_f, r.unit_weight_unit) }

    total_available = existing_opened_total + all_receipts_total_g
    Rails.logger.info "    총 가용 재고: 개봉품 #{existing_opened_total.round(2)}g + 입고품 #{all_receipts_total_g.round(2)}g = #{total_available.round(2)}g"

    if total_available < used_weight
      error_msg = "#{item.name}의 재고가 부족합니다. (필요: #{used_weight.round(2)}g, 가용: #{total_available.round(2)}g)"
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # 개봉품에서 중량 차감 (기존 개봉품 우선 소진, 부족 시 FIFO로 입고품 순차 개봉)
    Rails.logger.info "    개봉품에서 #{used_weight}g 차감 중... (기존 개봉품 우선 소진)"
    last_opened_item = deduct_from_opened_items(item, available_receipts, used_weight, production_log, current_user)

    unless last_opened_item
      error_msg = "#{item.name}의 개봉품에서 차감할 수 없습니다."
      Rails.logger.error "    #{error_msg}"
      result[:errors] << error_msg
      return result
    end

    # CheckedIngredient 생성 (마지막 사용된 개봉품 정보 기록)
    Rails.logger.info "    CheckedIngredient 생성 중..."
    checked_ingredient = production_log.checked_ingredients.create!(
      recipe_id: recipe_ingredient.recipe_id,
      ingredient_index: recipe_ingredient.position,
      batch_index: batch_index,
      used_weight: used_weight,
      expiration_date: last_opened_item.expiration_date,
      receipt_id: last_opened_item.receipt_id,
      opened_item_id: last_opened_item.id
    )
    Rails.logger.info "    CheckedIngredient 생성 완료: ID=#{checked_ingredient.id}"

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

  # 개봉품에서 중량 차감 (기존 개봉품 우선 소진, 부족 시 FIFO로 입고품 순차 개봉)
  # @param item [Item] 품목
  # @param available_receipts [ActiveRecord::Relation] FIFO 정렬된 입고품들
  # @param required_weight [Float] 필요한 중량
  # @param production_log [ProductionLog] 반죽일지 (출고 처리용)
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  # @return [OpenedItem, nil] 마지막 사용된 개봉품 (CheckedIngredient 기록용)
  def self.deduct_from_opened_items(item, available_receipts, required_weight, production_log, current_user = nil)
    Rails.logger.info "  > deduct_from_opened_items: 필요 중량=#{required_weight}g"

    remaining_to_deduct = required_weight
    last_used_opened_item = nil

    # 1. 기존 개봉품들을 유통기한 순으로 가져와서 순차 소진
    existing_opened_items = item.opened_items.available.by_expiration
    Rails.logger.info "  > 기존 개봉품 수: #{existing_opened_items.count}"

    existing_opened_items.each do |opened_item|
      break if remaining_to_deduct <= 0

      available = opened_item.remaining_weight
      deduct_amount = [ available, remaining_to_deduct ].min

      if deduct_amount > 0
        Rails.logger.info "  > 개봉품 ID=#{opened_item.id}에서 #{deduct_amount.round(2)}g 차감 (남은중량: #{available}g)"
        opened_item.deduct_weight(deduct_amount)
        remaining_to_deduct -= deduct_amount
        last_used_opened_item = opened_item
      end
    end

    # 2. 기존 개봉품으로 부족하면 FIFO 순서로 입고품 순차 개봉
    receipt_index = 0
    while remaining_to_deduct > 0 && receipt_index < available_receipts.count
      receipt = available_receipts[receipt_index]
      Rails.logger.info "  > 추가 필요량: #{remaining_to_deduct.round(2)}g - 입고품 #{receipt_index + 1}/#{available_receipts.count} 개봉 (Receipt ID=#{receipt.id})"

      new_opened_item = create_new_opened_item(item, receipt, production_log, current_user)
      unless new_opened_item
        # 현재 입고품에서 개봉 실패 시 다음 입고품으로 시도
        receipt_index += 1
        next
      end

      available = new_opened_item.remaining_weight
      deduct_amount = [ available, remaining_to_deduct ].min

      Rails.logger.info "  > 새 개봉품 ID=#{new_opened_item.id}에서 #{deduct_amount.round(2)}g 차감"
      new_opened_item.deduct_weight(deduct_amount)
      remaining_to_deduct -= deduct_amount
      last_used_opened_item = new_opened_item

      # 무한 루프 방지 (새 개봉품도 0g이면 다음 입고품으로)
      if available <= 0
        receipt_index += 1
      end
    end

    if remaining_to_deduct > 0
      Rails.logger.error "  > 경고: #{remaining_to_deduct.round(2)}g 차감 불가 - 모든 입고품 소진"
    end

    Rails.logger.info "  > 차감 완료. 마지막 사용 개봉품: ID=#{last_used_opened_item&.id}"
    last_used_opened_item
  end

  # 새 입고품 개봉 (출고 처리 포함)
  # @param item [Item] 품목
  # @param receipt [Receipt] 입고품
  # @param production_log [ProductionLog] 반죽일지
  # @param current_user [User] 현재 로그인 사용자
  # @return [OpenedItem, nil]
  def self.create_new_opened_item(item, receipt, production_log, current_user = nil)
    unit_weight_g = convert_to_grams(receipt.unit_weight, receipt.unit_weight_unit)
    Rails.logger.info "  > 새 입고품 개봉: Receipt ID=#{receipt.id}, 단위중량=#{unit_weight_g}g"

    opened_item = OpenedItem.create!(
      item: item,
      receipt: receipt,
      remaining_weight: unit_weight_g,
      expiration_date: receipt.expiration_date,
      opened_at: Time.current
    )

    # 새 개봉품 생성 시 출고 처리 (1개 출고)
    if opened_item && production_log
      Rails.logger.info "  > 새 개봉품 생성됨. 출고 처리 중..."
      create_shipment(item, receipt, production_log, current_user)
    end

    opened_item
  rescue => e
    Rails.logger.error "  > OpenedItem 생성 실패: #{e.class.name} - #{e.message}"
    nil
  end

  # 출고 처리
  # @param item [Item] 품목
  # @param receipt [Receipt] 입고품
  # @param production_log [ProductionLog] 반죽일지
  # @param current_user [User] 현재 로그인 사용자 (출고 요청자용)
  def self.create_shipment(item, receipt, production_log, current_user = nil)
    # 생산 사용 목적 찾기 또는 생성
    purpose = ShipmentPurpose.find_or_create_by!(name: "생산 사용") do |p|
      p.position = ShipmentPurpose.maximum(:position).to_i + 1
    end

    Shipment.create!(
      item: item,
      quantity: 1, # 1개 출고
      shipment_date: Time.current,
      purpose: purpose.name,
      requester: current_user&.name || "시스템",
      notes: "반죽일지 ##{production_log.id} - 자동 출고"
    )
  end

  # 단위를 그램으로 변환
  # @param weight [Float] 중량
  # @param unit [String] 단위 (Kg, g, L, mL, 개, 롤)
  # @return [Float] 그램 단위 중량 (개/롤은 개수 그대로 반환)
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
    when "개", "롤"
      weight # 개수 단위는 변환 없이 그대로 반환
    else
      weight * 1000 # 기본값: Kg로 간주
    end
  end
end
