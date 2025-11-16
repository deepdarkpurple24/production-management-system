class Production::PlansController < ApplicationController
  before_action :set_production_plan, only: [:edit, :update, :destroy]

  def index
    @view_type = params[:view] || 'monthly'
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    case @view_type
    when 'weekly'
      @start_date = @date.beginning_of_week
      @end_date = @date.end_of_week
    when 'daily'
      @start_date = @date
      @end_date = @date
    else # monthly
      @start_date = @date.beginning_of_month
      @end_date = @date.end_of_month
    end

    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @start_date..@end_date)
      .order(:production_date, :created_at)

    @finished_products = FinishedProduct.order(:name)
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
      redirect_to production_plans_path(date: @production_plan.production_date, view: params[:view] || 'monthly'),
                  notice: '생산 계획이 성공적으로 등록되었습니다.'
    else
      @finished_products = FinishedProduct.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @finished_products = FinishedProduct.order(:name)
  end

  def update
    if @production_plan.update(production_plan_params)
      redirect_to production_plans_path(date: @production_plan.production_date, view: params[:view] || 'monthly'),
                  notice: '생산 계획이 성공적으로 수정되었습니다.'
    else
      @finished_products = FinishedProduct.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    production_date = @production_plan.production_date
    @production_plan.destroy
    redirect_to production_plans_path(date: production_date, view: params[:view] || 'monthly'),
                notice: '생산 계획이 성공적으로 삭제되었습니다.'
  end

  private

  def set_production_plan
    @production_plan = ProductionPlan.find(params[:id])
  end

  def production_plan_params
    params.require(:production_plan).permit(
      :finished_product_id, :production_date, :quantity, :notes
    )
  end
end
