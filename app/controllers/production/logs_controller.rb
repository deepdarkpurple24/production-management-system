class Production::LogsController < ApplicationController
  before_action :set_production_log, only: [:edit, :update, :destroy]

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

    @production_logs = ProductionLog
      .includes(:finished_product, :production_plan)
      .where(production_date: @start_date..@end_date)
      .order(:production_date, :created_at)

    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @start_date..@end_date)
      .order(:production_date)

    @finished_products = FinishedProduct.order(:name)
  end

  def new
    @production_log = ProductionLog.new
    @production_log.production_date = params[:date] ? Date.parse(params[:date]) : Date.today

    # 생산계획 ID가 주어지면 해당 계획 로드
    if params[:production_plan_id]
      @production_plan = ProductionPlan.find(params[:production_plan_id])
      @production_log.production_plan = @production_plan
      @production_log.finished_product = @production_plan.finished_product
      @production_log.production_date = @production_plan.production_date
    end

    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @production_log.production_date)
      .order(:created_at)

    @finished_products = FinishedProduct.order(:name)
  end

  def create
    @production_log = ProductionLog.new(production_log_params)

    if @production_log.save
      # 막걸리 자동 출고 처리
      process_makgeolli_shipment(@production_log)

      redirect_to production_logs_path(date: @production_log.production_date, view: params[:view] || 'monthly'),
                  notice: '생산 일지가 성공적으로 등록되었습니다.'
    else
      @production_plans = ProductionPlan
        .includes(:finished_product)
        .where(production_date: @production_log.production_date)
        .order(:created_at)
      @finished_products = FinishedProduct.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @production_plans = ProductionPlan
      .includes(:finished_product)
      .where(production_date: @production_log.production_date)
      .order(:created_at)
    @finished_products = FinishedProduct.order(:name)
  end

  def update
    old_makgeolli_consumption = @production_log.makgeolli_consumption

    if @production_log.update(production_log_params)
      # 막걸리 소모량이 변경되었으면 자동 출고 처리
      if @production_log.makgeolli_consumption != old_makgeolli_consumption
        process_makgeolli_shipment(@production_log, old_makgeolli_consumption)
      end

      redirect_to production_logs_path(date: @production_log.production_date, view: params[:view] || 'monthly'),
                  notice: '생산 일지가 성공적으로 수정되었습니다.'
    else
      @production_plans = ProductionPlan
        .includes(:finished_product)
        .where(production_date: @production_log.production_date)
        .order(:created_at)
      @finished_products = FinishedProduct.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    production_date = @production_log.production_date
    @production_log.destroy
    redirect_to production_logs_path(date: production_date, view: params[:view] || 'monthly'),
                notice: '생산 일지가 성공적으로 삭제되었습니다.'
  end

  private

  def set_production_log
    @production_log = ProductionLog.find(params[:id])
  end

  def production_log_params
    params.require(:production_log).permit(
      :production_plan_id, :finished_product_id, :production_date, :production_time, :notes,
      # 기정떡 전용 필드
      :dough_count, :fermentation_room_temp, :refrigeration_room_temp,
      :yeast_amount, :steiva_amount, :salt_amount, :sugar_amount,
      :water_amount, :water_temp, :flour_temp, :porridge_temp, :dough_temp,
      :makgeolli_consumption, :makgeolli_expiry_date
    )
  end

  def process_makgeolli_shipment(production_log, old_consumption = nil)
    return unless production_log.makgeolli_consumption.present? && production_log.makgeolli_consumption > 0

    # 막걸리 품목 찾기 (이름에 "막걸리"가 포함된 품목)
    makgeolli_item = Item.where("name LIKE ?", "%막걸리%").first

    unless makgeolli_item
      flash[:warning] = "막걸리 품목을 찾을 수 없어 자동 출고 처리를 건너뜁니다. 품목 관리에서 막걸리를 등록해주세요."
      return
    end

    # 생산일지 ID를 포함한 고유 식별자
    reference_note = "[생산일지##{production_log.id}]"

    # 기존 출고 내역 찾기 (notes에 생산일지 ID가 포함된 것)
    shipment = Shipment.where(item: makgeolli_item)
                       .where("notes LIKE ?", "%#{reference_note}%")
                       .first_or_initialize

    shipment.shipment_date = production_log.production_date
    shipment.quantity = production_log.makgeolli_consumption
    shipment.notes = "#{reference_note} #{production_log.finished_product.name} 생산 자동 출고"
    shipment.purpose = "생산"

    if shipment.save
      flash[:success] = "막걸리 #{production_log.makgeolli_consumption}L가 자동으로 출고 처리되었습니다." if flash[:notice]
    else
      flash[:warning] = "막걸리 자동 출고 처리 실패: #{shipment.errors.full_messages.join(', ')}"
    end
  rescue => e
    Rails.logger.error "막걸리 자동 출고 처리 중 오류 발생: #{e.message}"
    flash[:warning] = "막걸리 자동 출고 처리 중 오류가 발생했습니다: #{e.message}"
  end
end
