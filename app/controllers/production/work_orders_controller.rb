# 작업지시 페이지 - 오늘 기준 실행 화면
class Production::WorkOrdersController < ApplicationController
  def index
    @today = Date.today
    @tomorrow = @today + 1.day
    @yesterday = @today - 1.day

    # ===============================
    # 왼쪽 컬럼: 오늘 작업
    # ===============================

    # 섹션 1: 기정떡 (D-1 반죽 → D-day 생산)
    # 어제 반죽한 양 = 어제 날짜에 생산계획이 있고 기정떡인 것들
    @gijeongddeok_plans = ProductionPlan
      .includes(:recipe, :production_plan_allocations => :finished_product)
      .joins(:recipe)
      .where("recipes.name LIKE ?", "%기정떡%")
      .where(production_date: @today)
      .order(:created_at)

    # 기정떡 사용 가능한 총 반죽량 계산
    @available_dough_weight = 0
    @gijeongddeok_plans.each do |plan|
      if plan.recipe&.total_weight.present? && plan.quantity.present?
        @available_dough_weight += plan.recipe.total_weight * plan.quantity
      end
    end

    # 기정떡 파생 상품들 (기정떡 레시피를 사용하는 완제품들)
    gijeongddeok_recipes = Recipe.where("name LIKE ?", "%기정떡%")
    @gijeongddeok_products = FinishedProduct
      .joins(:finished_product_recipes)
      .where(finished_product_recipes: { recipe_id: gijeongddeok_recipes.pluck(:id) })
      .distinct
      .order(:name)

    # 기본 기정떡 (primary product)
    @gijeongddeok_default = GijeongddeokDefault.instance
    @primary_product = FinishedProduct.find_by(id: @gijeongddeok_default.primary_finished_product_id)

    # 섹션 2: 기타 제품 (당일 반죽 → 당일 생산)
    # 오늘 날짜에 기정떡이 아닌 생산 계획
    @other_plans = ProductionPlan
      .includes(:recipe, :finished_product, :production_plan_allocations => :finished_product)
      .left_joins(:recipe)
      .where(production_date: @today)
      .where.not("recipes.name LIKE ?", "%기정떡%")
      .or(
        ProductionPlan
          .includes(:recipe, :finished_product, :production_plan_allocations => :finished_product)
          .left_joins(:recipe)
          .where(production_date: @today)
          .where(recipes: { id: nil })
      )
      .order(:created_at)

    # ===============================
    # 오른쪽 컬럼: 내일 반죽 준비
    # ===============================

    # 내일 날짜의 기정떡 생산 계획
    @tomorrow_gijeongddeok_plans = ProductionPlan
      .includes(:recipe)
      .joins(:recipe)
      .where("recipes.name LIKE ?", "%기정떡%")
      .where(production_date: @tomorrow)
      .order(:created_at)

    # 내일 계획된 총 반죽량/통수
    @planned_dough_count = @tomorrow_gijeongddeok_plans.sum(:quantity)
  end

  # 오늘 작업 저장 (파생 상품 수량)
  def save_today_work
    allocations_data = params[:allocations] || {}

    ActiveRecord::Base.transaction do
      allocations_data.each do |plan_id, products|
        plan = ProductionPlan.find(plan_id)

        # 기존 배분 삭제
        plan.production_plan_allocations.destroy_all

        # 새 배분 생성
        products.each do |product_id, qty|
          qty = qty.to_i
          next if qty <= 0

          plan.production_plan_allocations.create!(
            finished_product_id: product_id,
            quantity: qty
          )
        end
      end
    end

    redirect_to production_work_orders_path, notice: "오늘 작업이 저장되었습니다."
  rescue => e
    redirect_to production_work_orders_path, alert: "저장 중 오류가 발생했습니다: #{e.message}"
  end

  # 내일 반죽 준비 저장
  def save_tomorrow_dough
    dough_count = params[:dough_count].to_f
    tomorrow = Date.today + 1.day

    # 기정떡 레시피 찾기
    gijeongddeok_recipe = Recipe.where("name LIKE ?", "%기정떡%").first

    unless gijeongddeok_recipe
      redirect_to production_work_orders_path, alert: "기정떡 레시피를 찾을 수 없습니다."
      return
    end

    ActiveRecord::Base.transaction do
      # 내일 날짜에 기정떡 생산 계획이 있는지 확인
      existing_plan = ProductionPlan
        .joins(:recipe)
        .where("recipes.name LIKE ?", "%기정떡%")
        .where(production_date: tomorrow)
        .first

      if dough_count > 0
        if existing_plan
          # 기존 계획 수정
          existing_plan.update!(quantity: dough_count, unit_type: "통")
        else
          # 새 계획 생성
          ProductionPlan.create!(
            recipe_id: gijeongddeok_recipe.id,
            production_date: tomorrow,
            quantity: dough_count,
            unit_type: "통"
          )
        end
      else
        # 수량이 0이면 기존 계획 삭제
        existing_plan&.destroy
      end
    end

    redirect_to production_work_orders_path, notice: "내일 반죽 준비가 저장되었습니다."
  rescue => e
    redirect_to production_work_orders_path, alert: "저장 중 오류가 발생했습니다: #{e.message}"
  end
end
