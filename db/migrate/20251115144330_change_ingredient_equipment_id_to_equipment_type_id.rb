class ChangeIngredientEquipmentIdToEquipmentTypeId < ActiveRecord::Migration[8.1]
  def change
    remove_column :ingredients, :equipment_id, :integer
    add_column :ingredients, :equipment_type_id, :integer
  end
end
