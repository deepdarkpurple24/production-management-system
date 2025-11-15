class ChangeEquipmentIdToNullableInRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :recipe_equipments, :equipment_id, true
  end
end
