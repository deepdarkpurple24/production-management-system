class AddPositionToRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_equipments, :position, :integer
  end
end
