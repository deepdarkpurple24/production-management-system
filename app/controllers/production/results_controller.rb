module Production
  class ResultsController < ApplicationController
    before_action :set_production_plan
    before_action :set_production_result, only: [:update, :destroy]

    # POST /production/plans/:production_plan_id/results
    def create
      @production_result = @production_plan.production_results.build(production_result_params)

      respond_to do |format|
        if @production_result.save
          format.html { redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), notice: "생산 실적이 등록되었습니다." }
          format.json { render json: @production_result, status: :created }
        else
          format.html { redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), alert: @production_result.errors.full_messages.join(", ") }
          format.json { render json: @production_result.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /production/plans/:production_plan_id/results/:id
    def update
      respond_to do |format|
        if @production_result.update(production_result_params)
          format.html { redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), notice: "생산 실적이 수정되었습니다." }
          format.json { render json: @production_result }
        else
          format.html { redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), alert: @production_result.errors.full_messages.join(", ") }
          format.json { render json: @production_result.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /production/plans/:production_plan_id/results/:id
    def destroy
      @production_result.destroy

      respond_to do |format|
        format.html { redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), notice: "생산 실적이 삭제되었습니다." }
        format.json { head :no_content }
      end
    end

    # POST /production/plans/:production_plan_id/results/process_packaging
    def process_packaging
      results_to_process = @production_plan.production_results.where(packaging_processed: false).where("good_quantity > 0")

      if results_to_process.empty?
        redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), alert: "처리할 포장재 출고가 없습니다."
        return
      end

      begin
        ActiveRecord::Base.transaction do
          results_to_process.each do |result|
            process_result_packaging(result)
          end
        end

        redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), notice: "포장재 출고가 완료되었습니다."
      rescue => e
        redirect_to production_plans_path(view: 'daily', date: @production_plan.production_date), alert: "포장재 출고 처리 중 오류가 발생했습니다: #{e.message}"
      end
    end

    private

    def set_production_plan
      @production_plan = ProductionPlan.find(params[:production_plan_id])
    end

    def set_production_result
      @production_result = @production_plan.production_results.find(params[:id])
    end

    def production_result_params
      params.require(:production_result).permit(:packaging_unit_id, :good_quantity, :defect_count, :notes)
    end

    def process_result_packaging(result)
      materials = result.calculate_required_materials

      materials.each do |material|
        # 출고 생성
        shipment = Inventory::Shipment.create!(
          shipment_date: Date.current,
          purpose: "생산",
          requester: "생산관리시스템",
          notes: "#{@production_plan.finished_product.name} - #{result.packaging_unit.name} #{result.good_quantity}박스 포장재"
        )

        # 출고 항목 추가
        shipment.shipment_items.create!(
          item_id: material[:item].id,
          quantity: material[:quantity],
          unit: material[:item].unit || '개',
          notes: material[:material_type]
        )
      end

      result.update!(packaging_processed: true)
    end
  end
end
