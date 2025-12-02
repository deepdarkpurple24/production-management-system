class AddReferencedRecipeToRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_ingredients, :referenced_recipe_id, :integer
  end
end
