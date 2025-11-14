class AddUnitWeightToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :unit_weight, :decimal, precision: 10, scale: 2
  end
end
