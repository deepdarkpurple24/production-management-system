class AddWorkCapacityToRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_equipments, :work_capacity, :decimal, precision: 10, scale: 2
    add_column :recipe_equipments, :work_capacity_unit, :string
  end
end
