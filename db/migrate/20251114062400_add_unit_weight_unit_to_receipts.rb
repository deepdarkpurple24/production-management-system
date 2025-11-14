class AddUnitWeightUnitToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :unit_weight_unit, :string
  end
end
