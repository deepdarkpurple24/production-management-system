class AddWeightUnitToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :weight_unit, :string
  end
end
