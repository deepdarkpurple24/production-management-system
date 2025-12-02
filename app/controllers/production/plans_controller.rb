class Production::PlansController < ApplicationController
  before_action :set_production_plan, only: [ :edit, :update, :destroy ]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @start_date = @date.beginning_of_month
    @end_date = @date.end_of_month

    @production_plans = ProductionPlan
      .includes(:recipe, :finished_product, production_plan_allocations: :finished_product)
      .where(production_date: @start_date..@end_date)
      .order(:production_date, :created_at)

    @recipes = Recipe.where(show_in_production_plan: true).order(:name)
    @finished_products = FinishedProduct.order(:name)
  end

  # 일괄 생산계획 저장 (레시피 기반)
  def batch_create
    date = params[:date] ? Date.parse(params[:date]) : Date.today
    plans_data = params[:plans] || {}

    ActiveRecord::Base.transaction do
      plans_data.each do |recipe_id, plan_data|
        quantity = plan_data[:quantity].to_f  # 기정떡은 0.5 단위 지원
        unit_type = plan_data[:unit_type].presence || '개'
        allocations = plan_data[:allocations] || {}

        recipe = Recipe.find_by(id: recipe_id)
        next unless recipe

        # 해당 날짜에 해당 레시피의 기존 계획이 있는지 확인
        existing_plan = ProductionPlan
          .where(recipe_id: recipe_id)
          .where(production_date: date)
          .first

        if quantity > 0
          # 기정떡 레시피인 경우 기본 완제품들 자동 배분에 추가
          is_gijeongddeok = recipe.name.include?('기정떡')
          default_product_ids = []
          if is_gijeongddeok
            default_product_ids = GijeongddeokDefault.instance.default_finished_product_ids || []
          end

          # 기존 allocations에 기본 완제품 추가 (아직 없는 것만)
          if default_product_ids.any?
            default_product_ids.each do |product_id|
              allocations[product_id.to_s] ||= "0"
            end
          end

          if existing_plan
            # 기존 계획 수정
            existing_plan.update!(quantity: quantity, unit_type: unit_type, production_date: date)
            update_allocations(existing_plan, allocations)

            # 반죽일지 재생성
            existing_plan.production_logs.destroy_all
            ProductionLogInitializer.create_logs_for_plan(existing_plan) if existing_plan.finished_product_id
            log_activity(:update, existing_plan)
          else
            # 새 계획 생성
            plan = ProductionPlan.create!(
              recipe_id: recipe_id,
              production_date: date,
              quantity: quantity,
              unit_type: unit_type
            )
            update_allocations(plan, allocations)

            ProductionLogInitializer.create_logs_for_plan(plan) if plan.finished_product_id
            log_activity(:create, plan)
          end
        else
          # 수량이 0이면 기존 계획 삭제
          if existing_plan
            log_activity(:destroy, existing_plan)
            existing_plan.destroy!
          end
        end
      end
    end

    # 캘린더 뷰에서 저장한 경우 캘린더 뷰로 리다이렉트
    if params[:redirect_to_calendar] == "true"
      redirect_to production_plans_path(date: date.beginning_of_month), notice: "생산 계획이 저장되었습니다."
    else
      redirect_to production_plans_path(date: date, view: 'list'), notice: "생산 계획이 저장되었습니다."
    end
  rescue => e
    Rails.logger.error "batch_create error: #{e.message}"
    if params[:redirect_to_calendar] == "true"
      redirect_to production_plans_path(date: date.beginning_of_month), alert: "저장 중 오류가 발생했습니다: #{e.message}"
    else
      redirect_to production_plans_path(date: date, view: 'list'), alert: "저장 중 오류가 발생했습니다: #{e.message}"
    end
  end

  def new
    @production_plan = ProductionPlan.new
    @production_plan.production_date = params[:date] ? Date.parse(params[:date]) : Date.today
    @production_plan.finished_product_id = params[:finished_product_id] if params[:finished_product_id]
    @finished_products = FinishedProduct.order(:name)
    @recipes = Recipe.order(:name)
  end

  def create
    @production_plan = ProductionPlan.new(production_plan_params)

    if @production_plan.save
      # 생산계획 생성 시 반죽일지 자동 생성
      ProductionLogInitializer.create_logs_for_plan(@production_plan) if @production_plan.finished_product_id
      log_activity(:create, @production_plan)

      redirect_to production_plans_path(date: @production_plan.production_date),
                  notice: "생산 계획이 성공적으로 등록되었습니다."
    else
      @finished_products = FinishedProduct.order(:name)
      @recipes = Recipe.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @finished_products = FinishedProduct.order(:name)
    @recipes = Recipe.order(:name)
  end

  def update
    old_quantity = @production_plan.quantity
    old_finished_product_id = @production_plan.finished_product_id
    old_recipe_id = @production_plan.recipe_id

    if @production_plan.update(production_plan_params)
      # 수량이나 완제품/레시피가 변경되었으면 반죽일지 ingredient_weights 재계산
      if old_quantity != @production_plan.quantity ||
         old_finished_product_id != @production_plan.finished_product_id ||
         old_recipe_id != @production_plan.recipe_id
        # 기존 반죽일지 삭제 후 재생성
        @production_plan.production_logs.destroy_all
        ProductionLogInitializer.create_logs_for_plan(@production_plan) if @production_plan.finished_product_id
      end

      log_activity(:update, @production_plan)
      redirect_to production_plans_path(date: @production_plan.production_date),
                  notice: "생산 계획이 성공적으로 수정되었습니다."
    else
      @finished_products = FinishedProduct.order(:name)
      @recipes = Recipe.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    production_date = @production_plan.production_date
    log_activity(:destroy, @production_plan)
    @production_plan.destroy
    redirect_to production_plans_path(date: production_date),
                notice: "생산 계획이 성공적으로 삭제되었습니다."
  end

  private

  def set_production_plan
    @production_plan = ProductionPlan.find(params[:id])
  end

  def production_plan_params
    params.require(:production_plan).permit(
      :recipe_id, :finished_product_id, :production_date, :quantity, :unit_type, :notes,
      :is_gijeongddeok, :split_count, :split_unit,
      production_plan_allocations_attributes: [ :id, :finished_product_id, :quantity, :_destroy ]
    )
  end

  def update_allocations(plan, allocations)
    # 기존 배분 삭제
    plan.production_plan_allocations.destroy_all

    # 새 배분 생성
    allocations.each do |finished_product_id, qty|
      qty = qty.to_i
      next if qty <= 0

      plan.production_plan_allocations.create!(
        finished_product_id: finished_product_id,
        quantity: qty
      )
    end
  end
end
