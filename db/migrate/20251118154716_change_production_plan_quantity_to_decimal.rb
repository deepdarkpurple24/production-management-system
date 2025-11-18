class ChangeProductionPlanQuantityToDecimal < ActiveRecord::Migration[8.1]
  def change
    change_column :production_plans, :quantity, :decimal, precision: 10, scale: 2
  end
end
