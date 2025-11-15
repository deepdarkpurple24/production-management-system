class AddCapacityToEquipment < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :capacity, :decimal, precision: 10, scale: 2
    add_column :equipment, :capacity_unit, :string
  end
end
