class AddProductionFieldsToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :production_quantity, :decimal
    add_column :ingredients, :production_unit, :string
    add_column :ingredients, :equipment, :string
    add_column :ingredients, :cooking_method, :text
  end
end
