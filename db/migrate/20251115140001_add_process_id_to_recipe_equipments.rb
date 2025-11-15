class AddProcessIdToRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_equipments, :process_id, :integer
  end
end
