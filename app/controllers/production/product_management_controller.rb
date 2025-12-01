module Production
  class ProductManagementController < ApplicationController
    def index
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @production_plans = ProductionPlan.includes(
        :production_results,
        finished_product: { packaging_units: :packaging_unit_materials }
      ).where(production_date: @date).order(:created_at)
    end
  end
end
