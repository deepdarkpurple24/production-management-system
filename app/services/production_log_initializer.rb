# 생산계획에서 반죽일지 자동 생성 및 ingredient_weights 계산
class ProductionLogInitializer
  # 생산계획에 대한 모든 반죽일지 생성
  # @param production_plan [ProductionPlan] 생산 계획
  # @return [Array<ProductionLog>] 생성된 반죽일지 목록
  def self.create_logs_for_plan(production_plan)
    finished_product = production_plan.finished_product
    logs = []

    # 완제품의 각 레시피에 대해 반죽일지 생성
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

    # 장비 최대 작업 중량 확인
    max_work_capacity = recipe.recipe_equipments.where.not(work_capacity: [ nil, 0 ]).maximum(:work_capacity)
    max_work_capacity_g = max_work_capacity ? max_work_capacity * 1000 : nil

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
end
