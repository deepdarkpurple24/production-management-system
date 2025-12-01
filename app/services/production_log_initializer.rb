# 생산계획에서 반죽일지 자동 생성 및 ingredient_weights 계산
class ProductionLogInitializer
  # 생산계획에 대한 모든 반죽일지 생성
  # @param production_plan [ProductionPlan] 생산 계획
  # @return [Array<ProductionLog>] 생성된 반죽일지 목록
  def self.create_logs_for_plan(production_plan)
    finished_product = production_plan.finished_product
    logs = []

    # 완제품의 각 레시피에 대해 반죽일지 생성 (하나의 반죽일지에 여러 배치 포함)
    finished_product.recipes.each do |recipe|
      log = create_log_for_recipe(production_plan, recipe)
      logs << log if log
    end

    logs
  end

  # 특정 레시피에 대한 반죽일지 생성
  # @param production_plan [ProductionPlan] 생산 계획
  # @param recipe [Recipe] 레시피
  # @return [ProductionLog] 생성된 반죽일지
  def self.create_log_for_recipe(production_plan, recipe)
    # 이미 존재하는지 확인
    existing_log = ProductionLog.find_by(
      production_plan_id: production_plan.id,
      recipe_id: recipe.id
    )
    return existing_log if existing_log

    # ingredient_weights 계산
    ingredient_weights = calculate_ingredient_weights(production_plan, recipe)

    # 반죽일지 생성
    production_log = ProductionLog.new(
      production_plan_id: production_plan.id,
      finished_product_id: production_plan.finished_product_id,
      recipe_id: recipe.id,
      production_date: production_plan.production_date,
      ingredient_weights: ingredient_weights,
      status: production_plan.finished_product.name.include?("기정떡") ? "pending" : "in_progress"
    )

    production_log.save
    production_log
  end

  # ingredient_weights 계산
  # @param production_plan [ProductionPlan] 생산 계획
  # @param recipe [Recipe] 레시피
  # @return [Hash] ingredient_weights 해시
  def self.calculate_ingredient_weights(production_plan, recipe)
    finished_product = production_plan.finished_product

    # FinishedProductRecipe에서 quantity 가져오기
    fpr = finished_product.finished_product_recipes.find_by(recipe_id: recipe.id)
    weight_per_unit = fpr&.quantity || 0

    # 기정떡이거나 weight_per_unit이 0이면 빈 해시 반환
    is_gijeongddeok = finished_product.name.include?("기정떡")
    return {} if is_gijeongddeok || weight_per_unit.zero?

    # 레시피 총 중량 계산
    recipe_total = recipe.recipe_ingredients.where(row_type: [ "ingredient", nil ]).sum(:weight)
    recipe_total = recipe_total.zero? ? 1 : recipe_total

    # 배율 계산
    multiplier = (production_plan.quantity.to_f * weight_per_unit) / recipe_total

    # 총 스케일된 중량
    total_scaled = recipe_total * multiplier

    # 분할 기준 장비들의 최대 작업 중량 합계 계산
    batch_standard_equipments = recipe.recipe_equipments.where(is_batch_standard: true).where.not(work_capacity: [ nil, 0 ])

    if batch_standard_equipments.any?
      # 분할 기준 장비가 있으면 해당 장비들의 work_capacity 합계 사용
      total_work_capacity = batch_standard_equipments.sum(:work_capacity)
    else
      # 분할 기준 장비가 없으면 기존 방식 (최대값) 사용
      total_work_capacity = recipe.recipe_equipments.where.not(work_capacity: [ nil, 0 ]).maximum(:work_capacity)
    end

    max_work_capacity_g = total_work_capacity ? total_work_capacity * 1000 : nil

    # 배치 수 계산
    if max_work_capacity_g && max_work_capacity_g > 0 && total_scaled > max_work_capacity_g
      batch_count = (total_scaled / max_work_capacity_g).ceil
    else
      batch_count = 1
    end

    # ingredient_weights 해시 생성
    weights = {}
    batch_count.times do |batch_index|
      recipe.recipe_ingredients.where(row_type: [ "ingredient", nil ]).each do |ri|
        scaled_weight = (ri.weight.to_f * multiplier) / batch_count
        field_key = "batch_#{batch_index}_ri_#{ri.id}"
        weights[field_key] = scaled_weight.round(0).to_s
      end
    end

    weights
  end

  # 기정떡 분할용 ingredient_weights 계산
  # @param recipe [Recipe] 레시피
  # @param split_unit [Float] 분할 단위 (0.5, 1.0 등)
  # @return [Hash] ingredient_weights 해시
  def self.calculate_gijeongddeok_weights(recipe, split_unit)
    weights = {}

    # 레시피 재료들 (분할 단위에 맞게 조정)
    recipe.recipe_ingredients.where(row_type: [ "ingredient", nil ]).each do |ri|
      scaled_weight = ri.weight.to_f * split_unit
      field_key = "batch_0_ri_#{ri.id}"
      weights[field_key] = scaled_weight.round(0).to_s
    end

    # 0.5통일 경우 추가 재료 적용
    if split_unit == 0.5
      extra_ingredients = get_half_batch_extra_ingredients
      extra_ingredients.each do |extra|
        # 품목에 해당하는 재료를 찾아서 중량 추가
        matching_ri = recipe.recipe_ingredients
                            .where(row_type: [ "ingredient", nil ])
                            .joins(:item)
                            .find_by(items: { id: extra[:item_id] })

        if matching_ri
          field_key = "batch_0_ri_#{matching_ri.id}"
          current_weight = weights[field_key].to_f
          weights[field_key] = (current_weight + extra[:weight]).round(0).to_s
        else
          # 레시피에 없는 재료면 별도로 추가
          field_key = "batch_0_extra_#{extra[:item_id]}"
          weights[field_key] = extra[:weight].round(0).to_s
        end
      end
    end

    weights
  end

  # 0.5통 추가 재료 설정 가져오기
  # @return [Array<Hash>] 추가 재료 목록 [{item_id: 1, weight: 100}, ...]
  def self.get_half_batch_extra_ingredients
    gijeongddeok_default = GijeongddeokDefault.instance
    extra_ingredients = gijeongddeok_default.half_batch_extra_ingredients || []

    extra_ingredients.map do |ingredient|
      {
        item_id: ingredient["item_id"].to_i,
        weight: ingredient["weight"].to_f
      }
    end
  end
end
