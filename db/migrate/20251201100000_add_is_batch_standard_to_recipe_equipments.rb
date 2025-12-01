class AddIsBatchStandardToRecipeEquipments < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_equipments, :is_batch_standard, :boolean, default: false
  end
end
