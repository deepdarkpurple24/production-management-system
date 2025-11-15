class RemoveProcessNameFromRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    remove_column :recipe_equipments, :process_name, :string
  end
end
