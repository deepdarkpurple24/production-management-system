class AddIngredientReferenceToRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_ingredients, :source_type, :string, default: 'item'
    add_column :recipe_ingredients, :referenced_ingredient_id, :integer

    add_foreign_key :recipe_ingredients, :ingredients, column: :referenced_ingredient_id, on_delete: :cascade
    add_index :recipe_ingredients, :referenced_ingredient_id
    add_index :recipe_ingredients, :source_type
  end
end
