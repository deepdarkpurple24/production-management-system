class AddProcessFieldsToRecipeEquipments < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_equipments, :row_type, :string
    add_column :recipe_equipments, :process_name, :string
  end
end
