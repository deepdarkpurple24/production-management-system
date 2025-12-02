class ChangeQuantityToDecimalInProductionPlans < ActiveRecord::Migration[8.1]
  def up
    change_column :production_plans, :quantity, :decimal, precision: 10, scale: 1
  end

  def down
    change_column :production_plans, :quantity, :integer
  end
end
