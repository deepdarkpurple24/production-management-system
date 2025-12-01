class Production::LogsController < ApplicationController
  before_action :set_production_log, only: [ :edit, :update, :destroy ]

  def index
    @status = params[:status] || "pending"
    @selected_date = params[:date] ? Date.parse(params[:date]) : Date.today

    # 모든 탭의 개수를 계산 (항상 표시하기 위해)
    production_plans = ProductionPlan
      .includes(finished_product: :recipes)
      .where(production_date: @selected_date)
      .order(created_at: :desc)

    # 이미 반죽일지가 생성된 (plan_id, recipe_id) 조합 찾기
    existing_logs = ProductionLog
      .where(production_plan_id: production_plans.pluck(:id))
      .where.not(status: "pending")
      .pluck(:production_plan_id, :recipe_id)
      .to_set

    # 작업 전 개수 계산
    pending_count = 0
    production_plans.each do |plan|
      finished_product = plan.finished_product
      recipes = finished_product.recipes

      if recipes.any?
        recipes.each do |recipe|
          unless existing_logs.include?([ plan.id, recipe.id ])
            pending_count += 1
          end
        end
      else
        unless existing_logs.any? { |log| log[0] == plan.id }
          pending_count += 1
        end
      end
    end
    @pending_count = pending_count

    # 작업중 개수
    @in_progress_count = ProductionLog
      .where(status: "in_progress", production_date: @selected_date)
      .count

    # 작업완료 개수
    @completed_count = ProductionLog
      .where(status: "completed", production_date: @selected_date)
      .count

    # 현재 탭에 따라 상세 데이터 로드
    case @status
    when "pending"
      # 레시피별로 평탄화하여 각각 독립적인 항목으로 표시
      @pending_plans = []
      production_plans.each do |plan|
        finished_product = plan.finished_product
        recipes = finished_product.recipes

        if recipes.any?
          recipes.each do |recipe|
            unless existing_logs.include?([ plan.id, recipe.id ])
              @pending_plans << {
                plan: plan,
                finished_product: finished_product,
                recipe: recipe
              }
            end
          end
        else
          unless existing_logs.any? { |log| log[0] == plan.id }
            @pending_plans << {
              plan: plan,
              finished_product: finished_product,
              recipe: nil
            }
          end
        end
      end

    when "in_progress"
      @production_logs = ProductionLog
        .includes(:finished_product, :production_plan, :recipe)
        .where(status: "in_progress", production_date: @selected_date)
        .order(created_at: :desc)

    when "completed"
      @production_logs = ProductionLog
        .includes(:finished_product, :production_plan, :recipe)
        .where(status: "completed", production_date: @selected_date)
        .order(created_at: :desc)
    end
  end

  def new
    # 기존 반죽일지가 있으면 edit로 리다이렉트
    if params[:production_plan_id] && params[:recipe_id]
      existing_log = ProductionLog.find_by(
        production_plan_id: params[:production_plan_id],
        recipe_id: params[:recipe_id]
      )

      if existing_log
        redirect_to edit_production_log_path(existing_log) and return
      end

      @production_log = ProductionLog.new(
        production_plan_id: params[:production_plan_id],
        recipe_id: params[:recipe_id]
      )
    else
      @production_log = ProductionLog.new
    end

    @production_log.production_date = params[:date] ? Date.parse(params[:date]) : Date.today

    # 생산계획 ID와 레시피 ID가 주어지면 해당 레시피로 설정
    if params[:production_plan_id]
      @production_plan = ProductionPlan.find(params[:production_plan_id])
      @production_log.production_plan = @production_plan
      @production_log.finished_product = @production_plan.finished_product
      @production_log.production_date = @production_plan.production_date

      # 레시피 ID가 주어지면 해당 레시피 설정
      if params[:recipe_id]
        @recipe = Recipe.find(params[:recipe_id])
        @production_log.recipe = @recipe
      end
    end

    @finished_products = FinishedProduct.order(:name)
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
  end

  def create
    # 같은 생산계획 + 레시피 조합이 이미 있으면 업데이트
    existing_log = ProductionLog.find_by(
      production_plan_id: params[:production_log][:production_plan_id],
      recipe_id: params[:production_log][:recipe_id]
    )

    if existing_log
      # 이미 있으면 업데이트 (checked_ingredients 보존)
      @production_log = existing_log
      @production_log.assign_attributes(production_log_params)
    else
      # 새로 생성
      @production_log = ProductionLog.new(production_log_params)

      # 모든 반죽일지는 작업중으로 시작 (기정떡 포함)
      @production_log.status = "in_progress"
    end

    if @production_log.save
      # 생산 계획 수량 자동 업데이트
      update_production_plan_quantity(@production_log)

      log_activity(:create, @production_log)
      redirect_to production_logs_path(status: @production_log.status), notice: "생산 일지가 성공적으로 등록되었습니다."
    else
      @production_plans = ProductionPlan
        .includes(:finished_product)
        .where(production_date: @production_log.production_date)
        .order(:created_at)
      @finished_products = FinishedProduct.order(:name)
      @gijeongddeok_default = GijeongddeokDefault.instance
      @gijeongddeok_fields = GijeongddeokFieldOrder.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @production_log.production_date)
      .order(:created_at)
    @finished_products = FinishedProduct.order(:name)
    @gijeongddeok_default = GijeongddeokDefault.instance
    @gijeongddeok_fields = GijeongddeokFieldOrder.all
    @from_status = params[:from_status] || @production_log.status
  end

  def update
    old_dough_count = @production_log.dough_count
    from_status = params[:from_status] || @production_log.status

    if @production_log.update(production_log_params)
      # 생산 계획 수량 자동 업데이트 (반죽 통수가 변경된 경우)
      if @production_log.dough_count != old_dough_count
        update_production_plan_quantity(@production_log)
      end

      log_activity(:update, @production_log)
      redirect_to production_logs_path(status: from_status, date: @production_log.production_date), notice: "생산 일지가 성공적으로 수정되었습니다."
    else
      @production_plans = ProductionPlan
        .includes(:finished_product)
        .where(production_date: @production_log.production_date)
        .order(:created_at)
      @finished_products = FinishedProduct.order(:name)
      @gijeongddeok_default = GijeongddeokDefault.instance
      @gijeongddeok_fields = GijeongddeokFieldOrder.all
      @from_status = from_status
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    from_status = params[:from_status] || "pending"
    production_date = @production_log.production_date
    log_activity(:destroy, @production_log)
    @production_log.destroy
    redirect_to production_logs_path(status: from_status, date: production_date), notice: "생산 일지가 성공적으로 삭제되었습니다."
  end

  def create_draft
    # 중복 확인: 같은 생산계획 + 레시피 조합이 이미 있으면 기존 것 사용
    production_plan_id = params[:production_plan_id].present? ? params[:production_plan_id] : nil
    recipe_id = params[:recipe_id]

    existing_log = ProductionLog.find_by(
      production_plan_id: production_plan_id,
      recipe_id: recipe_id
    )

    if existing_log
      # 이미 있으면 기존 것 반환
      render json: {
        success: true,
        production_log_id: existing_log.id,
        status: existing_log.status
      }
      return
    end

    # 최소 정보로 반죽일지 초안 생성
    @production_log = ProductionLog.new
    @production_log.production_plan_id = production_plan_id
    @production_log.finished_product_id = params[:finished_product_id]
    @production_log.recipe_id = recipe_id
    @production_log.production_date = params[:production_date] ? Date.parse(params[:production_date]) : Date.today

    # 모든 반죽일지는 작업중으로 시작 (기정떡 포함)
    @production_log.status = "in_progress"

    if @production_log.save
      render json: {
        success: true,
        production_log_id: @production_log.id,
        status: @production_log.status
      }
    else
      render json: { success: false, errors: @production_log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_ingredient_check
    @production_log = ProductionLog.find(params[:id])
    recipe_id = params[:recipe_id]
    ingredient_index = params[:ingredient_index].to_i
    batch_index = params[:batch_index].to_i
    checked = ActiveModel::Type::Boolean.new.cast(params[:checked])

    # RecipeIngredient 찾기
    recipe = Recipe.find(recipe_id)
    recipe_ingredient = recipe.recipe_ingredients.find_by(position: ingredient_index)

    unless recipe_ingredient
      render json: { success: false, errors: [ "재료를 찾을 수 없습니다." ] }, status: :unprocessable_entity
      return
    end

    # CheckedIngredient 테이블을 사용한 체크 상태 관리 + 재고 처리
    if checked
      # 사용한 중량 가져오기
      # 1. ingredient_weights에 저장된 값이 있으면 사용
      # 2. 없으면 recipe_ingredient.weight를 기본값으로 사용
      field_key = "batch_#{batch_index}_ri_#{recipe_ingredient.id}"
      used_weight = @production_log.ingredient_weights&.dig(field_key)&.to_f

      # ingredient_weights에 값이 없으면 recipe_ingredient의 기본 중량 사용
      if used_weight.nil? || used_weight <= 0
        used_weight = recipe_ingredient.weight.to_f
      end

      if used_weight <= 0
        render json: { success: false, errors: [ "재료의 중량이 설정되지 않았습니다." ] }, status: :unprocessable_entity
        return
      end

      # 재고 처리 서비스 호출
      Rails.logger.info "=== Controller: 재고 처리 서비스 호출 ==="
      Rails.logger.info "Production Log ID: #{@production_log.id}, Recipe ID: #{recipe_id}"
      Rails.logger.info "Ingredient Index: #{ingredient_index}, Batch Index: #{batch_index}, Used Weight: #{used_weight}g"

      result = IngredientInventoryService.check_ingredient(
        @production_log,
        recipe_ingredient,
        batch_index,
        used_weight
      )

      Rails.logger.info "서비스 결과: success=#{result[:success]}, errors=#{result[:errors].inspect}"

      unless result[:success]
        Rails.logger.error "재고 처리 실패: #{result[:errors].join(', ')}"
        render json: { success: false, errors: result[:errors] }, status: :unprocessable_entity
        return
      end

      Rails.logger.info "재고 처리 성공!"
    else
      # 체크 해제: 레코드 찾기
      checked_ingredient = CheckedIngredient.find_by(
        production_log_id: @production_log.id,
        recipe_id: recipe_id,
        ingredient_index: ingredient_index,
        batch_index: batch_index
      )

      if checked_ingredient
        # 재고 복원 서비스 호출
        result = IngredientInventoryService.uncheck_ingredient(checked_ingredient)

        unless result[:success]
          render json: { success: false, errors: result[:errors] }, status: :unprocessable_entity
          return
        end
      end
    end

    # 작업 단계 자동 전환 로직
    update_work_status(@production_log)

    # 전체 체크된 재료 개수 계산
    checked_count = @production_log.checked_ingredients.count

    if @production_log.save
      render json: {
        success: true,
        status: @production_log.status,
        checked_count: checked_count,
        production_date: @production_log.production_date&.strftime("%m-%d"),
        production_time: @production_log.production_time&.strftime("%H:%M")
      }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def complete_work
    @production_log = ProductionLog.find(params[:id])
    batch_index = params[:batch_index].to_i

    # batch_completion_times를 Hash로 초기화 (없는 경우)
    @production_log.batch_completion_times ||= {}

    # 현재 배치의 완료 시간 저장
    current_time = Time.current
    @production_log.batch_completion_times[batch_index.to_s] = current_time.to_s

    # 첫 번째 배치 완료 시간을 production_date/time으로도 저장
    if @production_log.production_date.nil?
      @production_log.production_date = Date.today
      @production_log.production_time = current_time
    end

    # 모든 배치가 완료되었는지 확인하여 status 업데이트
    check_all_batches_completed(@production_log)

    if @production_log.save
      render json: {
        success: true,
        batch_index: batch_index,
        completion_time: current_time.strftime("%m-%d %H:%M")
      }
    else
      render json: { success: false, errors: @production_log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_production_log
    @production_log = ProductionLog.find(params[:id])
  end

  def production_log_params
    params.require(:production_log).permit(
      :production_plan_id, :finished_product_id, :recipe_id, :production_date, :production_time, :notes,
      # 기정떡 전용 필드 (온도 관리)
      :dough_count, :fermentation_room_temp, :refrigeration_room_temp,
      :water_temp, :flour_temp, :porridge_temp, :dough_temp,
      # 재료 중량 저장
      ingredient_weights: {}
    )
  end

  def update_work_status(production_log)
    # production_log의 레시피만 사용 (단일 레시피)
    recipe = production_log.recipe
    return if recipe.nil?

    # 배치 개수 계산 (뷰와 동일한 로직)
    # 뷰에서 사용하는 로직과 동일하게 계산
    fpr = production_log.finished_product.finished_product_recipes.find_by(recipe_id: recipe.id)
    weight_per_unit = fpr&.quantity || 0

    # weight_per_unit이 있는 경우에만 배치 계산
    if weight_per_unit > 0 && production_log.production_plan.present?
      recipe_total = recipe.recipe_ingredients.where(row_type: [ "ingredient", nil ]).sum(:weight)
      recipe_total = recipe_total.zero? ? 1 : recipe_total
      multiplier = (production_log.production_plan.quantity.to_f * weight_per_unit) / recipe_total
      total_scaled = recipe_total * multiplier

      # 장비 최대 작업 중량 확인
      max_work_capacity = recipe.recipe_equipments.where.not(work_capacity: [ nil, 0 ]).maximum(:work_capacity)
      max_work_capacity_g = max_work_capacity ? max_work_capacity * 1000 : nil

      if max_work_capacity_g && max_work_capacity_g > 0 && total_scaled > max_work_capacity_g
        batch_count = (total_scaled / max_work_capacity_g).ceil
      else
        batch_count = 1
      end
    else
      batch_count = 1
    end

    # 재료 개수 계산 (subtotal 제외) × 배치 개수
    ingredient_count = recipe.recipe_ingredients.where.not(row_type: "subtotal").count
    total_ingredients = ingredient_count * batch_count

    # 체크된 재료 개수 (해당 레시피만)
    checked_count = production_log.checked_ingredients.where(recipe_id: recipe.id).count

    # 상태 업데이트
    if checked_count == 0
      # 체크된 재료가 하나도 없으면 작업 전으로
      production_log.status = "pending"
    elsif checked_count >= total_ingredients
      # 모든 재료가 체크되면 작업 완료로
      production_log.status = "completed"
    else
      # 일부 재료만 체크되면 작업 중으로
      production_log.status = "in_progress"
    end
  end

  def check_all_batches_completed(production_log)
    # production_log의 레시피에서 배치 개수 계산
    recipe = production_log.recipe
    return if recipe.nil?

    # 배치 개수 계산 (update_work_status와 동일한 로직)
    fpr = production_log.finished_product.finished_product_recipes.find_by(recipe_id: recipe.id)
    weight_per_unit = fpr&.quantity || 0

    if weight_per_unit > 0 && production_log.production_plan.present?
      recipe_total = recipe.recipe_ingredients.where(row_type: [ "ingredient", nil ]).sum(:weight)
      recipe_total = recipe_total.zero? ? 1 : recipe_total
      multiplier = (production_log.production_plan.quantity.to_f * weight_per_unit) / recipe_total
      total_scaled = recipe_total * multiplier

      # 장비 최대 작업 중량 확인
      max_work_capacity = recipe.recipe_equipments.where.not(work_capacity: [ nil, 0 ]).maximum(:work_capacity)
      max_work_capacity_g = max_work_capacity ? max_work_capacity * 1000 : nil

      if max_work_capacity_g && max_work_capacity_g > 0 && total_scaled > max_work_capacity_g
        batch_count = (total_scaled / max_work_capacity_g).ceil
      else
        batch_count = 1
      end
    else
      batch_count = 1
    end

    # 모든 배치가 완료되었는지 확인
    completed_batches = production_log.batch_completion_times&.keys&.map(&:to_i) || []

    if completed_batches.length >= batch_count
      # 모든 배치가 완료되면 status를 completed로 변경
      production_log.status = "completed"
      Rails.logger.info "모든 배치(#{batch_count}개)가 완료되어 작업완료 상태로 변경됨"
    else
      # 일부 배치만 완료되면 in_progress 유지
      production_log.status = "in_progress"
      Rails.logger.info "#{completed_batches.length}/#{batch_count} 배치 완료, 작업중 상태 유지"
    end
  end

  def update_production_plan_quantity(production_log)
    # 생산 계획이 연결되어 있고, 반죽 통수가 입력되어 있으면 생산 계획 수량 업데이트
    return unless production_log.production_plan_id.present? && production_log.dough_count.present?

    begin
      production_plan = ProductionPlan.find(production_log.production_plan_id)
      production_plan.update(quantity: production_log.dough_count)

      Rails.logger.info "생산 계획 ##{production_plan.id}의 수량이 #{production_log.dough_count}(으)로 업데이트되었습니다."
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "생산 계획을 찾을 수 없습니다: #{e.message}"
    rescue => e
      Rails.logger.error "생산 계획 수량 업데이트 중 오류 발생: #{e.message}"
    end
  end
end
