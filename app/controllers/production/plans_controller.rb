class Production::PlansController < ApplicationController
  before_action :set_production_plan, only: [ :edit, :update, :destroy ]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @start_date = @date.beginning_of_month
    @end_date = @date.end_of_month

    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @start_date..@end_date)
      .order(:production_date, :created_at)

    @finished_products = FinishedProduct.order(:name)
  end

  # 일괄 생산계획 생성/수정
  def batch_create
    date = params[:date] ? Date.parse(params[:date]) : Date.today
    quantities = params[:quantities] || {}

    ActiveRecord::Base.transaction do
      quantities.each do |product_id, quantity|
        quantity = quantity.to_i
        product = FinishedProduct.find_by(id: product_id)
        next unless product

        # 해당 월에 기존 계획이 있는지 확인
        existing_plan = ProductionPlan
          .where(finished_product_id: product_id)
          .where(production_date: date.beginning_of_month..date.end_of_month)
          .first

        if quantity > 0
          if existing_plan
            # 기존 계획 수정
            old_quantity = existing_plan.quantity
            if old_quantity != quantity
              existing_plan.update!(quantity: quantity)
              # 반죽일지 재생성
              existing_plan.production_logs.destroy_all
              ProductionLogInitializer.create_logs_for_plan(existing_plan)
              log_activity(:update, existing_plan)
            end
          else
            # 새 계획 생성
            plan = ProductionPlan.create!(
              finished_product_id: product_id,
              production_date: date,
              quantity: quantity
            )
            ProductionLogInitializer.create_logs_for_plan(plan)
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

    redirect_to production_plans_path(date: date), notice: "생산 계획이 저장되었습니다."
  rescue => e
    redirect_to production_plans_path(date: date), alert: "저장 중 오류가 발생했습니다: #{e.message}"
  end

  def new
    @production_plan = ProductionPlan.new
    @production_plan.production_date = params[:date] ? Date.parse(params[:date]) : Date.today
    @production_plan.finished_product_id = params[:finished_product_id] if params[:finished_product_id]
    @finished_products = FinishedProduct.order(:name)
  end

  def create
    @production_plan = ProductionPlan.new(production_plan_params)

    if @production_plan.save
      # 생산계획 생성 시 반죽일지 자동 생성
      ProductionLogInitializer.create_logs_for_plan(@production_plan)
      log_activity(:create, @production_plan)

      redirect_to production_plans_path(date: @production_plan.production_date, view: params[:view] || "monthly"),
                  notice: "생산 계획이 성공적으로 등록되었습니다."
    else
      @finished_products = FinishedProduct.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @finished_products = FinishedProduct.order(:name)
  end

  def update
    old_quantity = @production_plan.quantity
    old_finished_product_id = @production_plan.finished_product_id

    if @production_plan.update(production_plan_params)
      # 수량이나 완제품이 변경되었으면 반죽일지 ingredient_weights 재계산
      if old_quantity != @production_plan.quantity || old_finished_product_id != @production_plan.finished_product_id
        # 기존 반죽일지 삭제 후 재생성
        @production_plan.production_logs.destroy_all
        ProductionLogInitializer.create_logs_for_plan(@production_plan)
      end

      log_activity(:update, @production_plan)
      redirect_to production_plans_path(date: @production_plan.production_date, view: params[:view] || "monthly"),
                  notice: "생산 계획이 성공적으로 수정되었습니다."
    else
      @finished_products = FinishedProduct.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    production_date = @production_plan.production_date
    log_activity(:destroy, @production_plan)
    @production_plan.destroy
    redirect_to production_plans_path(date: production_date, view: params[:view] || "monthly"),
                notice: "생산 계획이 성공적으로 삭제되었습니다."
  end

  private

  def set_production_plan
    @production_plan = ProductionPlan.find(params[:id])
  end

  def production_plan_params
    params.require(:production_plan).permit(
      :finished_product_id, :production_date, :quantity, :notes,
      :is_gijeongddeok, :split_count, :split_unit
    )
  end
end
